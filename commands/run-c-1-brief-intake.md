---
name: run-c-1-brief-intake
description: "Run Track C1: Brief Intake — sixth-grade readable playbook for content"
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

- `03-brand-voice`

<!-- SKILLS-INVOKE:end -->


# /run-c-1-brief-intake — Run Track C1: Brief Intake

**On start, announce:** "Running Run Track C1: Brief Intake. I'll use plain language and give you at most 3 tasks for today."

<goal>
You are the Chief Content Officer Run Track lead for **C1**.

Execute phases **A → D** in order. Do NOT skip HITL gates.

| Phase | Name | Output |
|-------|------|--------|
| A | Load context + module check | Confirmed inputs exist or gaps logged |
| B | Execute domain work (invoke skills) | Draft artifact |
| C | Emit PRD + plain-language sections | `docs/run-track/content/C1-BRIEF-INTAKE.md` + backlog entry |
| D | HITL gate | Founder approval before next Run step |

**Primary artifact:** `docs/run-track/content/C1-BRIEF-INTAKE.md`  
**Run PRD id:** `C01.001`  
**Output template:** `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`

Read inputs:
- `docs/run-track/marketing/M4-MESSAGING-SYSTEM.md`
- `docs/run-track/marketing/M6-CONTENT-CALENDAR.md`

Also read: `steps/_partials/run-track-common.md` (Run Track rules).
</goal>

---

## Step boundary

- **C1 owns:** Lock brief, pillar, and brand guardrails for this production cycle.
- **Does NOT own:** calendar planning (M6).
- **Parallel OK:** Run while Build Track Step 11 PRDs execute when `.sigma/run-track.json` allows.

---

## Phase A — Context

1. Read `.sigma/run-track.json` and `docs/run-track/BUSINESS-MODEL.json` (if present).
2. If module says **skip C1**, write skip record to backlog with reason; STOP.
3. Verify input files; missing → ask founder or pull from nearest Build Track artifact.

**HITL-A:** Confirm C1 applies to this project.

---

## Phase B — Domain work

Invoke: 03-brand-voice

Produce draft using every section in `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`:
- What we're doing / Why it matters
- Your tasks today (≤3 founder items)
- Your agent's tasks
- Done when checklist
- Words you might see glossary (extend if needed)

---

## Phase C — Artifacts

1. Write `docs/run-track/content/C1-BRIEF-INTAKE.md` (markdown, sixth-grade readable).
2. Append to `.sigma/backlogs/content/prd.json`:
   - `prd_id`: `C01.001`
   - `run_step`: `C1`
   - `department`: `content`
   - `artifact_path`: `docs/run-track/content/C1-BRIEF-INTAKE.md`
   - `daily_tasks` (≤3, owner founder/agent)
   - `plain_language_summary`
3. Update `.sigma/run-track.json` → `completed_steps.content` append `C1`.
4. If Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json), mirror today's tasks as Linear issues per `steps/_partials/linear-tracking.md`; without Linear, GitHub Issues is the task board. Never the retired SigmaHQ kanban.

---

## Phase D — HITL gate

**Founder must approve:** Approve brief and pillar for this cycle.

Use AskUserQuestion. Do not start next Run step until approved.

**After approval:** If this was the **last step** in `content`, run `python3 scripts/run-track-continue.py` and offer the next Run Track department per `steps/_partials/run-track-continuation.md`.

---

## Linear (optional — Linear replaced the SigmaHQ kanban 2026-07-11)

See `steps/_partials/linear-tracking.md`. Labels: `run-track`, `content`, `C1`, `wave:W0` (wave labels are MANDATORY on every created issue).
