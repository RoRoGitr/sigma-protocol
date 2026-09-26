#!/usr/bin/env bash
# =============================================================================
# tmux Spawn Helper for Sigma Swarm
# =============================================================================
# Creates a tmux session with one window per command.
#
# Usage:
#   scripts/swarm/tmux-spawn.sh --project=/path/to/repo --commands-file=/path/to/commands.txt
#
# commands.txt format:
#   One shell command per line.
# =============================================================================

set -euo pipefail

PROJECT_DIR=""
COMMANDS_FILE=""
SESSION_NAME="sigma-swarm"
ATTACH=true
DRY_RUN=false

log_error() { echo "[tmux] $*" >&2; }

show_help() {
  cat << EOF
tmux Spawn Helper for Sigma Swarm

USAGE:
  tmux-spawn.sh --project=PATH --commands-file=PATH [--session=NAME] [--no-attach] [--dry-run]

OPTIONS:
  --project=PATH        Project root directory (required)
  --commands-file=PATH  Path to commands file (required)
  --session=NAME        tmux session name (default: sigma-swarm)
  --no-attach           Do not attach after spawning
  --dry-run             Print tmux commands instead of executing
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
      --session=*)
        SESSION_NAME="${1#*=}"
        shift
        ;;
      --no-attach)
        ATTACH=false
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
  if ! command -v tmux >/dev/null 2>&1; then
    log_error "tmux not found"
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
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    log_error "Session '$SESSION_NAME' already exists. Kill it with: tmux kill-session -t $SESSION_NAME"
    exit 1
  fi
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

run() {
  if $DRY_RUN; then
    echo "$*"
    return 0
  fi
  "$@"
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

  run tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" -n "stream-1"
  run tmux send-keys -t "$SESSION_NAME:stream-1" "cd \"$PROJECT_DIR\" && ${commands[0]}" C-m

  for ((i=1; i<${#commands[@]}; i++)); do
    local win="stream-$((i+1))"
    run tmux new-window -t "$SESSION_NAME" -n "$win" -c "$PROJECT_DIR"
    run tmux send-keys -t "$SESSION_NAME:$win" "cd \"$PROJECT_DIR\" && ${commands[$i]}" C-m
  done

  if $ATTACH; then
    run tmux attach -t "$SESSION_NAME"
  else
    echo "[tmux] session created: $SESSION_NAME"
  fi
}

main "$@"

