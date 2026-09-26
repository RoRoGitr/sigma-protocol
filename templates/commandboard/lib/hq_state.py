#!/usr/bin/env python3
"""
SigmaHQ v4 state helpers.

Keeps the dashboard shell small by serving compact JSON payloads from live.sh
instead of embedding every task, agent, and review row into dashboard-live.html.
"""

from __future__ import annotations

import glob
import hashlib
import json
import os
import shutil
import subprocess
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

DIR = Path(os.environ.get("SIGMAHQ_HOME", str(Path.home() / ".commandboard"))).expanduser()
WORKSPACES_DIR = DIR / "workspaces"
ACTIVE_AGENTS = DIR / "active-agents.json"
REVIEW_QUEUE = DIR / "review-queue.json"
STATS = DIR / "stats.json"
STATS_EVENTS = DIR / "stats-events.jsonl"
UI_SETTINGS = DIR / "ui-settings.json"
THEME_FILE = DIR / "theme.txt"
STATE_ARCHIVE_DIR = DIR / "archive" / "state"

PRIORITY_XP = {
    "critical": 175,
    "high": 125,
    "medium": 75,
    "low": 40,
}

RANKS = [
    ("S", 20000, "Shadow Monarch"),
    ("A", 12000, "Elite Operator"),
    ("B", 7000, "Senior Hunter"),
    ("C", 3500, "Hunter"),
    ("D", 1500, "Apprentice"),
    ("E", 0, "Beginner"),
]

DEFAULT_THEME = "tokyo-night"
THEME_IDS = {
    "tokyo-night",
    "github-dark",
    "catppuccin",
    "dracula",
    "nord",
    "one-dark",
    "solo-leveling",
    "recording-high-contrast",
}


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_json(path: Path, default: Any) -> Any:
    try:
        with path.open("r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return default


def save_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)


def task_date(task: Dict[str, Any]) -> str:
    value = task.get("completed") or task.get("completed_at") or task.get("updated") or task.get("created") or ""
    return str(value)[:10] if value else ""


def parse_dt(value: Any) -> datetime:
    if not value:
        return datetime.fromtimestamp(0, timezone.utc)
    try:
        text = str(value).replace("Z", "+00:00")
        dt = datetime.fromisoformat(text)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except ValueError:
        return datetime.fromtimestamp(0, timezone.utc)


def stable_hash(parts: Iterable[Any]) -> str:
    raw = "|".join("" if p is None else str(p) for p in parts)
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()[:16]


def workspace_configs(include_archive: bool = True) -> List[Tuple[str, Path]]:
    configs = []
    for config in sorted(WORKSPACES_DIR.glob("**/config.yml")):
        rel = config.parent.relative_to(WORKSPACES_DIR).as_posix()
        if not include_archive and rel.startswith("archive/"):
            continue
        configs.append((rel, config.parent))
    return configs


def scan_workspace_tasks(ws_path: Path) -> List[Dict[str, Any]]:
    try:
        result = subprocess.run(
            ["kanban-md", "list", "--dir", str(ws_path), "--json"],
            capture_output=True,
            text=True,
            timeout=12,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return []
    if result.returncode != 0 or not result.stdout.strip():
        return []
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return []
    tasks = data.get("tasks", data) if isinstance(data, dict) else data
    return tasks if isinstance(tasks, list) else []


def scan_workspaces(include_archive: bool = False) -> Dict[str, List[Dict[str, Any]]]:
    workspaces: Dict[str, List[Dict[str, Any]]] = {}
    for name, path in workspace_configs(include_archive=include_archive):
        workspaces[name] = scan_workspace_tasks(path)
    return workspaces


def load_stats_events() -> Dict[str, Dict[str, Any]]:
    events: Dict[str, Dict[str, Any]] = {}
    if not STATS_EVENTS.exists():
        return events
    with STATS_EVENTS.open("r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            key = event.get("dedupe_key") or event.get("event_id")
            if key:
                events[str(key)] = event
    return events


def append_stats_events(events: List[Dict[str, Any]]) -> None:
    if not events:
        return
    STATS_EVENTS.parent.mkdir(parents=True, exist_ok=True)
    with STATS_EVENTS.open("a") as f:
        for event in events:
            f.write(json.dumps(event, sort_keys=True) + "\n")


def event_for_done_task(workspace: str, task: Dict[str, Any]) -> Dict[str, Any]:
    task_id = task.get("id")
    completed_at = task.get("completed") or task.get("completed_at") or task.get("updated") or now_iso()
    priority = str(task.get("priority") or "medium").lower()
    xp = PRIORITY_XP.get(priority, PRIORITY_XP["medium"])
    dedupe_key = f"task-done:{workspace}:{task_id}:{completed_at}"
    return {
        "event_id": stable_hash([dedupe_key]),
        "dedupe_key": dedupe_key,
        "type": "task.done",
        "source": "workspace-scan",
        "workspace": workspace,
        "task_id": task_id,
        "task_title": task.get("title") or "Untitled task",
        "priority": priority,
        "completed_at": completed_at,
        "xp_awarded": xp,
    }


def rebuild_stats_from_events(events: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
    ordered = sorted(events.values(), key=lambda e: str(e.get("completed_at") or e.get("timestamp") or ""))
    total_xp = sum(int(e.get("xp_awarded") or 0) for e in ordered)
    daily = Counter()
    workspace_xp = Counter()
    tasks_completed = 0
    for event in ordered:
        if event.get("type") != "task.done":
            continue
        tasks_completed += 1
        date_key = str(event.get("completed_at") or "")[:10]
        if date_key:
            daily[date_key] += 1
        workspace_xp[str(event.get("workspace") or "unknown")] += int(event.get("xp_awarded") or 0)

    level = max(1, total_xp // 500 + 1)
    xp = total_xp % 500
    xp_next = 500
    rank, rank_title = next((r, title) for r, threshold, title in RANKS if total_xp >= threshold)

    sorted_days = sorted(daily.keys())
    current_streak = 0
    longest_streak = 0
    previous = None
    for day in sorted_days:
        try:
            current = datetime.fromisoformat(day).date()
        except ValueError:
            continue
        if previous is not None and (current - previous).days == 1:
            current_streak += 1
        else:
            current_streak = 1
        longest_streak = max(longest_streak, current_streak)
        previous = current

    last_active = sorted_days[-1] if sorted_days else None
    return {
        "total_xp": total_xp,
        "totalXp": total_xp,
        "xp": xp,
        "xp_next": xp_next,
        "xpNext": xp_next,
        "level": level,
        "rank": rank,
        "rank_title": rank_title,
        "rankTitle": rank_title,
        "tasks_completed": tasks_completed,
        "tasksCompleted": tasks_completed,
        "current_streak": current_streak,
        "streak": current_streak,
        "longest_streak": longest_streak,
        "last_active_date": last_active,
        "daily_completions": dict(sorted(daily.items())),
        "workspace_xp": dict(workspace_xp.most_common()),
        "updated_at": now_iso(),
    }


def sync_stats(workspaces: Optional[Dict[str, List[Dict[str, Any]]]] = None) -> Dict[str, Any]:
    workspaces = workspaces if workspaces is not None else scan_workspaces(include_archive=False)
    events = load_stats_events()
    new_events = []
    for workspace, tasks in workspaces.items():
        for task in tasks:
            if task.get("status") != "done":
                continue
            event = event_for_done_task(workspace, task)
            if event["dedupe_key"] not in events:
                events[event["dedupe_key"]] = event
                new_events.append(event)
    append_stats_events(new_events)
    stats = rebuild_stats_from_events(events)
    save_json(STATS, stats)
    return stats


def load_theme() -> str:
    settings = load_json(UI_SETTINGS, {})
    theme = settings.get("theme")
    if isinstance(theme, str) and theme in THEME_IDS:
        return theme
    try:
        theme = THEME_FILE.read_text().strip()
    except OSError:
        theme = DEFAULT_THEME
    return theme if theme in THEME_IDS else DEFAULT_THEME


def save_theme(theme: str) -> Dict[str, Any]:
    if theme not in THEME_IDS:
        raise ValueError("unknown theme")
    settings = load_json(UI_SETTINGS, {})
    settings["theme"] = theme
    settings["updated_at"] = now_iso()
    save_json(UI_SETTINGS, settings)
    THEME_FILE.write_text(theme + "\n")
    return settings


def load_ui_settings() -> Dict[str, Any]:
    settings = load_json(UI_SETTINGS, {})
    settings.setdefault("theme", load_theme())
    settings.setdefault("sidebar", {
        "width": 280,
        "sections": {},
        "pinned": ["personal"],
        "recent": [],
    })
    return settings


def save_ui_settings(settings: Dict[str, Any]) -> Dict[str, Any]:
    settings["updated_at"] = now_iso()
    save_json(UI_SETTINGS, settings)
    if isinstance(settings.get("theme"), str) and settings["theme"] in THEME_IDS:
        THEME_FILE.write_text(settings["theme"] + "\n")
    return settings


def agent_sort_key(agent: Dict[str, Any]) -> datetime:
    return parse_dt(agent.get("last_activity") or agent.get("completed_at") or agent.get("started"))


def valid_agent_identity(agent: Dict[str, Any]) -> Tuple[Any, ...]:
    return (
        agent.get("source"),
        agent.get("pid"),
        agent.get("workspace"),
        agent.get("ticket_id"),
        agent.get("title"),
        agent.get("completed_at"),
    )


def compact_active_agents(history_limit: int = 500) -> Dict[str, Any]:
    data = load_json(ACTIVE_AGENTS, {"agents": [], "total_running": 0, "total_completed_today": 0})
    agents = data.get("agents", []) if isinstance(data, dict) else []
    seen = set()
    unique = []
    for agent in sorted(agents, key=agent_sort_key, reverse=True):
        key = valid_agent_identity(agent)
        if key in seen:
            continue
        seen.add(key)
        unique.append(agent)

    running = [a for a in unique if a.get("status") == "running"]
    history = [a for a in unique if a.get("status") != "running"]
    kept = running + history[:history_limit]
    today = datetime.now(timezone.utc).date().isoformat()
    result = {
        "agents": kept,
        "total_running": len(running),
        "total_completed_today": sum(
            1 for a in kept
            if a.get("status") == "completed" and str(a.get("completed_at") or "").startswith(today)
        ),
        "last_scan": data.get("last_scan") or now_iso(),
        "compacted_at": now_iso(),
        "compacted_from": len(agents),
        "history_limit": history_limit,
    }
    save_json(ACTIVE_AGENTS, result)
    return result


def valid_review_item(item: Dict[str, Any]) -> bool:
    return bool(item.get("ticket_id") and item.get("workspace"))


def review_key(item: Dict[str, Any]) -> Tuple[Any, ...]:
    return (
        item.get("ticket_id"),
        item.get("workspace"),
        item.get("title"),
        item.get("completed_at"),
        item.get("status"),
    )


def compact_review_queue(history_limit: int = 1000) -> Dict[str, Any]:
    data = load_json(REVIEW_QUEUE, {"items": []})
    items = data.get("items", []) if isinstance(data, dict) else []
    invalid = [i for i in items if not valid_review_item(i)]
    valid = [i for i in items if valid_review_item(i)]

    if invalid:
        STATE_ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
        archive_path = STATE_ARCHIVE_DIR / f"review-queue-invalid-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.json"
        save_json(archive_path, {"items": invalid, "archived_at": now_iso(), "reason": "missing ticket_id or workspace"})

    seen = set()
    unique = []
    for item in sorted(valid, key=lambda i: parse_dt(i.get("completed_at")), reverse=True):
        key = review_key(item)
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)

    pending = [i for i in unique if i.get("status") == "pending_review"]
    closed = [i for i in unique if i.get("status") != "pending_review"]
    kept = pending + closed[:history_limit]
    result = {
        "items": kept,
        "compacted_at": now_iso(),
        "compacted_from": len(items),
        "invalid_archived": len(invalid),
        "history_limit": history_limit,
    }
    save_json(REVIEW_QUEUE, result)
    return result


def compact_runtime_state() -> Dict[str, Any]:
    agents = compact_active_agents()
    reviews = compact_review_queue()
    return {
        "agents": {
            "before": agents.get("compacted_from"),
            "after": len(agents.get("agents", [])),
        },
        "reviews": {
            "before": reviews.get("compacted_from"),
            "after": len(reviews.get("items", [])),
            "invalid_archived": reviews.get("invalid_archived"),
        },
        "compacted_at": now_iso(),
    }


def quarantine_tmp_files() -> Dict[str, Any]:
    files = sorted(DIR.glob("tmp*.tmp"))
    if not files:
        return {"moved": 0, "bytes": 0, "destination": None}
    dest = STATE_ARCHIVE_DIR / f"tmp-quarantine-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"
    dest.mkdir(parents=True, exist_ok=True)
    total = 0
    moved = 0
    for path in files:
        try:
            total += path.stat().st_size
            shutil.move(str(path), str(dest / path.name))
            moved += 1
        except OSError:
            continue
    return {"moved": moved, "bytes": total, "destination": str(dest)}


def build_summary(workspaces: Optional[Dict[str, List[Dict[str, Any]]]] = None) -> Dict[str, Any]:
    workspaces = workspaces if workspaces is not None else scan_workspaces(include_archive=False)
    agents = load_json(ACTIVE_AGENTS, {"agents": [], "total_running": 0})
    reviews = load_json(REVIEW_QUEUE, {"items": []})
    stats = load_json(STATS, {})
    total_tasks = sum(len(tasks) for tasks in workspaces.values())
    done_tasks = sum(1 for tasks in workspaces.values() for task in tasks if task.get("status") == "done")
    active_tasks = total_tasks - done_tasks
    doing = sum(1 for tasks in workspaces.values() for task in tasks if task.get("status") == "doing")
    review_count = len([i for i in reviews.get("items", []) if i.get("status") == "pending_review"])
    return {
        "workspace_count": len(workspaces),
        "total_tasks": total_tasks,
        "done_tasks": done_tasks,
        "completed_tasks": done_tasks,
        "active_tasks": active_tasks,
        "doing_tasks": doing,
        "running_agents": agents.get("total_running", 0),
        "pending_reviews": review_count,
        "level": stats.get("level", 1),
        "rank": stats.get("rank", "E"),
        "updated_at": now_iso(),
        "generated_at": now_iso(),
    }


def _is_prd_shaped(task: Dict[str, Any]) -> bool:
    """Return True if the task dict has all PRD-required keys: prd_id, goal, mission."""
    return all(k in task for k in ("prd_id", "goal", "mission"))


def compute_dispatch_prompts(
    task_dict: Dict[str, Any],
    workspace: str = "",
    prd_doc: Optional[Any] = None,
) -> Dict[str, str]:
    """Return a 3-key dispatch_prompts dict for a kanban task.

    Branches on PRD shape:
    - PRD-shaped task (has prd_id + goal + mission): calls the 3 CLI emitters
      directly as Python imports (no subprocess — stays fast).
    - Plain kanban task: calls emit_kanban_prompts() from D3.

    Per-task emitter exceptions are caught and returned as fallback strings so
    one bad task never breaks the full sync.

    Args:
        task_dict: A kanban task dict (from kanban-md --json).
        workspace: Workspace name — passed through to the kanban emitter.
        prd_doc:   Optional pre-parsed PRD dict. When provided and the task is
                   PRD-shaped, it is used directly (avoids re-reading disk).

    Returns:
        Dict with exactly three keys: claude, codex, droid.
    """
    if _is_prd_shaped(task_dict) or isinstance(prd_doc, dict):
        prd = prd_doc if isinstance(prd_doc, dict) else task_dict
        return _emit_prd_prompts(prd)

    return _emit_kanban_prompts(task_dict, workspace)


def _resolve_emitters_dir() -> Optional[Path]:
    """Find the scripts/emitters/ directory, handling repo, standalone, and co-installed contexts.

    Search order (first match wins):
      1. Repo-relative: ../../../scripts/emitters/ from this file (works in the sigma-protocol repo).
      2. SIGMAHQ_HOME env var: $SIGMAHQ_HOME/scripts/emitters/ (set by standalone install.sh in shell rc).
      3. Sibling-relative: <dir-of-hq_state.py>/../scripts/emitters/ (works for any install where
         hq_state.py is in <root>/lib/ and emitters are in <root>/scripts/emitters/ — covers
         both the repo's `templates/commandboard/` layout and the standalone install at
         `~/.sigmahq/` where lib/ and scripts/ live as siblings).
      4. Standalone install convention: ~/.sigmahq/scripts/emitters/.
      5. Co-installed sigma-protocol fallbacks (legacy): known checkout paths.

    Returns the emitters directory Path if found, else None.
    """
    def _is_emitters_dir(p: Path) -> bool:
        return p.is_dir() and (p / "emit_kanban_prompt.py").exists()

    # 1. Repo-relative path (4 parents up = repo root when in templates/commandboard/lib/)
    candidate = Path(__file__).parent.parent.parent.parent / "scripts" / "emitters"
    if _is_emitters_dir(candidate):
        return candidate

    # 2. SIGMAHQ_HOME env var (D5 install.sh exports this in shell rc)
    sigmahq_home = os.environ.get("SIGMAHQ_HOME")
    if sigmahq_home:
        candidate = Path(sigmahq_home).expanduser() / "scripts" / "emitters"
        if _is_emitters_dir(candidate):
            return candidate

    # 3. Sibling-relative: hq_state.py in lib/ → ../scripts/emitters/
    # This catches the standalone-install layout where ~/.sigmahq/lib/hq_state.py
    # and ~/.sigmahq/scripts/emitters/ live as siblings of a common parent.
    candidate = Path(__file__).resolve().parent.parent / "scripts" / "emitters"
    if _is_emitters_dir(candidate):
        return candidate

    # 4. Standalone install convention from D5's install.sh
    home = Path.home()
    candidate = home / ".sigmahq" / "scripts" / "emitters"
    if _is_emitters_dir(candidate):
        return candidate

    # 5. Co-installed sigma-protocol checkout fallbacks (legacy)
    search_roots = [
        home / "sigma-protocol-v2",
        home / "sigma-protocol",
        home / "projects" / "sigma-protocol",
        home / "code" / "sigma-protocol",
    ]
    for root in search_roots:
        candidate = root / "scripts" / "emitters"
        if _is_emitters_dir(candidate):
            return candidate

    return None


def _ensure_emitters_on_path() -> bool:
    """Add the emitters directory to sys.path. Returns True if found."""
    import sys
    emitters_dir = _resolve_emitters_dir()
    if emitters_dir is None:
        return False
    emitters_str = str(emitters_dir)
    if emitters_str not in sys.path:
        sys.path.insert(0, emitters_str)
    return True


def _emit_prd_prompts(prd: Dict[str, Any]) -> Dict[str, str]:
    """Call all 3 PRD emitters and return the dispatch_prompts dict.

    Imports are deferred inside this function so that the module itself has no
    hard dependency on the emitters at import time. Each emitter is called once
    per PRD-shaped task; exceptions are caught and returned as fallback strings.
    """
    import importlib

    if not _ensure_emitters_on_path():
        return {
            "claude": "Error generating claude prompt: emitters directory not found",
            "codex": "Error generating codex prompt: emitters directory not found",
            "droid": "Error generating droid prompt: emitters directory not found",
        }

    result: Dict[str, str] = {}

    for cli_key, module_name, fn_name in (
        ("claude", "emit_claude_bundle", "generate"),
        ("codex", "emit_codex_bundle", "generate"),
        ("droid", "emit_droid_mission", "generate"),
    ):
        try:
            mod = importlib.import_module(module_name)
            fn = getattr(mod, fn_name)
            result[cli_key] = fn(prd)
        except Exception as exc:  # noqa: BLE001
            result[cli_key] = f"Error generating {cli_key} prompt: {exc}"

    return result


def _emit_kanban_prompts(task: Dict[str, Any], workspace: str) -> Dict[str, str]:
    """Call D3's emit_kanban_prompts and return its output.

    Imports are deferred to avoid a hard circular dependency at module load time.
    """
    import importlib

    if not _ensure_emitters_on_path():
        title = task.get("title") or "Untitled task"
        msg = "Error generating prompt: emitters directory not found"
        return {"claude": msg, "codex": msg, "droid": f"# Mission: {title}\n{msg}"}

    try:
        mod = importlib.import_module("emit_kanban_prompt")
        return mod.emit_kanban_prompts(task, workspace)
    except Exception as exc:  # noqa: BLE001
        title = task.get("title") or "Untitled task"
        msg = f"Error generating prompt: {exc}"
        return {"claude": msg, "codex": msg, "droid": f"# Mission: {title}\n{msg}"}


def build_leaderboard(workspaces: Optional[Dict[str, List[Dict[str, Any]]]] = None) -> Dict[str, Any]:
    workspaces = workspaces if workspaces is not None else scan_workspaces(include_archive=False)
    stats = load_json(STATS, {})
    agents_data = load_json(ACTIVE_AGENTS, {"agents": []})
    reviews = load_json(REVIEW_QUEUE, {"items": []})

    projects = []
    for workspace, tasks in workspaces.items():
        total = len(tasks)
        done = len([t for t in tasks if t.get("status") == "done"])
        active = total - done
        xp = int((stats.get("workspace_xp") or {}).get(workspace, 0))
        projects.append({
            "workspace": workspace,
            "xp": xp,
            "done": done,
            "total": total,
            "active": active,
            "completion_pct": round((done / total) * 100) if total else 0,
        })
    projects.sort(key=lambda p: (p["xp"], p["done"], p["completion_pct"]), reverse=True)

    agent_scores: Dict[str, Dict[str, Any]] = defaultdict(lambda: {
        "agent": "unknown",
        "score": 0,
        "completed": 0,
        "approved": 0,
        "rejected": 0,
        "running": 0,
    })
    for agent in agents_data.get("agents", []):
        name = agent.get("agent_name") or agent.get("agent_type") or agent.get("source") or "manual"
        row = agent_scores[str(name)]
        row["agent"] = str(name)
        if agent.get("status") == "running":
            row["running"] += 1
            row["score"] += 2
        elif agent.get("status") == "completed" and agent.get("ticket_id"):
            row["completed"] += 1
            row["score"] += 10
    for item in reviews.get("items", []):
        name = item.get("agent_name") or item.get("agent_type") or "reviewed-agent"
        row = agent_scores[str(name)]
        row["agent"] = str(name)
        if item.get("status") == "approved":
            row["approved"] += 1
            row["score"] += 15
        elif item.get("status") == "rejected":
            row["rejected"] += 1
            row["score"] -= 10
    agents = sorted(agent_scores.values(), key=lambda a: a["score"], reverse=True)

    operator = {
        "name": os.environ.get("USER") or os.environ.get("USERNAME") or "Operator",
        "xp": stats.get("totalXp", stats.get("total_xp", 0)),
        "level": stats.get("level", 1),
        "rank": stats.get("rank", "E"),
        "rank_title": stats.get("rankTitle", stats.get("rank_title", "Beginner")),
        "tasks_completed": stats.get("tasksCompleted", stats.get("tasks_completed", 0)),
        "streak": stats.get("streak", stats.get("current_streak", 0)),
    }
    # Build a flat tasks list with dispatch_prompts attached.
    enriched_tasks: List[Dict[str, Any]] = []
    for ws_name, tasks in workspaces.items():
        for task in tasks:
            enriched = dict(task)
            enriched["_workspace"] = ws_name
            enriched["dispatch_prompts"] = compute_dispatch_prompts(enriched, workspace=ws_name)
            enriched_tasks.append(enriched)

    return {
        "operator": [operator],
        "projects": projects[:50],
        "agents": agents[:50],
        "tasks": enriched_tasks,
        "updated_at": now_iso(),
    }
