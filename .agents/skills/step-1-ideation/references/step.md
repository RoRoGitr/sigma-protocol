---
description: "Step 1: Ideation → MASTER_PRD — interactive product discovery with Hormozi Value Equation, JTBD, Design Tree interview, and HITL gates"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --research-depth
---

<!-- HITL-GATE-POLICY:start -->
## ⛔ HITL Gate Contract (read before running any phase)

This step is **human-in-the-loop**. Every `<HARD-GATE>` below is a **hard stop**. Obey these rules exactly — they override any default to "keep going."

**Runtime adapter:** `AskUserQuestion` below means the host's supported user-question mechanism, not a required tool identifier. Use an available structured question tool only when it permits this kind of question. Otherwise ask in a normal response and end the turn at the gate. A tool that cannot collect approval is not an approval substitute. Frontmatter controls are host-specific: supported `allowed-tools` can preapprove tool access. Tool access does not authorize actions outside the user's scope or satisfy a phase, release or production approval.

1. **Ask, then wait.** At each `<HARD-GATE>` you MUST call `AskUserQuestion` and receive an **actual answer from the user** before starting the next phase. Producing the analysis for a phase is allowed; *advancing past its gate* is not, until the user answers.
2. **A non-answer is NOT approval.** If `AskUserQuestion` returns no response, times out, or says the user is away — **PAUSE the step and wait**. Do not "proceed on best judgment," do not draft the remaining phases, do not infer approval from silence. Save what you have, tell the user the step is paused at Phase _X_ awaiting their answer, and stop. Re-ask when they return.
3. **One gate per phase — never collapse them.** Ask each phase's gate at its own phase boundary (A, then B, then C…). Do not batch several phases into a single question, and do not run multiple phases and ask once at the end. The founder decides at every boundary.
4. **The only way to skip gates** is an explicit, up-front instruction from the user in *this* run — e.g. "run all phases without stopping," "autonomous mode," or "don't ask me, just draft it." Absent that explicit opt-in, gates are mandatory. Being mid-task, low on time, or unattended is never such an opt-in.
5. **Everything before an approval is a draft.** Nothing a gate guards is "locked" or "done" until the user has approved it at that gate.

**Explicit unattended runs:** Record the user's opt-in and its scope once. Complete authorized phases and local verification without repeatedly asking for the same permission. Mark decisions made under that delegation as assumptions or delegated decisions, not fabricated user answers. Unattended drafting does not grant release, spending, destructive-action or production authority. A genuine missing decision may block one part while independent authorized work continues.

> If you find yourself about to write the next phase without a user answer to the current gate, STOP — that is the exact failure this contract prevents.
<!-- HITL-GATE-POLICY:end -->

<!-- GAME-DOMAIN:start -->
## Conditional game-domain adaptation

Apply this section only when `docs/stack-profile.json` records `projectDomain: "game"`. A missing value means `general`; do not infer a game domain from product language. Keep this step's number, phases, outputs, gates, business functions, GTM, context, and handoff intact.

Read the selected entry from the canonical game-development catalog when it is available. Use only the workflows and questions applicable to the recorded game profile. If applicability is unknown, record it as unresolved; defer or skip work only with a reason. The catalog adapts this step. It does not create an alternate numbered sequence.

- Default to a solo creator. Contributor idea packs are separately authored, workspace-visible planning inputs; synthesis is an explicit creator decision that preserves selected revisions, attribution, disagreement, and rejected alternatives.
- Treat prototypes, art, audio, engine setup, imports, builds, performance measurements, multiplayer checks, and playtests as external execution. This Protocol step may prepare a decision, brief, checklist, or evidence requirement. Mark execution evidence `NOT-EXECUTED` until real evidence is attached and reviewed.
- Choose the smallest experiment that tests the current uncertainty. Do not require paper prototypes, outside testers, fixed art freezes, an engine, a team size, a schedule, or a downstream production method unless the creator records why it applies.
- Keep claims classified: source text, observed evidence, source claim, untested integration, or proposed adaptation. Preserve the catalog source IDs and linked research when creating game artifacts.

<!-- GAME-DOMAIN:end -->

<!-- SKILLS-INVOKE:start -->
## Required skills — invoke the live skills (do NOT rely on embedded summaries)

This step's output quality depends on these skills. **Invoke each via the host's installed Skill catalog by name at the relevant phase.** If the host cannot resolve that name, read the project source at `src/skills/<skill>/SKILL.md`, then the bundled `.agents/skills/<skill>/SKILL.md` when present. Do not rely on embedded summaries.

- `game-development` — conditional when `projectDomain: "game"`; select this step's catalog entry and applicable workflow

- `hormozi-frameworks` — Phase D (Value Equation Assessment)
- `brainstorming` — Phase A (Discovery Interview)
- `deep-research` — Phase B (Evidence-Backed Research)
- `icp-definition` — Phase A (Target Users)
- `map-codebase` — Preflight when `docs/ops/CODEBASE-MAP.md` exists or Step 0 recommended brownfield entry
- `companion-system` — Phase A/C when product includes gamification, collectibles, or trophy/achievement UX

Read `docs/references/CURATED-COMPONENT-LIBRARIES.md` in Phase C when locking platform hints. Read `templates/boilerplates/catalog.json` when greenfield to record `boilerplateCandidate` in `docs/stack-profile.json`.

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
- `game-discovery` — Phase A/B for an explicitly selected game project; use the current catalog questions and evidence rules.

<!-- SKILLS-INVOKE:end -->


# /step-1-ideation — Discovery-First PRD Bootstrapping

**On start, announce:** "Running Step 1: Product Discovery. I'll walk you through 5 phases with approval gates. No files are written until Phase D."

<goal>
You are the Product Discovery Lead. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Interactive Discovery Interview | Locked decisions on problem, user, outcome, scope |
| B | Evidence-Backed Research | Market analysis + evidence register |
| C | Lightweight Feasibility Preview | Data/integration/risk preview |
| D | Specification Development | MASTER_PRD.md draft |
| E | Review, Hardening & Handoff | Finalized docs + Step 1.5 trigger |

Final Outputs: `docs/specs/MASTER_PRD.md`, `docs/specs/constitution.md`, `docs/stack-profile.json`, `docs/research/market-analysis-{PROJECT}.md`, `docs/prds/.prd-status.json`

Quality gate: 95+/100 on verification schema.
</goal>

---

## Step Boundary

- **Trigger:** Run after Step 0 completes. Requires `.sigma/runtime-baseline.json` from Step 0.
- **Step 1 owns:** problem discovery, target users, evidence, scope, success criteria, assumptions, risks, feasibility preview.
- **Step 1 does NOT own:** pricing, guarantees, offer stacking, monetization architecture → **Step 1.5**.
- **Trigger Step 1.5** when the product is monetized or requires pricing/credits/subscriptions before architecture.
- **Fallback:** If Step 0 data is missing, prompt user to run Step 0 first or continue with defaults and label all stack assumptions.

---

## Linear Tracking (Conditional)

<!-- linear-tracking: canonical task-tracking block. Linear is primary when detected; GitHub Issues is the default fallback board (the SigmaHQ kanban was retired 2026-07-11). Included by steps under their own heading. -->

Task tracking has two supported boards — use whichever the user has:

**Linear (primary when detected).** Linear is configured when BOTH hold:
- `security find-generic-password -s LINEAR_API_KEY -w` returns a key (GraphQL endpoint `https://api.linear.app/graphql`, header `Authorization: <key>`, no Bearer prefix)
- `runtime-baseline.json` shows `linear.project: "<Linear project name>"` (each repo maps to exactly one Linear project; team is derived from the project)

When configured, mirror step progress as issues in `linear.project` via GraphQL `issueCreate` / `issueUpdate` (see Step 0 → Linear Operations Reference for the concrete queries): create a tracking issue when the step starts (state In Progress) and move it to Done when the step's primary output lands.

**GitHub Issues (default fallback).** When Linear is not configured, GitHub Issues is the task board — create wave-labeled issues in the project repo (`gh issue create --label "wave:W0" --title "…"`) and close them as work lands. This is a first-class path, not a degraded one: many protocol users run entirely on GitHub. File-based artifacts (`TASKS.md`, `.prd-status.json`) remain the offline fallback where a step defines one.

**Wave labels are MANDATORY on every created issue — an unlabeled issue is a defect** (same labels on either board). Planning/status issues (Steps 0–10, Run Track) carry `wave:W0`; execution issues carry their build-sequence wave (`wave:W1`, `wave:W2`, …) from Step 10 sequencing / Step 11.5 waves. Also label issues with the step name (e.g. `step-3`) so later steps can find them.

Never write task tracking to the retired SigmaHQ kanban (`~/.commandboard`, frozen 2026-07-11) — that board is dead for everyone. GitHub always owns the PR/branch/review/merge loop regardless of which board you track on; when Linear is connected, its issues two-way-sync to GitHub once the operator enables per-repo issue sync in the GitHub<->Linear integration (PR-linkback only today).

**Step-specific issues (when Linear is configured):**
- Phase A start: create issue "Step 1: Product Discovery in progress" — labels `step-1`, `wave:W0`, state In Progress.
- On MASTER_PRD.md completion (Phase D): move the tracking issue to Done and create "Step 1: MASTER_PRD.md complete" — labels `step-1`, `milestone`, `wave:W0`.

---

## Discovery Frameworks

Use to sharpen the PRD. Skip any that don't apply — don't pad.

### Hormozi Value Equation

Value = (Dream Outcome x Perceived Likelihood) / (Time Delay x Effort & Sacrifice)

- Dream Outcome vague → product is vague.
- Perceived Likelihood weak → needs proof, onboarding, or narrower user.
- Time Delay long → define faster first-value moment.
- Effort & Sacrifice high → simplify workflow or reduce switching costs.

Use this as a value-pressure heuristic, not a measured law. Record the evidence or test that makes each term credible.

### Jobs-to-be-Done

For each core use case: functional/emotional/social job, trigger, current workaround, why it's unacceptable.

Distinguish [Christensen's progress-in-context theory](https://www.christenseninstitute.org/theory/jobs-to-be-done/) from switching interviews and [Ulwick's quantitative Outcome-Driven Innovation](https://strategyn.com/jobs-to-be-done-template/). Choose the method the evidence supports; interview anecdotes do not establish statistically ranked unmet needs.

### Evidence Hierarchy

1. Direct customer/user quotes → 2. Observed behavior → 3. Market data → 4. Team inference.
Unverified claims must be labeled as assumptions.

### Continuous Discovery (Teresa Torres)

Keep discovery and delivery connected in small, project-proportionate loops. Map the desired outcome to opportunities, candidate solutions, and assumptions. Customer interviews and observed behavior are customer evidence; AI-generated personas, summaries, or simulated interviews can help prepare research but are never customer evidence.

### Scope Discipline

Every PRD defines: in scope, explicitly out of scope, deferred to Step 1.5 or Step 2. Vague scope = fake certainty = bad architecture.

---

## Phase A — Interactive Discovery Interview

### Preflight (auto, no user interaction)

1. Run `date +"%Y-%m-%d"`.
2. Read `.sigma/runtime-baseline.json` — extract runtime, research mode, boilerplate, stack integrations.
3. Read `.sigma/boilerplate.json` and `docs/stack-profile.json` if present.
4. Ensure `docs/specs/`, `docs/research/`, `docs/prds/` exist.
5. If `research_mode = blocked` → stop and tell user. If `reduced` → continue with assumption labels.
6. If boilerplate present → treat as implementation baseline, don't re-ask stack questions.

### Discovery Interview (sequential — one decision at a time)

Use the **Design Tree** pattern: resolve each decision before branching to the next.
Use **AskUserQuestion** where options can be predefined. For open-ended questions, ask directly.
Do NOT dump all questions at once. One question per turn. Lock the answer before moving on.

**Decision 1: The Idea**
Ask directly: "What are we building? Is it a game or a general product? Why does it matter?" Do not ask the domain question again when `projectDomain` is already recorded.
Listen. Clarify if vague. Lock the core concept.

If the creator selects `game`, record `projectDomain: "game"` in `docs/stack-profile.json`. For `general` or a missing domain, preserve existing behavior and do not add a new game record. For a game, invoke `game-discovery` and ask only the selected catalog's profile questions before the ordinary problem interview. Default creator mode to solo unless the creator chooses a contributor mode.

**Decision 2: The Problem**
Use AskUserQuestion: "What type of problem is this solving?"
Options: [Workflow is too slow/manual, Existing tools are fragmented, No good solution exists, Cost of current solution is too high, Other]
Then ask: "What happens if the user does nothing — what's the cost of inaction?"

**Decision 3: The User**
Use AskUserQuestion: "Who is the primary user?"
Options: [B2B teams, Solo professionals, Consumers, Developers/engineers, Internal team, Other]
Then ask: "How are they solving this today, and why is that unacceptable?"

**Decision 4: The Outcome**
Ask directly: "What's the concrete before/after transformation? What does the user's life look like after this works?"
Then ask: "What's the first moment of value — when do they know it's working?"

**Decision 5: Constraints & Scope**
Use AskUserQuestion: "What platforms must this support?"
Options: [Web only, Mobile only, Web + Mobile, Desktop, API/CLI, Other]
Then ask: "Any compliance, privacy, locked-in vendors, or timeline constraints?"

**Decision 6: Monetization Signal**
Use AskUserQuestion: "Is this product monetized?"
Options: [Yes — subscriptions/tiers/credits, Yes — one-time purchase, Not yet — explore later, No — internal/OSS/free, Other]
Lock the answer — this determines whether Step 1.5 runs.

### Decision Lock Summary

After all 6 decisions, present a summary table:

| Decision | Locked Answer |
|----------|---------------|
| Idea | [answer] |
| Problem | [answer] |
| Primary User | [answer] |
| Desired Outcome | [answer] |
| Platform / Constraints | [answer] |
| Monetization | [answer] |

Also show the working job/context, current workaround, trigger, evidence status, and the first assumption to test. Label each item as customer evidence, observed behavior, market evidence, team inference, or synthetic assistance.

<HARD-GATE>
Do NOT proceed to Phase B until the user approves the Decision Lock Summary.
Do NOT write any files before this gate.
Use AskUserQuestion: "Discovery direction locked. Approve and move to research?"
Options: [Approve — proceed to research, Revise — I want to change something]
Approval means the problem, user, outcome, scope, and first evidence gap are explicit enough to research; it does not validate the underlying assumptions.
</HARD-GATE>

---

## Phase B — Evidence-Backed Research

### Research Queries (directive — run these, don't improvise)

Based on locked decisions, construct and execute specific queries:

1. **Competitors:** Search `"[problem domain] alternatives 2025 2026"` — find direct competitors, substitutes, status quo workarounds
2. **User pain:** Search `"[primary user] [problem] frustration OR complaint OR review"` — find real user quotes and pain evidence
3. **Timing:** Search `"[domain] market trend 2026"` — find why this matters now
4. **Integration norms:** Search `"[platform] [domain] best practices stack"` — find what the market expects

Use the agent's built-in **web search** for discovery. For library/API specifics, read official documentation via web search or repo-local docs — do not require paid MCP search APIs.

### Evidence Register (mandatory — build during research, not after)

```markdown
| Claim | Evidence type | Source | Date | Confidence | What changed in the decision | Next test |
|-------|---------------|--------|------|------------|-------------------------------|-----------|
| [Claim] | Customer / observed / market / inference / synthetic assistance | [URL/source] | [YYYY-MM-DD] | High/Med/Low | [Decision or scope impact] | [Smallest useful test] |
```

If `research_mode = reduced`, state at the top what evidence tiers are missing.

Before feasibility, create a light opportunity map and assumption register. For each material assumption, name the evidence gap, owner, smallest proportionate test, and the result that would change scope or positioning. Do not manufacture customer proof from synthetic research.

When AI synthesizes an opportunity tree from interviews, retain source links and check missing groupings, poorly framed needs, and children that merely repeat their parent. With no real interviews, label the map as hypotheses. If using a model judge, calibrate it against human-labeled error and non-error examples representative of actual inputs; recheck calibration when inputs change. Track regressions alongside the target defect. Use structural checks and bounded repair where useful, inside this phase's existing evidence review. [Torres's September 16 case study](https://www.producttalk.org/4-new-evals-and-16-experiment-variants/) informs this conditional check; its experiment counts and vendor are not Sigma requirements.

### Market Analysis Output

Write `docs/research/market-analysis-{PROJECT}.md`:
1. Problem landscape
2. Existing solutions / competitors / substitutes
3. Key user pain evidence (with quotes where found)
4. Gaps or weaknesses in the market
5. Risks to differentiation
6. Sources with URLs

Write this as a sharp competitive brief — no filler. No "In today's rapidly evolving landscape." Start with what exists, what's broken, and what the gap is.

<HARD-GATE>
Do NOT proceed to Phase C until user approves research findings.
Use AskUserQuestion: "Research complete. How do you want to proceed?"
Options: [Approve research — move to feasibility, Pivot — the research changed my thinking, Dig deeper — I need more on a specific area]
Approval means the evidence has changed, supported, or weakened named decisions, and the remaining assumptions have an owner and next test.
</HARD-GATE>

---

## Phase C — Lightweight Feasibility Preview

Preview the technical shape without turning Step 1 into Step 2.

#### Boilerplate catalog (required when no `.sigma/boilerplate.json`)

Do **not** guess template names. Read the machine catalog and rank options:

1. **Read** `templates/boilerplates/catalog.json` (framework + product templates).
2. **Read** `templates/boilerplates/_shared/module-catalog.json` for module IDs when discussing features.
3. **Read** `docs/references/integration-packs-catalog.md` for integration pack summaries.
4. **Map** platform + product type from `docs/stack-profile.json`, `MASTER_PRD.md`, or Phase A/C decisions:

| Signal | Prefer catalog entries |
|--------|------------------------|
| Mobile app, IAP | `expo-mobile`, `products/mobile/*` |
| Full SaaS web | `nextjs-saas`, `tanstack-saas` |
| AI-first / real-time | `nextjs-ai`, `products/ai-tools` |
| Self-host / portable | `nextjs-portable` |
| Courses / gamification | `products/mobile/learning-platform` |
| Trading / fintech | `products/mobile/fintech` |

5. **If** `.sigma/boilerplate.json` already exists → document inherited template in the environment/architecture report; **skip** AskUserQuestion picker.
6. **If** greenfield (no boilerplate, no root `package.json`) → present top 3 catalog matches via AskUserQuestion with `id`, `stack`, and `use_when`.
7. **On selection** → record `boilerplateCandidate` in `docs/stack-profile.json` and instruct user to run `@new-project --template=<id>` (or clone product path from catalog `path` field) before Step 2 locks architecture.
8. **Status gate** — omit catalog entries with `"status": "stub"` unless user explicitly wants a stub shell; prefer `"status": "ready"` or `"status": "built"`.

When greenfield, record `boilerplateCandidate` in `docs/stack-profile.json` from catalog ranking. Read `docs/references/CURATED-COMPONENT-LIBRARIES.md` when feasibility touches charts, gamification, or mobile vs web component stacks.

### Data Entity Preview

| Entity | Purpose | Relationships | Complexity |
|--------|---------|---------------|------------|
| users | [Purpose] | [Relations] | Standard |

### Integration Preview

| Service | Purpose | Required Now? | Risk |
|---------|---------|---------------|------|
| [Service] | [Reason] | Yes / Later | Low/Med/High |

### Risk Flags

Identify highest-impact delivery risks: data sensitivity, compliance, external dependencies, complex workflows, real-time/background requirements.

Carry unresolved customer, monetization, and differentiation assumptions forward with an owner and a decision consequence. Step 2 receives these as constraints, not as settled facts.

### Stack Profile Seed

Create or update `docs/stack-profile.json`. Preserve boilerplate decisions. Don't guess undecided fields.

```json
{
  "project_mode": "custom-project",
  "platform": "web",
  "frontend": "undecided",
  "backend": "undecided",
  "database": "undecided",
  "auth": "undecided",
  "payments": null,
  "hosting": "undecided"
}
```

<HARD-GATE>
Do NOT proceed to Phase D until user approves feasibility preview.
Use AskUserQuestion: "Feasibility preview complete. Approve?"
Options: [Approve — write the PRD, Flag concerns — need to discuss risks, Revise scope — feasibility changed my thinking]
Approval means the technical shape is sufficient for a PRD draft and unresolved feasibility or commercial risks are visible; it is not an architecture decision.
</HARD-GATE>

---

## Phase D — Specification Development

Write `docs/specs/MASTER_PRD.md`. Reference the locked decisions from Phase A and evidence from Phase B directly — do not reinvent or contradict them.

```markdown
# [Project Name] - Product Requirements Document
**Version:** 1.0 | **Date:** {TODAY} | **Status:** Draft

## Executive Summary
[2-3 paragraphs: what, who, why now — derived from Decision Lock]

## Problem Statement
### The Problem
[From Decision 2 + research evidence]

### Why It Matters Now
[From Phase B timing research]

## Target Users
### Primary User
[From Decision 3 — role, context, behaviors, goals, frustrations]

### Secondary Users / Stakeholders
[Who else is affected]

## Jobs / Core Use Cases
| Job / Use Case | Current Friction | Desired Outcome |
|----------------|------------------|-----------------|

## Opportunity Map & Assumption Tests
| Desired Outcome | Opportunity | Candidate Solution | Assumption | Evidence Type | Next Test | Owner | Scope Decision if Disconfirmed |
|-----------------|-------------|--------------------|------------|---------------|-----------|-------|-------------------------------|

## Value Equation Assessment
- **Dream Outcome:** [From Decision 4]
- **Perceived Likelihood:** [What makes the outcome believable]
- **Time Delay:** [First moment of value from Decision 4]
- **Effort & Sacrifice:** [What friction must be removed]
- **Evidence and proof plan:** [What supports each term, what remains a hypothesis, and how it will be tested]

## Evidence Register
[From Phase B — copy or summarize]

## Product Scope
### In Scope (P0 — MVP must-ship)
[Committed scope from Decision Lock — bullet points, not prose]

### In Scope (P1 — should-have, post-MVP)
[Features that improve the product but aren't blocking launch]

### Out of Scope
[Explicit exclusions — these are product decisions, not optional notes]

### Do NOT Build
[Negative requirements — things the AI must explicitly avoid building. Examples: "Do NOT add social login before core auth works." "Do NOT build admin dashboard in v1."]

## Suggested File Structure
[Directory layout for the product — helps downstream agents organize code]
```
src/
  app/           # Routes and pages
  components/    # Shared UI components
  lib/           # Business logic, utilities, API clients
  types/         # TypeScript types and interfaces
docs/
  specs/         # PRDs and architecture docs
  research/      # Market analysis and evidence
```
[Adapt to the actual stack and platform from Decision 5]

## Build Order
[Explicit sequential phases — AI agents need this to avoid building everything at once]
1. **Foundation:** Auth, database schema, core data models
2. **Core features:** [P0 features in dependency order]
3. **Integration:** [External services, APIs]
4. **Polish:** [P1 features, UX refinement]

## Success Metrics
| Metric | Baseline | Target | Time Horizon |
|--------|----------|--------|--------------|

## Business Model / Monetization Trigger
- **Monetization in scope:** [From Decision 6]
- **If yes:** [Summary only — architecture deferred to Step 1.5]
- **If no:** [Why Step 1.5 can be skipped]

## Assumptions and Risks
| Assumption / Risk | Evidence Type | Confidence | Impact | Owner | Next Test | Scope Decision if Disconfirmed |
|-------------------|---------------|------------|--------|-------|-----------|-------------------------------|

## Open Questions
- [Question]

## Decision Table
| Decision | Status | Owner | Next Step |
|----------|--------|-------|-----------|

## Lightweight Feasibility Preview
[From Phase C — entity preview, integration preview, delivery risks]

## Step 1.5 Trigger Decision
- **Run Step 1.5 now?** [Yes / No]
- **Why:** [Signals from Decision 6 + research]
```

### Write `docs/specs/constitution.md` (alongside MASTER_PRD.md)

`constitution.md` is a versioned, **immutable** document of the project's foundational principles. It is created once in Step 1 and checked (never re-written) by every subsequent step. Amendments require explicit operator approval recorded in the document's changelog.

```markdown
# [Project Name] — Constitution
**Version:** 1.0.0 | **Date:** {TODAY} | **Status:** Ratified

## Purpose
Immutable principles that constrain every feature, PRD, and implementation decision.
These override convenience. When a PRD conflicts with the constitution, fix the PRD.

## Principles
1. [Principle 1 — e.g., "User data is never sold or shared with third parties"]
2. [Principle 2 — e.g., "The product must be operable with keyboard-only navigation"]
3. [Principle 3 — e.g., "No dark patterns; subscriptions may always be cancelled in one step"]
[Add 3-7 principles total — fewer is better; principles must be testable/falsifiable]

## What This Means in Practice
[One concrete example per principle of what a violation looks like]

## Amendment Process
Amendments require: (1) operator approval, (2) documented rationale, (3) version bump.
|Version | Date | Change | Approved By |
|--------|------|--------|-------------|
| 1.0.0  | {TODAY} | Initial ratification | [operator] |

## Downstream Use
- Step 11: Every PRD is checked against this document before acceptance (Constitution Check Gate)
- Step 12: Synthesized into AGENTS.md as project constraints
```

**Constitution rules:**
- 3-7 principles maximum — if you need more, merge or trim. A 20-principle constitution is ignored.
- Each principle must be **falsifiable** — "be good" is not a principle. "Never store raw payment card numbers" is.
- Version with semver. Minor bumps (`1.1.0`) = clarifications. Major bumps (`2.0.0`) = principle change.
- The file is committed alongside `MASTER_PRD.md` and tracked in version control.

### Writing Rules

- Every claim traces to evidence register or is labeled assumption.
- Scope in/out decisions are product decisions, not optional notes.
- Do not invent pricing tiers. Do not turn this into architecture. Do not leave assumptions unlabeled.

### Writing Standards (embedded — apply to ALL Step 1 outputs)

- No stock AI phrases: "Let's dive in", "Here's the thing", "In today's landscape", "At its core", "Game-changing", "Seamless", "Robust", "Ecosystem", "Leverage", "Delve", "Navigate challenges", "Unlock potential"
- Start with the topic, not a sweeping industry statement that narrows down
- Do not end sections with grander restatement than the content warrants
- Commit to claims or don't make them — no "might/could potentially" hedging on every line
- No breathless enthusiasm — not everything is "fascinating", "remarkable", or "transformative"
- No rhetorical questions as section transitions
- No "Final thoughts" or "Key takeaways" section headers
- Do not use the structure: "[Broad claim]. But [complication]. Here's [resolution]."
- Write like a product leader with conviction, not a median of all writing on the internet

---

## Phase E — Review, Hardening & Handoff

### Mandatory: Run $holes

Before the final checkpoint, invoke `$holes` to find:
- Weak evidence or unsupported claims
- Vague scope or ambiguous requirements
- Missing assumptions or unaddressed risks
- Contradictions between sections

Fix findings before presenting for approval. If `$holes` is unavailable, manually review against the verification schema.

### Required Files

| File | Location |
|------|----------|
| MASTER_PRD.md | docs/specs/ |
| constitution.md | docs/specs/ |
| stack-profile.json | docs/ |
| market-analysis-{PROJECT}.md | docs/research/ |
| .prd-status.json | docs/prds/ |

### Success Criteria

- [ ] Step 0 state was read and used
- [ ] Problem is evidence-backed or labeled assumptions
- [ ] Opportunity map distinguishes customer evidence from synthetic assistance
- [ ] Material assumptions have a proportionate next test, owner, and scope consequence
- [ ] Target users are specific enough to act on
- [ ] Out-of-scope items are explicit
- [ ] Success metrics are measurable
- [ ] Risks and open questions documented
- [ ] Monetization only summarized, not over-designed
- [ ] Step 1.5 trigger decision is explicit
- [ ] constitution.md written with 3-7 falsifiable principles and version 1.0.0
- [ ] $holes pass completed
- [ ] User approved the final PRD
- [ ] Linear tracking issues created (when configured)

### Step 1.5 Trigger Rules

**Run Step 1.5** when: subscription/tiered/credits/usage monetization in scope, billing affects schema, free/premium entitlements matter, or offer packaging materially affects product definition.

**Skip Step 1.5** when: internal/OSS/not monetized, monetization undefined and shouldn't constrain architecture, pricing out of scope.

<HARD-GATE>
FINAL GATE — Do NOT proceed without explicit approval.
Use AskUserQuestion: "Step 1 complete. What's next?"
Options based on Decision 6:
- If monetized: [Proceed to Step 1.5 — Offer Architecture, Skip Step 1.5 — go to Step 2, Revise PRD]
- If not monetized: [Proceed to Step 2 — Architecture, Revise PRD]
Approval means the PRD records its evidence, assumptions, and follow-up tests well enough for downstream work; it does not convert hypotheses into facts.
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 1 Verification Schema

### Required Files (20 points)

| File | Path | Min Size | Points |
|------|------|----------|--------|
| Master PRD | docs/specs/MASTER_PRD.md | 4KB | 5 |
| Constitution | docs/specs/constitution.md | 300B | 3 |
| Stack Profile | docs/stack-profile.json | 200B | 3 |
| Market Analysis | docs/research/market-analysis-*.md | 1KB | 5 |
| PRD Status | docs/prds/.prd-status.json | 50B | 4 |

### Required Sections in MASTER_PRD.md (45 points)

| Section | Points |
|---------|--------|
| Executive Summary | 5 |
| Problem Statement | 6 |
| Target Users | 6 |
| Jobs / Core Use Cases | 5 |
| Value Equation Assessment | 5 |
| Evidence Register | 5 |
| Product Scope + Out of Scope | 5 |
| Success Metrics | 4 |
| Assumptions and Risks | 4 |

### Content Quality (25 points)

| Check | Points |
|-------|--------|
| Claims source-backed or labeled assumptions | 6 |
| At least one competitor/substitute analysis | 4 |
| Target users specific enough to act on | 4 |
| Success metrics are measurable | 4 |
| Step 1.5 trigger decision is explicit | 4 |
| Reduced research mode disclosed when applicable | 3 |

### Approval & Handoff (10 points)

| Check | Points |
|-------|--------|
| Research checkpoint approved | 5 |
| Final PRD approved (after $holes pass) | 5 |
| Linear tracking issues created (when configured) | 1 |

**Passing score:** 95/100
</verification>

$END$
