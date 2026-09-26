#!/usr/bin/env bash
# test_failure_baseline.sh — hermetic test suite for scripts/verify/failure-baseline.mjs
#
# Strategy: use env overrides (FAILURE_BASELINE_HISTORY, FAILURE_BASELINE_CONFIDENCE,
# FAILURE_BASELINE_OUT) to point the script at synthetic fixtures in a temp dir.
# No real repo state is read or written.
#
# Assertions:
#   1. Synthetic history with known gate data → output file exists and is valid JSON
#   2. Output contains required top-level keys (confidence, manualReviewNeeded, ranked_gates, hypothesis_checks)
#   3. confidence:"low" and manualReviewNeeded:true are set
#   4. greptile_score appears in ranked_gates with skipped count = 2 (matches fixture)
#   5. --json flag → stdout is parseable JSON with same structure
#   6. Empty history (no history file) → still exits 0 and writes output
#
# Usage: bash tests/test_failure_baseline.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/verify/failure-baseline.mjs"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $1" >&2; FAIL=$(( FAIL + 1 )); }

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label (exit $actual)"
  else
    fail "$label — expected exit $expected, got $actual"
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    pass "$label (contains '$needle')"
  else
    fail "$label — output does not contain '$needle'"$'\n'"  Got: $haystack"
  fi
}

if ! command -v node &>/dev/null; then
  echo "FAIL: node not on PATH" >&2; exit 1
fi

echo ""
echo "failure-baseline test suite"
echo "---------------------------"

# ── Setup: temp dir with synthetic fixtures ──────────────────────────────────

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_HISTORY="$TMP_DIR/pipeline-history.jsonl"
FAKE_CONFIDENCE="$TMP_DIR/confidence"
FAKE_OUT="$TMP_DIR/out/ranked-moves.json"

mkdir -p "$FAKE_CONFIDENCE"

# Synthetic history: known counts we can assert on
cat > "$FAKE_HISTORY" << 'EOF'
{"gate":"qa_verification","status":"completed","score":null,"round":null,"timestamp":"2026-04-17T18:09:18Z","branch":"main","session_id":"test001"}
{"gate":"anti_slop","status":"passed","score":9,"round":null,"timestamp":"2026-04-17T18:09:19Z","branch":"main","session_id":"test001"}
{"gate":"greptile_score","status":"skipped","score":null,"round":null,"timestamp":"2026-04-17T18:09:19Z","branch":"main","session_id":"test001"}
{"gate":"gap_analysis","status":"completed","score":100,"round":1,"timestamp":"2026-04-17T18:09:19Z","branch":"main","session_id":"test001"}
{"gate":"greptile_score","status":"skipped","score":null,"round":null,"timestamp":"2026-04-30T00:48:57Z","branch":"main","session_id":"test001"}
{"gate":"anti_slop","status":"passed","score":8,"round":1,"timestamp":"2026-04-30T00:48:45Z","branch":"main","session_id":"test001"}
EOF

# Synthetic confidence file
cat > "$FAKE_CONFIDENCE/gap-analysis-test.json" << 'EOF'
{
  "schema_version": "1.0.0",
  "analysis_date": "2026-04-19",
  "verdict": "SHIP",
  "gaps_found": 3,
  "gaps_fixed": 3
}
EOF

# ── Test 1: output file is created and is valid JSON ────────────────────────

echo ""
echo "Test 1: script exits 0 and writes a valid JSON output file"

set +e
T1_STDERR="$(
  FAILURE_BASELINE_HISTORY="$FAKE_HISTORY" \
  FAILURE_BASELINE_CONFIDENCE="$FAKE_CONFIDENCE" \
  FAILURE_BASELINE_OUT="$FAKE_OUT" \
  node "$SCRIPT" 2>&1 >/dev/null
)"
T1_EXIT=$?
set -e

assert_exit "exits 0" 0 "$T1_EXIT"

if [ -f "$FAKE_OUT" ]; then
  pass "output file exists at $FAKE_OUT"
else
  fail "output file was not created"
fi

# ── Test 2: required top-level keys present ──────────────────────────────────

echo ""
echo "Test 2: output JSON has required top-level keys"

T2_CHECK="$(node -e "
  const j = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
  const required = ['confidence','manualReviewNeeded','ranked_gates','hypothesis_checks','caveat','recommendations'];
  const missing = required.filter(k => !(k in j));
  if (missing.length) { console.error('missing: ' + missing.join(', ')); process.exit(1); }
  console.log('all keys present');
" "$FAKE_OUT" 2>&1)"
T2_EXIT=$?

if [ "$T2_EXIT" -eq 0 ]; then
  pass "all required keys present ($T2_CHECK)"
else
  fail "missing required keys: $T2_CHECK"
fi

# ── Test 3: confidence:low and manualReviewNeeded:true ──────────────────────

echo ""
echo "Test 3: confidence:low + manualReviewNeeded:true"

T3_CHECK="$(node -e "
  const j = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
  if (j.confidence !== 'low') { console.error('confidence is ' + j.confidence + ' not low'); process.exit(1); }
  if (j.manualReviewNeeded !== true) { console.error('manualReviewNeeded is ' + j.manualReviewNeeded); process.exit(1); }
  console.log('ok');
" "$FAKE_OUT" 2>&1)"
T3_EXIT=$?

if [ "$T3_EXIT" -eq 0 ]; then
  pass "confidence:low and manualReviewNeeded:true"
else
  fail "confidence/manualReviewNeeded check: $T3_CHECK"
fi

# ── Test 4: greptile_score in ranked_gates with skipped=2 ───────────────────

echo ""
echo "Test 4: greptile_score appears in ranked_gates with skipped=2"

T4_CHECK="$(node -e "
  const j = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
  const g = j.ranked_gates.find(r => r.gate === 'greptile_score');
  if (!g) { console.error('greptile_score not found in ranked_gates'); process.exit(1); }
  if (g.skipped !== 2) { console.error('expected skipped=2, got ' + g.skipped); process.exit(1); }
  console.log('greptile_score: skipped=' + g.skipped + ' total=' + g.total);
" "$FAKE_OUT" 2>&1)"
T4_EXIT=$?

if [ "$T4_EXIT" -eq 0 ]; then
  pass "greptile_score in ranked_gates with correct counts ($T4_CHECK)"
else
  fail "greptile_score assertion: $T4_CHECK"
fi

# ── Test 5: --json flag prints parseable JSON to stdout ─────────────────────

echo ""
echo "Test 5: --json flag prints parseable JSON to stdout"

FAKE_OUT2="$TMP_DIR/out2/ranked-moves.json"
mkdir -p "$(dirname "$FAKE_OUT2")"

set +e
T5_JSON="$(
  FAILURE_BASELINE_HISTORY="$FAKE_HISTORY" \
  FAILURE_BASELINE_CONFIDENCE="$FAKE_CONFIDENCE" \
  FAILURE_BASELINE_OUT="$FAKE_OUT2" \
  node "$SCRIPT" --json 2>/dev/null
)"
T5_EXIT=$?
set -e

assert_exit "--json exits 0" 0 "$T5_EXIT"

T5_PARSE="$(node -e "
  const j = JSON.parse(process.argv[1]);
  if (!Array.isArray(j.ranked_gates)) { console.error('ranked_gates not array'); process.exit(1); }
  console.log('ranked_gates.length=' + j.ranked_gates.length);
" "$T5_JSON" 2>&1)"
T5_PARSE_EXIT=$?

if [ "$T5_PARSE_EXIT" -eq 0 ]; then
  pass "--json stdout is valid JSON ($T5_PARSE)"
else
  fail "--json stdout parse error: $T5_PARSE"
fi

# ── Test 6: empty history (no file) → exits 0 ───────────────────────────────

echo ""
echo "Test 6: missing history file → exits 0, zero records"

FAKE_OUT3="$TMP_DIR/out3/ranked-moves.json"
mkdir -p "$(dirname "$FAKE_OUT3")"

set +e
T6_STDERR="$(
  FAILURE_BASELINE_HISTORY="$TMP_DIR/nonexistent-history.jsonl" \
  FAILURE_BASELINE_CONFIDENCE="$FAKE_CONFIDENCE" \
  FAILURE_BASELINE_OUT="$FAKE_OUT3" \
  node "$SCRIPT" 2>&1 >/dev/null
)"
T6_EXIT=$?
set -e

assert_exit "exits 0 with no history file" 0 "$T6_EXIT"

if [ -f "$FAKE_OUT3" ]; then
  T6_RECORDS="$(node -e "
    const j = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    console.log(j.data_sources.history_record_count);
  " "$FAKE_OUT3" 2>&1)"
  if [ "$T6_RECORDS" = "0" ]; then
    pass "history_record_count=0 when file absent"
  else
    fail "expected history_record_count=0, got: $T6_RECORDS"
  fi
else
  fail "output file not created when history missing"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "---------------------------"
echo "Results: $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
