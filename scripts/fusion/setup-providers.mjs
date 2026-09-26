#!/usr/bin/env node
// setup-providers.mjs — write the canonical fusion provider CONFIG.
//
// This is the engine behind Step-0 Phase B.2 (the interactive provider-setup
// HARD-GATE). The Step-0 gate gathers the user's choices via AskUserQuestion,
// then calls this script with flags. It is also directly runnable.
//
// CONFIG vs CACHE — two distinct files, do not confuse them:
//   .sigma/providers.json         (ARRAY)  — detect-providers.mjs cache of what
//                                            is AVAILABLE on this machine.
//   .sigma/providers.config.json  (OBJECT) — THIS file's output: which voices
//                                            the user ENABLED + the synthesizer
//                                            default + which API-key ENV-VAR
//                                            NAMES to expect. fusion.mjs reads it.
//
// SECURITY (SECURITY.md): this file stores env-var NAMES only — NEVER secret
// values. Inputs are validated to be lowercase ids; anything that looks like a
// key (long / contains key-ish chars) is REFUSED, so a secret cannot be written
// even by accident.
//
// Usage:
//   node scripts/fusion/setup-providers.mjs [--enable <ids>] [--synthesizer <id>]
//        [--api-keys <ids>] [--detected-file <path>] [--no-detect] [--json]
//
//   --enable <ids>       comma-separated voice ids to enable
//                        (claude,codex,openrouter,minimax,glm).
//                        If omitted, defaults to all currently-detected voices.
//   --synthesizer <id>   default synthesizer voice id (must be in the enabled set).
//   --api-keys <ids>     comma-separated API providers to mark enabled
//                        (openrouter,minimax,glm) — records the ENV-VAR NAME only.
//   --detected-file <p>  read the detected-voices array from this JSON file
//                        instead of running detect-providers (tests / CI).
//   --no-detect          do not run detect-providers; rely on --enable only.
//   --json               print the written config to stdout.
//
// Env equivalents (flags win): SIGMA_PROVIDERS_ENABLE, SIGMA_PROVIDERS_SYNTH,
//   SIGMA_PROVIDERS_API_KEYS, SIGMA_PROVIDERS_DETECTED_FILE,
//   SIGMA_PROVIDERS_CONFIG_PATH (override output path — tests).

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

const CONFIG_PATH = process.env.SIGMA_PROVIDERS_CONFIG_PATH ||
  path.join(REPO_ROOT, '.sigma', 'providers.config.json');

// ── Known voices / API key name mapping (single source of truth) ─────────────

const CLI_VOICE_IDS = ['claude', 'codex'];
const API_KEY_ENV = {
  openrouter: 'OPENROUTER_API_KEY',
  minimax:    'MINIMAX_API_KEY',
  glm:        'ZHIPUAI_API_KEY',
};
const API_VOICE_IDS = Object.keys(API_KEY_ENV);
const ALL_KNOWN_IDS = new Set([...CLI_VOICE_IDS, ...API_VOICE_IDS]);

// A valid id is a short lowercase token. A secret will not match this, so we
// can never persist one: validation rejects the input before it is written.
const ID_RE = /^[a-z0-9-]{1,24}$/;

// ── Argument parsing ──────────────────────────────────────────────────────────

const args = process.argv.slice(2);
function flag(name) {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
}
const hasFlag = (name) => args.includes(name);

const enableRaw  = flag('--enable')       ?? process.env.SIGMA_PROVIDERS_ENABLE;
const synthRaw   = flag('--synthesizer')  ?? process.env.SIGMA_PROVIDERS_SYNTH;
const apiKeysRaw = flag('--api-keys')     ?? process.env.SIGMA_PROVIDERS_API_KEYS;
const detectedFile = flag('--detected-file') ?? process.env.SIGMA_PROVIDERS_DETECTED_FILE;
const noDetect   = hasFlag('--no-detect');
const jsonMode   = hasFlag('--json');

// ── Helpers ───────────────────────────────────────────────────────────────────

function die(msg) {
  console.error(`setup-providers: ${msg}`);
  process.exit(1);
}

/**
 * Parse a comma-separated id list and validate every token.
 * REFUSES any token that is not a known lowercase id — this is the guard that
 * makes it impossible to write a secret value into the config.
 */
function parseIds(raw, label) {
  if (!raw) return [];
  const tokens = String(raw).split(',').map(s => s.trim()).filter(Boolean);
  const out = [];
  for (const t of tokens) {
    if (!ID_RE.test(t)) {
      // Never echo any of the rejected token — it may be a pasted secret.
      die(`refusing an invalid ${label} value (${t.length} chars): not a known provider id. ` +
          `Pass provider IDS only (e.g. claude,codex) — never key values. Config stores env-var NAMES only.`);
    }
    if (!ALL_KNOWN_IDS.has(t)) {
      // Known ids are all <=13 chars; echo short typos for UX, but redact a
      // longer token (could be a pasted short secret that slipped past ID_RE).
      const shown = t.length > 16 ? `(${t.length} chars)` : `"${t}"`;
      die(`unknown ${label} id ${shown}. Known: ${[...ALL_KNOWN_IDS].join(', ')}.`);
    }
    if (!out.includes(t)) out.push(t);
  }
  return out;
}

/** Get the detected-voices array (from file, or by running detect-providers). */
function getDetected() {
  if (detectedFile) {
    try {
      const parsed = JSON.parse(fs.readFileSync(detectedFile, 'utf8'));
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  if (noDetect) return [];
  try {
    const detectPath = path.join(__dirname, 'detect-providers.mjs');
    const stdout = execFileSync(process.execPath, [detectPath, '--json', '--no-cache'],
      { timeout: 10_000, encoding: 'utf8' });
    const parsed = JSON.parse(stdout);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

// ── Build the config ────────────────────────────────────────────────────────────

const detected = getDetected();
const detectedIds = detected.map(v => v && v.id).filter(Boolean);

// enabledVoices: explicit --enable, else all detected CLI voices.
// API voices are opt-in via --api-keys ONLY — a key merely being present in the
// env must never auto-enable a paid voice (keeps enabledVoices consistent with
// apiKeys.<id>.enabled). enabledVoices is the authoritative allow-list fusion reads.
let enabledVoices = parseIds(enableRaw, 'enable');
if (enabledVoices.length === 0) {
  enabledVoices = detectedIds.filter(id => CLI_VOICE_IDS.includes(id));
}
if (enabledVoices.length === 0) {
  die('no voices to enable. Pass --enable <ids> or run detect-providers first ' +
      '(install a CLI: codex, claude).');
}

// api-keys: which API providers the user wants enabled (records env-var NAME only).
const apiKeyIds = parseIds(apiKeysRaw, 'api-keys');
for (const id of apiKeyIds) {
  if (!API_VOICE_IDS.includes(id)) {
    die(`--api-keys "${id}" is not an API provider. API providers: ${API_VOICE_IDS.join(', ')}.`);
  }
  // Enabling an API key implies enabling that voice.
  if (!enabledVoices.includes(id)) enabledVoices.push(id);
}

// synthesizer: explicit, else prefer claude / an enabled anthropic-ish CLI, else first enabled.
let synthesizer = synthRaw ? parseIds(synthRaw, 'synthesizer')[0] : null;
if (synthesizer && !enabledVoices.includes(synthesizer)) {
  console.error(`setup-providers: synthesizer "${synthesizer}" is not in the enabled set ` +
                `(${enabledVoices.join(', ')}); falling back to the default.`);
  synthesizer = null;
}
if (!synthesizer) {
  synthesizer = enabledVoices.includes('claude') ? 'claude' : enabledVoices[0];
}

// apiKeys block: env-var NAME + whether the user opted in. NEVER a value.
const apiKeys = {};
for (const id of API_VOICE_IDS) {
  apiKeys[id] = { envVar: API_KEY_ENV[id], enabled: apiKeyIds.includes(id) };
}

const config = {
  version: 1,
  generatedBy: 'setup-providers.mjs',
  updatedAt: new Date().toISOString(),
  enabledVoices,
  synthesizer,
  apiKeys,
  detectedSnapshot: detectedIds,
  note: 'env-var NAMES only — never secret values (SECURITY.md). CLI voices need no key.',
};

// ── Write ───────────────────────────────────────────────────────────────────────

try {
  const dir = path.dirname(CONFIG_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2) + '\n', 'utf8');
} catch (err) {
  die(`could not write config to ${CONFIG_PATH}: ${err.message}`);
}

// Informational: enabled CLI voices that are not currently detected.
const undetected = enabledVoices.filter(id =>
  CLI_VOICE_IDS.includes(id) && !detectedIds.includes(id));
if (undetected.length > 0) {
  console.error(`setup-providers: note — enabled but not detected on this machine: ` +
                `${undetected.join(', ')} (the CLI is not on PATH yet).`);
}

if (jsonMode) {
  process.stdout.write(JSON.stringify(config, null, 2) + '\n');
} else {
  console.log(`Wrote ${path.relative(REPO_ROOT, CONFIG_PATH)}`);
  console.log(`  enabled:     ${enabledVoices.join(', ')}`);
  console.log(`  synthesizer: ${synthesizer}`);
  const onKeys = apiKeyIds.length ? apiKeyIds.map(id => `${id} (${API_KEY_ENV[id]})`).join(', ') : 'none';
  console.log(`  api keys:    ${onKeys}`);
}
