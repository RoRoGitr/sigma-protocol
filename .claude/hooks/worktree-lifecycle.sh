#!/usr/bin/env bash
# =============================================================================
# Worktree Lifecycle Hook — WorktreeCreate / WorktreeRemove
# =============================================================================
# Events:   WorktreeCreate, WorktreeRemove
# Trigger:  Fires when Claude Code creates or removes a git worktree
#           (e.g., for parallel agent branches during swarm execution).
#
# When they fire:
#   WorktreeCreate — immediately after `git worktree add` succeeds.
#   WorktreeRemove — immediately after `git worktree remove` succeeds.
#
# Available environment variables:
#   CLAUDE_PROJECT_DIR       — root of the project that owns the worktree
#   CLAUDE_SESSION_ID        — current session identifier
#   CLAUDE_WORKTREE_PATH     — absolute path of the new/removed worktree
#   CLAUDE_WORKTREE_BRANCH   — branch checked out in the worktree
#   CLAUDE_HOOK_EVENT_NAME   — "WorktreeCreate" or "WorktreeRemove"
#   CLAUDE_AGENT_ID          — agent that triggered the worktree operation
#   CLAUDE_AGENT_TYPE        — "lead" | "teammate" | "subagent"
#
# Exit codes:
#   0  — success (allow the operation to proceed)
#   1  — block the operation (Claude will abort and report the error)
#   2+ — ignored (hook treated as not present; operation proceeds)
#
# Use cases:
#   - Auto-install dependencies in new worktrees (npm ci, pip install, etc.)
#   - Copy shared config files (.env.local, .tool-versions) into worktrees
#   - Register worktree with orchestration tracking (kanban, dashboards)
#   - Clean up temp files, caches, or logs when a worktree is removed
#   - Notify other agents that a new branch workspace is available
#   - Enforce naming conventions on worktree branches
#
# To activate, add to settings.json under "hooks":
#   "WorktreeCreate": [{
#     "hooks": [{
#       "type": "command",
#       "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/worktree-lifecycle.sh\""
#     }]
#   }],
#   "WorktreeRemove": [{
#     "hooks": [{
#       "type": "command",
#       "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/worktree-lifecycle.sh\""
#     }]
#   }]
# =============================================================================

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
EVENT="${CLAUDE_HOOK_EVENT_NAME:-unknown}"
WORKTREE_PATH="${CLAUDE_WORKTREE_PATH:-unknown}"
WORKTREE_BRANCH="${CLAUDE_WORKTREE_BRANCH:-unknown}"
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Orchestration log (optional — create .sigma/orchestration/ if using Sigma Protocol)
ORCH_DIR="$PROJECT_DIR/.sigma/orchestration"
LOG_FILE="$ORCH_DIR/worktree-events.log"

# Ensure log directory exists
if [[ -d "$ORCH_DIR" ]]; then
    printf '[%s] [%s] path=%s branch=%s agent=%s session=%s\n' \
        "$TIMESTAMP" \
        "$EVENT" \
        "$WORKTREE_PATH" \
        "$WORKTREE_BRANCH" \
        "$AGENT_ID" \
        "$SESSION_ID" >> "$LOG_FILE"
fi

# ─────────────────────────────────────────────────────────────────────────────
# WorktreeCreate — runs after a new worktree is added
# ─────────────────────────────────────────────────────────────────────────────
handle_create() {
    # TODO: Auto-install dependencies in the new worktree
    # Example:
    #   if [[ -f "$WORKTREE_PATH/package.json" ]]; then
    #       (cd "$WORKTREE_PATH" && npm ci --ignore-scripts 2>/dev/null) || true
    #   fi

    # TODO: Copy shared local config into the worktree
    # Example:
    #   for config in .env.local .tool-versions; do
    #       if [[ -f "$PROJECT_DIR/$config" && ! -f "$WORKTREE_PATH/$config" ]]; then
    #           cp "$PROJECT_DIR/$config" "$WORKTREE_PATH/$config"
    #       fi
    #   done

    # TODO: Enforce branch naming conventions
    # Example:
    #   if [[ ! "$WORKTREE_BRANCH" =~ ^(feat|fix|chore|refactor)/ ]]; then
    #       echo "ERROR: Branch '$WORKTREE_BRANCH' does not follow naming convention" >&2
    #       exit 1  # exit 1 blocks the worktree creation
    #   fi

    # TODO: Notify orchestration system
    # Example:
    #   echo "{\"event\":\"worktree_created\",\"branch\":\"$WORKTREE_BRANCH\"}" \
    #       >> "$ORCH_DIR/inbox/orchestrator.json"

    exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# WorktreeRemove — runs after a worktree is removed
# ─────────────────────────────────────────────────────────────────────────────
handle_remove() {
    # TODO: Clean up worktree-specific artifacts
    # Example:
    #   rm -rf "/tmp/sigma-worktree-$(basename "$WORKTREE_PATH")" 2>/dev/null || true

    # TODO: Update orchestration tracking
    # Example:
    #   echo "{\"event\":\"worktree_removed\",\"branch\":\"$WORKTREE_BRANCH\"}" \
    #       >> "$ORCH_DIR/inbox/orchestrator.json"

    # TODO: Archive worktree logs before cleanup
    # Example:
    #   ARCHIVE_DIR="$ORCH_DIR/archive/worktrees"
    #   mkdir -p "$ARCHIVE_DIR"
    #   if [[ -f "$WORKTREE_PATH/.sigma/local.log" ]]; then
    #       mv "$WORKTREE_PATH/.sigma/local.log" \
    #           "$ARCHIVE_DIR/$(basename "$WORKTREE_BRANCH")-$(date +%s).log"
    #   fi

    exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Route by event
# ─────────────────────────────────────────────────────────────────────────────
case "$EVENT" in
    WorktreeCreate)
        handle_create
        ;;
    WorktreeRemove)
        handle_remove
        ;;
    *)
        # Unknown event — pass through silently
        exit 0
        ;;
esac
