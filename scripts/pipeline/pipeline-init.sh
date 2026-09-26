#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed. Install with: brew install jq" >&2
  exit 1
fi

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERROR: Not inside a git repository" >&2
  exit 1
fi

BRANCH_RAW="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"

CHECKPOINT_FILE="${REPO_ROOT}/.pipeline-state.json"

# If checkpoint already exists, don't overwrite
if [[ -f "$CHECKPOINT_FILE" ]]; then
  exit 0
fi

# Generate a random session ID
SESSION_ID="$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 12 || true)"
TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

INITIAL_FINGERPRINT="$(
  {
    printf '%s\n' '---STAGED---'
    git diff --cached --binary --no-ext-diff 2>/dev/null || true
    printf '%s\n' '---UNSTAGED---'
    git diff --binary --no-ext-diff 2>/dev/null || true
    printf '%s\n' '---UNTRACKED---'
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      printf 'FILE:%s\n' "$file"
      shasum -a 256 "$file" 2>/dev/null || true
    done < <(git ls-files --others --exclude-standard 2>/dev/null || true)
  } | shasum -a 256 | awk '{print $1}'
)"

# Create the checkpoint file
jq -n \
  --arg session_id "$SESSION_ID" \
  --arg repo "$(basename "$REPO_ROOT")" \
  --arg branch "$BRANCH_RAW" \
  --arg created_at "$TIMESTAMP" \
  --arg worktree_fingerprint "$INITIAL_FINGERPRINT" \
  '{
    session_id: $session_id,
    repo: $repo,
    branch: $branch,
    changed_files: [],
    has_frontend_changes: false,
    change_counter: 0,
    worktree_fingerprint: $worktree_fingerprint,
    last_change_at: null,
    gates: {},
    commit_allowed: false,
    created_at: $created_at
  }' > "$CHECKPOINT_FILE"

echo "Pipeline checkpoint initialized: $CHECKPOINT_FILE"
