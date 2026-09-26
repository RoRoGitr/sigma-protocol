#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_PATH=".githooks"

if [[ ! -d "$REPO_ROOT/$HOOKS_PATH" ]]; then
  echo "Missing $HOOKS_PATH directory at $REPO_ROOT" >&2
  exit 1
fi

chmod +x "$REPO_ROOT/$HOOKS_PATH/pre-push"
git config core.hooksPath "$HOOKS_PATH"

echo "Configured git hooks path: $(git config --get core.hooksPath)"
echo "Pre-push PR file budget hook is active."
