---
name: map-codebase
description: "Map an existing codebase into Sigma's planning model and write the canonical brownfield map outputs"
---
---
version: "1.0.0"
last_updated: "2026-03-17"
changelog:
  - "1.0.0: Initial Sigma-native brownfield codebase mapping surface"
description: "Map an existing codebase into Sigma's planning model and write the canonical brownfield map outputs"
allowed-tools:
  - mcp_ref_ref_search_documentation
  - mcp_ref_ref_read_url
  - mcp_exa_web_search_exa
  - mcp_exa_get_code_context_exa
  - read_file
  - write
  - list_dir
  - glob_file_search
  - grep
  - run_terminal_cmd
parameters:
  - --depth
  - --focus
  - --markdown-output
  - --machine-output
---

# /map-codebase — Brownfield Codebase Mapping

**Mission**  
Map an existing repo into Sigma's planning model so later steps stop guessing about stack, structure, integrations, conventions, and readiness.

## Required outputs
- `docs/ops/CODEBASE-MAP.md`
- `docs/ops/codebase-map.json`

## Purpose
Use this before deeper planning on existing repos when you need:
- stack clarity
- entrypoint clarity
- auth/data/integration visibility
- a Sigma readiness baseline

## Core rules
- prefer facts from the repo over guesses
- summarize the repo as it exists today
- keep the output decision-useful, not consultant filler
- do not rewrite Sigma methodology docs here
- this command is for planning context, not execution dispatch (Linear/Orca own that)

## Required sections in `CODEBASE-MAP.md`
- `## Repo Summary`
- `## Stack Profile`
- `## Entrypoints`
- `## Data / Auth / Integration Surfaces`
- `## Conventions`
- `## Hotspots`
- `## Sigma Readiness`
- `## Recommended Next Steps`

## Recommended next-command behavior
- brownfield repo with missing Sigma docs -> recommend `sigma retrofit`
- brownfield repo with ambiguous feature work -> recommend `$discuss-phase`
- PRD-ready repo -> recommend `sigma plan`
