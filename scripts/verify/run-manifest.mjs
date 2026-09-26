#!/usr/bin/env node
// run-manifest.mjs — audit-trail recorder for a Sigma run.
//
// Pins EXACTLY what produced a gate verdict or step result: which step prompt
// ran, which artifact was judged, which judge models sat on the panel, which
// gate-logic code versions were active, and what environment the run lived in.
//
// This is a RECORDER (write-only audit), NOT a gate. It never blocks, never
// exits nonzero on content failures. Any gather error → that field is null.
// A manifest must never break a run.
//
// Usage:
//   node scripts/verify/run-manifest.mjs --step <name> [--gate <name>]
//        [--artifact <file>] [--json]
//
//   --step <name>      step name (e.g. step-1-ideation). Required.
//   --gate <name>      gate name: reads .sigma/judge/<gate>.json for panel info
//   --artifact <file>  path to the artifact being pinned; its SHA256 is captured
//   --json             echo the manifest JSON to stdout
//
// Environment overrides (for hermetic tests):
//   SIGMA_MANIFEST_DIR  — write manifests here instead of .sigma/manifests/
//   SIGMA_JUDGE_DIR     — read judge JSON from here instead of .sigma/judge/
//   SIGMA_SESSION_ID    — use as the run-id (otherwise derived from timestamp+sha)

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

// ── Paths (env-overridable for hermetic tests) ───────────────────────────────

const MANIFEST_DIR = process.env.SIGMA_MANIFEST_DIR
  || path.join(REPO_ROOT, '.sigma', 'manifests');

const JUDGE_DIR = process.env.SIGMA_JUDGE_DIR
  || path.join(REPO_ROOT, '.sigma', 'judge');

// Key gate scripts whose SHA256 is pinned so a logic change is detectable.
const GATE_SCRIPTS = [
  path.join(REPO_ROOT, '.claude', 'hooks', 'step-verify-gate.cjs'),
  path.join(REPO_ROOT, 'scripts', 'fusion', 'fusion.mjs'),
];

// ── Argument parsing ─────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2);
const flag = (n) => {
  const i = rawArgs.indexOf(n);
  return i >= 0 ? rawArgs[i + 1] : undefined;
};
const has = (n) => rawArgs.includes(n);

const stepName    = flag('--step');
const gateName    = flag('--gate');
const artifactArg = flag('--artifact');
const jsonMode    = has('--json');

if (!stepName) {
  console.error('run-manifest: --step <name> is required');
  process.exit(1);
}

// ── SHA256 helper — fail-soft, returns null on any error ────────────────────

function sha256File(filePath) {
  try {
    const buf = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(buf).digest('hex');
  } catch {
    return null;
  }
}

function sha256Buf(buf) {
  try {
    return crypto.createHash('sha256').update(buf).digest('hex');
  } catch {
    return null;
  }
}

// ── Gather: step ─────────────────────────────────────────────────────────────
// The canonical step file lives at steps/<stepName> (no extension — matches
// the dir listing we verified: step-1-ideation, step-2-architecture, …).

let stepInfo = null;
try {
  const stepFile = path.join(REPO_ROOT, 'steps', stepName);
  const stepHash = sha256File(stepFile);
  stepInfo = {
    name: stepName,
    file: fs.existsSync(stepFile) ? path.relative(REPO_ROOT, stepFile) : null,
    sha256: stepHash,
  };
} catch {
  stepInfo = { name: stepName, file: null, sha256: null };
}

// ── Gather: artifact ─────────────────────────────────────────────────────────

let artifactInfo = null;
if (artifactArg) {
  try {
    const resolved = path.resolve(artifactArg);
    const hash = sha256File(resolved);
    artifactInfo = {
      path: resolved,
      relative: fs.existsSync(resolved) ? path.relative(REPO_ROOT, resolved) : artifactArg,
      sha256: hash,
    };
  } catch {
    artifactInfo = { path: artifactArg, relative: artifactArg, sha256: null };
  }
}

// ── Gather: judge panel ───────────────────────────────────────────────────────
// Reads .sigma/judge/<gate>.json (written by step-judge.mjs).
// Fields consumed: panel (voice id/family), synthesizer id/family, families[].

let judgeInfo = null;
if (gateName) {
  try {
    const judgeFile = path.join(JUDGE_DIR, `${gateName}.json`);
    if (fs.existsSync(judgeFile)) {
      const raw = JSON.parse(fs.readFileSync(judgeFile, 'utf8'));
      judgeInfo = {
        gate: gateName,
        panel: Array.isArray(raw.panel) ? raw.panel.map(v => ({
          id: v.id ?? null,
          family: v.family ?? null,
        })) : null,
        synthesizer: raw.synthesizer
          ? { id: raw.synthesizer.id ?? null, family: raw.synthesizer.family ?? null }
          : null,
        families: Array.isArray(raw.families) ? raw.families : null,
        crossFamily: raw.crossFamily ?? null,
        status: raw.status ?? null,
        advisory: raw.advisory ?? null,
      };
    } else {
      judgeInfo = { gate: gateName, panel: null, synthesizer: null, families: null,
        crossFamily: null, status: null, advisory: null };
    }
  } catch {
    judgeInfo = { gate: gateName, panel: null, synthesizer: null, families: null,
      crossFamily: null, status: null, advisory: null };
  }
}

// ── Gather: code provenance ───────────────────────────────────────────────────
// git HEAD commit (fail-soft → null if not a git repo).
// SHA256 of the two key gate scripts.

let codeInfo = null;
try {
  let gitCommit = null;
  try {
    gitCommit = execFileSync('git', ['rev-parse', 'HEAD'], {
      cwd: REPO_ROOT,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    gitCommit = null;
  }

  const scripts = {};
  for (const scriptPath of GATE_SCRIPTS) {
    const rel = path.relative(REPO_ROOT, scriptPath);
    scripts[rel] = sha256File(scriptPath);
  }

  codeInfo = { git_commit: gitCommit, scripts };
} catch {
  codeInfo = { git_commit: null, scripts: {} };
}

// ── Gather: environment ───────────────────────────────────────────────────────

const envInfo = {
  node_version: process.version,
  timestamp: new Date().toISOString(),
  platform: process.platform,
};

// ── Derive run-id ─────────────────────────────────────────────────────────────
// SIGMA_SESSION_ID if set, otherwise sha-prefix of step+timestamp.

let runId = process.env.SIGMA_SESSION_ID || null;
if (!runId) {
  const raw = `${stepName}:${envInfo.timestamp}`;
  runId = sha256Buf(Buffer.from(raw)).slice(0, 16);
}

// ── Assemble manifest ─────────────────────────────────────────────────────────

const manifest = {
  run_id: runId,
  step: stepInfo,
  artifact: artifactInfo,
  judge: judgeInfo,
  code: codeInfo,
  env: envInfo,
};

// ── Write manifest ────────────────────────────────────────────────────────────
// Fail-open: a write error is logged but never throws and never exits nonzero.

try {
  if (!fs.existsSync(MANIFEST_DIR)) {
    fs.mkdirSync(MANIFEST_DIR, { recursive: true });
  }
  const outFile = path.join(MANIFEST_DIR, `${runId}.json`);
  fs.writeFileSync(outFile, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
} catch (e) {
  // Log but do not throw — a manifest write must never break a run.
  process.stderr.write(`run-manifest: warning: could not write manifest — ${e.message}\n`);
}

// ── Output ────────────────────────────────────────────────────────────────────

if (jsonMode) {
  process.stdout.write(JSON.stringify(manifest, null, 2) + '\n');
} else {
  const stepHash = stepInfo && stepInfo.sha256 ? stepInfo.sha256.slice(0, 12) : 'null';
  const commit = codeInfo && codeInfo.git_commit ? codeInfo.git_commit.slice(0, 10) : 'null';
  const panel = judgeInfo && judgeInfo.families ? `[${judgeInfo.families.join(', ')}]` : 'n/a';
  console.log(`run-manifest[${runId}]: step=${stepName} sha=${stepHash} commit=${commit} panel=${panel}`);
}

// Always exit 0 — this is a recorder, not a gate.
process.exit(0);
