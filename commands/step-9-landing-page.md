---
version: "2.2.0"
last_updated: "2026-09-19"
description: "Step 9: Landing Page → LANDING-PAGE.md — conversion-focused page strategy, copy system, avatar/diary empathy engine, and Track A/B/Hybrid implementation paths"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --page-type
  - --avatars-only
  - --template-only
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

- `direct-response-copy`
- `copywriting`
- `marketing-copywriting`
- `conversion-optimization`
- `frontend-design`
- `motion-landing-design` — Phase D (Divergence + Motion Concept)
- `threejs` — Phase D (3D/WebGL hero, when the direction calls for it)
- `shadcn`
- `image-to-code` — reference-site / screenshot capture (Track B)
- `demo-video-pipeline`
- `deep-research`
- `design-taste`
- `ux-psychology-pro`
- `web-design-guidelines`

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-9-landing-page — Landing Page Strategy, Copy & Template Mapping

**On start, announce:** "Running Step 9: Landing Page. I'll turn the offer and product story into a landing page that converts — using avatar empathy, conversion psychology, and the Design DNA."

**Note:** Step 9 is optional. Skip when the product doesn't need a marketing/conversion page yet.

<goal>
You are the Landing Page Strategy Lead. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Context & Page Type | Offer inputs + page type + audience |
| B | Customer Research & Empathy Engine | Avatar + labeled empathy hypotheses/actual diary evidence + sources |
| C | Page Strategy & Copy System | Message hierarchy, hero, proof, objections, CTA |
| D | Template Selection & Visual Generation | Template mapping + optional direct HTML/shadcn scaffolding |
| E | Output, Hardening & Handoff | LANDING-PAGE.md + implementation handoff |

Required Outputs:
- `docs/landing-page/LANDING-PAGE.md`
- `docs/avatars/PROBLEM-AWARE-AVATAR.md`
- `docs/avatars/DIARY-ENTRIES.md`
- `docs/research/LANDING-SOURCES.md`

Conditional: `docs/landing-page/TEMPLATE-MAPPING.md`, `docs/landing-page/CTA-VARIANTS.md`

Quality gate: 95+/100 on applicable verification criteria. Record conditional N/A rows and normalize earned/applicable points; missing required evidence or approvals cannot be scored away.

**Core rule:** The page has one dominant goal. Every section either builds belief or removes an objection. Nothing else belongs on the page.
</goal>

---

## Trigger

**Run after Step 8 (Technical Spec) is approved, OR skip if the product doesn't need a marketing/conversion page.** Step 9 is optional. It consumes Step 1.5 (offer architecture) and Step 6 (design system) outputs.

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
- Step start: create issue "Step 9: Landing Page" — labels `step-9`, `wave:W0`, state In Progress.
- Milestone issues as sections land: "Step 9: Avatar & empathy engine", "Step 9: Copy system", "Step 9: Template mapped" — labels `step-9`, `wave:W0`.
- On LANDING-PAGE.md completion: move the tracking issue to Done.

---

## Step Boundary

- **Step 9 owns:** landing page strategy, message hierarchy, conversion copy, above-the-fold clarity, avatar/diary empathy engine, social proof strategy, objection handling, CTA system, template selection, implementation handoff.
- **Step 9 does NOT own:** pricing/offer architecture (Step 1.5), product UI (Steps 3-8), boilerplate setup (Step 0).
- **Do NOT** re-litigate pricing, COGS, or offer architecture. Consume Step 1.5 outputs.

---

## Conversion Principles

Method sources checked 2026-09-19: [Copyhackers](https://copyhackers.com/) for customer-language/message development; [Wynter](https://wynter.com/landing-page-testing) for audience comprehension and relevance; [Dunford](https://www.aprildunford.com/books) for positioning-to-pitch alignment. Vendor case-study lifts are not predictions for this page.

### MECLABS conversion heuristic
`C = 4M + 3V + 2(I-F) - 2A`
- **M (Motivation):** How badly does the visitor want this? (highest weight)
- **V (Value Proposition):** Why should they choose you over alternatives?
- **I (Incentive):** What pushes them to act now?
- **F (Friction):** What makes it hard? (forms, confusion, steps)
- **A (Anxiety):** What scares them? (trust, risk, commitment)

### Above-the-fold comprehension check
Test whether representative visitors understand these three things. A five-second test is one useful diagnostic, not a universal conversion law:
1. What this is (value proposition)
2. Why it matters to them (relevance)
3. What to do next (CTA)

Search visibility and AI-discovery claims require their own source and measurement; visual hierarchy alone does not prove indexing or recommendation behavior.

### Message Match
Match the visitor's intent and the substantiated promise in the traffic source. Correct unsupported promises rather than repeating them. Preserve the underlying meaning, not necessarily identical wording.

### One Page, One Dominant Action
- One primary CTA (what you want most visitors to do)
- One optional supporting CTA (lower commitment alternative)
- No competing navigation, no sidebar distractions, no feature tours

### Avatars & Diaries Are the Empathy Engine
They are required because they sharpen every word on the page:
- What the visitor already believes
- What they fear
- What they want fast
- What objections must be handled on-page
- What language feels human vs corporate

---

## Phase A — Import Context & Page Type

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `docs/specs/MASTER_PRD.md`, `docs/specs/OFFER_ARCHITECTURE.md` (if Step 1.5 ran), `docs/specs/pricing-config.json` (if applicable).
3. Read `DESIGN.md`, `docs/design/ui-profile.json`, `docs/design/DESIGN-SYSTEM.md`.
4. Read `.sigma/runtime-baseline.json` for tool availability (shadcn MCP, `/clone` skill, asset generation keys).
- Read `.sigma/standards.json` if present (emitted by Step 3). Use its `dna_conformance` assertions as hard constraints for this step's outputs. If missing → record an advisory in the step report ("DNA standards file absent — Step 3 may not have completed; DNA gate will skip") and continue; do not invent substitute DNA rules.
5. If `research_mode = blocked` → stop. If `reduced` → label assumptions.

### Asset generation check

Check `.sigma/runtime-baseline.json` and environment for:
- `GOOGLE_API_KEY` or `GEMINI_API_KEY` → enables Nano Banana Pro 2 image generation (hero images, product mockups, illustrations, social proof visuals)
- If key exists → record in runtime baseline as `"asset_generation": { "nano_banana": true, "model": "nano-banana-2" }`
- If key missing → note that hero images and custom visuals must be sourced manually or via stock

When Nano Banana Pro 2 is available, Step 9 can generate:
- Hero section visuals (product screenshots, lifestyle imagery, abstract brand art)
- Social proof imagery (before/after visuals, data visualizations)
- OG images / social preview cards (1200x630)
- Favicon and app icon concepts
- Background textures and patterns matching the Design DNA

Use the `$media-generation` skill for the actual generation. Apply frontend aesthetics DNA — generated images must match the Design DNA archetype, not default to generic AI stock art.

### Sequential Decisions

**Decision 1: Page type**
Use AskUserQuestion: "What type of landing page?"
Options: [Product marketing page (SaaS/app), Waitlist / coming soon, Demo / signup / free trial, Course / coaching sales page, Portfolio / services page, Other]

**Decision 2: Primary conversion action**
Use AskUserQuestion: "What's the one thing you want visitors to do?"
Options: [Sign up / start free trial, Join waitlist, Book a demo/call, Buy now / enroll, Download / get access, Other]

**Decision 3: Traffic source**
Use AskUserQuestion: "Where is traffic coming from?"
Options: [Organic search / SEO, Paid ads (Google/Meta), Social media / content, Email list, Product Hunt / launch, Cold outreach, Multiple sources]

Evidence: named audience, real traffic source, offer version, single conversion goal and current baseline; choose a page type for that task, not a default template.

<HARD-GATE>
Do NOT proceed to Phase B until user approves page type + action + audience.
Use AskUserQuestion: "Page type and primary action locked. Approve?"
Options: [Approve — build avatar and research, Revise page type, Change primary action]
</HARD-GATE>

---

## Phase B — Customer Research & Empathy Engine

### Research (directive queries)

1. Search `"[product domain] landing page examples 2026"` — find competitor pages
2. Search `"[target user] frustration [problem domain]"` — find real user language
3. Search `"[product category] objections buying concerns"` — find objection patterns
4. If high-ticket: Search `"[price range] [category] sales page conversion"` — find comparable offers

### Create `docs/avatars/PROBLEM-AWARE-AVATAR.md`

| Dimension | Answer |
|-----------|--------|
| Problem awareness level | [Unaware / Problem-aware / Solution-aware / Product-aware / Most-aware] |
| Desired outcome | [specific transformation] |
| Current workaround | [what they do today] |
| Top 3 objections | [what stops them from buying] |
| Buying triggers | [what pushes them to act] |
| Proof sensitivity | [what type of proof they trust — data, testimonials, case studies, authority] |
| Language register | [technical, casual, aspirational, urgent] |

### Create `docs/avatars/DIARY-ENTRIES.md`

Write 3–5 clearly labeled empathy hypotheses unless actual diary-research consent and records exist. Never present synthetic first-person entries as interviews or customer quotations. Capture:
- Frustration moments (in the avatar's own voice)
- Moments of hesitation before buying
- What they wish existed
- Emotional vocabulary that informs headlines and objection copy

### Create `docs/research/LANDING-SOURCES.md`

Document: competitor pages analyzed, proof sources found, objection patterns identified, language patterns extracted.

Evidence: customer-language source links and sample limitations; label inferred avatars/diaries explicitly. Record the unresolved buying question to test.

<HARD-GATE>
Do NOT proceed to Phase C until user approves avatar + diary + research.
Use AskUserQuestion: "Avatar, source evidence and labeled empathy hypotheses complete. Approve?"
Options: [Approve — write page strategy, Deepen avatar research, Adjust target audience]
</HARD-GATE>

---

## Phase C — Page Strategy & Copy System

### Define in `LANDING-PAGE.md`:

**Offer Translation:** What Step 1.5 decided, translated into page language. What transformation are we selling? What's the value equation score?

**Message Hierarchy:** What must be communicated, in what order:
1. Above the fold — value proposition and CTA, tested for comprehension
2. Proof block — social proof that reduces the #1 objection
3. Features/benefits — tied to the avatar's desired outcome, not feature lists
4. Objection handling — each section answers a real objection from the avatar
5. Risk reversal — guarantee, trial, money-back, conditional
6. Final CTA — reinforced with urgency or scarcity (only if real)

**Hero Strategy:**
- Headline: names the outcome, not the product
- Subheadline: explains how or why it's different
- CTA: outcome-based copy (not "Get Started" — use "Start [doing the thing they want]")
- Visual: product screenshot, demo video, or social proof number

**Social Proof Strategy:** What type matches the avatar's proof sensitivity:
- Data points (users, revenue impact, time saved)
- Testimonials (specific, attributed, outcome-focused)
- Logos (only if recognizable to the target audience)
- Case studies (before/after with numbers)

**Objection Handling:** Map each avatar objection → page section that neutralizes it.

**CTA Strategy:**
- Primary CTA copy (outcome-based, not generic)
- Supporting CTA (lower commitment — "Watch demo", "See pricing")
- CTA placement (above fold, after proof, after objections, sticky mobile)
- If testing variants: mark `CTA Variant Artifact: Yes` → create `CTA-VARIANTS.md`

**Mobile Conversion Rules:**
- CTA visible without scrolling on mobile (500-600px viewport)
- Form friction minimized (3 fields max for first conversion)
- Touch targets 44px minimum
- No horizontal scroll

**Cognitive Load Rules (invoke `ux-psychology-pro`):**
- **Hick's Law** — one dominant CTA above the fold. Multiple competing CTAs slow decision time logarithmically.
- **Miller's Law** — feature lists and nav clusters cap at 7 items (5 is better).
- **Doherty Threshold** — page interactive in <400ms. Anything slower breaks flow and kills conversion.
- **Aesthetic-Usability Effect** — visual polish is conversion polish; it shifts perceived trust.
- **Peak-End Rule** — design the peak (hero or proof block) and the end (final CTA) — visitors judge the whole page by these two moments.

Evidence: message hierarchy, alternatives and differentiation, each claim paired with substantiation, objections, and a measurable CTA hypothesis. Use Copyhackers-style voice-of-customer research and Wynter-style clarity/relevance feedback as applicable.

<HARD-GATE>
Do NOT proceed to Phase D until user approves page strategy.
Use AskUserQuestion: "Page strategy and copy system complete. Approve?"
Options: [Approve — select template and generate visuals, Revise message hierarchy, Adjust CTA strategy]
</HARD-GATE>

---

## Award-Grade Marketing-Amplitude Bar

The landing page is the product's **marketing-amplitude / cinematic** surface — the place the named Design DNA is allowed to perform at full volume. This is NOT a "design a hero then add sections" exercise. The bar here is the same bar step-5 enforces for marketing-amplitude screens, applied to the full page.

An award-grade landing page is defined by three non-negotiables:

1. **Fresh research, not memory.** The page's visual identity and motion concept must come from current, real award-tier references for THIS product's domain — not from what the LLM has seen before, not from last year's SaaS patterns, not from this step's own prior outputs.
2. **Named direction chosen by the operator, not by the agent.** The agent proposes; the operator picks. A self-chosen direction is not a direction — it is the statistical mean of every landing page the model was trained on.
3. **Verified, not assumed.** The page is screenshot-verified at 375px and 1440px, and the reduced-motion branch is rendered and checked for stranding before the step is declared done.

This bar applies across all tracks (A, B, Hybrid). The divergence protocol in Phase D is the mechanism. The sections below are the explicit requirements that make it enforceable.

### Anti-Slop: Design Rules (expanded)

**Invoke `design-taste` at Phase D before any production work.** Apply `web-design-guidelines` as a final compliance check at Phase E.

The following patterns are **banned as defaults** — if any appear in the output, it is a slop tell and must be replaced:

| Banned pattern | Why it fails | Award-grade alternative |
|---------------|-------------|------------------------|
| Centered hero + proof strip + features + pricing + testimonials + CTA | This is the template every LLM defaults to; it signals zero design intent | Derive the structure from the page's *single dominant narrative* — what is the one arc the visitor must travel? |
| Radial glow / blurred orb behind hero text | Stock "futuristic" shortcut; feels unearned | Use a material treatment from the DNA (grain, mesh, geometric, editorial negative space) |
| Gradient fill on H1 heading | An often-repeated stylistic default; use only when it supports the chosen direction | Reserve gradients for illustration/background; headlines use the DNA's type weight and color |
| Frosted glass cards as the primary card treatment | Overused in 2023-2024; now the default of defaults | Use the DNA's surface/depth model for cards (flat, paper, machined, inked — whatever the invariant says) |
| Three equal feature cards in a horizontal row | The most common layout failure; implies the product has no hierarchy | Use asymmetric grid, 2-col zig-zag, or a bento that interlocks |
| Dark navy or black background + neon/electric accent | The "dark SaaS" default; a shortcut that lands everywhere | Only use dark if the DNA's material invariant specifies it AND the palette derives from the color story, not from a default neon |
| AI-purple as the primary accent (oklch hue 280-300) | Universal LLM default; invisible differentiation | Derive accent from the DNA's color story; if it happens to be that hue, document the deliberate choice |
| Full-bleed hero image from stock photography | No specificity; zero brand signal | Use product screenshots, real data viz, brand illustrations, or a generated asset via `$media-generation` with strict DNA conformance |

### Anti-Slop: Copy Rules (expanded)

**Invoke `direct-response-copy`, `copywriting`, `marketing-copywriting`, and `conversion-optimization` at Phase C** before writing section copy. The psychology layer (`ux-psychology-pro`) surfaces objections; the copy skills turn empathy into specific words.

**Invoke `ux-psychology-pro` at Phase C** before writing any copy. The psychology layer surfaces the *real objections and motivations* that make copy specific. Generic copy is a symptom of skipped empathy research.

The following copy patterns are banned regardless of track:

- "Trusted by..." / "Loved by..." / "Used by..." — meaningless without specificity; use real numbers with sources
- "Get Started" / "Start Free Trial" / "Book a Demo" as CTA copy — write outcome-based copy ("Start tracking your pipeline", "Run your first analysis")
- "Simple, honest pricing" / "Plans that scale" / "Everything you need" — none of these are claims; replace with the actual value
- "Ready to [verb]?" as the closing CTA headline — the laziest ending pattern
- "In today's [adjective] landscape..." — banned phrase opener
- "Game-changing" / "Revolutionary" / "Best-in-class" / "Cutting-edge" / "Next-gen" — no modifier without a measurement
- "Intuitive" / "Seamless" / "Frictionless" — design can demonstrate these; copy that says them is a self-assessment, not a proof
- Round fake numbers ("10,000+ users", "99.9% uptime") without sourced evidence — use real organic numbers or omit
- Any testimonial not from a real, attributable person with their role and company

### Verification Doctrine (evidence, not assertion)

Before Phase E declares done:

1. **Screenshot at 375px (mobile) and 1440px (desktop).** Capture at both. Run a documented comprehension check on both; record participant/sample limitations. Screenshots alone do not prove comprehension: value + relevance + CTA all visible without scrolling on mobile. Save screenshots to `docs/landing-page/`.
2. **Reduced-motion stranding check.** Load the page with `prefers-reduced-motion: reduce` forced. Every content element that appears via animation in the full-motion version must be visible in the reduced-motion version. Nothing may be stranded off-screen, invisible, or mid-transition. If a section only appears via a scroll-triggered animation, the reduced-motion version must render its final state on page load. Document each motion moment's reduced-motion equivalent in `MOTION-CONCEPT.md`.
3. **DNA conformance check.** Open `DESIGN.md`. Confirm the page's material, typography, motion physics, surface stance, and truthfulness all match the DNA's 5 invariants at cinematic amplitude. A stranger looking at the app and the landing page must immediately recognize them as the same product.
4. **Truthful copy pass.** Every metric, logo, testimonial, scarcity claim, and guarantee verified against reality and Step 1.5. Nothing unsubstantiated ships.

"Looks good in the code" is not verification. Screenshots + rendered check + DNA trace = verification.

---

## Phase D — Track Selection & Visual Generation

Step 9 supports three implementation paths. Pick one based on who iterates on the visuals and what kind of starting point the team wants.

### Track Comparison

| Path | Visual iterator | Starting point | Best for |
|------|----------------|---------------|----------|
| **Track A — Canvas visual-first (Pen.dev)** | Operator and agent using the detected canvas interface | Blank canvas → bundle | Client projects, founder review, when visual direction is uncertain |
| **Track B — Template/direct** (DEFAULT) | AI agent (from strategy + Design DNA) | shadcn block / boilerplate shell / repo template / direct HTML | Fast implementation, stack-native output, when Design DNA is clear |
| **Hybrid (A → B)** | Human in the selected canvas tool, then agent applies to template | approved canvas artifact seeds a template's visual layer | Want the selected canvas tool's polished visual direction AND a template's production-ready code scaffold |

**Default = Track B.** Track A is opt-in when `--visual-validate` flag is present, the page is high-stakes (founder reviewing, client project, paid launch), or the user picks it explicitly.

---

### Divergence Protocol (REQUIRED before production — all tracks)

The landing page is the product's **marketing-amplitude / cinematic** surface — the place the named Design DNA (from `DESIGN.md`) is allowed to perform at full volume. An award-grade page is NOT the default centered-hero + features + pricing template. Before any production work (HTML, visual brief, or template seed), run the divergence protocol in full.

**Invoke `motion-landing-design` now** — this IS its protocol; the steps below are the visible requirement so the gate is enforceable even if the skill is temporarily unavailable.

**Step 1 — Research fresh external references.**

**Invoke `deep-research` now.** Pull ≥2 current, real award-tier landing pages for this product's domain AND ≥1 from an adjacent domain. Sources: Awwwards, Godly, FWA, Siteinspire, agency sites from the last 12 months. Capture what makes each one feel distinctive — the *mechanism*, not the aesthetic label. Do NOT design from memory or reach for last year's pattern. Do NOT re-use references from Step 3's `DNA-REFERENCES.md` — the landing page research must be fresh to this surface.

For each reference:
- Name + URL
- The one motion or visual mechanism that makes it feel award-grade
- Why it works for that brand's story
- What idea you are taking as inspiration (mechanism only — not structure or template)

**Anti-anchor rule (absolute):** References are inspiration fuel, not blueprints. If the output's chapter order, section vocabulary, or palette energy matches any reference or any prior build, the divergence protocol was skipped. The brand's DNA and the product's story — not a remembered layout — decide the page.

**Step 2 — Propose 2-3 named creative directions.**

**Invoke `design-taste` now.** Propose exactly 2-3 named directions. Each gets:
- A **name** (an invented handle, not a descriptor — e.g. "Thermal Bloom", "Machined Slate", "Signal Paper")
- A **one-line concept** — the controlling idea
- A **brand-derived motion metaphor** — the motion concept must come FROM the DNA's motion-physics invariant and the product's core action, not from a scroll-trick library. What does this product's story feel like as motion? (e.g. a trading product whose core is "decisive execution" → motion is snappy, zero decoration, no overshoot; a creative-tools product whose core is "exploration" → motion has spring overshoot, invitation, gentle settlement)
- A **novelty quota** — ≥2 things this direction does that are NOT in any generic landing page template and NOT in the other proposed directions
- How it carries the named DNA at cinematic amplitude while remaining obviously the same product as the app

**Invoke `ux-psychology-pro`** to check each direction's motion metaphor against the avatar's emotional state (from Phase B): does the motion reinforce the visitor's buying emotion or fight it?

**Step 3 — Alignment gate (HARD).**

Present the 2-3 named directions to the operator/client and get an explicit pick BEFORE building.

Evidence: brief-derived visual direction with rationale, source references and a motion purpose or explicit static choice. Aesthetic presets are not conversion evidence.

<HARD-GATE>
Use AskUserQuestion: "Three named creative directions proposed for the landing page. Which direction do we build?"
Options: [Direction 1 — &lt;name&gt;, Direction 2 — &lt;name&gt;, Direction 3 — &lt;name&gt;, Blend — I'll specify, Research deeper — none land yet]
Do NOT proceed to production on a self-chosen direction. The pick is the operator's. If "Research deeper" is chosen, pull a new reference set and re-propose before returning to this gate.
</HARD-GATE>

**Step 4 — Write the motion-concept artifact (REQUIRED before production).**

Capture the chosen direction in `docs/landing-page/MOTION-CONCEPT.md`:
- Chosen direction name + concept
- The brand-derived motion metaphor: what the product's core action feels like as scroll/transition behavior, and where it appears (hero, scroll narrative, section transitions, CTA entrance)
- Per-section motion intent (what moves, why, at what amplitude, what easing curve)
- The **reduced-motion equivalent for every motion moment** (what the visitor sees with `prefers-reduced-motion: reduce` — no stranded content; every reveal must have a static final state that loads on page load)
- DNA invariants honored: material, type, motion physics, stance, truthfulness — mapped explicitly to the 5 invariants in `DESIGN.md`

Only after `MOTION-CONCEPT.md` exists do you proceed to the chosen track's production (Track A prompt, Track B HTML/template, or Hybrid).

---

### 2026 Motion & 3D Techniques (reference — apply only what the chosen direction needs)

Motion is in service of the narrative, never decoration. Pick techniques from `MOTION-CONCEPT.md`; do not bolt on effects the direction didn't call for. **Invoke `motion-landing-design` for scroll/transition work and `threejs` for any WebGL/3D hero.**

**Scroll-driven storytelling (the 2026 default for cinematic heroes):**
- **Native CSS scroll-driven animations (`scroll-timeline` / `animation-timeline: view()`) are the progressive-enhancement default for reveals, parallax, and progress effects** — they run off the main thread, need zero JS, and degrade gracefully in browsers that don't support them (the animation simply doesn't fire). Reach for them first; they cover most "elements animate as they enter" needs that previously required a library (Figma 2026 trends; "functional CSS scroll-driven animations").
- **GSAP ScrollTrigger image sequences on a pinned canvas** — for true frame-by-frame cinematic heroes that CSS can't express, pin a `<canvas>` section and draw a pre-rendered frame sequence as the user scrolls (the "Apple AirPods scroll" pattern). Scrub the frame index to `scrollTrigger` progress; draw to canvas rather than swapping `<img>` to avoid layout thrash.
- **Pinned sections + horizontal scroll panels** for chaptered narratives; release the pin cleanly so the page below is never stranded.
- Prefer transform/opacity-only animation (GPU-composited). Never animate layout properties (width/height/top/left) in scroll handlers.
- Decision rule: native CSS scroll-driven animation first → GSAP only when the effect genuinely exceeds what CSS timelines can do (frame sequences, complex timelines, pin choreography).

**Layout & visual direction (2026):**
- **Bento-grid layouts** (asymmetric modular tiles, varied cell sizes) are a current default for feature/proof sections — they break the "three equal cards" slop pattern while staying scannable. Use them when the page has 4+ distinct value points to show at a glance.
- **Anti-AI / human-made signal:** the strongest 2026 conversion edge is a page that does NOT look AI-generated (Moburst/Figma 2026). This reinforces the anti-slop bans already in this step — bespoke type pairing, real asymmetry, hand-felt spacing, and product-truthful imagery read as human-made and outperform the generic centered-hero + frosted-glass template. Treat "would a sharp designer recognize this as templated AI output?" as a rejection test.

**Asset pipeline for frame sequences (non-negotiable for performance):**
- Encode frames as **WebP or AVIF**, served from a **CDN**; never ship a folder of full-size PNGs.
- **Preload frames** before the pinned section enters the viewport (decode-ahead a sliding window; do not block first paint). Show the first frame as a static poster until enough frames are decoded.
- Budget: target the Doherty threshold (<400ms interactive) and keep LCP image off the animation path. Lazy-load below-fold media.

**3D / WebGL (only when the named direction is genuinely spatial):**
- Use `threejs` (or React Three Fiber) for interactive 3D; keep draw calls and polycount low, dispose geometries/materials on unmount.
- Provide a **static rendered image fallback** for low-power devices and reduced-motion — a 3D scene is never the only way to read the content.

**Reduced-motion is a first-class branch, not an afterthought:**
- Every technique above MUST have a `prefers-reduced-motion: reduce` equivalent already captured in `MOTION-CONCEPT.md`: pinned canvas → render the final/representative frame statically on load; scroll sequence → static hero image; 3D → static render. No content may be reachable only via animation (enforced by the reduced-motion stranding check in Phase E).

---

### Decision: Track Selection

Use AskUserQuestion: "How should we build this landing page?"
Options:
- **Track B — Templates/direct (default, fastest):** AI generates from strategy + Design DNA. shadcn blocks, boilerplate shell, repo template, or direct HTML.
- **Track A — Canvas visual-first (Pen.dev):** Generate a visual brief, iterate through the detected canvas interface with stakeholder review, export bundle, implement from bundle.
- **Hybrid — Canvas → Template:** Iterate visually in the selected canvas tool first (like Track A), export the bundle, then apply the bundle's visual direction to a template scaffold (shadcn block, boilerplate, or repo template). Combines polished visual direction with stack-native code.

Auto-default behavior:
- If `--visual-validate` or `--track=A` flag present → Track A
- If `--track=hybrid` present → Hybrid
- If `--track=B` present or accepted default → Track B

---

### Track A — Canvas prototype (Pen.dev)

Taste Skill supplies design guidance. Pen.dev supplies editable `.pen` artifacts and documented exports. TasteCode is an optional early-beta coding host with Design Mode, not an artifact format or required runtime. Confirm available capabilities using the actual host and [Pen documentation](https://docs.pen.dev/core-concepts/import-and-export); never invent commands or assume a subscription enables an API.

#### A.1 — Prepare a visual brief

Write `docs/landing-page/VISUAL-BRIEF.md` with the approved page/audience/traffic goal, Step 1.5 offer, claim-to-proof map, Step 3 direction, actual content/assets, responsive and reduced-motion behavior, CTA journey and chosen tool. Separate verbatim customer evidence from synthesis. Keep strategy unchanged while exploring visuals.

#### A.2 — Produce and review the artifact

1. Create or revise the `.pen` design through an available Pen interface. If unavailable, use the Direct track or record the missing capability; do not claim a render.
2. Save the editable artifact and approved exports under `docs/landing-page/visual-source/`.
3. Capture actual screenshots at representative narrow and wide viewports, plus interaction/state notes. Record tool/version, source file, assets and remaining gaps.
4. Review with the operator at the existing visual approval gate, or record explicitly delegated decisions under this run's authorization. Do not fabricate an approval.

Use the host's question mechanism: "Is the rendered canvas direction approved for the landing-page handoff?"
Options: [Approve this artifact, Revise direction, Use Direct prototype instead]

#### A.3 — Handoff

`LANDING-PAGE.md` maps source elements to production components and distinguishes visual approval from implemented behavior. Preserve existing legacy bundles when retrofitting; record their actual path rather than deleting them. A new run uses the neutral `visual-source/` contract.

---

### Track B — Template/Direct (DEFAULT — current behavior)

#### Template selection order

1. **shadcn blocks** (if shadcn/ui is in the stack **and** shadcn MCP/CLI is available) — login, signup, and landing page blocks as starting scaffolds
2. **Product boilerplate marketing shell** (only if `.sigma/boilerplate.json` + modules manifest or `stack.landing` proves a shell exists — see wiring below)
3. **Repo templates** from `templates/landing-page-templates/` — **must** read `catalog.json` and rank by page type (see wiring below)
4. **Direct HTML generation** — AI agent generates a self-contained HTML landing page from the strategy + Design DNA
5. **Custom implementation** — only if none of the above fit

#### Catalog-driven repo template selection (required when "Repo template" is in play)

Do **not** ask the user to pick from memory. Read the machine catalog and rank options:

1. **Read** `templates/landing-page-templates/catalog.json` (7 templates; schema at `schemas/landing-page-template-catalog.schema.json` if present).
2. **Map** the locked page type from Phase A Decision 1 → catalog `target_page_type` filter:

| Phase A page type | Prefer `target_page_type` (in order) |
|-------------------|--------------------------------------|
| Product marketing page (SaaS/app) | `saas-product`, `ai-product`, `developer-tool` |
| Waitlist / coming soon | `saas-product`, `changelog` |
| Demo / signup / free trial | `saas-product`, `developer-tool`, `ai-product` |
| Course / coaching sales page | `content-marketing`, `saas-product` |
| Portfolio / services page | `portfolio` |
| Other | show full catalog |

Also filter by orientation when relevant: if `docs/stack-profile.json` → `platform` is mobile-native, prefer `mobile-app`.

3. **Present** the top 3 catalog matches (name, `target_page_type`, `strengths`) via AskUserQuestion — not a generic "Repo template" label.
4. **Record** the chosen entry in `docs/landing-page/TEMPLATE-MAPPING.md`: template name, catalog `target_page_type`, path `templates/landing-page-templates/<name>/`, and why it beat the alternatives.

#### Boilerplate marketing shell detection (required before offering that option)

Before listing "Boilerplate marketing shell" as an option:

1. Read `.sigma/boilerplate.json` if present.
2. Detect a marketing/landing shell using **any** of:
   - `.sigma/modules.manifest.json` → `modules.marketing.enabled === true` (list `modules.marketing.files`)
   - `boilerplate.json` → `stack.landing` block (e.g. fintech monorepos)
   - `boilerplate.json` → `configFiles` containing a `landing/` path
   - Known paths on disk: `landing/`, `src/app/(marketing)/`, `src/routes/(marketing)/`
3. If **none** detected → omit "Boilerplate marketing shell" from the AskUserQuestion options (do not offer a dead option).
4. If detected → include the concrete path(s) in the option label, e.g. `Boilerplate marketing shell — landing/ (from fintech boilerplate)`.

#### shadcn blocks gate (required before offering shadcn option)

Only offer "shadcn blocks + customize" when **both** are true:
- `docs/stack-profile.json` → `"componentLibrary": "shadcn/ui"` (or Step 2 recorded shadcn)
- `.sigma/runtime-baseline.json` → `design_tools.shadcn_mcp === true` **OR** shadcn CLI is available

If shadcn is in stack but MCP/CLI unavailable → offer "shadcn blocks (install CLI first)" as a blocked option with the Step 0 install path, or fall through to repo template / direct HTML.

Build the AskUserQuestion options dynamically from the gates above — **never** offer boilerplate shell or shadcn blocks if the detection gates fail. For repo templates, list the top 3 catalog matches by name (not a generic "Repo template" label).

Use AskUserQuestion: "Which template approach?"
Options: [Dynamic — only viable options from catalog + boilerplate + shadcn gates above]

#### If using Direct HTML Generation

Generate a self-contained HTML landing page file from the page strategy:

1. If the user has reference sites or screenshots → invoke `image-to-code` to extract design DNA first
2. Generate complete HTML with inline CSS: page type + Design DNA + hero strategy + section order + CTA copy + mobile rules
3. Save to `docs/landing-page/landing-page.html`
4. Review against anti-slop rules — iterate until the page feels intentional
5. Responsive: must work at 375px (mobile) and 1440px (desktop)
6. All interactive elements work (hover states, focus rings, form validation feedback)
7. Dark mode support via `prefers-color-scheme` media query

The HTML file is self-contained (no external dependencies), opens in any browser, and serves as both the visual reference and the implementation starting point.

---

### Hybrid — Canvas → Template Seed

Run Track A phases A.1 and A.2 first (generate prompt, human iterates, export bundle to `docs/landing-page/visual-source/`).

Then:

#### H.1 — Select a template to seed

Run the same catalog + boilerplate + shadcn gates from Track B:

#### Catalog-driven repo template selection (required when "Repo template" is in play)

Do **not** ask the user to pick from memory. Read the machine catalog and rank options:

1. **Read** `templates/landing-page-templates/catalog.json` (7 templates; schema at `schemas/landing-page-template-catalog.schema.json` if present).
2. **Map** the locked page type from Phase A Decision 1 → catalog `target_page_type` filter:

| Phase A page type | Prefer `target_page_type` (in order) |
|-------------------|--------------------------------------|
| Product marketing page (SaaS/app) | `saas-product`, `ai-product`, `developer-tool` |
| Waitlist / coming soon | `saas-product`, `changelog` |
| Demo / signup / free trial | `saas-product`, `developer-tool`, `ai-product` |
| Course / coaching sales page | `content-marketing`, `saas-product` |
| Portfolio / services page | `portfolio` |
| Other | show full catalog |

Also filter by orientation when relevant: if `docs/stack-profile.json` → `platform` is mobile-native, prefer `mobile-app`.

3. **Present** the top 3 catalog matches (name, `target_page_type`, `strengths`) via AskUserQuestion — not a generic "Repo template" label.
4. **Record** the chosen entry in `docs/landing-page/TEMPLATE-MAPPING.md`: template name, catalog `target_page_type`, path `templates/landing-page-templates/<name>/`, and why it beat the alternatives.

#### Boilerplate marketing shell detection (required before offering that option)

Before listing "Boilerplate marketing shell" as an option:

1. Read `.sigma/boilerplate.json` if present.
2. Detect a marketing/landing shell using **any** of:
   - `.sigma/modules.manifest.json` → `modules.marketing.enabled === true` (list `modules.marketing.files`)
   - `boilerplate.json` → `stack.landing` block (e.g. fintech monorepos)
   - `boilerplate.json` → `configFiles` containing a `landing/` path
   - Known paths on disk: `landing/`, `src/app/(marketing)/`, `src/routes/(marketing)/`
3. If **none** detected → omit "Boilerplate marketing shell" from the AskUserQuestion options (do not offer a dead option).
4. If detected → include the concrete path(s) in the option label, e.g. `Boilerplate marketing shell — landing/ (from fintech boilerplate)`.

#### shadcn blocks gate (required before offering shadcn option)

Only offer "shadcn blocks + customize" when **both** are true:
- `docs/stack-profile.json` → `"componentLibrary": "shadcn/ui"` (or Step 2 recorded shadcn)
- `.sigma/runtime-baseline.json` → `design_tools.shadcn_mcp === true` **OR** shadcn CLI is available

If shadcn is in stack but MCP/CLI unavailable → offer "shadcn blocks (install CLI first)" as a blocked option with the Step 0 install path, or fall through to repo template / direct HTML.

Use AskUserQuestion: "Which template should we apply the the selected canvas tool visual direction to?"
Options: [Dynamic — top catalog match(es) by name, boilerplate shell if detected, shadcn block if gated, Direct HTML — use bundle as reference]

#### H.2 — Apply bundle to template

For the chosen template:
1. Extract the bundle's design tokens (colors, typography, spacing, radius, shadows)
2. Extract the bundle's component visual treatments (button styles, card styles, hero treatment)
3. Override the template's default styling with the bundle's tokens
4. Preserve the template's structure (routing, component hierarchy, data flow) — only the visual layer changes
5. Hand-edit sections where bundle layout differs from template layout — prefer the bundle's approved direction
6. Document which sections came from template vs which were reworked from bundle

This is the "best of both worlds" path: stakeholder-approved visual direction from the selected canvas tool + production-ready code scaffold from the template.

#### H.3 — Document the Hybrid output

In `LANDING-PAGE.md`, include both:
- Template mapping (which template, which sections map directly)
- Bundle influence map (which bundle decisions were applied to the template — tokens, typography, hero treatment, etc.)

---

### Asset generation (optional, selected provider and all tracks)

Use AskUserQuestion: "Generate landing page visual assets with AI?"
Options: [Yes — generate hero image + OG card + supporting visuals, Hero image only, OG/social preview card only, No — I'll provide my own assets]

If yes, for each asset:
1. Construct prompt from: Design DNA aesthetic + page purpose + brand context
2. Generate through the available approved media capability; verify the actual model, usage rights and supported output instead of hardcoding a product nickname
3. Review against Design DNA guardrails — reject if it looks like generic AI stock art
4. Save to `docs/landing-page/assets/`
5. Reference in LANDING-PAGE.md hero/visual sections

### Demo Video (optional — all tracks)

If the page hero or proof block uses a product demo video, invoke `demo-video-pipeline` to produce it. The demo video is a marketing-amplitude asset — it carries the named DNA's motion physics and must obey the truthful-copy rules below (no faked product behavior, no staged data presented as real).

Use AskUserQuestion: "Include a product demo video on the page?"
Options: [Yes — produce it via demo-video-pipeline, No — static hero/visual only, Later — leave a placeholder slot]

If yes: run `demo-video-pipeline`, save the output to `docs/landing-page/assets/`, and note the slot + fallback (poster image, captions, reduced-motion behavior) in LANDING-PAGE.md. A video that autoplays must respect `prefers-reduced-motion` and never trap the visitor.

### Template mapping

If using blocks, templates, or shells, create `docs/landing-page/TEMPLATE-MAPPING.md`:
- Chosen template/shell + why it fits
- Section-by-section mapping (which sections map directly, which need custom work)
- Which shadcn components/blocks are being used

### Anti-Slop Design & Copy Standards (HEAVILY apply here)

**Design:**
- Do NOT default to: centered hero + proof strip + features + pricing + testimonials + CTA (break this exact pattern)
- Do NOT use radial glows, blurred orbs, gradient text on H1, frosted glass cards
- Do NOT default devtools to dark+cyan, healthcare to cream+blue
- Do NOT use generic stock imagery — use product screenshots, real data, or illustrations that match DNA
- Spatial composition matters — asymmetry, overlap, grid-breaking are encouraged

**Copy:**
- Do NOT use: "Trusted by...", "Loved by...", "Built for..."
- Do NOT use: "Get Started", "Start Free Trial", "Book a Demo" as defaults — write outcome-based CTAs
- Do NOT use: "Simple, honest pricing", "Plans that scale", "Everything you need"
- Do NOT use: "Ready to [verb]?" as the closing CTA headline
- Do NOT use: "In today's [adjective] landscape..." anywhere on the page
- Do NOT use: "Game-changing", "Revolutionary", "Best-in-class", "Cutting-edge"
- Write like someone who sells things for a living, not a committee that describes features

**Truthful copy (the truthfulness invariant, applied to the page — non-negotiable):**
- Every claim is true and substantiable. No invented metrics, no "10,000+ users" if it's 200, no fake logos, no testimonials you don't have.
- No fake scarcity or fake urgency. A countdown that resets, "only 3 left" that never moves, or a "launch price ending tonight" that runs forever is a lie — cut it.
- The demo video and product screenshots show the REAL product behavior with representative data — never staged mockups presented as live, never a feature that doesn't exist yet shown as if it ships today.
- Placeholder/representative numbers must be visibly representative, never dressed up as real results.
- Risk-reversal claims (guarantee, refund, trial) must match what the business will actually honor — confirm against Step 1.5, don't invent terms.
- A page that earns the click by lying earns the refund and the chargeback. Truthful copy is the marketing-amplitude expression of the same truthfulness invariant the app obeys.

Evidence: actual editable canvas or direct preview, tool/version and viewport screenshots, CTA/form states, and source-to-component mapping. TasteCode remains optional; do not claim unverified host features.

<HARD-GATE>
Do NOT proceed to Phase E until user approves template selection + visual direction.

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

Use AskUserQuestion: "Template and visual direction set. Approve?"
Options: [Approve — finalize landing page, Revise template choice, Regenerate visuals]
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Above-the-fold confusion in the documented comprehension test; screenshots alone do not prove understanding
- Objections from avatar not handled on page
- Generic copy that could be about any product
- **Anti-slop design violations:** centered hero + proof + features + pricing + testimonials default; radial glows / blurred orbs; gradient H1; frosted glass cards; three equal horizontal feature cards; AI-purple default accent; full-bleed stock photography
- **Anti-slop copy violations:** generic CTA mismatch / unsubstantiated "Trusted by..." / "Simple honest pricing" / "Ready to [verb]?" / "Game-changing" / round fake numbers / unattributed testimonials
- Message hierarchy that buries the CTA
- Mobile conversion rules missing
- **Divergence protocol skipped** — any of: no fresh domain-specific references (not from memory or prior builds), no named directions with brand-derived motion metaphors and novelty quotas, no operator alignment gate, no `docs/landing-page/MOTION-CONCEPT.md`
- **Skill invocations skipped** — `motion-landing-design` not invoked before production; `design-taste` not invoked for anti-slop audit; `ux-psychology-pro` not invoked for copy empathy check
- Untruthful copy (invented metrics, fake scarcity, staged-as-real product behavior, guarantee terms not honored by Step 1.5)
- **Reduced-motion stranding** (any motion moment from MOTION-CONCEPT.md has no static final-state equivalent; content only reachable via animation)
- **Screenshot evidence missing** (375px + 1440px captures not saved to `docs/landing-page/`)
- Page drifts from the named Design DNA (`DESIGN.md`) — doesn't read as the same product as the app; material, type, or motion physics contradicts the 5 invariants

Fix findings before presenting.

### Verification Doctrine (required — evidence, not assertion)

Do not claim the page is done without running these and capturing evidence:

1. **Screenshot the page** at 375px (mobile) and 1440px (desktop). Check the hero against the chosen direction; record comprehension-test evidence separately from screenshots.
2. **Reduced-motion render:** load with `prefers-reduced-motion: reduce`. Confirm every motion moment from MOTION-CONCEPT.md has a truthful static/reduced equivalent and nothing is stranded (off-screen, invisible, mid-transition).
3. **Truthful-copy pass:** verify every metric, logo, testimonial, scarcity claim, and guarantee against reality / Step 1.5. Cut anything unsubstantiated.
4. **DNA conformance:** confirm material, type, motion physics, stance, and truthfulness match `DESIGN.md` at cinematic amplitude — and that the page still reads as the same product as the app.

Save the evidence (screenshots + notes) under `docs/landing-page/`. A "looks good" with nothing captured is not verification.

### Write `docs/landing-page/LANDING-PAGE.md`

Required sections:
```
Page Type & Primary Action
Offer Translation (from Step 1.5)
Chosen Creative Direction (name + concept from the divergence protocol)
Motion Concept (reference to MOTION-CONCEPT.md — brand-derived metaphor + per-section motion + reduced-motion equivalents)
Message Hierarchy
Hero Strategy (headline, subheadline, CTA, visual)
Social Proof Strategy
Objection Handling (mapped from avatar)
CTA Strategy + Mobile Placement
Mobile Conversion Rules
Track Used (A / B / Hybrid) — with bundle path if Track A or Hybrid
Template Mapping (Track B and Hybrid only)
Bundle Mapping (Track A and Hybrid only — component → production file path)
Anti-Slop Guardrails Applied
Implementation Handoff
Do NOT Build in This Step
```

### Implementation Handoff must state:
- **Track used** (A / B / Hybrid) and where its artifacts live (`docs/landing-page/visual-source/` for A/Hybrid, `docs/landing-page/landing-page.html` for B)
- Chosen template strategy (Track B and Hybrid) OR bundle-driven approach (Track A)
- What copy must not drift during implementation
- Mobile constraints that are non-negotiable
- Which sections come from templates vs custom vs bundle
- For Hybrid: which bundle decisions were applied to the template (tokens, typography, hero treatment, section layouts) vs preserved from template (structure, routing, data flow)
- Design DNA emphasis for the page

### Writing Standards (embedded)

- No stock AI phrases in copy: see anti-slop copy rules above
- Headlines name the outcome, not the product category
- Every proof element reduces a real objection (not decorative)
- CTA copy is specific: "Start tracking your portfolio" not "Get Started"
- Write like a direct-response copywriter, not a brand guidelines document

### Success Criteria

- [ ] Avatar evidence and labeled empathy hypotheses inform the page; synthetic material is not customer proof
- [ ] Above-the-fold comprehension evidence records value, relevance and next action; untested assumptions stay labeled
- [ ] Message hierarchy is specific to THIS product
- [ ] Social proof reduces real objections from avatar
- [ ] CTA is outcome-based, not generic
- [ ] Mobile CTA visible without scrolling
- [ ] Divergence protocol ran: fresh research → 2-3 named creative directions → operator alignment gate → MOTION-CONCEPT.md before production
- [ ] Page conforms to the named Design DNA at cinematic amplitude; reads as the same product as the app
- [ ] Truthful copy verified (no invented metrics, fake scarcity, or staged-as-real product behavior)
- [ ] Demo video (if used) produced via `demo-video-pipeline`, captioned, with reduced-motion behavior
- [ ] Verification doctrine run: screenshots (375px + 1440px) + reduced-motion stranding check captured as evidence
- [ ] Anti-slop design + copy rules applied
- [ ] Step 1.5 consumed, not re-litigated
- [ ] Template strategy recorded
- [ ] $holes pass completed
- [ ] Linear tracking issues created (when configured)
- [ ] User approved

Evidence: responsive/browser and accessibility checks, truthful proof, reduced-motion behavior, analytics event plan, and an experiment that names outcome and guardrails. Untested conversion lift remains a hypothesis.

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 10 without explicit approval.
Use AskUserQuestion: "Step 9 complete. Ready for Step 10 — Feature Breakdown?"
Options: [Proceed to Step 10, Revise landing page, Skip Step 9 — not needed]
</HARD-GATE>

---

<verification>
## Step 9 Verification Schema

### Required Outputs (30 points)

| Item | Path | Points |
|------|------|--------|
| Landing Page Strategy | docs/landing-page/LANDING-PAGE.md | 12 |
| Problem-Aware Avatar | docs/avatars/PROBLEM-AWARE-AVATAR.md | 6 |
| Labeled empathy hypotheses or actual diary evidence | docs/avatars/DIARY-ENTRIES.md | 6 |
| Landing Sources | docs/research/LANDING-SOURCES.md | 6 |

### Required Sections in LANDING-PAGE.md (35 points)

| Section | Points |
|---------|--------|
| Offer Translation | 4 |
| Chosen Creative Direction (name + concept from divergence protocol) | 3 |
| Motion Concept (reference to MOTION-CONCEPT.md — metaphor, per-section intent, reduced-motion equivalents) | 3 |
| Message Hierarchy | 4 |
| Hero Strategy (headline + CTA + visual) | 5 |
| Social Proof Strategy | 4 |
| Objection Handling | 4 |
| CTA Strategy + Mobile Placement | 4 |
| Template Mapping | 2 |
| Implementation Handoff | 2 |

### Quality Indicators (25 points)

| Check | Points |
|-------|--------|
| Above-the-fold comprehension checked on relevant viewports; participant evidence or untested hypothesis labeled | 4 |
| Avatar objections mapped to page sections | 3 |
| CTA copy is outcome-based (not "Get Started" / "Start Free Trial" / "Book a Demo") | 2 |
| Divergence protocol ran in full: fresh domain-specific references → 2-3 named directions with brand-derived motion metaphors + novelty quotas → operator alignment gate → MOTION-CONCEPT.md before any production work | 6 |
| Skills invoked at correct phase: `motion-landing-design` (divergence + motion concept), `design-taste` (anti-slop audit), `ux-psychology-pro` (copy empathy + direction fit-check) | 2 |
| Truthful copy verified (no fake metrics/scarcity/staged-as-real; guarantees match Step 1.5) | 2 |
| Reduced-motion stranding check passed (every motion moment has a static final-state; screenshots captured with reduced-motion forced) | 2 |
| Page conforms to named Design DNA at cinematic amplitude (material, type, motion physics, stance, truthfulness all traceable to `DESIGN.md`) | 2 |
| Anti-slop design rules applied: intentional layout/type/color choices traceable to the approved brief; no unexamined stock defaults | 1 |
| Anti-slop copy rules applied: no unsubstantiated "Trusted by..." claims / fabricated numbers / unattributed testimonials / banned phrase patterns | 1 |

### Boundary Integrity (10 points)

| Check | Points |
|-------|--------|
| Step 1.5 consumed, not re-litigated | 2 |
| Mobile conversion rules explicit | 3 |
| Template follows selection order | 2 |
| $holes pass completed | 2 |
| Linear tracking issues created (when configured) | 1 |

**Passing score:** 95/100

## CRAFT (award standard) — scored by step-verify-gate (deterministic) + the judge; never self-attested. See references/award-standard.md.
<VERIFY-ASSERT>
craft_antislop docs/landing-page/*.html
divergence_proof docs/design
</VERIFY-ASSERT>

## DNA Conformance — scored by step-verify-gate (deterministic); never self-attested. Requires .sigma/standards.json from Step 3. Missing file → advisory skip (not a fail). See schemas/standards.schema.json.
<VERIFY-ASSERT>
dna_conformance docs/landing-page/*.html
</VERIFY-ASSERT>
</verification>

$END$
