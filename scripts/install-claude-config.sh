#!/bin/bash
# Phoenix Pass — Install optimized Sigma Protocol agents + skills to ~/.claude/
# Usage: ./scripts/install-claude-config.sh [--dry-run] [--no-backup]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSS_ROOT="$(dirname "$SCRIPT_DIR")"
GLOBAL_DIR="$HOME/.claude"
DRY_RUN=false
NO_BACKUP=false
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m⚠\033[0m  %s\n' "$1"; }
ok()    { printf '\033[1;32m✓\033[0m  %s\n' "$1"; }
fail()  { printf '\033[1;31m✗\033[0m  %s\n' "$1" >&2; exit 1; }

# Parse args
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --no-backup) NO_BACKUP=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--no-backup]"
      echo "  --dry-run    Show what would be done without making changes"
      echo "  --no-backup  Skip creating backups of existing files"
      exit 0
      ;;
    *) warn "Unknown arg: $arg" ;;
  esac
done

info "Sigma Protocol Phoenix Installer"
echo "  Source: $SSS_ROOT"
echo "  Target: $GLOBAL_DIR"
echo "  Dry run: $DRY_RUN"
echo ""

# ── Step 1: Backup ──────────────────────────────────────────────────
if [ "$NO_BACKUP" = false ] && [ "$DRY_RUN" = false ]; then
  BACKUP_DIR="$GLOBAL_DIR/.backup-$TIMESTAMP"
  info "Backing up to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"

  if [ -d "$GLOBAL_DIR/agents" ]; then
    cp -r "$GLOBAL_DIR/agents" "$BACKUP_DIR/agents" 2>/dev/null || true
    ok "Backed up agents/"
  fi

  if [ -d "$GLOBAL_DIR/skills" ]; then
    cp -r "$GLOBAL_DIR/skills" "$BACKUP_DIR/skills" 2>/dev/null || true
    ok "Backed up skills/"
  fi
fi

# ── Step 2: Flatten agents (dept/name.md → name.md) ────────────────
info "Installing agents (flattened from departments)"
SRC_AGENTS="$SSS_ROOT/.claude/agents"
DST_AGENTS="$GLOBAL_DIR/agents"
AGENT_COUNT=0

if [ -d "$SRC_AGENTS" ]; then
  if [ "$DRY_RUN" = false ]; then
    # Clean existing agent .md files (preserve .archive, .backup dirs)
    find "$DST_AGENTS" -maxdepth 1 -name "*.md" -type f -delete 2>/dev/null || true
  fi

  # Find all .md files in department subdirs and flatten
  while IFS= read -r agent_file; do
    filename=$(basename "$agent_file")
    # Skip reference files and non-agent files
    if [[ "$filename" == *"-reference"* ]] || [[ "$filename" == "README.md" ]]; then
      continue
    fi

    if [ "$DRY_RUN" = true ]; then
      echo "  WOULD COPY: $agent_file → $DST_AGENTS/$filename"
    else
      cp "$agent_file" "$DST_AGENTS/$filename"
    fi
    AGENT_COUNT=$((AGENT_COUNT + 1))
  done < <(find "$SRC_AGENTS" -name "*.md" -type f -not -path "*/.archive/*" -not -path "*/.backup*/*")

  ok "Installed $AGENT_COUNT agents"
else
  warn "No agents directory found at $SRC_AGENTS"
fi

# ── Step 3: Copy skills (preserve department structure) ─────────────
info "Installing skills (preserving department structure)"
SRC_SKILLS="$SSS_ROOT/.claude/skills"
DST_SKILLS="$GLOBAL_DIR/skills"
SKILL_COUNT=0

if [ -d "$SRC_SKILLS" ]; then
  # Find all SKILL.md files at any depth, flatten to skill-name/SKILL.md
  while IFS= read -r skill_file; do
    skill_dir=$(dirname "$skill_file")
    skill_name=$(basename "$skill_dir")

    # Skip hidden dirs
    [[ "$skill_name" == .* ]] && continue

    dst_skill_dir="$DST_SKILLS/$skill_name"

    if [ "$DRY_RUN" = true ]; then
      echo "  WOULD COPY: $skill_file → $dst_skill_dir/SKILL.md"
    else
      mkdir -p "$dst_skill_dir"
      cp "$skill_file" "$dst_skill_dir/SKILL.md"
    fi
    SKILL_COUNT=$((SKILL_COUNT + 1))
  done < <(find "$SRC_SKILLS" -name "SKILL.md" -type f -not -path "*/.archive/*" -not -path "*/.backup*/*")

  ok "Installed $SKILL_COUNT skills"
else
  warn "No skills directory found at $SRC_SKILLS"
fi

# ── Step 4: Verification ───────────────────────────────────────────
if [ "$DRY_RUN" = false ]; then
  info "Verifying installation"

  actual_agents=$(find "$DST_AGENTS" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  actual_skills=$(find "$DST_SKILLS" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [ "$actual_agents" -ge "$AGENT_COUNT" ]; then
    ok "Agents: $actual_agents installed"
  else
    warn "Agents: expected $AGENT_COUNT, found $actual_agents"
  fi

  if [ "$actual_skills" -ge "$SKILL_COUNT" ]; then
    ok "Skills: $actual_skills installed"
  else
    warn "Skills: expected $SKILL_COUNT, found $actual_skills"
  fi
fi

echo ""
info "Installation complete"
echo "  Agents: $AGENT_COUNT (flattened to $DST_AGENTS/)"
echo "  Skills: $SKILL_COUNT (at $DST_SKILLS/)"
if [ "$NO_BACKUP" = false ] && [ "$DRY_RUN" = false ]; then
  echo "  Backup: $BACKUP_DIR"
fi
