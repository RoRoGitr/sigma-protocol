#!/usr/bin/env bash
# fusion.sh — cross-harness adapter spine for the fusion primitive.
#
# This is the ONE entrypoint every harness (Claude Code, Codex, Cursor, Factory
# Droid, or a plain shell) shells out to. It normalizes how a task is supplied
# (inline / file / stdin), then calls the shared core (fusion.mjs). Per the
# cross-harness shared-core + adapter doctrine: ONE core, thin per-surface
# adapters that all funnel through here.
#
# Usage:
#   fusion.sh --task "TEXT" [core-flags...]
#   fusion.sh --task-file FILE [core-flags...]
#   echo "TEXT" | fusion.sh [core-flags...]          # task from stdin
#
# Task source (pick one; precedence: --task-file > --task > stdin):
#   --task TEXT       inline task text
#   --task-file FILE  read the task from FILE (passed straight to the core)
#   (stdin)           if neither is given, the task is read from stdin
#
# Core flags forwarded to fusion.mjs unchanged:
#   --json | --panel <auto|ids> | --synthesizer <id> | --timeout <ms> | --max-panel <n>
#
# Security: the task is ALWAYS delivered to the core via a file path — never
# interpolated into a shell string or eval'd. Forwarded flags are passed as an
# argv array. A malicious task body cannot execute.
#
# Exit codes: 0 ok · 2 usage/empty-task error · other = core's exit code.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$SCRIPT_DIR/fusion.mjs"
DETECT="$SCRIPT_DIR/../detect-cli.sh"

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \?//'
}

die() { echo "fusion.sh: $*" >&2; exit 2; }

# ── Parse args ────────────────────────────────────────────────────────────────

TASK_TEXT=""
TASK_FILE=""
HAVE_TASK_TEXT=false
PASSTHROUGH=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)
      [[ $# -ge 2 ]] || die "--task requires a value"
      TASK_TEXT="$2"; HAVE_TASK_TEXT=true; shift 2 ;;
    --task-file)
      [[ $# -ge 2 ]] || die "--task-file requires a value"
      TASK_FILE="$2"; shift 2 ;;
    --json)
      PASSTHROUGH+=("$1"); shift ;;
    --panel|--synthesizer|--timeout|--max-panel|--backend)
      [[ $# -ge 2 ]] || die "$1 requires a value"
      PASSTHROUGH+=("$1" "$2"); shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    -)
      # explicit stdin marker — no-op, stdin is the default source
      shift ;;
    *)
      die "unknown flag: $1 (task goes via --task/--task-file/stdin)" ;;
  esac
done

# ── Resolve the task into a file the core can read ───────────────────────────

command -v node >/dev/null 2>&1 || { echo "fusion.sh: node not found on PATH" >&2; exit 127; }
[[ -f "$CORE" ]] || { echo "fusion.sh: core not found: $CORE" >&2; exit 1; }

TMP=""
RESOLVED_FILE=""
# Must return 0: an EXIT trap whose last command is non-zero overrides the
# script's real exit code on bash 3.2 (turns exit 0 into exit 1).
cleanup() { if [[ -n "$TMP" ]]; then rm -f "$TMP"; fi; return 0; }
trap cleanup EXIT

# Sets globals RESOLVED_FILE (+ TMP if a temp was created). Runs in the parent
# shell — NOT a command substitution — so the temp is tracked and cleaned up and
# die() exits the whole script.
resolve_task() {
  if [[ -n "$TASK_FILE" ]]; then
    [[ -f "$TASK_FILE" ]] || die "task file not found: $TASK_FILE"
    [[ -s "$TASK_FILE" ]] || die "task file is empty: $TASK_FILE"
    RESOLVED_FILE="$TASK_FILE"
    return
  fi
  TMP="$(mktemp "${TMPDIR:-/tmp}/fusion-task-XXXXXX")"
  if "$HAVE_TASK_TEXT"; then
    printf '%s' "$TASK_TEXT" > "$TMP"
  else
    # Read from stdin (pipe or redirect). cat is safe — content is never eval'd.
    cat > "$TMP"
  fi
  [[ -s "$TMP" ]] || die "empty task (supply --task, --task-file, or pipe text to stdin)"
  RESOLVED_FILE="$TMP"
}

resolve_task

# ── Tag the calling harness (read-only; available to the core/telemetry) ─────

if [[ -f "$DETECT" ]]; then
  FUSION_HARNESS="$(bash "$DETECT" 2>/dev/null || echo unknown)"
else
  FUSION_HARNESS="unknown"
fi
export FUSION_HARNESS

# ── Invoke the shared core (no exec — let the EXIT trap clean the temp) ───────

set +e
# ${arr[@]+...} guards the empty-array case under `set -u` on bash 3.2 (macOS).
node "$CORE" --task-file "$RESOLVED_FILE" ${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}
rc=$?
set -e
exit "$rc"
