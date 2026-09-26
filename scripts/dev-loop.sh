#!/usr/bin/env bash
# scripts/dev-loop.sh — thin wrapper around /sigma-dispatch --all with state tracking
# @dev-loop v5.0.0 — see .agents/skills/dev-loop/SKILL.md
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_FILE="${REPO_ROOT}/.sigma/orchestration/dev-loop-state.json"
PRD_STATUS_FILE="${REPO_ROOT}/docs/prds/.prd-status.json"
PRD_DIR="${REPO_ROOT}/docs/prds"
DISPATCH_SCRIPT="${REPO_ROOT}/scripts/sigma-dispatch.sh"

# ── arg parsing ──────────────────────────────────────────────────────────────
FROM_PRD=""
TO_PRD=""
BATCH=""
DRY_RUN=false
STATUS_ONLY=false
RESET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)    FROM_PRD="$2"; shift 2 ;;
    --from=*)  FROM_PRD="${1#*=}"; shift ;;
    --to)      TO_PRD="$2"; shift 2 ;;
    --to=*)    TO_PRD="${1#*=}"; shift ;;
    --batch)   BATCH="$2"; shift 2 ;;
    --batch=*) BATCH="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --status)  STATUS_ONLY=true; shift ;;
    --reset)   RESET=true; shift ;;
    --help|-h)
      cat <<'EOF'
@dev-loop v5.0.0 — thin wrapper around /sigma-dispatch --all

USAGE
  bash scripts/dev-loop.sh [options]

OPTIONS
  --from <PRD-ID>   Start of PRD range (e.g. F01)
  --to <PRD-ID>     End of PRD range (e.g. F05)
  --batch <name>    Named batch from Step 11.5 PRD swarm output
  --dry-run         Print execution plan without running anything
  --status          Print current orchestration state and exit
  --reset           Clear state file (restart from scratch)
  --help            Show this help

EXAMPLES
  bash scripts/dev-loop.sh                        # all unbuilt PRDs
  bash scripts/dev-loop.sh --from F01 --to F05   # range
  bash scripts/dev-loop.sh --dry-run              # preview plan
  bash scripts/dev-loop.sh --status               # check state

STATE
  .sigma/orchestration/dev-loop-state.json        # Ctrl-C safe; resume on next run

DOCS
  .agents/skills/dev-loop/SKILL.md               # full spec
  docs/strategy/2026-05-23-cli-native-prd-upgrade.md
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1. Run --help for usage." >&2; exit 1 ;;
  esac
done

mkdir -p "$(dirname "$STATE_FILE")"

# ── --reset ───────────────────────────────────────────────────────────────────
if $RESET; then
  if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
    echo "State file cleared. Next run starts from scratch."
  else
    echo "No state file found — already clean."
  fi
  exit 0
fi

# ── --status ──────────────────────────────────────────────────────────────────
if $STATUS_ONLY; then
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "No orchestration state found. Run @dev-loop to start."
    exit 0
  fi
  echo "=== @dev-loop state ==="
  cat "$STATE_FILE"
  exit 0
fi

# ── detect active CLI ─────────────────────────────────────────────────────────
detect_cli() {
  if [[ -n "${CLAUDE_CODE_VERSION:-}" ]]; then echo "claude"
  elif [[ -n "${CODEX_VERSION:-}" ]];     then echo "codex"
  elif [[ -n "${DROID_VERSION:-}" ]];     then echo "droid"
  else                                         echo "claude"   # safe default
  fi
}
ACTIVE_CLI="$(detect_cli)"

# ── collect PRDs ──────────────────────────────────────────────────────────────
collect_prds() {
  local prds=()
  if [[ -d "$PRD_DIR" ]]; then
    while IFS= read -r -d '' f; do
      local base
      base="$(basename "$f" .md)"
      # skip flows/ subdirectory (Step 5 prototypes) and the status file
      [[ "$f" == */flows/* ]] && continue
      [[ "$base" == .prd-status ]] && continue
      prds+=("$base")
    done < <(find "$PRD_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)
  fi
  [[ ${#prds[@]} -gt 0 ]] && printf '%s\n' "${prds[@]}"
}

# ── filter to unbuilt ─────────────────────────────────────────────────────────
filter_unbuilt() {
  local prd="$1"
  if [[ ! -f "$PRD_STATUS_FILE" ]]; then
    echo "$prd"   # no status file = nothing is done
    return
  fi
  local status
  status="$(python3 -c "
import json, sys
data = json.load(open('$PRD_STATUS_FILE'))
entry = data.get('$prd', {})
print(entry.get('status', 'pending'))
" 2>/dev/null || echo "pending")"
  if [[ "$status" != "done" && "$status" != "verified" ]]; then
    echo "$prd"
  fi
}

# ── apply range filter ────────────────────────────────────────────────────────
in_range() {
  local prd="$1"
  [[ -z "$FROM_PRD" && -z "$TO_PRD" ]] && { echo "$prd"; return; }
  local lo="${FROM_PRD:-}"
  local hi="${TO_PRD:-}"
  # simple lexicographic range check (works for F01..F99)
  if [[ -n "$lo" && "$prd" < "$lo" ]]; then return; fi
  if [[ -n "$hi" && "$prd" > "$hi" ]]; then return; fi
  echo "$prd"
}

# ── build planned order ───────────────────────────────────────────────────────
PLANNED=()
while IFS= read -r prd; do
  [[ -z "$prd" ]] && continue
  unbuilt="$(filter_unbuilt "$prd")"
  [[ -z "$unbuilt" ]] && continue
  ranged="$(in_range "$prd")"
  [[ -z "$ranged" ]] && continue
  PLANNED+=("$prd")
done < <(collect_prds)

if [[ ${#PLANNED[@]} -eq 0 ]]; then
  echo "No unbuilt PRDs found. All up to date."
  exit 0
fi

# ── resume: skip already-completed items from previous state ──────────────────
if [[ -f "$STATE_FILE" ]] && ! $DRY_RUN; then
  COMPLETED_JSON="$(python3 -c "
import json
data = json.load(open('$STATE_FILE'))
print(json.dumps(data.get('completed', [])))
" 2>/dev/null || echo "[]")"
  FILTERED=()
  for prd in "${PLANNED[@]}"; do
    already="$(python3 -c "
import json, sys
done = json.loads('$COMPLETED_JSON')
print('yes' if '$prd' in done else 'no')
" 2>/dev/null || echo "no")"
    [[ "$already" == "yes" ]] && continue
    FILTERED+=("$prd")
  done
  PLANNED=("${FILTERED[@]}")
  if [[ ${#PLANNED[@]} -eq 0 ]]; then
    echo "All PRDs in plan already completed. Run --reset to restart."
    exit 0
  fi
  echo "Resuming from prior state. ${#PLANNED[@]} PRDs remaining."
fi

# ── dry-run: show plan and exit ───────────────────────────────────────────────
if $DRY_RUN; then
  echo "=== @dev-loop dry-run ==="
  echo "CLI:           $ACTIVE_CLI"
  echo "PRDs planned:  ${#PLANNED[@]}"
  echo "Dispatch via:  bash scripts/sigma-dispatch.sh --all"
  echo ""
  echo "Execution order:"
  local_i=1
  for prd in "${PLANNED[@]}"; do
    printf "  %2d. %s\n" "$local_i" "$prd"
    (( local_i++ ))
  done
  echo ""
  echo "State file:    $STATE_FILE"
  echo ""
  echo "(No changes made. Remove --dry-run to execute.)"
  exit 0
fi

# ── write initial state ───────────────────────────────────────────────────────
PLANNED_JSON="$(printf '%s\n' "${PLANNED[@]}" | python3 -c "
import json, sys
prds = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(prds))
")"

python3 - <<PYEOF
import json, datetime
state = {
    "started_at": datetime.datetime.utcnow().isoformat() + "Z",
    "active_cli": "$ACTIVE_CLI",
    "planned_order": json.loads('$PLANNED_JSON'),
    "completed": [],
    "failed": [],
    "in_progress": None,
    "last_update": datetime.datetime.utcnow().isoformat() + "Z"
}
with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF

echo "=== @dev-loop v5.0.0 ==="
echo "CLI:     $ACTIVE_CLI"
echo "PRDs:    ${#PLANNED[@]}"
echo "Dispatch: bash scripts/sigma-dispatch.sh --all"
echo ""

# ── check sigma-dispatch exists ───────────────────────────────────────────────
if [[ ! -f "$DISPATCH_SCRIPT" ]]; then
  echo "ERROR: $DISPATCH_SCRIPT not found." >&2
  echo "       Run /sigma-dispatch (Phase 3) first to generate it." >&2
  exit 1
fi

# ── invoke sigma-dispatch --all ───────────────────────────────────────────────
CONSECUTIVE_FAILURES=0

update_state() {
  local prd="$1" result="$2"   # result: completed | failed
  python3 - <<PYEOF
import json, datetime

with open("$STATE_FILE") as f:
    state = json.load(f)

state["in_progress"] = None
state["last_update"] = datetime.datetime.utcnow().isoformat() + "Z"

prd = "$prd"
if "$result" == "completed":
    if prd not in state["completed"]:
        state["completed"].append(prd)
else:
    if prd not in state["failed"]:
        state["failed"].append(prd)

with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF
}

mark_in_progress() {
  local prd="$1"
  python3 - <<PYEOF
import json, datetime
with open("$STATE_FILE") as f:
    state = json.load(f)
state["in_progress"] = "$prd"
state["last_update"] = datetime.datetime.utcnow().isoformat() + "Z"
with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF
}

for prd in "${PLANNED[@]}"; do
  echo "→ Dispatching $prd ..."
  mark_in_progress "$prd"

  if bash "$DISPATCH_SCRIPT" "$prd"; then
    echo "✓ $prd complete"
    update_state "$prd" "completed"
    CONSECUTIVE_FAILURES=0
  else
    echo "✗ $prd failed — logging and continuing"
    update_state "$prd" "failed"
    (( CONSECUTIVE_FAILURES++ ))

    if (( CONSECUTIVE_FAILURES >= 3 )); then
      echo ""
      echo "ERROR: 3 consecutive PRD failures. Something systemic is broken." >&2
      echo "       Review state at $STATE_FILE" >&2
      echo "       Fix the issue, then re-run @dev-loop (it will resume)." >&2
      exit 1
    fi
  fi
done

# ── final summary ─────────────────────────────────────────────────────────────
python3 - <<PYEOF
import json
with open("$STATE_FILE") as f:
    state = json.load(f)
completed = len(state.get("completed", []))
failed    = len(state.get("failed", []))
total     = len(state.get("planned_order", []))
print(f"\n=== @dev-loop complete ===")
print(f"Total:     {total}")
print(f"Completed: {completed}")
print(f"Failed:    {failed}")
if failed:
    print(f"Failed PRDs: {', '.join(state['failed'])}")
    print("Re-run @dev-loop to retry failed PRDs, or --reset to start over.")
PYEOF
