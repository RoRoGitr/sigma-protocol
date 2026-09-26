#!/usr/bin/env bash
# mission-session-start.sh — Inject active mission context on session start.
#
# Performance budget: MUST complete in <2 seconds. No filesystem crawls,
# no kanban scans, no reconciliation. Cached-read only.
#
# Emits ONE of:
#   - Silent status banner (desktop + fresh, OR SSH, OR print mode)
#   - Flagged banner with [ACTION REQUIRED] (desktop + stale >24h)
#   - Nothing (no active mission for this workspace)
#
# Triggered by SessionStart hook in settings.json.
#
# Workspace resolution (in priority order):
#   1. CLAUDE_CODE_WORKSPACE_SLUG env var — explicit override, fastest
#   2. .commandboard-workspace sentinel file — walk CWD up to find it
#   3. Workspace directory name scan — match CWD component against
#      $SIGMAHQ_HOME/workspaces/{category}/{name}/
#
# To set a permanent slug for a project, either:
#   a) export CLAUDE_CODE_WORKSPACE_SLUG=products-my-product  (in shell rc or .envrc)
#   b) echo "products-my-product" > .commandboard-workspace   (in project root)

set -euo pipefail

COMMANDBOARD="${SIGMAHQ_HOME:-${CLAUDE_CODE_COMMANDBOARD:-$HOME/.commandboard}}"
export SIGMAHQ_HOME="$COMMANDBOARD"
export CLAUDE_CODE_COMMANDBOARD="${CLAUDE_CODE_COMMANDBOARD:-$COMMANDBOARD}"
MISSIONS_ROOT="$COMMANDBOARD/missions"
ACTIVE_DIR="$MISSIONS_ROOT/active"
SSH_STATE_FILE="$HOME/.claude/.ssh-mode"
SSH_PENDING_FILE="$HOME/.claude/.ssh-pending.md"

# ---------------------------------------------------------------------------
# Workspace detection — generic, no hardcoded project names
# ---------------------------------------------------------------------------
detect_workspace_slug() {
    local cwd="$1"

    # 1. Explicit env override — user sets CLAUDE_CODE_WORKSPACE_SLUG in shell rc or .envrc
    if [[ -n "${CLAUDE_CODE_WORKSPACE_SLUG:-}" ]]; then
        echo "$CLAUDE_CODE_WORKSPACE_SLUG"
        return
    fi

    # 2. Sentinel file — walk CWD upward looking for .commandboard-workspace
    local path="$cwd"
    while [[ "$path" != "/" && "$path" != "$HOME" ]]; do
        if [[ -f "$path/.commandboard-workspace" ]]; then
            local slug
            slug="$(tr -d '[:space:]' < "$path/.commandboard-workspace" 2>/dev/null)"
            if [[ -n "$slug" ]]; then
                echo "$slug"
                return
            fi
        fi
        path="$(dirname "$path")"
    done

    # 3. Workspace directory scan — match any CWD path component against
    #    $COMMANDBOARD/workspaces/{category}/{name}
    local workspaces_dir="$COMMANDBOARD/workspaces"
    if [[ -d "$workspaces_dir" ]]; then
        for category_dir in "$workspaces_dir"/*/; do
            [[ -d "$category_dir" ]] || continue
            local category
            category="$(basename "$category_dir")"
            for ws_dir in "$category_dir"*/; do
                [[ -d "$ws_dir" ]] || continue
                local ws_name
                ws_name="$(basename "$ws_dir")"
                # Match if any CWD path segment equals the workspace name
                if [[ "$cwd" == *"/$ws_name" || "$cwd" == *"/$ws_name/"* ]]; then
                    echo "${category}-${ws_name}"
                    return
                fi
            done
        done
    fi

    echo ""
}

CWD="$(pwd)"
WORKSPACE_SLUG="$(detect_workspace_slug "$CWD")"

# No workspace match → exit silently
[[ -z "$WORKSPACE_SLUG" ]] && exit 0

# No active symlink → no mission → exit silently
ACTIVE_LINK="$ACTIVE_DIR/$WORKSPACE_SLUG"
[[ ! -L "$ACTIVE_LINK" ]] && exit 0

MISSION_DIR="$(readlink "$ACTIVE_LINK" 2>/dev/null || echo "")"

# Handle relative symlinks
if [[ -n "$MISSION_DIR" && "$MISSION_DIR" != /* ]]; then
    MISSION_DIR="$ACTIVE_DIR/$MISSION_DIR"
fi

MISSION_JSON="$MISSION_DIR/mission.json"
[[ ! -f "$MISSION_JSON" ]] && exit 0

# Single Python read — fast path, no external tools beyond what's already loaded
python3 <<PYEOF
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

mission_path = Path("$MISSION_JSON")
try:
    data = json.loads(mission_path.read_text())
except Exception as e:
    # Malformed mission.json — exit silently so we don't break session start
    sys.exit(0)

mid = data.get("id", "unknown")
title = data.get("title", "(no title)")
status = data.get("status", "unknown")

# Skip injection for non-active statuses
if status not in ("active", "paused"):
    sys.exit(0)

deadline = data.get("deadline")
machine_checks = data.get("machine_checks", [])
soft_criteria = data.get("soft_criteria", [])

# Progress: pass or latched_pass counts as done
m_done = sum(
    1 for c in machine_checks
    if c.get("last_result") == "pass" or c.get("latched_pass", False)
)
m_total = len(machine_checks)
s_done = sum(1 for c in soft_criteria if c.get("last_answer") == "yes")
s_total = len(soft_criteria)

# Stale-check timestamp (latest of any last_check across all criteria)
last_checks = []
for c in machine_checks + soft_criteria:
    lc = c.get("last_check")
    if lc:
        try:
            last_checks.append(datetime.fromisoformat(lc.replace("Z", "+00:00")))
        except ValueError:
            pass

now = datetime.now(timezone.utc)
last_check_ts = max(last_checks) if last_checks else None
stale = True if last_check_ts is None else (now - last_check_ts).total_seconds() > 86400

# Mode detection
import os
is_ssh = os.environ.get("CLAUDE_CODE_SSH_MODE", "")
if not is_ssh and Path(os.path.expanduser("$SSH_STATE_FILE")).exists():
    try:
        if "ACTIVE" in Path(os.path.expanduser("$SSH_STATE_FILE")).read_text():
            is_ssh = True
    except Exception:
        pass

is_print = os.environ.get("CLAUDE_CODE_PRINT_MODE", "") or "--print" in os.environ.get("_", "")

# Budget remaining
budget = data.get("budget", {})

# Build banner
lines = []
lines.append(f"--- MISSION: {mid} ---")
lines.append(f"  Title: {title}")
lines.append(f"  Status: {status}")
lines.append(f"  Machine checks: {m_done}/{m_total} | Soft criteria: {s_done}/{s_total}")
if deadline:
    try:
        d = datetime.fromisoformat(deadline).date()
        today = now.date()
        days_to = (d - today).days
        if days_to < 0:
            lines.append(f"  Deadline: {deadline} ({-days_to}d PAST)")
        else:
            lines.append(f"  Deadline: {deadline} ({days_to}d remaining)")
    except ValueError:
        pass
if budget.get("usd"):
    lines.append(f"  Budget: \${budget.get('usd')} USD cap")
if last_check_ts:
    hours_ago = int((now - last_check_ts).total_seconds() / 3600)
    lines.append(f"  Last criterion check: {hours_ago}h ago")
else:
    lines.append(f"  Last criterion check: never")
lines.append(f"  Ledger: {data.get('ledger_path', 'ledger.jsonl')}")
lines.append(f"  Workspace: {data.get('workspace', 'unknown')}")

# Stale flag
if stale and not is_ssh and not is_print and status == "active":
    lines.append(f"  [ACTION REQUIRED] >24h since last criterion check — ask user whether to /mission reconcile or continue")

# SSH mode → write to .ssh-pending.md for review on /ssh off
if is_ssh:
    ssh_pending = Path(os.path.expanduser("$SSH_PENDING_FILE"))
    try:
        with ssh_pending.open("a") as f:
            f.write(f"\n- [mission-check {datetime.now(timezone.utc).isoformat()}] {mid}: {m_done}/{m_total} machine, {s_done}/{s_total} soft\n")
    except Exception:
        pass
    lines.append(f"  [SSH-MODE] Deferred check-in logged to .ssh-pending.md")

print("\n".join(lines))
PYEOF

exit 0
