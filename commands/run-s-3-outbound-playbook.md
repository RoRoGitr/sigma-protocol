---
name: run-s-3-outbound-playbook
description: "Run Track S3: Outbound Playbook — sixth-grade readable playbook for sales"
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

- `outreach-sequencing`

<!-- SKILLS-INVOKE:end -->


# /run-s-3-outbound-playbook — Run Track S3: Outbound Playbook

**On start, announce:** "Running Run Track S3: Outbound Playbook. I'll use plain language and give you at most 3 tasks for today."

<goal>
You are the CSO Run Track lead for **S3**.

Execute phases **A → D** in order. Do NOT skip HITL gates.

| Phase | Name | Output |
|-------|------|--------|
| A | Load context + module check | Confirmed inputs exist or gaps logged |
| B | Execute domain work (invoke skills) | Draft artifact |
| C | Emit PRD + plain-language sections | `docs/run-track/sales/S3-OUTBOUND-SEQUENCE.md` + backlog entry |
| D | HITL gate | Founder approval before next Run step |

**Primary artifact:** `docs/run-track/sales/S3-OUTBOUND-SEQUENCE.md`  
**Run PRD id:** `S03.001`  
**Output template:** `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`

Read inputs:
- `docs/run-track/sales/S2-CRM-PIPELINE.md`

Also read: `steps/_partials/run-track-common.md` (Run Track rules).
</goal>

---

## Step boundary

- **S3 owns:** 12-touch outbound sequence over 21 days.
- **Does NOT own:** discovery calls (`/run-s-4`).
- **Parallel OK:** Run while Build Track Step 11 PRDs execute when `.sigma/run-track.json` allows.

---

## Phase A — Context

1. Read `.sigma/run-track.json` and `docs/run-track/BUSINESS-MODEL.json` (if present).
2. If module says **skip S3**, write skip record to backlog with reason; STOP.
3. Verify input files; missing → ask founder or pull from nearest Build Track artifact.

**HITL-A:** Confirm S3 applies to this project.

---

## Phase B — Domain work

Invoke: outreach-sequencing

Produce draft using every section in `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`:
- What we're doing / Why it matters
- Your tasks today (≤3 founder items)
- Your agent's tasks
- Done when checklist
- Words you might see glossary (extend if needed)

---

## Phase C — Artifacts

1. Write `docs/run-track/sales/S3-OUTBOUND-SEQUENCE.md` (markdown, sixth-grade readable).
2. Append to `.sigma/backlogs/sales/prd.json`:
   - `prd_id`: `S03.001`
   - `run_step`: `S3`
   - `department`: `sales`
   - `artifact_path`: `docs/run-track/sales/S3-OUTBOUND-SEQUENCE.md`
   - `daily_tasks` (≤3, owner founder/agent)
   - `plain_language_summary`
3. Update `.sigma/run-track.json` → `completed_steps.sales` append `S3`.
4. If Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json), mirror today's tasks as Linear issues per `steps/_partials/linear-tracking.md`; without Linear, GitHub Issues is the task board. Never the retired SigmaHQ kanban.

---

## Phase D — HITL gate

**Founder must approve:** Approve first 20 sends.

Use AskUserQuestion. Do not start next Run step until approved.

**After approval:** If this was the **last step** in `sales`, run `python3 scripts/run-track-continue.py` and offer the next Run Track department per `steps/_partials/run-track-continuation.md`.

---

## Linear (optional — Linear replaced the SigmaHQ kanban 2026-07-11)

See `steps/_partials/linear-tracking.md`. Labels: `run-track`, `sales`, `S3`, `wave:W0` (wave labels are MANDATORY on every created issue).
