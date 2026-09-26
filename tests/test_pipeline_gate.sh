#!/usr/bin/env bash
# Hermetic tests for pipeline-gate.sh — C4 skip-reason capture + the additive
# fields don't break commit_allowed. PIPELINE_STATE_FILE redirects the checkpoint
# into a temp file so the real .pipeline-state.json is never touched.

set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$REPO_ROOT/scripts/pipeline/pipeline-gate.sh"
W="$(mktemp -d)"
PASS=0; FAIL=0
trap 'rm -rf "$W"' EXIT
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

CK="$W/state.json"
seed() { printf '{"change_counter":0,"worktree_fingerprint":"","has_frontend_changes":false,"gates":{}}\n' > "$CK"; }
field() { jq -r "$1" "$CK"; }
run() { PIPELINE_GATE_LOCK_DIR="$W/gate-lock.d" PIPELINE_STATE_FILE="$CK" PIPELINE_HISTORY_FILE="$W/history.jsonl" SIGMA_TELEMETRY_DIR="$W/tele" SIGMA_SESSION_ID="t" bash "$GATE" "$@"; }

echo "== pipeline-gate.sh (C4 skip-reason) =="

# (a) skipped WITHOUT --reason → WARN + reason recorded as 'unspecified-skip'
seed
run greptile_score skipped >/dev/null 2>"$W/a.err"
if [ "$(field '.gates.greptile_score.reason')" = "unspecified-skip" ] && grep -qi "skipped with NO --reason" "$W/a.err"; then
  ok "(a) silent skip → WARN + reason=unspecified-skip"
else bad "(a) reason=$(field '.gates.greptile_score.reason') err=$(cat "$W/a.err")"; fi

# (b) skipped WITH --reason → that reason recorded, no warn
seed
run greptile_score skipped --reason="greptile token unavailable" >/dev/null 2>"$W/b.err"
if [ "$(field '.gates.greptile_score.reason')" = "greptile token unavailable" ] && ! grep -qi "NO --reason" "$W/b.err"; then
  ok "(b) explicit --reason recorded, no warn"
else bad "(b) reason=$(field '.gates.greptile_score.reason')"; fi

# (c) commit_allowed still COMPUTES (boolean, not error) with the new reason field
seed
run greptile_score skipped --reason="token unavailable" >/dev/null 2>&1
ca="$(field '.commit_allowed')"
if [ "$ca" = "true" ] || [ "$ca" = "false" ]; then ok "(c) commit_allowed still computes (=$ca), reason field non-breaking"
else bad "(c) commit_allowed not a boolean: $ca"; fi

# (d) a non-skip gate (passed) → reason is null (only skips get a default)
seed
run anti_slop passed 96 >/dev/null 2>&1
if [ "$(field '.gates.anti_slop.reason')" = "null" ] && [ "$(field '.gates.anti_slop.status')" = "passed" ]; then
  ok "(d) passed gate → reason null (no spurious default)"
else bad "(d) anti_slop reason=$(field '.gates.anti_slop.reason')"; fi

# (e) greptile skipped is still commit-eligible per the IN(completed,skipped) rule
#     (record all OTHER gates passed/completed + greptile skipped → commit_allowed true)
seed
run anti_slop passed 96 >/dev/null 2>&1
run devils_advocate completed >/dev/null 2>&1
run gap_analysis completed >/dev/null 2>&1
run qa_verification completed >/dev/null 2>&1
run cross_model_review completed >/dev/null 2>&1
run greptile_score skipped --reason="token unavailable" >/dev/null 2>&1
ca="$(field '.commit_allowed')"
[ "$ca" = "true" ] && ok "(e) greptile skipped still allows commit (=$ca)" || bad "(e) expected commit_allowed true, got $ca (state: $(field '.gates'))"

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
