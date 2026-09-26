# Sigma Protocol - Agent Configuration

## Task tracking & execution (Standard Workflow — 2026-07-12)
- Tasks live in **Linear** (workspace dallion-king, project Dev Tools, team DAL); GitHub is the PR/code loop. New persistent task → Linear issue (wave-labeled).
- Builds run through **Orca**: pull the Linear task → `orca status` → orchestrator session (Fable/Claude side or Sol/Codex side per model lanes) → `~/.local/bin/orca-dispatch-task` per task (worktree waves, depth-1 workers) → gates (Greptile review + Codex cross-model + coordinator) → PR → merge → cleanup per the ownership ledger.
- Loop spec: `~/.claude/references/loop-registry.md` (Core-5: BUILD, TICK+TIMER, CLEANUP, PR-SWEEP, GAP). Constitution: `~/AGENTS.md`.

## Relevant Skills

These skills live in `src/skills/` (and the bundled `.agents/skills/` pool). Invoke them at the phase listed in each step's `SKILLS-INVOKE` block:

| Skill | Why it applies here |
|---|---|
| `prd-patterns` | Step 11 PRD generation; refresh sprints apply here |
| `sprint-patterns` | Pipeline gate enforcement is the methodology's execution backbone |
| `decisions-patterns` | decisions.md convention is part of Step 12 context engine output |
| `curriculum-patterns` | Methodology steps are a curriculum; prerequisite ordering applies |
| `gotchas-patterns` | Cross-step edge cases surface here first |

Full skill registry: `src/skills/` and `.sigma/indexes/skills-index.json`.

## Overview

Sigma Protocol is a platform-agnostic Steps 0–15 product development methodology (+ conditional 1.5 and 11.5) for AI-assisted development.

This `AGENTS.md` defines the active workflow for the repository. Canonical sources:

- **Steps:** `steps/` → rendered to `commands/` via `scripts/sync-steps-to-platforms.sh`
- **Skills:** `src/skills/<skill>/SKILL.md`
- **Agents:** `src/agents/<agent>.md`
- **Runtime:** `.sigma/runtime/`, `.sigma/memory/`, `.sigma/tools/` (Step 14)

Per-vendor mirror trees (Claude Code, Codex, Cursor) are **not** part of the OSS install contract. See `docs/PLATFORMS.md`.

### Value Equation (Hormozi)

Every feature must maximize:
```
Value = (Dream Outcome x Perceived Likelihood) / (Time Delay x Effort & Sacrifice)
```

## Quick Start

```bash
# Start Codex with the default Sigma profile
codex --profile sigma-dev

# Begin the workflow
codex "Run step 1 ideation for [your product idea]"

# Continue through the workflow
codex "Continue to step 2"
```

## Active Workflow

The active Sigma workflow is:

```
Step 0: Environment Setup
    |
Step 1: Ideation -> MASTER_PRD.md
    |
Step 1.5: Offer Architecture (if monetized)
    |
Step 2: Architecture -> docs/architecture/ARCHITECTURE.md
    |
Step 3: UX Design -> docs/ux/UX-DESIGN.md + UI profile outputs
    |
Step 4: Flow Tree -> Screen inventory, transitions, and bulletproof gates
    |
Step 5: Wireframes -> per-flow prototype PRDs under docs/prds/flows/
    |
Run /prd-json --mode prototype -> .sigma/backlogs/prototype/prd.json
    |
Step 6: Design System -> docs/design/DESIGN-SYSTEM.md + docs/tokens/design-tokens.json
    |
Step 7: Interface States -> docs/states/STATE-SPEC.md
    |
Step 8: Technical Spec -> docs/technical/TECHNICAL-SPEC.md
    |
Step 9: Landing Page (optional)
    |
Step 10: Feature Breakdown -> docs/implementation/FEATURE-BREAKDOWN.md
    |
Step 11: PRD Generation -> docs/prds/F01.001-<slug>.md (ID = F<wave:02d>.<feature:03d>) + docs/prds/.prd-status.json
    |
Run /prd-json --mode implementation -> .sigma/backlogs/implementation/prd.json
    |
Step 11.5: Task Handoff -> .sigma/backlogs/<mode>/TASKS.md
    |
[Optional] /prd-orchestrate -> .sigma/orchestration/*
    |
Step 12: Context Engine -> `AGENTS.md` + `.sigma/memory/` bridge
    |
Step 13: Skillpack Generator -> `src/skills/<category>/<skill>/SKILL.md` + `src/agents/<category>/<agent>.md`
    |
Step 14: Agent Runtime Bootstrap -> `docs/specs/AGENT-RUNTIME.md` + `.sigma/runtime/` + `.sigma/memory/` + `.sigma/tools/`
    |
Step 15: Observability Contract -> `docs/observability/INSTRUMENTATION-CONTRACT.md`
```

Active workflow language is limited to Steps `0-15` plus conditional Steps `1.5` and `11.5`.

Removed pseudo-step labels and legacy step-style aliases are not part of the active workflow vocabulary.

## Brownfield Entry Points

Use these when the repo already has meaningful code before you push deeper into the numbered steps:

- `$map-codebase` -> writes `docs/ops/CODEBASE-MAP.md` and `docs/ops/codebase-map.json`
- `$discuss-phase` -> writes `docs/plans/PHASE-BRIEF-<slug>.md`
- `$plan --phase-brief=<path>` -> injects a tracked phase brief into implementation planning

Brownfield flow:

```text
existing repo
  -> $map-codebase
  -> Step 0
  -> $discuss-phase (when decisions are still soft)
  -> $plan / Step 10 / Step 11
```

<!-- step12-runtime-context:start -->
## Step 12 Runtime Context (Managed)

Step 12 writes Sigma's runtime context into the native surfaces each coding agent actually uses.

Codex runtime surfaces:
- `AGENTS.md`
- `.codex/config.toml`
- `.agents/skills/`
- `.codex/skills/` *(compatibility adapter only)*

Claude Code runtime surfaces:
- `CLAUDE.md` — tracked thin pointer to this file (AGENTS.md is the single instruction surface)
- optional `CLAUDE.local.md` for operator-local overrides (gitignored)
- `.claude/settings.json`
- `.claude/hooks/`
- `.claude/agents/`
- `.claude/skills/` — operator-local install overlay, generated by `scripts/install-claude-code.sh`, never tracked

Step 13 supplies authored skills and agents. Step 14 owns `.sigma/tools/`, `.sigma/runtime/`, and `.sigma/memory/`.

**Built-in agent DNA (Ponytail / YAGNI):** the implementation/build agents Sigma generates (backend, frontend, mobile, client, devops, lead-architect, observability, qa) ship with the Ponytail lazy-senior DNA baked into their definitions — the best code is the code never written: a 6-rung ladder (need it? → stdlib → native platform → installed dep → one line → minimum code), deletion over addition, boring over clever, with intentional shortcuts marked by `ponytail:` comments. No external plugin is required; the DNA travels with the agents. The full skill lives at `.agents/skills/ponytail/SKILL.md` and is listed in those agents' `skills:`.

Optional Codex execution-policy files under `.codex/rules/*.rules` are repo policy files, not Step 12 outputs.
<!-- step12-runtime-context:end -->

## Available Skill Groups

### Core Step Skills

Invoke step skills directly in Codex with `$step-1-ideation` style names.

| Skill | Description |
|-------|-------------|
| `$step-1-ideation` | Discovery-first PRD with Value Equation framing |
| `$step-2-architecture` | Architecture profile, boundaries, tradeoffs, and handoffs |
| `$step-3-ux-design` | UX strategy, design DNA, and user flows |
| `$step-4-flow-tree` | Structural flow mapping and screen inventory |
| `$step-5-wireframe-prototypes` | Per-flow prototype PRDs |
| `$step-6-design-system` | Design system, themes, tokens, and component styling logic |
| `$step-7-interface-states` | Full state coverage, recovery patterns, and accessibility behavior |
| `$step-8-technical-spec` | Implementation blueprint, API/data/security/testing patterns |
| `$step-9-landing-page` | Landing-page strategy, copy, and template mapping |
| `$step-10-feature-breakdown` | Feature shaping, PRD eligibility, and sequencing |
| `$step-11-prd-generation` | Implementation-ready feature PRD generation |
| `$step-12-context-engine` | Native runtime context synthesis |
| `$step-13-skillpack-generator` | Project skill adapter generation |
| `$step-14-agent-runtime-bootstrap` | Agent runtime bootstrap |

### Execution Backlog Commands

| Command | Description |
|---------|-------------|
| `/prd-json --mode prototype` | Convert Step 5 flow PRDs into `.sigma/backlogs/prototype/prd.json` |
| `/prd-json --mode implementation` | Convert Step 11 PRDs into `.sigma/backlogs/implementation/prd.json` |
| `/prd-orchestrate` | Build dependency-aware orchestration plans under `.sigma/orchestration/` |
| `python3 scripts/sigmahq-sync-run-track.py --dept <dept>` | **LEGACY / FROZEN (2026-07-11).** SigmaHQ board-sync is retired — task tracking moved to **Linear** (workspace `dallion-king`). This bridge script and its `.sigma/integrations/sigmahq/` outputs are kept only for historical event state; do NOT rely on it as a live board sync. |

**Task tracking is Linear** (workspace `dallion-king`), not SigmaHQ — the old board bridge below is FROZEN. The SigmaHQ bridge outputs under `.sigma/integrations/sigmahq/` are legacy generated local event state (superseded 2026-07-11). Historically, successful step runs auto-synced workspace ensure, review cards, and Step 10 feature cards; Step 10 only promotes PRD-worthy rows from `docs/implementation/FEATURE-BREAKDOWN.md`, Step 11 only promotes PRDs whose `docs/prds/.prd-status.json` entry has `approved: true`. New work files Linear issues (wave-labeled, `LINEAR_API_KEY` in Keychain); never `gh issue create` for tracking.

### Audit Skills

| Skill | Description |
|-------|-------------|
| `$security-audit` | Security review |
| `$accessibility-audit` | Accessibility review |
| `$performance-check` | Performance review |
| `$gap-analysis` | Post-implementation gap analysis |

### Development Skills

| Skill | Description |
|-------|-------------|
| `$discuss-phase` | Capture unresolved planning decisions into a tracked phase brief |
| `$implement-prd` | Implement a PRD feature |
| `$plan` | Create an implementation plan |

### Operations Skills

| Skill | Description |
|-------|-------------|
| `$map-codebase` | Create the brownfield codebase map before deeper planning |
| `$pr-review` | Pull request review |
| `$sprint-plan` | Sprint planning |
| `$status` | Project status check |

## Codex Skill Layout

Codex is the default runtime target for Sigma skills.

### Official path

```text
.agents/skills/<skill>/SKILL.md
```

### Compatibility adapter

```text
.codex/skills/<skill>/SKILL.md
```

Use the `.codex/skills/` adapter only when the local runtime still expects it.

### Authored source

```text
src/skills/<category>/<skill>/SKILL.md
src/agents/<category>/<agent>.md
```

### Supported categories

- `steps`
- `ops`
- `audit`
- `dev`
- `deploy`
- `marketing`
- `orchestration`
- `platform`
- `deprecated`

### Legacy compatibility

```text
.codex/skills/<skill>/SKILL.md
```

Use the compatibility adapter only when the local Codex runtime still requires it.

### Machine-readable indexes

Sigma publishes generated indexes under `.sigma/indexes/`:
- `.sigma/indexes/commands-index.json`
- `.sigma/indexes/skills-index.json`
- `.sigma/indexes/agents-index.json`

## Named Profiles

Profiles are operator-local. Use `codex --profile <name>` only after confirming that profile exists in the effective configuration. A documentation example does not change the host's permissions, model or reasoning effort. See `docs/CODEX-GUIDE.md` for current setup guidance.

## MCP Tools

These integrations are optional. Use the host's available search, documentation and file tools; do not block a step merely because a named MCP server is absent:

| Server | Capabilities |
|--------|-------------|
| Firecrawl | Web scraping and crawling |
| EXA | Semantic search and code context |
| Ref | Documentation search and URL reading |
| Context7 | Library documentation lookup |
| Task Master AI | PRD parsing and backlog generation |

## Claude Code Alignment

Claude Code is a fully supported runtime. `CLAUDE.md` (tracked) points here — AGENTS.md is the single instruction surface for every runtime; Claude-specific runtime controls live in `.claude/settings.json`, `.claude/hooks/`, and `.claude/agents/`. Run `scripts/install-claude-code.sh` once per machine to generate the operator-local `.claude/skills/` overlay and command imports.

## HITL Checkpoint Policy

Every numbered step is human-in-the-loop. Each phase inside a step ends with a `<HARD-GATE>` requiring a real user answer before advancing, unless the user explicitly delegated those gates for this run. `AskUserQuestion` means the host's supported question mechanism: Claude Code's named tool when available, an appropriate Codex interaction tool, or a normal question followed by ending the turn. Tool availability never counts as approval. The canonical rules are inlined as the **HITL Gate Contract** (`steps/_partials/hitl-gate-policy.md`):

- **Ask every gate; never collapse or batch them.** One gate per phase, at its boundary.
- **A non-answer is not approval.** If `AskUserQuestion` times out or the user is away, PAUSE and wait — do not proceed on best judgment, do not draft the remaining phases. Silence ≠ yes.
- **Gates are skippable only on an explicit, up-front "run without stopping" from the user in this run.** Being unattended or short on time is never that opt-in.
- **Honor recorded authorization.** After explicit unattended approval, finish the authorized local work without repeated permission requests. Record assumptions and delegated decisions; do not invent user answers or extend approval to publishing, spending or production changes.

Key checkpoints (in addition to every phase gate):
- Step 1: approve value proposition before architecture
- Step 2: approve architecture before UX design
- Step 5: approve wireframes before design system
- Step 11: approve PRDs before implementation
- Step 15 → `/gtm`: approve the move into go-to-market before the Run Tracks begin
- Execution backlog outputs: approve generated backlog and orchestration artifacts before implementation continues

## Quality Gates

Each step defines its own verification threshold and required checks. Use that step's schema; `80+/100` is not a universal override of a stricter gate. A rubric score does not replace evidence or human approval.

Gate checks include:
- completeness
- consistency
- value alignment
- human sign-off

## Notes

- Codex reads `AGENTS.md` as the project-wide instruction surface.
- Codex project config (`.codex/config.toml`) is operator-local, generated on install — never tracked.
- Optional Codex execution-policy files may live in `.codex/rules/*.rules`, but Step 12 does not generate them.
- Codex runtime baselines, repo-local override patterns, and smoke tests live in `docs/CODEX-GUIDE.md`.
- Canonical machine backlogs live in `.sigma/backlogs/prototype/prd.json` and `.sigma/backlogs/implementation/prd.json`.
- Archived legacy execution guidance lives only under `docs/archive/`.

See [https://github.com/Dallionking/sigma-protocol-public](https://github.com/Dallionking/sigma-protocol-public) for broader documentation.

## Optional Tooling


### Sprint Execution Protocol
All implementation follows the Sprint Execution Factory defined in `@dev-loop`.
Every sprint team includes `sigma-devils-advocate` and `sigma-qa` as mandatory final gates.
Sprint branches merge to `dev`. Release PRs merge `dev` to `main`.

## Execution standard (non-negotiable)
Treat every change as audited line-by-line an hour after commit. A cut corner is a shipped defect.
- Evidence over assertion: no "done/passing/fixed" without the command and its real output in the same message. No output = not done.
- Never fake completion: no unrun tests reported green, no test deleted/skipped/loosened to pass, no mocked value presented as real, no silent scope-narrowing.
- No stubs shipped as final (TODO/pass/.../NotImplemented/fake data) unless requested; if stubbed, list each one under `STUBS SHIPPED:`.
- Done = acceptance criteria met + applicable verification passes + no unrequested placeholders. For a behavioral bug, show the failing reproduction and passing regression check. For documentation or prompt changes, verify contracts, links, rendering and affected runtime behavior. Run build/lint when applicable; record an explicit reason for a skipped check. Do not manufacture tests that merely restate prose.
- Loop/round exits only on an external check. Subagents return evidence; the orchestrator re-verifies against the diff before accepting.
- Close every task with PASS / MISS / SKIP per item, with proof.

## Source-first impact review

Use repository source search and available host language tools to trace definitions, callers/imports, consumers, and relevant tests. Report impact and uncertainty before editing; inspect the diff and run applicable checks before committing. Preserve existing review, approval, money-path, and release gates.

## Game-development adaptation

Game projects use the existing numbered methodology. `/game-development` is a domain entry point; Step 1 also asks what is being built. Record `projectDomain: "game"` in `docs/stack-profile.json` to load the conditional method. Missing/general projects retain their current flow.

The canonical source is `domains/game-development/catalog.json`: all 18 Protocol entries, an explicit 20-stage Atlas mapping, 12 nested workflows and 93 planning phases. See [the game guide](docs/GAME-DEVELOPMENT.md) and [step mapping](domains/game-development/STEP-MAPPING.md). Solo is the default; team mode preserves independent idea packs and explicit synthesis. Company, ownership, business, GTM, operations, context and handoffs remain part of the same system.

Game skills and role definitions prepare decisions and bounded external experiment briefs. Atlas never executes Blender/engine work or activates an agent from these records. A reviewed plan is distinct from an executed/validated asset, playable build, performance measurement or target import.

Author the catalog once, run `python3 scripts/validate-game-method.py`, then `python3 scripts/render-game-method.py`; use the normal step render/index checks. Generated skill references are portable snapshots. This repository update does not install skills globally.
