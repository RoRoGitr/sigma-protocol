---
name: run-o-1-ops-baseline
description: "Run Track O1: Ops Baseline Audit — sixth-grade readable playbook for ops"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

**Host interaction contract:** Resolve listed skills through the installed catalog before project-local paths. `AskUserQuestion` means the host's supported question mechanism; if unavailable, ask in a normal response and stop for an actual answer. Explicit unattended authorization for this run permits delegated local phases, with assumptions recorded; silence is never approval and this does not authorize publishing, spending, or production changes. Tool names in examples must be mapped to available host capabilities.

<!-- SKILLS-INVOKE:start -->
## Required skills — invoke at runtime

- `system-health`
- `doctor-fix`

<!-- SKILLS-INVOKE:end -->


# /run-o-1-ops-baseline — Run Track O1: Ops Baseline Audit

**On start, announce:** "Running Run Track O1: Ops Baseline Audit. I'll use plain language and give you at most 3 tasks for today."

<goal>
You are the COO Run Track lead for **O1**.

Execute phases **A → D** in order. Do NOT skip HITL gates.

| Phase | Name | Output |
|-------|------|--------|
| A | Load context + module check | Confirmed inputs exist or gaps logged |
| B | Execute domain work (invoke skills) | Draft artifact |
| C | Emit PRD + plain-language sections | `docs/run-track/ops/O1-OPS-BASELINE.md` + backlog entry |
| D | HITL gate | Founder approval before next Run step |

**Primary artifact:** `docs/run-track/ops/O1-OPS-BASELINE.md`  
**Run PRD id:** `O01.001`  
**Output template:** `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`

Read inputs:
- `docs/specs/MASTER_PRD.md`

Also read: `steps/_partials/run-track-common.md` (Run Track rules).
</goal>

---

## Step boundary

- **O1 owns:** Current tools, gaps, and single source of truth for tasks.
- **Does NOT own:** code implementation (`@dev-loop`).
- **Parallel OK:** Run while Build Track Step 11 PRDs execute when `.sigma/run-track.json` allows.

---

## Phase A — Context

1. Read `.sigma/run-track.json` and `docs/run-track/BUSINESS-MODEL.json` (if present).
2. If module says **skip O1**, write skip record to backlog with reason; STOP.
3. Verify input files; missing → ask founder or pull from nearest Build Track artifact.

**HITL-A:** Confirm O1 applies to this project.

---

## Phase B — Domain work

Invoke: system-health, doctor-fix

Produce draft using every section in `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`:
- What we're doing / Why it matters
- Your tasks today (≤3 founder items)
- Your agent's tasks
- Done when checklist
- Words you might see glossary (extend if needed)

---

## Phase C — Artifacts

1. Write `docs/run-track/ops/O1-OPS-BASELINE.md` (markdown, sixth-grade readable).
2. Append to `.sigma/backlogs/ops/prd.json`:
   - `prd_id`: `O01.001`
   - `run_step`: `O1`
   - `department`: `ops`
   - `artifact_path`: `docs/run-track/ops/O1-OPS-BASELINE.md`
   - `daily_tasks` (≤3, owner founder/agent)
   - `plain_language_summary`
3. Update `.sigma/run-track.json` → `completed_steps.ops` append `O1`.
4. If Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json), mirror today's tasks as Linear issues per `steps/_partials/linear-tracking.md`; without Linear, GitHub Issues is the task board. Never the retired SigmaHQ kanban.

---

## Phase D — HITL gate

**Founder must approve:** Confirm the Linear project mapping (linear.project in runtime-baseline.json).

Use AskUserQuestion. Do not start next Run step until approved.

**After approval:** If this was the **last step** in `ops`, run `python3 scripts/run-track-continue.py` and offer the next Run Track department per `steps/_partials/run-track-continuation.md`.

---

## Linear (optional — Linear replaced the SigmaHQ kanban 2026-07-11)

See `steps/_partials/linear-tracking.md`. Labels: `run-track`, `ops`, `O1`, `wave:W0` (wave labels are MANDATORY on every created issue).
