#!/bin/bash
# DEPRECATED — OSS single-surface: platforms/* mirrors removed (2026).
# Canonical skill surfaces:
#   src/skills/<skill>/SKILL.md     — authored source (Step 13)
#   .agents/skills/<skill>/SKILL.md — bundled Codex methodology pool
#
# Use instead:
#   Step 13 (skillpack generator) — promotes project skills to src/skills/
#   python3 scripts/sync-agents-step-pointers.py — step skill pointers on agents
#   scripts/sync-steps-to-platforms.sh — renders steps/ → commands/ only
#
# Usage:
#   ./scripts/sync-skills-to-platforms.sh [--help]
#   ./scripts/sync-skills-to-platforms.sh --sync-pool [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_SKILLS="$PROJECT_ROOT/src/skills"
AGENTS_POOL="$PROJECT_ROOT/.agents/skills"

print_deprecation() {
  cat <<MSG
[deprecated] sync-skills-to-platforms.sh no longer writes platforms/* mirrors.

Canonical paths:
  src/skills/       — Step 13 authored skills
  .agents/skills/   — bundled methodology pool (Codex)

Next steps:
  Run Step 13 (skillpack generator) for project skill adapters.
  python3 scripts/sync-agents-step-pointers.py — refresh agent step pointers.

Optional: pass --sync-pool to copy src/skills → .agents/skills (SKILL.md folders only).
MSG
}

SYNC_POOL=false
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      print_deprecation
      echo ""
      echo "Options:"
      echo "  --sync-pool   Copy src/skills into .agents/skills (does not touch platforms/)"
      echo "  --dry-run     With --sync-pool, print actions only"
      exit 0
      ;;
    --sync-pool) SYNC_POOL=true ;;
    --dry-run) DRY_RUN=true ;;
    *)
      echo "Unknown option: $arg (use --help)" >&2
      exit 1
      ;;
  esac
done

if [[ "$SYNC_POOL" != true ]]; then
  print_deprecation
  exit 0
fi

if [[ ! -d "$SRC_SKILLS" ]]; then
  echo "Error: missing canonical source: $SRC_SKILLS" >&2
  exit 1
fi

# Reject ambiguous source identities before copying. A skill root is a directory
# containing SKILL.md; only direct root Markdown files are legacy flat skills.
duplicate_skill_names="$({
  find "$SRC_SKILLS" -type f -name "SKILL.md" -exec dirname {} \; | while IFS= read -r source_dir; do
    basename "$source_dir"
  done
  find "$SRC_SKILLS" -mindepth 1 -maxdepth 1 -type f -name "*.md" -exec basename {} .md \;
} | sort | uniq -d)"
if [[ -n "$duplicate_skill_names" ]]; then
  echo "Error: duplicate skill names in $SRC_SKILLS:" >&2
  echo "$duplicate_skill_names" >&2
  exit 1
fi

synced=0

sync_skill() {
  local source_dir="$1"
  local skill_name="$2"
  local dest_dir="$AGENTS_POOL/$skill_name"
  if [[ "$DRY_RUN" == true ]]; then
    echo "would copy: $source_dir -> $dest_dir"
  else
    mkdir -p "$dest_dir"
    cp -R "$source_dir"/. "$dest_dir"/
  fi
  ((synced++)) || true
}

# A skill root is a directory containing SKILL.md. Copy the complete root so
# linked references, templates, and other support files stay available in the
# bundled pool. Nested Markdown files are support content, not skills.
while IFS= read -r skill_file; do
  [[ -z "$skill_file" ]] && continue
  source_dir=$(dirname "$skill_file")
  sync_skill "$source_dir" "$(basename "$source_dir")"
done < <(find "$SRC_SKILLS" -type f -name "SKILL.md" | sort)

# Older authored skills may be single Markdown files directly in src/skills.
# Keep supporting that explicit legacy shape without promoting nested docs.
while IFS= read -r skill_file; do
  [[ -z "$skill_file" ]] && continue
  skill_name=$(basename "$skill_file" .md)
  if [[ "$DRY_RUN" == true ]]; then
    echo "would copy: $skill_file -> $AGENTS_POOL/$skill_name/SKILL.md"
  else
    mkdir -p "$AGENTS_POOL/$skill_name"
    cp "$skill_file" "$AGENTS_POOL/$skill_name/SKILL.md"
  fi
  ((synced++)) || true
done < <(find "$SRC_SKILLS" -mindepth 1 -maxdepth 1 -type f -name "*.md" | sort)

echo "Pool sync: $synced skill source(s) from src/skills → .agents/skills"
exit 0
