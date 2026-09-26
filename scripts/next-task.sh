#!/usr/bin/env bash
# scripts/next-task.sh — minimal /next-task implementation.
#
# Reads .sigma/backlogs/<mode>/TASKS.md (the Step 11.5 handoff manifest) and
# returns the highest-priority claimable task: status unclaimed AND every
# "Blocked by" task is done. Read-only selection; this script does not reserve
# tasks or prevent concurrent agents from selecting the same task.
#
# Contract: steps/step-11.5-task-handoff (/next-task Autonomous-Loop Contract).
#
# Usage:
#   bash scripts/next-task.sh [--mode implementation|prototype] [--priority P0|P1|P2|P3]
#                             [--agent <name>] [--dry-run] [--help]
#
# Exit codes:
#   0  a task was found and printed
#   3  no claimable task (fleet idle) — caller should stop, never spin
#   2  usage / missing TASKS.md error
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MODE="implementation"
PRIORITY=""
AGENT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)      MODE="$2"; shift 2 ;;
    --mode=*)    MODE="${1#*=}"; shift ;;
    --priority)  PRIORITY="$2"; shift 2 ;;
    --priority=*) PRIORITY="${1#*=}"; shift ;;
    --agent)     AGENT="$2"; shift 2 ;;
    --agent=*)   AGENT="${1#*=}"; shift ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --help|-h)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "next-task: unknown option: $1" >&2; exit 2 ;;
  esac
done

TASKS_FILE="${REPO_ROOT}/.sigma/backlogs/${MODE}/TASKS.md"
if [[ ! -f "$TASKS_FILE" ]]; then
  echo "next-task: no TASKS.md at ${TASKS_FILE}" >&2
  echo "Run /step-11.5-task-handoff first to generate the execution manifest." >&2
  exit 2
fi

# Pass 1: collect every task id whose status is done (for blocker resolution).
DONE_IDS="$(awk '
  /^##[[:space:]]+T[0-9]+:/ { id=$2; sub(/:$/,"",id); cur=id; next }
  /^\*\*Status:\*\*/ {
    s=$0; sub(/.*Status:\*\*[[:space:]]*/,"",s); sub(/[[:space:]].*$/,"",s)
    if (s=="done") print cur
  }
' "$TASKS_FILE" | tr "\n" " ")"

is_done() {
  local needle="$1"
  for d in $DONE_IDS; do [[ "$d" == "$needle" ]] && return 0; done
  return 1
}

# Pass 2: emit one record per task: ID|TITLE|PRIORITY|STATUS|BLOCKERS
RECORDS="$(awk '
  function flush() {
    if (cur != "") printf "%s|%s|%s|%s|%s\n", cur, title, prio, status, blockers
  }
  /^##[[:space:]]+T[0-9]+:/ {
    flush()
    cur=$2; sub(/:$/,"",cur)
    title=$0; sub(/^##[[:space:]]+T[0-9]+:[[:space:]]*/,"",title)
    prio=""; status=""; blockers=""
    next
  }
  /^\*\*Priority:\*\*/ { p=$0; sub(/.*Priority:\*\*[[:space:]]*/,"",p); sub(/[[:space:]].*$/,"",p); prio=p; next }
  /^\*\*Status:\*\*/   { s=$0; sub(/.*Status:\*\*[[:space:]]*/,"",s); sub(/[[:space:]].*$/,"",s); status=s; next }
  /Blocked by:/ {
    b=$0; sub(/.*Blocked by:[[:space:]]*/,"",b)
    gsub(/\([^)]*\)/,"",b); gsub(/[, ]+/," ",b); gsub(/^ +| +$/,"",b)
    if (b=="none" || b=="None" || b=="-") b=""
    blockers=b; next
  }
  END { flush() }
' "$TASKS_FILE")"

pick=""
for rank in P0 P1 P2 P3; do
  [[ -n "$PRIORITY" && "$PRIORITY" != "$rank" ]] && continue
  while IFS='|' read -r id title prio status blockers; do
    [[ -z "$id" ]] && continue
    [[ "$prio" != "$rank" ]] && continue
    [[ "$status" != "unclaimed" ]] && continue
    ready=true
    for b in $blockers; do is_done "$b" || { ready=false; break; }; done
    $ready || continue
    pick="${id}|${title}|${prio}|${blockers}"
    break
  done <<< "$RECORDS"
  [[ -n "$pick" ]] && break
done

if [[ -z "$pick" ]]; then
  echo "Fleet idle: no claimable task in ${MODE} backlog${PRIORITY:+ at ${PRIORITY}}."
  # Summary so the operator sees why.
  echo "$RECORDS" | awk -F'|' 'NF>=4 { c[$4]++ } END { for (s in c) printf "  %s: %d\n", s, c[s] }'
  exit 3
fi

IFS='|' read -r PICK_ID PICK_TITLE PICK_PRIO PICK_BLOCKERS <<< "$pick"
echo "Next task: ${PICK_ID} — ${PICK_TITLE} (${PICK_PRIO})"
echo "Blocked by: ${PICK_BLOCKERS:-none (all clear)}"
echo "Source: ${TASKS_FILE}"
if $DRY_RUN; then
  echo "(dry-run — no claim written)"
  exit 0
fi
if [[ -n "$AGENT" ]]; then
  echo "Candidate for agent=${AGENT}: reserve ${PICK_ID} through the project's serialized coordinator or atomic claim mechanism before starting. This selector writes no claim and does not auto-requeue conflicts."
fi
exit 0
