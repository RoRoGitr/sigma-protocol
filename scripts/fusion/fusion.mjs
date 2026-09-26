#!/usr/bin/env node
// fusion.mjs — CLI-first multi-provider fusion primitive.
//
// Panel of diverse models each ANALYZE the task independently (in parallel),
// then a SYNTHESIZER writes the single best answer grounded in all analyses.
//
// Design principle: CLI-first — models are reached through installed CLIs via
// their own auth. API keys (OPENROUTER/MINIMAX/ZHIPUAI) are opt-in extra voices.
//
// Usage:
//   node scripts/fusion/fusion.mjs --task-file <path> [options]
//
//   --task-file <path>      : file containing the task prompt (required)
//   --panel auto|id,id,...  : voice selection (default: auto = cross-family ≥2)
//   --synthesizer <id>      : voice to synthesize (default: claude, then first available)
//   --json                  : output { answer, panel, synthesizer, dropped, cost }
//   --timeout <ms>          : per-voice timeout in ms (default: 60000)
//   --max-panel <n>         : cap panel size (default: 4)
//
// Test hooks (for hermetic tests — no real CLIs/keys needed):
//   FUSION_VOICE_CMD_<ID>   : override a voice's command (e.g. FUSION_VOICE_CMD_claude="echo mock")
//   FUSION_SYNTH_CMD        : override the synthesizer command
//
// Telemetry:
//   Records a fusion event to .sigma/telemetry/sessions/<session_id>.jsonl
//   matching the A0 pipeline-gate shape: {event, gen_ai.usage.total_tokens, cost_usd, ...}
//
// Graceful degradation:
//   - A voice that errors or times out is DROPPED (logged); others proceed.
//   - If ≤1 voice survives the panel, degrades to single-model and logs a warning.
//   - If 0 voices survive, exits with an error.

import { execFile, spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT  = path.resolve(__dirname, '..', '..');
const PROVIDERS_CACHE = path.join(REPO_ROOT, '.sigma', 'providers.json');
const PROVIDERS_CONFIG = path.join(REPO_ROOT, '.sigma', 'providers.config.json');
const TELEMETRY_DIR   = path.join(REPO_ROOT, '.sigma', 'telemetry', 'sessions');
const SYNTH_PROMPT_PATH = path.join(REPO_ROOT, 'references', 'fusion-synthesizer.md');

// ── Constants ────────────────────────────────────────────────────────────────

const DEFAULT_TIMEOUT_MS = 120_000;   // real reasoning CLIs (codex/claude) need >60s; override with --timeout
const DEFAULT_MAX_PANEL  = 4;
const MIN_PANEL_SIZE     = 2;   // fewer = degrade to single-model

// ── Argument parsing ─────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2);

let taskFile    = null;
let panelArg    = 'auto';
let synthId     = null;
let jsonMode    = false;
let timeoutMs   = DEFAULT_TIMEOUT_MS;
let maxPanel    = DEFAULT_MAX_PANEL;
let backend     = process.env.FUSION_BACKEND || 'byo';   // 'byo' (local panel) | 'openrouter' (hosted Fusion API); --backend overrides

for (let i = 0; i < rawArgs.length; i++) {
  const a = rawArgs[i];
  switch (a) {
    case '--task-file':
      taskFile = rawArgs[++i];
      break;
    case '--panel':
      panelArg = rawArgs[++i];
      break;
    case '--synthesizer':
      synthId = rawArgs[++i];
      break;
    case '--json':
      jsonMode = true;
      break;
    case '--timeout':
      timeoutMs = parseInt(rawArgs[++i], 10);
      break;
    case '--max-panel':
      maxPanel = parseInt(rawArgs[++i], 10);
      break;
    case '--backend':
      backend = rawArgs[++i];
      break;
    default:
      console.error(`fusion: unknown flag: ${a}`);
      process.exit(1);
  }
}

if (!taskFile) {
  console.error('fusion: --task-file <path> is required');
  process.exit(1);
}

if (backend !== 'byo' && backend !== 'openrouter') {
  console.error(`fusion: unknown --backend '${backend}' (use 'byo' or 'openrouter')`);
  process.exit(1);
}

// ── Task loading ─────────────────────────────────────────────────────────────

const taskAbsPath = path.resolve(taskFile);
if (!fs.existsSync(taskAbsPath)) {
  console.error(`fusion: task file not found: ${taskAbsPath}`);
  process.exit(1);
}
const taskContent = fs.readFileSync(taskAbsPath, 'utf8');

// ── Provider loading ─────────────────────────────────────────────────────────

// F2: the user's provider config (.sigma/providers.config.json), if any.
// Populated by loadProviders(); read by selectSynthesizer(). null = no config.
let providerConfig = null;

function loadProviderConfig() {
  if (!fs.existsSync(PROVIDERS_CONFIG)) return null;
  try {
    const cfg = JSON.parse(fs.readFileSync(PROVIDERS_CONFIG, 'utf8'));
    return (cfg && typeof cfg === 'object' && !Array.isArray(cfg)) ? cfg : null;
  } catch {
    return null;
  }
}

// Strip secrets before any error message is logged or returned. API errors can
// embed the HTTP response body, which may reflect back an Authorization header
// or the key value. Applied at every surface: dropped reasons, fatal errors.
function redactSecrets(s) {
  let out = String(s);
  for (const name of ['OPENROUTER_API_KEY', 'MINIMAX_API_KEY', 'ZHIPUAI_API_KEY']) {
    const v = process.env[name];
    if (v && v.length >= 8) out = out.split(v).join('[REDACTED]');
  }
  return out
    .replace(/Bearer\s+\S+/gi, 'Bearer [REDACTED]')
    .replace(/(x-api-key["':\s]+)\S+/gi, '$1[REDACTED]');
}

async function loadProviders() {
  if (!fs.existsSync(PROVIDERS_CACHE)) {
    // Run detect-providers.mjs to populate the cache, then read it.
    const detectPath = path.join(__dirname, 'detect-providers.mjs');
    try {
      await execFileAsync(process.execPath, [detectPath, '--json'], { timeout: 10_000 })
        .then(({ stdout }) => {
          const voices = JSON.parse(stdout);
          const dir = path.dirname(PROVIDERS_CACHE);
          if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
          fs.writeFileSync(PROVIDERS_CACHE, JSON.stringify(voices, null, 2) + '\n', 'utf8');
        });
    } catch {
      // ignore — return empty below
    }
  }
  if (!fs.existsSync(PROVIDERS_CACHE)) return [];
  let voices;
  try {
    voices = JSON.parse(fs.readFileSync(PROVIDERS_CACHE, 'utf8'));
  } catch {
    return [];
  }
  if (!Array.isArray(voices)) return [];
  // F2: honor the user's provider config if present. enabledVoices is the
  // AUTHORITATIVE allow-list — never fall open to a voice the user didn't enable
  // (esp. a paid API voice that was cached only because a key is in the env).
  // If the filter leaves zero, main() reports "no voices available" loudly
  // rather than silently running an un-opted voice. No config → voices unchanged.
  providerConfig = loadProviderConfig();
  // A PRESENT enabledVoices array is authoritative — even when empty (means
  // "nothing enabled" → loud no-voices error, not fall-open). Absent/non-array
  // key = no policy = voices unchanged.
  if (providerConfig && Array.isArray(providerConfig.enabledVoices)) {
    const enabled = new Set(providerConfig.enabledVoices);
    voices = voices.filter(v => enabled.has(v.id));
  }
  return voices;
}

// ── Panel selection ───────────────────────────────────────────────────────────

/**
 * Select ≥2 voices spanning ≥2 families (cross-family default), capped at maxPanel.
 * If panelArg is "auto", we pick greedily: first voice per family, then fill up to maxPanel.
 */
function selectPanel(allVoices) {
  if (panelArg !== 'auto') {
    // Explicit IDs
    const ids = panelArg.split(',').map(s => s.trim()).filter(Boolean);
    const selected = ids.map(id => {
      const v = allVoices.find(v => v.id === id);
      if (!v) console.warn(`fusion: panel voice '${id}' not available — skipping`);
      return v;
    }).filter(Boolean);
    return selected;
  }

  // Auto: pick cross-family, cap at maxPanel.
  // Priority: one voice per family first (breadth), then fill remaining slots.
  const byFamily = new Map();
  for (const v of allVoices) {
    if (!byFamily.has(v.family)) byFamily.set(v.family, []);
    byFamily.get(v.family).push(v);
  }

  const panel = [];
  // First pass: one per family
  for (const voices of byFamily.values()) {
    if (panel.length >= maxPanel) break;
    panel.push(voices[0]);
  }
  // Second pass: fill remaining slots with extras (different id)
  if (panel.length < maxPanel) {
    for (const v of allVoices) {
      if (panel.length >= maxPanel) break;
      if (!panel.find(p => p.id === v.id)) panel.push(v);
    }
  }

  return panel;
}

// ── Synthesizer selection ────────────────────────────────────────────────────

function selectSynthesizer(allVoices, _panel) {
  // Explicit override
  if (synthId) {
    const v = allVoices.find(v => v.id === synthId);
    if (!v) {
      console.error(`fusion: synthesizer '${synthId}' not available`);
      process.exit(1);
    }
    return v;
  }
  // F2: default synthesizer from the provider config, if it names an available voice.
  if (providerConfig && providerConfig.synthesizer) {
    const v = allVoices.find(v => v.id === providerConfig.synthesizer);
    if (v) return v;
  }
  // Default priority: claude (anthropic) → first available
  return allVoices.find(v => v.id === 'claude') ||
         allVoices.find(v => v.family === 'anthropic') ||
         allVoices[0];
}

// ── Command resolution ────────────────────────────────────────────────────────
//
// Test hook: FUSION_VOICE_CMD_<ID> overrides a voice's command.
// FUSION_SYNTH_CMD overrides the synthesizer command.
// The override value is treated as a literal executable path or name (no shell eval).

function resolveVoiceCommand(voice) {
  const envKey = `FUSION_VOICE_CMD_${voice.id.toUpperCase().replace(/-/g, '_')}`;
  return process.env[envKey] || voice.invoke;
}

function resolveSynthCommand(voice) {
  return process.env.FUSION_SYNTH_CMD || voice.invoke;
}

// ── Voice invocation ─────────────────────────────────────────────────────────
//
// CLI voices: write task to a temp file, pass filename as argument (injection-safe).
// API voices: use fetch() with the key from env.
// stdin is closed (< /dev/null equivalent) via input: '' to prevent hangs.

async function invokeVoice(voice, prompt, label) {
  const cmdRaw = resolveVoiceCommand(voice);

  if (voice.via === 'api') {
    return invokeApiVoice(voice, prompt, label);
  }

  // CLI voice — write prompt to a temp file to avoid any shell interpolation.
  const tmpFile = path.join(
    process.env.TMPDIR || '/tmp',
    `fusion-voice-${randomUUID()}.txt`
  );
  try {
    fs.writeFileSync(tmpFile, prompt, 'utf8');
    const result = await invokeCliVoice(voice, cmdRaw, tmpFile, label);
    return result;
  } finally {
    try { fs.unlinkSync(tmpFile); } catch {}
  }
}

/**
 * Invoke a CLI voice.
 * cmdRaw may be:
 *   - a test stub: "echo something" or "/path/to/script"
 *   - a real CLI: "claude --print -" / "codex exec ..."
 *
 * We split cmdRaw into [binary, ...args] and pass the tmpFile path as the
 * final argument so the content never touches a shell string.
 *
 * Special case: if the invoke string ends with "-" (stdin), we use stdin
 * instead of a file argument and pass the prompt via the `input` option.
 */
async function invokeCliVoice(_voice, cmdRaw, tmpFile, _label) {
  const parts = cmdRaw.trim().split(/\s+/);
  const binary = parts[0];
  let   cliArgs = parts.slice(1);

  let stdinContent = '';   // always written then closed (prevents stdin hangs)
  // If the invoke template ends with "-" the CLI reads the prompt from stdin.
  if (cliArgs[cliArgs.length - 1] === '-') {
    cliArgs = cliArgs.slice(0, -1);
    stdinContent = fs.readFileSync(tmpFile, 'utf8');
  } else {
    // Pass the temp file path as the last argument (injection-safe argv).
    cliArgs = [...cliArgs, tmpFile];
  }

  return spawnCapture(binary, cliArgs, stdinContent, timeoutMs);
}

/**
 * Spawn a child, write `stdinContent` to its stdin then close it, collect stdout.
 * Uses spawn — NOT execFile — because async execFile silently IGNORES the `input`
 * option, so stdin-mode voices (`claude --print -`, `codex exec ... -`) would
 * receive no prompt. (Caught by the live step-judge run; stub tests used echo.)
 */
function spawnCapture(binary, cliArgs, stdinContent, timeout) {
  return new Promise((resolve, reject) => {
    let child;
    try {
      child = spawn(binary, cliArgs, { stdio: ['pipe', 'pipe', 'pipe'] });
    } catch (err) { reject(err); return; }
    let stdout = '', stderr = '', outBytes = 0, done = false;
    const MAX = 4 * 1024 * 1024;
    const finish = (fn, arg) => { if (done) return; done = true; clearTimeout(timer); fn(arg); };
    const timer = setTimeout(() => { try { child.kill('SIGKILL'); } catch {} finish(reject, new Error(`timeout after ${timeout}ms`)); }, timeout);
    child.stdout.on('data', d => { outBytes += d.length; if (outBytes <= MAX) stdout += d; });
    child.stderr.on('data', d => { if (stderr.length < 4096) stderr += d; });
    child.on('error', err => finish(reject, err));
    child.on('close', code => {
      if (code === 0) finish(resolve, stdout.trim());
      else finish(reject, new Error(`exit ${code}: ${stderr.trim().slice(0, 200)}`));
    });
    if (child.stdin) {
      child.stdin.on('error', () => {});   // ignore EPIPE if the child exits early
      try { child.stdin.write(stdinContent); child.stdin.end(); } catch { /* already closed */ }
    }
  });
}

/**
 * Invoke an API voice via fetch().
 * Supports: openrouter, minimax (Anthropic-SDK-compat), zhipu (GLM).
 */
async function invokeApiVoice(voice, prompt, _label) {
  if (voice.id === 'openrouter') {
    const key = process.env.OPENROUTER_API_KEY;
    if (!key) throw new Error('OPENROUTER_API_KEY not set');
    const resp = await fetchWithTimeout('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'openrouter/auto',
        messages: [{ role: 'user', content: prompt }],
      }),
    }, timeoutMs);
    const data = await resp.json();
    return data.choices?.[0]?.message?.content || '';
  }

  if (voice.id === 'minimax') {
    const key = process.env.MINIMAX_API_KEY;
    if (!key) throw new Error('MINIMAX_API_KEY not set');
    // MiniMax is Anthropic-SDK-compatible at this base URL.
    const resp = await fetchWithTimeout('https://api.minimax.io/anthropic/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': key,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'MiniMax-Text-01',
        max_tokens: 2048,
        messages: [{ role: 'user', content: prompt }],
      }),
    }, timeoutMs);
    const data = await resp.json();
    return data.content?.[0]?.text || '';
  }

  if (voice.id === 'glm') {
    const key = process.env.ZHIPUAI_API_KEY;
    if (!key) throw new Error('ZHIPUAI_API_KEY not set');
    const resp = await fetchWithTimeout('https://open.bigmodel.cn/api/paas/v4/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'glm-4-flash',
        messages: [{ role: 'user', content: prompt }],
      }),
    }, timeoutMs);
    const data = await resp.json();
    return data.choices?.[0]?.message?.content || '';
  }

  throw new Error(`fusion: no API handler for voice '${voice.id}'`);
}

async function fetchWithTimeout(url, opts, ms) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  try {
    const resp = await fetch(url, { ...opts, signal: controller.signal });
    if (!resp.ok) {
      const body = await resp.text().catch(() => '');
      throw new Error(`HTTP ${resp.status}: ${body.slice(0, 200)}`);
    }
    return resp;
  } finally {
    clearTimeout(timer);
  }
}

// ── OpenRouter Fusion backend (hosted panel→judge) ───────────────────────────
//
// OpenRouter's Fusion is the standard chat-completions endpoint with
// model "openrouter/fusion": the router runs its own panel in parallel and a
// judge synthesizes the final answer. Opt-in (needs OPENROUTER_API_KEY).
// Returns { answer, costUsd } or null — null means "fall back to the BYO panel".
// NEVER throws: an external paid dep must not hard-fail a gate.
//
// Endpoint/model are env-overridable (OPENROUTER_FUSION_URL / _MODEL) so an API
// change does not require a code change. Test hook: FUSION_OPENROUTER_CMD — its
// stdout is used as the answer (no network).
async function runOpenRouterFusion(task) {
  const cmdRaw = process.env.FUSION_OPENROUTER_CMD;
  if (cmdRaw) {
    try {
      const parts = cmdRaw.trim().split(/\s+/);
      const { stdout } = await execFileAsync(parts[0], parts.slice(1),
        { timeout: timeoutMs, maxBuffer: 4 * 1024 * 1024 });
      const answer = stdout.trim();
      return answer ? { answer, costUsd: null } : null;
    } catch (err) {
      console.error(`fusion: FUSION_OPENROUTER_CMD failed — ${redactSecrets(err.message)}`);
      return null;
    }
  }

  const key = process.env.OPENROUTER_API_KEY;
  if (!key) {
    console.error('fusion: --backend openrouter needs OPENROUTER_API_KEY (opt-in extra).');
    return null;
  }

  const url   = process.env.OPENROUTER_FUSION_URL   || 'https://openrouter.ai/api/v1/chat/completions';
  const model = process.env.OPENROUTER_FUSION_MODEL || 'openrouter/fusion';
  try {
    const resp = await fetchWithTimeout(url, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model, messages: [{ role: 'user', content: task }] }),
    }, timeoutMs);
    const data = await resp.json();
    const answer = data.choices?.[0]?.message?.content || '';
    if (!answer) {
      console.error('fusion: openrouter fusion returned empty content.');
      return null;
    }
    const costUsd = typeof data.usage?.cost === 'number' ? data.usage.cost : null;
    return { answer, costUsd };
  } catch (err) {
    // The error can include the HTTP response body — redact before logging.
    console.error(`fusion: openrouter fusion call failed — ${redactSecrets(err.message)}`);
    return null;
  }
}

// ── Synthesizer prompt assembly ───────────────────────────────────────────────

function buildSynthPrompt(task, analyses) {
  // Load the versioned synthesizer prompt from references/fusion-synthesizer.md.
  let synthSystemPrompt = '';
  if (fs.existsSync(SYNTH_PROMPT_PATH)) {
    synthSystemPrompt = fs.readFileSync(SYNTH_PROMPT_PATH, 'utf8').trim();
  } else {
    synthSystemPrompt = '# Fusion Synthesizer\nYou are a synthesizer. Produce the single best answer grounded in the panel analyses provided.';
  }

  const analysisBlock = analyses.map(({ voice, output }, i) =>
    `## Analysis ${i + 1} — ${voice.id} (${voice.family})\n\n${output}`
  ).join('\n\n---\n\n');

  return [
    synthSystemPrompt,
    '',
    '---',
    '',
    '## Task',
    '',
    task,
    '',
    '---',
    '',
    '## Panel Analyses',
    '',
    analysisBlock,
    '',
    '---',
    '',
    'Synthesize the single best answer grounded in the analyses above.',
  ].join('\n');
}

// ── Telemetry ─────────────────────────────────────────────────────────────────
//
// Reuses the A0 shape: {event, gen_ai.usage.total_tokens, cost_usd, ...}
// Never blocks execution — all failures swallowed.

function recordTelemetry(sessionId, panel, synthVoice, dropped, costUsd, durationMs) {
  try {
    if (!fs.existsSync(TELEMETRY_DIR)) fs.mkdirSync(TELEMETRY_DIR, { recursive: true });
    const record = {
      event: 'fusion',
      ts: new Date().toISOString(),
      session_id: sessionId,
      panel: panel.map(v => ({ id: v.id, family: v.family })),
      synthesizer: { id: synthVoice.id, family: synthVoice.family },
      dropped: dropped.map(d => ({ id: d.voice.id, reason: d.reason })),
      'gen_ai.usage.total_tokens': null,  // not measurable across heterogeneous CLIs
      cost_usd: costUsd,
      duration_ms: durationMs,
    };
    const file = path.join(TELEMETRY_DIR, `${sessionId}.jsonl`);
    fs.appendFileSync(file, JSON.stringify(record) + '\n', 'utf8');
  } catch {
    // Telemetry must never break a gate.
  }
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  const startMs = Date.now();
  const sessionId = process.env.SIGMA_SESSION_ID || `fusion-${randomUUID().slice(0, 8)}`;

  // 0. OpenRouter Fusion backend (opt-in). Falls through to the BYO panel on any
  //    failure so an external paid dep can never hard-fail the run.
  if (backend === 'openrouter') {
    // Opt-in gate: respect the provider config as policy. A config that did NOT
    // opt into OpenRouter must not silently trigger a paid hosted call — even if
    // OPENROUTER_API_KEY is in the env (e.g. via FUSION_BACKEND). No config at
    // all = no policy = honor the explicit flag.
    const cfg = loadProviderConfig();
    const optedIn = !cfg || cfg.apiKeys?.openrouter?.enabled === true;
    if (!optedIn) {
      console.error('fusion: --backend openrouter requested, but providers.config.json has not opted into OpenRouter (apiKeys.openrouter.enabled=false). Run `node scripts/fusion/setup-providers.mjs --api-keys openrouter` to enable. Falling back to BYO.');
    } else {
      const r = await runOpenRouterFusion(taskContent);
      if (r) {
        const durationMs = Date.now() - startMs;
        const orVoice = { id: 'openrouter-fusion', family: 'openrouter' };
        recordTelemetry(sessionId, [orVoice], orVoice, [], r.costUsd, durationMs);
        if (jsonMode) {
          process.stdout.write(JSON.stringify({
            answer: r.answer,
            panel: [orVoice],
            synthesizer: orVoice,
            dropped: [],
            families: ['openrouter'],
            single_model_degrade: false,
            cost: r.costUsd ?? null,
            backend: 'openrouter',
          }, null, 2) + '\n');
        } else {
          console.log('\n' + '─'.repeat(60));
          console.log('FUSION ANSWER (OpenRouter Fusion backend)');
          console.log('─'.repeat(60));
          console.log(r.answer);
          console.log('─'.repeat(60));
          console.log(`Backend: openrouter (${process.env.OPENROUTER_FUSION_MODEL || 'openrouter/fusion'})  Duration: ${durationMs}ms`);
        }
        return;
      }
      console.error('fusion: openrouter backend unavailable — falling back to the BYO panel.');
    }
  }

  // 1. Load providers (runs detect-providers.mjs if cache absent).
  let allVoices = await loadProviders();

  if (allVoices.length === 0) {
    console.error('fusion: no voices available. Run `node scripts/fusion/detect-providers.mjs` first, or install a CLI (codex, claude).');
    process.exit(1);
  }

  // 2. Select panel.
  const panelVoices = selectPanel(allVoices);

  if (panelVoices.length === 0) {
    console.error('fusion: panel selection produced 0 voices. Check --panel argument or provider availability.');
    process.exit(1);
  }

  // 3. Select synthesizer (may overlap with panel — that is fine).
  const synthVoice = selectSynthesizer(allVoices, panelVoices);

  // 4. Build analysis prompt (the task as-is — voices analyze the raw task).
  const analysisPrompt = taskContent;

  // 5. Run panel in parallel.
  if (!jsonMode) {
    console.log(`\nfusion: panel [${panelVoices.map(v => v.id).join(', ')}] → synthesizer [${synthVoice.id}]`);
    console.log(`fusion: analyzing task in parallel (timeout ${timeoutMs}ms)...`);
  }

  const panelResults = await Promise.allSettled(
    panelVoices.map(voice =>
      invokeVoice(voice, analysisPrompt, voice.id)
        .then(output => ({ voice, output }))
    )
  );

  const succeeded = [];
  const dropped   = [];

  for (let i = 0; i < panelVoices.length; i++) {
    const r = panelResults[i];
    const voice = panelVoices[i];
    if (r.status === 'fulfilled') {
      succeeded.push(r.value);
    } else {
      // Redact secrets, then bound length — a failed CLI can echo the whole
      // prompt into its error; don't bloat stderr/telemetry/--json with it.
      const reason = redactSecrets(r.reason?.message || String(r.reason)).slice(0, 300);
      console.warn(`fusion: voice '${voice.id}' dropped — ${reason}`);
      dropped.push({ voice, reason });
    }
  }

  // 6. Graceful degradation check.
  const isSingleModel = succeeded.length < MIN_PANEL_SIZE;

  if (succeeded.length === 0) {
    console.error('fusion: all panel voices failed. Cannot synthesize.');
    process.exit(1);
  }

  if (isSingleModel) {
    console.warn(
      `fusion: WARNING — only ${succeeded.length} voice(s) responded (need ≥${MIN_PANEL_SIZE} for true fusion). ` +
      `Degrading to single-model response from '${succeeded[0].voice.id}'. No fusion guarantee.`
    );
  }

  // 7. Synthesize.
  if (!jsonMode) {
    console.log(`fusion: synthesizing with '${synthVoice.id}'...`);
  }

  const synthPrompt = buildSynthPrompt(taskContent, succeeded);

  // Write synth prompt to temp file — same injection-safe pattern as panel.
  const synthTmpFile = path.join(
    process.env.TMPDIR || '/tmp',
    `fusion-synth-${randomUUID()}.txt`
  );
  let answer = '';
  try {
    fs.writeFileSync(synthTmpFile, synthPrompt, 'utf8');
    const synthCmdRaw = resolveSynthCommand(synthVoice);
    const parts  = synthCmdRaw.trim().split(/\s+/);
    const binary = parts[0];
    let   cliArgs = parts.slice(1);

    let stdinContent = null;
    if (cliArgs[cliArgs.length - 1] === '-') {
      cliArgs = cliArgs.slice(0, -1);
      stdinContent = fs.readFileSync(synthTmpFile, 'utf8');
    } else if (synthVoice.via === 'api') {
      // API synthesizer — route through the API handler.
      answer = await invokeApiVoice(synthVoice, synthPrompt, 'synthesizer');
    } else {
      cliArgs = [...cliArgs, synthTmpFile];
    }

    if (answer === '' && synthVoice.via !== 'api') {
      const opts = { timeout: timeoutMs, maxBuffer: 8 * 1024 * 1024 };
      if (stdinContent !== null) opts.input = stdinContent;
      const { stdout } = await execFileAsync(binary, cliArgs, opts);
      answer = stdout.trim();
    }
  } finally {
    try { fs.unlinkSync(synthTmpFile); } catch {}
  }

  const durationMs = Date.now() - startMs;

  // 8. Record telemetry.
  recordTelemetry(sessionId, succeeded.map(s => s.voice), synthVoice, dropped, null, durationMs);

  // 9. Output.
  const families = [...new Set(succeeded.map(s => s.voice.family))];

  if (jsonMode) {
    const out = {
      answer,
      panel:       succeeded.map(s => ({ id: s.voice.id, family: s.voice.family })),
      synthesizer: { id: synthVoice.id, family: synthVoice.family },
      dropped:     dropped.map(d => ({ id: d.voice.id, reason: d.reason })),
      families,
      single_model_degrade: isSingleModel,
      cost: null,  // not measurable across heterogeneous CLIs
      backend: 'byo',
    };
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
  } else {
    console.log('\n' + '─'.repeat(60));
    console.log('FUSION ANSWER');
    console.log('─'.repeat(60));
    console.log(answer);
    console.log('─'.repeat(60));
    console.log(`Panel: [${succeeded.map(s => s.voice.id).join(', ')}]  Families: [${families.join(', ')}]`);
    console.log(`Synthesizer: ${synthVoice.id}  Duration: ${durationMs}ms`);
    if (dropped.length > 0) {
      console.log(`Dropped: [${dropped.map(d => d.voice.id).join(', ')}]`);
    }
    if (isSingleModel) {
      console.log('WARNING: Single-model degrade — not a true fusion result.');
    }
  }
}

main().catch(err => {
  console.error(`fusion: fatal error — ${redactSecrets(err.message)}`);
  process.exit(1);
});
