#!/usr/bin/env python3
"""Generate Run Track step files (steps/ + .agents/skills/) + manifest JSON. Idempotent."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from run_track_manifest import (  # noqa: E402
    ATOM_SKILLS,
    DEPT_LEAD,
    ORCHESTRATORS,
    WAVES,
    all_step_rows,
    prd_id_for_step,
)

STEPS = ROOT / "steps"
SKILLS = ROOT / ".agents" / "skills"
SRC_SKILLS = ROOT / "src" / "skills"
PARTIAL = "steps/_partials/run-track-common.md"
TEMPLATE_REF = "templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md"


RUN_GATE_CONTRACT = "**Host interaction contract:** Resolve listed skills through the installed catalog before project-local paths. `AskUserQuestion` means the host's supported question mechanism; if unavailable, ask in a normal response and stop for an actual answer. Explicit unattended authorization for this run permits delegated local phases, with assumptions recorded; silence is never approval and this does not authorize publishing, spending, or production changes. Tool names in examples must be mapped to available host capabilities.\n"


def skills_invoke_block(skills_csv: str) -> str:
    lines = ["<!-- SKILLS-INVOKE:start -->", "## Required skills — invoke at runtime", ""]
    for s in skills_csv.split(","):
        lines.append(f"- `{s.strip()}`")
    lines.extend(["", "<!-- SKILLS-INVOKE:end -->", ""])
    return "\n".join(lines)


def render_step(row: tuple) -> str:
    slug, step_id, title, dept, skills_csv, artifact, inputs, objective, founder_gate, does_not_own = row
    prd_id = prd_id_for_step(step_id)
    inputs_bullets = "\n".join(f"- `{p}`" for p in inputs)
    skill_list = skills_csv.replace(",", ", ")
    lead = DEPT_LEAD[dept]

    return f"""---
name: {slug}
description: "Run Track {step_id}: {title} — sixth-grade readable playbook for {dept}"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

{RUN_GATE_CONTRACT}
{skills_invoke_block(skills_csv)}

# /{slug} — Run Track {step_id}: {title}

**On start, announce:** "Running Run Track {step_id}: {title}. I'll use plain language and give you at most 3 tasks for today."

<goal>
You are the {lead} Run Track lead for **{step_id}**.

Execute phases **A → D** in order. Do NOT skip HITL gates.

| Phase | Name | Output |
|-------|------|--------|
| A | Load context + module check | Confirmed inputs exist or gaps logged |
| B | Execute domain work (invoke skills) | Draft artifact |
| C | Emit PRD + plain-language sections | `{artifact}` + backlog entry |
| D | HITL gate | Founder approval before next Run step |

**Primary artifact:** `{artifact}`  
**Run PRD id:** `{prd_id}`  
**Output template:** `{TEMPLATE_REF}`

Read inputs:
{inputs_bullets}

Also read: `{PARTIAL}` (Run Track rules).
</goal>

---

## Step boundary

- **{step_id} owns:** {objective}
- **Does NOT own:** {does_not_own}
- **Parallel OK:** Run while Build Track Step 11 PRDs execute when `.sigma/run-track.json` allows.

---

## Phase A — Context

1. Read `.sigma/run-track.json` and `docs/run-track/BUSINESS-MODEL.json` (if present).
2. If module says **skip {step_id}**, write skip record to backlog with reason; STOP.
3. Verify input files; missing → ask founder or pull from nearest Build Track artifact.

**HITL-A:** Confirm {step_id} applies to this project.

---

## Phase B — Domain work

Invoke: {skill_list}

Produce draft using every section in `{TEMPLATE_REF}`:
- What we're doing / Why it matters
- Your tasks today (≤3 founder items)
- Your agent's tasks
- Done when checklist
- Words you might see glossary (extend if needed)

---

## Phase C — Artifacts

1. Write `{artifact}` (markdown, sixth-grade readable).
2. Append to `.sigma/backlogs/{dept}/prd.json`:
   - `prd_id`: `{prd_id}`
   - `run_step`: `{step_id}`
   - `department`: `{dept}`
   - `artifact_path`: `{artifact}`
   - `daily_tasks` (≤3, owner founder/agent)
   - `plain_language_summary`
3. Update `.sigma/run-track.json` → `completed_steps.{dept}` append `{step_id}`.
4. If Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json), mirror today's tasks as Linear issues per `steps/_partials/linear-tracking.md`; without Linear, GitHub Issues is the task board. Never the retired SigmaHQ kanban.

---

## Phase D — HITL gate

**Founder must approve:** {founder_gate}

Use AskUserQuestion. Do not start next Run step until approved.

**After approval:** If this was the **last step** in `{dept}`, run `python3 scripts/run-track-continue.py` and offer the next Run Track department per `steps/_partials/run-track-continuation.md`.

---

## Linear (optional — Linear replaced the SigmaHQ kanban 2026-07-11)

See `steps/_partials/linear-tracking.md`. Labels: `run-track`, `{dept}`, `{step_id}`, `wave:W0` (wave labels are MANDATORY on every created issue).
"""


def render_orchestrator(slug: str, title: str, dept: str, steps: list, trigger: str) -> str:
    step_ids = [s[1] for s in steps]
    chain = "\n".join(f"| {i+1} | `/{s[0]}` | {s[1]} {s[2]} |" for i, s in enumerate(steps))

    return f"""---
name: {slug}
description: "Run Track orchestrator: {title} — sequential steps with daily task emission"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

{RUN_GATE_CONTRACT}
# /{slug} — {title}

**On start, announce:** "Starting Run Track for {dept}. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **{dept}**.

| # | Command | Step |
|---|---------|------|
{chain}

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/{slug}` resume on next session
</goal>

---

## Trigger

- Default: {trigger} (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.{dept}` in `.sigma/run-track.json`. Next step = first missing in: {step_ids}

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in {step_ids} is in `completed_steps.{dept}`:

1. Announce: "{dept.title()} Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
"""


def write_atom_skill(slug: str, body: str) -> None:
    skill_dir = SKILLS / slug
    skill_dir.mkdir(parents=True, exist_ok=True)
    fm = f"""---
name: {slug}
description: "Run Track atom skill — checklist and routing only; does NOT call APIs."
department: {ATOM_SKILLS.get(slug, {}).get('department', 'marketing')}
---

"""
    (skill_dir / "SKILL.md").write_text(fm + body)


def ensure_skill_adapter(slug: str) -> None:
    """Promote src/skills adapter into .agents/skills when missing."""
    dest = SKILLS / slug / "SKILL.md"
    if dest.exists():
        return
    for src in (SRC_SKILLS / slug / "SKILL.md", SRC_SKILLS / "ops" / slug / "SKILL.md"):
        if src.exists():
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(src.read_text())
            return


def main() -> None:
    STEPS.mkdir(parents=True, exist_ok=True)
    common = """# Run Track Common Rules

- **Reading level:** Sixth grade. Short sentences. Glossary for acronyms.
- **Founder tasks:** Max 3 per step per day.
- **Skills:** Invoke listed skills; do not duplicate their full bodies here.
- **Secrets:** Never commit credentials. Use project overlay for account IDs only.
- **PRD schema:** `schemas/sigma-run-prd.schema.json`
"""
    (ROOT / PARTIAL).write_text(common)

    count = 0
    manifest_steps = []

    for row in all_step_rows():
        content = render_step(row)
        slug = row[0]
        (STEPS / slug).write_text(content)
        skill_dir = SKILLS / slug
        skill_dir.mkdir(parents=True, exist_ok=True)
        (skill_dir / "SKILL.md").write_text(content)
        manifest_steps.append({
            "slug": slug,
            "step_id": row[1],
            "department": row[3],
            "primary_skill": row[4].split(",")[0].strip(),
            "artifact": row[5],
        })
        count += 1

    for slug, title, dept, steps, trigger in ORCHESTRATORS:
        content = render_orchestrator(slug, title, dept, steps, trigger)
        (STEPS / slug).write_text(content)
        d = SKILLS / slug
        d.mkdir(parents=True, exist_ok=True)
        (d / "SKILL.md").write_text(content)
        count += 1

    # Atom skill bodies
    write_atom_skill(
        "content-production-queue",
        """# content-production-queue

Checklist: brief approved → scripts → thumbs → social pack → the social-scheduler MCP (e.g. Buffer/Hootsuite integration).
Output: publish queue section in C8 artifact. Never store API keys in git.
""",
    )
    write_atom_skill(
        "funnel-instrumentation-setup",
        """# funnel-instrumentation-setup

Checklist: name funnel stages → map PostHog/GA4 events → verify one live event.
Read: `docs/run-track/TOOL-STACK-MATRIX.md`, M3 checklist.
""",
    )
    write_atom_skill(
        "ab-test-spec",
        """# ab-test-spec

Template: hypothesis, metric, variant, success threshold, duration, sample size note.
Routes to PostHog experiments docs. Used by G3–G5.
""",
    )
    write_atom_skill(
        "weekly-review",
        """# weekly-review

Checklist-only WBR (Weekly Business Review) for Run Track O6.

## Agenda (60 min)
1. Pipeline — read `docs/run-track/sales/S8-PIPELINE-OPS.md` highlights
2. Metrics — read `docs/run-track/growth/G2-BASELINE-METRICS.md` deltas
3. Blockers — open Linear issues (label `run-track`)
4. Decisions — write to project `decisions.md`

Does NOT call APIs. Used by `/run-o-6-wbr`.
""",
    )
    write_atom_skill(
        "entity-formation-setup",
        """# entity-formation-setup

**Corporate Formation Counsel** — educational advisor for Run Track **L0** (not legal advice).

## Required reading

1. `docs/run-track/RESEARCH-ENTITY-FORMATION.md` — decision matrix + filing checklist
2. `docs/specs/MASTER_PRD.md` — revenue model, co-founders, liability
3. Step 1.5 outputs if present (`docs/specs/OFFER_ARCHITECTURE.md`, pricing)

## Session flow

### 1. Interview (≤5 questions)

Ask founder: solo vs co-founders, 12-month revenue band, VC plan, liability exposure, home state.

### 2. Recommend ONE primary path

Use the matrix in RESEARCH-ENTITY-FORMATION.md. Explain in **sixth-grade English**:

- **LLC** — simple shield, pass-through tax
- **LLC + S-Corp election** — when profitable enough that CPA tax savings beat payroll admin
- **C-Corp (often DE)** — VC / standard equity

State **why for this project**, not generic pros/cons.

### 3. Write artifact

`docs/run-track/legal/L0-ENTITY-FORMATION.md` with sections:

- What we picked and why (2–3 short paragraphs)
- Your tasks today (≤3): e.g. pick registered agent, file articles, schedule CPA call
- Filing checklist (from research doc)
- What **not** to DIY (investor docs, multi-state, S-Corp salary modeling)

### 4. Escalation

- Tax / S-Corp / runway → `/run-finance` Fn1
- Contract templates → L2+ `/run-legal`
- Licensed filings → external attorney

## Triggers

`llc`, `s-corp`, `incorporate`, `ein`, `entity formation`, `/run-l-0`
""",
    )

    for slug in ("deep-research",):
        ensure_skill_adapter(slug)

    # Output dirs + backlog shells
    for dept in (
        "marketing",
        "sales",
        "content",
        "growth",
        "community",
        "ops",
        "finance",
        "legal",
    ):
        out = ROOT / "docs" / "run-track" / dept
        out.mkdir(parents=True, exist_ok=True)
        readme = out / "README.md"
        if not readme.exists():
            readme.write_text(f"# {dept.title()} Run Track — Output Directory\n\nArtifacts from `/{'run-' + dept}` land here.\n")
        backlog_dir = ROOT / ".sigma" / "backlogs" / dept
        backlog_dir.mkdir(parents=True, exist_ok=True)
        example = backlog_dir / "prd.json.example"
        if not example.exists():
            example.write_text(
                json.dumps(
                    {
                        "version": "1.0.0",
                        "updated": "2026-06-30",
                        "schema": "../../schemas/sigma-run-prd.schema.json",
                        "items": [],
                    },
                    indent=2,
                )
                + "\n"
            )
        backlog = backlog_dir / "prd.json"
        if not backlog.exists() and example.exists():
            backlog.write_text(example.read_text())

    manifest = {
        "version": "2.0.0",
        "orchestrators": [o[0] for o in ORCHESTRATORS],
        "steps": manifest_steps,
        "atom_skills": list(ATOM_SKILLS.keys()),
        "waves": {
            str(k): {"orchestrators": v["orchestrators"], "depts": v["depts"]}
            for k, v in WAVES.items()
        },
    }
    (ROOT / "scripts" / "run-track-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

    print(f"Generated {count} Run Track step/orchestrator files.")


if __name__ == "__main__":
    main()
