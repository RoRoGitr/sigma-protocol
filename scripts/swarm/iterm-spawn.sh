#!/usr/bin/env bash
# =============================================================================
# iTerm Spawn Helper for Sigma Swarm
# =============================================================================
# Creates a single iTerm2 window with one tab per command.
#
# Usage:
#   scripts/swarm/iterm-spawn.sh --project=/path/to/repo --commands-file=/path/to/commands.txt
#
# commands.txt format:
#   One shell command per line.
# =============================================================================

set -euo pipefail

PROJECT_DIR=""
COMMANDS_FILE=""
DRY_RUN=false

log_error() { echo "[iterm] $*" >&2; }

show_help() {
  cat << EOF
iTerm Spawn Helper for Sigma Swarm

USAGE:
  iterm-spawn.sh --project=PATH --commands-file=PATH [--dry-run]

OPTIONS:
  --project=PATH        Project root directory (required)
  --commands-file=PATH  Path to commands file (required)
  --dry-run             Print generated AppleScript instead of executing
  --help                Show this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project=*)
        PROJECT_DIR="${1#*=}"
        shift
        ;;
      --commands-file=*)
        COMMANDS_FILE="${1#*=}"
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

validate_requirements() {
  if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "iTerm spawn only works on macOS"
    exit 1
  fi
  if [[ ! -d "/Applications/iTerm.app" && ! -d "/Applications/iTerm2.app" ]]; then
    log_error "iTerm2 not found in /Applications"
    exit 1
  fi
  if [[ -z "$PROJECT_DIR" || ! -d "$PROJECT_DIR" ]]; then
    log_error "--project is required and must exist"
    exit 1
  fi
  if [[ -z "$COMMANDS_FILE" || ! -f "$COMMANDS_FILE" ]]; then
    log_error "--commands-file is required and must exist"
    exit 1
  fi
}

escape_for_applescript() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  echo "$str"
}

read_commands() {
  local -n out_ref=$1
  out_ref=()
  while IFS= read -r line; do
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [[ -z "$line" ]]; then
      continue
    fi
    out_ref+=("$line")
  done < "$COMMANDS_FILE"
}

main() {
  parse_args "$@"
  validate_requirements

  local commands=()
  read_commands commands
  if [[ ${#commands[@]} -eq 0 ]]; then
    log_error "No commands found in $COMMANDS_FILE"
    exit 1
  fi

  local project_escaped
  project_escaped="$(escape_for_applescript "$PROJECT_DIR")"

  local script
  script="$(mktemp -t sigma-swarm-iterm.XXXXXX.applescript)"
  trap 'rm -f "$script" 2>/dev/null || true' EXIT

  {
    echo "tell application \"iTerm\""
    echo "  activate"
    echo "  set newWindow to (create window with default profile)"
    echo "  tell newWindow"
    echo "    tell current session to write text \"cd \\\"$project_escaped\\\" && $(escape_for_applescript "${commands[0]}")\""
    echo "  end tell"
    echo "end tell"

    # Additional commands -> new tabs in the same window.
    for ((i=1; i<${#commands[@]}; i++)); do
      cmd_escaped="$(escape_for_applescript "${commands[$i]}")"
      echo "tell application \"iTerm\""
      echo "  tell current window"
      echo "    set newTab to (create tab with default profile)"
      echo "    tell current session of newTab to write text \"cd \\\"$project_escaped\\\" && $cmd_escaped\""
      echo "  end tell"
      echo "end tell"
    done
  } > "$script"

  if $DRY_RUN; then
    cat "$script"
    exit 0
  fi

  osascript "$script"
}

main "$@"

