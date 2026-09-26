#!/usr/bin/env python3
"""Run Track continuation — post Build Track gate + department walkthrough order.

Usage:
  python3 scripts/run-track-continue.py              # human prompt (markdown)
  python3 scripts/run-track-continue.py --json       # machine-readable
  python3 scripts/run-track-continue.py --mark-declined legal
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from run_track_manifest import CONTINUE_SEQUENCE, DEPT_STEP_IDS  # noqa: E402

RUN_TRACK_PATH = ROOT / ".sigma" / "run-track.json"

# Build Track gate — Run Track walkthrough unlocks after Step 15 (brain + observability contract)
BUILD_GATE = {
    "unlock_after": "step-15",
    "label": "Build Track Steps 0–15 (context engine + agent runtime + observability contract)",
    "required_paths": [
        "AGENTS.md",
        "docs/specs/AGENT-RUNTIME.md",
        "docs/observability/INSTRUMENTATION-CONTRACT.md",
    ],
}


def load_run_track() -> dict:
    if not RUN_TRACK_PATH.exists():
        return {"completed_steps": {}, "continuation": {}}
    return json.loads(RUN_TRACK_PATH.read_text())


def save_run_track(data: dict) -> None:
    RUN_TRACK_PATH.parent.mkdir(parents=True, exist_ok=True)
    RUN_TRACK_PATH.write_text(json.dumps(data, indent=2) + "\n")


def path_exists(rel: str) -> bool:
    p = ROOT / rel
    if p.is_dir():
        return any(p.iterdir())
    return p.exists()


def build_gate_status() -> dict:
    missing = [p for p in BUILD_GATE["required_paths"] if not path_exists(p)]
    override = load_run_track().get("continuation", {}).get("build_gate_override", False)
    met = override or len(missing) == 0
    return {
        "met": met,
        "unlock_after": BUILD_GATE["unlock_after"],
        "label": BUILD_GATE["label"],
        "missing_paths": missing,
        "override": override,
    }


def dept_progress(completed: dict, dept: str) -> dict:
    all_ids = DEPT_STEP_IDS.get(dept, [])
    done = completed.get(dept, [])
    remaining = [s for s in all_ids if s not in done]
    return {
        "dept": dept,
        "total": len(all_ids),
        "done_count": len(all_ids) - len(remaining),
        "complete": len(remaining) == 0 and len(all_ids) > 0,
        "next_step_id": remaining[0] if remaining else None,
        "remaining": remaining,
    }


def compute_state() -> dict:
    rt = load_run_track()
    completed = rt.get("completed_steps", {})
    cont = rt.get("continuation", {})
    declined = set(cont.get("declined_depts", []))
    gate = build_gate_status()

    depts_state = {d: dept_progress(completed, d) for d in DEPT_STEP_IDS}

    next_dept = None
    next_command = None
    next_label = None
    next_why = None
    in_progress_dept = None

    if gate["met"]:
        for dept, cmd, label, why in CONTINUE_SEQUENCE:
            if dept in declined:
                continue
            prog = depts_state[dept]
            if not prog["complete"]:
                next_dept = dept
                next_command = cmd
                next_label = label
                next_why = why
                if prog["done_count"] > 0:
                    in_progress_dept = dept
                break

    all_complete = gate["met"] and next_dept is None and not declined

    # Resume within active dept
    resume_command = None
    resume_step = None
    if next_dept:
        resume_command = next_command
        resume_step = depts_state[next_dept]["next_step_id"]

    return {
        "build_gate": gate,
        "run_track_unlocked": gate["met"],
        "all_run_track_complete": all_complete,
        "declined_depts": sorted(declined),
        "departments": depts_state,
        "sequence": [
            {"dept": d, "command": c, "label": l, "why": w} for d, c, l, w in CONTINUE_SEQUENCE
        ],
        "next": {
            "dept": next_dept,
            "command": next_command,
            "label": next_label,
            "why": next_why,
            "step_id": resume_step,
            "in_progress": in_progress_dept is not None,
        },
        "prompt": build_prompt(gate, next_dept, next_command, next_label, next_why, resume_step, in_progress_dept, all_complete, declined, depts_state),
    }


def build_prompt(gate, next_dept, next_command, next_label, next_why, resume_step, in_progress, all_complete, declined, depts_state):
    if not gate["met"]:
        missing = ", ".join(f"`{p}`" for p in gate["missing_paths"]) or "unknown"
        return (
            f"## Build Track not finished yet\n\n"
            f"Run Track walkthrough unlocks after **{gate['label']}**.\n\n"
            f"Missing: {missing}\n\n"
            f"Finish Build Track, then run `@continue --source=run-track` again."
        )

    if all_complete:
        return (
            "## Run Track complete\n\n"
            "All Growth Operations departments are done (or you skipped the rest).\n\n"
            "**Next:** `@dev-loop` to ship features, or `@gap-analysis` on a sprint."
        )

    if not next_dept:
        return (
            "## Run Track paused\n\n"
            "You declined remaining departments. Run `@continue --source=run-track` anytime to resume."
        )

    if next_dept == "legal" and resume_step == "L0":
        opener = (
            f"Your **planning brain is built** (Steps 0–15). Before marketing spend or contracts, "
            f"let's lock **how the company is formed** (LLC vs S-Corp vs C-Corp).\n\n"
            f"**Corporate Formation Counsel** walks L0 with the `entity-formation-setup` skill — "
            f"plain-language tradeoffs for *your* project, not generic legal advice."
        )
    elif in_progress:
        prog = depts_state[next_dept]
        opener = (
            f"You're mid-way through **{next_label}** ({prog['done_count']}/{prog['total']} steps). "
            f"Next step: **{resume_step}**."
        )
    else:
        opener = (
            f"Your **planning brain is built**. Ready for **{next_label}**?\n\n"
            f"*{next_why}*"
        )

    dept_complete_msg = ""
    # If previous dept in sequence just completed, celebrate briefly
    idx = next(i for i, (d, _, _, _) in enumerate(CONTINUE_SEQUENCE) if d == next_dept)
    if idx > 0:
        prev = CONTINUE_SEQUENCE[idx - 1][0]
        if depts_state[prev]["complete"]:
            prev_label = CONTINUE_SEQUENCE[idx - 1][2]
            dept_complete_msg = f"\n\n✓ **{prev_label}** is complete.\n"

    ask = (
        f"{opener}{dept_complete_msg}\n\n"
        f"---\n\n"
        f"**Would you like to run `{next_command}` now?**\n\n"
        f"| Option | Action |\n|--------|--------|\n"
        f"| **Yes** | Start/resume `{next_command}` (step **{resume_step}** next) |\n"
        f"| **Not yet** | Stay on Build/`@dev-loop`; Run Track waits |\n"
        f"| **Skip dept** | Say \"skip {next_dept}\" — we offer the next department |\n"
    )

    if next_dept == "marketing":
        ask += (
            f"\nAfter marketing is lined up, `@continue --source=run-track` will offer **`/run-sales`** "
            f"(then Growth, Content, Community, Ops in order).\n"
        )
    elif next_dept == "legal" and resume_step == "L0":
        ask += (
            f"\nL0 uses [`docs/run-track/RESEARCH-ENTITY-FORMATION.md`](../docs/run-track/RESEARCH-ENTITY-FORMATION.md) "
            f"to recommend entity type based on your product model.\n"
        )

    return ask


def mark_declined(dept: str) -> None:
    rt = load_run_track()
    cont = rt.setdefault("continuation", {})
    declined = set(cont.get("declined_depts", []))
    declined.add(dept)
    cont["declined_depts"] = sorted(declined)
    save_run_track(rt)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Track continuation prompt")
    parser.add_argument("--json", action="store_true", help="JSON output")
    parser.add_argument("--mark-declined", metavar="DEPT", help="Record skipped department")
    args = parser.parse_args()

    if args.mark_declined:
        mark_declined(args.mark_declined)
        if args.json:
            print(json.dumps({"declined": args.mark_declined}, indent=2))
        else:
            print(f"Marked `{args.mark_declined}` declined. Run again for next department.")
        return 0

    state = compute_state()
    if args.json:
        # prompt is long; still include for agents
        print(json.dumps(state, indent=2))
    else:
        print(state["prompt"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
