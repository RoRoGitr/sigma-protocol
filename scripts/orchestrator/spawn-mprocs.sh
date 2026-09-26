#!/bin/bash
# ============================================================================
# spawn-mprocs.sh - Sigma Protocol Multi-Agent Orchestration with mprocs TUI
# ============================================================================
# Uses mprocs (https://github.com/pvolok/mprocs) for a beautiful TUI
# with sidebar process management, keyboard navigation, and remote control.
#
# Usage:
#   ./spawn-mprocs.sh <project_root> [num_streams] [--agent=claude|manual]
#   ./spawn-mprocs.sh . 4
#   ./spawn-mprocs.sh /path/to/project 6 --agent=codex (example)
#
# Requirements:
#   - mprocs installed (brew install mprocs)
#   - git repository initialized
#   - Your chosen AI agent installed (claude or manual mode)
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DEFAULT_STREAMS=4
MAX_STREAMS=8
AGENT_TYPE="${SIGMA_AGENT:-auto}"

# Parse arguments
PROJECT_ROOT="${1:-.}"
NUM_STREAMS_ARG="${2:-}"
AGENT_ARG=""

# Parse remaining arguments
for arg in "$@"; do
    case $arg in
        --agent=*)
            AGENT_ARG="${arg#*=}"
            ;;
    esac
done

# Resolve absolute path
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

# Logging
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

count_backlog_stories() {
    local backlog_json="$1"
    local declared_count=""
    local counted_ids=0

    if [ ! -f "$backlog_json" ]; then
        echo 0
        return
    fi

    declared_count=$(grep -Eo '"totalStories"[[:space:]]*:[[:space:]]*[0-9]+' "$backlog_json" 2>/dev/null | head -1 | grep -Eo '[0-9]+' || true)
    if [ -n "$declared_count" ]; then
        echo "$declared_count"
        return
    fi

    counted_ids=$(grep -Eo '"id"[[:space:]]*:' "$backlog_json" 2>/dev/null | wc -l | tr -d ' ')
    echo "${counted_ids:-0}"
}

count_backlog_root_stories() {
    local backlog_root="$1"
    local total=0
    local count=0

    if [ ! -d "$backlog_root" ]; then
        echo 0
        return
    fi

    while IFS= read -r backlog_json; do
        [ -z "$backlog_json" ] && continue
        count=$(count_backlog_stories "$backlog_json")
        if [[ "$count" =~ ^[0-9]+$ ]]; then
            total=$((total + count))
        fi
    done < <(find "$backlog_root" -mindepth 2 -maxdepth 2 -type f -name 'prd.json' | sort)

    echo "$total"
}

clamp_stream_count() {
    local count="$1"
    if [ "$count" -gt "$MAX_STREAMS" ]; then
        echo "$MAX_STREAMS"
    else
        echo "$count"
    fi
}

# Detect stream count dynamically
detect_stream_count() {
    local project="$1"
    local count=0
    
    # Check streams.json
    local streams_json="$project/.sigma/orchestration/streams.json"
    if [ -f "$streams_json" ]; then
        count=$(grep -o '"name"' "$streams_json" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            echo "$count"
            return
        fi
    fi
    
    # Use canonical machine backlogs
    local canonical_backlogs="$project/.sigma/backlogs"
    count=$(count_backlog_root_stories "$canonical_backlogs")
    if [ "$count" -gt 0 ]; then
        clamp_stream_count "$count"
        return
    fi

    # Count PRD files in orchestration directory
    local prd_dir="$project/.sigma/orchestration/prds"
    if [ -d "$prd_dir" ]; then
        count=$(find "$prd_dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            echo "$count"
            return
        fi
    fi
    
    # Count PRD files in docs/prds
    local docs_prd_dir="$project/docs/prds"
    if [ -d "$docs_prd_dir" ]; then
        count=$(find "$docs_prd_dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ] && [ "$count" -le "$MAX_STREAMS" ]; then
            echo "$count"
            return
        fi
    fi
    
    # Legacy docs/ralph fallback during deprecation window
    local legacy_backlogs="$project/docs/ralph"
    count=$(count_backlog_root_stories "$legacy_backlogs")
    if [ "$count" -gt 0 ]; then
        clamp_stream_count "$count"
        return
    fi
    
    echo "$DEFAULT_STREAMS"
}

# Determine stream count
if [ -n "$NUM_STREAMS_ARG" ] && [[ "$NUM_STREAMS_ARG" =~ ^[0-9]+$ ]]; then
    NUM_STREAMS="$NUM_STREAMS_ARG"
else
    NUM_STREAMS=$(detect_stream_count "$PROJECT_ROOT")
    log_info "Auto-detected $NUM_STREAMS streams from project PRDs/backlogs"
fi

# Validate
if [[ ! "$NUM_STREAMS" =~ ^[0-9]+$ ]] || [ "$NUM_STREAMS" -lt 1 ] || [ "$NUM_STREAMS" -gt "$MAX_STREAMS" ]; then
    log_error "Invalid stream count: $NUM_STREAMS (must be 1-$MAX_STREAMS)"
    exit 1
fi

# Determine agent type
detect_agent() {
    if [ -n "$AGENT_ARG" ]; then
        echo "$AGENT_ARG"
        return
    fi
    
    if [ "$AGENT_TYPE" != "auto" ]; then
        echo "$AGENT_TYPE"
        return
    fi
    
    # Auto-detect: prefer claude, then manual
    if command -v claude &> /dev/null; then
        echo "claude"    else
        echo "manual"
    fi
}

SELECTED_AGENT=$(detect_agent)

# Get agent display name
get_agent_name() {
    case "$1" in
        claude) echo "Claude Code" ;;
        manual) echo "Manual (no auto-launch)" ;;
        *) echo "$1" ;;
    esac
}

# Print banner
agent_display=$(get_agent_name "$SELECTED_AGENT")
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     🐝 SIGMA PROTOCOL - MPROCS ORCHESTRATION                  ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
printf "║  Streams: %-5s  Agent: %-20s              ║\n" "$NUM_STREAMS" "$agent_display"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v mprocs &> /dev/null; then
    log_error "mprocs is not installed. Install with:"
    echo "  brew install mprocs"
    echo "  # or cargo install mprocs"
    exit 1
fi
log_success "mprocs found: $(mprocs --version 2>&1)"

if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &> /dev/null; then
    log_error "Not a git repository: $PROJECT_ROOT"
    exit 1
fi
log_success "Git repository found"

# Check selected agent
AGENT_CMD=""
case "$SELECTED_AGENT" in
    claude)
        if command -v claude &> /dev/null; then
            log_success "Claude Code found"
            AGENT_CMD="claude"
        else
            log_warn "Claude Code not found - falling back to manual mode"
            log_warn "Install with: claude install"
            log_warn "  macOS: brew install --cask claude-code"
            log_warn "  Windows: winget install Anthropic.ClaudeCode"
            log_warn "  npm fallback: npm install -g @anthropic-ai/claude-code"
            SELECTED_AGENT="manual"
        fi
        ;;
