---
name: run-c-6-social-copy
description: "Run Track C6: Social Copy Pack — sixth-grade readable playbook for content"
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

- `20-linkedin-writer`
- `21-twitter-threads`
- `23-story-posts`

<!-- SKILLS-INVOKE:end -->


# /run-c-6-social-copy — Run Track C6: Social Copy Pack

**On start, announce:** "Running Run Track C6: Social Copy Pack. I'll use plain language and give you at most 3 tasks for today."

<goal>
You are the Chief Content Officer Run Track lead for **C6**.

Execute phases **A → D** in order. Do NOT skip HITL gates.

| Phase | Name | Output |
|-------|------|--------|
| A | Load context + module check | Confirmed inputs exist or gaps logged |
| B | Execute domain work (invoke skills) | Draft artifact |
| C | Emit PRD + plain-language sections | `docs/run-track/content/C6-SOCIAL-COPY.md` + backlog entry |
| D | HITL gate | Founder approval before next Run step |

**Primary artifact:** `docs/run-track/content/C6-SOCIAL-COPY.md`  
**Run PRD id:** `C06.001`  
**Output template:** `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`

Read inputs:
- `docs/run-track/content/C3-LONGFORM-SCRIPTS.md`

Also read: `steps/_partials/run-track-common.md` (Run Track rules).
</goal>

---

## Step boundary

- **C6 owns:** LinkedIn, X threads, and story posts.
- **Does NOT own:** atomization map (C7).
- **Parallel OK:** Run while Build Track Step 11 PRDs execute when `.sigma/run-track.json` allows.

---

## Phase A — Context

1. Read `.sigma/run-track.json` and `docs/run-track/BUSINESS-MODEL.json` (if present).
2. If module says **skip C6**, write skip record to backlog with reason; STOP.
3. Verify input files; missing → ask founder or pull from nearest Build Track artifact.

**HITL-A:** Confirm C6 applies to this project.

---

## Phase B — Domain work

Invoke: 20-linkedin-writer, 21-twitter-threads, 23-story-posts

Produce draft using every section in `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`:
- What we're doing / Why it matters
- Your tasks today (≤3 founder items)
- Your agent's tasks
- Done when checklist
- Words you might see glossary (extend if needed)

---

## Phase C — Artifacts

1. Write `docs/run-track/content/C6-SOCIAL-COPY.md` (markdown, sixth-grade readable).
2. Append to `.sigma/backlogs/content/prd.json`:
   - `prd_id`: `C06.001`
   - `run_step`: `C6`
   - `department`: `content`
   - `artifact_path`: `docs/run-track/content/C6-SOCIAL-COPY.md`
   - `daily_tasks` (≤3, owner founder/agent)
   - `plain_language_summary`
3. Update `.sigma/run-track.json` → `completed_steps.content` append `C6`.
4. If Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json), mirror today's tasks as Linear issues per `steps/_partials/linear-tracking.md`; without Linear, GitHub Issues is the task board. Never the retired SigmaHQ kanban.

---

## Phase D — HITL gate

**Founder must approve:** Approve posts before schedule.

Use AskUserQuestion. Do not start next Run step until approved.

**After approval:** If this was the **last step** in `content`, run `python3 scripts/run-track-continue.py` and offer the next Run Track department per `steps/_partials/run-track-continuation.md`.

---

## Linear (optional — Linear replaced the SigmaHQ kanban 2026-07-11)

See `steps/_partials/linear-tracking.md`. Labels: `run-track`, `content`, `C6`, `wave:W0` (wave labels are MANDATORY on every created issue).
