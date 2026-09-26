#!/usr/bin/env bash
# scripts/ops-overnight.sh — overnight autonomous loop, three-CLI native dispatch
# Version: 2.0.0
# Called by /ops:overnight command.
#
# Usage:
#   ops-overnight.sh                # fire — auto-detect CLI, dispatch all PRDs
#   ops-overnight.sh --dry-run      # print command that WOULD fire, exit 0
#   ops-overnight.sh --status       # current overnight state
#   ops-overnight.sh morning        # morning debrief placeholder (slice 4d)
#   ops-overnight.sh --help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERNIGHT_DIR="$REPO_ROOT/.sigma/overnight"
DETECT_CLI="$SCRIPT_DIR/detect-cli.sh"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
  grep '^#' "$0" | sed 's/^# \?//'
  exit 0
}

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
MODE="fire"          # fire | dry-run | status | morning | help
MORNING_EXTRA_ARGS=()   # passthrough flags for morning-debrief.py
for arg in "$@"; do
  case "$arg" in
    --dry-run)  MODE="dry-run" ;;
    --status)   MODE="status" ;;
    morning)    MODE="morning" ;;
    --help|-h)  show_help ;;
    # morning-mode passthrough flags
    --since=*|--format=*|--target-dir=*)
      MORNING_EXTRA_ARGS+=("$arg") ;;
    *) echo "[overnight] unknown flag: $arg" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Detect CLI
# ---------------------------------------------------------------------------
if [[ ! -x "$DETECT_CLI" ]]; then
  echo "[overnight] ERROR: scripts/detect-cli.sh not found or not executable." >&2
  exit 1
fi

CLI="$("$DETECT_CLI")"

# ---------------------------------------------------------------------------
# Refusals
# ---------------------------------------------------------------------------
refuse_if_unsupported() {
  case "$CLI" in
    unknown)
      echo "[overnight] ERROR: Cannot detect active CLI." >&2
      echo "  Set CLAUDECODE_ENTRYPOINT (Claude Code), CODEX_EXEC=1 (Codex)," >&2
      echo "  or DROID_SESSION_ID (Factory Droid) before running overnight." >&2
      exit 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Build the fire command per CLI
# ---------------------------------------------------------------------------
build_cmd() {
  case "$CLI" in
    claude)
      echo "claude -p '/sigma-dispatch --all' --permission-mode acceptEdits"
      ;;
    codex)
      echo "codex exec -m gpt-5.5 --auto high '/sigma-dispatch --all'"
      ;;
    droid)
      echo "bash scripts/sigma-dispatch.sh --all"
      ;;
    *)
      echo "[overnight] ERROR: Unknown CLI '$CLI' after detection." >&2
      exit 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Ensure overnight dir exists
# ---------------------------------------------------------------------------
ensure_overnight_dir() {
  mkdir -p "$OVERNIGHT_DIR"
}

# ---------------------------------------------------------------------------
# Count deferred questions
# ---------------------------------------------------------------------------
count_deferred() {
  find "$OVERNIGHT_DIR" -maxdepth 1 -name "deferred-questions-*.md" 2>/dev/null | wc -l | tr -d ' '
}

# ---------------------------------------------------------------------------
# STATUS mode
# ---------------------------------------------------------------------------
if [[ "$MODE" == "status" ]]; then
  ensure_overnight_dir
  echo "[overnight] Status report — $(date)"
  echo ""

  # Latest run summary
  LATEST_RUN="$(find "$OVERNIGHT_DIR" -maxdepth 1 -name "run-*.json" 2>/dev/null | sort | tail -n1)"
  if [[ -n "$LATEST_RUN" ]]; then
    echo "Last run: $(basename "$LATEST_RUN")"
    cat "$LATEST_RUN"
  else
    echo "No run summaries found."
  fi

  echo ""
  DEFERRED="$(count_deferred)"
  echo "Deferred questions pending: $DEFERRED"
  exit 0
fi

# ---------------------------------------------------------------------------
# MORNING mode — delegate to morning-debrief.py
# ---------------------------------------------------------------------------
if [[ "$MODE" == "morning" ]]; then
  # Only inject --target-dir if the caller didn't already supply one
  MORNING_TARGET_ARG=()
  for a in "${MORNING_EXTRA_ARGS[@]+"${MORNING_EXTRA_ARGS[@]}"}"; do
    if [[ "$a" == --target-dir=* ]]; then
      MORNING_TARGET_ARG=()
      break
    fi
  done
  # If no --target-dir was found in extra args, prepend the default
  has_target=0
  for a in "${MORNING_EXTRA_ARGS[@]+"${MORNING_EXTRA_ARGS[@]}"}"; do
    [[ "$a" == --target-dir=* ]] && has_target=1
  done
  if [[ $has_target -eq 0 ]]; then
    exec python3 "$SCRIPT_DIR/morning-debrief.py" \
      "--target-dir=$OVERNIGHT_DIR" \
      "${MORNING_EXTRA_ARGS[@]+"${MORNING_EXTRA_ARGS[@]}"}"
  else
    exec python3 "$SCRIPT_DIR/morning-debrief.py" \
      "${MORNING_EXTRA_ARGS[@]}"
  fi
fi

# ---------------------------------------------------------------------------
# DRY-RUN and FIRE modes both need CLI validation and CMD
# ---------------------------------------------------------------------------
refuse_if_unsupported
CMD="$(build_cmd)"

# ---------------------------------------------------------------------------
# DRY-RUN mode
# ---------------------------------------------------------------------------
if [[ "$MODE" == "dry-run" ]]; then
  echo "[overnight] --dry-run — active CLI: $CLI"
  echo ""
  echo "Would execute:"
  echo "  $CMD"
  echo ""
  echo "Deferred questions would write to:"
  echo "  $OVERNIGHT_DIR/deferred-questions-<timestamp>.md"
  echo ""
  echo "Run summary would write to:"
  echo "  $OVERNIGHT_DIR/run-<timestamp>.json"
  exit 0
fi

# ---------------------------------------------------------------------------
# FIRE mode
# ---------------------------------------------------------------------------
ensure_overnight_dir
START_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_LABEL="$(date +%Y-%m-%d-%H%M%S)"

echo "[overnight] Starting at $(date) — active CLI: $CLI"
echo "[overnight] Command: $CMD"
echo ""

# Run the dispatch; capture exit code without aborting (set -e is active, so use ||)
EXIT_CODE=0
eval "$CMD" || EXIT_CODE=$?

END_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DEFERRED="$(count_deferred)"

# Write run summary JSON
RUN_FILE="$OVERNIGHT_DIR/run-${START_LABEL}.json"
cat > "$RUN_FILE" <<JSON
{
  "started_at": "$START_TS",
  "ended_at": "$END_TS",
  "cli": "$CLI",
  "PRDs_completed": [],
  "PRDs_failed": [],
  "deferred_question_count": $DEFERRED,
  "exit_code": $EXIT_CODE
}
JSON

echo ""
echo "[overnight] Run complete — exit code: $EXIT_CODE"
echo "[overnight] Summary written: $RUN_FILE"
echo "[overnight] Deferred questions: $DEFERRED"

if [[ "$EXIT_CODE" -ne 0 ]]; then
  echo "[overnight] One or more PRDs failed. Check /sigma-dispatch output above." >&2
  exit "$EXIT_CODE"
fi
