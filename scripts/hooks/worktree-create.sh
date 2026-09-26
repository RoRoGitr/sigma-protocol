#!/usr/bin/env bash
# Optional Claude hook template: WorktreeCreate
# Logs worktree lifecycle events for Sigma orchestration observability.

set -euo pipefail

PROJECT_ROOT="${SIGMA_PROJECT_ROOT:-$(pwd)}"
ORCH_DIR="$PROJECT_ROOT/.sigma/orchestration"
LOG_FILE="$ORCH_DIR/hooks.log"
WORKTREE_PATH="${WORKTREE_PATH:-${CLAUDE_WORKTREE_PATH:-unknown}}"
WORKTREE_BRANCH="${WORKTREE_BRANCH:-${CLAUDE_WORKTREE_BRANCH:-unknown}}"

mkdir -p "$ORCH_DIR"
printf '[%s] [worktree-create] path=%s branch=%s\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  "$WORKTREE_PATH" \
  "$WORKTREE_BRANCH" >> "$LOG_FILE"

exit 0
