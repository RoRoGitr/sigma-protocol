#!/usr/bin/env bash
# test_gates_summary.sh — hermetic test suite for scripts/verify/gates-summary.mjs
#
# Strategy: use env overrides (SIGMA_TELEMETRY_DIR, SIGMA_HISTORY_PATH,
# SIGMA_STATE_PATH, SIGMA_SUMMARY_OUT) to point at synthetic fixtures.
# No real repo state is read or written.
#
# Assertions:
#   1. Aggregate mode with synthetic telemetry → valid JSON output with per_gate entries
#   2. History supplement populates historyTotal fields
#   3. --check mode with all gates fired → exit 0
#   4. --check mode with a missing gate → SILENT_SKIP: <gate> + exit 1
#   5. --check mode with no telemetry dir → exits 0 gracefully
#   6. --check mode with no state file → exits 0 gracefully
#
# Usage: bash tests/test_gates_summary.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/verify/gates-summary.mjs"

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
echo "gates-summary test suite"
echo "------------------------"

# ── Temp dir setup ───────────────────────────────────────────────────────────

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TELEM_DIR="$TMP/sessions"
HISTORY_FILE="$TMP/history.jsonl"
STATE_FILE="$TMP/state.json"
OUT_FILE="$TMP/out/gates-summary.json"

mkdir -p "$TELEM_DIR"
mkdir -p "$(dirname "$OUT_FILE")"

# change_counter we'll use in tests
COUNTER=42

# All 7 expected gates
ALL_GATES="anti_slop ui_validation devils_advocate gap_analysis qa_verification cross_model_review greptile_score"

# Write synthetic telemetry session — all 7 gates fired for counter=42
cat > "$TELEM_DIR/session-test.jsonl" << EOF
{"event":"gate_fired","gate":"anti_slop","status":"passed","ts":"2026-06-14T10:00:00Z","change_counter":$COUNTER,"session_id":"test","gen_ai.usage.total_tokens":1200,"cost_usd":0.002,"duration_ms":3000}
{"event":"gate_fired","gate":"ui_validation","status":"passed","ts":"2026-06-14T10:01:00Z","change_counter":$COUNTER,"session_id":"test","gen_ai.usage.total_tokens":null,"cost_usd":null,"duration_ms":null}
{"event":"gate_fired","gate":"devils_advocate","status":"completed","ts":"2026-06-14T10:02:00Z","change_counter":$COUNTER,"session_id":"test","gen_ai.usage.total_tokens":3000,"cost_usd":0.006,"duration_ms":8000}
{"event":"gate_fired","gate":"gap_analysis","status":"completed","ts":"2026-06-14T10:03:00Z","change_counter":$COUNTER,"session_id":"test","gen_ai.usage.total_tokens":2500,"cost_usd":0.005,"duration_ms":7000}
{"event":"gate_fired","gate":"qa_verification","status":"completed","ts":"2026-06-14T10:04:00Z","change_counter":$COUNTER,"session_id":"test","gen_ai.usage.total_tokens":null,"cost_usd":null,"duration_ms":null}
{"event":"gate_fired","gate":"cross_model_review","status":"completed","ts":"2026-06-14T10:05:00Z","change_counter":$COUNTER,"session_id":"test","gen_ai.usage.total_tokens":null,"cost_usd":null,"duration_ms":null}
{"event":"gate_fired","gate":"greptile_score","status":"skipped","ts":"2026-06-14T10:06:00Z","change_counter":$COUNTER,"session_id":"test","gen_ai.usage.total_tokens":null,"cost_usd":null,"duration_ms":null}
EOF

# Synthetic pipeline history
cat > "$HISTORY_FILE" << 'EOF'
{"gate":"qa_verification","status":"completed","score":null,"round":null,"timestamp":"2026-04-17T18:09:18Z","branch":"main","session_id":"h001"}
{"gate":"anti_slop","status":"passed","score":9,"round":null,"timestamp":"2026-04-17T18:09:19Z","branch":"main","session_id":"h001"}
{"gate":"greptile_score","status":"skipped","score":null,"round":null,"timestamp":"2026-04-17T18:09:19Z","branch":"main","session_id":"h001"}
EOF

# Synthetic pipeline state
cat > "$STATE_FILE" << EOF
{"session_id":"test","change_counter":$COUNTER,"commit_allowed":false}
EOF

# ── Test 1: aggregate mode → valid JSON output ───────────────────────────────

echo ""
echo "Test 1: aggregate mode exits 0 and writes valid JSON"

set +e
T1_ERR="$(
  SIGMA_TELEMETRY_DIR="$TELEM_DIR" \
  SIGMA_HISTORY_PATH="$HISTORY_FILE" \
  SIGMA_STATE_PATH="$STATE_FILE" \
  SIGMA_SUMMARY_OUT="$OUT_FILE" \
  node "$SCRIPT" 2>&1 >/dev/null
)"
T1_EXIT=$?
set -e

assert_exit "aggregate mode exits 0" 0 "$T1_EXIT"

if [ -f "$OUT_FILE" ]; then
  pass "output file written"
else
  fail "output file not created"
fi

T1_PARSE="$(node -e "
  const j = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
  const req = ['generated_at','telemetry_event_count','history_record_count','per_gate'];
  const miss = req.filter(k => !(k in j));
  if (miss.length) { console.error('missing: ' + miss.join(', ')); process.exit(1); }
  if (!Array.isArray(j.per_gate)) { console.error('per_gate not array'); process.exit(1); }
  console.log('per_gate.length=' + j.per_gate.length + ' event_count=' + j.telemetry_event_count);
" "$OUT_FILE" 2>&1)"
T1_PARSE_EXIT=$?

if [ "$T1_PARSE_EXIT" -eq 0 ]; then
  pass "output JSON structure valid ($T1_PARSE)"
else
  fail "output JSON structure: $T1_PARSE"
fi

# ── Test 2: history supplement visible in per_gate ──────────────────────────

echo ""
echo "Test 2: history data appears in per_gate entries"

T2_CHECK="$(node -e "
  const j = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
  // greptile_score should have historyTotal=1 from our synthetic history
  const g = j.per_gate.find(r => r.gate === 'greptile_score');
  if (!g) { console.error('greptile_score not in per_gate'); process.exit(1); }
  if (g.historyTotal !== 1) { console.error('expected historyTotal=1, got ' + g.historyTotal); process.exit(1); }
  console.log('greptile_score historyTotal=' + g.historyTotal);
" "$OUT_FILE" 2>&1)"
T2_EXIT=$?

if [ "$T2_EXIT" -eq 0 ]; then
  pass "history supplement visible in per_gate ($T2_CHECK)"
else
  fail "history supplement: $T2_CHECK"
fi

# ── Test 3: --check with all gates fired → exit 0 ───────────────────────────

echo ""
echo "Test 3: --check with all 7 gates fired → exit 0"

set +e
T3_OUT="$(
  SIGMA_TELEMETRY_DIR="$TELEM_DIR" \
  SIGMA_HISTORY_PATH="$HISTORY_FILE" \
  SIGMA_STATE_PATH="$STATE_FILE" \
  SIGMA_SUMMARY_OUT="$OUT_FILE" \
  node "$SCRIPT" --check 2>&1
)"
T3_EXIT=$?
set -e

assert_exit "--check all gates present → exit 0" 0 "$T3_EXIT"

# ── Test 4: --check with a missing gate → SILENT_SKIP + exit 1 ──────────────

echo ""
echo "Test 4: --check with gap_analysis missing from telemetry → SILENT_SKIP: gap_analysis + exit 1"

TELEM_DIR2="$TMP/sessions2"
mkdir -p "$TELEM_DIR2"

# Write telemetry with gap_analysis omitted
cat > "$TELEM_DIR2/session-partial.jsonl" << EOF
{"event":"gate_fired","gate":"anti_slop","status":"passed","ts":"2026-06-14T10:00:00Z","change_counter":$COUNTER}
{"event":"gate_fired","gate":"ui_validation","status":"passed","ts":"2026-06-14T10:01:00Z","change_counter":$COUNTER}
{"event":"gate_fired","gate":"devils_advocate","status":"completed","ts":"2026-06-14T10:02:00Z","change_counter":$COUNTER}
{"event":"gate_fired","gate":"qa_verification","status":"completed","ts":"2026-06-14T10:04:00Z","change_counter":$COUNTER}
{"event":"gate_fired","gate":"cross_model_review","status":"completed","ts":"2026-06-14T10:05:00Z","change_counter":$COUNTER}
{"event":"gate_fired","gate":"greptile_score","status":"skipped","ts":"2026-06-14T10:06:00Z","change_counter":$COUNTER}
EOF
# gap_analysis deliberately omitted

set +e
T4_OUT="$(
  SIGMA_TELEMETRY_DIR="$TELEM_DIR2" \
  SIGMA_HISTORY_PATH="$HISTORY_FILE" \
  SIGMA_STATE_PATH="$STATE_FILE" \
  SIGMA_SUMMARY_OUT="$OUT_FILE" \
  node "$SCRIPT" --check 2>&1
)"
T4_EXIT=$?
set -e

assert_exit "--check missing gate → exit 1" 1 "$T4_EXIT"
assert_contains "--check prints SILENT_SKIP:gap_analysis" "SILENT_SKIP: gap_analysis" "$T4_OUT"

# ── Test 5: --check with no telemetry → exits 0 gracefully ─────────────────

echo ""
echo "Test 5: --check with empty telemetry dir → exit 0 (graceful)"

TELEM_DIR3="$TMP/sessions3"
mkdir -p "$TELEM_DIR3"
# Empty directory

set +e
T5_OUT="$(
  SIGMA_TELEMETRY_DIR="$TELEM_DIR3" \
  SIGMA_HISTORY_PATH="$HISTORY_FILE" \
  SIGMA_STATE_PATH="$STATE_FILE" \
  SIGMA_SUMMARY_OUT="$OUT_FILE" \
  node "$SCRIPT" --check 2>&1
)"
T5_EXIT=$?
set -e

assert_exit "--check empty telemetry → exit 0" 0 "$T5_EXIT"

# ── Test 6: --check with no state file → exits 0 gracefully ─────────────────

echo ""
echo "Test 6: --check with missing state file → exit 0 (graceful)"

set +e
T6_OUT="$(
  SIGMA_TELEMETRY_DIR="$TELEM_DIR" \
  SIGMA_HISTORY_PATH="$HISTORY_FILE" \
  SIGMA_STATE_PATH="$TMP/nonexistent-state.json" \
  SIGMA_SUMMARY_OUT="$OUT_FILE" \
  node "$SCRIPT" --check 2>&1
)"
T6_EXIT=$?
set -e

assert_exit "--check no state file → exit 0" 0 "$T6_EXIT"

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "------------------------"
echo "Results: $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
