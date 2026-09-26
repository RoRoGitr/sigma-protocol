#!/bin/bash
# test-parallel-lock.sh
#
# Verifies that pipeline-gate.sh serializes concurrent invocations via its
# mkdir-based mutex. Runs 4 gate marks in parallel, then asserts:
#   1. All 4 invocations exit 0 (none lost the race and failed)
#   2. Every gate stamp's change_counter matches the current counter in
#      .pipeline-state.json — no counter drift between concurrent callers
#
# Run from any directory inside a git repo with pipeline-state.json present
# (the script auto-inits if missing).
#
# Usage:
#   bash scripts/pipeline/tests/test-parallel-lock.sh
#
# Exit codes:
#   0 — all assertions passed
#   1 — one or more assertions failed

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "FAIL: not inside a git repo" >&2
  exit 1
fi

CHECKPOINT="$REPO_ROOT/.pipeline-state.json"
LOCK_DIR="/tmp/sigma-pipeline-gate.lock.d"

# Clean up any stale lock from a prior failed run
rm -rf "$LOCK_DIR"

# Ensure pipeline state is initialized
if [[ ! -f "$CHECKPOINT" ]]; then
  "$SCRIPT_DIR/pipeline-init.sh" >/dev/null 2>&1 || true
fi

echo "--- test-parallel-lock: launching 4 concurrent gate marks ---"

# Track exit codes via temp files (background processes cannot share variables)
TMPDIR_RESULTS="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_RESULTS"' EXIT

run_gate() {
  local gate="$1"
  local status="$2"
  local idx="$3"
  "$SCRIPT_DIR/pipeline-gate.sh" "$gate" "$status" >/dev/null 2>&1
  echo $? > "$TMPDIR_RESULTS/exit-$idx"
}

run_gate anti_slop       passed    1 &
run_gate devils_advocate completed 2 &
run_gate qa_verification completed 3 &
run_gate gap_analysis    completed 4 &

wait
echo "--- all 4 background jobs completed ---"

# Assertion 1: all exit codes are 0
FAILURES=0
for i in 1 2 3 4; do
  code="$(cat "$TMPDIR_RESULTS/exit-$i" 2>/dev/null || echo "MISSING")"
  if [[ "$code" != "0" ]]; then
    echo "FAIL: gate invocation $i exited with code '$code'" >&2
    FAILURES=$(( FAILURES + 1 ))
  else
    echo "PASS: gate invocation $i exited 0"
  fi
done

# Assertion 2: every gate stamp's change_counter matches the current counter
CURRENT_COUNTER=$(jq -r '.change_counter // 0' "$CHECKPOINT")

for gate in anti_slop devils_advocate qa_verification gap_analysis; do
  gate_counter=$(jq -r ".gates.${gate}.change_counter // -1" "$CHECKPOINT")
  if [[ "$gate_counter" -eq "$CURRENT_COUNTER" ]]; then
    echo "PASS: gate '$gate' change_counter=$gate_counter matches current=$CURRENT_COUNTER"
  else
    echo "FAIL: gate '$gate' change_counter=$gate_counter != current=$CURRENT_COUNTER (counter drift)" >&2
    FAILURES=$(( FAILURES + 1 ))
  fi
done

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "RESULT: ALL PASSED (4 parallel invocations, 0 counter drift)"
  exit 0
else
  echo "RESULT: $FAILURES ASSERTION(S) FAILED"
  exit 1
fi
