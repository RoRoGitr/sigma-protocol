#!/usr/bin/env python3
"""
scripts/morning-debrief.py — morning debrief reader for /ops:overnight morning

Reads:
  - .sigma/overnight/deferred-questions-*.md   (last 24h or --since)
  - .sigma/overnight/run-*.json                (latest run summary)
  - git log since last overnight run start
  - ~/.commandboard/workspaces/products/sigma-protocol/activity.jsonl (kanban changes)

CLI:
  python3 morning-debrief.py [--since=<ISO-timestamp>] [--target-dir=.sigma/overnight] [--format=markdown|json]

Stdlib only — no third-party dependencies.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def _parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """Parse simple YAML-ish frontmatter between --- delimiters using regex only.
    Returns (fields_dict, body_without_frontmatter).
    """
    pattern = r"^---\s*\n(.*?)\n---\s*\n"
    m = re.match(pattern, text, re.DOTALL)
    if not m:
        return {}, text
    raw = m.group(1)
    fields: dict[str, str] = {}
    for line in raw.splitlines():
        if ":" in line:
            key, _, val = line.partition(":")
            fields[key.strip()] = val.strip()
    body = text[m.end():]
    return fields, body


def _iso_to_dt(s: str) -> datetime:
    """Parse an ISO-8601 timestamp to an aware UTC datetime."""
    s = s.rstrip("Z")
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        # Fall back: strip sub-second precision
        dt = datetime.fromisoformat(s[:19])
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _fmt_ts(s: str) -> str:
    """Return a human-readable local representation of an ISO timestamp."""
    try:
        return _iso_to_dt(s).strftime("%Y-%m-%d %H:%M UTC")
    except Exception:
        return s


# ---------------------------------------------------------------------------
# Data loaders
# ---------------------------------------------------------------------------

def load_run_summary(target_dir: Path) -> dict[str, Any] | None:
    """Return the latest run-*.json contents or None."""
    runs = sorted(target_dir.glob("run-*.json"))
    if not runs:
        return None
    try:
        return json.loads(runs[-1].read_text())
    except (json.JSONDecodeError, OSError):
        return None


def load_deferred_questions(target_dir: Path, since: datetime | None) -> list[dict[str, str]]:
    """Return a list of parsed deferred-questions-*.md files, ordered by timestamp."""
    questions: list[dict[str, str]] = []
    for path in sorted(target_dir.glob("deferred-questions-*.md")):
        try:
            text = path.read_text()
        except OSError:
            continue
        fields, body = _parse_frontmatter(text)
        ts_raw = fields.get("timestamp", "")
        if since and ts_raw:
            try:
                ts = _iso_to_dt(ts_raw)
                if ts < since:
                    continue
            except Exception:
                pass
        questions.append({
            "timestamp": ts_raw,
            "workspace": fields.get("workspace", ""),
            "prd_id": fields.get("prd_id", ""),
            "recommended_default": fields.get("recommended_default", ""),
            "body": body.strip(),
            "filename": path.name,
        })
    return questions


def load_git_log(repo_root: Path, since_ts: str | None) -> list[str]:
    """Return git log --oneline lines since since_ts (ISO string) or last 24h."""
    if not (repo_root / ".git").exists():
        return []
    cmd = ["git", "log", "--oneline"]
    if since_ts:
        cmd += [f"--after={since_ts}"]
    else:
        cmd += ["--after=24 hours ago"]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(repo_root),
            timeout=15,
        )
        return result.stdout.strip().splitlines() if result.returncode == 0 else []
    except Exception:
        return []


def load_kanban_changes(since_ts: str | None) -> dict[str, list[str]]:
    """Return kanban tasks moved to done/blocked since since_ts.
    Reads ~/.commandboard/workspaces/products/sigma-protocol/activity.jsonl if present.
    """
    activity_path = Path.home() / ".commandboard" / "workspaces" / "products" / "sigma-protocol" / "activity.jsonl"
    changes: dict[str, list[str]] = {"done": [], "blocked": []}
    if not activity_path.exists():
        return changes

    cutoff: datetime | None = None
    if since_ts:
        try:
            cutoff = _iso_to_dt(since_ts)
        except Exception:
            pass

    try:
        for line in activity_path.read_text().splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if cutoff:
                entry_ts_raw = entry.get("timestamp", entry.get("ts", ""))
                if entry_ts_raw:
                    try:
                        entry_ts = _iso_to_dt(entry_ts_raw)
                        if entry_ts < cutoff:
                            continue
                    except Exception:
                        pass
            task_id = entry.get("task_id", entry.get("id", ""))
            status = entry.get("status", entry.get("to", ""))
            if status in ("done", "completed") and task_id:
                changes["done"].append(task_id)
            elif status in ("blocked",) and task_id:
                changes["blocked"].append(task_id)
    except OSError:
        pass

    return changes


# ---------------------------------------------------------------------------
# Formatters
# ---------------------------------------------------------------------------

def _duration_str(seconds: int | float | None) -> str:
    if seconds is None:
        return ""
    s = int(seconds)
    if s < 60:
        return f"{s}s"
    return f"{s // 60}m {s % 60}s"


def format_markdown(
    run: dict[str, Any] | None,
    questions: list[dict[str, str]],
    commits: list[str],
    kanban: dict[str, list[str]],
    date_str: str,
) -> str:
    lines: list[str] = [f"# Overnight debrief — {date_str}", ""]

    # --- Run summary ---
    lines.append("## Run summary")
    if run:
        lines.append(f"- Started: {_fmt_ts(run.get('started_at', ''))}")
        ended = run.get("ended_at", "")
        lines.append(f"- Ended: {_fmt_ts(ended) if ended else 'in progress'}")
        lines.append(f"- CLI: {run.get('cli', 'unknown')}")
        completed = run.get("PRDs_completed") or []
        failed = run.get("PRDs_failed") or []
        lines.append(f"- PRDs completed: {len(completed)}")
        lines.append(f"- PRDs failed: {len(failed)}")
        lines.append(f"- Deferred questions: {run.get('deferred_question_count', len(questions))}")
    else:
        lines.append("- No run summary available")
    lines.append("")

    # --- Commits ---
    lines.append("## Commits shipped")
    if commits:
        for c in commits:
            lines.append(f"- {c}")
    else:
        lines.append("- (no commits found in window)")
    lines.append("")

    # --- PRDs completed ---
    if run and (run.get("PRDs_completed") or []):
        lines.append("## PRDs completed")
        for prd in run["PRDs_completed"]:
            prd_id = prd.get("id", "")
            title = prd.get("title", "")
            commit = prd.get("commit", "")
            dur = _duration_str(prd.get("duration_s"))
            parts = [f"- {prd_id}"]
            if title:
                parts.append(f"({title})")
            if commit:
                parts.append(f"— commit {commit}")
            if dur:
                parts.append(f"— {dur}")
            lines.append(" ".join(parts))
        lines.append("")

    # --- PRDs failed ---
    if run and (run.get("PRDs_failed") or []):
        lines.append("## PRDs failed")
        for prd in run["PRDs_failed"]:
            prd_id = prd.get("id", "")
            title = prd.get("title", "")
            last_commit = prd.get("last_commit", "")
            error = prd.get("error", "")
            error_tail = error.strip().splitlines()[-1] if error else ""
            parts = [f"- {prd_id}"]
            if title:
                parts.append(f"({title})")
            if last_commit:
                parts.append(f"— last attempt commit {last_commit}")
            if error_tail:
                parts.append(f"— error: {error_tail}")
            lines.append(" ".join(parts))
        lines.append("")

    # --- Deferred questions ---
    if questions:
        lines.append(f"## Deferred questions (need your call)")
        for i, q in enumerate(questions, start=1):
            lines.append(f"### Q{i} — {q['timestamp']}")
            if q["workspace"]:
                lines.append(f"**Workspace:** {q['workspace']}")
            if q["prd_id"]:
                lines.append(f"**PRD:** {q['prd_id']}")
            lines.append("")
            lines.append(q["body"])
            lines.append("")
            if q["recommended_default"]:
                lines.append(f"**Recommended default:** {q['recommended_default']}")
            lines.append("")
            lines.append("---")
            lines.append("")
    else:
        # Only emit the header if run had deferred_question_count > 0 in summary
        # (to match spec: omit or say "None pending")
        if run and run.get("deferred_question_count", 0) > 0:
            lines.append("## Deferred questions (need your call)")
            lines.append("None pending")
            lines.append("")

    # --- Kanban changes ---
    lines.append("## Kanban changes")
    if kanban["done"]:
        lines.append(f"- Done: {', '.join(kanban['done'])}")
    if kanban["blocked"]:
        lines.append(f"- Blocked: {', '.join(kanban['blocked'])}")
    if not kanban["done"] and not kanban["blocked"]:
        lines.append("- (no kanban changes in window)")
    lines.append("")

    # --- Next actions ---
    lines.append("## Next actions")
    next_actions: list[str] = []
    if questions:
        q_ids = [q["prd_id"] or q["filename"] for q in questions]
        next_actions.append(f"- Resolve {len(questions)} deferred question(s): {', '.join(q_ids)}")
    if run and (run.get("PRDs_failed") or []):
        failed_ids = [p.get("id", "") for p in run["PRDs_failed"] if p.get("id")]
        next_actions.append(f"- Re-dispatch failed PRDs: {', '.join(failed_ids)}")
    if run and (run.get("PRDs_completed") or []):
        completed_ids = [p.get("id", "") for p in (run["PRDs_completed"] or []) if p.get("id")]
        if completed_ids:
            next_actions.append(f"- (Optional) Spot-check shipped PRDs: {', '.join(completed_ids[:3])}")
    if not next_actions:
        next_actions.append("- Nothing urgent — clean overnight run.")
    lines.extend(next_actions)

    return "\n".join(lines) + "\n"


def format_json(
    run: dict[str, Any] | None,
    questions: list[dict[str, str]],
    commits: list[str],
    kanban: dict[str, list[str]],
    date_str: str,
) -> str:
    data: dict[str, Any] = {
        "date": date_str,
        "run_summary": run or {},
        "commits_shipped": commits,
        "prds_completed": (run or {}).get("PRDs_completed") or [],
        "prds_failed": (run or {}).get("PRDs_failed") or [],
        "deferred_questions": questions,
        "kanban_changes": kanban,
        "next_actions": [],
    }
    if questions:
        data["next_actions"].append(
            f"Resolve {len(questions)} deferred question(s)"
        )
    if data["prds_failed"]:
        failed_ids = [p.get("id", "") for p in data["prds_failed"]]
        data["next_actions"].append(f"Re-dispatch failed PRDs: {', '.join(failed_ids)}")
    return json.dumps(data, indent=2)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Morning debrief reader for /ops:overnight morning"
    )
    parser.add_argument(
        "--target-dir",
        default=".sigma/overnight",
        help="Directory containing overnight run files (default: .sigma/overnight)",
    )
    parser.add_argument(
        "--since",
        default=None,
        help="ISO timestamp — only include items after this point",
    )
    parser.add_argument(
        "--format",
        choices=["markdown", "json"],
        default="markdown",
        help="Output format (default: markdown)",
    )
    args = parser.parse_args()

    # Resolve target_dir relative to cwd
    target_dir = Path(args.target_dir)
    if not target_dir.is_absolute():
        target_dir = Path.cwd() / target_dir

    if not target_dir.exists():
        print(
            f"No overnight runs found in {target_dir}. "
            "Did you run `/ops:overnight` last night?"
        )
        return 0

    # Parse --since
    since_dt: datetime | None = None
    if args.since:
        try:
            since_dt = _iso_to_dt(args.since)
        except Exception:
            print(f"[morning-debrief] WARNING: could not parse --since={args.since!r}", file=sys.stderr)

    # Load data
    run = load_run_summary(target_dir)

    if run is None and not list(target_dir.glob("deferred-questions-*.md")):
        print(
            f"No overnight runs found in {target_dir}. "
            "Did you run `/ops:overnight` last night?"
        )
        return 0

    since_ts_str = run.get("started_at") if run else None
    if args.since:
        since_ts_str = args.since

    questions = load_deferred_questions(target_dir, since=since_dt)

    repo_root = Path.cwd()
    commits = load_git_log(repo_root, since_ts=since_ts_str)

    kanban = load_kanban_changes(since_ts=since_ts_str)

    date_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    if args.format == "json":
        print(format_json(run, questions, commits, kanban, date_str))
    else:
        print(format_markdown(run, questions, commits, kanban, date_str))

    return 0


if __name__ == "__main__":
    sys.exit(main())
