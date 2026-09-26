---
name: run-co-1-platform-audit
description: "Run Track Co1: Platform Health Audit — sixth-grade readable playbook for community"
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

- `community-analytics`

<!-- SKILLS-INVOKE:end -->


# /run-co-1-platform-audit — Run Track Co1: Platform Health Audit

**On start, announce:** "Running Run Track Co1: Platform Health Audit. I'll use plain language and give you at most 3 tasks for today."

<goal>
You are the Community Lead Run Track lead for **Co1**.

Execute phases **A → D** in order. Do NOT skip HITL gates.

| Phase | Name | Output |
|-------|------|--------|
| A | Load context + module check | Confirmed inputs exist or gaps logged |
| B | Execute domain work (invoke skills) | Draft artifact |
| C | Emit PRD + plain-language sections | `docs/run-track/community/Co1-PLATFORM-AUDIT.md` + backlog entry |
| D | HITL gate | Founder approval before next Run step |

**Primary artifact:** `docs/run-track/community/Co1-PLATFORM-AUDIT.md`  
**Run PRD id:** `Co01.001`  
**Output template:** `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`

Read inputs:
- `docs/run-track/marketing/M2-AVATAR-POSITIONING.md`

Also read: `steps/_partials/run-track-common.md` (Run Track rules).
</goal>

---

## Step boundary

- **Co1 owns:** Audit Discord/TG/forum health metrics.
- **Does NOT own:** content scripts (`/run-content`).
- **Parallel OK:** Run while Build Track Step 11 PRDs execute when `.sigma/run-track.json` allows.

---

## Phase A — Context

1. Read `.sigma/run-track.json` and `docs/run-track/BUSINESS-MODEL.json` (if present).
2. If module says **skip Co1**, write skip record to backlog with reason; STOP.
3. Verify input files; missing → ask founder or pull from nearest Build Track artifact.

**HITL-A:** Confirm Co1 applies to this project.

---

## Phase B — Domain work

Invoke: community-analytics

Produce draft using every section in `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`:
- What we're doing / Why it matters
- Your tasks today (≤3 founder items)
- Your agent's tasks
- Done when checklist
- Words you might see glossary (extend if needed)

---

## Phase C — Artifacts

1. Write `docs/run-track/community/Co1-PLATFORM-AUDIT.md` (markdown, sixth-grade readable).
2. Append to `.sigma/backlogs/community/prd.json`:
   - `prd_id`: `Co01.001`
   - `run_step`: `Co1`
   - `department`: `community`
   - `artifact_path`: `docs/run-track/community/Co1-PLATFORM-AUDIT.md`
   - `daily_tasks` (≤3, owner founder/agent)
   - `plain_language_summary`
3. Update `.sigma/run-track.json` → `completed_steps.community` append `Co1`.
4. If Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json), mirror today's tasks as Linear issues per `steps/_partials/linear-tracking.md`; without Linear, GitHub Issues is the task board. Never the retired SigmaHQ kanban.

---

## Phase D — HITL gate

**Founder must approve:** List active platforms and admin access.

Use AskUserQuestion. Do not start next Run step until approved.

**After approval:** If this was the **last step** in `community`, run `python3 scripts/run-track-continue.py` and offer the next Run Track department per `steps/_partials/run-track-continuation.md`.

---

## Linear (optional — Linear replaced the SigmaHQ kanban 2026-07-11)

See `steps/_partials/linear-tracking.md`. Labels: `run-track`, `community`, `Co1`, `wave:W0` (wave labels are MANDATORY on every created issue).
