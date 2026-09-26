#!/usr/bin/env bash
# Hermetic tests for setup-providers.mjs (Step-0 Phase B.2 engine) +
# the fusion.mjs config consumer. No real CLIs, no network, no secrets.
#
# Strategy:
#   - Config output is redirected via SIGMA_PROVIDERS_CONFIG_PATH to a temp file.
#   - Detected voices are fed via --detected-file (a stub array) — detect-providers
#     is never run.
#   - The fusion regression writes into REPO_ROOT/.sigma (same as test_fusion.sh)
#     and is cleaned up on exit so it never pollutes other suites.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$REPO_ROOT/scripts/fusion/setup-providers.mjs"
FUSION="$REPO_ROOT/scripts/fusion/fusion.mjs"
TMP="$(mktemp -d)"
PASS=0
FAIL=0

# Clean up any config we drop into the real .sigma during the fusion regression.
cleanup() {
  rm -rf "$TMP"
  rm -f "$REPO_ROOT/.sigma/providers.config.json"
}
trap cleanup EXIT

ok()   { PASS=$((PASS+1)); echo "  ok: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

# A stub detected-voices array (2 supported CLIs and 1 opt-in API).
DETECTED="$TMP/detected.json"
cat > "$DETECTED" <<'JSON'
[
  { "id": "claude", "family": "anthropic", "via": "cli", "invoke": "claude --print -", "cost_tier": "high" },
  { "id": "codex", "family": "openai", "via": "cli", "invoke": "codex exec -", "cost_tier": "high" },
  { "id": "openrouter", "family": "openrouter", "via": "api", "invoke": "OPENROUTER_API", "cost_tier": "medium" }
]
JSON

CFG="$TMP/providers.config.json"
run_setup() { SIGMA_PROVIDERS_CONFIG_PATH="$CFG" node "$SETUP" --detected-file "$DETECTED" "$@"; }

echo "== setup-providers.mjs =="

# (a) basic enable + synthesizer
rm -f "$CFG"
if run_setup --enable claude,codex --synthesizer codex --json >"$TMP/a.out" 2>"$TMP/a.err"; then
  if node -e 'const c=require("'"$CFG"'");process.exit(JSON.stringify(c.enabledVoices)==="[\"claude\",\"codex\"]"&&c.synthesizer==="codex"?0:1)'; then
    ok "(a) enable + synthesizer recorded"
  else bad "(a) enabledVoices/synthesizer wrong: $(cat "$CFG")"; fi
else bad "(a) exited nonzero: $(cat "$TMP/a.err")"; fi

# (b) default enable = all detected when --enable omitted
rm -f "$CFG"
if run_setup >"$TMP/b.out" 2>"$TMP/b.err"; then
  if node -e 'const c=require("'"$CFG"'");process.exit(JSON.stringify(c.enabledVoices)==="[\"claude\",\"codex\"]"?0:1)'; then
    ok "(b) default enable = detected voices"
  else bad "(b) default enable wrong: $(cat "$CFG")"; fi
else bad "(b) exited nonzero: $(cat "$TMP/b.err")"; fi

# (c) api-keys records env-var NAME + enables voice
rm -f "$CFG"
if run_setup --enable claude --api-keys openrouter,glm >"$TMP/c.out" 2>"$TMP/c.err"; then
  if node -e '
    const c=require("'"$CFG"'");
    const ok = c.apiKeys.openrouter.envVar==="OPENROUTER_API_KEY" && c.apiKeys.openrouter.enabled===true
      && c.apiKeys.glm.envVar==="ZHIPUAI_API_KEY" && c.apiKeys.glm.enabled===true
      && c.apiKeys.minimax.enabled===false
      && c.enabledVoices.includes("openrouter") && c.enabledVoices.includes("glm");
    process.exit(ok?0:1)'; then
    ok "(c) api-keys → env-var NAMES + voices enabled"
  else bad "(c) api-keys block wrong: $(cat "$CFG")"; fi
else bad "(c) exited nonzero: $(cat "$TMP/c.err")"; fi

# (d) SECRET REFUSAL — a key-looking token must be rejected and nothing written.
rm -f "$CFG"
FAKE_SECRET="sk-$(printf 'x%.0s' $(seq 1 48))"   # constructed at runtime — no literal key in this file
if run_setup --enable "$FAKE_SECRET" >"$TMP/d.out" 2>"$TMP/d.err"; then
  bad "(d) accepted a secret-looking value (should refuse)"
else
  if [ ! -f "$CFG" ] && grep -qi "never key values\|valid id" "$TMP/d.err"; then
    ok "(d) refused secret-looking value, wrote nothing"
  else bad "(d) refused but config exists or wrong message: $(cat "$TMP/d.err")"; fi
fi

# (e) unknown id rejected
rm -f "$CFG"
if run_setup --enable claude,not-a-real-voice >"$TMP/e.out" 2>"$TMP/e.err"; then
  bad "(e) accepted unknown id"
else
  if grep -qi "unknown enable id" "$TMP/e.err"; then ok "(e) unknown id rejected"
  else bad "(e) wrong error: $(cat "$TMP/e.err")"; fi
fi

# (f) synthesizer not in enabled → falls back, still valid (synth ∈ enabled)
rm -f "$CFG"
if run_setup --enable claude,codex --synthesizer openrouter >"$TMP/f.out" 2>"$TMP/f.err"; then
  if node -e 'const c=require("'"$CFG"'");process.exit(c.enabledVoices.includes(c.synthesizer)?0:1)' \
     && grep -qi "not in the enabled set" "$TMP/f.err"; then
    ok "(f) out-of-set synthesizer falls back + warns"
  else bad "(f) fallback wrong: $(cat "$CFG") / $(cat "$TMP/f.err")"; fi
else bad "(f) exited nonzero: $(cat "$TMP/f.err")"; fi

# (g) NAMES-ONLY invariant — config carries env-var names, never a value.
rm -f "$CFG"
run_setup --enable claude --api-keys openrouter >/dev/null 2>&1
if grep -q "OPENROUTER_API_KEY" "$CFG" && ! grep -qiE 'sk-[a-z0-9]{20}|"[A-Za-z0-9_-]{40,}"' "$CFG"; then
  ok "(g) names-only: env-var name present, no secret value"
else bad "(g) names-only invariant violated: $(cat "$CFG")"; fi

# (h) idempotent re-run — enabledVoices stable
rm -f "$CFG"
run_setup --enable claude,codex --synthesizer claude >/dev/null 2>&1
H1="$(node -e 'process.stdout.write(JSON.stringify(require("'"$CFG"'").enabledVoices))')"
run_setup --enable claude,codex --synthesizer claude >/dev/null 2>&1
H2="$(node -e 'process.stdout.write(JSON.stringify(require("'"$CFG"'").enabledVoices))')"
if [ "$H1" = "$H2" ] && [ "$H1" = '["claude","codex"]' ]; then ok "(h) idempotent"
else bad "(h) not idempotent: $H1 vs $H2"; fi

# (i) valid JSON + zero banned markers
rm -f "$CFG"
run_setup --enable claude >/dev/null 2>&1
if node -e 'JSON.parse(require("fs").readFileSync("'"$CFG"'","utf8"))' 2>/dev/null; then ok "(i) output is valid JSON"
else bad "(i) invalid JSON"; fi

# (k) API voice detected via a key but NOT --api-keys'd → NOT auto-enabled (opt-in)
DETECTED_API="$TMP/detected_api.json"
cat > "$DETECTED_API" <<'JSON'
[
  { "id": "claude", "family": "anthropic", "via": "cli", "invoke": "x", "cost_tier": "high" },
  { "id": "openrouter", "family": "openrouter", "via": "api", "invoke": "OPENROUTER_API", "cost_tier": "medium" }
]
JSON
rm -f "$CFG"
if SIGMA_PROVIDERS_CONFIG_PATH="$CFG" node "$SETUP" --detected-file "$DETECTED_API" >/dev/null 2>&1 \
   && node -e 'const c=require("'"$CFG"'");process.exit((c.enabledVoices.includes("claude") && !c.enabledVoices.includes("openrouter") && c.apiKeys.openrouter.enabled===false)?0:1)'; then
  ok "(k) detected API voice not auto-enabled without --api-keys (opt-in)"
else bad "(k) API voice auto-enabled or run failed: $(cat "$CFG" 2>/dev/null)"; fi

echo "== fusion.mjs honors the config =="

# (j) fusion filters its panel to enabledVoices.
# Write a 3-voice cache + a config enabling only 2; stub every voice + synth.
mkdir -p "$REPO_ROOT/.sigma"
cat > "$REPO_ROOT/.sigma/providers.json" <<'JSON'
[
  { "id": "claude", "family": "anthropic", "via": "cli", "invoke": "echo claude-ran", "cost_tier": "high" },
  { "id": "codex", "family": "openai", "via": "cli", "invoke": "echo codex-ran", "cost_tier": "high" },
  { "id": "fixture-third", "family": "moonshot", "via": "cli", "invoke": "echo kimi-ran", "cost_tier": "medium" }
]
JSON
# Enable only claude + codex (drop fixture-third).
SIGMA_PROVIDERS_CONFIG_PATH="$REPO_ROOT/.sigma/providers.config.json" \
  node "$SETUP" --detected-file "$DETECTED" --enable claude,codex --synthesizer claude >/dev/null 2>&1

TASK="$TMP/task.txt"; echo "summarize this" > "$TASK"
OUT="$TMP/fusion.json"
FUSION_VOICE_CMD_CLAUDE="echo claude-analysis" \
FUSION_VOICE_CMD_CODEX="echo codex-analysis" \
FUSION_VOICE_CMD_FIXTURE_THIRD="echo kimi-analysis" \
FUSION_SYNTH_CMD="echo final-answer" \
  node "$FUSION" --task-file "$TASK" --json >"$OUT" 2>"$TMP/fusion.err"
if [ -s "$OUT" ] && node -e '
    const r=JSON.parse(require("fs").readFileSync("'"$OUT"'","utf8"));
    const panel=(r.panel||[]).map(p=>typeof p==="string"?p:p.id);
    const ok = !panel.includes("fixture-third") && panel.includes("claude") && panel.includes("codex");
    process.exit(ok?0:1)'; then
  ok "(j) fusion panel filtered to enabled voices (fixture-third dropped)"
else bad "(j) fusion did not honor config: $(cat "$OUT" 2>/dev/null) / $(cat "$TMP/fusion.err")"; fi

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
