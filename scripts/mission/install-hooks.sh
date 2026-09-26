#!/usr/bin/env bash
# install-hooks.sh — Idempotent installer for mission system scripts.
#
# Copies mission-stack.py + mission-autoresearch.py to ~/.claude/scripts/
# Copies mission-session-start.sh to ~/.claude/hooks/
# Appends SessionStart hook entry to ~/.claude/settings.json if not present
#
# Called by scripts/install-sigmahq.sh. Safe to run standalone.
#
# Usage:
#   bash scripts/mission/install-hooks.sh          # install
#   bash scripts/mission/install-hooks.sh --force  # overwrite existing files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --help|-h)
            echo "Usage: $0 [--force]"
            echo "  --force  Overwrite existing files (default: skip if present)"
            exit 0
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Destination paths
# ---------------------------------------------------------------------------
CLAUDE_DIR="${CLAUDE_CODE_CONFIG_DIR:-$HOME/.claude}"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_JSON="$CLAUDE_DIR/settings.json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo "[install-hooks] $*"; }
warn()  { echo "[install-hooks] WARN: $*" >&2; }
error() { echo "[install-hooks] ERROR: $*" >&2; exit 1; }

copy_file() {
    local src="$1"
    local dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    mkdir -p "$dst_dir"

    if [[ -f "$dst" && "$FORCE" -eq 0 ]]; then
        info "Skipping (already exists): $dst — use --force to overwrite"
        return
    fi

    cp "$src" "$dst"
    info "Installed: $dst"
}

# ---------------------------------------------------------------------------
# Check dependencies
# ---------------------------------------------------------------------------
if ! command -v python3 &>/dev/null; then
    error "python3 not found. Install Python 3.9+ and re-run."
fi

PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PYTHON_MAJOR="${PYTHON_VERSION%%.*}"
PYTHON_MINOR="${PYTHON_VERSION#*.}"
if [[ "$PYTHON_MAJOR" -lt 3 || ( "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 9 ) ]]; then
    error "Python 3.9+ required (found $PYTHON_VERSION). Upgrade Python and re-run."
fi

if ! command -v jq &>/dev/null; then
    warn "jq not found — cannot update settings.json automatically."
    warn "Install jq (brew install jq / apt install jq) and re-run, or add the hook manually."
    JQ_AVAILABLE=0
else
    JQ_AVAILABLE=1
fi

# ---------------------------------------------------------------------------
# Copy Python scripts
# ---------------------------------------------------------------------------
info "Installing mission scripts to $SCRIPTS_DIR/"
copy_file "$SCRIPT_DIR/mission-stack.py"        "$SCRIPTS_DIR/mission-stack.py"
copy_file "$SCRIPT_DIR/mission-autoresearch.py" "$SCRIPTS_DIR/mission-autoresearch.py"

# Make scripts executable
chmod +x "$SCRIPTS_DIR/mission-stack.py" 2>/dev/null || true
chmod +x "$SCRIPTS_DIR/mission-autoresearch.py" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Copy hook
# ---------------------------------------------------------------------------
info "Installing hook to $HOOKS_DIR/"
copy_file "$SCRIPT_DIR/mission-session-start.sh" "$HOOKS_DIR/mission-session-start.sh"
chmod +x "$HOOKS_DIR/mission-session-start.sh"

# ---------------------------------------------------------------------------
# Wire SessionStart hook in settings.json
# ---------------------------------------------------------------------------
HOOK_COMMAND="bash $HOOKS_DIR/mission-session-start.sh"

if [[ "$JQ_AVAILABLE" -eq 0 ]]; then
    warn "Skipping settings.json update (jq unavailable)."
    warn "Add this manually to ~/.claude/settings.json under hooks.SessionStart:"
    warn "  { \"type\": \"command\", \"command\": \"$HOOK_COMMAND\" }"
else
    # Create settings.json if it doesn't exist
    if [[ ! -f "$SETTINGS_JSON" ]]; then
        info "Creating $SETTINGS_JSON"
        echo '{}' > "$SETTINGS_JSON"
    fi

    # Check if the hook is already present (match by command string)
    ALREADY_WIRED="$(jq --arg cmd "$HOOK_COMMAND" \
        '.hooks.SessionStart // [] | map(select(.command == $cmd)) | length' \
        "$SETTINGS_JSON" 2>/dev/null || echo "0")"

    if [[ "$ALREADY_WIRED" -gt 0 ]]; then
        info "SessionStart hook already present in settings.json — skipping"
    else
        # Append the new hook entry to hooks.SessionStart array
        UPDATED="$(jq --arg cmd "$HOOK_COMMAND" '
            .hooks.SessionStart = ((.hooks.SessionStart // []) + [{"type": "command", "command": $cmd}])
        ' "$SETTINGS_JSON")"
        echo "$UPDATED" > "$SETTINGS_JSON"
        info "Added SessionStart hook to $SETTINGS_JSON"
    fi
fi

# ---------------------------------------------------------------------------
# Verify install
# ---------------------------------------------------------------------------
info ""
info "Verifying installation..."

ERRORS=0
for f in \
    "$SCRIPTS_DIR/mission-stack.py" \
    "$SCRIPTS_DIR/mission-autoresearch.py" \
    "$HOOKS_DIR/mission-session-start.sh"; do
    if [[ -f "$f" ]]; then
        info "  OK: $f"
    else
        warn "  MISSING: $f"
        ERRORS=$((ERRORS + 1))
    fi
done

# Quick doctest smoke-check
if python3 "$SCRIPTS_DIR/mission-stack.py" --doctest &>/dev/null; then
    info "  OK: mission-stack.py doctests pass"
else
    warn "  WARN: mission-stack.py doctests failed — check Python version compatibility"
fi

if [[ "$ERRORS" -gt 0 ]]; then
    error "Installation incomplete — $ERRORS file(s) missing. Check permissions and re-run."
fi

info ""
info "Mission system installed. Next steps:"
info "  1. Run 'source ~/.zshrc' (or open a new terminal) to activate the SessionStart hook"
info "  2. Set your workspace slug for each project:"
info "       export CLAUDE_CODE_WORKSPACE_SLUG=products-my-project   (in .envrc)"
info "       — OR —"
info "       echo 'products-my-project' > /path/to/project/.commandboard-workspace"
info "  3. Create your first mission: /mission new"
