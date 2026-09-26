#!/usr/bin/env node
// gates-summary.mjs — aggregate per-gate telemetry + pipeline history into a
// machine-readable summary. Also implements the A5 canary check.
//
// Data sources:
//   1. .sigma/telemetry/sessions/*.jsonl  — gate_fired events from A0 telemetry
//   2. .pipeline-history.jsonl            — legacy gate records (status/score only)
//
// Output: .sigma/telemetry/gates-summary.json
//
// Modes:
//   (default)  aggregate both sources, write output file
//   --check    A5 canary: for the current change_counter in .pipeline-state.json,
//              assert each expected gate emitted a gate_fired event in telemetry.
//              SILENT_SKIP: <gate> printed + exit 1 for any missing gate.
//              exit 0 if all present (or if telemetry dir is empty / no state file).
//
// CLI:
//   node scripts/verify/gates-summary.mjs           # aggregate + write
//   node scripts/verify/gates-summary.mjs --check   # A5 canary
//
// Env overrides (for hermetic tests):
//   SIGMA_TELEMETRY_DIR=<dir>  overrides .sigma/telemetry/sessions/
//   SIGMA_HISTORY_PATH=<path>  overrides .pipeline-history.jsonl
//   SIGMA_STATE_PATH=<path>    overrides .pipeline-state.json
//   SIGMA_SUMMARY_OUT=<path>   overrides output file path

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

// ── Arg parsing ──────────────────────────────────────────────────────────────

const args = new Set(process.argv.slice(2));
const CHECK_MODE = args.has('--check');

// ── Path resolution ──────────────────────────────────────────────────────────

const TELEMETRY_DIR = process.env.SIGMA_TELEMETRY_DIR
  || path.join(REPO_ROOT, '.sigma', 'telemetry', 'sessions');

const HISTORY_PATH = process.env.SIGMA_HISTORY_PATH
  || path.join(REPO_ROOT, '.pipeline-history.jsonl');

const STATE_PATH = process.env.SIGMA_STATE_PATH
  || path.join(REPO_ROOT, '.pipeline-state.json');

const SUMMARY_OUT = process.env.SIGMA_SUMMARY_OUT
  || path.join(REPO_ROOT, '.sigma', 'telemetry', 'gates-summary.json');

// ── Expected gates (the full 7-gate pipeline) ────────────────────────────────

const EXPECTED_GATES = [
  'anti_slop',
  'ui_validation',
  'devils_advocate',
  'gap_analysis',
  'qa_verification',
  'cross_model_review',
  'greptile_score',
];

// ── Load telemetry files ─────────────────────────────────────────────────────

function loadTelemetryEvents(dir) {
  if (!fs.existsSync(dir)) return [];
  const events = [];
  for (const name of fs.readdirSync(dir)) {
    if (!name.endsWith('.jsonl')) continue;
    const p = path.join(dir, name);
    const raw = fs.readFileSync(p, 'utf8');
    for (const line of raw.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      try {
        events.push(JSON.parse(trimmed));
      } catch {
        // skip malformed
      }
    }
  }
  return events;
}

// ── Load pipeline history ────────────────────────────────────────────────────

function loadHistory(filePath) {
  if (!fs.existsSync(filePath)) return [];
  const raw = fs.readFileSync(filePath, 'utf8');
  const records = [];
  for (const line of raw.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      records.push(JSON.parse(trimmed));
    } catch {
      // skip
    }
  }
  return records;
}

// ── Aggregate gate stats from telemetry events ───────────────────────────────

function aggregateFromTelemetry(events) {
  // Only process gate_fired events
  const gateFired = events.filter(e => e.event === 'gate_fired');
  const stats = {};

  for (const e of gateFired) {
    const gate = e.gate;
    if (!gate) continue;
    if (!stats[gate]) {
      stats[gate] = {
        gate,
        fireCount: 0,
        passed: 0,
        failed: 0,
        skipped: 0,
        other: 0,
        totalTokens: 0,
        totalCostUsd: 0,
        totalDurationMs: 0,
        tokenSamples: 0,
        costSamples: 0,
        durationSamples: 0,
        lastFired: null,
        changeCounters: new Set(),
      };
    }
    const s = stats[gate];
    s.fireCount++;

    const status = (e.status || '').toLowerCase();
    if (status === 'passed') s.passed++;
    else if (status === 'failed') s.failed++;
    else if (status === 'skipped') s.skipped++;
    else s.other++;

    const tokens = e['gen_ai.usage.total_tokens'];
    if (tokens !== null && tokens !== undefined && typeof tokens === 'number') {
      s.totalTokens += tokens;
      s.tokenSamples++;
    }

    if (e.cost_usd !== null && e.cost_usd !== undefined && typeof e.cost_usd === 'number') {
      s.totalCostUsd += e.cost_usd;
      s.costSamples++;
    }

    if (e.duration_ms !== null && e.duration_ms !== undefined && typeof e.duration_ms === 'number') {
      s.totalDurationMs += e.duration_ms;
      s.durationSamples++;
    }

    if (e.ts && (!s.lastFired || e.ts > s.lastFired)) {
      s.lastFired = e.ts;
    }

    if (e.change_counter !== null && e.change_counter !== undefined) {
      s.changeCounters.add(e.change_counter);
    }
  }

  return stats;
}

// ── Supplement from pipeline history (legacy source) ─────────────────────────

function aggregateFromHistory(records) {
  const stats = {};
  for (const r of records) {
    const gate = r.gate;
    if (!gate) continue;
    if (!stats[gate]) {
      stats[gate] = {
        gate,
        historyTotal: 0,
        historyPassed: 0,
        historyFailed: 0,
        historySkipped: 0,
        historyCompleted: 0,
        lastSeen: null,
      };
    }
    const s = stats[gate];
    s.historyTotal++;
    const status = (r.status || '').toLowerCase();
    if (status === 'passed') s.historyPassed++;
    else if (status === 'failed') s.historyFailed++;
    else if (status === 'skipped') s.historySkipped++;
    else if (status === 'completed') s.historyCompleted++;

    if (r.timestamp && (!s.lastSeen || r.timestamp > s.lastSeen)) {
      s.lastSeen = r.timestamp;
    }
  }
  return stats;
}

// ── Merge telemetry + history into per-gate entries ──────────────────────────

function mergeStats(telemetryStats, historyStats) {
  const allGates = new Set([
    ...Object.keys(telemetryStats),
    ...Object.keys(historyStats),
  ]);

  const merged = [];
  for (const gate of allGates) {
    const t = telemetryStats[gate] || {};
    const h = historyStats[gate] || {};

    merged.push({
      gate,
      // telemetry fields
      fireCount: t.fireCount || 0,
      passed: t.passed || 0,
      failed: t.failed || 0,
      skipped: t.skipped || 0,
      other: t.other || 0,
      totalTokens: t.totalTokens || 0,
      avgTokens: t.tokenSamples > 0 ? Math.round(t.totalTokens / t.tokenSamples) : null,
      totalCostUsd: t.costSamples > 0 ? parseFloat((t.totalCostUsd).toFixed(6)) : null,
      avgCostUsd: t.costSamples > 0 ? parseFloat((t.totalCostUsd / t.costSamples).toFixed(6)) : null,
      totalDurationMs: t.durationSamples > 0 ? Math.round(t.totalDurationMs) : null,
      avgDurationMs: t.durationSamples > 0 ? Math.round(t.totalDurationMs / t.durationSamples) : null,
      lastFired: t.lastFired || null,
      // history supplement
      historyTotal: h.historyTotal || 0,
      historyPassed: h.historyPassed || 0,
      historyFailed: h.historyFailed || 0,
      historySkipped: h.historySkipped || 0,
      historyCompleted: h.historyCompleted || 0,
      historyLastSeen: h.lastSeen || null,
    });
  }

  merged.sort((a, b) => a.gate.localeCompare(b.gate));
  return merged;
}

// ── CHECK MODE: A5 canary ────────────────────────────────────────────────────

function runCheckMode(telemetryEvents, currentChangeCounter) {
  // Find all gate_fired events for the current change_counter
  const fired = new Set(
    telemetryEvents
      .filter(e => e.event === 'gate_fired' && e.change_counter === currentChangeCounter)
      .map(e => e.gate)
  );

  const missing = EXPECTED_GATES.filter(g => !fired.has(g));

  if (missing.length > 0) {
    for (const gate of missing) {
      console.log(`SILENT_SKIP: ${gate}`);
    }
    console.error(`gates-summary --check: ${missing.length} gate(s) missing for change_counter=${currentChangeCounter}`);
    process.exit(1);
  }

  console.log(`gates-summary --check: all ${EXPECTED_GATES.length} gates fired for change_counter=${currentChangeCounter}`);
  process.exit(0);
}

// ── Main ─────────────────────────────────────────────────────────────────────

const telemetryEvents = loadTelemetryEvents(TELEMETRY_DIR);
const historyRecords = loadHistory(HISTORY_PATH);

if (CHECK_MODE) {
  // Load current change_counter from pipeline state
  if (!fs.existsSync(STATE_PATH)) {
    // No state file — nothing to check against, pass gracefully
    console.log('gates-summary --check: no pipeline state file found, skipping canary check');
    process.exit(0);
  }

  let state;
  try {
    state = JSON.parse(fs.readFileSync(STATE_PATH, 'utf8'));
  } catch (e) {
    console.error(`gates-summary --check: failed to parse pipeline state: ${e.message}`);
    process.exit(1);
  }

  const currentChangeCounter = state.change_counter;
  if (currentChangeCounter === undefined || currentChangeCounter === null) {
    console.log('gates-summary --check: no change_counter in state, skipping canary check');
    process.exit(0);
  }

  if (telemetryEvents.length === 0) {
    // No telemetry yet (A0 not shipped) — skip gracefully with note
    console.log(`gates-summary --check: no telemetry events (A0 not shipped yet), skipping canary check`);
    process.exit(0);
  }

  runCheckMode(telemetryEvents, currentChangeCounter);
  // unreachable — runCheckMode always exits
}

// ── Aggregate mode ────────────────────────────────────────────────────────────

const telemetryStats = aggregateFromTelemetry(telemetryEvents);
const historyStats = aggregateFromHistory(historyRecords);
const perGate = mergeStats(telemetryStats, historyStats);

const summary = {
  generated_at: new Date().toISOString(),
  telemetry_event_count: telemetryEvents.length,
  history_record_count: historyRecords.length,
  gate_count: perGate.length,
  per_gate: perGate,
};

// Ensure output directory exists
const outDir = path.dirname(SUMMARY_OUT);
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

fs.writeFileSync(SUMMARY_OUT, JSON.stringify(summary, null, 2) + '\n');

console.error(`gates-summary: wrote ${SUMMARY_OUT}`);
console.error(`  telemetry events: ${telemetryEvents.length}`);
console.error(`  history records: ${historyRecords.length}`);
console.error(`  gates: ${perGate.map(g => g.gate).join(', ')}`);
