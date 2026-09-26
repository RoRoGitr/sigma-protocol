#!/usr/bin/env bash
set -euo pipefail

# Claude PreToolUse preflight:
# blocks "gh pr create" when changed files exceed Greptile-safe budget.

TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

if ! echo "$TOOL_INPUT" | grep -q "gh pr create"; then
  exit 0
fi

CHECK_SCRIPT="$PROJECT_DIR/scripts/check-pr-file-budget.sh"
if [[ ! -x "$CHECK_SCRIPT" ]]; then
  exit 0
fi

BASE_REF="${PR_FILE_BUDGET_BASE:-origin/main}"

# Honor explicit base from gh command.
# Supports: --base <branch> and -B <branch>.
if base_flag="$(echo "$TOOL_INPUT" | sed -nE 's/.*(--base|-B)[[:space:]]+([^[:space:]]+).*/\2/p' | head -1)"; then
  if [[ -n "$base_flag" ]]; then
    if [[ "$base_flag" == */* ]]; then
      BASE_REF="$base_flag"
    else
      BASE_REF="origin/$base_flag"
    fi
  fi
fi

if ! MAX_CHANGED_FILES="${MAX_CHANGED_FILES:-9999}" "$CHECK_SCRIPT" "$BASE_REF" HEAD >/dev/null 2>&1; then
  echo "[PR_FILE_BUDGET_BLOCK] Refusing gh pr create because this branch exceeds the PR file budget."
  echo "Run: scripts/check-pr-file-budget.sh ${BASE_REF} HEAD"
  echo "Split into stacked PRs (<= ${MAX_CHANGED_FILES:-9999} files each), then retry gh pr create."
  exit 2
fi

exit 0
