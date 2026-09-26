---
name: run-content
description: "Run Track orchestrator: Run Track — Content (C1–C8) — sequential steps with daily task emission"
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

# /run-content — Run Track — Content (C1–C8)

**On start, announce:** "Starting Run Track for content. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **content**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-c-1-brief-intake` | C1 Brief Intake |
| 2 | `/run-c-2-video-research` | C2 Video Research Pack |
| 3 | `/run-c-3-longform-scripts` | C3 Long-Form Scripts |
| 4 | `/run-c-4-thumbnails-titles` | C4 Thumbnails + Titles |
| 5 | `/run-c-5-shortform-pack` | C5 Short-Form Pack |
| 6 | `/run-c-6-social-copy` | C6 Social Copy Pack |
| 7 | `/run-c-7-atomization-map` | C7 Atomization Map |
| 8 | `/run-c-8-publish-handoff` | C8 Publish Handoff |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-content` resume on next session
</goal>

---

## Trigger

- Default: After M6 (editorial calendar approved) (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.content` in `.sigma/run-track.json`. Next step = first missing in: ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8'] is in `completed_steps.content`:

1. Announce: "Content Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
