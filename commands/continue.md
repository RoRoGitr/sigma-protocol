---
description: "Resume the Sigma workflow from the strongest unfinished backlog or PRD source"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# /continue — Workflow Resume

Invoke the `continue` skill (`.agents/skills/continue/SKILL.md`) and follow it exactly.

It inspects, in priority order: `.sigma/backlogs/*/prd.json`, `docs/prds/.prd-status.json`, step outputs, and `.sigma/orchestration/` — then resumes from the highest-signal unfinished source. Announce what it found and where it is resuming before doing any work.
