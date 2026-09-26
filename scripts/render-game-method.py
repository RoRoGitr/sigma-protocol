#!/usr/bin/env python3
"""Render portable game-method references from the one canonical catalog."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def lines(values):
    return "\n".join("- " + value for value in values) or "- None specified."


def questions(values):
    return "\n".join(f"- **{q['id']}**: {q['prompt']}" for q in values)


def render():
    source = ROOT / "domains/game-development/catalog.json"
    catalog = json.loads(source.read_text(encoding="utf-8"))
    target = ROOT / "src/skills/game-development/references"
    (target / "steps").mkdir(parents=True, exist_ok=True)
    (target / "workflows").mkdir(exist_ok=True)
    (target / "catalog.json").write_bytes(source.read_bytes())
    source_map = {row["id"]: row for row in catalog["sources"]}
    local_refs = {}
    for row in catalog["sources"]:
        if not row["url"].startswith(("https://", "http://")):
            local = (ROOT / row["url"]).resolve()
            if row["evidenceStatus"] != "proposed-adaptation" or not local.is_relative_to(ROOT) or not local.is_file():
                raise ValueError("Invalid internal game-method source")
            name = row["id"] + ".md"
            (target / name).write_bytes(local.read_bytes())
            local_refs[row["id"]] = "../" + name

    def refs(ids):
        return "\n".join(f"- [{source_map[key]['title']}]({local_refs.get(key, source_map[key]['url'])}) — {source_map[key]['evidenceStatus']}. {source_map[key]['limitations']}" for key in ids)

    for step in catalog["canonicalSteps"]:
        body = f"# Game adaptation — Step {step['id']}: {step['title']}\n\nGenerated from catalog {catalog['version']}. Canonical source: `{step['source']}`.\n\nTreatment: **{step['treatment']}** — {step['reason']}\n\n## Creator questions\n\n{questions(step['questions'])}\n"
        for key in ["inputs", "activities", "workflowIds", "skills", "roles", "outputs", "dependencies", "reviewCriteria", "revisionRules"]:
            body += f"\n## {key}\n\n{lines(step[key])}\n"
        body += "\n## Sources and limits\n\n" + refs(step["sources"]) + "\n"
        (target / "steps" / (step["id"] + ".md")).write_text(body, encoding="utf-8")
    for workflow in catalog["workflows"]:
        body = f"# {workflow['title']}\n\nGenerated from catalog {catalog['version']}.\n\n{workflow['purpose']}\n\nApplicability: {workflow['applicability']}\n\nAtlas stages: {', '.join(workflow['atlasStepIds'])}. Canonical steps: {', '.join(workflow['canonicalStepIds'])}.\n"
        for phase in workflow["phases"]:
            body += f"\n## {phase['id']} — {phase['title']}\n\n### Creator questions\n\n{questions(phase['questions'])}\n"
            for key in ["inputs", "activities", "tools", "skills", "roles", "outputs", "dependencies", "reviewCriteria", "revisionRules"]:
                body += f"\n### {key}\n\n{lines(phase[key])}\n"
            body += f"\n### Evidence required\n\n{phase['evidenceRequired']}\n\n### Sources\n\n{refs(phase['sources'])}\n"
        (target / "workflows" / (workflow["id"] + ".md")).write_text(body, encoding="utf-8")
    print(f"Game references: {len(catalog['canonicalSteps'])} steps, {len(catalog['workflows'])} workflows")


if __name__ == "__main__":
    render()
