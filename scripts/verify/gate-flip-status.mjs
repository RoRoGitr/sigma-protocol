#!/usr/bin/env node
// gate-flip-status.mjs — operationalizes the advisory→blocking flip contract.
//
// The flip contract (from the program's flip doctrine):
//
//   DETERMINISTIC gates (anti_slop, ui_validation, step-verify assertions
//   incl. craft_antislop/dna_conformance, security deterministic slice):
//     Flip-eligible when the A5 firing-canary shows the gate fired on
//     >=10 eligible runs with <=5% false-positive rate.
//
//   JUDGE gates (gap_analysis, cross_model_review, C2 step-judge):
//     Flip-eligible ONLY when their calibration report says calibrated:true
//     (bal-acc>=0.85, TNR>=0.80, n>=40, cross-family).
//
//   NEVER recommend flipping without the data.
//   Thin data → "NOT eligible — needs N more clean fires" / "NOT calibrated".
//
// Modes:
//   (default)  node gate-flip-status.mjs             — human summary table
//   --json     node gate-flip-status.mjs --json       — machine output
//   --record-fp --gate <g>
//              node gate-flip-status.mjs --record-fp --gate anti_slop
//              Appends a false-positive label to the FP log.
//
// Data sources:
//   SIGMA_TELEMETRY_DIR  (default .sigma/telemetry/sessions/)  — gate_fired events
//   SIGMA_FLIP_DIR       (default .sigma/flip/)                 — false-positives.jsonl
//   SIGMA_CALIBRATION_DIR (default .sigma/calibration/)        — <gate>.json for judge gates
//
// Thresholds (env-overridable for hermetic tests):
//   FLIP_MIN_FIRES=10   minimum eligible fires
//   FLIP_MAX_FP_RATE=0.05  maximum false-positive rate (5%)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

// ── Path resolution (env-overridable for hermetic tests) ─────────────────────

const TELEMETRY_DIR = process.env.SIGMA_TELEMETRY_DIR
  || path.join(REPO_ROOT, '.sigma', 'telemetry', 'sessions');

const CALIBRATION_DIR = process.env.SIGMA_CALIBRATION_DIR
  || path.join(REPO_ROOT, '.sigma', 'calibration');

const FLIP_DIR = process.env.SIGMA_FLIP_DIR
  || path.join(REPO_ROOT, '.sigma', 'flip');

const FP_LOG = path.join(FLIP_DIR, 'false-positives.jsonl');

// ── Thresholds ────────────────────────────────────────────────────────────────

const FLIP_MIN_FIRES   = Number(process.env.FLIP_MIN_FIRES   || 10);
const FLIP_MAX_FP_RATE = Number(process.env.FLIP_MAX_FP_RATE || 0.05);

// ── Gate classification ───────────────────────────────────────────────────────
// Deterministic: gate behaviour is rule-based; FP rate is the eligibility bar.
// Judge: gate uses an LLM judge; calibration report is the eligibility bar.

const GATE_TIERS = {
  anti_slop:         'deterministic',
  ui_validation:     'deterministic',
  devils_advocate:   'judge',
  gap_analysis:      'judge',
  qa_verification:   'judge',
  cross_model_review:'judge',
  greptile_score:    'deterministic',
};

// All 7 pipeline gates (the canonical list from pipeline-gate.sh).
const ALL_GATES = Object.keys(GATE_TIERS);

// ── Arg parsing ───────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const has  = (f) => args.includes(f);
const flag = (f) => { const i = args.indexOf(f); return i >= 0 ? args[i + 1] : undefined; };

const JSON_MODE     = has('--json');
const RECORD_FP     = has('--record-fp');
const GATE_ARG      = flag('--gate');

// ── Helpers ───────────────────────────────────────────────────────────────────

function readJsonlFile(filePath) {
  if (!fs.existsSync(filePath)) return [];
  const lines = [];
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    for (const line of raw.split('\n')) {
      const t = line.trim();
      if (!t) continue;
      try { lines.push(JSON.parse(t)); } catch { /* skip malformed */ }
    }
  } catch { /* fail-open: return what we have */ }
  return lines;
}

function loadTelemetryEvents() {
  if (!fs.existsSync(TELEMETRY_DIR)) return [];
  const events = [];
  try {
    for (const name of fs.readdirSync(TELEMETRY_DIR)) {
      if (!name.endsWith('.jsonl')) continue;
      events.push(...readJsonlFile(path.join(TELEMETRY_DIR, name)));
    }
  } catch { /* fail-open */ }
  return events;
}

function loadFpLog() {
  return readJsonlFile(FP_LOG);
}

function loadCalibrationReport(gate) {
  const p = path.join(CALIBRATION_DIR, `${gate}.json`);
  if (!fs.existsSync(p)) return null;
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch {
    return null;
  }
}

// ── --record-fp mode ──────────────────────────────────────────────────────────

if (RECORD_FP) {
  if (!GATE_ARG || !ALL_GATES.includes(GATE_ARG)) {
    console.error(`gate-flip-status: --record-fp requires --gate <gate>; valid: ${ALL_GATES.join(', ')}`);
    process.exit(2);
  }
  const record = {
    gate: GATE_ARG,
    ts: new Date().toISOString(),
    operator: process.env.USER || 'unknown',
    note: flag('--note') || null,
  };
  try {
    if (!fs.existsSync(FLIP_DIR)) fs.mkdirSync(FLIP_DIR, { recursive: true });
    fs.appendFileSync(FP_LOG, JSON.stringify(record) + '\n', 'utf8');
    console.log(`gate-flip-status: recorded false-positive for gate '${GATE_ARG}' at ${record.ts}`);
  } catch (e) {
    console.error(`gate-flip-status: failed to write FP log: ${e.message}`);
    process.exit(2);
  }
  process.exit(0);
}

// ── Compute eligibility per gate ──────────────────────────────────────────────

function computeGateStatus(gate, gateFiredEvents, fpCountByGate, errors) {
  const tier = GATE_TIERS[gate];

  if (tier === 'judge') {
    // Judge gates: eligibility is determined solely by the calibration report.
    let calibrated = false;
    let calReport = null;
    try {
      calReport = loadCalibrationReport(gate);
    } catch (e) {
      errors.push(`${gate}: failed to read calibration report: ${e.message}`);
    }

    if (calReport && calReport.calibrated === true) {
      calibrated = true;
    }

    const eligibleToBlock = calibrated;
    let reason;
    if (calibrated) {
      reason = `ELIGIBLE — flip via judge-calibration.mjs --gate ${gate} --enforce`;
    } else if (calReport) {
      reason = `NOT calibrated — ${calReport.blocking_reason || 'calibrated:false'}`;
    } else {
      reason = 'NOT calibrated — no calibration report found; run judge-calibration.mjs';
    }

    return {
      gate,
      tier,
      eligibleToBlock,
      reason,
      // judge-specific details
      calibrated,
      calibration_n: calReport ? (calReport.n || 0) : null,
      calibration_balanced_accuracy: calReport ? calReport.balanced_accuracy : null,
      calibration_tnr: calReport ? calReport.tnr : null,
      // deterministic fields not applicable
      total_fires: null,
      eligible_fires: null,
      fp_count: null,
      fp_rate: null,
    };
  }

  // Deterministic gate: count eligible fires + FP rate.
  // "Eligible fires" = gate_fired events for this gate (any status).
  // We count all fires regardless of status — the canary fires on every run.
  const gateFires = gateFiredEvents.filter(e => e.gate === gate);
  const totalFires = gateFires.length;
  const fpCount = fpCountByGate[gate] || 0;

  // Eligible fires: fires that were not operator-confirmed false positives.
  // Simple model: total fires minus confirmed FPs.
  const eligibleFires = Math.max(0, totalFires - fpCount);
  const fpRate = totalFires > 0 ? fpCount / totalFires : 0;

  const needsMoreFires = eligibleFires < FLIP_MIN_FIRES;
  const fpRateTooHigh  = fpRate > FLIP_MAX_FP_RATE;

  const eligibleToBlock = !needsMoreFires && !fpRateTooHigh;

  let reason;
  if (eligibleToBlock) {
    reason = `ELIGIBLE — flip via STEP_VERIFY_GATE_ENFORCE=1 or <!-- VERIFY-ENFORCE --> in step doc`;
  } else if (needsMoreFires && fpRateTooHigh) {
    const stillNeed = FLIP_MIN_FIRES - eligibleFires;
    reason = `NOT eligible — needs ${stillNeed} more clean fire${stillNeed === 1 ? '' : 's'}; FP-rate ${(fpRate * 100).toFixed(1)}% > ${(FLIP_MAX_FP_RATE * 100).toFixed(0)}%`;
  } else if (needsMoreFires) {
    const stillNeed = FLIP_MIN_FIRES - eligibleFires;
    reason = `NOT eligible — needs ${stillNeed} more clean fire${stillNeed === 1 ? '' : 's'} (${eligibleFires}/${FLIP_MIN_FIRES})`;
  } else {
    reason = `NOT eligible — FP-rate ${(fpRate * 100).toFixed(1)}% > ${(FLIP_MAX_FP_RATE * 100).toFixed(0)}% (${fpCount} FP of ${totalFires} fires)`;
  }

  return {
    gate,
    tier,
    eligibleToBlock,
    reason,
    // deterministic-specific details
    total_fires: totalFires,
    eligible_fires: eligibleFires,
    fp_count: fpCount,
    fp_rate: Number(fpRate.toFixed(4)),
    // judge fields not applicable
    calibrated: null,
    calibration_n: null,
    calibration_balanced_accuracy: null,
    calibration_tnr: null,
  };
}

// ── Main ──────────────────────────────────────────────────────────────────────

const errors = [];

// Load data (fail-open on every step).
let telemetryEvents = [];
try {
  telemetryEvents = loadTelemetryEvents();
} catch (e) {
  errors.push(`telemetry load failed: ${e.message}`);
}

const gateFiredEvents = telemetryEvents.filter(e => e.event === 'gate_fired');

// Build FP count per gate from the FP log.
let fpCountByGate = {};
try {
  const fpRecords = loadFpLog();
  for (const r of fpRecords) {
    if (r.gate) fpCountByGate[r.gate] = (fpCountByGate[r.gate] || 0) + 1;
  }
} catch (e) {
  errors.push(`FP log load failed: ${e.message}`);
}

// Compute status for every gate.
const gates = ALL_GATES.map(g => computeGateStatus(g, gateFiredEvents, fpCountByGate, errors));

const eligibleCount = gates.filter(g => g.eligibleToBlock).length;

const output = {
  generated_at: new Date().toISOString(),
  telemetry_events_loaded: gateFiredEvents.length,
  fp_log_path: FP_LOG,
  thresholds: {
    FLIP_MIN_FIRES,
    FLIP_MAX_FP_RATE,
  },
  gates,
  summary: {
    total: gates.length,
    eligible: eligibleCount,
    not_eligible: gates.length - eligibleCount,
  },
  errors: errors.length > 0 ? errors : [],
};

if (JSON_MODE) {
  process.stdout.write(JSON.stringify(output, null, 2) + '\n');
  process.exit(0);
}

// ── Human summary table ───────────────────────────────────────────────────────

const COL_GATE  = 20;
const COL_TIER  = 13;
const COL_ELIG  = 8;
const COL_FIRES = 7;
const COL_FP    = 7;

function pad(s, n) { return String(s).padEnd(n); }

console.log('');
console.log('Gate Flip Eligibility Report');
console.log('============================');
console.log(`Generated: ${output.generated_at}`);
console.log(`Telemetry events: ${output.telemetry_events_loaded}`);
console.log(`Thresholds: min_fires=${FLIP_MIN_FIRES}  max_fp_rate=${(FLIP_MAX_FP_RATE * 100).toFixed(0)}%`);
console.log('');

const header = pad('GATE', COL_GATE) + pad('TIER', COL_TIER) + pad('ELIGIBLE', COL_ELIG) + pad('FIRES', COL_FIRES) + pad('FP', COL_FP) + 'REASON';
console.log(header);
console.log('-'.repeat(header.length));

for (const g of gates) {
  const eligible = g.eligibleToBlock ? 'YES' : 'no';
  const fires = g.total_fires !== null ? String(g.total_fires) : '(judge)';
  const fp    = g.fp_count   !== null ? String(g.fp_count)    : '(judge)';
  console.log(
    pad(g.gate, COL_GATE) +
    pad(g.tier, COL_TIER) +
    pad(eligible, COL_ELIG) +
    pad(fires, COL_FIRES) +
    pad(fp, COL_FP) +
    g.reason
  );
}

console.log('');
console.log(`Summary: ${eligibleCount}/${gates.length} gates eligible to flip to blocking`);

if (errors.length > 0) {
  console.log('');
  console.log('Errors encountered (fail-open — data may be incomplete):');
  for (const e of errors) console.log(`  - ${e}`);
}

console.log('');
console.log('To flip an eligible gate:');
console.log('  Deterministic: set STEP_VERIFY_GATE_ENFORCE=1 or add <!-- VERIFY-ENFORCE --> to the step doc');
console.log('  Judge:         re-run judge-calibration.mjs --gate <g>; auto-blocks once calibrated:true + --enforce');
console.log('  See: docs/GATE-FLIP-PROCEDURE.md');
console.log('');

process.exit(0);
