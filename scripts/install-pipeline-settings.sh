#!/usr/bin/env bash
# install-pipeline-settings.sh — Idempotent settings.json patcher for pipeline gate hooks.
#
# Wires three Claude Code hook types into ~/.claude/settings.json:
#   hooks.Stop        -> stop-pipeline.sh   (parallel pipeline runner)
#   hooks.PreToolUse  -> pre-commit-gate.sh (blocks non-compliant commits)
#   hooks.PreToolUse  -> sprint-step-guard.sh (blocks out-of-order sprint ops)
#   hooks.PostToolUse -> sprint-step-tracker.sh (advances sprint state)
#
# Idempotent: re-running 3x produces identical settings.json after the first run.
# Preserves all existing hook entries — never clobbers them.
# Backs up settings.json before any mutation.
#
# Usage:
#   bash scripts/install-pipeline-settings.sh [OPTIONS]
#
# Options:
#   --settings-file PATH   Override target settings.json path (default: ~/.claude/settings.json)
#   --bin-dir PATH         Override bin dir where pipeline scripts live (default: ~/.local/bin)
#   --dry-run              Print what would change without writing anything
#   --force                Re-apply even if hooks appear present
#   --help                 Show this help

set -euo pipefail

# ── Parse args ──────────────────────────────────────────────────────────────
CLAUDE_DIR="${CLAUDE_CODE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
BIN_DIR="${HOME}/.local/bin"
DRY_RUN=0
FORCE=0

for arg in "$@"; do
    case "$arg" in
        --settings-file=*) SETTINGS_FILE="${arg#*=}" ;;
        --bin-dir=*)       BIN_DIR="${arg#*=}" ;;
        --dry-run)         DRY_RUN=1 ;;
        --force)           FORCE=1 ;;
        --help|-h)
            sed -n '/^# /s/^# \?//p' "$0" | head -25
            exit 0
            ;;
    esac
done

# ── Helpers ─────────────────────────────────────────────────────────────────
info()  { echo "[pipeline-settings] $*"; }
warn()  { echo "[pipeline-settings] WARN: $*" >&2; }
error() { echo "[pipeline-settings] ERROR: $*" >&2; exit 1; }

# ── Dependency check ─────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
    error "jq is required but not found. Install with: brew install jq"
fi

# ── Ensure settings.json exists ──────────────────────────────────────────────
if [[ ! -f "$SETTINGS_FILE" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] Would create $SETTINGS_FILE with {}"
    else
        mkdir -p "$(dirname "$SETTINGS_FILE")"
        echo '{}' > "$SETTINGS_FILE"
        info "Created $SETTINGS_FILE"
    fi
fi

# ── Backup before mutation ───────────────────────────────────────────────────
backup_settings() {
    local backup="${SETTINGS_FILE}.bak-$(date +%s)"
    cp "$SETTINGS_FILE" "$backup"
    info "Backup: $backup"
}

# ── Install the gate scripts the hooks point at ─────────────────────────────
# Standalone-safe: copy the pipeline scripts into BIN_DIR ourselves instead of
# assuming install-sigmahq.sh already did. Copies, not symlinks, so the wiring
# survives moving or deleting the checkout.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIPELINE_SRC="$REPO_ROOT/scripts/pipeline"
for gate_script in stop-pipeline.sh pre-commit-gate.sh sprint-step-guard.sh sprint-step-tracker.sh; do
    src="$PIPELINE_SRC/$gate_script"
    dest="$BIN_DIR/$gate_script"
    if [[ ! -f "$src" ]]; then
        warn "Missing in repo: scripts/pipeline/$gate_script — its hook will be wired but inert."
        continue
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] Would install $gate_script -> $dest"
        continue
    fi
    mkdir -p "$BIN_DIR"
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
        :
    else
        [[ -L "$dest" ]] && rm -f "$dest"
        cp "$src" "$dest" && chmod +x "$dest"
        info "Installed $gate_script -> $dest"
    fi
done

# ── Hook definitions ─────────────────────────────────────────────────────────
# Each entry: "hook_type|command_string|matcher (optional, for PreToolUse)|timeout"
# We use a structured approach: build the JSON fragment per hook and check idempotency.

STOP_CMD="bash ${BIN_DIR}/stop-pipeline.sh"
PRECOMMIT_CMD="bash ${BIN_DIR}/pre-commit-gate.sh"
SPRINTGUARD_CMD="bash ${BIN_DIR}/sprint-step-guard.sh"
SPRINTTRACKER_CMD="bash ${BIN_DIR}/sprint-step-tracker.sh"

# ── Check if a command is already present in a hook array ───────────────────
hook_already_present() {
    local hook_type="$1"
    local cmd="$2"
    local settings="$3"
    local count
    count="$(jq --arg ht "$hook_type" --arg cmd "$cmd" \
        '.hooks[$ht] // [] | map(select(.command == $cmd)) | length' \
        "$settings" 2>/dev/null || echo "0")"
    [[ "$count" -gt 0 ]]
}

# ── Append a hook entry idempotently ────────────────────────────────────────
append_hook() {
    local hook_type="$1"     # e.g. "Stop", "PreToolUse", "PostToolUse"
    local cmd="$2"
    local settings="$3"
    local extra_fields="${4:-}"  # optional extra jq fields to merge, e.g. '"timeout":20'

    if hook_already_present "$hook_type" "$cmd" "$settings" && [[ "$FORCE" -eq 0 ]]; then
        info "Already present ($hook_type): $cmd — skipping"
        return
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "[dry-run] Would append to $hook_type: $cmd"
        return
    fi

    local entry
    # Use jq -n --arg to safely encode the command string without introducing trailing newlines
    if [[ -n "$extra_fields" ]]; then
        entry="$(jq -cn --arg cmd "$cmd" --argjson extra "{${extra_fields}}" \
            '{"type":"command","command":$cmd} + $extra')"
    else
        entry="$(jq -cn --arg cmd "$cmd" '{"type":"command","command":$cmd}')"
    fi

    local updated
    updated="$(jq --arg ht "$hook_type" --argjson entry "$entry" \
        '.hooks[$ht] = ((.hooks[$ht] // []) + [$entry])' \
        "$settings")"
    echo "$updated" > "$settings"
    info "Wired ($hook_type): $cmd"
}

# ── Main patching logic ──────────────────────────────────────────────────────
info "Target: $SETTINGS_FILE"
info "Bin dir: $BIN_DIR"

if [[ "$DRY_RUN" -eq 0 ]]; then
    backup_settings
fi

# Stop hook — parallel pipeline runner (timeout 20s per stop-pipeline.sh comment)
append_hook "Stop" "$STOP_CMD" "$SETTINGS_FILE" '"timeout":20'

# PreToolUse hooks — commit gate + sprint guard (both read stdin, output JSON decision)
append_hook "PreToolUse" "$PRECOMMIT_CMD" "$SETTINGS_FILE"
append_hook "PreToolUse" "$SPRINTGUARD_CMD" "$SETTINGS_FILE"

# PostToolUse hook — sprint step tracker
append_hook "PostToolUse" "$SPRINTTRACKER_CMD" "$SETTINGS_FILE"

# ── Verify result is valid JSON ──────────────────────────────────────────────
if [[ "$DRY_RUN" -eq 0 ]]; then
    if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
        error "settings.json is not valid JSON after patching — check $SETTINGS_FILE"
    fi
    info "settings.json is valid JSON"
fi

info ""
info "Pipeline settings installed. Hooks wired:"
info "  Stop        -> stop-pipeline.sh"
info "  PreToolUse  -> pre-commit-gate.sh"
info "  PreToolUse  -> sprint-step-guard.sh"
info "  PostToolUse -> sprint-step-tracker.sh"
info ""
info "Re-running this script is idempotent — existing entries are never duplicated."
