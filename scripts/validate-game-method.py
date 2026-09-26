#!/usr/bin/env python3
"""Check game method coverage, resolvable references and runnable lookup structure."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]


def validate():
    catalog = json.loads((ROOT / "domains/game-development/catalog.json").read_text(encoding="utf-8"))
    assert catalog["format"] == "sigma-game-development" and catalog["version"] == "1.0.0"
    sources = {source["id"]: source for source in catalog["sources"]}
    assert len(sources) == len(catalog["sources"]), "Duplicate source ID"
    for source in sources.values():
        if not re.match(r"https?://", source["url"]):
            local = (ROOT / source["url"]).resolve()
            assert source["evidenceStatus"] == "proposed-adaptation" and local.is_relative_to(ROOT) and local.is_file(), source["id"]
        assert source["title"] and source["limitations"] and source["evidenceStatus"]
    steps = catalog["canonicalSteps"]
    actual_sources = {str(path.relative_to(ROOT)) for path in (ROOT / "steps").glob("step-*") if path.is_file()}
    assert {step["source"] for step in steps} == actual_sources, "Every canonical source must be mapped"
    canonical_ids = {step["id"] for step in steps}
    assert len(canonical_ids) == len(steps) == 18
    atlas_ids = {"0", "1", "1.5", *map(str, range(2, 19))}
    assert {step["id"] for step in catalog["atlasSteps"]} == atlas_ids and len(catalog["atlasSteps"]) == 20
    workflows = {workflow["id"]: workflow for workflow in catalog["workflows"]}
    assert len(workflows) == len(catalog["workflows"]) == 12

    def questions(rows):
        assert rows and len({row["id"] for row in rows}) == len(rows), "Questions need unique IDs"
        for row in rows:
            assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,119}", row["id"])
            assert row["prompt"].strip() and type(row["required"]) is bool

    def references(row):
        assert row["sources"] and set(row["sources"]) <= sources.keys(), "Unresolved or missing source"
        for skill in row.get("skills", []):
            assert (ROOT / "src/skills" / skill / "SKILL.md").exists() or (ROOT / ".agents/skills" / skill / "SKILL.md").exists(), f"Unresolved skill: {skill}"

    for step in steps:
        assert step["treatment"] in {"reuse", "adapt", "conditional", "not-applicable"} and step["reason"].strip()
        for key in ["inputs", "activities", "outputs", "reviewCriteria", "revisionRules"]:
            assert step[key], (step["id"], key)
        assert set(step["workflowIds"]) <= workflows.keys()
        questions(step["questions"])
        references(step)
    for step in catalog["atlasSteps"]:
        assert set(step["canonicalStepIds"]) <= canonical_ids
        assert set(step["workflowIds"]) <= workflows.keys()
        assert step["purpose"] and step["notes"] and step["outputs"]
        questions(step["questions"])
    phase_count = 0
    for workflow in workflows.values():
        references(workflow)
        assert set(workflow["canonicalStepIds"]) <= canonical_ids and set(workflow["atlasStepIds"]) <= atlas_ids
        phases = {phase["id"]: phase for phase in workflow["phases"]}
        assert phases and len(phases) == len(workflow["phases"])
        phase_count += len(phases)
        for phase in phases.values():
            questions(phase["questions"])
            references(phase)
            assert set(phase["dependencies"]) <= phases.keys()
            for key in ["inputs", "activities", "tools", "roles", "outputs", "reviewCriteria", "revisionRules", "evidenceRequired"]:
                assert phase[key], (workflow["id"], phase["id"], key)
            assert isinstance(phase["evidenceRequired"], str)
        visited, visiting = set(), set()

        def visit(key):
            assert key not in visiting, "Cyclic phase dependency"
            if key in visited:
                return
            visiting.add(key)
            for dependency in phases[key]["dependencies"]:
                visit(dependency)
            visiting.remove(key)
            visited.add(key)

        for key in phases:
            visit(key)
    assert {"profile", "idea-pack"} <= {p["id"] for p in workflows["discovery"]["phases"]}
    assert "synthesis" in {p["id"] for p in workflows["team"]["phases"]}
    print(f"Game method: PASS — {len(steps)} canonical steps, 20 Atlas stages, {len(workflows)} workflows, {phase_count} phases, {len(sources)} source records")


if __name__ == "__main__":
    validate()
