#!/usr/bin/env bash
# scripts/sigma-upgrade.sh — Upgrade Sigma Protocol installation
#
# Usage:
#   bash scripts/sigma-upgrade.sh [--dry-run] [--yes] [--from <version>] [--help]
#
# Flags:
#   --dry-run         show what would change, don't apply (skips steps 5-7-8)
#   --yes             auto-confirm (no interactive prompt)
#   --from <version>  override the marker's "from" version (useful if marker missing/corrupt)
#   --help            print this
#
# 7-step flow:
#   1. Read marker .sigma/installed-version
#   2. git fetch origin main
#   3. Show changelog diff + git log since last install (capped at 30 lines)
#   4. Confirm with user (unless --yes)
#   5. git pull --ff-only origin main
#   6. Re-run bash scripts/install-sigmahq.sh --no-open
#   7. python3 scripts/migrate-prds-to-3.0.py --dry-run and report
#   8. (implicit in re-install) marker auto-updated via U1 logic
#
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET} $*"; }
error()   { echo -e "${RED}  ✗${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ── Parse flags ────────────────────────────────────────────────
DRY_RUN=0
AUTO_YES=0
FROM_VERSION=""
HELP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --yes)     AUTO_YES=1; shift ;;
    --from)
      if [ $# -lt 2 ]; then
        error "--from requires a version argument (e.g. --from 2.5.0)"
        echo "  Usage: $0 [--dry-run] [--yes] [--from <version>] [--help]" >&2
        exit 2
      fi
      FROM_VERSION="$2"
      shift 2
      ;;
    --help|-h) HELP=1; shift ;;
    *)
      error "Unknown flag: $1"
      echo "  Usage: $0 [--dry-run] [--yes] [--from <version>] [--help]" >&2
      exit 2
      ;;
  esac
done

# ── --help early exit ──────────────────────────────────────────
if [ "$HELP" -eq 1 ]; then
  cat <<'EOF'
sigma-upgrade.sh — Upgrade Sigma Protocol installation

Usage:
  bash scripts/sigma-upgrade.sh [--dry-run] [--yes] [--from <version>] [--help]

Flags:
  --dry-run         Show what would change without applying it (skips steps 5-7-8)
  --yes             Auto-confirm the upgrade prompt (non-interactive)
  --from <version>  Override the marker's detected "from" version (useful if marker
                    is missing or corrupt — e.g. --from 2.5.0)
  --help            Print this help text and exit

7-step flow:
  1. Read .sigma/installed-version marker
  2. git fetch origin main
  3. Show CHANGELOG.md diff + git log since last install (capped at 30 lines)
  4. Prompt for confirmation (skipped with --yes)
  5. git pull --ff-only origin main
  6. Re-run bash scripts/install-sigmahq.sh --no-open
  7. python3 scripts/migrate-prds-to-3.0.py --dry-run and report

Exit codes:
  0 = success (or user declined)
  1 = failure (network, conflict, installer failed)
  2 = invalid arguments

EOF
  exit 0
fi

# ── Locate repo root ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MARKER_FILE="$REPO_ROOT/.sigma/installed-version"
INSTALLER="$REPO_ROOT/scripts/install-sigmahq.sh"
MIGRATION="$REPO_ROOT/scripts/migrate-prds-to-3.0.py"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

echo ""
echo -e "${BOLD}Sigma Protocol — Upgrade${RESET}"
echo "────────────────────────────────────────────────────────"

# ── Step 1: Read marker ────────────────────────────────────────
header "Step 1/7: Reading version marker"

PREV_VERSION=""
PREV_COMMIT=""

if [ -n "$FROM_VERSION" ]; then
  # --from flag overrides everything
  PREV_VERSION="$FROM_VERSION"
  PREV_COMMIT=""
  info "Using --from override: $PREV_VERSION"
elif [ -f "$MARKER_FILE" ] && command -v jq &>/dev/null; then
  PREV_VERSION="$(jq -r '.version // empty' "$MARKER_FILE" 2>/dev/null || echo "")"
  PREV_COMMIT="$(jq -r '.commit // empty' "$MARKER_FILE" 2>/dev/null || echo "")"
  if [ -z "$PREV_VERSION" ]; then
    PREV_VERSION="pre-3.0"
    PREV_COMMIT=""
    warn "Marker exists but version unreadable — treating as pre-3.0"
  else
    info "Current install: $PREV_VERSION (commit: ${PREV_COMMIT:-unknown})"
  fi
elif [ -f "$MARKER_FILE" ]; then
  # jq not available — try python3 fallback
  PREV_VERSION="$(python3 -c "import json,sys; d=json.load(open('$MARKER_FILE')); print(d.get('version',''))" 2>/dev/null || echo "")"
  PREV_COMMIT="$(python3 -c "import json,sys; d=json.load(open('$MARKER_FILE')); print(d.get('commit',''))" 2>/dev/null || echo "")"
  if [ -z "$PREV_VERSION" ]; then
    PREV_VERSION="pre-3.0"
    PREV_COMMIT=""
    warn "Marker exists but is unreadable — treating as pre-3.0"
  else
    info "Current install: $PREV_VERSION (commit: ${PREV_COMMIT:-unknown})"
  fi
else
  PREV_VERSION="pre-3.0"
  PREV_COMMIT=""
  warn "No .sigma/installed-version marker found — treating as pre-3.0 install"
fi

# ── Step 2: git fetch ──────────────────────────────────────────
header "Step 2/7: Fetching origin main"

FETCH_STATUS=0
git -C "$REPO_ROOT" fetch origin main 2>&1 || FETCH_STATUS=$?
if [ "$FETCH_STATUS" -ne 0 ]; then
  error "could not reach origin — check network and remote configuration"
  exit 1
fi
success "Fetch complete"

# ── Step 3: Show changelog + git log diff ──────────────────────
header "Step 3/7: Changes since $PREV_VERSION"

# Extract relevant CHANGELOG section (entries newer than PREV_VERSION)
if [ -f "$CHANGELOG" ]; then
  echo ""
  echo -e "${BOLD}CHANGELOG entries since $PREV_VERSION:${RESET}"

  if [ "$PREV_VERSION" = "pre-3.0" ] || [ -z "$PREV_VERSION" ]; then
    # Show everything — just cap at first 40 lines of the changelog body
    awk '/^## \[/ { count++; if (count > 6) exit } count > 0 { print }' "$CHANGELOG" 2>/dev/null | head -40 || true
  else
    # Extract between ## [latest] and ## [PREV_VERSION]
    # awk: print lines between the first ## [ heading and the ## [PREV_VERSION] heading
    awk -v prev="## [$PREV_VERSION]" '
      /^## \[/ && found { if (index($0, prev) > 0) exit; print; next }
      /^## \[/ && !found { if (index($0, prev) == 0) { found=1; print; next } }
      found { print }
    ' "$CHANGELOG" 2>/dev/null | head -50 || true
  fi
  echo ""
fi

# git log since prev commit
echo -e "${BOLD}Commits since last install:${RESET}"
if [ -n "$PREV_COMMIT" ]; then
  { git -C "$REPO_ROOT" log "$PREV_COMMIT..origin/main" --oneline 2>/dev/null || \
    git -C "$REPO_ROOT" log origin/main --oneline 2>/dev/null; } | head -30 || true
else
  git -C "$REPO_ROOT" log origin/main --oneline 2>/dev/null | head -30 || true
fi
echo ""

# Check if already on latest
REMOTE_SHORT="$(git -C "$REPO_ROOT" rev-parse --short origin/main 2>/dev/null || echo "unknown")"
LOCAL_SHORT="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")"

if [ "$LOCAL_SHORT" = "$REMOTE_SHORT" ] && [ -z "$FROM_VERSION" ]; then
  info "Already on latest commit ($LOCAL_SHORT). No pull needed."
  if [ "$DRY_RUN" -eq 1 ]; then
    echo ""
    echo "[DRY-RUN] Already on latest. No changes would be made."
    exit 0
  fi
fi

# ── Step 4: Confirm ────────────────────────────────────────────
header "Step 4/7: Confirm"

if [ "$DRY_RUN" -eq 1 ]; then
  echo ""
  echo -e "${YELLOW}[DRY-RUN]${RESET} Would proceed with upgrade from ${BOLD}$PREV_VERSION${RESET} (${PREV_COMMIT:-n/a}) to ${BOLD}$REMOTE_SHORT${RESET} if not in dry-run mode."
  echo ""
  echo "  Steps that would run:"
  echo "    5. git pull --ff-only origin main"
  echo "    6. bash scripts/install-sigmahq.sh --no-open"
  echo "    7. python3 scripts/migrate-prds-to-3.0.py --dry-run"
  echo ""
  echo "[DRY-RUN] No changes made."
  exit 0
fi

if [ "$AUTO_YES" -eq 0 ]; then
  printf "Proceed with upgrade from %s (%s) to %s? [y/N] " \
    "$PREV_VERSION" "${PREV_COMMIT:-n/a}" "$REMOTE_SHORT"
  CONFIRM=""
  # Read from tty when available (interactive), fall back to stdin (piped/test)
  if [ -t 0 ]; then
    read -r CONFIRM </dev/tty || CONFIRM=""
  else
    read -r CONFIRM || CONFIRM=""
  fi
  case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *)
      echo "No changes made."
      exit 0
      ;;
  esac
fi

# ── Step 5: git pull --ff-only ────────────────────────────────
header "Step 5/7: Pulling latest"

PULL_STATUS=0
git -C "$REPO_ROOT" pull --ff-only origin main || PULL_STATUS=$?
if [ "$PULL_STATUS" -ne 0 ]; then
  error "Cannot fast-forward. Stash or commit local changes first, then re-run."
  error "  git stash && bash scripts/sigma-upgrade.sh"
  exit 1
fi
success "Pull complete"

# ── Step 6: Re-run installer ───────────────────────────────────
header "Step 6/7: Re-running installer"

if [ ! -f "$INSTALLER" ]; then
  error "Installer not found: $INSTALLER"
  exit 1
fi

INSTALL_STATUS=0
bash "$INSTALLER" --no-open || INSTALL_STATUS=$?
if [ "$INSTALL_STATUS" -ne 0 ]; then
  error "Installer failed — settings may be in a partial state."
  error "Check ~/.claude/settings.json.bak-* for backup."
  exit 1
fi
success "Installer complete"

# ── Step 7: Migration dry-run ──────────────────────────────────
header "Step 7/7: Migration check"

if [ -f "$MIGRATION" ]; then
  MIGRATION_OUT=""
  MIGRATION_STATUS=0
  MIGRATION_OUT="$(python3 "$MIGRATION" --dry-run --target "$REPO_ROOT/docs/prds/" 2>&1)" || MIGRATION_STATUS=$?

  if [ "$MIGRATION_STATUS" -ne 0 ]; then
    warn "Migration dry-run exited non-zero — check output below"
    echo "$MIGRATION_OUT"
  else
    # Parse "would_upgrade: N" line
    UPGRADE_COUNT="$(echo "$MIGRATION_OUT" | grep -i 'would_upgrade:' | grep -o '[0-9]*' | tail -1 || echo "0")"
    UPGRADE_COUNT="${UPGRADE_COUNT:-0}"

    if [ "$UPGRADE_COUNT" -gt 0 ]; then
      warn "$UPGRADE_COUNT PRDs ready to upgrade. Run:"
      echo "    python3 scripts/migrate-prds-to-3.0.py --apply --target docs/prds/"
    else
      success "All PRDs current"
    fi
  fi
else
  warn "Migration script not found: $MIGRATION (skipping)"
fi

# ── Step 8: Verify marker was updated ─────────────────────────
echo ""
if [ -f "$MARKER_FILE" ] && command -v jq &>/dev/null; then
  NEW_VERSION="$(jq -r '.version // "unknown"' "$MARKER_FILE" 2>/dev/null || echo "unknown")"
  NEW_COMMIT="$(jq -r '.commit // "unknown"' "$MARKER_FILE" 2>/dev/null || echo "unknown")"
  success "Marker updated: version=$NEW_VERSION, commit=$NEW_COMMIT"
elif [ -f "$MARKER_FILE" ]; then
  success "Marker updated: $(cat "$MARKER_FILE" | head -3)"
else
  warn "Marker not found after install — check install-sigmahq.sh output above"
fi

echo ""
echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}${BOLD}Sigma Protocol upgraded successfully.${RESET}"
echo ""
echo "  Run '/sigma:upgrade --help' inside your CLI for the slash command surface."
echo ""
