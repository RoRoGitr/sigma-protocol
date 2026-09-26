#!/usr/bin/env bash
# test_gate_flip_status.sh — hermetic tests for scripts/verify/gate-flip-status.mjs
#
# Strategy: synthesize telemetry/calibration via SIGMA_*_DIR env overrides.
# No real repo state is read or written. All I/O goes to mktemp dirs.
#
# Tests:
#   (a) deterministic gate with 12 fires, 0 FP → ELIGIBLE
#   (b) deterministic gate with 9 fires → NOT eligible (needs 1 more)
#   (c) deterministic gate with 12 fires, 2 FP (>5%) → NOT eligible (FP-rate)
#   (d) judge gate with calibrated:true → ELIGIBLE
#   (e) judge gate with calibrated:false → NOT eligible
#   (f) --record-fp appends an FP label to the FP log
#   (g) --json shape valid (required keys present, array per gate)
#   (h) empty telemetry → all NOT eligible, no crash (fail-open)
#
# Usage: bash tests/test_gate_flip_status.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/verify/gate-flip-status.mjs"

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
    pass "$label (contains '${needle}')"
  else
    fail "$label — output does not contain '${needle}'"$'\n'"  Got: $haystack"
  fi
}

assert_not_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    fail "$label — output unexpectedly contains '${needle}'"
  else
    pass "$label (does not contain '${needle}')"
  fi
}

if ! command -v node &>/dev/null; then
  echo "FAIL: node not on PATH" >&2; exit 1
fi

echo ""
echo "gate-flip-status test suite"
echo "---------------------------"

W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT

# Helper: write N gate_fired events for a gate into a telemetry session file.
# Usage: write_fires <telem_dir> <gate> <count>
write_fires() {
  local tdir="$1" gate="$2" count="$3"
  mkdir -p "$tdir"
  local out=""
  for i in $(seq 1 "$count"); do
    out+='{"event":"gate_fired","gate":"'"$gate"'","status":"passed","ts":"2026-06-15T10:00:00Z","change_counter":'"$i"'}'$'\n'
  done
  printf '%s' "$out" > "$tdir/session.jsonl"
}

# Helper: write a calibration JSON for a judge gate.
# Usage: write_cal <cal_dir> <gate> <calibrated:true|false>
write_cal() {
  local cdir="$1" gate="$2" cal="$3"
  mkdir -p "$cdir"
  local reason=""
  if [ "$cal" = "false" ]; then
    reason="advisory — n=5 < 40"
  fi
  cat > "$cdir/${gate}.json" <<EOF
{
  "gate": "$gate",
  "calibrated": $cal,
  "n": 5,
  "balanced_accuracy": 0.9,
  "tnr": 0.85,
  "blocking_reason": "$reason",
  "updated_at": "2026-06-15T10:00:00Z"
}
EOF
}

# ── (a) deterministic gate: 12 fires, 0 FP → ELIGIBLE ────────────────────────

echo ""
echo "(a) deterministic gate: 12 fires, 0 FP → ELIGIBLE"

TDIR_A="$W/a/telem"
write_fires "$TDIR_A" "anti_slop" 12

set +e
OUT_A="$(
  SIGMA_TELEMETRY_DIR="$TDIR_A" \
  SIGMA_CALIBRATION_DIR="$W/a/cal" \
  SIGMA_FLIP_DIR="$W/a/flip" \
  FLIP_MIN_FIRES=10 \
  FLIP_MAX_FP_RATE=0.05 \
  node "$SCRIPT" --json 2>&1
)"
EXIT_A=$?
set -e

assert_exit "(a) exits 0" 0 "$EXIT_A"

# Parse the anti_slop gate entry from JSON output.
A_ELIGIBLE="$(echo "$OUT_A" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="anti_slop");
    if(!g){process.stderr.write("anti_slop gate not in output\n");process.exit(1);}
    process.stdout.write(String(g.eligibleToBlock));
  });
' 2>&1)"

if [ "$A_ELIGIBLE" = "true" ]; then
  pass "(a) anti_slop eligibleToBlock=true (12 fires, 0 FP)"
else
  fail "(a) expected eligibleToBlock=true, got: $A_ELIGIBLE"
fi

assert_contains "(a) ELIGIBLE appears in reason" "ELIGIBLE" "$(echo "$OUT_A" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="anti_slop");
    process.stdout.write(g ? g.reason : "");
  });
')"

# ── (b) deterministic gate: 9 fires → NOT eligible (needs 1 more) ────────────

echo ""
echo "(b) deterministic gate: 9 fires → NOT eligible (needs 1 more)"

TDIR_B="$W/b/telem"
write_fires "$TDIR_B" "anti_slop" 9

set +e
OUT_B="$(
  SIGMA_TELEMETRY_DIR="$TDIR_B" \
  SIGMA_CALIBRATION_DIR="$W/b/cal" \
  SIGMA_FLIP_DIR="$W/b/flip" \
  FLIP_MIN_FIRES=10 \
  FLIP_MAX_FP_RATE=0.05 \
  node "$SCRIPT" --json 2>&1
)"
EXIT_B=$?
set -e

assert_exit "(b) exits 0" 0 "$EXIT_B"

B_ELIGIBLE="$(echo "$OUT_B" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="anti_slop");
    process.stdout.write(g ? String(g.eligibleToBlock) : "missing");
  });
')"

if [ "$B_ELIGIBLE" = "false" ]; then
  pass "(b) anti_slop eligibleToBlock=false (9/10 fires)"
else
  fail "(b) expected eligibleToBlock=false, got: $B_ELIGIBLE"
fi

B_REASON="$(echo "$OUT_B" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="anti_slop");
    process.stdout.write(g ? g.reason : "");
  });
')"
assert_contains "(b) reason mentions 'needs 1 more'" "needs 1 more" "$B_REASON"

# ── (c) deterministic gate: 12 fires, 2 FP (>5%) → NOT eligible ──────────────

echo ""
echo "(c) deterministic gate: 12 fires, 2 FP (>5%) → NOT eligible (FP-rate)"

TDIR_C="$W/c/telem"
write_fires "$TDIR_C" "anti_slop" 12

# Write 2 FP records into the FP log.
mkdir -p "$W/c/flip"
printf '{"gate":"anti_slop","ts":"2026-06-15T09:00:00Z","operator":"test"}\n' >> "$W/c/flip/false-positives.jsonl"
printf '{"gate":"anti_slop","ts":"2026-06-15T09:01:00Z","operator":"test"}\n' >> "$W/c/flip/false-positives.jsonl"

set +e
OUT_C="$(
  SIGMA_TELEMETRY_DIR="$TDIR_C" \
  SIGMA_CALIBRATION_DIR="$W/c/cal" \
  SIGMA_FLIP_DIR="$W/c/flip" \
  FLIP_MIN_FIRES=10 \
  FLIP_MAX_FP_RATE=0.05 \
  node "$SCRIPT" --json 2>&1
)"
EXIT_C=$?
set -e

assert_exit "(c) exits 0" 0 "$EXIT_C"

C_ELIGIBLE="$(echo "$OUT_C" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="anti_slop");
    process.stdout.write(g ? String(g.eligibleToBlock) : "missing");
  });
')"

if [ "$C_ELIGIBLE" = "false" ]; then
  pass "(c) anti_slop eligibleToBlock=false (FP-rate 16.7% > 5%)"
else
  fail "(c) expected eligibleToBlock=false, got: $C_ELIGIBLE"
fi

C_REASON="$(echo "$OUT_C" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="anti_slop");
    process.stdout.write(g ? g.reason : "");
  });
')"
assert_contains "(c) reason mentions FP-rate" "FP-rate" "$C_REASON"

# ── (d) judge gate: calibrated:true → ELIGIBLE ───────────────────────────────

echo ""
echo "(d) judge gate: calibrated:true → ELIGIBLE"

TDIR_D="$W/d/telem"
mkdir -p "$TDIR_D"
write_cal "$W/d/cal" "gap_analysis" "true"

set +e
OUT_D="$(
  SIGMA_TELEMETRY_DIR="$TDIR_D" \
  SIGMA_CALIBRATION_DIR="$W/d/cal" \
  SIGMA_FLIP_DIR="$W/d/flip" \
  FLIP_MIN_FIRES=10 \
  FLIP_MAX_FP_RATE=0.05 \
  node "$SCRIPT" --json 2>&1
)"
EXIT_D=$?
set -e

assert_exit "(d) exits 0" 0 "$EXIT_D"

D_ELIGIBLE="$(echo "$OUT_D" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="gap_analysis");
    process.stdout.write(g ? String(g.eligibleToBlock) : "missing");
  });
')"

if [ "$D_ELIGIBLE" = "true" ]; then
  pass "(d) gap_analysis eligibleToBlock=true (calibrated:true)"
else
  fail "(d) expected eligibleToBlock=true, got: $D_ELIGIBLE"
fi

D_REASON="$(echo "$OUT_D" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="gap_analysis");
    process.stdout.write(g ? g.reason : "");
  });
')"
assert_contains "(d) reason says ELIGIBLE" "ELIGIBLE" "$D_REASON"

# ── (e) judge gate: calibrated:false → NOT eligible ──────────────────────────

echo ""
echo "(e) judge gate: calibrated:false → NOT eligible"

TDIR_E="$W/e/telem"
mkdir -p "$TDIR_E"
write_cal "$W/e/cal" "gap_analysis" "false"

set +e
OUT_E="$(
  SIGMA_TELEMETRY_DIR="$TDIR_E" \
  SIGMA_CALIBRATION_DIR="$W/e/cal" \
  SIGMA_FLIP_DIR="$W/e/flip" \
  FLIP_MIN_FIRES=10 \
  FLIP_MAX_FP_RATE=0.05 \
  node "$SCRIPT" --json 2>&1
)"
EXIT_E=$?
set -e

assert_exit "(e) exits 0" 0 "$EXIT_E"

E_ELIGIBLE="$(echo "$OUT_E" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="gap_analysis");
    process.stdout.write(g ? String(g.eligibleToBlock) : "missing");
  });
')"

if [ "$E_ELIGIBLE" = "false" ]; then
  pass "(e) gap_analysis eligibleToBlock=false (calibrated:false)"
else
  fail "(e) expected eligibleToBlock=false, got: $E_ELIGIBLE"
fi

E_REASON="$(echo "$OUT_E" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const g=j.gates.find(x=>x.gate==="gap_analysis");
    process.stdout.write(g ? g.reason : "");
  });
')"
assert_contains "(e) reason says NOT calibrated" "NOT calibrated" "$E_REASON"

# ── (f) --record-fp appends an FP label ──────────────────────────────────────

echo ""
echo "(f) --record-fp appends an FP label to the FP log"

TDIR_F="$W/f/telem"; mkdir -p "$TDIR_F"
FLIP_DIR_F="$W/f/flip"

set +e
OUT_F="$(
  SIGMA_TELEMETRY_DIR="$TDIR_F" \
  SIGMA_CALIBRATION_DIR="$W/f/cal" \
  SIGMA_FLIP_DIR="$FLIP_DIR_F" \
  node "$SCRIPT" --record-fp --gate anti_slop 2>&1
)"
EXIT_F=$?
set -e

assert_exit "(f) --record-fp exits 0" 0 "$EXIT_F"

FP_LOG_F="$FLIP_DIR_F/false-positives.jsonl"
if [ -f "$FP_LOG_F" ]; then
  F_GATE="$(node -e '
    const line=require("fs").readFileSync(process.argv[1],"utf8").trim().split("\n")[0];
    const r=JSON.parse(line);
    process.stdout.write(r.gate||"");
  ' "$FP_LOG_F" 2>&1)"
  if [ "$F_GATE" = "anti_slop" ]; then
    pass "(f) FP log contains anti_slop entry"
  else
    fail "(f) FP log gate mismatch: '$F_GATE'"
  fi
  # Verify ts field is present.
  F_HAS_TS="$(node -e '
    const line=require("fs").readFileSync(process.argv[1],"utf8").trim().split("\n")[0];
    const r=JSON.parse(line);
    process.stdout.write(r.ts ? "yes" : "no");
  ' "$FP_LOG_F" 2>&1)"
  if [ "$F_HAS_TS" = "yes" ]; then
    pass "(f) FP log entry has ts field"
  else
    fail "(f) FP log entry missing ts field"
  fi
else
  fail "(f) FP log not created at $FP_LOG_F"
fi

# ── (g) --json shape valid ────────────────────────────────────────────────────

echo ""
echo "(g) --json shape: required keys present, gates array has 7 entries"

TDIR_G="$W/g/telem"
write_fires "$TDIR_G" "anti_slop" 5

set +e
OUT_G="$(
  SIGMA_TELEMETRY_DIR="$TDIR_G" \
  SIGMA_CALIBRATION_DIR="$W/g/cal" \
  SIGMA_FLIP_DIR="$W/g/flip" \
  node "$SCRIPT" --json 2>&1
)"
EXIT_G=$?
set -e

assert_exit "(g) --json exits 0" 0 "$EXIT_G"

G_CHECK="$(echo "$OUT_G" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    try {
      const j=JSON.parse(chunks.join(""));
      const req=["generated_at","telemetry_events_loaded","thresholds","gates","summary","errors"];
      const miss=req.filter(k=>!(k in j));
      if(miss.length){process.stdout.write("missing: "+miss.join(", "));process.exit(1);}
      if(!Array.isArray(j.gates)){process.stdout.write("gates not array");process.exit(1);}
      if(j.gates.length!==7){process.stdout.write("expected 7 gates, got "+j.gates.length);process.exit(1);}
      const gReq=["gate","tier","eligibleToBlock","reason"];
      for(const g of j.gates){
        const gm=gReq.filter(k=>!(k in g));
        if(gm.length){process.stdout.write(g.gate+" missing: "+gm.join(", "));process.exit(1);}
      }
      process.stdout.write("ok gates="+j.gates.length+" summary="+JSON.stringify(j.summary));
    } catch(e){process.stdout.write("parse error: "+e.message);process.exit(1);}
  });
' 2>&1)"
G_CHECK_EXIT=$?

if [ "$G_CHECK_EXIT" -eq 0 ]; then
  pass "(g) --json structure valid ($G_CHECK)"
else
  fail "(g) --json structure: $G_CHECK"
fi

# Verify summary totals add up.
G_TOTAL_OK="$(echo "$OUT_G" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    const j=JSON.parse(chunks.join(""));
    const ok=(j.summary.eligible + j.summary.not_eligible === j.summary.total && j.summary.total===7);
    process.stdout.write(ok?"ok":"bad: "+JSON.stringify(j.summary));
  });
' 2>&1)"
if [ "$G_TOTAL_OK" = "ok" ]; then
  pass "(g) summary totals are consistent"
else
  fail "(g) summary totals: $G_TOTAL_OK"
fi

# ── (h) empty telemetry → all NOT eligible, no crash ─────────────────────────

echo ""
echo "(h) empty telemetry → all NOT eligible, no crash (fail-open)"

TDIR_H="$W/h/telem"
mkdir -p "$TDIR_H"
# No files in telem dir.

set +e
OUT_H="$(
  SIGMA_TELEMETRY_DIR="$TDIR_H" \
  SIGMA_CALIBRATION_DIR="$W/h/cal" \
  SIGMA_FLIP_DIR="$W/h/flip" \
  FLIP_MIN_FIRES=10 \
  FLIP_MAX_FP_RATE=0.05 \
  node "$SCRIPT" --json 2>&1
)"
EXIT_H=$?
set -e

assert_exit "(h) empty telemetry exits 0 (fail-open)" 0 "$EXIT_H"

H_CHECK="$(echo "$OUT_H" | node -e '
  const chunks=[]; process.stdin.on("data",d=>chunks.push(d)); process.stdin.on("end",()=>{
    try {
      const j=JSON.parse(chunks.join(""));
      if(!Array.isArray(j.gates)||j.gates.length!==7){process.stdout.write("bad gates array");process.exit(1);}
      // All deterministic gates must have eligibleToBlock=false (0 fires)
      // Judge gates without calibration reports also ineligible.
      const anyEligible=j.gates.filter(g=>g.eligibleToBlock);
      if(anyEligible.length>0){
        process.stdout.write("unexpected eligible gates: "+anyEligible.map(g=>g.gate).join(", "));
        process.exit(1);
      }
      process.stdout.write("ok all-ineligible events="+j.telemetry_events_loaded);
    } catch(e){process.stdout.write("parse error: "+e.message);process.exit(1);}
  });
' 2>&1)"
H_CHECK_EXIT=$?

if [ "$H_CHECK_EXIT" -eq 0 ]; then
  pass "(h) all gates ineligible with empty telemetry ($H_CHECK)"
else
  fail "(h) unexpected result: $H_CHECK"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "---------------------------"
echo "Results: $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
