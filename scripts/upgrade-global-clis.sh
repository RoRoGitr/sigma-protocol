#!/usr/bin/env bash
# upgrade-global-clis.sh — Refresh Sigma Protocol across Claude Code, Codex, Cursor, SigmaHQ
#
# Uses the local repo checkout (no git pull). Safe to re-run.
#
# Usage:
#   bash scripts/upgrade-global-clis.sh [--dry-run] [--skip-validation]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=0
SKIP_VALIDATION=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --skip-validation) SKIP_VALIDATION=1; shift ;;
    -h|--help)
      cat <<'USAGE'
Usage: bash scripts/upgrade-global-clis.sh [--dry-run] [--skip-validation]

Refreshes Sigma Protocol globally from the local repo (no git pull):
  1. Render steps/ → commands/ + step skill pointers
  2. install-sigmahq.sh (SigmaHQ, hooks, pipeline gates, version marker)
  3. install-claude-code.sh (skills, agents, category commands)
  4. install-departments.sh (department router + sigma-protocol-root marker)
  5. Flat commands/ → ~/.claude/commands/ and .cursor/commands/
  6. .agents/skills/ → ~/.codex/skills/ (methodology pool merge)
  7. Validation gates (unless --skip-validation)
USAGE
      exit 0
      ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET} $*"; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    info "[dry-run] $*"
  else
    "$@"
  fi
}

CLAUDE_HOME="${CLAUDE_CODE_CONFIG_DIR:-$HOME/.claude}"
CODEX_HOME="${CODEX_CONFIG_DIR:-$HOME/.codex}"

echo ""
echo -e "${BOLD}Sigma Protocol — Global CLI Upgrade${RESET}"
echo "Repo: $REPO_ROOT"
echo "Claude: $CLAUDE_HOME"
echo "Codex:  $CODEX_HOME"
echo "────────────────────────────────────────────────────────"

# ── 1. Canon sync in repo ───────────────────────────────────────
header "1/7  Render canonical commands + skill pointers"
run bash "$REPO_ROOT/scripts/sync-steps-to-platforms.sh" --prune
run python3 "$REPO_ROOT/scripts/sync-agents-step-pointers.py"
run node "$REPO_ROOT/scripts/generate-sigma-indexes.mjs"
success "Repo canon synced"

# ── 2. SigmaHQ + hooks + pipeline ───────────────────────────────
header "2/7  SigmaHQ + mission hooks + pipeline gates"
if [ "$DRY_RUN" -eq 1 ]; then
  info "[dry-run] bash scripts/install-sigmahq.sh --no-open --force"
else
  bash "$REPO_ROOT/scripts/install-sigmahq.sh" --no-open --force
fi
success "SigmaHQ install complete"

# ── 3. Claude Code global ───────────────────────────────────────
header "3/7  Claude Code (skills, agents, hooks)"
if [ "$DRY_RUN" -eq 1 ]; then
  info "[dry-run] bash scripts/install-claude-code.sh --force"
else
  bash "$REPO_ROOT/scripts/install-claude-code.sh" --force
fi
success "Claude Code install complete"

# ── 4. Department router ────────────────────────────────────────
header "4/7  Department router"
if [ "$DRY_RUN" -eq 1 ]; then
  info "[dry-run] SSS_PROTOCOL_ROOT=$REPO_ROOT bash scripts/install-departments.sh --non-interactive"
else
  SSS_PROTOCOL_ROOT="$REPO_ROOT" bash "$REPO_ROOT/scripts/install-departments.sh" --non-interactive
fi
success "Departments wired"

# ── 5. Flat rendered commands ─────────────────────────────────────
header "5/7  Flat commands → Claude + Cursor"
CMD_COUNT=0
if [ -d "$REPO_ROOT/commands" ]; then
  for f in "$REPO_ROOT/commands"/*.md; do
    [ -f "$f" ] || continue
    CMD_COUNT=$((CMD_COUNT + 1))
    base="$(basename "$f")"
    if [ "$DRY_RUN" -eq 1 ]; then
      info "[dry-run] cp $base → ~/.claude/commands/ and .cursor/commands/"
    else
      mkdir -p "$CLAUDE_HOME/commands" "$REPO_ROOT/.cursor/commands"
      cp -f "$f" "$CLAUDE_HOME/commands/$base"
      cp -f "$f" "$REPO_ROOT/.cursor/commands/$base"
    fi
  done
fi
success "Synced $CMD_COUNT flat command(s)"

# ── 6. Codex methodology pool ─────────────────────────────────────
header "6/7  Codex skills (methodology pool merge)"
if [ -d "$REPO_ROOT/.agents/skills" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    info "[dry-run] rsync .agents/skills/ → ~/.codex/skills/"
  else
    mkdir -p "$CODEX_HOME/skills"
    if command -v rsync &>/dev/null; then
      rsync -a "$REPO_ROOT/.agents/skills/" "$CODEX_HOME/skills/"
    else
      cp -R "$REPO_ROOT/.agents/skills/." "$CODEX_HOME/skills/"
    fi
  fi
  success "Codex skills merged from .agents/skills/"
else
  warn ".agents/skills/ not found — skipped Codex pool sync"
fi

# Also merge step pointer stubs from .codex/skills (compatibility layer)
if [ -d "$REPO_ROOT/.codex/skills" ]; then
  if [ "$DRY_RUN" -eq 0 ]; then
    for d in "$REPO_ROOT/.codex/skills"/step-*; do
      [ -d "$d" ] || continue
      name="$(basename "$d")"
      rm -rf "$CODEX_HOME/skills/$name"
      cp -R "$d" "$CODEX_HOME/skills/$name"
    done
  fi
fi

# ── 7. Validation ───────────────────────────────────────────────
header "7/7  Validation gates"
if [ "$SKIP_VALIDATION" -eq 1 ]; then
  warn "Skipped (--skip-validation)"
elif [ "$DRY_RUN" -eq 1 ]; then
  info "[dry-run] validate-step-wiring + audit-oss-drift"
else
  node "$REPO_ROOT/scripts/verify/validate-step-wiring.mjs"
  bash "$REPO_ROOT/scripts/audit-oss-drift.sh"
  success "Validation passed"
fi

# ── Summary ─────────────────────────────────────────────────────
MARKER="$REPO_ROOT/.sigma/installed-version"
echo ""
echo "────────────────────────────────────────────────────────"
if [ -f "$MARKER" ]; then
  if command -v jq &>/dev/null; then
    VER="$(jq -r '.version // "unknown"' "$MARKER" 2>/dev/null || echo unknown)"
    COMMIT="$(jq -r '.commit // "unknown"' "$MARKER" 2>/dev/null || echo unknown)"
    success "Installed: version=$VER commit=$COMMIT"
  else
    success "Marker: $MARKER"
  fi
else
  warn "No .sigma/installed-version marker — check install-sigmahq output"
fi

echo ""
echo -e "${GREEN}${BOLD}Global CLI upgrade complete.${RESET}"
echo ""
echo "  Claude commands: $CLAUDE_HOME/commands/ ($CMD_COUNT flat step/ops commands)"
echo "  Claude skills:   $CLAUDE_HOME/skills/"
echo "  Codex skills:    $CODEX_HOME/skills/"
echo "  Cursor commands: $REPO_ROOT/.cursor/commands/"
echo "  Sigma root:      $(cat "$CLAUDE_HOME/sigma-protocol-root" 2>/dev/null || echo '(not set)')"
echo ""
