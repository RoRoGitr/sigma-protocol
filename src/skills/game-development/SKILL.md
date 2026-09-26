---
name: game-development
description: "Use when adapting Sigma Protocol to a game project. Routes an existing numbered step to conditional game guidance without creating a separate game lifecycle."
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Game Development

Use only when `docs/stack-profile.json` has `projectDomain: "game"`. Missing remains `general`.

## Entry and routing

1. Load `references/catalog.json` in this skill when bundled. In an author checkout, also load `domains/game-development/catalog.json` and use the canonical copy.
2. Select the exact `canonicalSteps` entry for the active Sigma step and each named `workflowId`; load the gateway's generated `references/steps/<step-id>.md` and `references/workflows/<workflow-id>.md` when present.
3. Retain the current step's phases, output path, review gate, company functions, GTM, context, and handoff. Catalog treatment adapts the step; it does not replace it.
4. If the detailed pack is missing, say `BLOCKED: game catalog detail unavailable`; keep the ordinary step work honest and do not invent a complete fallback workflow.

## Record and evidence

Create only selected, revisable game documents with workflow/phase IDs, subject, applicability, scope reason, answers, source revisions, evidence, dependencies, owner/function links, and review status. Unknown applicability remains unresolved; deferment needs a reason.

`PREPARED` means a decision, brief, checklist, or experiment plan exists. Engine runs, imports, renders, builds, meter readings, performance/network results, and player tests require actual attached evidence and review. A bounded experiment already authorized by the active task may be prepared here; Atlas never executes it, while an authorized external harness may.

Route selected work to `game-discovery`, `game-systems-design`, `game-world-design`, `game-art-pipeline`, `game-audio-design`, `game-technical-production`, `game-quality-planning`, or `game-team-synthesis`.

## Sources

Use the catalog's source IDs and links. Classify claims as verified source text, observed evidence, source claim, untested integration, or proposed adaptation. [MDA](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) supports mechanics/dynamics/aesthetics vocabulary; it does not prove a project result.
