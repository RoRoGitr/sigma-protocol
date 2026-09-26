#!/usr/bin/env bash
# Hermetic tests for run-step-judge.sh (the pipeline entrypoint for the C2 judge).
# Fusion is stubbed via SIGMA_JUDGE_FUSION_CMD (forwarded to step-judge.mjs).

set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN="$REPO_ROOT/scripts/pipeline/run-step-judge.sh"
W="$(mktemp -d)"
PASS=0; FAIL=0
cleanup() { rm -rf "$W"; rm -f "$REPO_ROOT/.sigma/judge/test-rsj-"*.json; }
trap cleanup EXIT
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

ART="$W/art.md"; printf '# Artifact\n\nReal content with enough words to be judgeable.\n' > "$ART"

cat > "$W/pass.json" <<'EOF'
{"answer":"{\"verdict\":\"PASS\",\"criteria\":[{\"id\":\"CR-01\",\"met\":true,\"evidence\":\"x\",\"line\":\"1\",\"notes\":\"\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"anthropic\",\"calibrated\":false,\"advisory_reason\":\"advisory pending calibration\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/fail.json" <<'EOF'
{"answer":"{\"verdict\":\"FAIL\",\"criteria\":[{\"id\":\"CR-02\",\"met\":false,\"evidence\":\"<absent>\",\"line\":\"n/a\",\"notes\":\"missing section\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"anthropic\",\"calibrated\":false,\"advisory_reason\":\"advisory pending calibration\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/fail_cal.json" <<'EOF'
{"answer":"{\"verdict\":\"FAIL\",\"criteria\":[{\"id\":\"CR-02\",\"met\":false,\"evidence\":\"<absent>\",\"line\":\"n/a\",\"notes\":\"missing\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"openai\",\"calibrated\":true,\"advisory_reason\":\"\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF

echo "== run-step-judge.sh =="

# (a) PASS cross-family → ADVISORY, exit 0, summary shows PASS
out="$(SIGMA_JUDGE_FUSION_CMD="cat $W/pass.json" bash "$RUN" --artifact "$ART" --gate test-rsj-a 2>/dev/null)"; rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q "PASS (ADVISORY"; then ok "(a) PASS → advisory, exit 0"
else bad "(a) rc=$rc out=$out"; fi

# (b) FAIL uncalibrated → ADVISORY, exit 0 (no block)
out="$(SIGMA_JUDGE_FUSION_CMD="cat $W/fail.json" bash "$RUN" --artifact "$ART" --gate test-rsj-b 2>/dev/null)"; rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q "FAIL (ADVISORY"; then ok "(b) FAIL uncalibrated → advisory, exit 0"
else bad "(b) rc=$rc out=$out"; fi

# (c) FAIL calibrated + cross-family + --enforce → BLOCKING, exit 1
SIGMA_JUDGE_FUSION_CMD="cat $W/fail_cal.json" bash "$RUN" --artifact "$ART" --gate test-rsj-c --enforce >/dev/null 2>&1; rc=$?
[ $rc -eq 1 ] && ok "(c) FAIL calibrated+enforce → exit 1 (block)" || bad "(c) expected exit 1 got $rc"

# (d) missing --artifact → usage error exit 2
bash "$RUN" --gate test-rsj-d >/dev/null 2>&1; rc=$?
[ $rc -eq 2 ] && ok "(d) missing --artifact → exit 2" || bad "(d) expected 2 got $rc"

# (e) artifact not found → exit 2
bash "$RUN" --artifact "$W/nope.md" --gate test-rsj-e >/dev/null 2>&1; rc=$?
[ $rc -eq 2 ] && ok "(e) artifact-not-found → exit 2" || bad "(e) expected 2 got $rc"

# (f) verdict recorded to .sigma/judge/<gate>.json
SIGMA_JUDGE_FUSION_CMD="cat $W/pass.json" bash "$RUN" --artifact "$ART" --gate test-rsj-f >/dev/null 2>&1
[ -f "$REPO_ROOT/.sigma/judge/test-rsj-f.json" ] && ok "(f) verdict recorded to .sigma/judge/" || bad "(f) no recorded verdict"

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
