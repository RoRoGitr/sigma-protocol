#!/usr/bin/env python3
"""
SigmaHQ Agent Scanner — detects ALL running Claude agents.

Merges 3 data sources:
  1. ps aux — finds claude processes with rich CLI metadata
  2. tmux list-panes — maps PIDs to tmux session:window names
  3. active-agents.json — existing dispatch.sh records

Output: updated active-agents.json with unified agent list.

Usage:
  python3 ~/.commandboard/agent-scanner.py
  python3 ~/.commandboard/agent-scanner.py --json   # print result to stdout
"""

import importlib.util
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

DIR = os.path.expanduser("~/.commandboard")
ACTIVE_AGENTS_JSON = os.path.join(DIR, "active-agents.json")
SSS_ACTIVE_AGENTS_JSON = os.path.join(DIR, "sss-active-agents.json")
LOCKED_JSON_PATH = os.path.join(DIR, "lib", "locked_json.py")

# Import locked_json module
spec = importlib.util.spec_from_file_location("locked_json", LOCKED_JSON_PATH)
locked_json = importlib.util.module_from_spec(spec)
spec.loader.exec_module(locked_json)


def parse_ps_agents():
    """Parse ps aux for all running claude processes."""
    agents = {}
    try:
        result = subprocess.run(
            ["ps", "aux"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return agents
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return agents

    for line in result.stdout.splitlines():
        # Match lines where the command contains 'claude' binary (not just any mention)
        if "claude" not in line:
            continue
        # Skip grep itself, this script, and non-claude-binary lines
        if "agent-scanner" in line or "grep" in line:
            continue

        fields = line.split(None, 10)
        if len(fields) < 11:
            continue

        pid_str = fields[1]
        cpu_str = fields[2]
        cmdline = fields[10]

        # Must be an actual claude binary invocation
        if not re.search(r'(?:^|/)claude\b', cmdline):
            continue
        # Skip node/python helper processes that mention claude in path
        if cmdline.startswith("node ") or cmdline.startswith("python"):
            continue

        try:
            pid = int(pid_str)
        except ValueError:
            continue

        try:
            cpu_pct = float(cpu_str)
        except ValueError:
            cpu_pct = 0.0

        agent = {
            "pid": pid,
            "cpu_pct": cpu_pct,
            "agent_name": None,
            "team_name": None,
            "agent_type": None,
            "parent_session_id": None,
            "ticket_id": None,
            "workspace": None,
            "title": None,
            "cmdline": cmdline,
        }

        # Extract --flag VALUE pairs from cmdline
        flag_patterns = {
            "agent_name": r"--agent-name\s+(\S+)",
            "team_name": r"--team-name\s+(\S+)",
            "agent_type": r"--agent-type\s+(\S+)",
            "parent_session_id": r"--parent-session-id\s+(\S+)",
        }
        for key, pattern in flag_patterns.items():
            m = re.search(pattern, cmdline)
            if m:
                agent[key] = m.group(1)

        # Extract ticket ID from prompt text (e.g., "ticket EM-019:" or "ticket JQ-021")
        ticket_match = re.search(r"ticket\s+([A-Z]{2}-\d{3})", cmdline, re.IGNORECASE)
        if ticket_match:
            agent["ticket_id"] = ticket_match.group(1)

        # Extract title from prompt (after ticket ID, grab the next phrase)
        title_match = re.search(
            r"ticket\s+[A-Z]{2}-\d{3}[:\s]+([^.\"]+)",
            cmdline, re.IGNORECASE
        )
        if title_match:
            agent["title"] = title_match.group(1).strip()[:80]

        # Extract workspace from --dir flag
        dir_match = re.search(r'--dir\s+"?([^"]+)"?', cmdline)
        if not dir_match:
            dir_match = re.search(r"--dir\s+(\S+)", cmdline)
        if dir_match:
            agent["workspace"] = dir_match.group(1)

        agents[pid] = agent

    return agents


def parse_tmux_panes():
    """Parse tmux list-panes for PID → session:window mapping."""
    pane_map = {}  # pid -> {session, window}
    try:
        result = subprocess.run(
            ["tmux", "list-panes", "-a", "-F",
             "#{session_name}\t#{window_name}\t#{pane_pid}"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return pane_map
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return pane_map

    for line in result.stdout.strip().splitlines():
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        session_name, window_name, pid_str = parts[0], parts[1], parts[2]
        try:
            pid = int(pid_str)
        except ValueError:
            continue
        pane_map[pid] = {
            "tmux_session": session_name,
            "tmux_window": window_name,
        }

        # Also map child processes — the actual claude process may be a
        # child of the tmux pane's shell. Walk one level of children.
        try:
            child_result = subprocess.run(
                ["pgrep", "-P", pid_str],
                capture_output=True, text=True, timeout=5
            )
            for child_pid_str in child_result.stdout.strip().splitlines():
                try:
                    child_pid = int(child_pid_str)
                    pane_map[child_pid] = {
                        "tmux_session": session_name,
                        "tmux_window": window_name,
                    }
                except ValueError:
                    pass
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass

    return pane_map


def determine_source(agent, tmux_info):
    """Determine how the agent was spawned."""
    if tmux_info and tmux_info.get("tmux_session") == "dispatch":
        return "dispatch"
    if agent.get("team_name"):
        return "team"
    if agent.get("parent_session_id") and not agent.get("team_name"):
        return "subagent"
    return "manual"


def scan():
    """Run full scan and return merged agent data."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # 1. Get live process data
    ps_agents = parse_ps_agents()

    # 2. Get tmux pane mapping
    tmux_panes = parse_tmux_panes()

    # 3. Read existing active-agents.json
    existing = locked_json.locked_read(ACTIVE_AGENTS_JSON)
    if existing is None:
        existing = {"agents": [], "total_running": 0, "total_completed_today": 0}

    existing_agents = existing.get("agents", [])
    existing_by_pid = {}
    existing_synthetic_keys = set()
    for agent in existing_agents:
        pid = agent.get("pid", 0)
        if pid > 0:
            existing_by_pid[pid] = agent
        if agent.get("source") == "sss-orchestration":
            existing_synthetic_keys.add((
                agent.get("pid"),
                agent.get("workspace"),
                agent.get("title"),
                agent.get("completed_at"),
            ))

    # 4. Merge: update existing, add new, mark dead
    merged = []
    seen_pids = set()

    # Process all live PIDs from ps
    for pid, ps_agent in ps_agents.items():
        seen_pids.add(pid)
        tmux_info = tmux_panes.get(pid)
        source = determine_source(ps_agent, tmux_info)

        if pid in existing_by_pid:
            # Update existing agent with live data
            agent = existing_by_pid[pid].copy()
            agent["last_activity"] = now
            agent["cpu_pct"] = ps_agent["cpu_pct"]
            agent["status"] = "running"
            # Update tmux info if available
            if tmux_info:
                agent["tmux_session"] = tmux_info["tmux_session"]
                agent["tmux_window"] = tmux_info["tmux_window"]
            # Fill in any newly discoverable fields
            if ps_agent["agent_name"] and not agent.get("agent_name"):
                agent["agent_name"] = ps_agent["agent_name"]
            if ps_agent["team_name"] and not agent.get("team_name"):
                agent["team_name"] = ps_agent["team_name"]
            if ps_agent["agent_type"] and not agent.get("agent_type"):
                agent["agent_type"] = ps_agent["agent_type"]
            if ps_agent["ticket_id"] and not agent.get("ticket_id"):
                agent["ticket_id"] = ps_agent["ticket_id"]
            if ps_agent["title"] and not agent.get("title"):
                agent["title"] = ps_agent["title"]
            if not agent.get("source"):
                agent["source"] = source
            merged.append(agent)
        else:
            # New agent discovered from process list
            agent = {
                "pid": pid,
                "agent_name": ps_agent["agent_name"],
                "team_name": ps_agent["team_name"],
                "agent_type": ps_agent["agent_type"] or "general-purpose",
                "workspace": ps_agent["workspace"],
                "ticket_id": ps_agent["ticket_id"],
                "title": ps_agent["title"] or ps_agent["agent_name"] or f"claude-{pid}",
                "status": "running",
                "started": now,
                "last_activity": now,
                "cpu_pct": ps_agent["cpu_pct"],
                "source": source,
            }
            if tmux_info:
                agent["tmux_session"] = tmux_info["tmux_session"]
                agent["tmux_window"] = tmux_info["tmux_window"]
            merged.append(agent)

    # Process existing agents whose PIDs are no longer running
    for agent in existing_agents:
        pid = agent.get("pid", 0)
        if pid in seen_pids:
            continue  # already handled above

        if agent.get("status") == "running":
            # Process died — mark as completed
            agent = agent.copy()
            agent["status"] = "completed"
            agent["completed_at"] = now
            merged.append(agent)
        else:
            # Keep completed/stopped/exited agents in history
            merged.append(agent)

    # Merge synthetic SSS orchestration agents so live mode can show activity
    # even when the signal comes from inbox telemetry rather than a visible OS process.
    synthetic = locked_json.locked_read(SSS_ACTIVE_AGENTS_JSON)
    synthetic_keys_in_scan = set()
    if synthetic and isinstance(synthetic.get("agents"), list):
        for agent in synthetic["agents"]:
            pid = agent.get("pid")
            key = (
                agent.get("pid"),
                agent.get("workspace"),
                agent.get("title"),
                agent.get("completed_at"),
            )
            if key in existing_synthetic_keys or key in synthetic_keys_in_scan:
                continue
            synthetic_keys_in_scan.add(key)
            if isinstance(pid, int) and pid not in seen_pids:
                merged.append(agent)

    # 5. Build result
    total_running = sum(1 for a in merged if a.get("status") == "running")
    total_completed = existing.get("total_completed_today", 0)
    # Count newly completed agents
    new_completed = sum(
        1 for a in merged
        if a.get("status") == "completed"
        and a.get("completed_at") == now
        and a.get("pid", 0) in existing_by_pid
        and existing_by_pid[a["pid"]].get("status") == "running"
    )
    total_completed += new_completed

    result = {
        "agents": merged,
        "total_running": total_running,
        "total_completed_today": total_completed,
        "last_scan": now,
    }

    return result


def main():
    result = scan()

    # Write atomically via locked_json
    locked_json.locked_write(ACTIVE_AGENTS_JSON, result)

    if "--json" in sys.argv:
        json.dump(result, sys.stdout, indent=2)
        print()
    else:
        running = result["total_running"]
        total = len(result["agents"])
        completed = result["total_completed_today"]
        print(f"Scan complete: {running} running, {total} total, {completed} completed today")


if __name__ == "__main__":
    main()
