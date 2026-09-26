#!/bin/bash
# DEPRECATED — platforms/claude-code/skills → .claude/skills flat sync removed.
#
# Canonical skill surfaces (OSS):
#   src/skills/<skill>/SKILL.md     — authored source (Step 13)
#   .agents/skills/<skill>/SKILL.md — bundled methodology pool (Codex)
#
# Claude Code project skills (when used): ~/.claude/skills/ or repo .claude/skills/
# via Step 12/13 outputs — not from platforms/claude-code.
#
# Usage: ./scripts/sync-skills-to-master.sh [--help]

set -euo pipefail

for arg in "$@"; do
  case "$arg" in
    --help|-h) ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

cat <<'MSG'
[deprecated] sync-skills-to-master.sh no longer copies from platforms/claude-code/skills/.

.agents/skills/ is the canonical bundled methodology pool in this repository.
Project skills are authored under src/skills/ (Step 13 skillpack generator).

Use:
  Step 13 — promote skills to src/skills/
  python3 scripts/sync-agents-step-pointers.py — agent step pointers
  ./scripts/sync-skills-to-platforms.sh --sync-pool — optional src/skills → .agents/skills
MSG

exit 0
