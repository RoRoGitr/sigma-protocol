#!/usr/bin/env node
// detect-providers.mjs — emit JSON array of available fusion voices.
//
// A voice is AVAILABLE if:
//   - its CLI binary is on PATH (via `command -v`), OR
//   - its API key env var is set
//
// CLI voices are reached through the installed CLI's own auth — no keys needed.
// API voices are opt-in extras (OPENROUTER_API_KEY, MINIMAX_API_KEY, ZHIPUAI_API_KEY).
//
// Usage:
//   node scripts/fusion/detect-providers.mjs [--json] [--no-cache]
//
//   --json      : print JSON array to stdout (default: human-readable table)
//   --no-cache  : skip reading/writing .sigma/providers.json
//
// Output shape per voice:
//   { id, family, via: "cli"|"api", invoke, cost_tier }
//
// Cache: .sigma/providers.json (gitignored — contains no secrets, only availability)

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const CACHE_PATH = path.join(REPO_ROOT, '.sigma', 'providers.json');

// ── Argument parsing ────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const jsonMode = args.includes('--json');
const noCache  = args.includes('--no-cache');

// ── CLI availability check ──────────────────────────────────────────────────

/**
 * Returns true if `binaryName` is on PATH.
 * Uses /usr/bin/which via execFileSync — no shell, no injection surface.
 * Falls back to /bin/which if the primary path doesn't exist.
 */
function cliOnPath(binaryName) {
  // Allowlist: only alphanumeric + hyphen binary names are accepted.
  // This is a defense-in-depth check; the VOICE_DEFS above use only safe literals.
  if (!/^[a-z0-9-]+$/i.test(binaryName)) return false;
  const whichBins = ['/usr/bin/which', '/bin/which'];
  for (const whichBin of whichBins) {
    try {
      execFileSync(whichBin, [binaryName], { stdio: 'ignore' });
      return true;
    } catch {
      // try next
    }
  }
  return false;
}

// ── Voice definitions ───────────────────────────────────────────────────────
//
// Each definition describes one potential voice.
// `available()` is called at runtime to decide inclusion.
// `invoke` is the command the fusion engine will use to call this voice
//   (template — fusion.mjs substitutes the actual task).
// `cost_tier`: "free" | "low" | "medium" | "high"

const VOICE_DEFS = [
  // ── CLI voices ────────────────────────────────────────────────────────────
  {
    id: 'claude',
    family: 'anthropic',
    via: 'cli',
    // Pass task via stdin so no shell interpolation of task content.
    invoke: 'claude --print -',
    cost_tier: 'high',
    available: () => cliOnPath('claude'),
  },
  {
    id: 'codex',
    family: 'openai',
    via: 'cli',
    // codex exec with read-only sandbox; task piped via stdin.
    // --skip-git-repo-check: fusion runs from repo root but the voice is
    // analyzing an artifact, not a repo.
    invoke: 'codex exec -m gpt-5.5 -s read-only --skip-git-repo-check -',
    cost_tier: 'high',
    available: () => cliOnPath('codex'),
  },
  // ── API voices (opt-in, BYO key) ─────────────────────────────────────────
  {
    id: 'openrouter',
    family: 'openrouter',
    via: 'api',
    // Endpoint: https://openrouter.ai/api/v1/chat/completions
    // Model: openrouter default (auto-routes to best available).
    invoke: 'OPENROUTER_API',
    cost_tier: 'medium',
    available: () => Boolean(process.env.OPENROUTER_API_KEY),
  },
  {
    id: 'minimax',
    family: 'minimax',
    via: 'api',
    // MiniMax is Anthropic-SDK-compatible: base_url=https://api.minimax.io/anthropic
    invoke: 'MINIMAX_API',
    cost_tier: 'low',
    available: () => Boolean(process.env.MINIMAX_API_KEY),
  },
  {
    id: 'glm',
    family: 'zhipu',
    via: 'api',
    // GLM-4.7-Flash — ZhipuAI, free tier available.
    invoke: 'ZHIPUAI_API',
    cost_tier: 'free',
    available: () => Boolean(process.env.ZHIPUAI_API_KEY),
  },
];

// ── Build available voice list ──────────────────────────────────────────────

function detectProviders() {
  const voices = [];
  for (const def of VOICE_DEFS) {
    if (def.available()) {
      voices.push({
        id:        def.id,
        family:    def.family,
        via:       def.via,
        invoke:    def.invoke,
        cost_tier: def.cost_tier,
      });
    }
  }
  return voices;
}

// ── Cache ───────────────────────────────────────────────────────────────────

function writeCache(voices) {
  try {
    const dir = path.dirname(CACHE_PATH);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(CACHE_PATH, JSON.stringify(voices, null, 2) + '\n', 'utf8');
  } catch {
    // Cache write failure is non-fatal.
  }
}

// ── Main ────────────────────────────────────────────────────────────────────

const voices = detectProviders();

if (!noCache) {
  writeCache(voices);
}

if (jsonMode) {
  process.stdout.write(JSON.stringify(voices, null, 2) + '\n');
} else {
  if (voices.length === 0) {
    console.log('No voices available. Install a CLI (codex, claude) or set an API key env var.');
    process.exit(0);
  }
  // Human-readable table
  const colW = [16, 12, 6, 8];
  const header = ['ID', 'FAMILY', 'VIA', 'COST'].map((h, i) => h.padEnd(colW[i])).join('  ');
  const sep    = colW.map(w => '-'.repeat(w)).join('  ');
  console.log('\nAvailable fusion voices:');
  console.log(header);
  console.log(sep);
  for (const v of voices) {
    const row = [v.id, v.family, v.via, v.cost_tier].map((c, i) => String(c).padEnd(colW[i])).join('  ');
    console.log(row);
  }
  console.log(`\n${voices.length} voice(s) detected. Cache written to .sigma/providers.json`);
}
