#!/usr/bin/env bash
# install-sigmahq.sh — Bootstrap SigmaHQ personal kanban + mission command center
#
# Usage:
#   ./scripts/install-sigmahq.sh [OPTIONS]
#
# Options:
#   --force               Overwrite existing install (backs up to ~/.commandboard.backup.TIMESTAMP)
#   --upgrade-runtime     Replace SigmaHQ runtime files while preserving local data
#   --no-rc               Skip adding SigmaHQ env vars to shell RC
#   --no-skills           Skip installing SigmaHQ/methodology skills
#   --no-hooks            Skip installing Claude Code mission hooks
#   --no-pipeline-gates   Skip installing pipeline gate scripts and settings.json hooks
#   --no-open             Skip opening dashboard after install
#   --print-marker        Print current .sigma/installed-version marker and exit (no install)
#
# What it does:
#   1. Checks dependencies (python3 >= 3.10, kanban-md)
#   2. Detects existing install — exits cleanly or backs up with --force
#   3. Copies templates/commandboard/ to ~/.commandboard/ with placeholder substitution
#   4. Installs methodology skills for Claude Code and the SigmaHQ skill for Codex unless skipped
#   5. Installs mission hook scripts for Claude Code unless skipped
#   5b. Installs pipeline gate scripts to ~/.local/bin/ and wires settings.json hooks unless skipped
#   6. Optionally adds SIGMAHQ_HOME + Claude compatibility env vars to shell RC
#   7. Runs first sync to populate briefing.json + build dashboard-live.html
#   8. Writes .sigma/installed-version marker
#   9. Prints next steps

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
FORCE=0
UPGRADE_RUNTIME=0
NO_RC=0
NO_SKILLS=0
NO_HOOKS=0
NO_PIPELINE_GATES=0
NO_OPEN=0
PRINT_MARKER=0

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=1 ;;
        --upgrade-runtime) UPGRADE_RUNTIME=1 ;;
        --no-rc)   NO_RC=1 ;;
        --no-skills) NO_SKILLS=1 ;;
        --no-hooks) NO_HOOKS=1 ;;
        --no-pipeline-gates) NO_PIPELINE_GATES=1 ;;
        --no-open) NO_OPEN=1 ;;
        --print-marker) PRINT_MARKER=1 ;;
        --help|-h)
            sed -n '/^# /s/^# \?//p' "$0" | head -26
            exit 0
            ;;
        *)
            error "Unknown flag: $arg"
            echo "  Usage: $0 [--force] [--upgrade-runtime] [--no-rc] [--no-skills] [--no-hooks] [--no-pipeline-gates] [--no-open] [--print-marker]"
            exit 1
            ;;
    esac
done

# ── --print-marker early exit ──────────────────────────────────
# Used by sigma-upgrade.sh to read current marker without running install.
if [ "$PRINT_MARKER" -eq 1 ]; then
    SCRIPT_DIR_PM="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT_PM="$(cd "$SCRIPT_DIR_PM/.." && pwd)"
    MARKER_FILE_PM="$REPO_ROOT_PM/.sigma/installed-version"
    if [ -f "$MARKER_FILE_PM" ]; then
        cat "$MARKER_FILE_PM"
    else
        echo "null"
    fi
    exit 0
fi

# ── Version marker ────────────────────────────────────────────
# Reads previous .sigma/installed-version, determines install_method, writes updated marker.
# install_method:
#   fresh   — marker did not exist before this run
#   repair  — marker existed AND commit matches current HEAD
#   upgrade — marker existed AND commit differs from current HEAD
write_version_marker() {
    local repo_root="$1"
    local pipeline_installed="$2"   # true|false
    local settings_patched="$3"     # true|false

    local marker_dir="$repo_root/.sigma"
    local marker_file="$marker_dir/installed-version"

    # Ensure .sigma/ exists
    mkdir -p "$marker_dir"

    # Resolve current version (read VERSION file if present, else fall back to 3.0.0)
    local version="3.0.0"
    if [ -f "$repo_root/VERSION" ]; then
        version="$(cat "$repo_root/VERSION" | tr -d '[:space:]')"
    fi

    # Current commit SHA (short)
    local current_commit
    current_commit="$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || echo "unknown")"

    # Current timestamp (ISO-8601 UTC)
    local installed_at
    installed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || python3 -c 'import datetime; print(datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"))')"

    # Read previous marker if it exists
    local install_method="fresh"
    local previous_version="null"
    local previous_commit="null"

    if [ -f "$marker_file" ] && command -v jq &>/dev/null; then
        local prev_commit_val
        prev_commit_val="$(jq -r '.commit // empty' "$marker_file" 2>/dev/null || echo "")"
        local prev_version_val
        prev_version_val="$(jq -r '.version // empty' "$marker_file" 2>/dev/null || echo "")"

        if [ -n "$prev_commit_val" ]; then
            # Marker existed — determine repair vs upgrade
            if [ "$prev_commit_val" = "$current_commit" ]; then
                install_method="repair"
            else
                install_method="upgrade"
            fi
            previous_commit="\"$prev_commit_val\""
            previous_version="\"${prev_version_val:-unknown}\""
        fi
    fi

    # Build JSON via jq (atomic write via tmpfile + mv)
    local tmpfile
    tmpfile="$(mktemp "$marker_dir/.installed-version.XXXXXX")"

    jq -n \
        --arg version "$version" \
        --arg installed_at "$installed_at" \
        --arg commit "$current_commit" \
        --arg install_method "$install_method" \
        --argjson previous_version "$previous_version" \
        --argjson previous_commit "$previous_commit" \
        --argjson pipeline_gates_installed "$pipeline_installed" \
        --argjson settings_json_patched "$settings_patched" \
        '{
            version: $version,
            installed_at: $installed_at,
            commit: $commit,
            install_method: $install_method,
            previous_version: $previous_version,
            previous_commit: $previous_commit,
            pipeline_gates_installed: $pipeline_gates_installed,
            settings_json_patched: $settings_json_patched
        }' > "$tmpfile" && mv "$tmpfile" "$marker_file"

    success "Version marker written: .sigma/installed-version (method: $install_method, version: $version, commit: $current_commit)"
}

# ── Locate template source ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/templates/commandboard"
DEST_DIR="$HOME/.commandboard"

if [ ! -d "$TEMPLATE_DIR" ]; then
    error "Template directory not found: $TEMPLATE_DIR"
    error "Run this script from the sigma-protocol repo root."
    exit 1
fi

copy_file_or_dir() {
    local src="$1"
    local dest="$2"
    if [ -d "$src" ]; then
        rm -rf "$dest"
        mkdir -p "$(dirname "$dest")"
        cp -R "$src" "$dest"
    elif [ -f "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
    fi
}

backup_runtime_file() {
    local rel="$1"
    local backup_root="$2"
    if [ -e "$DEST_DIR/$rel" ]; then
        mkdir -p "$backup_root/$(dirname "$rel")"
        cp -R "$DEST_DIR/$rel" "$backup_root/$rel"
    fi
}

upgrade_runtime_files() {
    local backup="$DEST_DIR/archive/runtime-backups/$(date +%Y%m%d-%H%M%S)"
    local runtime_paths=(
        "README.md"
        "dashboard.html"
        "sync-dashboard.sh"
        "install-daily-refresh.sh"
        "state-maintenance.py"
        "lib"
        "bin"
        "missions/_schema"
    )

    warn "Runtime upgrade mode: preserving local tasks, missions, dumps, stats, settings, and schedules."
    mkdir -p "$backup"
    for rel in "${runtime_paths[@]}"; do
        backup_runtime_file "$rel" "$backup"
        copy_file_or_dir "$TEMPLATE_DIR/$rel" "$DEST_DIR/$rel"
    done
    success "Runtime files upgraded. Backup: $backup"
}

echo ""
echo -e "${BOLD}SigmaHQ Bootstrap${RESET}"
echo "────────────────────────────────────────────────────────"

# ── Dependency preflight ───────────────────────────────────────
header "Step 1/7: Dependency check"

# python3 >= 3.10
if ! command -v python3 &>/dev/null; then
    error "python3 not found."
    echo "  Install: https://python.org/downloads"
    exit 1
fi

PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]; }; then
    error "python3 >= 3.10 required (found $PY_VER)."
    echo "  Install: https://python.org/downloads"
    exit 1
fi
success "python3 $PY_VER"

# kanban-md (optional — board CLI features degrade gracefully without it)
if ! command -v kanban-md &>/dev/null; then
    warn "kanban-md not found — installing SigmaHQ WITHOUT kanban CLI integration."
    echo "  Board files still install; card automation stays dormant until you add"
    echo "  kanban-md (npm install -g kanban-md) and re-run: $0 --force"
else
    KANBAN_VER=$(kanban-md --version 2>/dev/null | head -1 || echo "unknown")
    success "kanban-md ($KANBAN_VER)"
fi

# ── Existing install detection ─────────────────────────────────
header "Step 2/7: Install check"

if [ -d "$DEST_DIR" ]; then
    if [ "$FORCE" -eq 1 ]; then
        BACKUP="$HOME/.commandboard.backup.$(date +%Y%m%d-%H%M%S)"
        warn "Existing install found. Backing up to $BACKUP"
        mv "$DEST_DIR" "$BACKUP"
        success "Backed up existing install → $BACKUP"
    elif [ "$UPGRADE_RUNTIME" -eq 1 ]; then
        warn "Existing install found at $DEST_DIR"
        upgrade_runtime_files
    else
        warn "Existing install found at $DEST_DIR"
        warn "Use --force to overwrite (existing install will be backed up)."
        warn "Use --upgrade-runtime to update SigmaHQ code without touching local tasks."
        echo ""
        echo "  Recommended runtime upgrade:"
        echo "    ./scripts/install-sigmahq.sh --upgrade-runtime"
        echo ""
        echo "  Re-running sync to refresh briefing.json..."
        if [ -f "$DEST_DIR/sync-dashboard.sh" ]; then
            bash "$DEST_DIR/sync-dashboard.sh" --no-open && success "Sync complete."
        fi
        echo ""
        echo -e "  Dashboard: ${CYAN}$DEST_DIR/dashboard-live.html${RESET}"
        # Write/refresh the version marker before exiting — bypassed otherwise (U6 P0)
        write_version_marker "$REPO_ROOT" "false" "false"
        exit 0
    fi
fi

# ── Copy template tree ────────────────────────────────────────
header "Step 3/7: Installing files"

if [ "$UPGRADE_RUNTIME" -eq 1 ] && [ -d "$DEST_DIR" ]; then
    info "Runtime files already upgraded in Step 2."
else
    mkdir -p "$DEST_DIR"

    # rsync the template tree
    if command -v rsync &>/dev/null; then
        rsync -av --exclude='.gitkeep' --exclude='__pycache__/' --exclude='*.pyc' "$TEMPLATE_DIR/" "$DEST_DIR/" \
            | grep -v '/$' | while read -r line; do info "$line"; done
    else
        cp -r "$TEMPLATE_DIR/." "$DEST_DIR/"
        find "$DEST_DIR" -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
        find "$DEST_DIR" -name '*.pyc' -type f -delete 2>/dev/null || true
    fi
    success "Files copied to $DEST_DIR"

    # Substitute placeholders in board.md.template → board.md
    BOARD_TEMPLATE="$DEST_DIR/board.md.template"
    BOARD_OUTPUT="$DEST_DIR/board.md"
    TODAY_DATE=$(date +%Y-%m-%d 2>/dev/null || python3 -c 'import datetime; print(datetime.date.today())')
    SIGMAHQ_USER="${USER:-${LOGNAME:-$(id -un 2>/dev/null || echo operator)}}"

    if [ -f "$BOARD_TEMPLATE" ]; then
        sed \
            -e "s/{{USER_NAME}}/$SIGMAHQ_USER/g" \
            -e "s/{{TODAY_DATE}}/$TODAY_DATE/g" \
            "$BOARD_TEMPLATE" > "$BOARD_OUTPUT"
        rm -f "$BOARD_TEMPLATE"
        success "board.md created (owner: $SIGMAHQ_USER, date: $TODAY_DATE)"
    fi
fi

# Ensure directories exist
mkdir -p \
    "$DEST_DIR/workspaces/personal/tasks" \
    "$DEST_DIR/workspaces/products" \
    "$DEST_DIR/workspaces/community" \
    "$DEST_DIR/workspaces/tools" \
    "$DEST_DIR/workspaces/clients" \
    "$DEST_DIR/missions/_schema" \
    "$DEST_DIR/missions/active" \
    "$DEST_DIR/missions/archive" \
    "$DEST_DIR/schedules" \
    "$DEST_DIR/logs" \
    "$DEST_DIR/dumps" \
    "$DEST_DIR/archive"

# Make helper scripts executable
chmod +x "$DEST_DIR/sync-dashboard.sh"
if [ -f "$DEST_DIR/bin/hq" ]; then
    chmod +x "$DEST_DIR/bin/hq"
fi
if [ -f "$DEST_DIR/install-daily-refresh.sh" ]; then
    chmod +x "$DEST_DIR/install-daily-refresh.sh"
fi
if [ -f "$DEST_DIR/state-maintenance.py" ]; then
    chmod +x "$DEST_DIR/state-maintenance.py"
fi
success "SigmaHQ runtime scripts are executable"

# Create empty stub files that the sync script expects
[ -f "$DEST_DIR/stats.json" ] || echo '{"level":1,"rank":"E","xp":0,"xpNext":500,"tasksCompleted":0,"streak":0,"totalXp":0}' > "$DEST_DIR/stats.json"
[ -f "$DEST_DIR/active-agents.json" ] || echo '{"agents":[],"total_running":0,"total_completed_today":0}' > "$DEST_DIR/active-agents.json"
[ -f "$DEST_DIR/review-queue.json" ] || echo '{"items":[]}' > "$DEST_DIR/review-queue.json"
[ -f "$DEST_DIR/dispatch.json" ] || echo '{"global":{},"queues":[]}' > "$DEST_DIR/dispatch.json"
[ -f "$DEST_DIR/briefing.json" ] || echo '{}' > "$DEST_DIR/briefing.json"
[ -f "$DEST_DIR/stats-events.jsonl" ] || : > "$DEST_DIR/stats-events.jsonl"
[ -f "$DEST_DIR/ui-settings.json" ] || echo '{"theme":"tokyo-night","sidebar":{"width":280,"sections":{},"pinned":["personal"],"recent":[]}}' > "$DEST_DIR/ui-settings.json"
success "Stub JSON files created"

# ── Methodology skills ────────────────────────────────────────
header "Step 4/7: Skills"

CLAUDE_DIR="${CLAUDE_CODE_CONFIG_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_CONFIG_DIR:-$HOME/.codex}"
SKILLS_SRC="$REPO_ROOT/templates/skills"
SKILLS_DEST="$CLAUDE_DIR/skills"
CODEX_SKILLS_DEST="$CODEX_DIR/skills"
CLAUDE_SKILLS=(decisions-patterns gotchas-patterns sprint-patterns prd-patterns sigmahq)
CODEX_SKILLS=(sigmahq)

if [ "$NO_SKILLS" -eq 1 ]; then
    warn "Skipping skills (--no-skills)."
elif [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DEST"
    for skill in "${CLAUDE_SKILLS[@]}"; do
        if [ -d "$SKILLS_SRC/$skill" ]; then
            if [ -d "$SKILLS_DEST/$skill" ] && [ "$FORCE" -eq 0 ] && [ "$UPGRADE_RUNTIME" -eq 0 ]; then
                info "Claude skill already installed: $skill"
            else
                rm -rf "$SKILLS_DEST/$skill"
                cp -R "$SKILLS_SRC/$skill" "$SKILLS_DEST/$skill"
                success "Installed Claude skill: $skill"
            fi
        else
            warn "Missing skill template: $skill"
        fi
    done
    mkdir -p "$CODEX_SKILLS_DEST"
    for skill in "${CODEX_SKILLS[@]}"; do
        if [ -d "$SKILLS_SRC/$skill" ]; then
            rm -rf "$CODEX_SKILLS_DEST/$skill"
            cp -R "$SKILLS_SRC/$skill" "$CODEX_SKILLS_DEST/$skill"
            success "Installed Codex skill: $skill"
        else
            warn "Missing Codex skill template: $skill"
        fi
    done
else
    warn "Skill template directory not found: $SKILLS_SRC"
fi

# ── Mission hooks ─────────────────────────────────────────────
header "Step 5/7: Mission hooks"

HOOK_INSTALLER="$REPO_ROOT/scripts/mission/install-hooks.sh"
if [ "$NO_HOOKS" -eq 1 ]; then
    warn "Skipping mission hooks (--no-hooks)."
    echo "    bash scripts/mission/install-hooks.sh"
elif [ -f "$HOOK_INSTALLER" ]; then
    if [ "$FORCE" -eq 1 ] || [ "$UPGRADE_RUNTIME" -eq 1 ]; then
        HOOK_STATUS=0
        bash "$HOOK_INSTALLER" --force || HOOK_STATUS=$?
    else
        HOOK_STATUS=0
        bash "$HOOK_INSTALLER" || HOOK_STATUS=$?
    fi

    if [ "$HOOK_STATUS" -eq 0 ]; then
        success "Mission hooks installed"
    else
        warn "Mission hook install encountered an issue."
        warn "Run manually: bash scripts/mission/install-hooks.sh"
    fi
else
    warn "Mission hook installer not found: $HOOK_INSTALLER"
fi

# ── Pipeline gates ────────────────────────────────────────────
header "Step 5b/7: Pipeline gate scripts"

# State flags captured for the version marker written at end of install.
MARKER_PIPELINE_INSTALLED=false
MARKER_SETTINGS_PATCHED=false

PIPELINE_SCRIPTS_SRC="$REPO_ROOT/scripts/pipeline"
PIPELINE_BIN_DEST="$HOME/.local/bin"
PIPELINE_SETTINGS_INSTALLER="$REPO_ROOT/scripts/install-pipeline-settings.sh"

if [ "$NO_PIPELINE_GATES" -eq 1 ]; then
    warn "Skipping pipeline gates (--no-pipeline-gates)."
    echo "    bash scripts/install-pipeline-settings.sh"
elif [ ! -d "$PIPELINE_SCRIPTS_SRC" ]; then
    warn "Pipeline scripts directory not found: $PIPELINE_SCRIPTS_SRC"
    warn "Run slice 0g first to generate scripts/pipeline/*.sh"
else
    # Create ~/.local/bin if needed
    mkdir -p "$PIPELINE_BIN_DEST"

    GATE_INSTALL_ERRORS=0
    GATE_INSTALL_COUNT=0
    GATE_SKIP_COUNT=0

    for script in "$PIPELINE_SCRIPTS_SRC"/*.sh; do
        [ -f "$script" ] || continue
        script_name="$(basename "$script")"
        dest="$PIPELINE_BIN_DEST/$script_name"

        # Copy (not symlink) so ~/.local/bin keeps working if the checkout
        # moves or is deleted. Legacy symlinks from older installs are replaced.
        if [ -L "$dest" ]; then
            rm -f "$dest"
        elif [ -f "$dest" ]; then
            if cmp -s "$script" "$dest"; then
                GATE_SKIP_COUNT=$((GATE_SKIP_COUNT + 1))
                continue
            fi
            if [ "$FORCE" -eq 0 ] && [ "$UPGRADE_RUNTIME" -eq 0 ]; then
                # Different content and we are not forcing — preserve user edits
                info "Skipping (existing file differs, use --force to overwrite): $script_name"
                GATE_SKIP_COUNT=$((GATE_SKIP_COUNT + 1))
                continue
            fi
            rm -f "$dest"
        fi

        cp "$script" "$dest"
        chmod +x "$dest"
        GATE_INSTALL_COUNT=$((GATE_INSTALL_COUNT + 1))
    done

    if [ "$GATE_INSTALL_COUNT" -gt 0 ]; then
        success "Installed $GATE_INSTALL_COUNT pipeline script(s) to $PIPELINE_BIN_DEST"
    fi
    if [ "$GATE_SKIP_COUNT" -gt 0 ]; then
        info "$GATE_SKIP_COUNT pipeline script(s) already up-to-date (idempotent)"
    fi
    # Count total installed+skipped to determine whether pipeline gates are present
    local_total=$((GATE_INSTALL_COUNT + GATE_SKIP_COUNT))
    if [ "$local_total" -gt 0 ] || [ "$GATE_INSTALL_COUNT" -gt 0 ]; then
        MARKER_PIPELINE_INSTALLED=true
    fi

    # Wire settings.json hooks via dedicated patcher
    if [ -f "$PIPELINE_SETTINGS_INSTALLER" ]; then
        SETTINGS_STATUS=0
        bash "$PIPELINE_SETTINGS_INSTALLER" || SETTINGS_STATUS=$?
        if [ "$SETTINGS_STATUS" -eq 0 ]; then
            success "Pipeline gate hooks wired in settings.json"
            MARKER_SETTINGS_PATCHED=true
        else
            warn "settings.json patcher encountered an issue."
            warn "Run manually: bash scripts/install-pipeline-settings.sh"
        fi
    else
        warn "Pipeline settings installer not found: $PIPELINE_SETTINGS_INSTALLER"
    fi

    # ── 8-Gate model summary (slice 0j) ──────────────────────────
    echo ""
    echo -e "  ${BOLD}What you got — 8-Gate Pipeline Model:${RESET}"
    echo ""
    echo -e "  ${CYAN}Gate 1 — Anti-Slop${RESET}"
    echo "           Blocks AI-generated boilerplate and low-signal prose."
    echo "           Agent: codex-anti-slop. Fires on Stop."
    echo ""
    echo -e "  ${CYAN}Gate 2 — UI Validation${RESET} ${YELLOW}(frontend only)${RESET}"
    echo "           Verifies component rendering, responsive layout, and visual regressions."
    echo "           Agent: codex-ui-validator. Skips on backend-only changes."
    echo ""
    echo -e "  ${CYAN}Gate 3 — Expect / Browser Test${RESET} ${YELLOW}(frontend only)${RESET}"
    echo "           Runs browser-level acceptance tests against the running app."
    echo "           Tool: expect-cli. Skips on backend-only changes."
    echo ""
    echo -e "  ${CYAN}Gate 4 — Devils Advocate${RESET}"
    echo "           Adversarial post-implementation review — challenges assumptions,"
    echo "           finds edge cases, and surfaces blind spots."
    echo "           Agent: codex-reviewer."
    echo ""
    echo -e "  ${CYAN}Gate 5 — Gap Analysis${RESET}"
    echo "           Iterative completeness check. Requires 2 consecutive clean rounds"
    echo "           with score >= 8 and zero new findings to exit."
    echo "           Agent: codex-gap-analyst."
    echo ""
    echo -e "  ${CYAN}Gate 6 — QA Verification${RESET}"
    echo "           Structured test coverage review — unit, integration, edge cases."
    echo "           Agent: qa-engineer."
    echo ""
    echo -e "  ${CYAN}Gate 7 — Cross-Model Review${RESET}"
    echo "           Mandatory adversarial review by a second model (codex exec gpt-5.5)."
    echo "           Catches same-model blind spots. Cannot be skipped."
    echo ""
    echo -e "  ${CYAN}Gate 8 — Greptile Score${RESET}"
    echo "           Codebase-aware AI code review. Skip only if repo not indexed in Greptile."
    echo ""
    echo "  State tracked per-repo in .pipeline-state.json"
    echo "  Override (explicit user request only): SKIP_PIPELINE_CHECK=1 git commit"
    echo ""
fi

# ── Shell RC ──────────────────────────────────────────────────
header "Step 6/7: Shell configuration"

ENV_LINES=(
    'export SIGMAHQ_HOME="$HOME/.commandboard"'
    'export PATH="$SIGMAHQ_HOME/bin:$PATH"'
    'export CLAUDE_CODE_COMMANDBOARD="$SIGMAHQ_HOME"'
)

if [ "$NO_RC" -eq 1 ]; then
    warn "Skipping shell RC update (--no-rc). Add manually if needed:"
    for line in "${ENV_LINES[@]}"; do
        echo "    $line"
    done
else
    # Detect shell RC
    RC_FILE=""
    if [[ "${SHELL:-}" == */zsh ]]; then
        RC_FILE="$HOME/.zshrc"
    elif [[ "${SHELL:-}" == */bash ]]; then
        RC_FILE="$HOME/.bashrc"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        RC_FILE="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        RC_FILE="$HOME/.bashrc"
    else
        RC_FILE="$HOME/.profile"
    fi

    if grep -qF "SIGMAHQ_HOME" "$RC_FILE" 2>/dev/null; then
        info "SIGMAHQ_HOME already set in $RC_FILE"
        if ! grep -qF '.commandboard/bin' "$RC_FILE" 2>/dev/null && ! grep -qF '$SIGMAHQ_HOME/bin' "$RC_FILE" 2>/dev/null; then
            echo 'export PATH="$SIGMAHQ_HOME/bin:$PATH"' >> "$RC_FILE"
            success "Added SigmaHQ bin path to $RC_FILE"
        fi
        if ! grep -qF "CLAUDE_CODE_COMMANDBOARD" "$RC_FILE" 2>/dev/null; then
            echo 'export CLAUDE_CODE_COMMANDBOARD="$SIGMAHQ_HOME"' >> "$RC_FILE"
            success "Added Claude Code compatibility env var to $RC_FILE"
        fi
    else
        echo "" >> "$RC_FILE"
        echo "# SigmaHQ - personal kanban + mission command center" >> "$RC_FILE"
        for line in "${ENV_LINES[@]}"; do
            echo "$line" >> "$RC_FILE"
        done
        success "Added SigmaHQ env vars to $RC_FILE"
        info "Run: source $RC_FILE"
    fi
fi

# ── First sync ────────────────────────────────────────────────
header "Step 7/7: First sync"

info "Running hq sync to build briefing.json..."
if "$DEST_DIR/bin/hq" sync --no-open; then
    success "First sync complete"
else
    warn "Sync encountered an issue — dashboard may be empty until you re-run."
    warn "Run: hq sync --no-open"
fi

# ── Version marker ────────────────────────────────────────────
# Write after all install work is complete so the marker reflects actual state.
write_version_marker "$REPO_ROOT" "$MARKER_PIPELINE_INSTALLED" "$MARKER_SETTINGS_PATCHED"

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
echo -e "${GREEN}${BOLD}SigmaHQ installed at $DEST_DIR${RESET}"
echo ""
echo -e "  ${BOLD}Open dashboard:${RESET}"
echo "    open $DEST_DIR/dashboard-live.html"
echo ""
echo -e "  ${BOLD}Sync on session start:${RESET}"
echo "    hq sync --no-open"
echo ""
echo -e "  ${BOLD}Optional daily 8 AM refresh:${RESET}"
echo "    hq daily-refresh install --time 08:00"
echo ""
echo -e "  ${BOLD}Create your first task:${RESET}"
echo "    kanban-md create --dir ~/.commandboard/workspaces/personal --title \"My task\""
echo ""
echo -e "  ${BOLD}Set a north-star mission (in Claude Code):${RESET}"
echo "    /mission new"
echo ""
echo -e "  ${BOLD}Installed methodology skills:${RESET}"
echo "    decisions-patterns, gotchas-patterns, sprint-patterns, prd-patterns, sigmahq"
echo ""

# Open dashboard unless suppressed
if [ "$NO_OPEN" -eq 0 ]; then
    LIVE="$DEST_DIR/dashboard-live.html"
    if [ -f "$LIVE" ]; then
        info "Opening dashboard..."
        open "$LIVE" 2>/dev/null || xdg-open "$LIVE" 2>/dev/null || \
            echo "  Open manually: $LIVE"
    fi
fi
