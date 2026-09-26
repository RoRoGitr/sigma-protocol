#!/usr/bin/env python3
"""SigmaHQ v4 maintenance entrypoint."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))

from hq_state import (  # noqa: E402
    build_leaderboard,
    build_summary,
    compact_runtime_state,
    quarantine_tmp_files,
    scan_workspaces,
    sync_stats,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Maintain SigmaHQ v4 state files")
    parser.add_argument("--compact", action="store_true", help="compact active agents and review queue")
    parser.add_argument("--stats", action="store_true", help="sync stats and leaderboard from workspace tasks")
    parser.add_argument("--quarantine-tmp", action="store_true", help="move orphan tmp*.tmp files to archive/state")
    parser.add_argument("--all", action="store_true", help="run compact, stats, and tmp quarantine")
    parser.add_argument("--json", action="store_true", help="print JSON output")
    args = parser.parse_args()

    run_all = args.all or not (args.compact or args.stats or args.quarantine_tmp)
    result = {}
    workspaces = None

    if run_all or args.compact:
        result["compact"] = compact_runtime_state()
    if run_all or args.stats:
        workspaces = scan_workspaces(include_archive=False)
        result["stats"] = sync_stats(workspaces)
        result["summary"] = build_summary(workspaces)
        result["leaderboard"] = build_leaderboard(workspaces)
    if run_all or args.quarantine_tmp:
        result["tmp"] = quarantine_tmp_files()

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if "compact" in result:
            c = result["compact"]
            print(
                "Compacted agents "
                f"{c['agents']['before']} -> {c['agents']['after']}; "
                "reviews "
                f"{c['reviews']['before']} -> {c['reviews']['after']} "
                f"({c['reviews']['invalid_archived']} invalid archived)"
            )
        if "stats" in result:
            s = result["stats"]
            print(
                f"Stats synced: LV.{s.get('level')} {s.get('rank')} "
                f"{s.get('totalXp')} XP, {s.get('tasksCompleted')} tasks"
            )
        if "tmp" in result:
            t = result["tmp"]
            mb = round((t.get("bytes") or 0) / (1024 * 1024), 1)
            print(f"Tmp quarantine: moved {t.get('moved')} files ({mb} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
