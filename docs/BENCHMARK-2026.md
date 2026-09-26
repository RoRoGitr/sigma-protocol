# Sigma Protocol — 2026 Benchmark & Gap Analysis

**Date:** 2026-06-29
**Scope:** Every workflow step (0-15 + conditional 1.5, 11.5) benchmarked against current (2026) best practice, plus a global-skills sync, a vendor-neutral Step 0 tooling gate, and a rebuilt artifact contract.
**Method:** Read-only research first (Exa/Firecrawl/Ref), then surgical canonical edits, then full gate suite. Sources are linked per finding.

---

## Verdict up front

The methodology was **already very current** going into this sweep — April Dunford's 2nd edition (Feb 2026), Chargebee pricing archetypes (March 2026), DTCG 2025.10 tokens, WCAG 2.2, C4 model, EARS, MASVS, and OpenTelemetry `gen_ai.*` spans were all present. This was a **precision refresh + sync + reorganization**, not a rewrite.

Four genuinely new 2026 shifts were woven in, the skills pool was synced/imported, Step 0 was vendor-neutralized, and the artifact contract was rebuilt.

**Verdict legend:** CURRENT = no change needed · REFRESH = small targeted edit · GAP = missing concept added.

---

## The four 2026 shifts integrated

1. **Spec-Driven Development (SDD)** is now a named movement (Spec-Kit, BMAD, OpenSpec). Sigma's PRD already *is* an executable spec (goal/mission/slices + Eval Contract + verifier gate), but Steps 8/11 never named the paradigm. Added explicit SDD framing + Addy Osmani context-budget spec-sizing. — [Addy Osmani: good specs for agents](https://addyosmani.com/blog/good-spec/)
2. **Agentic Design Systems / Generative UI** (Brad Frost): components are now consumed by agents, not only humans; design systems become machine-assembled contracts. Added the "design system as agent contract" principle to Steps 3 and 6. — [Brad Frost: Agentic Design Systems](https://www.youtube.com/watch?v=Vg78K3t9KYc), [UX Tigers 2026 predictions](https://www.uxtigers.com/post/2026-predictions)
3. **Native CSS scroll-driven animations + bento + anti-AI/human-made** (Figma/Moburst 2026): Step 9 led with GSAP only. Added native CSS `scroll-timeline` as the progressive-enhancement default, bento layouts, and the anti-AI human-made angle. — [Figma web design trends](https://www.figma.com/resource-library/web-design-trends/)
4. **Memory-type taxonomy** (episodic / semantic / procedural / hierarchical, OS-tiered retention): Steps 12/14 memory layer now uses the standard vocabulary on top of importance-scoring + TTL/eviction mechanics. — [Memory Engineering for AI Agents 2026](https://medium.com/@mjgmario/memory-engineering-for-ai-agents-how-to-build-real-long-term-memory-and-avoid-production-1d4e5266595c)

---

## Per-step benchmark

| Step | Verdict | Best-practice anchor (2026) | Action taken |
|------|---------|------------------------------|--------------|
| 0 Environment Setup | REFRESH | Vendor-neutral tooling; graceful degradation | Rewrote "One Brain doctrine" → optional, vendor-neutral **shared memory layer**; generalized RTK → optional **output/token optimizer**; `runtime-baseline.json` gains `memory_layer` + `token_optimizer` |
| 1 Ideation | CURRENT | Hormozi Value Equation, JTBD, Design Tree | No change (verified `constitution.md` is the real second output, not phantom `FEATURES.md`/`USP.md`) |
| 1.5 Offer Architecture | CURRENT | Dunford 2nd ed, Brunson, Moesta, Chargebee | No change |
| 2 Architecture | REFRESH | Fowler/Evans/Brown/Ousterhout; ADRs as agent-readable records | ADR section reframed as **agent-readable decision records** aligned to `decisions.md` |
| 3 UX Design | REFRESH | Norman/NN-g/Baymard + Generative UI | Added **Design System as Agent Contract (Generative UI)** section |
| 4 Flow Tree | CURRENT | Structural completeness / zero-omission | No change |
| 5 Wireframe Prototypes | CURRENT | Track A (Claude Design) + Stitch + native Expo/SwiftUI | No change |
| 6 Design System | REFRESH | DTCG 2025.10, OKLCH, Style Dictionary v4 | Added **The Token File Is the Agent-Consumable Contract** |
| 7 Interface States | CURRENT | Discriminated unions, React 19 `useOptimistic`, ARIA live, EAA/ADA dates | No change |
| 8 Technical Spec | GAP | Spec-Driven Development; EARS acceptance contract | Added **Spec-Driven Development (the spec is an executable contract)** + spec-sizing |
| 9 Landing Page | GAP | Native CSS `scroll-timeline`, bento, anti-AI | Reordered to native CSS scroll-driven first; added layout + anti-AI/human-made sections |
| 10 Feature Breakdown | CURRENT | Patton story mapping, Shape Up appetites, INVEST | No change |
| 11 PRD Generation | GAP | SDD executable spec; context-budget specs | Added **The PRD Is an Executable Spec** + spec-sizing; unified ID to `F01.001-<slug>` |
| 11.5 Task Handoff | CURRENT | Vendor-neutral TASKS.md + /next-task contract | No change (added to validate-methodology + FILE-PATH-REFERENCE) |
| 12 Context Engine | REFRESH | Memory-type taxonomy; AGENTS.md ≤200-line discipline | Renamed Brain → **Memory Context Synthesis**; vendor-neutral shared memory layer; memory-type tagging |
| 13 Skillpack Generator | REFRESH | Agent Skills frontmatter standard | Folded in Phase C skills sync; `eval-runner.sh` ownership clarified |
| 14 Agent Runtime Bootstrap | REFRESH | MS orchestration patterns, MAESTRO, OWASP LLM06 | Added memory-type taxonomy + OS-tiered retention; vendor-neutralized memory paths |
| 15 Observability Contract | CURRENT | OpenTelemetry `gen_ai.*` / `tool.*` spans | No change (added to validate-methodology + FILE-PATH-REFERENCE) |

---

## Phase B — vendor neutrality

Step 0's vendor-neutral directive was contradicted by hardcoded branded references in Steps 12/14 (`~/.claude/brain`, "Global AI Brain", `brain-status`, `install-brain.sh`, `sigma-brain`, RTK). All were replaced with a generic, **optional shared memory layer** and **optional output/token optimizer** vocabulary. Private-tool references in skills were scrubbed from `src/skills/`.

---

## Phase C — skills sync & import

- **Refreshed 14** `src/skills` from newer global versions; re-stripped version/changelog tails; standardized section headers.
- **Imported 14** curated skills (13 methodology-relevant + `ponytail`): `architecture-template`, `sprint-patterns`, `agent-goal-skill`, `self-healing-loop`, `gotchas-patterns`, `decisions-patterns`, `curriculum-patterns`, `audit-verify-prd`, `audit-step-verify`, `sentry`, `shadcn`, `macos-design`, `expo-cinematic-motion`, `ponytail`.
- **Preserved** Sigma-ahead skills (`frontend-design`, `hormozi-frameworks`, `mobile-app-security`, `writing-clearly`).
- **Deployed** all canonical `src/skills` to the `.claude/skills` runtime.
- **Registered** every new skill in `.claude/lib/agent-skill-registry.json` with `trigger_keywords`, `department`, `owning_agents`, `sigma_steps`, `quality_tier`.
- **Resolved** the `ponytail` validation failure by importing it into canonical `src/skills` (it was agent-referenced but absent).

---

## Phase D — artifact contract rebuild

- **Rebuilt** [`docs/FILE-PATH-REFERENCE.md`](FILE-PATH-REFERENCE.md) as the authoritative Steps 0-15 + 11.5 output tree, every path verified against each step's `Required Outputs` block.
- **Resolved the orchestration split:** `.sigma/orchestration/*` is canonical; deprecated `docs/prds/swarm-*` / `SWARM-PLAN.md` (fixed in COMMANDS.md, QUICK-REFERENCE.md, FILE-PATH-REFERENCE.md).
- **Unified PRD IDs** to `F01.001-<slug>.md` (`F<wave:02d>.<feature:03d>`) across AGENTS.md, COMMANDS.md, WORKFLOW-OVERVIEW.md, QUICK-REFERENCE.md, FILE-PATH-REFERENCE.md.
- **Updated** `steps/validate-methodology` from Steps 0-14 → 0-15 + 11.5; added checks for `constitution.md` (Step 1), `.sigma/standards.json` + `DNA-REFERENCES.md` (Step 3), Step 11.5 TASKS.md, and Step 15 observability outputs.
- **Documented ownership** drift guards: `.sigma/tools/` (Step 14 owns; Step 13 writes only `eval-runner.sh`), `CLAUDE.md.example` (hand-authored, never overwritten), `docs/evals/*-golden.json` (Step 11 authors, Step 14 appends), `product/flows/flow-tree.json` vs `docs/flows/*` (intentional machine/human split).
- **Removed phantom Step 1 outputs** (`FEATURES.md`, `USP.md`, `NFRS.md`, `DEV-READINESS.md`, `SUCCESS-METRICS.md`) from the reference.

---

## Gate results (this sweep)

| Gate | Result |
|------|--------|
| `lint-deprecated-step-refs.sh` | PASS |
| `lint-step-parity.sh` | PASS — 18 canonical step files identical across claude-code / codex / factory-droid |
| `audit-platform-parity.sh` | PASS (after regenerating mirrors via `sync-steps-to-platforms.sh`) |
| `validate-cascade.mjs` | PASS — 13 departments, 62 agents, 79 registry skills, 19 step skill blocks |
| `validate-skills.mjs` | PASS — 66 skills frontmatter valid, 53 agent skill-refs resolve |
| `validate-mirrors.mjs --strict` | PASS — 66 canonical skills, no corruption, no drift, no missing across `.claude`/`.codex`/`.factory`/`.agents` |
| `pytest tests/` | PASS — 82 passed |

Mirrors were regenerated from canon — step mirrors via `sync-steps-to-platforms.sh` (80 files), skill runtime mirrors via direct re-mirror (184 files across the 4 runtime surfaces), and platform skill mirrors via `sync-skills-to-platforms.sh --force` (cursor/factory/antigravity/codex). No mirror was hand-edited.

### Post-implementation gap fix (caught by `@gap-analysis` sweep)

The initial sweep regenerated **step** mirrors but left **skill** mirrors stale: the 14 newly imported + 14 updated skills existed in `src/skills` and `.claude/skills` but were missing/stale in `.codex/skills`, `.factory/skills`, and `.agents/skills` (`validate-mirrors.mjs` reported 5 drift + 179 missing, non-strict). A re-mirror pass brought all 66 canonical skills faithfully into all four runtime surfaces; `validate-mirrors.mjs --strict` now passes. This is the only gap the post-implementation analysis found.

---

## Residual / deferred

- The `design.md` lint (`npx @google/design.md lint DESIGN.md`) is a **per-product** gate; this methodology repo authors no product `DESIGN.md`, so there is nothing to lint here. It remains a Step 3 output gate for downstream projects.
- Optional department-persona skills (`source-command-*`) and `b2b-cold-call-screenplay` / `crm-objection-router` were left out of the curated import pending an explicit call — they are sales-team niceties, not methodology-critical.
