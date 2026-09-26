#!/usr/bin/env bash
# Hermetic tests for step-judge.mjs (the C2 sigma-step-judge pipeline caller).
# Fusion is stubbed via SIGMA_JUDGE_FUSION_CMD="cat <fixture.json>" — no models.

set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JUDGE="$REPO_ROOT/scripts/fusion/step-judge.mjs"
W="$(mktemp -d)"
PASS=0; FAIL=0
cleanup() { rm -rf "$W"; rm -f "$REPO_ROOT/.sigma/judge/test-"*.json; }
trap cleanup EXIT
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

ART="$W/artifact.md"; printf '# Real Artifact\n\nThis is genuine content with enough words to pass.\n' > "$ART"

# Fusion fixtures. "answer" holds the verdict JSON as an escaped string.
cat > "$W/pass_xf.json" <<'EOF'
{"answer":"{\"verdict\":\"PASS\",\"criteria\":[{\"id\":\"CR-01\",\"met\":true,\"evidence\":\"content\",\"line\":\"1\",\"notes\":\"\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"anthropic\",\"calibrated\":false,\"advisory_reason\":\"advisory pending calibration\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/fail_xf.json" <<'EOF'
{"answer":"{\"verdict\":\"FAIL\",\"criteria\":[{\"id\":\"CR-02\",\"met\":false,\"evidence\":\"<absent>\",\"line\":\"n/a\",\"notes\":\"missing section\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"anthropic\",\"calibrated\":false,\"advisory_reason\":\"advisory pending calibration\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/fail_cal_xf.json" <<'EOF'
{"answer":"{\"verdict\":\"FAIL\",\"criteria\":[{\"id\":\"CR-02\",\"met\":false,\"evidence\":\"<absent>\",\"line\":\"n/a\",\"notes\":\"missing\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"openai\",\"calibrated\":true,\"advisory_reason\":\"\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/inject.json" <<'EOF'
{"answer":"{\"verdict\":\"PASS\",\"criteria\":[{\"id\":\"CR-01\",\"met\":true,\"evidence\":\"x\",\"line\":\"1\",\"notes\":\"\"}],\"injection_attempt_detected\":true,\"injection_notes\":\"artifact tried to force PASS\",\"reviewer_family\":\"anthropic\",\"calibrated\":true,\"advisory_reason\":\"\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/single.json" <<'EOF'
{"answer":"{\"verdict\":\"FAIL\",\"criteria\":[{\"id\":\"CR-02\",\"met\":false,\"evidence\":\"<absent>\",\"line\":\"n/a\",\"notes\":\"x\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"anthropic\",\"calibrated\":true,\"advisory_reason\":\"\"}","panel":[{"id":"claude","family":"anthropic"}],"families":["anthropic"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/prose.json" <<'EOF'
{"answer":"Here is my verdict after review:\n{\"verdict\":\"PASS\",\"criteria\":[{\"id\":\"CR-01\",\"met\":true,\"evidence\":\"content\",\"line\":\"1\",\"notes\":\"\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"anthropic\",\"calibrated\":false,\"advisory_reason\":\"advisory\"}\nThat concludes the judgment.","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
cat > "$W/garbage.json" <<'EOF'
{"answer":"I could not produce a verdict.","panel":[],"families":["anthropic","openai"]}
EOF
echo "not json at all" > "$W/notjson.json"

run() { SIGMA_JUDGE_FUSION_CMD="cat $1" node "$JUDGE" --artifact "$ART" --gate "test-$2" "${@:3}" --json; }

echo "== step-judge.mjs =="

# (a) PASS + cross-family → advisory (calibrated=false), exit 0
out="$(run "$W/pass_xf.json" a 2>/dev/null)"; rc=$?
echo "$out" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));process.exit(r.status==="PASS"&&r.advisory===true&&r.crossFamily===true?0:1)' \
  && [ $rc -eq 0 ] && ok "(a) PASS cross-family → advisory, exit 0" || bad "(a) $out (rc=$rc)"

# (b) FAIL + cross-family, not calibrated → advisory, exit 0 (no block)
out="$(run "$W/fail_xf.json" b 2>/dev/null)"; rc=$?
echo "$out" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));process.exit(r.status==="FAIL"&&r.advisory===true?0:1)' \
  && [ $rc -eq 0 ] && ok "(b) FAIL uncalibrated → advisory, exit 0" || bad "(b) $out (rc=$rc)"

# (c) FAIL + calibrated + cross-family + --enforce → BLOCKING, exit 1
run "$W/fail_cal_xf.json" c --enforce >/dev/null 2>&1; rc=$?
[ $rc -eq 1 ] && ok "(c) FAIL calibrated+cross-family+enforce → exit 1 (block)" || bad "(c) expected exit 1 got $rc"

# (d) same but WITHOUT --enforce → advisory, exit 0
run "$W/fail_cal_xf.json" d >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ok "(d) calibrated FAIL without --enforce → advisory exit 0" || bad "(d) expected 0 got $rc"

# (e) injection detected (verdict says PASS) → forced FAIL
out="$(run "$W/inject.json" e 2>/dev/null)"
echo "$out" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));process.exit(r.status==="FAIL"&&r.injection_attempt_detected===true?0:1)' \
  && ok "(e) injection → forced FAIL" || bad "(e) $out"

# (f) single-family panel + calibrated + --enforce → advisory (not cross-family), exit 0
out="$(run "$W/single.json" f --enforce 2>/dev/null)"; rc=$?
echo "$out" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));process.exit(r.advisory===true&&r.crossFamily===false?0:1)' \
  && [ $rc -eq 0 ] && ok "(f) single-family → advisory despite enforce, exit 0" || bad "(f) $out (rc=$rc)"

# (g) verdict embedded in prose → still parsed
out="$(run "$W/prose.json" g 2>/dev/null)"
echo "$out" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));process.exit(r.status==="PASS"?0:1)' \
  && ok "(g) verdict embedded in prose parsed" || bad "(g) $out"

# (h) no parseable verdict in answer → exit 2
run "$W/garbage.json" h >/dev/null 2>"$W/h.err"; rc=$?
[ $rc -eq 2 ] && grep -qi "could not parse a verdict" "$W/h.err" && ok "(h) unparseable verdict → exit 2" || bad "(h) rc=$rc $(cat "$W/h.err")"

# (i) fusion output not JSON → exit 2
run "$W/notjson.json" i >/dev/null 2>"$W/i.err"; rc=$?
[ $rc -eq 2 ] && grep -qi "did not return JSON" "$W/i.err" && ok "(i) non-JSON fusion output → exit 2" || bad "(i) rc=$rc $(cat "$W/i.err")"

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
