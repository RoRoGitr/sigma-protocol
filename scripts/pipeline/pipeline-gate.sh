#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed. Install with: brew install jq" >&2
  exit 1
fi

# Usage check
if [[ $# -lt 2 ]]; then
  echo "Usage: pipeline-gate.sh <gate_name> <status> [score] [round]" >&2
  echo "  gate_name: anti_slop, ui_validation, devils_advocate, gap_analysis, qa_verification, cross_model_review, coderabbit_review" >&2
  echo "  status: passed, failed, completed, skipped" >&2
  echo "  score: optional numeric (for anti_slop and ui_validation)" >&2
  echo "  round: optional round number" >&2
  exit 1
fi

GATE_NAME="$1"
STATUS="$2"
SCORE="null"; ROUND="null"
# $3/$4 are positional score/round UNLESS they are --flags. All --flags parsed regardless of position.
if [[ -n "${3:-}" && "${3:-}" != --* ]]; then SCORE="$3"; fi
if [[ -n "${4:-}" && "${4:-}" != --* ]]; then ROUND="$4"; fi

# A0 (additive): optional flags for judge gates — reviewer/implementer vendor family + clean-rounds.
REVIEWER_FAMILY=""; IMPLEMENTER_FAMILY=""; CLEAN_ROUNDS="null"; REASON=""
for arg in "$@"; do
  case "$arg" in
    --reviewer-family=*)    REVIEWER_FAMILY="${arg#*=}" ;;
    --implementer-family=*) IMPLEMENTER_FAMILY="${arg#*=}" ;;
    --clean-rounds=*)       CLEAN_ROUNDS="${arg#*=}" ;;
    --reason=*)             REASON="${arg#*=}" ;;
  esac
done
# Map a CLI/agent token to its vendor MODEL family (self-preference bias is about family, not binary).
_vendor_family() {
  case "$1" in
    claude|droid|factory) echo "anthropic" ;;
    codex|openai)         echo "openai" ;;
    gemini|google)        echo "google" ;;
    "")                   echo "" ;;
    *)                    echo "$1" ;;
  esac
}
REVIEWER_FAMILY="$(_vendor_family "$REVIEWER_FAMILY")"
if [[ -z "$IMPLEMENTER_FAMILY" ]]; then
  IMPLEMENTER_FAMILY="$(_vendor_family "$("$SCRIPT_DIR/../detect-cli.sh" 2>/dev/null || echo "")")"
else
  IMPLEMENTER_FAMILY="$(_vendor_family "$IMPLEMENTER_FAMILY")"
fi

# Validate gate name
case "$GATE_NAME" in
  anti_slop|ui_validation|devils_advocate|gap_analysis|qa_verification|cross_model_review|coderabbit_review|greptile_score) ;; # greptile_score = back-compat READ only (Greptile BANNED 2026-07-31)
  *)
    echo "ERROR: Invalid gate name '$GATE_NAME'. Must be one of: anti_slop, ui_validation, devils_advocate, gap_analysis, qa_verification, cross_model_review, coderabbit_review" >&2
    exit 1
    ;;
esac

# Validate status
case "$STATUS" in
  passed|failed|completed|skipped) ;;
  *)
    echo "ERROR: Invalid status '$STATUS'. Must be one of: passed, failed, completed, skipped" >&2
    exit 1
    ;;
esac

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERROR: Not inside a git repository" >&2
  exit 1
fi

CHECKPOINT_FILE="${PIPELINE_STATE_FILE:-${REPO_ROOT}/.pipeline-state.json}"

# ---------------------------------------------------------------------------
# Mutex: serialize concurrent gate-mark invocations so that each agent's
# sync-worktree + counter-read + state-write is atomic.
#
# Uses a mkdir-based lock (POSIX-atomic on all filesystems, no flock/lockf
# dependency). Stale locks (owner PID dead) are removed automatically.
# Timeout: 30 seconds with 0.2s polling.
# ---------------------------------------------------------------------------
LOCK_DIR="${PIPELINE_GATE_LOCK_DIR:-/tmp/sigma-pipeline-gate.lock.d}"
LOCK_TIMEOUT=30
LOCK_POLL=0.2
LOCK_ACQUIRED=false

_release_lock() {
  if [[ "$LOCK_ACQUIRED" == "true" ]]; then
    rm -rf "$LOCK_DIR"
    LOCK_ACQUIRED=false
  fi
}
trap _release_lock EXIT

_acquire_lock() {
  local deadline=$(( $(date +%s) + LOCK_TIMEOUT ))
  while true; do
    # Try to create the lock dir atomically
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      echo $$ > "$LOCK_DIR/pid"
      LOCK_ACQUIRED=true
      return 0
    fi

    # Check for stale lock: if the owning PID no longer exists, forcibly remove it
    if [[ -f "$LOCK_DIR/pid" ]]; then
      local owner_pid
      owner_pid=$(cat "$LOCK_DIR/pid" 2>/dev/null || echo "")
      if [[ -n "$owner_pid" ]] && ! kill -0 "$owner_pid" 2>/dev/null; then
        echo "WARNING: Removing stale pipeline-gate lock (dead PID $owner_pid)" >&2
        rm -rf "$LOCK_DIR"
        continue
      fi
    fi

    # Timeout check
    if [[ $(date +%s) -ge $deadline ]]; then
      echo "ERROR: Could not acquire pipeline-gate mutex after ${LOCK_TIMEOUT}s" >&2
      exit 1
    fi

    sleep "$LOCK_POLL"
  done
}

_acquire_lock
# ---------------------------------------------------------------------------

# Auto-initialize if checkpoint doesn't exist
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
  "$SCRIPT_DIR/pipeline-init.sh"
fi

# Bind the gate result to the current worktree, not a stale earlier diff.
"$SCRIPT_DIR/sync-worktree-state.sh" >/dev/null

CURRENT_CHANGE_COUNTER=$(jq -r '.change_counter // 0' "$CHECKPOINT_FILE")
CURRENT_FINGERPRINT=$(jq -r '.worktree_fingerprint // ""' "$CHECKPOINT_FILE")

# C4: a skip must be self-documenting — flag a silent skip + default the reason so
# gates-summary can tell a benign skip (e.g. PR not yet Ready for CodeRabbit) from a
# real bypass. commit_allowed logic is unchanged (coderabbit_review skipped still passes).
if [[ "$STATUS" == "skipped" && -z "$REASON" ]]; then
  echo "WARN: gate '$GATE_NAME' skipped with NO --reason= — recording 'unspecified-skip' (a silent skip is suspicious; pass --reason=\"...\")" >&2
  REASON="unspecified-skip"
fi

TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# Build the gate entry
GATE_ENTRY=$(jq -n \
  --arg status "$STATUS" \
  --arg updated_at "$TIMESTAMP" \
  --argjson score "$SCORE" \
  --argjson round "$ROUND" \
  --argjson change_counter "$CURRENT_CHANGE_COUNTER" \
  --arg worktree_fingerprint "$CURRENT_FINGERPRINT" \
  --arg reviewer_family "$REVIEWER_FAMILY" \
  --arg implementer_family "$IMPLEMENTER_FAMILY" \
  --argjson clean_rounds "$CLEAN_ROUNDS" \
  --arg reason "$REASON" \
  '{status: $status, updated_at: $updated_at, score: $score, round: $round, change_counter: $change_counter, worktree_fingerprint: $worktree_fingerprint, reviewer_family: (if $reviewer_family=="" then null else $reviewer_family end), implementer_family: (if $implementer_family=="" then null else $implementer_family end), clean_rounds: $clean_rounds, reason: (if $reason=="" then null else $reason end)}')

# Update the checkpoint file with the gate result
UPDATED=$(jq \
  --arg gate_name "$GATE_NAME" \
  --argjson gate_entry "$GATE_ENTRY" \
  '.gates[$gate_name] = $gate_entry' "$CHECKPOINT_FILE")

# Recalculate commit_allowed
UPDATED=$(echo "$UPDATED" | jq '
  .commit_allowed = (
    (.gates.anti_slop.status // "" | IN("passed","completed")) and
    ((.gates.anti_slop.change_counter // -1) == (.change_counter // 0)) and
    (if .has_frontend_changes then (.gates.ui_validation.status // "" | IN("passed","completed")) else true end) and
    (if .has_frontend_changes then ((.gates.ui_validation.change_counter // -1) == (.change_counter // 0)) else true end) and
    (.gates.devils_advocate.status // "" | . == "completed") and
    ((.gates.devils_advocate.change_counter // -1) == (.change_counter // 0)) and
    (.gates.gap_analysis.status // "" | . == "completed") and
    ((.gates.gap_analysis.change_counter // -1) == (.change_counter // 0)) and
    (.gates.qa_verification.status // "" | . == "completed") and
    ((.gates.qa_verification.change_counter // -1) == (.change_counter // 0)) and
    (.gates.cross_model_review.status // "" | . == "completed") and
    ((.gates.cross_model_review.change_counter // -1) == (.change_counter // 0)) and
    ((.gates.coderabbit_review.status // .gates.greptile_score.status // "") | IN("completed", "skipped")) and
    (((.gates.coderabbit_review.change_counter // .gates.greptile_score.change_counter) // -1) == (.change_counter // 0))
  )
')

echo "$UPDATED" > "$CHECKPOINT_FILE"

# Append to gate history (JSONL)
HISTORY_FILE="${PIPELINE_HISTORY_FILE:-${REPO_ROOT}/.pipeline-history.jsonl}"
BRANCH_RAW="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
SESSION_ID=$(jq -r '.session_id // ""' "$CHECKPOINT_FILE" 2>/dev/null || echo "")

jq -nc \
  --arg gate "$GATE_NAME" \
  --arg status "$STATUS" \
  --argjson score "$SCORE" \
  --argjson round "$ROUND" \
  --arg timestamp "$TIMESTAMP" \
  --arg branch "$BRANCH_RAW" \
  --arg session_id "$SESSION_ID" \
  '{gate: $gate, status: $status, score: $score, round: $round, timestamp: $timestamp, branch: $branch, session_id: $session_id}' \
  >> "$HISTORY_FILE"

# --- A0 telemetry + A5 firing-canary (additive; NEVER affects commit_allowed) ---
# The gate_fired event proves the gate ran: a silent fail-open emits no event for a change_counter,
# which gates-summary.mjs --check flags as a SILENT_SKIP. Cost fields are null unless the caller
# exports them (never fabricated). All failures swallowed so telemetry can't break a gate.
{
  TELEMETRY_DIR="${SIGMA_TELEMETRY_DIR:-${REPO_ROOT}/.sigma/telemetry/sessions}"
  mkdir -p "$TELEMETRY_DIR" 2>/dev/null || true
  jq -nc \
    --arg gate "$GATE_NAME" --arg status "$STATUS" --arg ts "$TIMESTAMP" \
    --arg branch "$BRANCH_RAW" --arg session_id "$SESSION_ID" \
    --argjson change_counter "$CURRENT_CHANGE_COUNTER" \
    --arg reviewer_family "$REVIEWER_FAMILY" --arg implementer_family "$IMPLEMENTER_FAMILY" \
    --argjson tokens "${SIGMA_GATE_TOKENS:-null}" \
    --argjson cost "${SIGMA_GATE_COST_USD:-null}" \
    --argjson dur "${SIGMA_GATE_DURATION_MS:-null}" \
    --arg reason "$REASON" \
    '{event:"gate_fired", gate:$gate, status:$status, ts:$ts, branch:$branch, session_id:$session_id, change_counter:$change_counter, reviewer_family:(if $reviewer_family=="" then null else $reviewer_family end), implementer_family:(if $implementer_family=="" then null else $implementer_family end), "gen_ai.usage.total_tokens":$tokens, cost_usd:$cost, duration_ms:$dur, reason:(if $reason=="" then null else $reason end)}' \
    >> "${TELEMETRY_DIR}/${SESSION_ID:-unknown}.jsonl"
} 2>/dev/null || true

# Report
COMMIT_ALLOWED=$(echo "$UPDATED" | jq -r '.commit_allowed')
echo "Gate '$GATE_NAME' recorded: status=$STATUS score=$SCORE round=$ROUND"
echo "Commit allowed: $COMMIT_ALLOWED"
