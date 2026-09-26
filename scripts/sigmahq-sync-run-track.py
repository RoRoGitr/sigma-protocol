#!/usr/bin/env python3
"""Sync Run Track department PRDs to SigmaHQ kanban (kanban-md). Fail-open if not installed."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

DEPT_PREFIX = {
    "marketing": "M",
    "sales": "S",
    "content": "C",
    "growth": "G",
    "community": "Co",
    "ops": "O",
    "finance": "Fn",
    "legal": "L",
}

ALL_DEPTS = list(DEPT_PREFIX.keys())


def kanban_available() -> bool:
    if not Path.home().joinpath(".commandboard").is_dir():
        return False
    try:
        subprocess.run(["kanban-md", "--version"], capture_output=True, check=True)
        return True
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False


def load_backlog(dept: str) -> dict:
    path = ROOT / ".sigma" / "backlogs" / dept / "prd.json"
    if not path.exists():
        return {"items": []}
    return json.loads(path.read_text())


def sync_department(dept: str, dry_run: bool) -> int:
    data = load_backlog(dept)
    items = data.get("items") or []
    if not items:
        print(f"[sigmahq-sync-run-track] no {dept} PRDs to sync")
        return 0

    prefix = DEPT_PREFIX[dept]
    created = 0
    for item in items:
        if item.get("status") == "completed":
            continue
        prd_id = item.get("prd_id", "")
        if not prd_id.startswith(prefix):
            continue
        title = item.get("title") or prd_id
        run_step = item.get("run_step", "")
        tasks = item.get("daily_tasks") or []
        founder_tasks = [t["task"] for t in tasks if t.get("owner") == "founder"][:3]
        task_line = founder_tasks[0] if founder_tasks else title
        card_title = f"[{dept}|{run_step}] {task_line}"

        if dry_run:
            print(f"  would create: {card_title}")
            created += 1
            continue

        try:
            subprocess.run(
                [
                    "kanban-md",
                    "add",
                    card_title,
                    "--tag",
                    "run-track",
                    "--tag",
                    dept,
                    "--tag",
                    run_step,
                    "--due",
                    date.today().isoformat(),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            created += 1
        except subprocess.CalledProcessError as e:
            print(f"[warn] kanban-md add failed: {e.stderr or e}", file=sys.stderr)

    print(f"[sigmahq-sync-run-track] synced {created} {dept} card(s)")
    return created


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync Run Track PRDs to SigmaHQ")
    parser.add_argument("--dept", choices=ALL_DEPTS + ["all"], default="all")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not kanban_available() and not args.dry_run:
        print("[sigmahq-sync-run-track] skip — ~/.commandboard or kanban-md not available")
        return 0

    depts = ALL_DEPTS if args.dept == "all" else [args.dept]
    total = sum(sync_department(d, args.dry_run) for d in depts)
    return 0 if total >= 0 else 1


if __name__ == "__main__":
    sys.exit(main())
