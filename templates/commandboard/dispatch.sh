#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# dispatch.sh — SigmaHQ Parallel Agent Dispatch Engine
# ──────────────────────────────────────────────────────────────
# Usage:
#   dispatch.sh all          — dispatch all auto_dispatch=true queues
#   dispatch.sh {workspace}  — dispatch tasks for specific workspace
#   dispatch.sh status       — show running agents with elapsed time
#   dispatch.sh stop [ws]    — stop agents (all or specific workspace)
#   dispatch.sh review       — show review queue summary
# ──────────────────────────────────────────────────────────────

COMMANDBOARD="$HOME/.commandboard"
PROJECTS_JSON="$COMMANDBOARD/projects.json"
DISPATCH_JSON="$COMMANDBOARD/dispatch.json"
ACTIVE_AGENTS_JSON="$COMMANDBOARD/active-agents.json"
REVIEW_QUEUE_JSON="$COMMANDBOARD/review-queue.json"
LOCKED_JSON="$COMMANDBOARD/lib/locked_json.py"

# ── Helpers ──

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

ensure_active_agents() {
  if [[ ! -f "$ACTIVE_AGENTS_JSON" ]]; then
    echo '{"agents":[]}' > "$ACTIVE_AGENTS_JSON"
  fi
}

expand_path() {
  echo "${1/#\~/$HOME}"
}

get_ticket_prefix() {
  # Maps project key to ticket prefix — passes key via argv to avoid injection
  python3 - "$1" << 'PYEOF'
import sys
key = sys.argv[1]
prefixes = {
    'acme': 'AC', 'demo': 'DM',
    'personal': 'PR', 'sss-protocol': 'SS', 'discord-bots': 'DB',
    'tradebench': 'TB', 'sigmahq-ops': 'HQ', 'jet-quest': 'JQ',
    'elderly-meet-design': 'EM',
    'sample-app': 'SA'
}
print(prefixes.get(key, 'XX'))
PYEOF
}

get_project_key() {
  # Maps dispatch.json workspace names to projects.json keys
  python3 - "$1" << 'PYEOF'
import sys
ws = sys.argv[1]
ws_map = {
    'clients/jet-quest': 'jet-quest',
    'clients/elderlyMeetDesign': 'elderly-meet-design',
    'products/acme': 'acme',
    'products/tradebench': 'tradebench',
    'products/sample-app': 'sample-app',
    'products/sss-protocol': 'sss-protocol',
    'community/sample-community': 'sample-community',
    'tools/discord-bots': 'discord-bots',
    'tools/donna': 'donna',
    'tools/sigmahq-ops': 'sigmahq-ops'
}
print(ws_map.get(ws, ws))
PYEOF
}

get_project_path() {
  python3 - "$1" "$PROJECTS_JSON" << 'PYEOF'
import json, sys
key = sys.argv[1]
with open(sys.argv[2]) as f:
    projects = json.load(f)
if key in projects:
    print(projects[key]['path'])
else:
    sys.exit(1)
PYEOF
}

get_project_branch() {
  python3 - "$1" "$PROJECTS_JSON" << 'PYEOF'
import json, sys
key = sys.argv[1]
with open(sys.argv[2]) as f:
    projects = json.load(f)
if key in projects:
    b = projects[key].get('branch')
    print(b if b else '')
PYEOF
}

get_queue_config() {
  python3 - "$1" "$DISPATCH_JSON" << 'PYEOF'
import json, sys
ws = sys.argv[1]
with open(sys.argv[2]) as f:
    data = json.load(f)
for q in data['queues']:
    if q['workspace'] == ws:
        json.dump(q, sys.stdout)
        sys.exit(0)
sys.exit(1)
PYEOF
}

get_max_total_agents() {
  python3 - "$DISPATCH_JSON" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
print(data['global']['max_total_agents'])
PYEOF
}

count_running_agents() {
  ensure_active_agents
  python3 - "$ACTIVE_AGENTS_JSON" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
count = sum(1 for a in data['agents'] if a['status'] == 'running')
print(count)
PYEOF
}

count_running_agents_for_ws() {
  local ws="$1"
  ensure_active_agents
  python3 - "$ws" "$ACTIVE_AGENTS_JSON" << 'PYEOF'
import json, sys
ws = sys.argv[1]
with open(sys.argv[2]) as f:
    data = json.load(f)
count = sum(1 for a in data['agents'] if a['status'] == 'running' and a['workspace'] == ws)
print(count)
PYEOF
}

get_auto_dispatch_workspaces() {
  python3 - "$DISPATCH_JSON" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for q in data['queues']:
    if q.get('auto_dispatch') and q.get('enabled'):
        print(q['workspace'])
PYEOF
}

# ── Dispatch Logic ──

dispatch_workspace() {
  local ws="$1"
  local engine="${2:-claude}"  # claude (default) or codex
  local target_task_id="${3:-}"  # optional: dispatch only this task id
  local manual_mode=0
  if [[ -n "$target_task_id" ]]; then
    manual_mode=1
  fi
  local project_key
  project_key=$(get_project_key "$ws")

  local prefix
  prefix=$(get_ticket_prefix "$project_key")

  # Get queue config
  local queue_json
  queue_json=$(get_queue_config "$ws") || {
    if (( manual_mode == 1 )); then
      # Manual task deploys should still work even if the workspace is not in
      # dispatch.json yet. Use safe defaults and best-effort skill routing.
      queue_json='{"max_concurrent":1,"agent_type":"general-purpose","priority_filter":["critical","high","medium","low"],"skill_routing":{"default":""}}'
    else
      echo "  [SKIP] No queue config found for workspace: $ws"
      return 0
    fi
  }

  local max_concurrent
  max_concurrent=$(echo "$queue_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['max_concurrent'])")

  local agent_type
  agent_type=$(echo "$queue_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['agent_type'])")

  local priority_filter
  priority_filter=$(echo "$queue_json" | python3 -c "import json,sys; print(','.join(json.load(sys.stdin)['priority_filter']))")

  # Get project path
  local raw_path
  raw_path=$(get_project_path "$project_key") || {
    echo "  [SKIP] No project config found for key: $project_key"
    if (( manual_mode == 1 )); then
      return 1
    fi
    return 0
  }
  local project_path
  project_path=$(expand_path "$raw_path")

  # Get branch
  local branch
  branch=$(get_project_branch "$project_key")

  # Atomic slot reservation (fixes TOCTOU race — count + reserve in one lock)
  local max_total
  max_total=$(get_max_total_agents)
  local reserve_max_total="$max_total"

  local reserve_max_ws="$max_concurrent"
  if [[ -n "$target_task_id" ]]; then
    # Manual task deploys should bypass queue concurrency caps and global
    # dispatch ceilings. A clicked Deploy button is an explicit operator
    # override, not passive queue scheduling.
    reserve_max_ws=999999
    reserve_max_total=999999
  fi

  local reserve_result
  reserve_result=$(python3 "$LOCKED_JSON" reserve_slot "$ACTIVE_AGENTS_JSON" "$ws" "$reserve_max_ws" "$reserve_max_total")

  local reserve_status
  reserve_status=$(echo "$reserve_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['status'])")

  if [[ "$reserve_status" == "global_limit" ]]; then
    local r_running r_max
    r_running=$(echo "$reserve_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['running'])")
    r_max=$(echo "$reserve_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['max'])")
    echo "  [LIMIT] Global agent limit reached ($r_running/$r_max). Skipping $ws."
    if (( manual_mode == 1 )); then
      return 1
    fi
    return 0
  fi

  if [[ "$reserve_status" == "ws_limit" ]]; then
    local r_running r_max
    r_running=$(echo "$reserve_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['running'])")
    r_max=$(echo "$reserve_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['max'])")
    echo "  [LIMIT] Workspace $ws at max ($r_running/$r_max). Skipping."
    if (( manual_mode == 1 )); then
      return 1
    fi
    return 0
  fi

  local slots_available
  slots_available=$(echo "$reserve_result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('slots_available', 1))")
  if [[ -n "$target_task_id" ]]; then
    slots_available=1
  fi

  # Resolve kanban workspace path (boards are at ~/.commandboard/workspaces/{ws}/)
  local ws_path="$COMMANDBOARD/workspaces/$ws"
  if [[ ! -d "$ws_path" ]]; then
    echo "  [SKIP] No workspace at $ws_path"
    if (( manual_mode == 1 )); then
      return 1
    fi
    return 0
  fi

  # Query kanban-md for dispatchable tasks using workspace path
  local tasks_json
  tasks_json=$(kanban-md list --dir "$ws_path" --json 2>/dev/null) || {
    echo "  [SKIP] No dispatchable tasks for $ws"
    if (( manual_mode == 1 )); then
      return 1
    fi
    return 0
  }

  # Filter tasks: status=todo/backlog, matching priority, limit by slots
  local priority_list="$priority_filter"
  local filtered_json
  filtered_json=$(python3 -c "
import json, sys
raw = sys.stdin.read().strip()
if not raw:
    print('[]')
    sys.exit(0)
data = json.loads(raw)
tasks = data.get('tasks', data) if isinstance(data, dict) else data
if not isinstance(tasks, list):
    print('[]')
    sys.exit(0)
target = sys.argv[1].strip()
priorities = set(filter(None, '$priority_list'.split(',')))
if target:
    try:
        target_id = int(target)
    except ValueError:
        print('[]')
        sys.exit(0)
    filtered = [
        t for t in tasks
        if int(t.get('id', -1)) == target_id
        and t.get('status', '') != 'done'
    ]
else:
    filtered = [t for t in tasks
        if t.get('status', '') in ('todo', 'backlog')
        and t.get('priority', 'medium') in priorities]
json.dump(filtered, sys.stdout)
" "$target_task_id" <<< "$tasks_json" 2>/dev/null) || filtered_json="[]"

  local task_count
  task_count=$(python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))" <<< "$filtered_json")

  if (( task_count == 0 )); then
    if [[ -n "$target_task_id" ]]; then
      echo "  [ERROR] Task $target_task_id not found or already done in $ws"
      return 1
    fi
    echo "  [INFO] No dispatchable tasks for $ws (0 matching priority: $priority_filter)"
    return 0
  fi

  echo "  Found $task_count task(s), dispatching up to $slots_available..."

  # Generate dispatch lines: task_id|title|body|tags
  local dispatch_lines
  dispatch_lines=$(python3 -c "
import json, sys
tasks = json.loads(sys.stdin.read())
for t in tasks[:$slots_available]:
    tid = t.get('id', 0)
    title = str(t.get('title', 'Untitled'))
    body = str(t.get('body', '')).replace('\n', ' ')
    tags = ' '.join(t.get('tags', []))
    print(f'{tid}|{title}|{body}|{tags}')
" <<< "$filtered_json" 2>/dev/null) || true

  if [[ -z "$dispatch_lines" ]]; then
    echo "  [INFO] No tasks to dispatch for $ws"
    return 0
  fi

  local dispatched=0

  while IFS='|' read -r task_id title body tags; do
    if [[ -z "$task_id" ]]; then
      continue
    fi

    local ticket_id
    ticket_id=$(printf "%s-%03d" "$prefix" "$task_id")

    local branch_arg=""
    if [[ -n "$branch" ]]; then
      branch_arg="Branch: ${branch}."
    fi

    # ── SSS Skill Routing ──
    # Tags already extracted from filtered_json (no per-task subprocess needed)
    local skill=""
    if [[ -n "$tags" ]]; then
      skill=$(python3 - "$ws" "$tags" "$DISPATCH_JSON" << 'PYEOF'
import json, sys
ws, tags_str, dispatch_path = sys.argv[1], sys.argv[2], sys.argv[3]
tags = tags_str.split()
with open(dispatch_path) as f:
    cfg = json.load(f)
routing = {}
for q in cfg.get("queues", []):
    if q["workspace"] == ws:
        routing = q.get("skill_routing", {})
        break
for tag in tags:
    if tag in routing:
        print(routing[tag]); sys.exit(0)
print(routing.get("default", ""))
PYEOF
      ) || true
    fi

    echo "  [DISPATCH] $ticket_id: $title${skill:+ (skill: /$skill)}"

    local ws_id=""
    local launch_backend="terminal"
    local launched=0
    local cmux_available=0
    if cmux ping >/dev/null 2>&1; then
      cmux_available=1
      launch_backend="cmux"
    fi

    # Build temp prompt + temp launcher script so interactive terminal runs
    # don't depend on fragile shell quoting for long task bodies.
    local launch_script
    launch_script=$(python3 - "$ticket_id" "$title" "$branch_arg" "$body" "$project_path" "$engine" "$skill" "$cmux_available" "$ws" << 'PYEOF'
import os
import shlex
import stat
import sys
import tempfile

ticket = sys.argv[1]
title = sys.argv[2]
branch = sys.argv[3]
body = sys.argv[4]
path = sys.argv[5]
engine = sys.argv[6] if len(sys.argv) > 6 else "claude"
skill = sys.argv[7] if len(sys.argv) > 7 else ""
cmux_available = sys.argv[8] == "1"
workspace = sys.argv[9] if len(sys.argv) > 9 else ""

skill_prefix = f"Use the /{skill} skill for this task. " if skill else ""
progress = ""
if cmux_available:
    progress = (
        "PROGRESS REPORTING: Before starting, run: cmux set-status phase Understanding --icon eye; "
        "After writing tests, run: cmux set-progress 0.33 --label 'Tests written'; "
        "After implementation, run: cmux set-progress 0.66 --label 'Implementing'; "
        "After committing, run: cmux set-progress 1.0 --label 'Complete' && "
        "cmux set-status phase Done --icon check --color '#22c55e'. "
    )

prompt = (
    f"{skill_prefix}You are working on ticket {ticket}: {title}. Full auto mode. {branch} "
    f"Task: {body}. "
    f"{progress}"
    "When done, commit with ticket ID in message and create a PR."
)

prompt_fd, prompt_path = tempfile.mkstemp(prefix="sigmahq-prompt-", suffix=".txt", dir="/tmp")
with os.fdopen(prompt_fd, "w") as f:
    f.write(prompt)

engine_name = "Codex" if engine == "codex" else "Claude Code"
allowed_tools = "Bash,Read,Write,Edit,Grep,Glob"

if engine == "codex":
    launch_line = 'codex -a never -s danger-full-access "$PROMPT_TEXT"'
else:
    launch_line = (
        "command claude --dangerously-skip-permissions "
        f"--allowedTools {shlex.quote(allowed_tools)} "
        '"$PROMPT_TEXT"'
    )

script_fd, script_path = tempfile.mkstemp(prefix="sigmahq-launch-", suffix=".sh", dir="/tmp")
script = f"""#!/usr/bin/env bash
	unset CLAUDECODE
	export SIGMAHQ_TICKET_ID={shlex.quote(ticket)}
	export SIGMAHQ_ENGINE={shlex.quote(engine)}
	export SIGMAHQ_WORKSPACE={shlex.quote(workspace)}
	cd {shlex.quote(path)} || exit 1
PROMPT_FILE={shlex.quote(prompt_path)}
PROMPT_TEXT="$(cat "$PROMPT_FILE")"
rm -f "$PROMPT_FILE"
echo "[SigmaHQ] Ticket: {ticket}"
echo "[SigmaHQ] Engine: {engine_name}"
echo "[SigmaHQ] Dir: {path}"
echo "[SigmaHQ] Launching interactive session..."
{launch_line}
status=$?
echo
echo "[SigmaHQ] Agent exited with status $status"
rm -f "$0"
exec bash
"""
with os.fdopen(script_fd, "w") as f:
    f.write(script)
os.chmod(script_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
print(script_path)
PYEOF
    ) || {
      echo "  [ERROR] Failed to build launcher script for $ticket_id"
      continue
    }

    if (( cmux_available == 1 )); then
      # Capture the first window so we can keep new workspace in it
      local first_window=""
      first_window=$(cmux list-windows 2>/dev/null | grep -oE 'window:[0-9]+' | head -1) || true

      # Spawn as cmux workspace
      # cmux new-workspace returns "OK workspace:N" — extract the ref
      local ws_raw
      local quoted_cmd
      quoted_cmd=$(python3 - "$launch_script" << 'PYEOF'
import sys, shlex
print("bash " + shlex.quote(sys.argv[1]))
PYEOF
      ) || {
        echo "  [ERROR] Failed to quote launcher for $ticket_id"
        continue
      }
      ws_raw=$(cmux new-workspace --command "$quoted_cmd" 2>&1) || {
        echo "  [ERROR] Failed to create cmux workspace for $ticket_id: $ws_raw"
        ws_raw=""
      }
      # Parse "OK workspace:3" → "workspace:3"
      ws_id=$(echo "$ws_raw" | grep -oE 'workspace:[0-9]+' | head -1)
      ws_id="${ws_id:-}"

      if [[ -n "$ws_id" ]]; then
        # Move workspace to original window (prevents new window spawning)
        if [[ -n "$first_window" ]]; then
          cmux move-workspace-to-window --workspace "$ws_id" --window "$first_window" 2>/dev/null || true
        fi

        # ── Name the workspace and set initial sidebar state ──
        local ws_label="${ticket_id}: $(echo "$title" | cut -c1-40)"
        cmux rename-workspace "$ws_label" --workspace "$ws_id" 2>/dev/null || true
        cmux set-status task "$ticket_id" --icon tag --color "#4a9eff" --workspace "$ws_id" 2>/dev/null || true
        cmux set-status agent "$agent_type" --icon sparkle --color "#a78bfa" --workspace "$ws_id" 2>/dev/null || true
        cmux set-progress 0.0 --label "Starting..." --workspace "$ws_id" 2>/dev/null || true

        # Send desktop notification
        cmux notify --title "Dispatched $ticket_id" --body "$title" 2>/dev/null || true
        launched=1
      fi
    fi

    if (( launched == 0 )); then
      launch_backend="terminal"
      local osa_file
      osa_file=$(mktemp /tmp/sigmahq-deploy-XXXXXX.applescript)
      python3 - "$launch_script" > "$osa_file" << 'PYEOF'
import sys
cmd = ("bash " + sys.argv[1]).replace("\\", "\\\\").replace('"', '\\"')
print('tell application "Terminal"')
print('  activate')
print(f'  do script "{cmd}"')
print('end tell')
PYEOF
      if osascript "$osa_file" >/dev/null 2>&1; then
        launched=1
      else
        rm -f "$osa_file"
        echo "  [ERROR] Failed to launch Terminal fallback for $ticket_id"
        continue
      fi
      rm -f "$osa_file"
    fi

    sleep 0.3

    # Get PID — cmux manages its own PTY, use $! or 0 as fallback
    local pid=0

    # Log to active-agents.json via locked module (atomic write, no injection)
    local now
    now=$(now_iso)

    local agent_json
    agent_json=$(python3 - "$pid" "$ws" "$ticket_id" "$title" "$agent_type" "$now" "$task_id" "$ws_id" "$launch_backend" << 'PYEOF'
import json, sys
print(json.dumps({
    "pid": int(sys.argv[1]) if sys.argv[1].isdigit() else 0,
    "workspace": sys.argv[2],
    "ticket_id": sys.argv[3],
    "title": sys.argv[4],
    "agent_type": sys.argv[5],
    "started": sys.argv[6],
    "status": "running",
    "last_activity": sys.argv[6],
    "task_id": int(sys.argv[7]) if sys.argv[7].isdigit() else 0,
    "cmux_workspace": sys.argv[8],
    "launch_backend": sys.argv[9]
}))
PYEOF
    )

    python3 "$LOCKED_JSON" append_agent "$ACTIVE_AGENTS_JSON" "$agent_json"

    # Write v3 session file
    python3 - "$ticket_id" "$ws" "$title" "$agent_type" "$engine" "${skill:-}" "$task_id" "${ws_id:-}" << 'PYEOF'
import sys, json, os
sys.path.insert(0, os.path.expanduser("~/.commandboard/lib"))
try:
    import session_state
    session_state.create_session(
        ticket_id=sys.argv[1], workspace=sys.argv[2], title=sys.argv[3],
        agent_type=sys.argv[4], engine=sys.argv[5], skill=sys.argv[6],
        task_id=int(sys.argv[7]) if sys.argv[7].isdigit() else 0,
        cmux_workspace=sys.argv[8]
    )
except Exception:
    pass  # v3 session write is best-effort, don't break v2 flow
PYEOF

    # Emit session.spawned event to events.jsonl
    python3 - "$ticket_id" "$ws" "$title" << 'PYEOF'
import sys, json, datetime, os
event = {
    "id": os.urandom(4).hex(),
    "type": "session.spawned",
    "priority": "info",
    "ticket_id": sys.argv[1],
    "workspace": sys.argv[2],
    "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "message": f"Agent dispatched for {sys.argv[3]}",
    "data": {}
}
events_file = os.path.expanduser("~/.commandboard/events.jsonl")
with open(events_file, "a") as f:
    f.write(json.dumps(event) + "\n")
PYEOF

    # Move kanban task to doing (using workspace path, not project path)
    if ! kanban-md move --dir "$ws_path" "$task_id" doing 2>/dev/null; then
      echo "  [WARN] Failed to move task $task_id to doing in $ws — task may be re-dispatched"
    fi

    dispatched=$((dispatched + 1))
  done <<< "$dispatch_lines"

  if (( manual_mode == 1 && dispatched == 0 )); then
    echo "  [ERROR] No agents launched for task $target_task_id in $ws"
    return 1
  fi

  echo "  [DONE] Dispatched $dispatched agent(s) for $ws"
}

# ── Commands ──

cmd_dispatch_all() {
  local engine="${1:-claude}"
  echo "═══ Dispatching all auto_dispatch queues (engine: $engine) ═══"
  ensure_active_agents

  local workspaces
  workspaces=$(get_auto_dispatch_workspaces)

  if [[ -z "$workspaces" ]]; then
    echo "No auto_dispatch queues enabled."
    return 0
  fi

  while IFS= read -r ws; do
    echo ""
    echo "── Queue: $ws ──"
    dispatch_workspace "$ws" "$engine"
  done <<< "$workspaces"

  echo ""
  echo "═══ Dispatch complete ═══"
  cmd_status
}

cmd_dispatch_workspace() {
  local ws="$1"
  local engine="${2:-claude}"
  echo "═══ Dispatching workspace: $ws (engine: $engine) ═══"
  ensure_active_agents

  dispatch_workspace "$ws" "$engine"

  echo ""
  echo "═══ Dispatch complete ═══"
  cmd_status
}

cmd_dispatch_task() {
  local ws="${1:-}"
  local task_id="${2:-}"
  local engine="${3:-claude}"

  if [[ -z "$ws" || -z "$task_id" ]]; then
    echo "Usage: dispatch.sh task <workspace> <task_id> [--engine codex]" >&2
    return 1
  fi

  echo "═══ Dispatching task $task_id in workspace: $ws (engine: $engine) ═══"
  ensure_active_agents

  dispatch_workspace "$ws" "$engine" "$task_id"
  local rc=$?

  echo ""
  echo "═══ Dispatch complete ═══"
  if (( rc == 0 )); then
    cmd_status
  fi
  return $rc
}

cmd_status() {
  ensure_active_agents
  echo ""
  echo "═══ Agent Status ═══"

  python3 - "$LOCKED_JSON" "$ACTIVE_AGENTS_JSON" << 'PYEOF'
import json, os, sys, importlib.util
from datetime import datetime, timezone

# Import locked_json module
spec = importlib.util.spec_from_file_location("locked_json", sys.argv[1])
lj = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lj)

agents_path = sys.argv[2]
data = lj.locked_read(agents_path)
if data is None:
    data = {"agents": [], "total_running": 0, "total_completed_today": 0}

agents = data.get("agents", [])
if not agents:
    print("  No agents registered.")
    raise SystemExit(0)

# Check PIDs and update status under lock
changed = False
for agent in agents:
    if agent["status"] == "running" and agent.get("pid", 0) > 0:
        try:
            os.kill(agent["pid"], 0)
        except (ProcessLookupError, PermissionError):
            agent["status"] = "exited"
            changed = True

if changed:
    data["total_running"] = sum(1 for a in agents if a["status"] == "running")
    lj.locked_write(agents_path, data)

# Print table. These files can contain thousands of historical/manual agent
# records, so keep the CLI view bounded unless the operator asks for all rows.
limit_raw = os.environ.get("DISPATCH_STATUS_LIMIT", "50")
try:
    limit = int(limit_raw)
except ValueError:
    limit = 50

def clean(value, fallback="—"):
    if value is None:
        return fallback
    text = str(value).strip()
    return text if text else fallback

def sort_key(agent):
    status_rank = 0 if agent.get("status") == "running" else 1
    started = clean(agent.get("started"), "")
    return (status_rank, started)

display_agents = sorted(agents, key=sort_key)[:limit] if limit > 0 else agents

header = f"{'TICKET':<12} {'WORKSPACE':<25} {'TITLE':<35} {'ELAPSED':<12} {'STATUS':<10}"
print(header)
print("─" * len(header))

now = datetime.now(timezone.utc)
for agent in display_agents:
    ticket = clean(agent.get("ticket_id"), f"pid:{clean(agent.get('pid'), '0')}")
    ws = clean(agent.get("workspace"), clean(agent.get("source"), "manual"))
    title = clean(agent.get("title"), clean(agent.get("agent_name"), clean(agent.get("team_name"), "untitled")))[:33]
    status = clean(agent.get("status"), "unknown")

    started_str = agent.get("started", "")
    if started_str:
        try:
            started = datetime.fromisoformat(started_str.replace("Z", "+00:00"))
            delta = now - started
            hours, remainder = divmod(int(delta.total_seconds()), 3600)
            minutes, seconds = divmod(remainder, 60)
            if hours > 0:
                elapsed = f"{hours}h{minutes:02d}m"
            else:
                elapsed = f"{minutes}m{seconds:02d}s"
        except Exception:
            elapsed = "???"
    else:
        elapsed = "???"

    print(f"{ticket:<12} {ws:<25} {title:<35} {elapsed:<12} {status:<10}")

running = sum(1 for a in agents if a["status"] == "running")
total = len(agents)
remaining = total - len(display_agents)
if remaining > 0:
    print(f"  ... {remaining} more agent records hidden. Set DISPATCH_STATUS_LIMIT=0 to show all.")
print(f"\n  Running: {running}/{total} agents")
PYEOF
}

cmd_stop() {
  local filter_ws="${1:-}"
  ensure_active_agents

  echo "═══ Stopping agents${filter_ws:+ (workspace: $filter_ws)} ═══"

  python3 - "$LOCKED_JSON" "$ACTIVE_AGENTS_JSON" "$filter_ws" << 'PYEOF'
import json, os, signal, sys, importlib.util

spec = importlib.util.spec_from_file_location("locked_json", sys.argv[1])
lj = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lj)

agents_path = sys.argv[2]
filter_ws = sys.argv[3] if len(sys.argv) > 3 else ""

stopped = 0

def _stop(data):
    global stopped
    if data is None:
        return data
    for agent in data.get("agents", []):
        if agent["status"] != "running":
            continue
        if filter_ws and agent.get("workspace") != filter_ws:
            continue
        pid = agent.get("pid", 0)
        ticket = agent.get("ticket_id", "???")
        if pid > 0:
            try:
                os.kill(pid, signal.SIGTERM)
                print(f"  [STOP] {ticket} (PID {pid}) — SIGTERM sent")
            except ProcessLookupError:
                print(f"  [STOP] {ticket} (PID {pid}) — already exited")
            except PermissionError:
                print(f"  [WARN] {ticket} (PID {pid}) — permission denied")
        else:
            print(f"  [STOP] {ticket} — no PID recorded")
        agent["status"] = "stopped"
        stopped += 1
        # Close the cmux workspace for this agent (fallback: try tmux for legacy agents)
        import subprocess
        cmux_ws = agent.get("cmux_workspace")
        if cmux_ws:
            subprocess.run(
                ["cmux", "close-workspace", "--workspace", cmux_ws],
                capture_output=True, timeout=5
            )
        else:
            tmux_win = agent.get("tmux_window", ticket)
            subprocess.run(
                ["tmux", "kill-window", "-t", f"dispatch:{tmux_win}"],
                capture_output=True, timeout=5
            )
    data["total_running"] = sum(1 for a in data["agents"] if a["status"] == "running")
    return data

lj.locked_update(agents_path, _stop)
print(f"\n  Stopped {stopped} agent(s).")
PYEOF
}

cmd_review() {
  echo "═══ Review Queue ═══"

  if [[ ! -f "$REVIEW_QUEUE_JSON" ]]; then
    echo "  No review queue file found."
    echo "  Reviews will appear here as agents complete work."
    return 0
  fi

  python3 << 'PYEOF'
import json, os

review_path = os.path.expanduser("~/.commandboard/review-queue.json")
with open(review_path) as f:
    data = json.load(f)

reviews = data if isinstance(data, list) else data.get("items", [])

if not reviews:
    print("  No items in review queue.")
    raise SystemExit(0)

limit_raw = os.environ.get("DISPATCH_REVIEW_LIMIT", "50")
try:
    limit = int(limit_raw)
except ValueError:
    limit = 50

def clean(value, fallback="—"):
    if value is None:
        return fallback
    text = str(value).strip()
    return text if text else fallback

display_reviews = reviews[:limit] if limit > 0 else reviews

header = f"{'TICKET':<12} {'WORKSPACE':<25} {'PR':<12} {'FILES':<8} {'STATUS':<12}"
print(header)
print("─" * len(header))

for r in display_reviews:
    ticket = clean(r.get("ticket_id"), clean(r.get("title"), "—"))
    ws = clean(r.get("workspace"), "manual")
    pr = clean(r.get("pr_url", r.get("pr_number", "—")))
    if isinstance(pr, int):
        pr = f"#{pr}"
    files = clean(r.get("files_changed"), "—")
    status = clean(r.get("status"), "pending")
    print(f"{ticket:<12} {ws:<25} {pr:<12} {files:<8} {status:<12}")

pending_statuses = {"pending", "pending_review", "review"}
pending = sum(1 for r in reviews if clean(r.get("status"), "pending") in pending_statuses)
remaining = len(reviews) - len(display_reviews)
if remaining > 0:
    print(f"  ... {remaining} more review records hidden. Set DISPATCH_REVIEW_LIMIT=0 to show all.")
print(f"\n  Pending reviews: {pending}/{len(reviews)}")
PYEOF
}

cmd_approve() {
  local ticket_id="$1"
  if [[ -z "$ticket_id" ]]; then
    echo "Usage: dispatch.sh approve TICKET_ID"
    return 1
  fi

  python3 - "$LOCKED_JSON" "$REVIEW_QUEUE_JSON" "$ticket_id" << 'PYEOF'
import json, os, subprocess, sys, importlib.util

spec = importlib.util.spec_from_file_location("locked_json", sys.argv[1])
lj = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lj)

review_path = sys.argv[2]
ticket_id = sys.argv[3]
ws_found = ""

def _approve(data):
    global ws_found
    if data is None:
        return data
    for item in data.get("items", []):
        if item.get("ticket_id") == ticket_id:
            item["status"] = "approved"
            ws_found = item.get("workspace", "")
            print(f"  [APPROVED] {ticket_id}")
            return data
    print(f"  [ERROR] Ticket {ticket_id} not found in review queue")
    return data

lj.locked_update(review_path, _approve)

# Move kanban task to done
if ws_found:
    ws_path = os.path.expanduser(f"~/.commandboard/workspaces/{ws_found}")
    if os.path.isdir(ws_path):
        parts = ticket_id.split("-")
        if len(parts) >= 2:
            task_id = parts[-1].lstrip('0') or '0'
            subprocess.run(["kanban-md", "move", "--dir", ws_path, task_id, "done"],
                          capture_output=True, timeout=10)
            print(f"  Moved task #{task_id} to done in {ws_found}")
PYEOF
}

cmd_reject() {
  local ticket_id="$1"
  local notes="${2:-No notes provided}"
  if [[ -z "$ticket_id" ]]; then
    echo "Usage: dispatch.sh reject TICKET_ID [\"notes\"]"
    return 1
  fi

  python3 - "$LOCKED_JSON" "$REVIEW_QUEUE_JSON" "$ticket_id" "$notes" << 'PYEOF'
import json, os, subprocess, sys, importlib.util

spec = importlib.util.spec_from_file_location("locked_json", sys.argv[1])
lj = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lj)

review_path = sys.argv[2]
ticket_id = sys.argv[3]
notes = sys.argv[4] if len(sys.argv) > 4 else ""
ws_found = ""

def _reject(data):
    global ws_found
    if data is None:
        return data
    for item in data.get("items", []):
        if item.get("ticket_id") == ticket_id:
            item["status"] = "rejected"
            if notes:
                item["rejection_notes"] = notes
            ws_found = item.get("workspace", "")
            print(f"  [REJECTED] {ticket_id} — {notes}")
            return data
    print(f"  [ERROR] Ticket {ticket_id} not found in review queue")
    return data

lj.locked_update(review_path, _reject)

if ws_found:
    ws_path = os.path.expanduser(f"~/.commandboard/workspaces/{ws_found}")
    if os.path.isdir(ws_path):
        parts = ticket_id.split("-")
        if len(parts) >= 2:
            task_id = parts[-1].lstrip('0') or '0'
            subprocess.run(["kanban-md", "move", "--dir", ws_path, task_id, "todo"],
                          capture_output=True, timeout=10)
            print(f"  Moved task #{task_id} back to todo in {ws_found}")
PYEOF
}

usage() {
  cat << 'EOF'
SigmaHQ Dispatch Engine

Usage:
  dispatch.sh all [--engine codex]          — dispatch all auto_dispatch=true queues
  dispatch.sh {workspace} [--engine codex]  — dispatch tasks for specific workspace
  dispatch.sh task {workspace} {id} [--engine codex] — dispatch one specific task now
  dispatch.sh status                        — show running agents with elapsed time
  dispatch.sh stop [ws]                     — stop agents (all or specific workspace)
  dispatch.sh review                        — show review queue summary
  dispatch.sh approve TICKET                — approve reviewed item (moves to done)
  dispatch.sh reject TICKET "msg"           — reject with notes (moves back to todo)

Engines:
  claude (default) — uses `command claude -p` for dispatch
  codex            — uses `codex exec -s danger-full-access` for dispatch
EOF
}

# ── Main ──

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi

  # Parse --engine flag from any position
  local engine="claude"
  local args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --engine=*)
        engine="${1#*=}"
        shift
        ;;
      --engine)
        engine="${2:-claude}"
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    usage
    exit 0
  fi

  local cmd="${args[0]}"

  case "$cmd" in
    all)
      cmd_dispatch_all "$engine"
      ;;
    task)
      cmd_dispatch_task "${args[1]:-}" "${args[2]:-}" "$engine"
      ;;
    status)
      cmd_status
      ;;
    stop)
      cmd_stop "${args[1]:-}"
      ;;
    review)
      cmd_review
      ;;
    approve)
      cmd_approve "${args[1]:-}"
      ;;
    reject)
      cmd_reject "${args[1]:-}" "${args[2]:-}"
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      cmd_dispatch_workspace "$cmd" "$engine"
      ;;
  esac
}

main "$@"
