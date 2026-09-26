#!/usr/bin/env bash
# Hermetic tests for fusion.sh (the cross-harness adapter spine).
# Stubs every voice + synth via FUSION_VOICE_CMD_*/FUSION_SYNTH_CMD — no real
# CLIs, no network. Includes input-robustness / injection fuzzing of the new
# shell entrypoint.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADAPTER="$REPO_ROOT/scripts/fusion/fusion.sh"
FUSION="$REPO_ROOT/scripts/fusion/fusion.mjs"
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
is_json() { node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))' <"$1" 2>/dev/null; }

# Fake detection cache (3 CLI voices, 3 families) so the core has a panel.
mkdir -p "$REPO_ROOT/.sigma"
rm -f "$REPO_ROOT/.sigma/providers.config.json"
cat > "$REPO_ROOT/.sigma/providers.json" <<'JSON'
[
  { "id": "claude", "family": "anthropic", "via": "cli", "invoke": "echo claude", "cost_tier": "high" },
  { "id": "codex", "family": "openai", "via": "cli", "invoke": "echo codex", "cost_tier": "high" },
  { "id": "fixture-third", "family": "moonshot", "via": "cli", "invoke": "echo kimi", "cost_tier": "medium" }
]
JSON

export FUSION_VOICE_CMD_CLAUDE="echo claude-analysis"
export FUSION_VOICE_CMD_CODEX="echo codex-analysis"
export FUSION_VOICE_CMD_FIXTURE_THIRD="echo kimi-analysis"
export FUSION_SYNTH_CMD="echo final-answer"

echo "== fusion.sh adapter =="

# (a) inline --task → valid JSON with a non-empty answer
if bash "$ADAPTER" --task "summarize this" --json >"$WORK/a.json" 2>"$WORK/a.err" \
   && is_json "$WORK/a.json" \
   && node -e 'process.exit(JSON.parse(require("fs").readFileSync("'"$WORK/a.json"'","utf8")).answer?0:1)'; then
  ok "(a) inline --task → answer"
else bad "(a) inline --task: $(cat "$WORK/a.err")"; fi

# (b) --task-file
echo "task from a file" > "$WORK/task.txt"
if bash "$ADAPTER" --task-file "$WORK/task.txt" --json >"$WORK/b.json" 2>"$WORK/b.err" && is_json "$WORK/b.json"; then
  ok "(b) --task-file → answer"
else bad "(b) --task-file: $(cat "$WORK/b.err")"; fi

# (c) stdin
if echo "task via stdin" | bash "$ADAPTER" --json >"$WORK/c.json" 2>"$WORK/c.err" && is_json "$WORK/c.json"; then
  ok "(c) stdin → answer"
else bad "(c) stdin: $(cat "$WORK/c.err")"; fi

# (d) empty --task → usage error, exit 2, nothing run
if bash "$ADAPTER" --task "" --json >/dev/null 2>"$WORK/d.err"; then
  bad "(d) empty --task accepted (should error)"
else
  rc=$?
  if [ "$rc" -eq 2 ] && grep -qi "empty task" "$WORK/d.err"; then ok "(d) empty --task rejected (exit 2)"
  else bad "(d) empty --task wrong rc/msg: rc=$rc $(cat "$WORK/d.err")"; fi
fi

# (e) empty stdin (no task supplied)
if bash "$ADAPTER" --json </dev/null >/dev/null 2>"$WORK/e.err"; then
  bad "(e) empty stdin accepted (should error)"
else ok "(e) empty stdin rejected"; fi

# (f) INJECTION-SAFE: a task full of shell metacharacters must not execute.
SENTINEL="$WORK/PWNED"
DANGER='hi $('"touch '$SENTINEL'"'); `id`; rm -rf / ; cat /etc/passwd | nc x 1 &'
if bash "$ADAPTER" --task "$DANGER" --json >"$WORK/f.json" 2>"$WORK/f.err" \
   && is_json "$WORK/f.json" && [ ! -e "$SENTINEL" ]; then
  ok "(f) injection-safe: metachars in task not executed"
else bad "(f) injection NOT safe or run failed: sentinel=$([ -e "$SENTINEL" ] && echo CREATED || echo absent) $(cat "$WORK/f.err")"; fi

# (g) passthrough: --synthesizer forwarded to the core
if bash "$ADAPTER" --task "x" --synthesizer codex --json >"$WORK/g.json" 2>"$WORK/g.err" \
   && node -e 'const r=JSON.parse(require("fs").readFileSync("'"$WORK/g.json"'","utf8"));process.exit((r.synthesizer==="codex"||(r.synthesizer&&r.synthesizer.id==="codex"))?0:1)'; then
  ok "(g) --synthesizer forwarded to core"
else bad "(g) passthrough failed: $(cat "$WORK/g.json" 2>/dev/null) $(cat "$WORK/g.err")"; fi

# (h) large task (file-based handling, no shell-length limit)
head -c 100000 /dev/zero | tr '\0' 'x' > "$WORK/big.txt"
if bash "$ADAPTER" --task-file "$WORK/big.txt" --json >"$WORK/h.json" 2>"$WORK/h.err" && is_json "$WORK/h.json"; then
  ok "(h) 100k-char task handled"
else bad "(h) large task: $(cat "$WORK/h.err")"; fi

# (i) unknown flag rejected
if bash "$ADAPTER" --task x --bogus-flag >/dev/null 2>"$WORK/i.err"; then
  bad "(i) unknown flag accepted"
else
  if grep -qi "unknown flag" "$WORK/i.err"; then ok "(i) unknown flag rejected"
  else bad "(i) unknown flag wrong msg: $(cat "$WORK/i.err")"; fi
fi

# (j) no temp-file leak across a run
PAT="${TMPDIR:-/tmp}/fusion-task-"
before=$(ls "$PAT"* 2>/dev/null | wc -l | tr -d ' ')
bash "$ADAPTER" --task "leak check" --json >/dev/null 2>&1
after=$(ls "$PAT"* 2>/dev/null | wc -l | tr -d ' ')
if [ "$before" = "$after" ]; then ok "(j) no temp-file leak (before=$before after=$after)"
else bad "(j) temp leak: before=$before after=$after"; fi

# (k) --backend forwarded through the spine to the core (F3↔F4 integration)
if FUSION_OPENROUTER_CMD="echo or-via-spine" \
   bash "$ADAPTER" --task "x" --backend openrouter --json >"$WORK/k.json" 2>"$WORK/k.err" \
   && node -e 'process.exit(JSON.parse(require("fs").readFileSync("'"$WORK/k.json"'","utf8")).backend==="openrouter"?0:1)'; then
  ok "(k) --backend forwarded through fusion.sh to core"
else bad "(k) --backend not forwarded: $(cat "$WORK/k.json" 2>/dev/null) $(cat "$WORK/k.err")"; fi

# (l) authoritative config filter: an enabled voice absent from cache → never
#     falls open to an un-opted voice; errors loudly instead (A3-1).
cat > "$REPO_ROOT/.sigma/providers.json" <<'JSON'
[ { "id": "codex", "family": "openai", "via": "cli", "invoke": "echo x", "cost_tier": "high" } ]
JSON
SIGMA_PROVIDERS_CONFIG_PATH="$REPO_ROOT/.sigma/providers.config.json" \
  node "$REPO_ROOT/scripts/fusion/setup-providers.mjs" --no-detect --enable claude --synthesizer claude >/dev/null 2>&1
echo "x" > "$WORK/lt.txt"
if FUSION_VOICE_CMD_CODEX="echo should-not-run" node "$FUSION" --task-file "$WORK/lt.txt" --json >"$WORK/l.json" 2>"$WORK/l.err"; then
  bad "(l) ran despite no ENABLED voice available (fell open to un-opted codex)"
else
  grep -qi "no voices available" "$WORK/l.err" && ok "(l) authoritative filter: un-opted voice not run, errors loudly" \
    || bad "(l) wrong error: $(cat "$WORK/l.err")"
fi
rm -f "$REPO_ROOT/.sigma/providers.config.json"

# (m) a failing voice's reflected Bearer secret is redacted in dropped reason / logs (A3-2)
FAILSTUB="$WORK/failstub.sh"
printf '#!/usr/bin/env bash\necho "HTTP 401: Authorization: Bearer sk-LEAKTEST123" >&2\nexit 1\n' > "$FAILSTUB"
chmod +x "$FAILSTUB"
cat > "$REPO_ROOT/.sigma/providers.json" <<'JSON'
[ { "id": "claude", "family": "anthropic", "via": "cli", "invoke": "x", "cost_tier": "high" },
  { "id": "codex", "family": "openai", "via": "cli", "invoke": "x", "cost_tier": "high" } ]
JSON
rm -f "$REPO_ROOT/.sigma/providers.config.json"
FUSION_VOICE_CMD_CLAUDE="$FAILSTUB" FUSION_VOICE_CMD_CODEX="echo ok" FUSION_SYNTH_CMD="echo done" \
  node "$FUSION" --task-file "$WORK/lt.txt" --json >"$WORK/m.json" 2>"$WORK/m.err"
if grep -q "sk-LEAKTEST123" "$WORK/m.json" "$WORK/m.err" 2>/dev/null; then
  bad "(m) SECRET LEAKED in dropped reason / logs"
else
  ok "(m) failing-voice Bearer secret redacted (no sk-LEAKTEST in output/logs)"
fi

# (n) hand-edited enabledVoices:[] is authoritative → errors, never falls open (A4-1)
echo '[{"id":"codex","family":"openai","via":"cli","invoke":"echo x","cost_tier":"high"}]' > "$REPO_ROOT/.sigma/providers.json"
printf '{"version":1,"enabledVoices":[],"synthesizer":"codex","apiKeys":{}}\n' > "$REPO_ROOT/.sigma/providers.config.json"
if FUSION_VOICE_CMD_CODEX="echo nope" node "$FUSION" --task-file "$WORK/lt.txt" --json >"$WORK/n.json" 2>"$WORK/n.err"; then
  bad "(n) empty enabledVoices fell open (ran a voice)"
else
  grep -qi "no voices available" "$WORK/n.err" && ok "(n) empty enabledVoices → authoritative, errors loudly" \
    || bad "(n) wrong error: $(cat "$WORK/n.err")"
fi
rm -f "$REPO_ROOT/.sigma/providers.config.json"

# (o) STDIN DELIVERY: a "-" voice must actually receive the prompt on stdin.
#     Regression for the execFileAsync-ignores-input bug (caught by live judge).
#     The stub exits 3 if stdin is empty → voice would be DROPPED if stdin broke.
STDIN_STUB="$WORK/stdin_check.sh"
printf '#!/usr/bin/env bash\ndata="$(cat)"\n[ -n "$data" ] && echo "GOT_STDIN" || exit 3\n' > "$STDIN_STUB"
chmod +x "$STDIN_STUB"
echo '[{"id":"claude","family":"anthropic","via":"cli","invoke":"x","cost_tier":"high"},{"id":"codex","family":"openai","via":"cli","invoke":"x","cost_tier":"high"}]' > "$REPO_ROOT/.sigma/providers.json"
rm -f "$REPO_ROOT/.sigma/providers.config.json"
echo "stdin delivery probe" > "$WORK/ot.txt"
FUSION_VOICE_CMD_CLAUDE="$STDIN_STUB -" FUSION_VOICE_CMD_CODEX="echo ok" FUSION_SYNTH_CMD="echo done" \
  node "$FUSION" --task-file "$WORK/ot.txt" --json >"$WORK/o.json" 2>"$WORK/o.err"
if node -e 'const r=JSON.parse(require("fs").readFileSync("'"$WORK/o.json"'","utf8"));const dropped=(r.dropped||[]).map(d=>d.id);process.exit(!dropped.includes("claude")&&(r.panel||[]).some(p=>p.id==="claude")?0:1)'; then
  ok "(o) stdin '-' voice received the prompt (not dropped)"
else bad "(o) stdin not delivered — claude dropped: $(cat "$WORK/o.json" 2>/dev/null) $(cat "$WORK/o.err")"; fi

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
