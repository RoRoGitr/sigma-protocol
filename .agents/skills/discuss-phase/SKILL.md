---
name: discuss-phase
description: "Capture unresolved decisions before planning or feature/PRD work and write a tracked phase brief"
---
---
version: "1.0.0"
last_updated: "2026-03-17"
changelog:
  - "1.0.0: Initial Sigma-native pre-plan discussion surface"
description: "Capture unresolved decisions before planning or feature/PRD work and write a tracked phase brief"
allowed-tools:
  - read_file
  - write
  - list_dir
  - grep
  - glob_file_search
  - run_terminal_cmd
parameters:
  - --topic
  - --phase
  - --feature-id
  - --prd-path
  - --output
---

# /discuss-phase — Pre-Plan Decision Capture

**Mission**  
Turn ambiguity into a tracked planning brief before `plan`, Step 10, or Step 11 run.

## Required output
- `docs/plans/PHASE-BRIEF-<slug>.md`

## Purpose
Use this when the work is directionally clear but key decisions are still soft.

Examples:
- unclear scope boundaries
- unresolved constraints
- feature-level tradeoffs before Step 10 or Step 11
- PRD work that needs decisions locked before planning starts

## Required sections
- `## Goal`
- `## Audience / User Affected`
- `## In Scope`
- `## Out of Scope`
- `## Constraints`
- `## Locked Decisions`
- `## Open Questions`
- `## Risks`
- `## Recommended Next Command`

## Rules
- do not convert this into a full implementation plan
- do not silently answer open questions that need explicit judgment
- keep the brief tracked and reusable by later planning surfaces
- if a matching brief already exists, update it instead of creating random duplicates
