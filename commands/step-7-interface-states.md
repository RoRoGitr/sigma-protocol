---
version: "1.1.0"
last_updated: "2026-09-19"
description: "Step 7: Interface States → STATE-SPEC.md — full state catalog, recovery logic, announcements, focus behavior, and accessibility for every screen"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --depth
  - --mobile
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

- `frontend-design`
- `design-tokens`
- `audit-accessibility-audit`
- `ux-psychology-pro`
- `macos-design`

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-7-interface-states — Interface States, Recovery & State Accessibility

**On start, announce:** "Running Step 7: Interface States. I'll define how every screen behaves when reality happens — loading, errors, empty data, permissions, offline, and recovery."

<goal>
You are the State Architecture Lead. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Context & State Surface Inventory | Stateful surfaces identified + system rules imported |
| B | Universal State Model & Per-Flow Coverage | State taxonomy + per-screen state mapping |
| C | Recovery Patterns & Accessibility | Recovery rules + announcements + focus management |
| D | Cross-Feature Patterns & State Transitions | Shared patterns + transition rules |
| E | Output, Hardening & Handoff | STATE-SPEC.md + Step 8 handoff |

Required Output: `docs/states/STATE-SPEC.md`

Optional (when justified): `docs/states/MICRO-INTERACTIONS.md`, `docs/states/MOBILE-STATES.md`, `docs/states/ACCESSIBILITY-STATES.md`

Quality gate: 95+/100 on verification schema.

**Core rule:** If Step 7 is weak, the app can be technically correct and still feel broken. Every screen must have its states defined.

**AI-native output rule:** STATE-SPEC.md is consumed by AI agents in Steps 8 and 11. State definitions must be structured as tables/matrices — not prose descriptions.
</goal>

---

## Trigger

**Run after Step 6 (Design System) is approved.** Step 7 requires Step 6 design tokens and system rules to define state behavior that inherits from the design system. If Step 6 outputs are missing, stop and inform the user.

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
- Step start: create issue "Step 7: Interface States" — labels `step-7`, `wave:W0`, state In Progress.
- Milestone issues as sections land: "Step 7: State model mapped" and "Step 7: Recovery & a11y rules" — labels `step-7`, `wave:W0`.
- On STATE-SPEC.md completion: move the tracking issue to Done.

---

## Step Boundary

- **Step 7 owns:** universal state taxonomy, per-flow/per-screen state coverage, first-user vs seeded-demo vs populated vs unauthorized behavior, recovery patterns, state microcopy expectations, announcements, focus behavior, cross-feature state patterns.
- **Step 7 does NOT own:** motion system (Step 6), design tokens (Step 6), animation library choices (Step 8), implementation patterns (Step 8), stack-specific state management (Step 8).
- **Do NOT** redefine the motion system or prescribe implementation libraries. Define BEHAVIOR, not implementation.

Step relationship: Step 5 shows prototype screens → Step 6 defines system rules → **Step 7 defines every real-world state those screens can enter** → Step 8 implements.

---

## State Principles

### States Are Product Behavior, Not Edge Cases
Every state answers:
- What the user believes is happening
- What the system is actually doing
- What the user can do next
- How the user recovers if something goes wrong

### Make Invalid States Unrepresentable
Model states as discriminated unions, not boolean flags. Don't allow `isLoading=true AND hasError=true` — use explicit state families: `idle | loading | success | error`.

```typescript
// ❌ Boolean flags allow impossible states
{ isLoading: true, isError: true, data: "x" }

// ✅ Discriminated union — each state has only relevant data
type State =
  | { type: "idle" }
  | { type: "loading"; startedAt: number }
  | { type: "success"; data: T }
  | { type: "error"; error: Error; retryCount: number }
```

This is the implementation pattern Step 8 should enforce. Step 7 defines WHICH states exist; this principle ensures agents model them correctly.

### Optimistic UI Pattern
For actions where 99% succeed (likes, saves, toggles), show success instantly and sync in background:
- Store previous state before optimistic update
- On failure: full rollback (revert to previous), partial rollback (revert failed items), or merge with server response
- Always provide a visible error recovery path when rollback occurs

### Empty States Drive Activation (NN/g)
Empty states are onboarding opportunities, not dead ends:
- **Communicate system status** — "No records" is only valid if the system finished loading. Don't show "No records" while still fetching.
- **Provide learning cues** — "Star your favorites to list them here" teaches functionality in context
- **Offer direct pathways** — Action buttons and documentation links, not just explanatory text

### Accessibility target and applicable law
- Use WCAG 2.2 AA as this protocol's design target; confirm the actual legal standard, covered entity/product, exceptions and jurisdiction for the project.
- The [EU Accessibility Act](https://commission.europa.eu/strategy-and-policy/policies/justice-and-fundamental-rights/disability/european-accessibility-act-eaa_en) covers specified products and services. Do not apply a single EU-wide penalty to every website.
- The [US DOJ Title II fact sheet](https://www.ada.gov/resources/2024-03-08-web-rule/), checked 2026-09-19, reports extended deadlines of April 26, 2027 for public entities serving 50,000+ people and April 26, 2028 for smaller entities/special districts. This rule concerns state/local government web content and mobile apps, not every private business.
- Record legal applicability separately from accessibility test results; automated checks alone do not establish compliance.

### Distinguish Unavailable States Clearly
These are NOT the same — don't blur them:

| State | Why the user can't act | Can they recover? | Next best action |
|-------|----------------------|-------------------|-----------------|
| **Disabled** | Precondition not met | Yes — complete precondition | Show what's needed |
| **Read-only** | Viewing without edit rights | No — by design | Navigate to editable context |
| **Locked** | Feature or resource locked | Maybe — upgrade, wait, or request | Show unlock path |
| **Unauthorized** | No permission | Yes — sign in or request access | Auth flow or contact admin |
| **Unavailable** | Feature doesn't exist yet or is down | No — system limitation | Communicate timeline or alternative |
| **Offline** | No network | Yes — when connection returns | Queue actions, show cached data |

### State Changes Should Reduce Uncertainty
- Loading should reassure (skeleton > spinner for structured content)
- Empty states should guide (explain what belongs here + next action)
- Errors should calm and recover (what happened + what to do)
- Success should confirm and direct (what worked + what's next)

---

## Phase A — Import Context & State Surface Inventory

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read Step 5 flow PRDs: `docs/prds/flows/*/FLOW-*.md`, `docs/prds/flows/PRD-SUMMARY.md`.
3. **Detect Step 5 track visual artifacts:**
   - If `docs/prds/flows/*/visual-artifact/` exists (Canvas), read `VISUAL-ARTIFACT.md` and any actual interaction notes/export. Use them as source material only; do not infer absent state behavior.
   - If `docs/prds/flows/*/screens/` exists (Direct), inspect the artifact appropriate to its platform to identify the states actually shown.
   - Legacy imported visual fixtures may be read for migration, but new Step 5 work uses `visual-artifact/` or `screens/`.
   - If visual evidence is unavailable, record the gap and derive requirements from the approved Step 4 transitions and Step 5 PRD rather than reporting visual coverage.
4. Read Step 6: `docs/design/DESIGN-SYSTEM.md`, `docs/tokens/design-tokens.json`.
- Read `.sigma/standards.json` if present (emitted by Step 3). Use its `dna_conformance` assertions as hard constraints for this step's outputs. If missing → record an advisory in the step report ("DNA standards file absent — Step 3 may not have completed; DNA gate will skip") and continue; do not invent substitute DNA rules.
#### Curated component library reference (read before UI stack decisions)

Before offering component-library, chart, or gamification options:

1. **Read** `docs/references/CURATED-COMPONENT-LIBRARIES.md` (web, mobile, charts, trophies, boilerplate map).
2. **Map platform** → default library from the doc's tables; **do not** offer Tamagui as default on Expo + NativeWind stacks.
3. **Record** in `docs/stack-profile.json`:
   - `componentLibrary` — e.g. `shadcn/ui`, `react-native-reusables`
   - `chartsLibrary` — e.g. `@bklit/charts` (mobile), `tremor` or `recharts` (web)
   - `gamification.reference` — when PRD includes XP/achievements/trophies
4. **Invoke skills** at decision time (not from memory):
   - Web/desktop React → `shadcn`
   - Mobile Expo → `rn-component-library`, `react-native-patterns`
   - Gamification / collectibles → `companion-system` (in addition to learning-platform refs)
5. Read `.sigma/runtime-baseline.json`. If `research_mode = blocked` → stop.

### Classify state-heavy surfaces

Scan all Step 5 flow PRDs and categorize:
- **Data surfaces** — lists, dashboards, tables, feeds (need: empty, loading, error, populated)
- **Form surfaces** — inputs, creation flows (need: validation, submission, success, error)
- **Destructive actions** — delete, cancel, revoke (need: confirmation, success, undo)
- **Permission-gated** — auth-required, role-based, paywall (need: unauthorized, locked, upgrade)
- **Offline-sensitive** — real-time data, sync-dependent (need: offline, stale, reconnection)
- **Agent-output surfaces** — only when model output or agent actions are shown (need: streaming/partial, variable-length result, tool-running, interrupted, refusal, uncertainty/needs verification, retry/regenerate, stop, and any applicable approval/audit/undo state)

### Production Data Coverage Model

For authenticated or data-bearing surfaces, MUST define all of:
- `seeded-demo` — what a demo account sees
- `first-real-user-empty` — what a brand-new real account sees (first action, bootstrap CTA)
- `existing-user-populated` — normal usage state
- `unauthorized` — what happens without proper auth
- `loading` — what shows while data loads
- `error` — what shows when data fetch fails

If no authenticated surfaces exist, state: "No authenticated/data-bearing surfaces in scope."

<HARD-GATE>
Do NOT proceed to Phase B until user approves state surface inventory.
Use AskUserQuestion: "State surfaces classified. Approve?"
Options: [Approve — define state model, Add more surfaces, Reclassify]
</HARD-GATE>

---

## Phase B — Universal State Model & Per-Flow Coverage

### Universal State Taxonomy

Define the core state families for this product:

| State | User Interpretation | System Reality | Visual Intent | Recovery | Announcement |
|-------|-------------------|---------------|---------------|----------|--------------|
| Empty | Nothing here yet | No data exists | Guide to first action | Create first item | None |
| Loading | Working on it | Fetching data | Skeleton / progress | Wait | Polite status |
| Success | It worked | Action completed | Confirm + next step | None needed | Polite status |
| Error | Something broke | Request failed | Explain + retry | Retry / go back / contact support | Assertive alert |
| Partial | Some things worked | Partial data/failure | Show what works + flag what failed | Retry failed parts | Polite status |
| Offline | No connection | Network unavailable | Show cached + queue actions | Reconnect | Polite status |
| Unauthorized | Can't access this | Auth required | Sign-in prompt | Authenticate | None |
| Locked/Upgrade | Need higher tier | Entitlement check failed | Show upgrade path | Upgrade or contact sales | None |
| Read-only | Can view, can't edit | Permission level | Subtle indicator | Navigate to editable context | None |

### Agent-output state extension (only for applicable surfaces)

For every surface that renders model output or launches an agent operation, add the applicable rows to the per-screen matrix: `preview`, `awaiting-approval`, `streaming`, `tool-running`, `partial`, `interrupted`, `refusal`, `uncertain-needs-verification`, `retry-regenerate`, `stopped`, `completed`, `undo-available`, and `escalated`. Each row must name what is visible, whether an action is still in progress, what the user can do next, and the recovery or audit path. Do not add these rows to products without agent behavior.

### Per-Flow State Coverage

For each flow from Step 5, map every screen to its applicable states:

| Screen ID | Empty | Loading | Success | Error | Auth | Locked | Offline | Notes |
|-----------|-------|---------|---------|-------|------|--------|---------|-------|
| [id] | [behavior] | [behavior] | [behavior] | [behavior] | [behavior] | [behavior] | [behavior] | |

For each cell, define: what the user sees, what they can do, what microcopy appears.

For the Step 4 core-journey slice and its high-risk component, add independently checkable visual and behavior acceptance for each applicable state: expected render at the Reference Contract viewport, next action/recovery, keyboard behavior, and long-data or input behavior. A unit or build pass does not prove this visual contract.

<HARD-GATE>
Do NOT proceed to Phase C until user approves state model + per-flow coverage.
Use AskUserQuestion: "State model and per-flow coverage mapped. Approve?"
Options: [Approve — define recovery and accessibility, Add states for more screens, Revise state model]
</HARD-GATE>

---

## Phase C — Recovery Patterns & Accessibility

### Cross-Feature Recovery Rules

| Scenario | What Happens | What's Announced | Where Focus Goes | User's Next Action |
|----------|-------------|-----------------|-----------------|-------------------|
| Network failure | Show error + cached data if available | Assertive: "Connection lost" | Retry button | Retry or wait |
| Validation failure | Inline error on field | Assertive: field-specific error | First invalid field | Fix and resubmit |
| Permission failure | Auth prompt or upgrade card | None (visual only) | Sign-in / upgrade CTA | Authenticate or upgrade |
| Offline mode | Show cached data + offline badge | Polite: "You're offline" | No change | Queue actions, wait |
| Empty → first value | Onboarding CTA or guided action | None | Primary CTA | Create first item |
| Destructive confirmation | Modal with explicit confirm | Polite: "Are you sure?" | Confirm button | Confirm or cancel |
| Save/submit success | Toast or inline confirmation | Polite: "Saved" | Next logical action | Continue workflow |

### Accessibility & Announcement Rules

**Announcements (ARIA live regions):**
- `role="status"` (polite) — loading completion, save success, non-critical updates
- `role="alert"` (assertive) — errors, validation failures, destructive consequences
- `aria-busy="true"` on containers during data updates — signals screen readers to delay announcing changes
- `aria-disabled="true"` on buttons during submission + change accessible name to "Submitting..."
- Skeleton screens: apply `aria-hidden="true"` (they're visual-only) and announce via separate live region
- Do NOT announce every state change — skip announcements for sub-second operations
- Do NOT announce in-progress loading unless the operation takes >2 seconds

**Focus Management:**
- After state change → preserve focus during typing and asynchronous updates; move it only when the user action or accessibility pattern calls for a new target
- Frequent keyboard actions must respond immediately; do not put routine navigation, typing, or dismissal behind a decorative transition
- After modal/overlay close → focus returns to the element that opened it
- After error → focus moves to the first invalid field or error summary
- After destructive action → focus moves to the item's former context
- Do NOT trap focus unless in a modal/dialog

**Large Text & Scaling:**
- State layouts must survive 200% text zoom (WCAG 2.2 AA)
- Empty state illustrations/icons should not push content off-screen at large text sizes

**Cognitive principles (advisory — invoke `ux-psychology-pro`):**
- **Recognition over Recall** — error states should show the user how to fix the problem, not require them to recall syntax/format from memory
- **Feedback Loop** — every state transition (loading → loaded, submitting → saved, etc.) needs visible feedback within the Doherty Threshold (<400ms)
- **Cognitive Tunneling** — under stress, users fixate on one element. Error states must keep the recovery action visually obvious, not buried beneath retry messaging.

<HARD-GATE>
Do NOT proceed to Phase D until user approves recovery + accessibility.
Use AskUserQuestion: "Recovery patterns and accessibility rules defined. Approve?"
Options: [Approve — finalize cross-feature patterns, Strengthen recovery rules, Add more a11y rules]
</HARD-GATE>

---

## Phase D — Cross-Feature Patterns & State Transitions

### Shared Patterns (apply across all flows)

Document reusable patterns that appear in multiple flows:
- **Skeleton loading** — use for structured content (lists, cards, tables). Spinners only for indeterminate short waits. Progress bars for uploads/multi-step processes with known duration.
- **Toast/notification** — success (auto-dismiss 3-5s), info (auto-dismiss), warning (persist until dismissed), error (persist + action). Use Sonner if shadcn/ui.
- **Confirmation** — required for destructive actions (delete, cancel, revoke) and large scope changes. Never for routine saves.
- **Retry** — auto-retry (1-3 attempts with exponential backoff) for network errors. Manual retry button for persistent failures. "Try again later" only when the service is genuinely down.
- **Optimistic update** — show success instantly for high-confidence actions (likes, toggles, saves). Store previous state → update UI → fire API → rollback on failure. React 19: use `useOptimistic` hook.
- **Stale-while-revalidate** — show cached/stale data immediately, refresh in background, update when fresh data arrives. Never show full loading state when stale data exists.
- **Error boundary** — wrap independent UI sections so one component failure doesn't crash the entire app. Show fallback UI for the affected section only. Log error for debugging.
- **Offline queue** — when offline, queue write actions locally, sync when connection returns, show pending indicator on queued items.

### State Transition Rules

For critical transitions, define:

| From | To | Trigger | Animation Intent | Announcement |
|------|-----|---------|-----------------|--------------|
| Loading | Success | Data received | Fade in content | Polite: "Loaded" |
| Loading | Error | Request failed | Shake or error reveal | Assertive: error message |
| Empty | Populated | First item created | Entrance animation | Polite: "First [item] created" |

Animation intent is documented here. Animation implementation is Step 8's job.

Use motion only to communicate state, orientation, or cause and effect. Respect reduced-motion and prioritize the product, platform, and task constraints when they conflict with a generic motion preference; never require motion merely to make a surface feel active.

<HARD-GATE>
Do NOT proceed to Phase E until user approves cross-feature patterns.
Use AskUserQuestion: "Cross-feature patterns defined. Approve?"
Options: [Approve — write STATE-SPEC.md, Add more patterns, Revise transitions]
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Screens from Step 5 without state coverage
- Missing recovery paths for critical user flows
- Weak announcement/focus rules
- State behavior that contradicts Step 6 system rules
- Step 8 implementation detail absorbed into Step 7

Fix findings before presenting.

### Write `docs/states/STATE-SPEC.md`

Required sections:
```
State Model (universal taxonomy table)
Production Data Coverage Model
Flow & Screen State Coverage (per-flow state matrices)
Recovery Patterns (cross-feature table)
Accessibility & Announcement Rules
Focus Management
Cross-Feature Patterns
State Transitions (animation intent)
Step 8 Handoff — what engineering must implement
Do NOT Build in This Step
```

### Step 8 Handoff must include:
- Stateful screens needing implementation attention
- State-specific accessibility requirements (ARIA roles, focus traps)
- Missing independent visual/behavior acceptance for the core journey at its reference viewport, including long data or input evidence
- Announcement rules to implement
- Focus restoration rules
- Permission/locked/offline handling requirements
- Which transitions depend on Step 6 motion tokens
- Which patterns need engineering decisions (retry logic, caching, optimistic updates)

### Writing Standards (embedded)

- No stock AI phrases: "Graceful degradation", "Smooth transitions", "Delightful experience"
- State descriptions are concrete: "Show error message + retry button" not "handle the error gracefully"
- Microcopy is realistic, not placeholder: "Couldn't load your projects. Check your connection and try again." not "An error occurred."
- Recovery actions are specific: "Retry button re-fetches the failed request" not "the user can try again"

### Success Criteria

- [ ] Universal state taxonomy defined
- [ ] Production data coverage model applied (or explicitly not applicable)
- [ ] Per-flow state coverage matches Step 5 screens
- [ ] Core journey and high-risk component have independent visual and behavior acceptance, backed by an actual render at the representative viewport and long-data or input evidence where applicable
- [ ] Recovery patterns are concrete with next actions
- [ ] Accessibility announcements use proper ARIA patterns
- [ ] Focus management rules are explicit
- [ ] Unavailable states are distinguished (disabled/read-only/locked/unauthorized/offline)
- [ ] State behavior inherits Step 6 system rules
- [ ] Step 8 handoff explicit
- [ ] $holes pass completed
- [ ] Linear tracking issues created (when configured)
- [ ] User approved

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 8 without explicit approval.
Use AskUserQuestion: "Step 7 complete. Ready for Step 8 — Technical Spec?"
Options: [Proceed to Step 8, Revise state spec, Add more state coverage]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 7 Verification Schema

### Required Outputs (25 points)

| Item | Path | Points |
|------|------|--------|
| State Specification | docs/states/STATE-SPEC.md | 25 |

### Required Sections (35 points)

| Section | Points |
|---------|--------|
| State Model (universal taxonomy) | 5 |
| Production Data Coverage Model | 5 |
| Flow & Screen State Coverage (per-flow matrices) | 8 |
| Recovery Patterns (cross-feature) | 5 |
| Accessibility & Announcement Rules | 5 |
| Focus Management | 4 |
| Cross-Feature Patterns | 3 |

### Quality Indicators (30 points)

| Check | Points |
|-------|--------|
| Empty states are contextual with next-action CTAs | 5 |
| Loading uses skeleton-first for structured content | 4 |
| Errors explain what happened + what to do next | 5 |
| Unavailable states are distinct (disabled/read-only/locked/unauthorized/offline) | 5 |
| Announcements use proper ARIA roles (status vs alert) | 4 |
| Focus management is explicit for state transitions | 4 |
| Microcopy is realistic, not placeholder | 3 |

### Handoff & Boundary (10 points)

| Check | Points |
|-------|--------|
| Step 8 handoff explicit | 4 |
| No Step 6 motion system redefined | 2 |
| No Step 8 implementation detail absorbed | 2 |
| $holes pass completed | 2 |
| Linear tracking issues created (when configured) | 1 |

**Passing score:** 95/100

## CRAFT (award standard) — scored by step-verify-gate (deterministic) + the judge; never self-attested. See references/award-standard.md.
<VERIFY-ASSERT>
craft_antislop docs/states/*.md
</VERIFY-ASSERT>

## DNA Conformance — scored by step-verify-gate (deterministic); never self-attested. Requires .sigma/standards.json from Step 3. Missing file → advisory skip (not a fail). See schemas/standards.schema.json.
<VERIFY-ASSERT>
dna_conformance docs/states/*.md
</VERIFY-ASSERT>
</verification>

$END$
