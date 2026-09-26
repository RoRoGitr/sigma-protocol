#!/usr/bin/env node
// failure-baseline.mjs — mine pipeline history + confidence files into a ranked-moves
// baseline for understanding which gates fail most often.
//
// Data sources:
//   1. .pipeline-history.jsonl  — per-gate status records (~46 records; very thin)
//   2. .sigma/confidence/*.json — gap-analysis rounds with verdict/scores
//
// Output: .sigma/failure-baseline/ranked-moves.json
//
// IMPORTANT: The substrate is thin (~46 records). All frequency/percentage numbers
// here are descriptive counts on a tiny sample, NOT statistically significant.
// The output is stamped with confidence:"low" and manualReviewNeeded:true.
// Use it to direct manual review, not to draw conclusions.
//
// Hypothesis checked:
//   - Do gates with self-scored outputs (gap_analysis round scores) ever report
//     perfect scores? (Self-scoring passing bad output risk)
//   - Does greptile_score appear mostly as "skipped"? (Gate-skip risk)
//
// CLI:
//   node scripts/verify/failure-baseline.mjs          # writes output file
//   node scripts/verify/failure-baseline.mjs --json   # also prints JSON to stdout
//
// Env overrides (for hermetic tests):
//   FAILURE_BASELINE_HISTORY=<path>   overrides .pipeline-history.jsonl
//   FAILURE_BASELINE_CONFIDENCE=<dir> overrides .sigma/confidence/
//   FAILURE_BASELINE_OUT=<path>       overrides output file path

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

// ── Arg parsing ──────────────────────────────────────────────────────────────

const args = new Set(process.argv.slice(2));
const JSON_MODE = args.has('--json');

// ── Path resolution (env-overridable for tests) ──────────────────────────────

const HISTORY_PATH = process.env.FAILURE_BASELINE_HISTORY
  || path.join(REPO_ROOT, '.pipeline-history.jsonl');

const CONFIDENCE_DIR = process.env.FAILURE_BASELINE_CONFIDENCE
  || path.join(REPO_ROOT, '.sigma', 'confidence');

const OUT_PATH = process.env.FAILURE_BASELINE_OUT
  || path.join(REPO_ROOT, '.sigma', 'failure-baseline', 'ranked-moves.json');

// ── Load pipeline history ────────────────────────────────────────────────────

function loadHistory(filePath) {
  if (!fs.existsSync(filePath)) {
    return [];
  }
  const raw = fs.readFileSync(filePath, 'utf8');
  const records = [];
  for (const line of raw.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      records.push(JSON.parse(trimmed));
    } catch {
      // skip malformed lines
    }
  }
  return records;
}

// ── Load confidence files ────────────────────────────────────────────────────

function loadConfidenceFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  for (const name of fs.readdirSync(dir)) {
    if (!name.endsWith('.json')) continue;
    const p = path.join(dir, name);
    try {
      const parsed = JSON.parse(fs.readFileSync(p, 'utf8'));
      out.push({ file: name, ...parsed });
    } catch {
      // skip malformed
    }
  }
  return out;
}

// ── Aggregate gate stats from history ───────────────────────────────────────

function aggregateGateStats(records) {
  // { gate -> { total, pass, fail, skip, skipped, completed, scores: [] } }
  const stats = {};

  for (const r of records) {
    const gate = r.gate;
    if (!gate) continue;
    if (!stats[gate]) {
      stats[gate] = { gate, total: 0, passed: 0, failed: 0, skipped: 0, completed: 0, other: 0, scores: [], lastSeen: null };
    }
    const s = stats[gate];
    s.total++;

    const status = (r.status || '').toLowerCase();
    if (status === 'passed') s.passed++;
    else if (status === 'failed') s.failed++;
    else if (status === 'skipped') s.skipped++;
    else if (status === 'completed') s.completed++;
    else s.other++;

    if (r.score !== null && r.score !== undefined) {
      s.scores.push(r.score);
    }

    if (r.timestamp && (!s.lastSeen || r.timestamp > s.lastSeen)) {
      s.lastSeen = r.timestamp;
    }
  }

  return stats;
}

// ── Rank gates by failure/skip concern ──────────────────────────────────────
// Ranking heuristic (higher score = more concern):
//   - skipped gates get high concern score (they never actually fire)
//   - failed gates get concern proportional to fail rate
//   - "completed" with no score may be self-attested (medium concern)

function rankGates(stats, totalRecords) {
  const ranked = [];
  for (const [gate, s] of Object.entries(stats)) {
    const skipRate = totalRecords > 0 ? s.skipped / s.total : 0;
    const failRate = s.total > 0 ? s.failed / s.total : 0;
    // "completed" without score suggests self-attestation
    const selfAttestedRisk = s.completed > 0 && s.scores.length === 0;
    const avgScore = s.scores.length > 0
      ? s.scores.reduce((a, b) => a + b, 0) / s.scores.length
      : null;

    // concern score: weighted heuristic on thin data
    let concernScore = 0;
    concernScore += skipRate * 3;     // skips are the most concerning
    concernScore += failRate * 2;     // failures
    if (selfAttestedRisk) concernScore += 1; // self-attestation risk

    ranked.push({
      gate,
      total: s.total,
      passed: s.passed,
      failed: s.failed,
      skipped: s.skipped,
      completed: s.completed,
      other: s.other,
      skipRate: parseFloat(skipRate.toFixed(3)),
      failRate: parseFloat(failRate.toFixed(3)),
      avgScore,
      selfAttestedRisk,
      concernScore: parseFloat(concernScore.toFixed(3)),
      lastSeen: s.lastSeen,
    });
  }

  ranked.sort((a, b) => b.concernScore - a.concernScore);
  return ranked;
}

// ── Hypothesis checks ────────────────────────────────────────────────────────

function checkHypotheses(records, confidenceFiles) {
  const hypotheses = [];

  // H1: Self-scoring passes bad output (gap_analysis always gets high scores)
  const gapRecords = records.filter(r => r.gate === 'gap_analysis' && r.score !== null);
  const gapScores = gapRecords.map(r => r.score);
  const gapPerfect = gapScores.filter(s => s >= 100).length;
  const gapHigh = gapScores.filter(s => s >= 90).length;

  hypotheses.push({
    id: 'H1',
    hypothesis: 'Self-scoring passes bad output: gap_analysis self-scores at 100 despite no external validation',
    dataPoints: gapScores.length,
    finding: gapScores.length === 0
      ? 'No scored gap_analysis records in history — cannot confirm or deny.'
      : `${gapPerfect}/${gapScores.length} gap_analysis records scored 100; ${gapHigh}/${gapScores.length} scored >=90. With only ${gapScores.length} records this is observational only.`,
    verdict: gapScores.length < 5
      ? 'INSUFFICIENT_DATA'
      : gapPerfect === gapScores.length
        ? 'CONSISTENT_WITH_HYPOTHESIS'
        : 'INCONCLUSIVE',
    confidenceNote: 'Thin data (few records). Manual review of individual gate runs required.',
  });

  // H2: /step runs skip gates (greptile_score always skipped)
  const greptileRecords = records.filter(r => r.gate === 'greptile_score');
  const greptileSkipped = greptileRecords.filter(r => r.status === 'skipped').length;
  const greptileTotal = greptileRecords.length;

  hypotheses.push({
    id: 'H2',
    hypothesis: '/step runs skip gates: greptile_score is systematically skipped',
    dataPoints: greptileTotal,
    finding: greptileTotal === 0
      ? 'No greptile_score records in history.'
      : `${greptileSkipped}/${greptileTotal} greptile_score records have status:skipped (${(greptileSkipped / greptileTotal * 100).toFixed(0)}%). This is consistent with greptile being unavailable in most runs.`,
    verdict: greptileTotal < 3
      ? 'INSUFFICIENT_DATA'
      : greptileSkipped === greptileTotal
        ? 'CONSISTENT_WITH_HYPOTHESIS'
        : 'PARTIALLY_CONFIRMED',
    confidenceNote: 'greptile_score skip may be legitimate (no greptile token) rather than a pipeline bypass.',
  });

  // H3: confidence files show SHIP verdicts regardless of gaps found
  const shipVerdicts = confidenceFiles.filter(f => f.verdict === 'SHIP').length;
  const noShipVerdicts = confidenceFiles.filter(f => f.verdict && f.verdict !== 'SHIP').length;

  hypotheses.push({
    id: 'H3',
    hypothesis: 'Gap analysis ships even when gaps are found (self-grading is lenient)',
    dataPoints: confidenceFiles.length,
    finding: confidenceFiles.length === 0
      ? 'No confidence files found.'
      : `${shipVerdicts} SHIP verdict(s), ${noShipVerdicts} non-SHIP verdict(s) across ${confidenceFiles.length} confidence file(s). Individual files: ${confidenceFiles.map(f => `${f.file}:${f.verdict}(gaps_found=${f.gaps_found ?? 'unknown'})`).join(', ')}.`,
    verdict: confidenceFiles.length < 2
      ? 'INSUFFICIENT_DATA'
      : noShipVerdicts === 0
        ? 'CONSISTENT_WITH_HYPOTHESIS'
        : 'INCONCLUSIVE',
    confidenceNote: 'Sample size is too small for conclusions. Manual review needed.',
  });

  return hypotheses;
}

// ── Main ─────────────────────────────────────────────────────────────────────

const historyRecords = loadHistory(HISTORY_PATH);
const confidenceFiles = loadConfidenceFiles(CONFIDENCE_DIR);

const gateStats = aggregateGateStats(historyRecords);
const rankedGates = rankGates(gateStats, historyRecords.length);
const hypotheses = checkHypotheses(historyRecords, confidenceFiles);

// Build output document
const output = {
  generated_at: new Date().toISOString(),
  confidence: 'low',
  manualReviewNeeded: true,
  caveat: [
    `Pipeline history contains ${historyRecords.length} records across ${Object.keys(gateStats).length} distinct gates.`,
    'This sample size is insufficient for statistical significance.',
    'All frequency/rate figures are descriptive counts on thin data.',
    'Use this baseline to direct manual review, not to draw hard conclusions.',
    'As more pipeline runs are recorded, re-run this script to improve signal.',
  ].join(' '),
  data_sources: {
    history_path: HISTORY_PATH,
    history_record_count: historyRecords.length,
    confidence_dir: CONFIDENCE_DIR,
    confidence_file_count: confidenceFiles.length,
  },
  ranked_gates: rankedGates,
  hypothesis_checks: hypotheses,
  recommendations: [
    {
      priority: 1,
      action: 'MANUAL_REVIEW',
      detail: 'Review at least 10 actual gate runs per gate type to validate the concern scores above.',
    },
    {
      priority: 2,
      action: 'INSTRUMENT_TELEMETRY',
      detail: 'Ship A0 (pipeline-gate.sh telemetry extension) to populate .sigma/telemetry/sessions/ with richer gate_fired events. This will make gates-summary.mjs --check reliable.',
    },
    {
      priority: 3,
      action: 'INVESTIGATE_GREPTILE_SKIPS',
      detail: 'greptile_score is consistently skipped. Determine if this is a missing token (acceptable) or a systematic bypass (must fix).',
    },
    {
      priority: 4,
      action: 'VERIFY_GAP_ANALYSIS_SCORING',
      detail: 'gap_analysis scores are self-attested. Run a cross-family judge on stored gap analysis artifacts to validate the scores are earned.',
    },
  ],
};

// Ensure output directory exists
const outDir = path.dirname(OUT_PATH);
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

fs.writeFileSync(OUT_PATH, JSON.stringify(output, null, 2) + '\n');

if (JSON_MODE) {
  process.stdout.write(JSON.stringify(output, null, 2) + '\n');
}

console.error(`failure-baseline: wrote ${OUT_PATH}`);
console.error(`  ${historyRecords.length} history records, ${confidenceFiles.length} confidence files`);
console.error(`  ${rankedGates.length} gates ranked, ${hypotheses.length} hypotheses checked`);
console.error(`  confidence:low — manualReviewNeeded:true`);
