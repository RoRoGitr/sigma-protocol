#!/bin/bash
# DEPRECATED — cross-platform platforms/* skill mirrors removed (OSS single-surface).
#
# Canonical skill locations:
#   src/skills/<skill>/SKILL.md     — authored source (Step 13)
#   .agents/skills/<skill>/SKILL.md — bundled methodology pool
#
# Use instead:
#   Step 13 (skillpack generator)
#   python3 scripts/sync-agents-step-pointers.py
#   ./scripts/sync-skills-to-platforms.sh --sync-pool  (optional pool refresh)
#
# Usage: ./scripts/sync-skills.sh [--help]

set -euo pipefail

for arg in "$@"; do
  case "$arg" in
    --help|-h) ;;
    *)
      echo "Unknown or legacy option: $arg" >&2
      echo "This script is deprecated. Use --help for replacements." >&2
      exit 1
      ;;
  esac
done

cat <<'MSG'
[deprecated] sync-skills.sh no longer syncs platforms/claude-code, platforms/codex, or platforms/factory-droid.

Canonical paths:
  src/skills/       — project-authored skills (Step 13)
  .agents/skills/   — bundled methodology pool

Replacements:
  Step 13 — generate/promote skills under src/skills/
  python3 scripts/sync-agents-step-pointers.py — agent step skill pointers
  ./scripts/sync-skills-to-platforms.sh --sync-pool — optional src → .agents pool copy

Legacy flags (--fix, --inventory, --verbose) are not supported.
MSG

exit 0
