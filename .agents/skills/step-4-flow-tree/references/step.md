---
version: "3.1.0"
last_updated: "2026-04-19"
description: "Step 4: Flow Tree → structural screen inventory, transitions, traceability, zero-omission proof, and machine-readable flow tree"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --platform
  - --depth
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

- `ux-designer`
- `web-design-guidelines`
- `wireframe`
- `shadcn` — curated preflight (web/desktop React)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — gamification / trophy flows in screen inventory

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-4-flow-tree — Structural Flow Mapping and Screen Inventory

**On start, announce:** "Running Step 4: Flow Tree. I'll map every screen, transition, and flow branch — then prove nothing was missed with traceability and zero-omission gates."

<goal>
You are the Flow Architect. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Context & UI Profile | Confirmed inputs + Design DNA applied structurally |
| B | Flow Model & Categories | Top-level flows, subflows, structural logic |
| C | Screen Inventory & Transitions | Full screen list + transition map + navigation |
| D | Bulletproof Gates & Machine-Readable Tree | Traceability matrix + zero-omission proof + flow-tree.json |
| E | Output, Hardening & Handoff | Full artifact set + Step 5 handoff |

Final Outputs:
- `docs/flows/FLOW-TREE.md`
- `docs/flows/SCREEN-INVENTORY.md`
- `docs/flows/TRANSITION-MAP.md`
- `docs/flows/TRACEABILITY-MATRIX.md`
- `docs/flows/ZERO-OMISSION-CERTIFICATE.md`
- `product/flows/flow-tree.json`

Quality gate: 95+/100 on verification schema.

**Core rule:** If a screen, state entry point, or flow branch is not in Step 4, it does not exist for downstream implementation.

**Exhaustive mandate:** enumerate EVERY screen and EVERY distinct full-screen state or edge case as its own entry, and give EVERY interactive control its own destination route. Do not summarize, sample, or collapse states into "etc." or "and variants." For a real product, 100+ discrete screens/states is expected and correct — a thin inventory is a defect, not efficiency. See Phase C for the fan-out pattern that makes this tractable.

**AI-native output rule:** flow-tree.json and SCREEN-INVENTORY.md are consumed by AI agents in Steps 5, 10, and 11. Structured fields, not prose. Every screen has an ID, route, and priority.
</goal>

---

## Step Boundary

- **Step 4 owns:** flow categories, screen families, full screen inventory, transitions, navigation structure, deep-link/entry/exit mapping, traceability, omission proof, machine-readable flow structure.
- **Step 4 does NOT own:** Design DNA selection (Step 3), visual tokens (Step 6), full state catalog (Step 7), wireframe-level detail (Step 5).
- **Step 4 imports** Design DNA and UI profile from Step 3 and applies them structurally — do NOT reselect.
- **Do NOT** create wireframes, component specs, or visual design. Map the structure, not the pixels.

---

## Structural Principles

### Structural Completeness
- Every meaningful screen appears in a visible hierarchy
- Subflows carry their own screen counts
- Related flows are grouped coherently
- Structure is legible to both product and engineering

### Journey Traceability
- Every PRD feature maps to one or more screens
- Every screen maps back to a user job, journey stage, and feature/requirement
- If a feature has no screen, the PRD has a gap. If a screen has no feature, the flow tree has bloat.

### Complexity Handling
For nonlinear, expert-facing, or high-stakes products:
- Model branching paths, expert shortcuts, exception paths, recovery paths
- Model permission/role-based path differences
- Don't flatten complexity — represent it honestly

### Design DNA Application (imported, not reselected)
Use Step 3's Design DNA to influence:
- Where trust-heavy screens should appear
- Where delight or emotional peaks matter
- Which paths should feel low-friction vs high-intent
- Which surfaces should be calmer, denser, or more energetic
- **Amplitude tagging (imported from Step 3's two-amplitude doctrine):** every screen is `marketing` (cinematic) or `app` (instrument). Marketing surfaces (landing, launch, acquisition) carry the DNA at full volume; app surfaces (the working product) carry it restrained. Tag at the screen level so Step 5 picks the right skills/quality bar and Step 7 applies the right state rigor. Do NOT redefine the DNA — only classify each screen's amplitude.
- **Differentiation:** Which flows should feel unforgettable (from Step 3's Design Thinking)?

---

## Phase A — Import Context & UI Profile

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `.sigma/runtime-baseline.json`, `docs/specs/MASTER_PRD.md`, `docs/architecture/ARCHITECTURE.md`, `docs/ux/UX-DESIGN.md`, `DESIGN.md`, `docs/design/ui-profile.json`.
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
#### Boilerplate module manifest (when `.sigma/boilerplate.json` exists)

1. **Read** `.sigma/modules.manifest.json` if present.
2. **Cross-check** Step 4 screen inventory / Step 10 features against enabled modules (`modules.*.enabled === true`).
3. **Record** inherited routes and module file paths in the step output — do not re-scaffold modules the boilerplate already ships.
4. **Module ID vocabulary** must match `templates/boilerplates/_shared/module-catalog.json` (see `docs/references/integration-packs-catalog.md`).

If manifest is missing but `boilerplate.json` exists → note as gap; do not invent module IDs.
3. Read `.sigma/boilerplate.json` if present.
4. Read `docs/specs/OFFER_ARCHITECTURE.md` if monetization affects flow branching.
5. If `research_mode = blocked` → stop. If `reduced` → continue with assumption labels.

### Sequential Decisions

**Decision 1: Platform scope confirmation**
Use AskUserQuestion: "Confirm platform scope for flow mapping?"
Options: [Web only, Web + Mobile, Native iOS, Cross-platform, Already confirmed in Step 3]

**Decision 2: Flow complexity**
Use AskUserQuestion: "How many major flows do you expect?"
Options: [Small (3-5 flows, <20 screens), Medium (6-12 flows, 20-50 screens), Large (12+ flows, 50+ screens), Not sure — let's discover]

### Import Summary

Document: Design DNA archetype imported, UI profile metadata, architecture constraints, journey model from Step 3, monetization flows (if applicable).

<HARD-GATE>
Do NOT proceed to Phase B until user approves imports.
Use AskUserQuestion: "Context and DNA imported. Approve?"
Options: [Approve — map flow categories, Revise imports]
</HARD-GATE>

---

## Phase B — Flow Model & Categories

### Required flow categories (enumerate all that apply)

- Launch / splash
- Onboarding (first-time + returning)
- Authentication (sign up, sign in, password reset, MFA)
- Core work flows (the main "spines" of usage)
- Management / settings / preferences
- Profile / account
- Monetization / billing / upgrade (if applicable)
- Support / recovery / error flows
- Admin / internal flows (if applicable)
- Marketing / referral flows (if applicable)

**Public entry (root):** the product's public marketing landing page is the flow tree's root entry point — include it even for internal or backend-heavy products that still have a public site. It belongs under "Marketing / referral flows" (or its own category for a marketing-led product). Full landing-page CRO and copy are designed later in Step 9 — Step 4 only needs the screen and its outbound routes recorded now. A flow tree that omits the public entry page is incomplete.

**Fan-out unit:** these approved flow categories are the unit of decomposition for Phase C — one subagent enumerates each category's full screen inventory in parallel. Keep categories mutually exclusive so no subagent's slice overlaps another's.

### For each category, document:
- Subflows within the category
- Actor/audience ownership
- DNA emphasis notes (where the Design DNA should be felt most)
- Platform differences (if any flows differ by platform)

### Flow questions to answer:
- What are the user-entry paths into the product?
- What are the main usage spines?
- What are the recovery/failure paths?
- Which flows differ by platform or role?

### Prototype target (record in the existing flow artifacts)

Before inventory expansion, select one core journey for Step 5's first runnable slice. Record its entry screen ID, immediate next action and destination, recovery screen ID, and one representative high-risk component to prototype. Carry those IDs into `FLOW-TREE.md`, `TRACEABILITY-MATRIX.md`, and the Step 5 handoff; do not create a separate artifact or invent new IDs later.

<HARD-GATE>
Do NOT proceed to Phase C until user approves flow model.
Use AskUserQuestion: "Flow categories mapped. Approve?"
Options: [Approve — build screen inventory, Add missing flows, Restructure categories]
</HARD-GATE>

---

## Phase C — Screen Inventory & Transitions

### Exhaustive Inventory Mandate (hard rule)

A base-level screen list is not enough. This inventory must enumerate:
- **Every screen** — including screens implied by branches, permissions, roles, and platform variants.
- **Every distinct full-screen state or edge case as its OWN entry** — empty, loading, error, offline, permission-denied, expired, rate-limited, zero-results, first-run, and any domain-specific edge state each get their own screen `id`. Do not fold them into a parent screen's description; never write "and its variants."
- **Every interactive control's destination** — every button, link, tab, menu item, and gesture that navigates or triggers something names where it goes (see the `actions` field below).

Do not summarize, sample, or collapse states to save space. For a real product, **100+ discrete screens/states is expected and correct** — a short list of "main" screens with edge cases waved away is a defect, not efficiency. When in doubt, split the entry: an over-granular tree can be pruned in review, but a tree that hides states cannot be trusted downstream.

### Fan-Out Execution Pattern (multi-agent)

Screen inventory is built by fan-out, not by one pass over the whole product:

1. Take the flow categories approved in Phase B.
2. The invoking agent spawns **one subagent per flow category**, run in parallel — the subagent count equals the approved category count.
3. Each subagent independently and exhaustively enumerates its own category only — every screen, every full-screen state/edge case, and every control's destination route within that slice — applying the Exhaustive Inventory Mandate above.
4. Each subagent writes its slice to its own fragment files, not to the shared documents directly: `docs/flows/sections/<category>.json` (screen + transition fragment) and `docs/flows/sections/<category>.md` (the human-readable section). This keeps the orchestrating agent's context lean instead of holding every category's full detail at once.
5. The invoking agent merges the fragments: concatenate the markdown sections into `docs/flows/SCREEN-INVENTORY.md` / `docs/flows/TRANSITION-MAP.md`, and merge the JSON fragments into `product/flows/flow-tree.json`'s `screens[]` and `flows[]` arrays.
6. The invoking agent resolves merge conflicts (duplicate IDs, cross-category transitions) before Phase D's gates run.

This pattern is agent-neutral — whichever agent is invoking this step fans out the same way, regardless of which model or CLI is running it.

### Screen fields (every screen must have ALL of these)

| Field | Description |
|-------|------------|
| `id` | Unique identifier (e.g., `onb-01`) |
| `title` | Human-readable screen name |
| `flow` | Parent flow category |
| `subflow` | Subflow within the category |
| `platform` | web / mobile / both |
| `route` | URL path or navigation route |
| `actor` | Who sees this screen |
| `purpose` | One sentence — what the user does here |
| `priority` | P0 / P1 / P2 |
| `complexity` | simple / medium / complex |
| `entryPoints` | How the user gets here |
| `exitPoints` | Where the user goes from here |
| `dnaEmphasis` | How Design DNA applies (if relevant) |
| `amplitude` | `marketing` (cinematic surface — landing, launch, acquisition, public marketing) or `app` (instrument surface — the working product: dashboards, forms, settings, core flows). Tag EVERY screen. This feeds Step 5 (which skills + quality bar) and Step 7 (state rigor). From Step 3's DNA: marketing screens may perform; app screens confirm, never perform. |
| `actions` | Every interactive control on the screen, as an array — see Actions schema below. Required; empty only for a pure display/terminal screen, and only when the inventory states why nothing on it navigates or triggers anything. |

### Actions schema (per screen — hard rule)

Every screen's `actions` array lists every button, link, tab, menu item, or gesture that navigates or triggers something. Each entry:

| Field | Description |
|-------|------------|
| `label` | The control's visible label or accessible name |
| `type` | `nav` (screen-to-screen navigation) / `gated` (navigation behind a permission, auth, or paywall check) / `action` (triggers a side effect without necessarily navigating, e.g. "Save", "Delete", "Copy link") / `exceptional` (error/recovery/edge-case-only control, e.g. "Retry", "Report a problem") |
| `to` | Destination screen `id`, or an external/system route (e.g. `system:share-sheet`, `external:support-mailto`) when it does not resolve to an in-tree screen |
| `condition` | Guard or branch logic that determines when this action is available or where it routes (empty string if unconditional) |

**Hard rule: every button must name a destination.** A control with no `to` value is either miscategorized (it does nothing — remove it) or the flow tree is incomplete (find where it goes and add the `to`). "Opens a modal" or "expands a section" still names a destination — the modal or expanded state is its own screen/state entry with its own `id`.

### Public Landing Page — Flow Tree Root

The product's public marketing landing page is the flow tree's **root entry point**, even for backend-heavy or internal-tool products that still have a public site. Give it its own screen entry (e.g. `mkt-landing`) with `entryPoints` covering how visitors arrive (direct URL, search, ad/referral) and `exitPoints`/`actions` pointing at sign-up, sign-in, and any other in-product routes the page links to.

Step 4 does not design the landing page's conversion layout or copy — that is Step 9's job. Step 4 only records that the screen exists, where it sits in the tree, and where its controls route to. A flow tree that omits the public entry page is incomplete regardless of how thorough the in-app inventory is.

### Transition fields (for each major transition)

| Field | Description |
|-------|------------|
| `from` | Source screen ID |
| `to` | Destination screen ID |
| `trigger` | What causes the transition |
| `conditions` | Branch logic, guards, permissions |
| `type` | linear / optional / gated / exceptional |
| `deepLink` | External entry behavior (if applicable) |

### Agent-operated branches (only when agent behavior is in scope)

For each agent-triggered operation, map the user-visible nodes for intent preview, approval when required, execution, interruption, partial completion, refusal, uncertainty/verification, undo where possible, and escalation. These are flow branches with destinations and conditions, not merely visual states reserved for Step 7.

### Required artifacts
- `docs/flows/SCREEN-INVENTORY.md` (merged from the `docs/flows/sections/<category>.md` fan-out fragments)
- `docs/flows/TRANSITION-MAP.md` (merged from the same fragments)

<HARD-GATE>
Do NOT proceed to Phase D until user approves screen inventory + transitions.
Use AskUserQuestion: "Screen inventory and transitions mapped. Approve?"
Options: [Approve — run bulletproof gates, Add missing screens, Revise transitions]
</HARD-GATE>

---

## Phase D — Bulletproof Gates & Machine-Readable Tree

### Traceability Matrix (`docs/flows/TRACEABILITY-MATRIX.md`)

Every PRD feature maps to:
- One or more screens (by ID)
- One or more journey stages
- One or more transitions (when applicable)

Format as a table:

| PRD Feature | Screen IDs | Journey Stage | Transitions | Status |
|------------|-----------|---------------|-------------|--------|

### Zero-Omission Certificate (`docs/flows/ZERO-OMISSION-CERTIFICATE.md`)

Must contain:
- Total feature count from PRD
- Total mapped feature count
- **Features without screens = 0** (if not 0, fix before proceeding)
- **Cross-check gate results: 0 dangling routes, 0 orphan screens, 0 duplicate IDs, keyword-coverage sweep clean** (if not clean, fix before proceeding — see Cross-Check Gate below)
- Total screen count
- Why the screen count is reasonable
- Certification statement

### Cross-Check Gate (programmatic, after fragment merge)

Run this after Phase C's fan-out fragments are merged into `product/flows/flow-tree.json`, before the Zero-Omission Certificate is finalized:

1. **0 dangling routes** — every `to` value on every screen's `actions[]`, and every transition's `to`, resolves to a real screen `id` in the merged tree (or is explicitly tagged `system:` / `external:`). Run `node scripts/verify/structural-verify.mjs --file product/flows/flow-tree.json` for the structural layer (duplicate IDs, module/screen/flow referential integrity), then extend the same pass by hand to check `actions[].to` resolution, which the base script does not yet cover.
2. **0 orphan screens** — every screen is reachable either via an inbound `to` from another screen's action/transition, or is a declared `entryPoint` (deep link, external referral, the landing-page root). A screen nobody routes to, and that isn't a declared entry point, is either dead weight or missing its inbound link.
3. **0 duplicate IDs** — across the merged `screens[]`, `modules[]`, and `flows[]`.
4. **Keyword-coverage sweep** — search the merged inventory for cross-cutting screens fan-out tends to miss because no single category owns them: search, notifications, settings, help/FAQ, 404/not-found, empty states, offline, error/exception states, and every domain-specific edge state named in the PRD. A missing keyword category is a gap — add the screen(s), or state explicitly why it does not apply to this product.

Any gap this gate finds is fixed — by adding the missing screen, route, or entry point — before the gate is reported as passed. Do not log the gap and move on.

### Machine-Readable Flow Tree (`product/flows/flow-tree.json`)

Required metadata:
```json
{
  "meta": {
    "appName": "[name]",
    "platform": "[web|mobile|both]",
    "generatedAt": "[ISO date]",
    "designDNA": "[archetype from Step 3]",
    "uiProfile": "[reference to ui-profile.json]",
    "totalScreens": 0,
    "prdSource": "docs/specs/MASTER_PRD.md"
  },
  "modules": [],
  "screens": [],
  "flows": []
}
```

Rules:
- `meta.designDNA` must come from Step 3, not be selected here
- Flow tree JSON must match the markdown artifacts exactly — no invented flows
- Every screen in JSON must exist in SCREEN-INVENTORY.md

<HARD-GATE>
Do NOT proceed to Phase E until user approves traceability + zero-omission + flow tree.
Use AskUserQuestion: "Bulletproof gates passed. Zero omissions confirmed. Approve?"
Options: [Approve — finalize outputs, Fix traceability gaps, Add missing screens]
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Missing screens or flows
- Weak traceability (features without screen coverage)
- Flow tree JSON that doesn't match markdown
- Step 5/7 work absorbed into Step 4

Fix findings before presenting.

### Required Outputs

1. `docs/flows/FLOW-TREE.md`
2. `docs/flows/SCREEN-INVENTORY.md`
3. `docs/flows/TRANSITION-MAP.md`
4. `docs/flows/TRACEABILITY-MATRIX.md`
5. `docs/flows/ZERO-OMISSION-CERTIFICATE.md`
6. `product/flows/flow-tree.json`

### Step 5 Handoff

Must state:
- Total screen count Step 5 must cover in wireframes
- P0 screens to wireframe first
- Which screens require the most structural attention
- Core journey prototype target: entry ID, next-action destination, recovery ID, representative high-risk component, and the linked traceability rows
- How Design DNA should influence wireframe emphasis (without redefining the DNA)
- **Artifact-path preview** — Step 5 will select either Canvas (a durable visual artifact such as a `.pen` source and export) when a visual review is useful, or Direct (a stack-native prototype) when code is the right learning artifact.
- If a clear preference is already known, include it as a recommendation only. The final decision happens at Step 5 Phase A; do not claim an external canvas, renderer, export, or approval before it exists.

### Linear Sync (when configured — Linear replaced the SigmaHQ kanban 2026-07-11)

When Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json — see Step 0 → Linear Operations Reference):

1. Parse the screen inventory into Linear issues — one per flow category, via GraphQL `issueCreate`:
   - title: `Flow: {flow-category-name}`
   - description: screen count, priority, and screen list
   - labels: `flow-card` + `wave:W0` (wave labels are MANDATORY on every created issue)
   - priority: highest among screens in the category (P0 → high, P1 → medium, P2 → low)
   - state: Todo
2. These issues represent the structural inventory — Step 5 picks them up for prototype PRDs
3. Step 10 will later refine them into feature-level engineering issues

If Linear is not configured, track handoff tasks as wave-labeled GitHub Issues, or skip this section and rely on file-based artifacts. Never write task tracking to the retired SigmaHQ kanban — that board is dead for everyone. GitHub always owns the PR/branch/review/merge loop; when Linear is connected its issues two-way-sync once the operator enables per-repo issue sync in the GitHub<->Linear integration (PR-linkback only today).

### Writing Standards (embedded)

- No stock AI phrases: "Comprehensive", "Robust", "Seamless flow", "Intuitive navigation"
- Screen purposes are one concrete sentence, not vague descriptions
- Transition logic is explicit — no "as expected" or "standard behavior"
- Write like a systems architect mapping routes, not a PM describing aspirations

### Success Criteria

- [ ] All PRD features map to screens (traceability complete)
- [ ] Zero-omission certificate shows 0 unmapped features
- [ ] Design DNA imported and applied structurally, not reselected
- [ ] Every screen tagged `marketing` (cinematic) or `app` (instrument) amplitude — feeds Steps 5 and 7
- [ ] flow-tree.json matches markdown artifacts
- [ ] Every screen has all required fields (including `amplitude` and `actions`)
- [ ] Every action names a destination (`to`) — zero unresolved buttons
- [ ] One core journey and representative high-risk component are identified with stable screen IDs and traceability for Step 5's first runnable slice
- [ ] Public marketing landing page present as the flow tree's root entry point
- [ ] Cross-check gate clean: 0 dangling routes, 0 orphan screens, 0 duplicate IDs, keyword-coverage sweep passed
- [ ] Transitions have explicit triggers and conditions
- [ ] No Step 5 wireframe detail or Step 7 state catalog absorbed
- [ ] $holes pass completed
- [ ] Linear flow-card issues created for each flow category (when configured)
- [ ] User approved

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 5 without explicit approval.
Use AskUserQuestion: "Step 4 complete. Ready for Step 5 — Wireframe Prototypes?"
Options: [Proceed to Step 5, Revise flow tree, Add missing flows]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 4 Verification Schema

### Required Outputs (50 points)

| Item | Path | Points |
|------|------|--------|
| Flow Tree | docs/flows/FLOW-TREE.md | 10 |
| Screen Inventory | docs/flows/SCREEN-INVENTORY.md | 10 |
| Transition Map | docs/flows/TRANSITION-MAP.md | 10 |
| Traceability Matrix | docs/flows/TRACEABILITY-MATRIX.md | 8 |
| Zero Omission Certificate | docs/flows/ZERO-OMISSION-CERTIFICATE.md | 6 |
| Flow Tree JSON | product/flows/flow-tree.json | 6 |

### Required Sections (20 points)

| Section | Points |
|---------|--------|
| Imported Design DNA & UI Profile | 4 |
| Flow Categories | 4 |
| Screen Inventory with all fields | 4 |
| Navigation & Transition Notes | 4 |
| Step 5 Handoff | 4 |

### Quality Indicators (20 points)

| Check | Points |
|-------|--------|
| All screens trace to flows and features | 5 |
| PRD-to-screen traceability explicit | 5 |
| Design DNA applied structurally, not reselected | 5 |
| flow-tree.json matches markdown | 5 |

### Boundary Integrity (10 points)

| Check | Points |
|-------|--------|
| No Step 3 DNA reselection | 3 |
| No Step 5 wireframe scope absorbed | 3 |
| No Step 7 state catalog absorbed | 2 |
| $holes pass completed | 1 |
| Linear flow-card issues created (when configured) | 1 |

**Passing score:** 95/100

## DNA Conformance — scored by step-verify-gate (deterministic); never self-attested. Requires .sigma/standards.json from Step 3. Missing file → advisory skip (not a fail). See schemas/standards.schema.json.
<VERIFY-ASSERT>
dna_conformance docs/flows/*.md
</VERIFY-ASSERT>
</verification>

$END$
