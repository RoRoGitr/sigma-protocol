#!/bin/bash
# test_dispatch_prompts_schema.sh
#
# D1 integration test: runs sync-dashboard.sh against a small fixture workspace
# and verifies briefing.json contains dispatch_prompts with the 3 required keys.
#
# Exit 0 = PASS. Exit non-zero = FAIL with diagnostic output.
#
# Usage: bash tests/test_dispatch_prompts_schema.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYNC_SCRIPT="$REPO_ROOT/templates/commandboard/sync-dashboard.sh"
LIB_DIR="$REPO_ROOT/templates/commandboard/lib"

# ── Dependency checks ──────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
    echo "FAIL: jq is required. Install via: brew install jq" >&2
    exit 1
fi

if ! command -v kanban-md &>/dev/null; then
    echo "FAIL: kanban-md is required. Install via: npm install -g kanban-md" >&2
    exit 1
fi

# ── Fixture workspace setup ───────────────────────────────────────────────────
FIXTURE_HOME="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_HOME"' EXIT

FIXTURE_CB="$FIXTURE_HOME/.commandboard"
FIXTURE_WS="$FIXTURE_CB/workspaces/test-project"

mkdir -p "$FIXTURE_WS" "$FIXTURE_CB/lib"

# Copy hq_state.py and schema into the fixture's lib dir.
cp "$LIB_DIR/hq_state.py" "$FIXTURE_CB/lib/"
cp "$LIB_DIR/dispatch_prompts.schema.json" "$FIXTURE_CB/lib/"

# Workspace config — kanban-md >=10 requires version, priorities, tui, next_id.
mkdir -p "$FIXTURE_WS/tasks"
cat > "$FIXTURE_WS/config.yml" <<'YAML'
version: 10
board:
    name: d1-fixture
tasks_dir: tasks
statuses:
    - name: todo
    - name: doing
    - name: done
priorities:
    - low
    - medium
    - high
defaults:
    status: todo
    priority: medium
    class: standard
classes:
    - name: standard
tui:
    title_lines: 1
next_id: 1
YAML

# Create a kanban task using kanban-md.
kanban-md create \
    --dir "$FIXTURE_WS" \
    --title "D1 test task: wire dispatch prompts" \
    --body "Fixture task for schema integration test." \
    --status todo \
    --priority high \
    >/dev/null 2>&1 || {
    echo "FAIL: kanban-md create failed — cannot seed fixture workspace" >&2
    exit 1
}

# ── Run sync-dashboard.sh against the fixture ─────────────────────────────────
export SIGMAHQ_HOME="$FIXTURE_CB"
export CLAUDE_CODE_COMMANDBOARD="$FIXTURE_CB"

# sync-dashboard.sh tries to open dashboard.html — create a stub so it doesn't
# fail on missing template, and pass --no-open to skip the open call.
cat > "$FIXTURE_CB/dashboard.html" <<'HTML'
<!DOCTYPE html><html><body>
<script>const __WORKSPACES_JSON__ = null;</script>
</body></html>
HTML

bash "$SYNC_SCRIPT" --no-open --quiet 2>/dev/null || {
    echo "FAIL: sync-dashboard.sh exited non-zero" >&2
    exit 1
}

BRIEFING="$FIXTURE_CB/briefing.json"
if [ ! -f "$BRIEFING" ]; then
    echo "FAIL: briefing.json was not created by sync-dashboard.sh" >&2
    exit 1
fi

# ── Verify dispatch_prompts structure ─────────────────────────────────────────
# briefing["tasks"] must be an array with at least one element.
TASKS_LEN=$(jq '.tasks | length' "$BRIEFING" 2>/dev/null || echo "0")
if [ "$TASKS_LEN" -lt 1 ]; then
    echo "FAIL: briefing.json .tasks[] is empty or missing (len=$TASKS_LEN)" >&2
    echo "Briefing tasks key:" >&2
    jq '.tasks' "$BRIEFING" >&2 || true
    exit 1
fi

# Each task must have dispatch_prompts with all 3 keys.
JQ_CHECK='
  .tasks[] |
  select(
    (.dispatch_prompts | has("claude")) and
    (.dispatch_prompts | has("codex")) and
    (.dispatch_prompts | has("droid"))
  ) |
  .dispatch_prompts
'

MATCH_COUNT=$(jq -r "$JQ_CHECK" "$BRIEFING" 2>/dev/null | jq -s 'length' 2>/dev/null || echo "0")

if [ "$MATCH_COUNT" -lt 1 ]; then
    echo "FAIL: no task in briefing.json has all 3 dispatch_prompts keys (claude/codex/droid)" >&2
    echo "tasks[0].dispatch_prompts:" >&2
    jq '.tasks[0].dispatch_prompts' "$BRIEFING" >&2 || true
    exit 1
fi

# Primary assertion: jq -e form used by the acceptance criteria.
if ! jq -e '.tasks[0].dispatch_prompts | has("claude") and has("codex") and has("droid")' \
        "$BRIEFING" >/dev/null 2>&1; then
    echo "FAIL: jq assertion failed on .tasks[0].dispatch_prompts" >&2
    jq '.tasks[0]' "$BRIEFING" >&2 || true
    exit 1
fi

echo "PASS: briefing.json .tasks[0].dispatch_prompts contains claude, codex, and droid"
exit 0
