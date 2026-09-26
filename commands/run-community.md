---
name: run-community
description: "Run Track orchestrator: Run Track — Community (Co1–Co6) — sequential steps with daily task emission"
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

# /run-community — Run Track — Community (Co1–Co6)

**On start, announce:** "Starting Run Track for community. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **community**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-co-1-platform-audit` | Co1 Platform Health Audit |
| 2 | `/run-co-2-welcome-flow` | Co2 Welcome + First Value |
| 3 | `/run-co-3-content-rhythm` | Co3 Community Content Rhythm |
| 4 | `/run-co-4-moderation` | Co4 Moderation + Escalation |
| 5 | `/run-co-5-feedback-loop` | Co5 Product Feedback Loop |
| 6 | `/run-co-6-advocacy` | Co6 Retention + Advocacy |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-community` resume on next session
</goal>

---

## Trigger

- Default: After M2 or M8 for launch-heavy products (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.community` in `.sigma/run-track.json`. Next step = first missing in: ['Co1', 'Co2', 'Co3', 'Co4', 'Co5', 'Co6']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['Co1', 'Co2', 'Co3', 'Co4', 'Co5', 'Co6'] is in `completed_steps.community`:

1. Announce: "Community Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

# Run Track Continuation (post Build Track)

**When this applies:** After **Step 15** is approved — context engine, agent runtime, and observability contract exist.

**Conductor:** `/gtm` is the natural entry after Step 15 — it owns the launch motion and sequences these Run Tracks (see `steps/step-15-observability-contract` § Go-To-Market handoff). This partial defines the walkthrough engine `/gtm` conducts.

**Command:** `@continue --source=run-track` (or `/continue --source=run-track`)

**Engine:** `python3 scripts/run-track-continue.py`

---

## Gate (same as Step 1 → 1.5 pattern)

Do **not** offer Run Track walkthrough until Build Track gate passes:

| Required artifact | Step |
|-------------------|------|
| `AGENTS.md` | 12 |
| `docs/specs/AGENT-RUNTIME.md` | 14 |
| `docs/observability/INSTRUMENTATION-CONTRACT.md` | 15 |

If missing → tell the founder which Build step to finish. Do not skip to `/run-marketing`.

---

## HITL walkthrough order

After gate passes, offer **one department at a time** (founder must say yes):

1. `/run-legal` — L0 entity formation first (LLC/S-Corp advisor)
2. `/run-finance`
3. `/run-marketing`
4. `/run-sales`
5. `/run-growth`
6. `/run-content`
7. `/run-community`
8. `/run-ops`

When a department completes all steps → run `@continue --source=run-track` again for the next offer.

If founder skips a department → `python3 scripts/run-track-continue.py --mark-declined {dept}`

---

## Step 15 final gate copy

After Step 15 approval, **must** run:

```bash
python3 scripts/run-track-continue.py
```

Present the output verbatim. Use AskUserQuestion:

- **Yes** → invoke the suggested `/run-*` command
- **Not yet** → `@dev-loop` or pause
- **Skip** → mark declined and re-run continue script

---

## Orchestrator completion

When an orchestrator finishes **all** steps in its department, Phase E:

1. Congratulate briefly
2. Run `python3 scripts/run-track-continue.py`
3. Present next department offer — do not auto-start without approval

---

## In-progress resume

If founder returns mid-department, `@continue --source=run-track` should resume the **same** `/run-*` orchestrator at the next missing step id in `.sigma/run-track.json`.
