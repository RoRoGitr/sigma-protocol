#!/usr/bin/env bash
# =============================================================================
# Config Change Handler — ConfigChange
# =============================================================================
# Event:    ConfigChange
# Trigger:  Fires when Claude Code detects a change to configuration files
#           including .claude/rules/*.md, .claude/settings.json, CLAUDE.md,
#           or MCP configuration (.mcp.json).
#
# When it fires:
#   After a write to any file Claude Code treats as configuration. This
#   includes manual edits, agent-generated edits, and git operations that
#   modify these files (checkout, merge, rebase, cherry-pick).
#
# Available environment variables:
#   CLAUDE_PROJECT_DIR          — root of the project
#   CLAUDE_SESSION_ID           — current session identifier
#   CLAUDE_HOOK_EVENT_NAME      — "ConfigChange"
#   CLAUDE_CONFIG_PATH          — absolute path of the changed config file
#   CLAUDE_CONFIG_CHANGE_KIND   — "created" | "updated" | "deleted"
#   CLAUDE_AGENT_ID             — agent that triggered the change (if any)
#   CLAUDE_AGENT_TYPE           — "lead" | "teammate" | "subagent"
#
# Exit codes:
#   0  — success (accept the change)
#   1  — block the change (Claude will revert and report the error)
#   2+ — ignored (hook treated as not present; change proceeds)
#
# Use cases:
#   - Auto-reload rules without requiring a session restart
#   - Validate settings.json schema before accepting changes
#   - Log an audit trail of who changed what config and when
#   - Detect conflicting rule definitions across multiple .md files
#   - Sync config changes to other platforms (Cursor, Codex, etc.)
#   - Prevent accidental deletion of critical configuration files
#
# To activate, add to settings.json under "hooks":
#   "ConfigChange": [{
#     "hooks": [{
#       "type": "command",
#       "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/config-change-handler.sh\""
#     }]
#   }]
# =============================================================================

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CONFIG_PATH="${CLAUDE_CONFIG_PATH:-unknown}"
CHANGE_KIND="${CLAUDE_CONFIG_CHANGE_KIND:-updated}"
AGENT_ID="${CLAUDE_AGENT_ID:-unknown}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Orchestration log
ORCH_DIR="$PROJECT_DIR/.sigma/orchestration"
LOG_FILE="$ORCH_DIR/config-changes.log"

# ─────────────────────────────────────────────────────────────────────────────
# Log the change (always, for audit trail)
# ─────────────────────────────────────────────────────────────────────────────
if [[ -d "$ORCH_DIR" ]]; then
    printf '[%s] [config-change] file=%s kind=%s agent=%s session=%s\n' \
        "$TIMESTAMP" \
        "$CONFIG_PATH" \
        "$CHANGE_KIND" \
        "$AGENT_ID" \
        "$SESSION_ID" >> "$LOG_FILE"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Derive the relative path and file type
# ─────────────────────────────────────────────────────────────────────────────
REL_PATH="${CONFIG_PATH#"$PROJECT_DIR"/}"
BASENAME=$(basename "$CONFIG_PATH")

# ─────────────────────────────────────────────────────────────────────────────
# Guard: Block deletion of critical config files
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$CHANGE_KIND" == "deleted" ]]; then
    case "$REL_PATH" in
        CLAUDE.md|.claude/settings.json|.mcp.json)
            echo "ERROR: Deletion of $REL_PATH is blocked. This is a critical config file." >&2
            echo "If intentional, manually delete it outside of Claude Code." >&2
            exit 1  # exit 1 blocks the deletion
            ;;
    esac
fi

# ─────────────────────────────────────────────────────────────────────────────
# Validate settings.json on update
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$BASENAME" == "settings.json" && "$CHANGE_KIND" != "deleted" ]]; then
    # TODO: Validate JSON syntax
    # Example:
    #   if ! jq empty "$CONFIG_PATH" 2>/dev/null; then
    #       echo "ERROR: $REL_PATH contains invalid JSON" >&2
    #       exit 1
    #   fi

    # TODO: Validate required fields exist
    # Example:
    #   if ! jq -e '.hooks' "$CONFIG_PATH" >/dev/null 2>&1; then
    #       echo "WARNING: settings.json is missing 'hooks' section" >&2
    #   fi

    true  # placeholder — remove when uncommenting above
fi

# ─────────────────────────────────────────────────────────────────────────────
# Handle rule file changes (.claude/rules/*.md)
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$REL_PATH" == .claude/rules/*.md ]]; then
    # TODO: Detect conflicting rules across files
    # Example:
    #   RULE_DIR="$PROJECT_DIR/.claude/rules"
    #   CONFLICT=$(grep -rl "NEVER.*skip" "$RULE_DIR" 2>/dev/null | wc -l)
    #   if [[ "$CONFLICT" -gt 1 ]]; then
    #       echo "WARNING: Multiple rule files define skip policies. Review for conflicts."
    #   fi

    # TODO: Auto-sync to other platforms
    # Example:
    #   if [[ -d "$PROJECT_DIR/.cursor/rules" ]]; then
    #       echo "TIP: Rule changed in .claude/rules/. Run /platform-sync to update Cursor rules."
    #   fi

    true  # placeholder — remove when uncommenting above
fi

# ─────────────────────────────────────────────────────────────────────────────
# Handle CLAUDE.md changes
# ─────────────────────────────────────────────────────────────────────────────
if [[ "$BASENAME" == "CLAUDE.md" ]]; then
    # TODO: Validate CLAUDE.md structure
    # Example:
    #   if ! grep -q "^## " "$CONFIG_PATH" 2>/dev/null; then
    #       echo "WARNING: CLAUDE.md appears to be missing section headers"
    #   fi

    # TODO: Check for size limits (very large CLAUDE.md wastes context)
    # Example:
    #   LINES=$(wc -l < "$CONFIG_PATH" 2>/dev/null || echo 0)
    #   if [[ "$LINES" -gt 500 ]]; then
    #       echo "WARNING: CLAUDE.md is $LINES lines. Consider splitting into .claude/rules/ files."
    #   fi

    true  # placeholder — remove when uncommenting above
fi

# ─────────────────────────────────────────────────────────────────────────────
# Notify model about the config change (additionalContext)
# ─────────────────────────────────────────────────────────────────────────────

# TODO: Uncomment to inject context back into the conversation
# Example:
#   cat <<EOF
# {
#   "additionalContext": "Config file changed: $REL_PATH ($CHANGE_KIND). Rules may have been updated."
# }
# EOF

exit 0
