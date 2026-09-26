# Design and UX methodology refresh

Date checked: 2026-09-19. Scope: Steps 3, 4, 5, 6, 7, and the design portion of Step 9. This is a research ledger, not a claim that the protocol files have been updated.

## Executive findings

1. The protocol's design sequence is structurally sound: UX intent (3) → flow coverage (4) → prototype evidence (5) → reusable system (6) → state coverage (7) → conversion surface (9).
2. Step 5 and Step 9 still treat Claude Design as the default visual-first tool. That is stale. A tool-neutral visual-first branch should make Pen.dev the first documented implementation-capable option when it is available, with Taste Skill as the design-quality instruction layer. Claude Design, Stitch, or another tool can remain an operator-selected adapter.
3. Pen.dev and Taste Skill are different things. Pen.dev is a design canvas/agent/CLI with `.pen` artifacts and HTML/Tailwind export. Taste Skill is portable agent instruction; its default install is now v2 experimental, and it also publishes a stable `gpt-tasteskill` variant. TasteCode is a separate early-beta desktop harness for agents with a Design Mode; it is not a design artifact format and should not be a required protocol dependency.
4. The local `design-taste` skill is materially older than upstream v2. It has useful anti-slop rules, but its universal bans and GPT-strict randomized plan should be treated as policy candidates, not laws. Upstream v2 makes the agent infer direction from the brief before choosing layout, motion, and density; that is a better Step 3/5 entry contract.
5. Design-token guidance should remain W3C DTCG-based, but the protocol should distinguish the stable 2025.10 format from local export tooling. A command such as `@google/design.md export` must be optional and verified at runtime; it is not the DTCG authority.
6. Accessibility guidance is correctly anchored to WCAG 2.2, but every step should state that WCAG success criteria are the conformance target and techniques are informative. Legal applicability and test evidence must remain separate.

## Source and maturity ledger

| Source | What it actually is | Maturity at cutoff | Protocol use |
|---|---|---|---|
| [Pen.dev docs](https://docs.pen.dev/) | IDE/desktop design canvas, connected agents, `.pen` files, code and image export | Active product; CLI docs updated 2026-09-10; auth and Node 22.19+ prerequisites | Optional visual-first artifact path in Step 5/9; import/export evidence must be committed |
| [Pen.dev CLI](https://docs.pen.dev/for-developers/pen-cli) | Headless create/edit/export CLI; exposes `execute`, `get_app_state`, `read_skill`, `get_style` | Active, but authenticated and provider-dependent | Useful for repeatable generation/export; never imply it replaces human review |
| [Taste Skill docs](https://www.tasteskill.dev/docs) | Portable `SKILL.md` bundle; v2 experimental default plus stable variants | v2 experimental; wording and section numbers can change before v2 stable | Refresh local skill from pinned upstream commit; retain a pinned copy and changelog |
| [Taste Skill repository](https://github.com/Leonxlnx/taste-skill) | Source for design-taste, GPT taste, redesign, image-to-code and related skills | High adoption but no stable v2 tag; upstream is actively changing | Source for instruction patterns, never a substitute for product-specific research |
| [TasteCode](https://github.com/Leonxlnx/tastecode) | Local desktop harness bundling Codex, Claude Code, Grok, terminal, browser, diffs and Design Mode | `0.1.0-beta.7` released 2026-09-18; early beta | Optional host for visual inspection/orchestration; not a Step 5 artifact or gate |
| [DTCG 2025.10](https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/) | JSON interchange format and token semantics | Stable 2025.10 format; W3C-hosted community report | Canonical token contract; validate `$value`, `$type`, aliases, groups, and resolver behavior |
| [WCAG 2.2](https://www.w3.org/TR/wcag/) | Technology-neutral accessibility success criteria | W3C Recommendation | Conformance target; use techniques as implementation guidance, not as the standard |
| [Baymard navigation research](https://baymard.com/research/homepage-and-category-usability) | Original usability research on taxonomy, category navigation, and product finding | Research-backed but ecommerce-specific | Conditional IA evidence for commerce; do not generalize to every product |
| [NN/g UX methods](https://www.nngroup.com/articles/ux-mapping-cheat-sheet/) | Journey, service, task, and experience mapping methods | Practitioner guidance; method choice depends on question | Use to select a map type, not as a mandatory universal diagram |

Designscape searches surfaced the academic **DesignScape** layout-assistance work and the European **Designscapes** service-design project, not a verified current product that should become a Sigma dependency. Keep the name unresolved in the protocol until a canonical URL is supplied.

## Gate-by-gate audit

### Step 3 — UX Design

| Existing decision | Verdict | Evidence required after refresh |
|---|---|---|
| Select platform scope, audience, jobs, journey model, and one Design DNA direction | Retain | Approved UX brief, journey map, platform constraints, and `DESIGN.md`/`ui-profile.json` |
| Use Norman, NN/g, Baymard, WCAG, agentic UI, and cognitive principles as a library | Revise | Record the question each method answers and the decision it changed; mark Baymard as conditional ecommerce evidence |
| Treat the design system as an agent contract | Retain and sharpen | Every non-obvious invariant has a token or explicit rule; no adjectives-only DNA |
| Use Taste's three dials and anti-slop rules | Revise | Dials are hypotheses derived from the brief; no universal bans without product rationale; cite the pinned Taste version |
| Agentic UI patterns | Retain conditionally | If the product has agent behavior, specify intent preview, autonomy, confidence, audit/undo, and escalation; otherwise omit |

The new Step 3 gate should require a **design read**: page/product kind, audience, vibe/reference signals, chosen direction, rejected defaults, and the reason. This directly adopts Taste v2's brief-inference behavior without making Taste itself the source of UX truth.

### Step 4 — Flow Tree

| Existing decision | Verdict | Evidence required after refresh |
|---|---|---|
| Import journeys and architecture before mapping flows | Retain | Source artifact hashes/paths and unresolved assumptions |
| Public landing page is the root entry when one exists | Retain | Entry points, exits, and route destinations in the machine-readable tree |
| Every feature maps to a screen and every control names a destination | Retain | Traceability matrix; modal, drawer, and expanded state IDs where applicable |
| Categories are mutually exclusive fan-out units | Revise | Ownership boundaries and duplicate-screen check; parallelization is a method, not a user requirement |
| Amplitude tag controls later visual treatment | Retain | Per-screen `marketing`/`app` classification and rationale; do not let it redefine UX DNA |

Add explicit branches for agentic operations, if present: preview, approval, execution, interruption, partial completion, refusal, uncertainty, undo, and escalation. These are flow nodes, not merely Step 7 visual states.

### Step 5 — Wireframe Prototypes

| Existing decision | Verdict | Evidence required after refresh |
|---|---|---|
| Direct scaffolding is a valid path | Retain | Stack-matched HTML/native artifact, rendered screenshots, and interaction notes |
| Claude Design is the default visual-first path | Replace | Tool-neutral visual-first path; operator selects Pen.dev, TasteCode Design Mode, Stitch, Claude Design, or another verified tool |
| External visual bundle is visual source of truth | Revise | Human approval receipt, committed artifact, export version, and alignment check against Step 3/4 |
| Generate all flows and review each flow at a gate | Retain | Flow tracker, coverage counts, omissions, and per-flow approval |
| Pen.dev `.pen` artifact can be a visual-first source | Add | `.pen` file, exported PNG/PDF/HTML as appropriate, tool/model/auth metadata, and code handoff mapping |

Recommended portable tracks:

- **Direct:** agent creates stack-native prototype artifacts and renders them.
- **Canvas:** Pen.dev or another verified canvas produces a committed source artifact; the agent imports/export-checks it and generates the flow PRD.
- **Taste-assisted:** Taste Skill supplies design direction and anti-generic checks in either track; it does not create the approval receipt by itself.

TasteCode can be documented as an optional host for a human review loop. Its beta status, provider differences, and local-first security model mean it must never be a required gate or hidden dependency.

### Step 6 — Design System

| Existing decision | Verdict | Evidence required after refresh |
|---|---|---|
| Three token layers: primitive, semantic, component | Retain | DTCG-valid JSON plus token-to-component usage examples |
| DTCG 2025.10 as interchange contract | Retain | Schema/fixture validation; do not call the format a W3C Recommendation |
| Seed from prototypes, then normalize repeated patterns | Retain | Pattern audit and documented exceptions |
| `@google/design.md export` as a seed command | Revise | Treat as optional adapter; verify package and failure path, preserve source values manually if unavailable |
| Taste anti-slop rules as token requirements | Revise | Encode project decisions, not global prohibitions; use a design review for taste-specific checks |
| Reduced motion, contrast, and high contrast as themes | Retain | Tokens plus behavior tests and WCAG evidence |

The gate should validate DTCG syntax and semantic coverage, then inspect rendered representative components. A valid token file alone does not prove visual coherence.

### Step 7 — Interface States

| Existing decision | Verdict | Evidence required after refresh |
|---|---|---|
| States describe behavior, belief, next action, and recovery | Retain | Per-surface state table and transition map |
| Discriminated unions prevent impossible combinations | Retain, Step 8 handoff | State model with implementation type sketch |
| Empty/loading/error/offline/permission coverage | Retain | Screens or state fixtures for each applicable state |
| WCAG 2.2 AA design target | Retain and clarify | Criterion IDs, manual/automated test evidence, applicable law recorded separately |
| Read Claude Design interaction notes | Replace with artifact-neutral import | Read the approved visual artifact's interaction notes, regardless of tool |

Add agent-output states where the UI renders model output: streaming/partial, variable length, tool-running, interrupted, refusal, uncertain/needs verification, retry/regenerate, and stop. These are product behavior requirements when applicable, not a universal AI trend requirement.

### Step 9 — Landing Page design

| Existing decision | Verdict | Evidence required after refresh |
|---|---|---|
| Offer, avatar, message hierarchy, one dominant action, and message match | Retain | Source-backed audience/offer evidence and a falsifiable copy decision |
| MECLABS formula and 5-second rule | Reframe | Heuristics to test, not laws or guaranteed conversion predictors |
| Fresh reference research before visual production | Retain | Dated sources, mechanism notes, and no copied layouts |
| Claude Design visual-first and hybrid tracks | Replace | Same tool-neutral Canvas/Direct tracks as Step 5; Pen.dev is an available option |
| Motion and anti-slop visual review | Retain conditionally | Chosen direction, reduced-motion behavior, performance evidence, and rendered review |
| AI-discovery claim about above-fold structure | Downgrade | Treat as a hypothesis unless supported by current first-party search documentation or experiment data |

The landing-page gate should approve the message and conversion hypothesis before approving a visual direction. A design tool can render and export the page; it cannot validate market motivation, message match, or conversion performance.

## Required local follow-up

1. Replace the Claude Design default language in Steps 5 and 9 with the portable tracks above, preserving Claude Design as an adapter only if the operator selects it.
2. Change Step 6 and Step 7 references from `claude-design/` to a tool-neutral `visual-artifact/` contract, with a migration note for existing bundles.
3. Refresh `.agents/skills/design-taste/SKILL.md` from a pinned upstream commit after diffing v2 experimental and `gpt-tasteskill`; do not overwrite local Sigma-specific safety or evidence rules.
4. Add a Pen.dev adapter note with prerequisites, export formats, authentication, and the human approval boundary. Do not install the CLI as part of the protocol refresh.
5. Add `visual_tool`, `artifact_path`, `export_receipt`, `model/provider`, and `human_approval` fields to the Step 5 tracker schema if the existing schema permits it; otherwise record them in the PRD metadata.
6. Audit all generated `commands/` and `.agents/skills/` mirrors after source edits.

## Sources checked

- https://docs.pen.dev/
- https://docs.pen.dev/for-developers/pen-cli
- https://docs.pen.dev/core-concepts/import-and-export
- https://github.com/Leonxlnx/taste-skill
- https://www.tasteskill.dev/docs
- https://www.tasteskill.dev/guide
- https://github.com/Leonxlnx/tastecode
- https://github.com/Leonxlnx/tastecode/releases
- https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/
- https://www.w3.org/TR/wcag/
- https://www.w3.org/WAI/WCAG22/Understanding/understanding-techniques
- https://baymard.com/research/homepage-and-category-usability
- https://www.nngroup.com/articles/ux-mapping-cheat-sheet/

No edits to protocol sources or global installations were made for this research pass.
