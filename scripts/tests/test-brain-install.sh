#!/usr/bin/env bash
# Physical bench for scripts/install-brain.sh using a temp HOME.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_HOME="/tmp/brain-test-home"
VAULT="$TEST_HOME/Documents/Test Brain"
TRACE="$TEST_HOME/install-trace.txt"
STATUS_OUT="$TEST_HOME/brain-status.out"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

assert_dir() {
  [[ -d "$1" ]] || fail "missing dir: $1"
}

rm -rf "$TEST_HOME"
mkdir -p "$TEST_HOME"

HOME="$TEST_HOME" \
BRAIN_INSTALL_SKIP_CRON_LOAD=true \
BRAIN_INSTALL_TRACE_FILE="$TRACE" \
bash "$REPO_ROOT/scripts/install-brain.sh" --yes --vault-path "$VAULT" --skip-cron-load

HOME="$TEST_HOME" \
BRAIN_INSTALL_SKIP_CRON_LOAD=true \
BRAIN_INSTALL_TRACE_FILE="$TRACE" \
bash "$REPO_ROOT/scripts/install-brain.sh" --yes --vault-path "$VAULT" --skip-cron-load

assert_dir "$VAULT"
assert_dir "$VAULT/memory"
assert_dir "$VAULT/sessions"
assert_dir "$VAULT/research"
assert_file "$TEST_HOME/.claude/brain/.brain-config.yaml"
assert_file "$TEST_HOME/.claude/brain/scripts/compile.py"
assert_file "$TEST_HOME/.claude/brain/scripts/flush.py"
assert_file "$TEST_HOME/.claude/brain/scripts/query.py"
assert_file "$TEST_HOME/.claude/brain/scripts/evict.py"
assert_file "$TEST_HOME/.claude/brain/scripts/evolve.py"
assert_file "$TEST_HOME/.claude/brain/scripts/lint.py"
assert_file "$TEST_HOME/.claude/brain/scripts/update-hot-cache.sh"
assert_file "$TEST_HOME/.claude/brain/scripts/autoresearch.sh"
assert_file "$TEST_HOME/.claude/brain/scripts/autoresearch-gated.sh"

skill_count="$(find "$TEST_HOME/.claude/skills" -maxdepth 1 -type d -name 'brain-*' | wc -l | tr -d ' ')"
[[ "$skill_count" = "7" ]] || fail "expected 7 brain skills, got $skill_count"

python3 - "$TEST_HOME/.claude/settings.json" <<'PY'
import json
import sys
from pathlib import Path

settings = Path(sys.argv[1])
data = json.loads(settings.read_text(encoding="utf-8"))
hooks = data.get("hooks", {})
for event in ("SessionStart", "PreCompact", "Stop"):
    if event not in hooks:
        raise SystemExit(f"missing hook event: {event}")

checks = {
    "SessionStart": ".claude/brain/hooks/session-start.sh",
    "PreCompact": ".claude/brain/hooks/pre-compact.sh",
    "Stop": ".claude/brain/hooks/stop.sh",
    "SessionEnd": ".claude/brain/hooks/stop.sh",
}
for event, fragment in checks.items():
    commands = [
        hook.get("command", "")
        for entry in hooks.get(event, [])
        for hook in entry.get("hooks", [])
    ]
    matches = [command for command in commands if fragment in command]
    if not matches:
        raise SystemExit(f"missing hook command fragment for {event}: {fragment}")
    if len(matches) != 1:
        raise SystemExit(f"duplicate hook command fragment for {event}: {fragment}")
PY

assert_file "$TEST_HOME/Library/LaunchAgents/ai.sigma.brain-autoresearch.plist"
grep -q "$TEST_HOME/.claude/brain/scripts/autoresearch-gated.sh --force" "$TEST_HOME/Library/LaunchAgents/ai.sigma.brain-autoresearch.plist" || fail "launchd plist does not call gated runner"

PATH="$TEST_HOME/.local/bin:$PATH" HOME="$TEST_HOME" brain-status > "$STATUS_OUT"
grep -q "## Brain Status" "$STATUS_OUT" || fail "brain-status did not print dashboard"

cat > "$VAULT/sessions/2026-01-01.md" <<'EOF'
# Session - 2026-01-01

## Decisions
- Use one global brain for all local CLIs.

## Next
- Keep install scripts idempotent.
EOF

HOME="$TEST_HOME" bash "$TEST_HOME/.claude/brain/scripts/update-hot-cache.sh"
assert_file "$VAULT/hot.md"
grep -q "Use one global brain" "$VAULT/hot.md" || fail "hot cache did not capture decision"

HOME="$TEST_HOME" bash "$TEST_HOME/.claude/brain/scripts/autoresearch.sh" --dry-run

assert_file "$TRACE"
python3 - "$TRACE" "$TEST_HOME" <<'PY'
import sys
from pathlib import Path

trace = Path(sys.argv[1])
home = Path(sys.argv[2]).resolve()
bad = []
for raw in trace.read_text(encoding="utf-8").splitlines():
    if not raw.strip():
        continue
    path = Path(raw).resolve()
    if path != home and home not in path.parents:
        bad.append(str(path))
if bad:
    raise SystemExit("writes outside temp HOME:\n" + "\n".join(bad))
PY

echo "PASS: brain install bench"
