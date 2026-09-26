#!/usr/bin/env bash
set -euo pipefail

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "COMMIT BLOCKED: gitleaks is not installed." >&2
  echo "Install it with: brew install gitleaks" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

gitleaks protect --staged --no-banner
