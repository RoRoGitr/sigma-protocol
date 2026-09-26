---
version: "2.2.0"
last_updated: "2026-09-19"
description: "Step 6: Design System → DESIGN-SYSTEM.md + design-tokens.json — convert Design DNA into reusable token system, component styling, theming, and cross-platform export"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --theme
  - --density
  - --platforms
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

- `design-tokens`
- `tailwind-design-system`
- `theme-factory`
- `applying-brand-guidelines`
- `design-taste`
- `shadcn`
- `rn-component-library`
- `macos-design`

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-6-design-system — Design System & Token Architecture

**On start, announce:** "Running Step 6: Design System. I'll turn the Design DNA from Step 3 and prototype patterns from Step 5 into a reusable token system, component styling logic, and cross-platform export strategy."

<goal>
You are the Design Systems Architect. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Context & Pattern Audit | Repeated patterns + system scope |
| B | System Principles, Token Architecture & Themes | Principles + token layers + theme model |
| C | Foundations & Component Styling | Color, type, spacing, shape, icons + component families |
| D | Motion, Accessibility & Platform Export | Motion tokens, a11y rules, export strategy |
| E | Output, Hardening & Handoff | DESIGN-SYSTEM.md + design-tokens.json |

Required Outputs:
- `docs/design/DESIGN-SYSTEM.md`
- `docs/tokens/design-tokens.json` (W3C DTCG 2025.10 compliant, Oklch/CSS Color 4)
- `docs/tokens/style-dictionary.config.json` (Style Dictionary v4 build config)

Optional (when justified): `docs/tokens/css-variables.css`, `docs/tokens/react-native-tokens.ts`, `docs/tokens/swiftui-tokens.swift`, `docs/components/COMPONENT-LIBRARY.md`, `docs/design/MOTION.md`

Conditional: When `stack-profile.json` includes `"componentLibrary": "shadcn/ui"`, also output a **shadcn preset code** using `registry:base` format. This distributes the entire design system (colors, themes, icons, fonts, radius) as one portable payload that can be applied via `shadcn init --preset [code]`.

Quality gate: 95+/100 on verification schema.

**AI-native output rule:** design-tokens.json is consumed by AI agents in Steps 7, 8, and 11. It must be machine-readable, role-based, and standards-aligned (W3C DTCG format).
</goal>

---

## Trigger

**Run after Step 5 (Wireframe Prototypes) is approved.** Step 6 requires Step 5 flow PRDs to audit repeated patterns. If Step 5 outputs are missing, stop and inform the user.

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
- Step start: create issue "Step 6: Design System" — labels `step-6`, `wave:W0`, state In Progress.
- Milestone issues as sections land: "Step 6: Design tokens defined" and "Step 6: Component styling logic" — labels `step-6`, `wave:W0`.
- On DESIGN-SYSTEM.md completion: move the tracking issue to Done.

---

## Step Boundary

- **Step 6 owns:** token architecture, themes, foundations (color, type, spacing, shape, elevation, icons), component styling logic, motion principles/tokens, accessibility foundations, cross-platform export intent.
- **Step 6 does NOT own:** Design DNA selection (Step 3), screen inventory (Step 4), full state catalog (Step 7), implementation patterns (Step 8).
- **Do NOT** create full component APIs, Storybook configs, or build tooling. Define the SYSTEM, not the implementation.

Step relationship: Step 3 chooses personality → Step 5 proves it in prototypes → **Step 6 turns repeated decisions into a reusable system** → Step 7 expands states → Step 8 implements.

---

## Design System Principles

### Dieter Rams — Less, But Better
- Token families exist for a reason — no bloat
- Components solve real UI problems, not style vanity
- Naming is understandable — role-based, not color-name-based
- The system ages well

### Token Architecture (three layers)
- **Primitives** — raw scales: color values (OKLCH), spacing increments, radius, elevation, type families, motion durations
- **Semantic tokens** — role-based: `text.primary`, `surface.raised`, `action.primary`, `feedback.success`
- **Component tokens** — component-level: `button.padding`, `card.shadow`, `input.border`

Rule: name tokens by ROLE, not raw value. `action.primary` not `blue-500`.

### Theme Model
Themes are collections of token values, not just light/dark toggle:
- Light / Dark (required for most products)
- High contrast (when accessibility profile demands it)
- Reduced motion (real system mode, not a margin note)
- Density mode: compact/cozy (only when product needs it)

### Cross-Platform Truth
- `design-tokens.json` is the source of truth
- CSS variables are one export
- React Native tokens are another export
- SwiftUI tokens are another export
- Do NOT let the CSS layer become the source of truth

### The Token File Is the Agent-Consumable Contract
Components are now assembled by coding agents, not only hand-built by humans (Brad Frost, "Agentic Design Systems"; Generative UI, 2026). `design-tokens.json` is therefore the machine-readable contract an agent reads to style any screen on-DNA without re-deriving the aesthetic. Two rules follow:
- **Every DNA invariant from `DESIGN.md` must be expressible as a token an agent can read.** A motion-physics invariant becomes a named easing token; an accent-hue invariant becomes a semantic color token. If an invariant cannot round-trip into a token, it cannot be enforced at assembly time.
- **No magic values in component specs.** When an agent reads "use the primary action color," it must resolve to `action.primary` in the token file — never an inline hex. Anything left as prose becomes drift when an agent generates the next screen.

---

## Phase A — Import Context & Pattern Audit

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `.sigma/runtime-baseline.json`, `docs/ux/UX-DESIGN.md`, `DESIGN.md`, `docs/design/ui-profile.json`.
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
3. Read Step 5 flow PRDs: `docs/prds/flows/*/FLOW-*.md`, `docs/prds/flows/PRD-SUMMARY.md`.
4. **Detect Step 5 artifact path:** parse `PRD-SUMMARY.md` and the tracker for provenance, then inspect the committed artifact:
   - If `docs/prds/flows/*/visual-artifact/` contains a source artifact and `VISUAL-ARTIFACT.md` → load the source/export as evidence for token seeding.
   - If `docs/prds/flows/*/screens/` contains Direct artifacts → extract repeated patterns from the actual artifacts.
   - Legacy imported visual fixtures may remain readable for migration, but new Step 5 work writes only `visual-artifact/` or `screens/`.
   - If neither is present, retain Step 3 as the source and record the missing Step 5 evidence; do not invent a visual source.
5. Read `.sigma/boilerplate.json` and `docs/stack-profile.json` if present.
6. If `research_mode = blocked` → stop. If `reduced` → label assumptions.

### Seed tokens from DESIGN.md (canonical source)

`DESIGN.md` (Step 3) holds the canonical design constraints. If the selected project has a verified compatible exporter, it may seed `design-tokens.json`; otherwise author the DTCG token file from the approved values and preserve traceability:

```bash
# W3C DTCG tokens.json — the same standard design-tokens.json must conform to
npx -y @google/design.md export --format dtcg DESIGN.md > docs/tokens/design-tokens.json
# Optional: Tailwind v4 @theme CSS for the web target
npx -y @google/design.md export --format css-tailwind DESIGN.md > docs/tokens/theme.css
```

Run that command only after confirming the package/version supports the requested export. Then enrich the result into the three-layer architecture below (primitives → semantic → component). The approved design decisions remain the source of truth; the exporter is an adapter. If it is unavailable or fails, hand-author the primitives from the approved source and record the result.

### Pattern Audit

Scan all Step 5 flow PRDs and identify repeated patterns:
- Button families (primary, secondary, ghost, destructive)
- Card families (content, action, stats, media)
- Form patterns (inputs, selects, toggles, validation)
- List/table patterns (data tables, list items, grids)
- Navigation structures (sidebar, tabs, breadcrumbs, command palette)
- Overlays (modals, drawers, sheets, popovers)
- Feedback (toasts, banners, alerts, empty/loading/error states)

Note where prototype screens are inconsistent — these need system normalization.

Finalize reusable patterns from the Step 5 runnable slice and approved prototype evidence. Provisional token preparation may continue from Step 3 when render evidence is unavailable, but label it provisional; it cannot establish visual acceptance.

### Visual artifact ingestion (when Canvas was used)

If the preflight detected `docs/prds/flows/*/visual-artifact/`, ingest the approved source/export as evidence for the token system. Do not start from scratch when a real approved artifact exists.

For each flow artifact:
1. Read `VISUAL-ARTIFACT.md` and the actual source/export contents (components, tokens, copy, and interaction notes only when present)
2. Extract token values:
   - **Colors** → primary/accent/surface/text values (convert to OKLCH if in hex/rgb)
   - **Typography** → font families, size scale, weights actually used
   - **Spacing** → padding/gap/margin values that appear repeatedly across the artifact
   - **Radius** → corner radii actually applied to cards, buttons, inputs
   - **Elevation** → shadow patterns in the artifact
   - **Component styling** → button/input/card styling actually rendered
3. Reconcile across artifacts:
   - If two artifacts use different values for the same role, choose one canonical value and document the deviation.
   - Cross-check against Step 3's UI Profile. Record drift and the resolution; an artifact does not overrule accessibility requirements.
4. Tag each extracted token with its actual artifact path and tool/provider in `design-tokens.json` metadata so downstream agents can trace origin.

**Rule:** an approved visual artifact informs the visual direction. Step 6 formalizes it into a reusable system and resolves conflicts with accessibility requirements or the published UI Profile explicitly.

### Direct artifact ingestion

If Direct was used, scan `docs/prds/flows/*/screens/` for repeated patterns and extract them. Use the platform's actual representation; do not reduce native artifacts to HTML assumptions.

### Sequential Decisions

**Decision 1: Theme scope**
Use AskUserQuestion: "What themes does this system need?"
Options: [Light + Dark, Light only, Dark only, Light + Dark + High Contrast, Custom — describe]

**Decision 2: Platform targets**
Use AskUserQuestion: "What platforms will consume these tokens?"
Options: [Web only (CSS variables + Tailwind), Web + React Native, Web + SwiftUI, All platforms, Already decided in stack-profile]

<HARD-GATE>
Do NOT proceed to Phase B until user approves pattern audit + scope.
Use AskUserQuestion: "Pattern audit complete, system scope defined. Approve?"
Options: [Approve — define principles and token architecture, Adjust scope, Audit more patterns]
</HARD-GATE>

---

## Phase B — System Principles, Token Architecture & Themes

### Research (directive queries)

1. Search `"design tokens [stack from stack-profile] 2026 best practices"` — current token patterns
2. Search `"OKLCH color system design tokens"` — modern color format
3. If Tailwind: Search `"Tailwind v4 @theme directive CSS variables tokens"` — integration approach
4. If shadcn: Search `"shadcn/ui v4 design tokens OKLCH data-slot"` — component patterns

### System Principles (answer these explicitly)

- What should always feel consistent?
- What should flex by platform?
- What tradeoffs are intentional?
- What does the system optimize for first: trust / density / speed / premium feel / accessibility / clarity?

### Token Architecture Definition

Define the three layers with naming conventions:

```
primitives/
  color/     → oklch values in scales (50-950)
  spacing/   → 4px base scale (0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64)
  radius/    → none, sm, md, lg, xl, full
  elevation/ → shadow scales
  typography/→ families, sizes, weights, line-heights
  motion/    → durations, easing curves

semantic/
  surface/   → background, raised, overlay, sunken
  text/      → primary, secondary, muted, inverse
  border/    → default, strong, muted
  action/    → primary, secondary, destructive, ghost
  feedback/  → success, warning, error, info

components/
  button/    → padding, gap, font-size per size variant
  input/     → padding, border, focus-ring
  card/      → padding, shadow, radius
```

### Theme Structure

Define token overrides per theme. Each theme maps semantic tokens to different primitive values.

<HARD-GATE>
Do NOT proceed to Phase C until user approves principles + token architecture.
Use AskUserQuestion: "Token architecture and principles defined. Approve?"
Options: [Approve — define foundations, Adjust token naming, Change theme model]
</HARD-GATE>

---

## Phase C — Foundations & Component Styling

### Color System
- Use OKLCH for perceptually uniform scales: `oklch(lightness chroma hue)`
- Define only the scales the selected component system needs; an 11-step web scale is an option, not a requirement for every platform
- Map to semantic roles (surface, text, action, feedback)
- Surface and accent roles follow the approved content/action hierarchy
- All pairings must meet WCAG 2.2 AA contrast (4.5:1 body, 3:1 large/UI)

### Typography System
- Define heading, body, and mono families from UI Profile
- Use the approved DNA typography invariant and existing brand or platform constraints. Inter, Roboto, Arial and system fonts are valid when that direction explicitly chooses them.
- Use a distinctive pairing only when it supports the approved direction and readable product use.
- Size scale that accounts for readability and dynamic type scaling
- Weight strategy (regular, medium, semibold, bold — define which contexts use which)

---

## Token Fit and Traceability (required — invoke design-taste + design-tokens)

**Invoke `design-taste` and `design-tokens` now.** Primitive values must be traceable to the approved DNA, brand and product use. The three-tier hierarchy is only valuable when its values are intentional rather than unexamined defaults.

### Distinctiveness Rules for Primitive Token Values

**Color primitives:**
- The `color.action.primary` chain must be derived FROM the DNA's color story (locked in Step 3's named direction and recorded in `DESIGN.md`). It is NOT a default brand color chosen by the token system.
- If a blue-purple hue is not supported by the DNA or brand, choose the hue the color story dictates. An explicitly chosen blue-purple is valid.
- **Neutral base:** use the approved neutral or tinted surfaces. Evaluate contrast and appearance in the actual theme rather than applying an absolute black/white ban.
- Assign accents to deliberate action, feedback or categorical roles. Do not impose one accent count or saturation ceiling across unrelated products.
- All OKLCH values must be intentional: the lightness, chroma, and hue should each have a rationale tied to the DNA's material invariant and stance.

**Typography token values:**
- Heading family must come from the DNA's typography invariant (the "one type move that's unmistakable"). If the DNA doc says Fraunces + Geist Mono, those are the primitive values. Do not default to a "safe" alternative.
- Preserve an explicitly chosen Inter, Roboto, Arial or system stack. Otherwise select the family that the typography invariant and readability requirements support.
- Explain the chosen family or pairing through the approved direction and readable product use; a single system font is valid.

**Motion primitive values:**
- Prefer platform-native motion where appropriate. Custom easing follows the approved purpose and interaction frequency; a brand metaphor must not override immediate keyboard response or tested behavior.
- Duration tokens reflect the tested interaction. Include an immediate/no-motion option for frequent actions, and verify reduced-motion behavior; example durations are not acceptance evidence.

### Token Anti-Slop Checklist (run at Phase E before $holes)

**Invoke `design-taste` for a final audit pass against this checklist.**

- [ ] `color.action.primary` is traceable to the approved DNA or brand; a blue-purple hue has an explicit rationale when used
- [ ] `typography.heading` and `typography.body` match the approved typography invariant, including any intentional familiar or system font
- [ ] Text and surface colors meet the contrast and appearance contract; neutral or chromatic choices follow the approved direction rather than a blanket color ban
- [ ] The neutral base, whether untinted or warm/cool, supports the approved hierarchy and material direction
- [ ] Custom motion has an explicit purpose; repeated keyboard interactions are immediate, and platform-native motion is retained where appropriate
- [ ] Decorative treatments are justified by the selected surface and reference contract; none are required merely to appear distinctive
- [ ] Primary actions have a clear emphasis; additional semantic or categorical hues have named roles and are not the only way to convey meaning
- [ ] Shadows and elevation match the approved depth model and actual theme; avoid an untested universal opacity recipe
- [ ] Component token values reference semantic tokens — zero direct primitive references from the component tier
- [ ] `design-tokens` DTCG compliance verified: every token has `$type` + `$value`; no flat key-value dumps

**The test:** Load `DESIGN.md` and read its 5 invariants. Then open `design-tokens.json`. Every primitive value should be explainable by one of those invariants. If a value cannot be traced to an invariant, it is a generic default and must be replaced.

---

### Spacing & Layout System
- Coherent scale based on 4px increments
- Density mode support when product needs compact views
- Document spacing tokens for padding, gap, margin contexts

### Shape, Radius, Border & Elevation
- Radius tokens matched to Design DNA (sharp = 0-2px, rounded = 6-12px, pill = full)
- Elevation/shadow reinforces hierarchy without visual noise
- Borders separate only where hierarchy, grouping, input affordance, or platform convention calls for them; do not turn every surface into a card
- Define shell, content, and task hierarchy explicitly so surfaces have a purpose rather than a uniform card treatment

### Iconography
- Consistent stroke/fill logic and optical weight
- Icon sizing aligned to typography scale
- Source library reference (Lucide, Phosphor, SF Symbols, etc.)

### Component Styling Logic

For each repeated family from Phase A pattern audit:

| Component | Variants | Sizes | Density | States (style only) | Platform Notes |
|-----------|----------|-------|---------|---------------------|----------------|
| Button | primary, secondary, ghost, destructive | sm, md, lg | compact/cozy | default, hover, active, disabled, loading | |
| Input | text, select, textarea | sm, md, lg | compact/cozy | default, focus, error, disabled | |
| Card | content, action, stats | — | — | default, hover, selected | |

Define for each: purpose, token references, hierarchy rules, what stays stable vs. adapts by platform. Document which input and interaction patterns vary by web, touch, native, or desktop host; a token or component rule must not silently cross platform boundaries.

Do NOT create full component API docs — define styling logic only. Step 7 handles states. Step 8 handles implementation.

<HARD-GATE>
Do NOT proceed to Phase D until user approves foundations + component styling.
Use AskUserQuestion: "Foundations and component styling defined. Approve?"
Options: [Approve — define motion and accessibility, Adjust color system, Revise components]
</HARD-GATE>

---

## Phase D — Motion, Accessibility & Platform Export

### Motion System
- Duration tokens: instant (0ms), fast (100ms), normal (200ms), slow (300ms), slower (500ms)
- Easing tokens: ease-in, ease-out, ease-in-out, spring, bounce
- Stagger tokens: base (50ms), fast (30ms), slow (100ms)
- Motion roles: feedback, transition, entrance, exit, emphasis
- **Reduced-motion is a real system mode** — `prefers-reduced-motion` must be respected
- Motion communicates, it does not decorate (Design DNA rule)

### Accessibility Foundations (system-level)
- Color contrast: 4.5:1 body text, 3:1 large text / UI components (WCAG 2.2 AA)
- Focus visibility: explicit focus-ring tokens (width, offset, color)
- Touch targets: meet the applicable platform sizing rules; web pointer targets follow WCAG 2.2 AA (24 by 24 CSS pixels or a documented qualifying exception). Prefer larger touch targets and record the chosen size/spacing and input mode
- Typography scaling: system must survive 200% text zoom
- Reduced-motion: all motion tokens have a reduced-motion fallback

### Platform Export Strategy

| Platform | Export Format | Token Source |
|----------|-------------|-------------|
| Web | CSS custom properties (via Tailwind v4 `@theme` or standalone) | design-tokens.json |
| React Native | TypeScript token module | design-tokens.json |
| SwiftUI | Swift constants or asset catalog | design-tokens.json |
| macOS desktop (Electron/Tauri/native) | CSS vars + window-chrome tokens | design-tokens.json |

Rule: JSON is the truth. Platform exports are derived artifacts.

**Desktop macOS guidance:** When the stack includes a desktop macOS surface, invoke `macos-design` for window-chrome conventions (traffic lights, drag zones, sidebar layout), backdrop-blur/vibrancy values, and a radius scale appropriate to the product and host. Record the rationale; do not impose a fixed macOS radius scale across every product.

<HARD-GATE>
Do NOT proceed to Phase E until user approves motion + a11y + export strategy.
Use AskUserQuestion: "Motion, accessibility, and platform export defined. Approve?"
Options: [Approve — assemble final outputs, Adjust motion tokens, Strengthen accessibility rules]
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Token bloat (families that exist without a reason)
- Missing accessibility constraints
- Inconsistency between design-tokens.json and DESIGN-SYSTEM.md
- Step 7/8 work absorbed into Step 6
- Design DNA contradictions

Fix findings before presenting.

### Write `docs/design/DESIGN-SYSTEM.md`

Required sections:
```
System Principles
Token Architecture (three layers explained)
Theme Model
Color System
Typography System
Spacing & Layout System
Shape, Radius, Border & Elevation
Iconography
Component Styling Logic
Motion System
Accessibility Foundations
Platform Export Strategy
shadcn Preset (when shadcn/ui is in the stack — export design system as a shareable preset code)
Step 7 Handoff — what Step 7 must expand into full state catalog
Step 8 Handoff — what Step 8 must implement
Do NOT Build in This Step
```

### DTCG 2025.10 token exchange

Use the [DTCG Format Module 2025.10](https://www.designtokens.org/tr/2025.10/format/), a stable Community Group report, not a W3C Recommendation. Verify the selected importer's supported format.

```json
{
  "color": {
    "action": {
      "primary": {
        "$type": "color",
        "$value": { "colorSpace": "oklch", "components": [0.55, 0.22, 250] },
        "$extensions": { "com.sigma.role": "action-primary" }
      }
    }
  }
}
```

- Use nested groups; token/group names cannot contain periods or braces or start with `$`.
- A token has `$value`; `$type` can be explicit or inherited. `string` is not a standard token type.
- Colors use structured values per the [Color Module](https://www.designtokens.org/tr/2025.10/color/). CSS `oklch(...)` strings belong in generated CSS, not this exchange format.
- Do not use a documentation page URL as a JSON Schema. Validate with the chosen tool and record its version and result.
- Brand/mode organization is project-specific; prove import and export for each selected target.

**Generate `docs/tokens/style-dictionary.config.json`** alongside `design-tokens.json`. This config drives `style-dictionary build` to export CSS variables, React Native modules, and any other platform targets selected in Phase A.

```json
{
  "source": ["docs/tokens/design-tokens.json"],
  "platforms": {
    "css": {
      "transformGroup": "css",
      "prefix": "token",
      "buildPath": "docs/tokens/output/",
      "files": [{ "destination": "tokens.css", "format": "css/variables" }]
    },
    "js": {
      "transformGroup": "js",
      "buildPath": "docs/tokens/output/",
      "files": [{ "destination": "tokens.js", "format": "javascript/es6" }]
    }
  }
}
```

Add platform entries for `react-native` and `ios-swift` only when those platforms are in the project's target list.

### Write `docs/tokens/design-tokens.json`

```json
{
  "$extensions": {
    "com.sigma": { "name": "[project]", "version": "1.0.0", "dtcg": "2025.10", "sourceStep": "6", "uiProfile": "[id]", "updated": "[date]" }
  },
  "primitives": {
    "color": {},
    "spacing": {},
    "radius": {},
    "elevation": {},
    "typography": {},
    "motion": {}
  },
  "semantic": { "surface": {}, "text": {}, "border": {}, "action": {}, "feedback": {} },
  "components": { "button": {}, "input": {}, "card": {} },
  "themes": {
    "light": {},
    "dark": {},
    "high-contrast": {},
    "reduced-motion": {}
  },
  "brand-default": {}
}
```

Every token entry inside these groups must follow the DTCG `{ "$type": "...", "$value": "..." }` form.

### Writing Standards (embedded)

- No stock AI phrases: "Cohesive", "Harmonious", "Pixel-perfect", "Consistent across"
- Token names are decisions, not descriptions — `action.primary` not `the main action color`
- System principles are concrete rules, not aspirational statements
- Write like a systems engineer defining a contract, not a designer writing a mood board

### Success Criteria

- [ ] Step 3 DNA and UI Profile imported; `DESIGN.md` read and 5 invariants confirmed as the source for primitive token values
- [ ] Step 5 prototype patterns imported and normalized
- [ ] Token values are formalized from the proven runnable slice or approved prototype evidence, with shell/content/task hierarchy and purposeful borders explicit
- [ ] Theme, input, and component rules state their platform scope
- [ ] design-tokens.json is machine-readable and role-based
- [ ] Themes are explicit (not just light/dark toggle)
- [ ] Motion supports reduced-motion mode; custom motion follows tested interaction frequency and purpose; native transitions remain platform-owned
- [ ] Typography traces to the approved DNA, brand and readability requirements; any familiar or system font is intentional
- [ ] Color meets WCAG 2.2 AA contrast requirements; primary and neutral choices trace to the approved color story
- [ ] **Token anti-slop checklist ran** (invoked `design-taste` + `design-tokens`; all 10 checklist items passed)
- [ ] Every primitive token value is traceable to one of the DNA's 5 invariants
- [ ] Accessibility expressed as system rules
- [ ] Component styling is reusable, not screen-specific; component tier references semantic tokens only (zero direct primitive references)
- [ ] Platform export intent is clear
- [ ] Step 7 and Step 8 handoffs explicit
- [ ] $holes pass completed
- [ ] Linear tracking issues created (when configured)
- [ ] User approved

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 7 without explicit approval.
Use AskUserQuestion: "Step 6 complete. Ready for Step 7 — Interface States?"
Options: [Proceed to Step 7, Revise design system, Adjust token architecture]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 6 Verification Schema

### Required Outputs (30 points)

| Item | Path | Points |
|------|------|--------|
| Design System Document | docs/design/DESIGN-SYSTEM.md | 18 |
| Design Tokens JSON | docs/tokens/design-tokens.json | 12 |

### Required Sections in DESIGN-SYSTEM.md (35 points)

| Section | Points |
|---------|--------|
| System Principles | 4 |
| Token Architecture (three layers) | 5 |
| Theme Model | 4 |
| Color System (OKLCH, role-based, contrast-checked) | 5 |
| Typography System (distinctive fonts, scaling) | 4 |
| Spacing & Layout System | 3 |
| Component Styling Logic | 4 |
| Motion System (with reduced-motion) | 3 |
| Accessibility Foundations | 3 |

### Quality Indicators (25 points)

| Check | Points |
|-------|--------|
| Tokens are role-based, not raw value dumps | 3 |
| Themes are explicit and complete | 3 |
| Typography traces to the approved DNA, brand and readability requirements | 4 |
| Color meets WCAG 2.2 AA contrast and traces to the approved color story | 4 |
| Motion respects prefers-reduced-motion; custom motion follows tested frequency/purpose and native transitions remain platform-owned | 3 |
| design-tokens.json matches DESIGN-SYSTEM.md | 2 |
| Platform export strategy is clear | 1 |
| Token anti-slop checklist passed (design-taste + design-tokens invoked; all primitive values traceable to DNA invariants) | 5 |

### Handoff & Boundary (10 points)

| Check | Points |
|-------|--------|
| Step 7 handoff explicit | 3 |
| Step 8 handoff explicit | 3 |
| No Step 7/8 scope absorbed | 2 |
| $holes pass completed | 2 |
| Linear tracking issues created (when configured) | 1 |

**Passing score:** 95/100

## CRAFT (award standard) — scored by step-verify-gate (deterministic) + the judge; never self-attested. See references/award-standard.md.
<VERIFY-ASSERT>
craft_antislop docs/design/*.md
</VERIFY-ASSERT>

## DNA Conformance — scored by step-verify-gate (deterministic); never self-attested. Requires .sigma/standards.json from Step 3. Missing file → advisory skip (not a fail). See schemas/standards.schema.json.
<VERIFY-ASSERT>
dna_conformance docs/design/*.md
</VERIFY-ASSERT>
</verification>

$END$
