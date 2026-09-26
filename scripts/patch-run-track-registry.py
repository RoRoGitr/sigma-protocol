#!/usr/bin/env python3
"""Patch agent-skill-registry.json with all Run Track steps and atom skills."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from run_track_manifest import ATOM_SKILLS, ORCHESTRATOR_SKILLS, all_step_rows  # noqa: E402

REG = ROOT / ".claude/lib/agent-skill-registry.json"


def main() -> None:
    data = json.loads(REG.read_text())
    steps = data.setdefault("steps", {})
    skills = data.setdefault("skills", {})

    for slug, meta in ORCHESTRATOR_SKILLS.items():
        steps[slug] = {
            "command": f"commands/{slug}.md",
            "department": meta["department"],
            "skills": meta.get("extra_skills", []),
        }
        skills[slug] = {k: v for k, v in meta.items() if k != "extra_skills"}

    for row in all_step_rows():
        slug, _step_id, _title, dept, skills_csv, *_rest = row
        primary = skills_csv.split(",")[0].strip()
        steps[slug] = {
            "command": f"commands/{slug}.md",
            "department": dept,
            "skills": [s.strip() for s in skills_csv.split(",")],
        }
        if primary in skills:
            rs = skills[primary].setdefault("run_steps", [])
            if slug not in rs:
                rs.append(slug)

    for slug, meta in ATOM_SKILLS.items():
        skills[slug] = meta

    data["updated"] = "2026-06-29"
    REG.write_text(json.dumps(data, indent=2) + "\n")
    print(f"Patched {REG}")


if __name__ == "__main__":
    main()
