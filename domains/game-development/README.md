# domains/game-development

Reusable game-development methodology data for Sigma Protocol. This directory holds **data only**: the canonical catalog that adapts Steps 0-15 (+1.5, 11.5) and the twenty Atlas stages to any game, plus its human-readable mapping.

| File | Purpose |
|---|---|
| `catalog.json` | Canonical catalog, format `sigma-game-development` version `1.0.0`. Sources, 18 canonical step entries, 20 Atlas stage entries, 12 nested workflows with 93 phases and 400 creator questions. |
| `STEP-MAPPING.md` | Human-readable explanation of every mapping, the twelve workflows, the character phases, what was not adopted from the research inputs, and evidence honesty notes. |
| `README.md` | This file. |

## What this is

A **domain adaptation**, not a separate game track. The Protocol keeps its numbered steps and gates. Atlas keeps all twenty stages, including the operating-company stages 12-14 (company map, people and bot roles, workflows and go-to-market) which every game retains. Game work nests inside existing steps as recognized JSON documents inside ordinary artifacts. The decision and its reasons: `docs/research/game-development/ARCHITECTURE-DECISION.md`. The exact shape: `docs/research/game-development/INTEGRATION-CONTRACT.md`.

## What this is not

- This directory is the canonical methodology data. `scripts/validate-game-method.py` checks coverage and references; `scripts/render-game-method.py` generates portable skill references. Atlas imports a pinned local snapshot with its `scripts/import-game-method.py`; app builds do not read this checkout. Skills and role definitions are authored under `src/skills/game-*` and `src/agents/engineering/game-*.md`. Method files are prepared guidance, not installed runtimes or executed game tools.
- Not a game-quality guarantee. Every phase's `evidenceRequired` field states that a document proves nothing about a game; proof comes from authorized external experiments (playtests, imports, profiler samples) reviewed by a human.
- Not an executor. Atlas prepares briefs, questions, decisions and evidence requirements. It never installs an editor bridge, runs a game tool, writes source, or publishes.

## Design rules the catalog follows

- Solo is the default. Team mode only enables independent, workspace-visible idea packs (one per contributor) and an explicit synthesis that selects exact pack revisions and preserves attribution and dissent. No team size or timebox is forced.
- Engine, genre, platform, multiplayer and monetization are unknown until the creator answers. Conditional work marked not-applicable or deferred always carries a reason. Unknown is never silently skipped.
- Every art mode is first-class: 3D, 2D sprite, vector, text, audio-first, abstract, mixed. Asset phases name their non-3D equivalent.
- The smallest experiment that can fail the actual uncertainty wins. No fixed pillar count, no universal paper prototype, no blanket art or narrative freeze.
- Revisions propagate through existing artifact dependencies; the catalog's `revisionRules` say which downstream documents and receipts a change re-opens.
- Company functions (finance, legal and rights, marketing and GTM, community, support, operations, security, platform relations) are retained for any game, with human and agent owners recorded or a gap named.

## Planned vocabulary used in the catalog

Skills: `game-development`, `game-discovery`, `game-systems-design`, `game-world-design`, `game-art-pipeline`, `game-audio-design`, `game-technical-production`, `game-quality-planning`, `game-team-synthesis`, plus existing repository skills where relevant (for example `deep-research`, `prd-patterns`, `design-tokens`, `accessibility-audit`, `observability`).

Roles: `game-design-lead`, `game-art-director`, `game-technical-director`, `game-quality-lead`, `creator` (the solo creator who may hold every role), plus existing department agents where relevant.

Skill and role definitions are authored under `src/skills/game-*` and `src/agents/engineering/game-*.md`; their portable references are generated from this catalog.

## Validation performed on 2026-09-22

`python3 scripts/validate-game-method.py` checks: JSON parses; exactly 18 canonical IDs in order with `steps/step-*` source paths that exist; exactly 20 Atlas IDs in order; exactly 12 workflow IDs in order; every source ID cited by a step, workflow or phase resolves; no duplicate source, phase or question IDs; every phase dependency is a different phase in the same workflow; no dependency cycles; reserved phases present; skill names resolve in authored or bundled skills. Atlas also validates the exact catalog schema and document lookup structure.

The Atlas helper's own `validateCatalog`, `template`, `createDocument`, `documentReadiness` and `stepContext` were also run against `catalog.json` from the Atlas checkout as a read-only check. See the commission report for the receipts. Running the helper is a validation of catalog shape, not evidence that the Atlas integration is complete.
