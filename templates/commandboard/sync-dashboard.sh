#!/bin/bash
# SigmaHQ Dashboard Sync
# Scans workspaces, generates briefing.json, and builds dashboard-live.html.
#
# Usage: sync-dashboard.sh [--no-open] [--quiet]
#
# What it does:
# 1. Scans all workspace tasks under ~/.commandboard/workspaces/
# 2. Generates briefing.json with per-project summaries, time blocks, missions, dumps
# 3. Builds dashboard-live.html by injecting briefing data into dashboard.html
# 4. Opens the dashboard (unless --no-open)
#
# Run at session start or via: hq sync

set -euo pipefail

DIR="${SIGMAHQ_HOME:-${CLAUDE_CODE_COMMANDBOARD:-$HOME/.commandboard}}"
export SIGMAHQ_HOME="$DIR"
export CLAUDE_CODE_COMMANDBOARD="${CLAUDE_CODE_COMMANDBOARD:-$DIR}"
BRIEFING="$DIR/briefing.json"
SCHEDULES_DIR="$DIR/schedules"
TODAY=$(date +%Y-%m-%d 2>/dev/null || gdate +%Y-%m-%d 2>/dev/null || echo "$(python3 -c 'import datetime; print(datetime.date.today())')")
NO_OPEN=0
QUIET=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-open) NO_OPEN=1 ;;
        --quiet) QUIET=1 ;;
        --help|-h)
            echo "Usage: sync-dashboard.sh [--no-open] [--quiet]"
            exit 0
            ;;
        *)
            echo "Unknown flag: $1" >&2
            exit 1
            ;;
    esac
    shift
done

[ "$QUIET" -eq 1 ] || echo "Syncing SigmaHQ dashboard for $TODAY..."
if [ "$QUIET" -eq 1 ]; then
    export SIGMAHQ_SYNC_QUIET=1
else
    export SIGMAHQ_SYNC_QUIET=0
fi

# Keep generated runtime files small and XP/rank current before building.
if [ -f "$DIR/state-maintenance.py" ]; then
    PYTHONDONTWRITEBYTECODE=1 python3 "$DIR/state-maintenance.py" --compact --stats >/dev/null 2>&1 || true
fi

# Step 1: Generate briefing.json from workspace tasks
PYTHONDONTWRITEBYTECODE=1 python3 << 'PYEOF'
import subprocess, json, os, glob, re as _re_sync, sys
from datetime import datetime, date

HQ_DIR = os.environ.get("SIGMAHQ_HOME", os.path.expanduser("~/.commandboard"))
sys.path.insert(0, os.path.join(HQ_DIR, "lib"))
try:
    from hq_state import build_leaderboard, sync_stats
except Exception:
    build_leaderboard = sync_stats = None

def scan_workspace_tasks(ws_path):
    result = subprocess.run(
        ["kanban-md", "list", "--dir", ws_path, "--json"],
        capture_output=True, text=True
    )
    if result.returncode == 0 and result.stdout.strip():
        try:
            data = json.loads(result.stdout.strip())
            if isinstance(data, list):
                return data
            if isinstance(data, dict):
                for key in ("tasks", "items", "data"):
                    if isinstance(data.get(key), list):
                        return data[key]
            return []
        except json.JSONDecodeError:
            return []
    return []

def scan_session_logs(ws_path):
    sessions_dir = os.path.join(ws_path, "sessions")
    if not os.path.isdir(sessions_dir):
        return {"count": 0, "latest": None, "sessions": []}
    logs = sorted(glob.glob(os.path.join(sessions_dir, "session-*.md")), reverse=True)
    sessions_list = []
    for log_path in logs[:5]:
        filename = os.path.basename(log_path)
        date_part = filename.replace("session-", "").replace(".md", "")
        summary = ""
        files_count = 0
        try:
            with open(log_path, "r") as lf:
                content = lf.read()
            m = _re_sync.search(r'## Summary\s*\n(.+?)(\n##|\Z)', content, _re_sync.DOTALL)
            if m:
                summary = m.group(1).strip()[:200]
            rows = _re_sync.findall(r'^\|\s*(?!File\b|\-)', content, _re_sync.MULTILINE)
            files_count = max(0, len(rows) - 1)
        except Exception:
            pass
        sessions_list.append({
            "file": filename,
            "path": log_path,
            "date": date_part,
            "summary": summary,
            "files_count": files_count
        })
    return {
        "count": len(logs),
        "latest": sessions_list[0] if sessions_list else None,
        "sessions": sessions_list
    }

def format12(h, m=0):
    suffix = 'PM' if h >= 12 else 'AM'
    h12 = h % 12 or 12
    return f"{h12}:{m:02d} {suffix}" if m else f"{h12} {suffix}"

ws_dir = os.path.join(HQ_DIR, "workspaces")
today_str = date.today().isoformat()
hour = datetime.now().hour

# Greeting
if hour < 12:
    greeting = "Good morning"
elif hour < 17:
    greeting = "Good afternoon"
else:
    greeting = "Good evening"

# Scan all workspaces — recursive to handle flat (workspaces/{project}/)
# and category layouts (workspaces/{category}/{project}/)
all_workspaces = {}
workspace_sessions = {}
for config_path in sorted(glob.glob(os.path.join(ws_dir, "**/config.yml"), recursive=True)):
    ws_path_item = os.path.dirname(config_path)
    rel = os.path.relpath(ws_path_item, ws_dir)
    ws_name = rel if os.sep in rel else os.path.basename(ws_path_item)
    all_workspaces[ws_name] = scan_workspace_tasks(ws_path_item)
    workspace_sessions[ws_name] = scan_session_logs(ws_path_item)

# Generate per-project summaries
project_briefs = {}
total_tasks = 0
total_done = 0
total_critical = 0
total_doing = 0
all_active = []

for name, tasks in all_workspaces.items():
    total = len(tasks)
    if total == 0:
        continue

    done = len([t for t in tasks if t.get("status") == "done"])
    doing = len([t for t in tasks if t.get("status") == "doing"])
    review = len([t for t in tasks if t.get("status") == "review"])
    critical = len([t for t in tasks if t.get("priority") == "critical" and t.get("status") != "done"])
    high = len([t for t in tasks if t.get("priority") == "high" and t.get("status") != "done"])
    remaining = total - done
    pct = round((done / total) * 100)

    total_tasks += total
    total_done += done
    total_critical += critical
    total_doing += doing

    parts = []
    parts.append(f"{pct}% complete ({done}/{total}).")

    if doing > 0 or review > 0:
        active_parts = []
        if doing > 0:
            active_parts.append(f"{doing} in progress")
        if review > 0:
            active_parts.append(f"{review} in review")
        parts.append(f"Currently {', '.join(active_parts)}.")

    if critical > 0:
        crit_tasks = [t["title"] for t in tasks if t.get("priority") == "critical" and t.get("status") != "done"][:2]
        parts.append(f"{critical} critical: {', '.join(crit_tasks)}.")
    elif high > 0:
        top = next((t for t in tasks if t.get("priority") == "high" and t.get("status") != "done"), None)
        if top:
            parts.append(f"Top priority: {top['title']}.")

    active = [t for t in tasks if t.get("status") != "done"]
    prio_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    active.sort(key=lambda t: prio_order.get(t.get("priority", "low"), 99))
    top_tasks = [t["title"] for t in active[:3]]

    for t in active:
        t["_workspace"] = name
    all_active.extend(active)

    project_briefs[name] = {
        "summary": " ".join(parts),
        "top_tasks": top_tasks,
        "pct": pct,
        "active": remaining,
        "critical": critical,
        "last_session": workspace_sessions.get(name, {}).get("latest"),
        "session_count": workspace_sessions.get(name, {}).get("count", 0)
    }

# Generate time blocks from top priorities
prio_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
all_active.sort(key=lambda t: prio_order.get(t.get("priority", "low"), 99))

time_blocks = []
hour_cursor = 9
block_count = 0

for t in all_active[:6]:
    if hour_cursor >= 18:
        break

    duration = 2 if t.get("priority") in ("critical", "high") else 1
    end_hour = min(hour_cursor + duration, 18)
    block_type = "review" if t.get("status") == "review" else "deep"

    ws = t.get("_workspace", "")
    # Auto-generate prefix from workspace name (2-letter abbreviation)
    parts = ws.replace("/", " ").replace("-", " ").split()
    if len(parts) >= 2:
        prefix = (parts[-2][0] + parts[-1][0]).upper()
    elif parts:
        prefix = parts[0][:2].upper()
    else:
        prefix = "XX"
    tid = str(t.get("id", 0)).zfill(3)
    ticket_id = f"{prefix}-{tid}"

    time_blocks.append({
        "date": today_str,
        "start": format12(hour_cursor, 0),
        "end": format12(end_hour, 0),
        "title": t["title"][:50],
        "type": block_type,
        "workspace": ws,
        "ticketId": ticket_id,
        "source": "priority"
    })

    hour_cursor = end_hour
    block_count += 1

    if block_count % 2 == 0 and hour_cursor < 17:
        time_blocks.append({
            "date": today_str,
            "start": format12(hour_cursor, 0),
            "end": format12(hour_cursor, 30),
            "title": "Break",
            "type": "break",
            "source": "system"
        })
        hour_cursor = hour_cursor + 1

if not time_blocks:
    time_blocks = [
        {"date": today_str, "start": format12(9, 0), "end": format12(11, 0), "title": "Deep Work", "type": "deep", "source": "default"},
        {"date": today_str, "start": format12(11, 0), "end": format12(11, 30), "title": "Break", "type": "break", "source": "default"},
        {"date": today_str, "start": format12(11, 30), "end": format12(13, 0), "title": "Project Review", "type": "review", "source": "default"},
        {"date": today_str, "start": format12(13, 0), "end": format12(14, 0), "title": "Lunch", "type": "break", "source": "default"},
        {"date": today_str, "start": format12(14, 0), "end": format12(16, 0), "title": "Deep Work", "type": "deep", "source": "default"},
        {"date": today_str, "start": format12(16, 0), "end": format12(17, 0), "title": "Admin & Planning", "type": "admin", "source": "default"},
    ]

# Load dispatch data
agent_data = {"agents": [], "total_running": 0, "total_completed_today": 0}
review_data = {"items": []}

agent_path = os.path.join(HQ_DIR, "active-agents.json")
review_path = os.path.join(HQ_DIR, "review-queue.json")

if os.path.exists(agent_path):
    try:
        with open(agent_path) as f:
            agent_data = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass

if os.path.exists(review_path):
    try:
        with open(review_path) as f:
            review_data = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass

running_agents = len([a for a in agent_data.get("agents", []) if a.get("status") == "running"])
pending_reviews = len([i for i in review_data.get("items", []) if i.get("status") == "pending_review"])

# Overall summary
overall_parts = []
remaining = total_tasks - total_done
overall_parts.append(f"{greeting}. You have {remaining} active tasks across {len(project_briefs)} projects.")
if total_doing > 0:
    overall_parts.append(f"{total_doing} currently in progress.")
if total_critical > 0:
    overall_parts.append(f"{total_critical} critical items need attention today.")

sorted_projects = sorted(project_briefs.items(), key=lambda x: x[1]["active"], reverse=True)
if sorted_projects:
    top_names = [f"{name} ({info['active']})" for name, info in sorted_projects[:3]]
    overall_parts.append(f"Focus areas: {', '.join(top_names)}.")

briefing = {
    "date": today_str,
    "greeting": greeting,
    "overall_summary": " ".join(overall_parts),
    "projects": project_briefs,
    "time_blocks": time_blocks,
    "dispatch": {
        "running_agents": running_agents,
        "pending_reviews": pending_reviews,
        "total_completed_today": agent_data.get("total_completed_today", 0),
        "agents": agent_data.get("agents", []),
        "review_items": review_data.get("items", [])
    },
    "session_logs": workspace_sessions
}

def aggregate_missions():
    """Scan SigmaHQ missions and return a missions[] array for briefing.json."""
    missions_dir = os.path.join(HQ_DIR, "missions")
    results = []
    for mission_json in sorted(glob.glob(os.path.join(missions_dir, "*/mission.json"))):
        slug = os.path.basename(os.path.dirname(mission_json))
        if slug in ("_schema", "archive", "active"):
            continue
        try:
            with open(mission_json) as mf:
                m = json.load(mf)
        except (json.JSONDecodeError, IOError):
            continue
        if m.get("status") not in ("active", "paused"):
            continue

        machine_checks = m.get("machine_checks", [])
        total_mc = len(machine_checks)
        pass_or_latched = sum(
            1 for c in machine_checks
            if c.get("latched_pass") or c.get("last_result") == "pass"
        )
        soft_criteria = m.get("soft_criteria", [])
        total_sc = len(soft_criteria)
        soft_yes = sum(1 for c in soft_criteria if c.get("last_answer") == "yes")

        if (total_mc + total_sc) > 0:
            progress_pct = round(((pass_or_latched + soft_yes) / (total_mc + total_sc)) * 100)
        else:
            progress_pct = 0

        deadline = m.get("deadline")
        days_to_deadline = None
        if deadline:
            try:
                d = date.fromisoformat(deadline)
                days_to_deadline = (d - date.today()).days
            except (ValueError, TypeError):
                pass

        budget = m.get("budget", {})
        budget_usd_remaining = budget.get("usd") if budget else None

        ledger_path = os.path.join(os.path.dirname(mission_json), m.get("ledger_path", "ledger.jsonl"))
        last_ledger_entry = None
        if os.path.exists(ledger_path):
            try:
                with open(ledger_path) as lf:
                    lines = [l.strip() for l in lf if l.strip()]
                if lines:
                    last_line = json.loads(lines[-1])
                    last_ledger_entry = last_line.get("ts")
            except (json.JSONDecodeError, IOError):
                pass

        results.append({
            "slug": slug,
            "id": m.get("id", slug),
            "title": m.get("title", ""),
            "workspace": m.get("workspace", ""),
            "status": m.get("status", ""),
            "progress_pct": progress_pct,
            "machine_checks_passing": f"{pass_or_latched}/{total_mc}",
            "soft_criteria_answered": f"{soft_yes}/{total_sc}",
            "deadline": deadline,
            "days_to_deadline": days_to_deadline,
            "budget_usd_remaining": budget_usd_remaining,
            "last_ledger_entry": last_ledger_entry
        })
    return results

def aggregate_dumps():
    """Scan SigmaHQ dumps for unprocessed brain dumps.

    Returns a list of dicts (filename, date, size_bytes, age_days, preview, status)
    sorted oldest-first. Excludes .gitkeep and README files. Does not recurse.
    Processed dumps live under archive/dumps/ and are excluded.
    """
    dumps_dir = os.path.join(HQ_DIR, "dumps")
    if not os.path.isdir(dumps_dir):
        return []
    results = []
    today = date.today()
    for dump_path in sorted(glob.glob(os.path.join(dumps_dir, "*.md"))):
        filename = os.path.basename(dump_path)
        if filename.startswith(".") or filename.lower() in ("readme.md",):
            continue
        try:
            size_bytes = os.path.getsize(dump_path)
        except OSError:
            size_bytes = 0
        dump_date_str = None
        dump_date_obj = None
        m = _re_sync.match(r'^(\d{4}-\d{2}-\d{2})', filename)
        if m:
            dump_date_str = m.group(1)
            try:
                dump_date_obj = date.fromisoformat(dump_date_str)
            except ValueError:
                dump_date_obj = None
        if dump_date_obj is None:
            try:
                mtime = datetime.fromtimestamp(os.path.getmtime(dump_path))
                dump_date_obj = mtime.date()
                dump_date_str = dump_date_obj.isoformat()
            except OSError:
                dump_date_str = None
        age_days = (today - dump_date_obj).days if dump_date_obj else None
        preview = ""
        try:
            with open(dump_path, "r", encoding="utf-8", errors="replace") as df:
                preview = df.read(400).strip().replace("\n", " ")[:100]
        except (OSError, UnicodeError):
            preview = ""
        results.append({
            "filename": filename,
            "date": dump_date_str,
            "size_bytes": size_bytes,
            "age_days": age_days,
            "preview": preview,
            "status": "unprocessed"
        })
    results.sort(key=lambda d: (0 if d.get("age_days") is not None else 1, -(d.get("age_days") or 0)))
    return results

missions_list = aggregate_missions()
dumps_list = aggregate_dumps()
stats = sync_stats(all_workspaces) if sync_stats else {}
leaderboard = build_leaderboard(all_workspaces) if build_leaderboard else {"operator": [], "projects": [], "agents": []}

briefing_path = os.path.join(HQ_DIR, "briefing.json")
briefing["missions"] = missions_list
briefing["dumps"] = dumps_list
briefing["stats"] = stats
briefing["leaderboard"] = leaderboard
# Hoist tasks[] with dispatch_prompts out of leaderboard for top-level access.
# Consumers can read briefing["tasks"][n]["dispatch_prompts"]["claude|codex|droid"].
# Field is additive — old consumers that don't reference tasks[] keep working.
briefing["tasks"] = leaderboard.get("tasks", []) if isinstance(leaderboard, dict) else []
with open(briefing_path, "w") as f:
    json.dump(briefing, f, indent=2)

def ticket_id_for(task):
    ws = task.get("_workspace", "")
    parts = ws.replace("/", " ").replace("-", " ").split()
    if len(parts) >= 2:
        prefix = (parts[-2][0] + parts[-1][0]).upper()
    elif parts:
        prefix = parts[0][:2].upper()
    else:
        prefix = "XX"
    return f"{prefix}-{str(task.get('id', 0)).zfill(3)}"

schedule_dir = os.path.join(HQ_DIR, "schedules")
os.makedirs(schedule_dir, exist_ok=True)
schedule = {
    "date": today_str,
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "executive_summary": briefing["overall_summary"],
    "time_blocks": time_blocks,
    "projects": project_briefs,
    "top_priorities": [
        {
            "id": t.get("id"),
            "ticketId": ticket_id_for(t),
            "title": t.get("title", ""),
            "workspace": t.get("_workspace", ""),
            "priority": t.get("priority", ""),
            "status": t.get("status", ""),
        }
        for t in all_active[:10]
    ],
}

with open(os.path.join(schedule_dir, f"{today_str}.json"), "w") as sf:
    json.dump(schedule, sf, indent=2)

with open(os.path.join(schedule_dir, f"{today_str}.md"), "w") as sf:
    sf.write(f"# SigmaHQ Schedule - {today_str}\n\n")
    sf.write("## Executive Summary\n\n")
    sf.write(schedule["executive_summary"] + "\n\n")
    sf.write("## Time Blocks\n\n")
    for block in time_blocks:
        ticket = f" [{block.get('ticketId')}]" if block.get("ticketId") else ""
        workspace = f" - {block.get('workspace')}" if block.get("workspace") else ""
        sf.write(f"- {block.get('start')} - {block.get('end')}: {block.get('title')}{ticket}{workspace}\n")
    sf.write("\n## Top Priorities\n\n")
    for item in schedule["top_priorities"]:
        sf.write(
            f"- {item.get('ticketId')} {item.get('title')} "
            f"({item.get('workspace')}, {item.get('priority')}, {item.get('status')})\n"
        )

if os.environ.get("SIGMAHQ_SYNC_QUIET") != "1":
    print(f"  Briefing: {len(project_briefs)} projects, {len(time_blocks)} time blocks, "
          f"{running_agents} agents, {pending_reviews} reviews, "
          f"{len(missions_list)} active missions, {len(dumps_list)} unprocessed dumps")
PYEOF

# Step 2: Build dashboard-live.html by injecting briefing.json into dashboard.html template
PYTHONDONTWRITEBYTECODE=1 python3 << 'PYEOF'
import json, os, glob, re as _re, sys

HQ_DIR = os.environ.get("SIGMAHQ_HOME", os.path.expanduser("~/.commandboard"))
sys.path.insert(0, os.path.join(HQ_DIR, "lib"))
try:
    from hq_state import load_ui_settings, sync_stats
except Exception:
    load_ui_settings = sync_stats = None

def scan_workspace_tasks(ws_path):
    import subprocess
    result = subprocess.run(
        ["kanban-md", "list", "--dir", ws_path, "--json"],
        capture_output=True, text=True
    )
    if result.returncode == 0 and result.stdout.strip():
        try:
            return json.loads(result.stdout.strip())
        except json.JSONDecodeError:
            return []
    return []

# Scan all workspaces for the JS data injection
ws_dir = os.path.join(HQ_DIR, "workspaces")
all_workspaces = {}
for config_path in sorted(glob.glob(os.path.join(ws_dir, "**/config.yml"), recursive=True)):
    ws_path_item = os.path.dirname(config_path)
    rel = os.path.relpath(ws_path_item, ws_dir)
    ws_name = rel if os.sep in rel else os.path.basename(ws_path_item)
    all_workspaces[ws_name] = scan_workspace_tasks(ws_path_item)

# Load briefing
briefing = None
briefing_path = os.path.join(HQ_DIR, "briefing.json")
if os.path.exists(briefing_path):
    try:
        with open(briefing_path) as f:
            briefing = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass

# Load stats
stats = {}
stats_path = os.path.join(HQ_DIR, "stats.json")
if os.path.exists(stats_path):
    try:
        with open(stats_path) as f:
            stats = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass
if sync_stats:
    try:
        stats = sync_stats(all_workspaces)
    except Exception:
        pass

# Load theme preference
theme = "tokyo-night"
theme_path = os.path.join(HQ_DIR, "theme.txt")
if os.path.exists(theme_path):
    try:
        with open(theme_path) as f:
            theme = f.read().strip()
    except (IOError, OSError):
        pass
if load_ui_settings:
    try:
        theme = load_ui_settings().get("theme", theme)
    except Exception:
        pass

# Load dispatch data
agent_data = {"agents": [], "total_running": 0, "total_completed_today": 0}
review_data = {"items": []}
dispatch_config = {"global": {}, "queues": []}

for path, key in [
    (os.path.join(HQ_DIR, "active-agents.json"), "agent_data"),
    (os.path.join(HQ_DIR, "review-queue.json"), "review_data"),
    (os.path.join(HQ_DIR, "dispatch.json"), "dispatch_config"),
]:
    if os.path.exists(path):
        try:
            with open(path) as f:
                data = json.load(f)
                if key == "agent_data":
                    agent_data = data
                elif key == "review_data":
                    review_data = data
                elif key == "dispatch_config":
                    dispatch_config = data
        except (json.JSONDecodeError, IOError):
            pass
if isinstance(agent_data.get("agents"), list):
    agent_data["agents"] = agent_data["agents"][:50]
if isinstance(review_data.get("items"), list):
    review_data["items"] = [i for i in review_data["items"] if i.get("status") == "pending_review"][:50]
if briefing and isinstance(briefing, dict):
    briefing = {
        "date": briefing.get("date"),
        "greeting": briefing.get("greeting"),
        "overall_summary": briefing.get("overall_summary"),
        "time_blocks": briefing.get("time_blocks", [])[:8],
        "missions": briefing.get("missions", [])[:20],
        "dumps": briefing.get("dumps", [])[:50],
        "leaderboard": briefing.get("leaderboard", {}),
        "stats": briefing.get("stats", {}),
        # D4: dispatch_prompts per task — kept so dashboard can build DISPATCH_MAP
        "tasks": briefing.get("tasks", []),
    }

# Load brain dumps for JS injection (summary list, no full content)
dumps_data = briefing.get("dumps", []) if briefing else []
# Expand to include title for the JS view
dumps_js = []
for d in dumps_data:
    dumps_js.append({
        "filename": d.get("filename", ""),
        "date": d.get("date", ""),
        "title": d.get("preview", d.get("filename", ""))[:80],
        "themes": [],
        "preview": d.get("preview", ""),
        "size": d.get("size_bytes", 0),
        "age_days": d.get("age_days")
    })

# Read dashboard template
template_path = os.path.join(HQ_DIR, "dashboard.html")
if not os.path.exists(template_path):
    if os.environ.get("SIGMAHQ_SYNC_QUIET") != "1":
        print("  dashboard.html not found — skipping live rebuild")
    exit(0)

with open(template_path, "r") as f:
    template = f.read()

# Inject data
output = template.replace("__WORKSPACES_JSON__", json.dumps(all_workspaces))
output = output.replace("__STATS_JSON__", json.dumps(stats))
output = output.replace("__BRIEFING_JSON__", json.dumps(briefing) if briefing else "null")
output = output.replace("__AGENT_DATA_JSON__", json.dumps(agent_data))
output = output.replace("__REVIEW_DATA_JSON__", json.dumps(review_data))
output = output.replace("__DISPATCH_CONFIG_JSON__", json.dumps(dispatch_config))
output = output.replace("__DUMPS_JSON__", json.dumps(dumps_js))
output = output.replace("__THEME__", json.dumps(theme))

output_path = os.path.join(HQ_DIR, "dashboard-live.html")
with open(output_path, "w") as f:
    f.write(output)

total = sum(len(t) for t in all_workspaces.values())
if os.environ.get("SIGMAHQ_SYNC_QUIET") != "1":
    print(f"  Dashboard built: {len(all_workspaces)} workspaces, {total} tasks")
PYEOF

# Step 3: Open dashboard (unless --no-open)
if [ "$NO_OPEN" -eq 0 ]; then
    LIVE="$DIR/dashboard-live.html"
    if [ -f "$LIVE" ]; then
        open "$LIVE" 2>/dev/null || xdg-open "$LIVE" 2>/dev/null || echo "Open $LIVE in your browser"
    else
        echo "dashboard-live.html not found — run sync again after confirming kanban-md is installed"
    fi
fi

[ "$QUIET" -eq 1 ] || echo "Sync complete."
