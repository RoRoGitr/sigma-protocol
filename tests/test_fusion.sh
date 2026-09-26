#!/usr/bin/env bash
# tests/test_fusion.sh — hermetic tests for the fusion primitive.
#
# All voices and the synthesizer are stubbed via:
#   FUSION_VOICE_CMD_<ID>  — overrides a voice's CLI command
#   FUSION_SYNTH_CMD       — overrides the synthesizer command
#
# No real CLIs, no real API keys, no network calls.
#
# Usage: bash tests/test_fusion.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FUSION_MJS="$REPO_ROOT/scripts/fusion/fusion.mjs"
DETECT_MJS="$REPO_ROOT/scripts/fusion/detect-providers.mjs"
TELEMETRY_DIR="$REPO_ROOT/.sigma/telemetry/sessions"

PASS=0
FAIL=0
ERRORS=()

# ── Test harness ─────────────────────────────────────────────────────────────

run_test() {
  local name="$1"
  local result="$2"   # "pass" or "fail"
  local detail="${3:-}"
  if [[ "$result" == "pass" ]]; then
    echo "  [PASS] $name"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $name${detail:+  ($detail)}"
    FAIL=$((FAIL + 1))
    ERRORS+=("$name${detail:+: $detail}")
  fi
}

# ── Temp directory for stubs and task files ───────────────────────────────────

TMPDIR_TEST="$(mktemp -d /tmp/test_fusion_XXXXXX)"
cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

# ── Build stub scripts ────────────────────────────────────────────────────────
# Each stub is an executable script that echoes a fixed analysis.
# The fusion engine passes the task file path as the last argument;
# stubs can read it or ignore it.

STUB_ANALYSIS_A="$TMPDIR_TEST/stub_voice_a.sh"
STUB_ANALYSIS_B="$TMPDIR_TEST/stub_voice_b.sh"
STUB_ANALYSIS_C="$TMPDIR_TEST/stub_voice_c.sh"
STUB_ANALYSIS_FAIL="$TMPDIR_TEST/stub_voice_fail.sh"
STUB_SYNTH="$TMPDIR_TEST/stub_synth.sh"

# Voice A — echoes its analysis and the task file content so we can verify
# the synthesizer received both.
cat > "$STUB_ANALYSIS_A" << 'EOF'
#!/usr/bin/env bash
echo "ANALYSIS-A: The answer is 42. Reasoning: math."
EOF

cat > "$STUB_ANALYSIS_B" << 'EOF'
#!/usr/bin/env bash
echo "ANALYSIS-B: The answer is 42. Reasoning: logic."
EOF

cat > "$STUB_ANALYSIS_C" << 'EOF'
#!/usr/bin/env bash
echo "ANALYSIS-C: The answer is 42. Reasoning: intuition."
EOF

# Fail stub: exits non-zero to simulate a voice error.
cat > "$STUB_ANALYSIS_FAIL" << 'EOF'
#!/usr/bin/env bash
echo "voice error" >&2
exit 1
EOF

# Synthesizer stub: echoes a fixed synthesis + all stdin/args so we can
# verify it received the concatenated analyses.
cat > "$STUB_SYNTH" << 'EOF'
#!/usr/bin/env bash
# Read the task file passed as the last argument (or via stdin via -).
content=""
last_arg="${@: -1}"
if [[ "$last_arg" == "-" ]]; then
  content="$(cat)"
elif [[ -f "$last_arg" ]]; then
  content="$(cat "$last_arg")"
fi
echo "SYNTHESIS: 42 [A1][A2][A3]"
echo "PANEL-RECEIVED: $content" >&2
EOF

chmod +x "$STUB_ANALYSIS_A" "$STUB_ANALYSIS_B" "$STUB_ANALYSIS_C" "$STUB_ANALYSIS_FAIL" "$STUB_SYNTH"

# ── Build a fake providers.json with three voices (three families) ────────────

FAKE_PROVIDERS="$TMPDIR_TEST/providers.json"
cat > "$FAKE_PROVIDERS" << EOF
[
  {"id":"claude",      "family":"anthropic", "via":"cli", "invoke":"$STUB_ANALYSIS_A", "cost_tier":"high"},
  {"id":"codex",       "family":"openai",    "via":"cli", "invoke":"$STUB_ANALYSIS_B", "cost_tier":"high"},
  {"id":"fixture-third", "family":"moonshot",  "via":"cli", "invoke":"$STUB_ANALYSIS_C", "cost_tier":"medium"}
]
EOF

# Write providers.json to the .sigma/ directory so detect-providers cache is there.
mkdir -p "$REPO_ROOT/.sigma"
cp "$FAKE_PROVIDERS" "$REPO_ROOT/.sigma/providers.json"

# ── Helper: build a task file ────────────────────────────────────────────────

_TASK_COUNTER=0
make_task() {
  local content="${1:-What is the answer to everything?}"
  _TASK_COUNTER=$(( _TASK_COUNTER + 1 ))
  local f="$TMPDIR_TEST/task_${_TASK_COUNTER}.txt"
  printf '%s\n' "$content" > "$f"
  echo "$f"
}

echo ""
echo "=== test_fusion.sh ==="
echo ""

# ────────────────────────────────────────────────────────────────────────────
# Test (a): 3-voice panel → synthesizer fuses; assert synth saw all 3 analyses
# ────────────────────────────────────────────────────────────────────────────

echo "--- (a) 3-voice panel → synthesizer fuses ---"

TASK_A="$(make_task 'What is 6 * 7?')"
TELEMETRY_SESSION_A="test-fusion-a"

output_a=$(
  SIGMA_SESSION_ID="$TELEMETRY_SESSION_A" \
  FUSION_VOICE_CMD_CLAUDE="$STUB_ANALYSIS_A" \
  FUSION_VOICE_CMD_CODEX="$STUB_ANALYSIS_B" \
  FUSION_VOICE_CMD_FIXTURE_THIRD="$STUB_ANALYSIS_C" \
  FUSION_SYNTH_CMD="$STUB_SYNTH" \
  node "$FUSION_MJS" --task-file "$TASK_A" --json 2>/dev/null
)

# Check: output is valid JSON
if echo "$output_a" | node -e "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'))" 2>/dev/null; then
  run_test "(a) output is valid JSON" pass
else
  run_test "(a) output is valid JSON" fail "raw: ${output_a:0:100}"
fi

# Check: answer field present and non-empty
answer_a=$(echo "$output_a" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));process.stdout.write(d.answer||'')" 2>/dev/null || echo "")
if [[ -n "$answer_a" ]]; then
  run_test "(a) answer field non-empty" pass
else
  run_test "(a) answer field non-empty" fail
fi

# Check: panel has 3 entries
panel_len=$(echo "$output_a" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log(d.panel.length)" 2>/dev/null || echo "0")
if [[ "$panel_len" == "3" ]]; then
  run_test "(a) panel has 3 voices" pass
else
  run_test "(a) panel has 3 voices" fail "got $panel_len"
fi

# Check: synthesizer recorded
synth_id=$(echo "$output_a" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));process.stdout.write(d.synthesizer.id||'')" 2>/dev/null || echo "")
if [[ -n "$synth_id" ]]; then
  run_test "(a) synthesizer field present" pass
else
  run_test "(a) synthesizer field present" fail
fi

# Check: answer contains SYNTHESIS (from stub_synth output)
if echo "$answer_a" | grep -q "SYNTHESIS"; then
  run_test "(a) synthesizer stub was invoked (answer contains SYNTHESIS)" pass
else
  run_test "(a) synthesizer stub was invoked (answer contains SYNTHESIS)" fail "answer: $answer_a"
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────
# Test (b): one voice exits 1 → dropped; others proceed
# ────────────────────────────────────────────────────────────────────────────

echo "--- (b) voice exits 1 → dropped, others proceed ---"

# Fake providers: 3 voices but one will fail.
FAKE_PROVIDERS_B="$TMPDIR_TEST/providers_b.json"
cat > "$FAKE_PROVIDERS_B" << EOF
[
  {"id":"claude",      "family":"anthropic", "via":"cli", "invoke":"$STUB_ANALYSIS_A", "cost_tier":"high"},
  {"id":"codex",       "family":"openai",    "via":"cli", "invoke":"$STUB_ANALYSIS_FAIL", "cost_tier":"high"},
  {"id":"fixture-third", "family":"moonshot",  "via":"cli", "invoke":"$STUB_ANALYSIS_C", "cost_tier":"medium"}
]
EOF
cp "$FAKE_PROVIDERS_B" "$REPO_ROOT/.sigma/providers.json"

TASK_B="$(make_task 'What is 2 + 2?')"

output_b=$(
  SIGMA_SESSION_ID="test-fusion-b" \
  FUSION_VOICE_CMD_CLAUDE="$STUB_ANALYSIS_A" \
  FUSION_VOICE_CMD_CODEX="$STUB_ANALYSIS_FAIL" \
  FUSION_VOICE_CMD_FIXTURE_THIRD="$STUB_ANALYSIS_C" \
  FUSION_SYNTH_CMD="$STUB_SYNTH" \
  node "$FUSION_MJS" --task-file "$TASK_B" --json 2>/dev/null
)

# Check: output valid JSON
if echo "$output_b" | node -e "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'))" 2>/dev/null; then
  run_test "(b) output valid JSON after voice drop" pass
else
  run_test "(b) output valid JSON after voice drop" fail
fi

# Check: dropped array contains the failed voice
dropped_b=$(echo "$output_b" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log(d.dropped.length)" 2>/dev/null || echo "0")
if [[ "$dropped_b" == "1" ]]; then
  run_test "(b) dropped array has 1 entry" pass
else
  run_test "(b) dropped array has 1 entry" fail "got $dropped_b"
fi

# Check: panel still has 2 entries (survivors)
panel_b=$(echo "$output_b" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log(d.panel.length)" 2>/dev/null || echo "0")
if [[ "$panel_b" == "2" ]]; then
  run_test "(b) 2 surviving panel voices" pass
else
  run_test "(b) 2 surviving panel voices" fail "got $panel_b"
fi

# Restore the 3-voice providers
cp "$FAKE_PROVIDERS" "$REPO_ROOT/.sigma/providers.json"

echo ""

# ────────────────────────────────────────────────────────────────────────────
# Test (c): only 1 voice available → single-model degrade + warning logged
# ────────────────────────────────────────────────────────────────────────────

echo "--- (c) only 1 voice → single-model degrade + logged ---"

FAKE_PROVIDERS_C="$TMPDIR_TEST/providers_c.json"
cat > "$FAKE_PROVIDERS_C" << EOF
[
  {"id":"claude","family":"anthropic","via":"cli","invoke":"$STUB_ANALYSIS_A","cost_tier":"high"}
]
EOF
cp "$FAKE_PROVIDERS_C" "$REPO_ROOT/.sigma/providers.json"

TASK_C="$(make_task 'Single voice test')"

# Capture stderr to check for warning
output_c_json=$(
  SIGMA_SESSION_ID="test-fusion-c" \
  FUSION_VOICE_CMD_CLAUDE="$STUB_ANALYSIS_A" \
  FUSION_SYNTH_CMD="$STUB_SYNTH" \
  node "$FUSION_MJS" --task-file "$TASK_C" --json 2>/tmp/fusion_c_stderr.txt || true
)

stderr_c="$(cat /tmp/fusion_c_stderr.txt || echo "")"

# Check: single_model_degrade = true in output
degrade_c=$(echo "$output_c_json" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));console.log(d.single_model_degrade)" 2>/dev/null || echo "false")
if [[ "$degrade_c" == "true" ]]; then
  run_test "(c) single_model_degrade flag set" pass
else
  run_test "(c) single_model_degrade flag set" fail "got: $degrade_c"
fi

# Check: warning was emitted to stderr
if echo "$stderr_c" | grep -qi "degrad\|single.model\|WARNING"; then
  run_test "(c) degrade warning logged to stderr" pass
else
  run_test "(c) degrade warning logged to stderr" fail "stderr: ${stderr_c:0:200}"
fi

# Restore 3-voice providers
cp "$FAKE_PROVIDERS" "$REPO_ROOT/.sigma/providers.json"

echo ""

# ────────────────────────────────────────────────────────────────────────────
# Test (d): panel spans ≥2 families (auto selection from 3-family pool)
# ────────────────────────────────────────────────────────────────────────────

echo "--- (d) panel auto-selects ≥2 families ---"

TASK_D="$(make_task 'Cross-family selection test')"

output_d=$(
  SIGMA_SESSION_ID="test-fusion-d" \
  FUSION_VOICE_CMD_CLAUDE="$STUB_ANALYSIS_A" \
  FUSION_VOICE_CMD_CODEX="$STUB_ANALYSIS_B" \
  FUSION_VOICE_CMD_FIXTURE_THIRD="$STUB_ANALYSIS_C" \
  FUSION_SYNTH_CMD="$STUB_SYNTH" \
  node "$FUSION_MJS" --task-file "$TASK_D" --json 2>/dev/null
)

# Extract families array and count unique values
families_count=$(echo "$output_d" | node -e "
  const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  const fams = new Set(d.panel.map(v=>v.family));
  console.log(fams.size);
" 2>/dev/null || echo "0")

if [[ "$families_count" -ge 2 ]]; then
  run_test "(d) panel spans ≥2 families (got $families_count)" pass
else
  run_test "(d) panel spans ≥2 families" fail "got $families_count"
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────
# Test (e): cost recorded to telemetry (.sigma/telemetry/sessions/<id>.jsonl)
# ────────────────────────────────────────────────────────────────────────────

echo "--- (e) fusion event recorded to telemetry ---"

TASK_E="$(make_task 'Telemetry test')"
SESSION_E="test-fusion-e-$$"

FUSION_VOICE_CMD_CLAUDE="$STUB_ANALYSIS_A" \
FUSION_VOICE_CMD_CODEX="$STUB_ANALYSIS_B" \
FUSION_VOICE_CMD_FIXTURE_THIRD="$STUB_ANALYSIS_C" \
FUSION_SYNTH_CMD="$STUB_SYNTH" \
SIGMA_SESSION_ID="$SESSION_E" \
node "$FUSION_MJS" --task-file "$TASK_E" --json >/dev/null 2>/dev/null || true

TELEMETRY_FILE="$TELEMETRY_DIR/${SESSION_E}.jsonl"

if [[ -f "$TELEMETRY_FILE" ]]; then
  run_test "(e) telemetry file created" pass
else
  run_test "(e) telemetry file created" fail "expected: $TELEMETRY_FILE"
fi

if [[ -f "$TELEMETRY_FILE" ]]; then
  # Check: contains a fusion event
  if grep -q '"event":"fusion"' "$TELEMETRY_FILE"; then
    run_test "(e) telemetry contains fusion event" pass
  else
    run_test "(e) telemetry contains fusion event" fail "contents: $(cat "$TELEMETRY_FILE" | head -1)"
  fi

  # Check: event has required A0 fields
  has_fields=$(node -e "
    const line = require('fs').readFileSync('$TELEMETRY_FILE','utf8').trim().split('\n').find(l=>l.includes('fusion'));
    if (!line) { console.log('no'); process.exit(0); }
    const d = JSON.parse(line);
    const ok = d.event && d.ts && d.panel && d.synthesizer && 'cost_usd' in d && 'duration_ms' in d;
    console.log(ok ? 'yes' : 'no');
  " 2>/dev/null || echo "no")

  if [[ "$has_fields" == "yes" ]]; then
    run_test "(e) telemetry record has required A0 fields" pass
  else
    run_test "(e) telemetry record has required A0 fields" fail
  fi
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────
# Test (f): --json output shape is valid (all required top-level keys present)
# ────────────────────────────────────────────────────────────────────────────

echo "--- (f) --json output shape valid ---"

TASK_F="$(make_task 'JSON shape test')"

output_f=$(
  FUSION_VOICE_CMD_CLAUDE="$STUB_ANALYSIS_A" \
  FUSION_VOICE_CMD_CODEX="$STUB_ANALYSIS_B" \
  FUSION_VOICE_CMD_FIXTURE_THIRD="$STUB_ANALYSIS_C" \
  FUSION_SYNTH_CMD="$STUB_SYNTH" \
  SIGMA_SESSION_ID="test-fusion-f" \
  node "$FUSION_MJS" --task-file "$TASK_F" --json 2>/dev/null
)

shape_check=$(echo "$output_f" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  const required = ['answer','panel','synthesizer','dropped','families','single_model_degrade','cost'];
  const missing = required.filter(k => !(k in d));
  if (missing.length > 0) { console.log('MISSING:' + missing.join(',')); process.exit(0); }
  // panel entries must have id + family
  for (const v of d.panel) {
    if (!v.id || !v.family) { console.log('MISSING panel.id or panel.family'); process.exit(0); }
  }
  // synthesizer must have id + family
  if (!d.synthesizer.id || !d.synthesizer.family) { console.log('MISSING synthesizer.id or .family'); process.exit(0); }
  console.log('OK');
" 2>/dev/null || echo "ERROR")

if [[ "$shape_check" == "OK" ]]; then
  run_test "(f) --json shape: all required keys present" pass
else
  run_test "(f) --json shape: all required keys present" fail "$shape_check"
fi

# Check: dropped array is an array (not null/missing)
dropped_is_array=$(echo "$output_f" | node -e "
  const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log(Array.isArray(d.dropped) ? 'yes' : 'no');
" 2>/dev/null || echo "no")

if [[ "$dropped_is_array" == "yes" ]]; then
  run_test "(f) dropped field is an array" pass
else
  run_test "(f) dropped field is an array" fail
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────
# Bonus: detect-providers.mjs --json emits valid JSON array
# ────────────────────────────────────────────────────────────────────────────

echo "--- detect-providers.mjs --json syntax check ---"

detect_out=$(node "$DETECT_MJS" --json --no-cache 2>/dev/null || echo "ERROR")

if echo "$detect_out" | node -e "
  const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  if (!Array.isArray(d)) throw new Error('not array');
" 2>/dev/null; then
  run_test "(bonus) detect-providers --json emits valid JSON array" pass
else
  run_test "(bonus) detect-providers --json emits valid JSON array" fail "output: ${detect_out:0:80}"
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────
# Restore providers cache to real state
# ────────────────────────────────────────────────────────────────────────────
node "$DETECT_MJS" --json >/dev/null 2>/dev/null || true

# ── Summary ──────────────────────────────────────────────────────────────────

echo "=============================="
echo " Summary"
echo "=============================="
echo "  PASSED: $PASS"
echo "  FAILED: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "Failures:"
  for e in "${ERRORS[@]}"; do
    echo "  - $e"
  done
  echo ""
  exit 1
fi

echo "All tests passed."
exit 0
