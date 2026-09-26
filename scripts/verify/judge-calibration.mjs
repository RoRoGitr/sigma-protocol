#!/usr/bin/env node
// judge-calibration.mjs — gate the C2 judge's advisory→blocking flip on real data.
//
// A judge may only BLOCK autonomously once it is CALIBRATED against a labeled
// golden set drawn from HITL overrides (zero new human burden — every time the
// operator disagrees with a judge verdict, that disagreement is a labeled
// example). Calibration bar (all must hold):
//   n >= 40 · >=15 positive (human=FAIL) · >=15 negative (human=PASS)
//   balanced-accuracy >= 0.85 · true-negative-rate (TNR) >= 0.80
//   every example cross-family (reviewer_family != implementer_family)
//
// Positive class = "FAIL" (the judge's job is to DETECT bad artifacts):
//   TP judge=FAIL,human=FAIL · FN judge=PASS,human=FAIL (dangerous: missed a bad one)
//   FP judge=FAIL,human=PASS (over-strict) · TN judge=PASS,human=PASS
//   TNR = TN/(TN+FP)  — the "don't cry wolf on good work" guard
//   TPR = TP/(TP+FN)  — recall on real failures
//
// Two modes:
//   compute (default):  node judge-calibration.mjs --gate <name> [--json]
//   record a label:     node judge-calibration.mjs --record --gate <name> \
//                          --artifact <file> --judge <PASS|FAIL> --human <PASS|FAIL> \
//                          --reviewer-family <fam> --implementer-family <fam>
//
// Files (env SIGMA_CALIBRATION_DIR overrides the base for tests):
//   golden: <base>/golden/<gate>.jsonl   report: <base>/<gate>.json
//
// NEVER fabricates calibration: an empty/thin golden set → calibrated:false.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const BASE = process.env.SIGMA_CALIBRATION_DIR || path.join(REPO_ROOT, '.sigma', 'calibration');
const GOLDEN_DIR = path.join(BASE, 'golden');

// Thresholds (env-overridable for hermetic tests).
const MIN_N         = Number(process.env.JUDGE_CAL_MIN_N || 40);
const MIN_PER_CLASS = Number(process.env.JUDGE_CAL_MIN_PER_CLASS || 15);
const MIN_BAL_ACC   = Number(process.env.JUDGE_CAL_MIN_BAL_ACC || 0.85);
const MIN_TNR       = Number(process.env.JUDGE_CAL_MIN_TNR || 0.80);

// ── Args ──────────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const flag = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
const has = (n) => args.includes(n);
const gate = flag('--gate');
const jsonMode = has('--json');
function die(m) { console.error(`judge-calibration: ${m}`); process.exit(2); }
if (!gate || !/^[A-Za-z0-9._-]{1,64}$/.test(gate)) die('--gate <name> required (safe id)');

const goldenPath = path.join(GOLDEN_DIR, `${gate}.jsonl`);

// ── Record mode: append a labeled example (HITL override capture) ─────────────
if (has('--record')) {
  const artifact = flag('--artifact');
  const judge = (flag('--judge') || '').toUpperCase();
  const human = (flag('--human') || '').toUpperCase();
  const rf = flag('--reviewer-family');
  const impf = flag('--implementer-family');
  if (!artifact || !fs.existsSync(artifact)) die('--artifact <existing file> required');
  if (!['PASS', 'FAIL'].includes(judge)) die('--judge must be PASS or FAIL');
  if (!['PASS', 'FAIL'].includes(human)) die('--human must be PASS or FAIL');
  for (const [k, v] of [['--reviewer-family', rf], ['--implementer-family', impf]]) {
    if (!v || !/^[a-z0-9-]{1,24}$/.test(v)) die(`${k} must be a lowercase family id`);
  }
  const hash = crypto.createHash('sha256').update(fs.readFileSync(artifact)).digest('hex');
  const rec = {
    gate, artifact_hash: hash, judge_verdict: judge, human_label: human,
    reviewer_family: rf, implementer_family: impf,
    cross_family: rf !== impf, ts: new Date().toISOString(),
  };
  try {
    if (!fs.existsSync(GOLDEN_DIR)) fs.mkdirSync(GOLDEN_DIR, { recursive: true });
    fs.appendFileSync(goldenPath, JSON.stringify(rec) + '\n', 'utf8');
  } catch (e) { die(`could not append golden example: ${e.message}`); }
  console.log(`judge-calibration[${gate}]: recorded label (judge=${judge} human=${human} cross_family=${rec.cross_family})`);
  process.exit(0);
}

// ── Compute mode: read golden set → metrics → calibrated decision ─────────────
function readGolden() {
  if (!fs.existsSync(goldenPath)) return { rows: [], malformed: 0 };
  const rows = [], lines = fs.readFileSync(goldenPath, 'utf8').split('\n');
  let malformed = 0;
  for (const ln of lines) {
    const t = ln.trim();
    if (!t) continue;
    try {
      const r = JSON.parse(t);
      if (['PASS', 'FAIL'].includes(r.judge_verdict) && ['PASS', 'FAIL'].includes(r.human_label)) rows.push(r);
      else malformed++;
    } catch { malformed++; }
  }
  return { rows, malformed };
}

const { rows, malformed } = readGolden();
let TP = 0, FN = 0, FP = 0, TN = 0;
let allCrossFamily = rows.length > 0;
for (const r of rows) {
  if (r.cross_family === false || (r.reviewer_family && r.implementer_family && r.reviewer_family === r.implementer_family)) allCrossFamily = false;
  if (r.human_label === 'FAIL') { if (r.judge_verdict === 'FAIL') TP++; else FN++; }
  else { if (r.judge_verdict === 'FAIL') FP++; else TN++; }
}
const n = rows.length;
const pos = TP + FN;   // actual failures
const neg = TN + FP;   // actual passes
const tpr = pos > 0 ? TP / pos : null;
const tnr = neg > 0 ? TN / neg : null;
const balAcc = (tpr !== null && tnr !== null) ? (tpr + tnr) / 2 : null;

const reasons = [];
if (n < MIN_N) reasons.push(`n=${n} < ${MIN_N}`);
if (pos < MIN_PER_CLASS) reasons.push(`positives=${pos} < ${MIN_PER_CLASS}`);
if (neg < MIN_PER_CLASS) reasons.push(`negatives=${neg} < ${MIN_PER_CLASS}`);
if (balAcc === null || balAcc < MIN_BAL_ACC) reasons.push(`balAcc=${balAcc === null ? 'n/a' : balAcc.toFixed(3)} < ${MIN_BAL_ACC}`);
if (tnr === null || tnr < MIN_TNR) reasons.push(`TNR=${tnr === null ? 'n/a' : tnr.toFixed(3)} < ${MIN_TNR}`);
if (!allCrossFamily) reasons.push('not all examples are cross-family');
const calibrated = reasons.length === 0;

const report = {
  gate, calibrated,
  n, positives: pos, negatives: neg, malformed,
  confusion: { TP, FN, FP, TN },
  tpr: tpr === null ? null : Number(tpr.toFixed(4)),
  tnr: tnr === null ? null : Number(tnr.toFixed(4)),
  balanced_accuracy: balAcc === null ? null : Number(balAcc.toFixed(4)),
  cross_family: allCrossFamily,
  thresholds: { MIN_N, MIN_PER_CLASS, MIN_BAL_ACC, MIN_TNR },
  blocking_reason: calibrated ? '' : `advisory — ${reasons.join('; ')}`,
  updated_at: new Date().toISOString(),
};

try {
  if (!fs.existsSync(BASE)) fs.mkdirSync(BASE, { recursive: true });
  fs.writeFileSync(path.join(BASE, `${gate}.json`), JSON.stringify(report, null, 2) + '\n', 'utf8');
} catch { /* report write must never throw the gate */ }

if (jsonMode) {
  process.stdout.write(JSON.stringify(report, null, 2) + '\n');
} else {
  console.log(`judge-calibration[${gate}]: ${calibrated ? 'CALIBRATED (may block)' : 'NOT calibrated (advisory)'}`);
  console.log(`  n=${n} (pos=${pos}/neg=${neg}) balAcc=${report.balanced_accuracy ?? 'n/a'} TNR=${report.tnr ?? 'n/a'} cross-family=${allCrossFamily}`);
  if (!calibrated) console.log(`  ${report.blocking_reason}`);
}
process.exit(0);
