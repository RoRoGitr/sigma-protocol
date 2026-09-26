#!/usr/bin/env bash
# Hermetic tests for judge-calibration.mjs (the advisory→blocking gate for the
# C2 judge) + the step-judge.mjs integration that reads the calibration report.
# SIGMA_CALIBRATION_DIR redirects all golden/report I/O into a temp dir.

set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CAL="$REPO_ROOT/scripts/verify/judge-calibration.mjs"
JUDGE="$REPO_ROOT/scripts/fusion/step-judge.mjs"
W="$(mktemp -d)"
PASS=0; FAIL=0
trap 'rm -rf "$W"' EXIT
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

# Generate a golden jsonl with given confusion counts (TP/FN/TN/FP) + cross-family flag.
gen() { # $1 gate $2 tp $3 fn $4 tn $5 fp $6 crossFamily(true|false)
  node -e '
    const fs=require("fs"),path=require("path");
    const [gate,tp,fn,tn,fp,xf]=process.argv.slice(1);
    const dir=path.join(process.env.SIGMA_CALIBRATION_DIR,"golden"); fs.mkdirSync(dir,{recursive:true});
    const out=[]; const rf="openai", impf="anthropic";
    const push=(jv,hl,cross)=>out.push(JSON.stringify({gate,judge_verdict:jv,human_label:hl,reviewer_family:rf,implementer_family:cross?impf:rf,cross_family:cross}));
    const cross=(xf==="true");
    for(let i=0;i<+tp;i++)push("FAIL","FAIL",cross);
    for(let i=0;i<+fn;i++)push("PASS","FAIL",cross);
    for(let i=0;i<+tn;i++)push("PASS","PASS",cross);
    for(let i=0;i<+fp;i++)push("FAIL","PASS",cross);
    fs.writeFileSync(path.join(dir,gate+".jsonl"),out.join("\n")+"\n");
  ' "$1" "$2" "$3" "$4" "$5" "$6"
}
caljson() { node -e 'const r=JSON.parse(require("fs").readFileSync(process.argv[1]+"/"+process.argv[2]+".json","utf8"));process.stdout.write(String(r[process.argv[3]]))' "$1" "$2" "$3"; }

echo "== judge-calibration.mjs =="

# (a) crosses the bar: TP20/FN2/TN18/FP2 → n42 pos22 neg20 TPR.909 TNR.90 balAcc.905 cross → CALIBRATED
export SIGMA_CALIBRATION_DIR="$W/a"; gen ga 20 2 18 2 true
node "$CAL" --gate ga --json >/dev/null 2>&1
[ "$(caljson "$W/a" ga calibrated)" = "true" ] && ok "(a) crosses bar → calibrated" || bad "(a) $(caljson "$W/a" ga blocking_reason)"

# (b) low TNR: TP20/FN2/TN10/FP10 → TNR .50 < .80 → NOT calibrated
export SIGMA_CALIBRATION_DIR="$W/b"; gen gb 20 2 10 10 true
node "$CAL" --gate gb >/dev/null 2>&1
if [ "$(caljson "$W/b" gb calibrated)" = "false" ] && caljson "$W/b" gb blocking_reason | grep -qi "TNR"; then ok "(b) low TNR → not calibrated"
else bad "(b) $(caljson "$W/b" gb blocking_reason)"; fi

# (c) thin n: TP5/FN1/TN5/FP1 → n12 < 40 → NOT calibrated
export SIGMA_CALIBRATION_DIR="$W/c"; gen gc 5 1 5 1 true
node "$CAL" --gate gc >/dev/null 2>&1
if [ "$(caljson "$W/c" gc calibrated)" = "false" ] && caljson "$W/c" gc blocking_reason | grep -qi "n=12"; then ok "(c) thin n → not calibrated"
else bad "(c) $(caljson "$W/c" gc blocking_reason)"; fi

# (d) good metrics but SAME-family → NOT calibrated
export SIGMA_CALIBRATION_DIR="$W/d"; gen gd 20 2 18 2 false
node "$CAL" --gate gd >/dev/null 2>&1
if [ "$(caljson "$W/d" gd calibrated)" = "false" ] && caljson "$W/d" gd blocking_reason | grep -qi "cross-family"; then ok "(d) same-family → not calibrated"
else bad "(d) $(caljson "$W/d" gd blocking_reason)"; fi

# (e) --record appends a labeled example
export SIGMA_CALIBRATION_DIR="$W/e"; ART="$W/art.md"; echo "x" > "$ART"
node "$CAL" --record --gate ge --artifact "$ART" --judge FAIL --human PASS --reviewer-family openai --implementer-family anthropic >/dev/null 2>&1
if [ -f "$W/e/golden/ge.jsonl" ] && grep -q '"judge_verdict":"FAIL"' "$W/e/golden/ge.jsonl" && grep -q '"cross_family":true' "$W/e/golden/ge.jsonl"; then ok "(e) --record appends labeled example"
else bad "(e) record failed: $(cat "$W/e/golden/ge.jsonl" 2>/dev/null)"; fi

# (f) no golden → calibrated false, n=0
export SIGMA_CALIBRATION_DIR="$W/f"
node "$CAL" --gate gf >/dev/null 2>&1
[ "$(caljson "$W/f" gf calibrated)" = "false" ] && [ "$(caljson "$W/f" gf n)" = "0" ] && ok "(f) empty golden → not calibrated, n=0" || bad "(f) unexpected"

echo "== step-judge.mjs reads the calibration report (integration) =="
# (g) a CALIBRATED report makes step-judge block on FAIL+enforce, even though the
#     verdict's own calibrated field is false (report is authoritative).
export SIGMA_CALIBRATION_DIR="$W/g"; mkdir -p "$W/g"
printf '{"gate":"gg","calibrated":true}\n' > "$W/g/gg.json"
cat > "$W/g/fail.json" <<'EOF'
{"answer":"{\"verdict\":\"FAIL\",\"criteria\":[{\"id\":\"CR-02\",\"met\":false,\"evidence\":\"<absent>\",\"line\":\"n/a\",\"notes\":\"x\"}],\"injection_attempt_detected\":false,\"reviewer_family\":\"openai\",\"calibrated\":false,\"advisory_reason\":\"\"}","panel":[{"id":"claude","family":"anthropic"},{"id":"codex","family":"openai"}],"families":["anthropic","openai"],"synthesizer":{"id":"claude","family":"anthropic"}}
EOF
echo "art" > "$W/g/a.md"
SIGMA_JUDGE_FUSION_CMD="cat $W/g/fail.json" node "$JUDGE" --artifact "$W/g/a.md" --gate gg --enforce >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && ok "(g) calibrated report → step-judge blocks (exit 1)" || bad "(g) expected exit 1 got $rc (report not consumed)"

# (h) WITHOUT a report, same FAIL+enforce stays advisory (verdict calibrated=false) → exit 0
export SIGMA_CALIBRATION_DIR="$W/h"; mkdir -p "$W/h"
SIGMA_JUDGE_FUSION_CMD="cat $W/g/fail.json" node "$JUDGE" --artifact "$W/g/a.md" --gate gh --enforce >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "(h) no report → advisory (exit 0), backward-compatible" || bad "(h) expected exit 0 got $rc"

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
