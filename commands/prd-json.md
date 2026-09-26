---
description: "Convert Step 5 flow PRDs (prototype mode) or Step 11 PRDs (implementation mode) into the canonical execution backlog JSON"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# /prd-json — PRD → Execution Backlog Converter

Convert authored PRD markdown into the machine-readable backlog that execution tooling consumes.

## Usage

```
/prd-json --mode prototype        # after Step 5 — converts docs/prds/flows/*
/prd-json --mode implementation   # after Step 11 — converts docs/prds/F*.md
```

`--mode` is required. If omitted, ask the user which mode they want before doing anything.

## Contract

| Mode | Input | Output |
|------|-------|--------|
| `prototype` | `docs/prds/flows/*.md` (Step 5 flow PRDs) | `.sigma/backlogs/prototype/prd.json` |
| `implementation` | `docs/prds/F*.md` with `approved: true` in `docs/prds/.prd-status.json` | `.sigma/backlogs/implementation/prd.json` |

## Procedure

1. **Validate inputs exist.** No source PRDs → stop and name the missing step output; do not fabricate a backlog.
2. **Read every source PRD** for the selected mode. In implementation mode, skip PRDs not marked `approved: true` in `docs/prds/.prd-status.json` and list the skipped IDs.
3. **Emit the backlog JSON** conforming to `schemas/execution-backlog.schema.json` — one entry per PRD with id, slug, title, dependencies, acceptance criteria, and complexity. Validate your output against the schema before writing.
4. **Write atomically** to the output path (write temp, then move). Never leave a half-written backlog.
5. **Report**: counts (converted / skipped / failed validation) with the output path.

## HITL checkpoint

After generating, show the backlog summary and get explicit approval before any execution tooling consumes it.
