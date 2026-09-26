#!/usr/bin/env bash
# Hermetic tests for the OpenRouter Fusion backend (--backend openrouter).
# The hosted call is stubbed via FUSION_OPENROUTER_CMD — no network, no key.
# BYO fallback uses stubbed local voices.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="$REPO_ROOT/scripts/fusion/fusion.mjs"
WORK="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
  rm -rf "$WORK"
  rm -f "$REPO_ROOT/.sigma/providers.json" "$REPO_ROOT/.sigma/providers.config.json"
}
trap cleanup EXIT

ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
field() { node -e 'const r=JSON.parse(require("fs").readFileSync("'"$1"'","utf8"));process.stdout.write(String(r["'"$2"'"]))' 2>/dev/null; }

# No real key — exercise the opt-in + fallback paths deterministically.
unset OPENROUTER_API_KEY

# BYO voices for the fallback path.
mkdir -p "$REPO_ROOT/.sigma"
rm -f "$REPO_ROOT/.sigma/providers.config.json"
cat > "$REPO_ROOT/.sigma/providers.json" <<'JSON'
[
  { "id": "claude", "family": "anthropic", "via": "cli", "invoke": "echo c", "cost_tier": "high" },
  { "id": "codex", "family": "openai", "via": "cli", "invoke": "echo x", "cost_tier": "high" }
]
JSON
export FUSION_VOICE_CMD_CLAUDE="echo claude-analysis"
export FUSION_VOICE_CMD_CODEX="echo codex-analysis"
export FUSION_SYNTH_CMD="echo byo-final"

TASK="$WORK/task.txt"; echo "do the thing" > "$TASK"

echo "== OpenRouter Fusion backend =="

# (a) --backend openrouter with a stubbed hosted call
if FUSION_OPENROUTER_CMD="echo openrouter-fusion-answer" \
   node "$CORE" --task-file "$TASK" --backend openrouter --json >"$WORK/a.json" 2>"$WORK/a.err"; then
  if node -e '
      const r=JSON.parse(require("fs").readFileSync("'"$WORK/a.json"'","utf8"));
      const ok = r.backend==="openrouter" && /openrouter-fusion-answer/.test(r.answer)
        && Array.isArray(r.families) && r.families[0]==="openrouter";
      process.exit(ok?0:1)'; then
    ok "(a) openrouter backend used (stubbed)"
  else bad "(a) wrong shape: $(cat "$WORK/a.json")"; fi
else bad "(a) exited nonzero: $(cat "$WORK/a.err")"; fi

# (b) --backend openrouter, NO key + NO stub → falls back to BYO + logs
if node "$CORE" --task-file "$TASK" --backend openrouter --json >"$WORK/b.json" 2>"$WORK/b.err"; then
  if [ "$(field "$WORK/b.json" backend)" = "byo" ] \
     && grep -qi "OPENROUTER_API_KEY" "$WORK/b.err" \
     && grep -qi "falling back" "$WORK/b.err"; then
    ok "(b) no key → fell back to BYO + logged"
  else bad "(b) fallback wrong: backend=$(field "$WORK/b.json" backend) err=$(cat "$WORK/b.err")"; fi
else bad "(b) exited nonzero: $(cat "$WORK/b.err")"; fi

# (c) explicit --backend byo
node "$CORE" --task-file "$TASK" --backend byo --json >"$WORK/c.json" 2>/dev/null
if [ "$(field "$WORK/c.json" backend)" = "byo" ]; then ok "(c) explicit byo"
else bad "(c) backend=$(field "$WORK/c.json" backend)"; fi

# (d) default backend = byo
node "$CORE" --task-file "$TASK" --json >"$WORK/d.json" 2>/dev/null
if [ "$(field "$WORK/d.json" backend)" = "byo" ]; then ok "(d) default = byo"
else bad "(d) backend=$(field "$WORK/d.json" backend)"; fi

# (e) unknown backend rejected
if node "$CORE" --task-file "$TASK" --backend bogus --json >/dev/null 2>"$WORK/e.err"; then
  bad "(e) unknown backend accepted"
else
  grep -qi "unknown --backend" "$WORK/e.err" && ok "(e) unknown backend rejected" \
    || bad "(e) wrong error: $(cat "$WORK/e.err")"
fi

# (f) stub returns empty → treated as unavailable → falls back to BYO
if FUSION_OPENROUTER_CMD="true" \
   node "$CORE" --task-file "$TASK" --backend openrouter --json >"$WORK/f.json" 2>"$WORK/f.err"; then
  if [ "$(field "$WORK/f.json" backend)" = "byo" ]; then ok "(f) empty hosted answer → BYO fallback"
  else bad "(f) backend=$(field "$WORK/f.json" backend)"; fi
else bad "(f) exited nonzero: $(cat "$WORK/f.err")"; fi

# (g) config did NOT opt into openrouter → --backend openrouter gated → BYO fallback
SIGMA_PROVIDERS_CONFIG_PATH="$REPO_ROOT/.sigma/providers.config.json" \
  node "$REPO_ROOT/scripts/fusion/setup-providers.mjs" --no-detect --enable claude,codex --synthesizer claude >/dev/null 2>&1
if FUSION_OPENROUTER_CMD="echo should-not-run" \
   node "$CORE" --task-file "$TASK" --backend openrouter --json >"$WORK/g.json" 2>"$WORK/g.err"; then
  if [ "$(field "$WORK/g.json" backend)" = "byo" ] && grep -qi "not opted into OpenRouter" "$WORK/g.err"; then
    ok "(g) config not opted in → openrouter gated, BYO fallback"
  else bad "(g) opt-in gate failed: backend=$(field "$WORK/g.json" backend) err=$(cat "$WORK/g.err")"; fi
else bad "(g) exited nonzero: $(cat "$WORK/g.err")"; fi
rm -f "$REPO_ROOT/.sigma/providers.config.json"

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
