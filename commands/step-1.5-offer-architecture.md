---
description: "Step 1.5: Offer Architecture — monetization, positioning, packaging, and pricing across SaaS, high-ticket, and AI-native models with Hormozi, Dunford, Brunson, and a16z frameworks"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --market
  - --product
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

- `hormozi-frameworks`
- `pricing-psychology`
- `monetization`
- `pricing-strategy`

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-1.5-offer-architecture — Offer Architecture, Positioning & Monetization Sync

**On start, announce:** "Running Step 1.5: Offer Architecture. I'll walk you through 5 phases covering positioning, pricing, packaging, and product impact — with approval gates at each phase."

<goal>
You are the Offer Strategist and Pricing Architect. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Trigger Validation & Monetization Classification | Category + model + research confidence |
| B | Positioning & Purchase Context | Best-fit customer, alternatives, differentiated value |
| C | Pricing, Packaging & Offer Architecture | Value metric, tiers, guarantees, funnel type |
| D | Entitlements & Product Impact | Schema, billing, UX, architecture consequences |
| E | Output, Hardening & Handoff | OFFER_ARCHITECTURE.md + synced docs |

Final Outputs: `docs/specs/OFFER_ARCHITECTURE.md`, `docs/specs/pricing-config.json` (conditional), updated `MASTER_PRD.md`, updated `docs/stack-profile.json`

Quality gate: 95+/100 on verification schema.
</goal>

---

## Step Boundary

- **Trigger:** Run after Step 1 when Decision 6 flags monetization. Requires `docs/specs/MASTER_PRD.md` from Step 1.
- **Step 1.5 owns:** positioning for monetization, pricing model, packaging, guarantees, value metric, offer stack, funnel architecture, entitlement design, product-impact sync.
- **Step 1.5 does NOT own:** landing page copy (Step 9), system architecture (Step 2), implementation-ready entitlement wiring (Step 8/11), brand voice (marketing skills), sales scripts.
- **Do NOT** design full landing page messaging. Do NOT implement billing integration. Do NOT write UX flows — those belong to later steps.
- **Fallback:** If MASTER_PRD.md is missing or Decision 6 is absent, prompt user to run Step 1 first or provide monetization intent directly.

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
- Phase A start: create issue "Step 1.5: Offer Architecture in progress" — labels `step-1.5`, `wave:W0`, state In Progress.
- After Phase C (pricing locked): create one issue per tier "Step 1.5: Tier — {tier} defined" — labels `step-1.5`, `wave:W0`.
- On OFFER_ARCHITECTURE.md completion (Phase E): move the tracking issue to Done and create "Step 1.5: OFFER_ARCHITECTURE.md complete" — labels `step-1.5`, `milestone`, `wave:W0`.

---

## Monetization Categories

Step 1.5 covers three categories. Phase A determines which apply.

| Category | Models | Conversion Mechanism |
|----------|--------|---------------------|
| **SaaS / Digital Product** | Subscription, usage-based, seat-based, freemium, hybrid, one-time | Self-serve checkout, trial, free tier |
| **High-Ticket** | Coaching, courses, consulting, masterminds, done-for-you, workshops | Webinar, VSL + application, discovery call, value ladder |
| **AI-Native** | Outcome-based, action/workflow credits, premium AI seats, hybrid base+usage | Credits, per-resolution, metered usage |

Products can span multiple categories (e.g., SaaS platform + high-ticket consulting tier).

---

## Framework Library

Use the frameworks that match the monetization category. Skip frameworks that don't apply — don't pad.

### Hormozi Value Equation (all categories)

Value = (Dream Outcome x Perceived Likelihood) / (Time Delay x Effort & Sacrifice)

- Dream Outcome vague → offer is vague.
- Perceived Likelihood weak → needs proof, case studies, or guarantee.
- Time Delay long → compress time-to-first-value.
- Effort & Sacrifice high → simplify onboarding or remove switching costs.

### Hormozi Grand Slam Offer (all categories)

Use the offer components below as a commercial design checklist, then test the buyer response rather than claiming the offer is irresistible. Components:
- **Dream outcome** — the transformation, not the deliverable
- **Value stack** — pile value until price feels absurd
- **Commitment / risk reversal** — make only promises the operator can deliver, measure, and support
- **Scarcity** — only when real and defensible (do NOT invent fake scarcity)
- **Urgency** — only when real (cohort close, limited seats, launch window)
- **Bonuses** — solve objections or compress time-to-value, not pad the offer

### Hormozi Money Models (all categories)

Use the current Money Models layer to examine how buyers enter, continue, expand, reduce, or leave the offer: attraction, initial purchase, upsell, downsell, and continuity. Treat these as candidate paths to validate against buyer behavior, capacity, and unit economics—not mandatory funnel stages or guaranteed outcomes. Source: [Acquisition.com](https://shop.acquisition.com/).

### April Dunford Positioning (all categories)

**Four pre-decisions (resolve BEFORE positioning):**
1. **Positioning readiness** — is the product/offer mature enough to position deliberately?
2. **Audience type** — customer positioning (not investor, not employee)
3. **Scope** — positioning a single product, company, suite, or hybrid?
4. **Deal champion** — who creates shortlists, coordinates stakeholders, recommends?

**Five positioning components:**
1. Competitive alternatives (what they'd do without you)
2. Differentiated capabilities (what you do that alternatives can't)
3. Differentiated value (what customers get because of those capabilities)
4. Best-fit customers (who cares most about that value)
5. Market category (frame that makes your value easiest to understand)

Use the resulting positioning inputs to create a concise Sales Pitch handoff: audience, alternatives, differentiated capability-to-value chain, category, champion/stakeholder, objections, proof, and open tests. This is an evidence-backed handoff to Step 9 and Run Sales, not a sales script. Source: [April Dunford](https://www.aprildunford.com/books).

### JTBD / Bob Moesta Purchase Context (all categories)

- What struggling moment triggered the search?
- What would the buyer do if this product/offer didn't exist?
- What forces push them to switch vs. stay?
- What are they hiring and firing?
- What clues indicate willingness to pay?

### Russell Brunson Value Ladder (high-ticket + hybrid)

Candidate stages of progressive commitment:
1. **Attraction** — a useful first interaction, where appropriate
2. **Front-end** — an initial paid or low-commitment offer, where appropriate
3. **Core** — the primary offer
4. **Expansion** — a higher-touch or higher-capacity offer, where appropriate
5. **Continuity** — an ongoing relationship or renewal path, where appropriate

Each stage must solve a real buyer problem and lead naturally to the next decision. Test the sequence against buyer behavior; do not impose a fixed number of stages or choices.

### Stack Slide Method (high-ticket)

Six components stacked to build belief progressively:
1. **Opportunity Switch Masterclass** — reframes their belief about the problem
2. **Asset Pack** — tangible tools (templates, dashboards, scripts) that save time immediately
3. **Case Study Breakdowns** — real before/after with specific metrics
4. **Feedback / Community Layer** — accountability, async audits, group support
5. **"Mini Coach" Tool** — calculator, AI tool, or decision flow that scales guidance
6. **Urgent Exclusive Bonus** — time-limited, VIP-only (must be real, not manufactured)

Rule: Each element kills a specific objection. If it doesn't kill an objection or increase certainty, cut it.

### a16z Packaging Models (SaaS + AI-native)

| Model | When to use |
|-------|-------------|
| **Core** | All customers want it, it drives adoption, AI is mission-critical to value prop |
| **Upgrade Tier** | Nice-to-have upsell for most, enhances but doesn't fundamentally change product |
| **Add-On** | Significant value for a small set of power users willing to pay premium |

Warning: AI features that started as premium add-ons have become table stakes (Notion, Salesforce). Don't over-gate what buyers now expect as baseline.

### AI-Native Pricing Models

Select based on the **Autonomy-Attribution-Predictability Triangle:**

| Model | Best for | Core logic |
|-------|----------|------------|
| **Outcome-based** | Quantifiable, standardized results | Charge per resolved issue, meeting booked, task completed |
| **Action/Workflow-based** | Multi-step, variable-effort tasks | Credits abstracting heterogeneous actions (Clay burn table, N8N per-workflow) |
| **Hybrid** | Unpredictable workloads | Fixed base fee + usage overage tail |

Selection axes:
- **Value attribution** — how clearly does output tie to customer outcomes?
- **Execution autonomy** — does the agent solve problems without human-in-loop?
- **Workload predictability** — is effort consistent or highly spiky?

### High-Ticket Funnel Types (high-ticket)

| Funnel | Structure |
|--------|-----------|
| **Ascension** | Initial offer → relevant expansion → nurture where buyer behavior supports it |
| **Webinar** | Education or demonstration → appropriately qualified conversion path |
| **VSL + Application** | Sales narrative → application → qualification → human review where appropriate |

---

## Phase A — Trigger Validation & Monetization Classification

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `.sigma/runtime-baseline.json`, `docs/specs/MASTER_PRD.md`, `docs/stack-profile.json`.
3. Read `docs/specs/OFFER_ARCHITECTURE.md` if it already exists.
4. Extract the Step 1 monetization trigger decision (Decision 6).
5. If `research_mode = blocked` → stop. If `reduced` → continue with assumption labels.

### Monetization Classification (sequential decisions)

**Decision 1: Confirm Step 1.5 is needed**
Use AskUserQuestion: "Step 1 flagged monetization. Confirm Step 1.5 should run?"
Options: [Yes — design the offer architecture, Skip — monetization is out of scope for now]

**Decision 2: Monetization category**
Use AskUserQuestion: "What type of monetization?"
Options: [SaaS / Digital Product (subscriptions, usage, freemium), High-Ticket (coaching, courses, consulting, $997+), AI-Native (outcome-based, credits, per-resolution), Hybrid — multiple categories, Other]

**Decision 3: Pricing model**
Based on category, use AskUserQuestion:

If SaaS: Options: [Subscription (monthly/annual), Usage-based (per-unit, per-call), Seat-based, Freemium + paid tiers, Hybrid (base + usage), One-time purchase, Other]

If High-Ticket: Options: [Course / membership ($97-$997), Coaching program ($1K-$5K), Consulting / done-for-you ($5K-$25K), Mastermind / retainer ($10K+), Value ladder (multiple tiers), Other]

If AI-Native: Options: [Outcome-based (per-resolution), Action/workflow credits, Premium AI seats (2-3x), Hybrid base + usage tail, Other]

**Decision 4: Structured monetization needed?**
Use AskUserQuestion: "Does pricing need machine-readable representation (pricing-config.json)?"
Options: [Yes — multiple tiers with distinct entitlements, credits, usage metering, Yes — credit/token system, No — simple pricing, single tier, or high-ticket (no config needed), Not sure — decide after Phase C]

Lock all 4 decisions.

For the selected model, record the buyer, alternative, value metric, price hypothesis, delivery cost, capacity constraint, proof available, and any promise that must remain conditional.

<HARD-GATE>
Do NOT proceed to Phase B until user approves classification.
Use AskUserQuestion: "Monetization classification locked. Approve?"
Options: [Approve — proceed to positioning, Revise — change classification]
Approval means the model is a testable commercial hypothesis with known evidence gaps, not a committed price or guarantee.
</HARD-GATE>

---

## Phase B — Positioning & Purchase Context

### Dunford Pre-Decisions (resolve before positioning)

Use AskUserQuestion for each:

1. **Positioning readiness:** "Is the offer mature enough to position deliberately, or should we draft a positioning thesis to validate?"
2. **Scope:** "Are we positioning a single product, a company, a product suite, or a specific offer tier?"
3. **Deal champion:** "Who is the person who creates shortlists and recommends — what's their role?"

### Research (directive queries based on locked decisions)

1. Search `"[product domain] [category] alternatives competitors 2025 2026"` — find what buyers use today
2. Search `"[primary user] [problem] pricing willingness to pay"` — find WTP signals
3. Search `"[category] pricing benchmarks [price range]"` — find market norms
4. If high-ticket: Search `"[domain] coaching program course pricing conversion"` — find comparable offers

### Required Positioning Sections

Complete these using Dunford + JTBD:

1. **Best-Fit Customer** — who gets the most value, their context, maturity, urgency
2. **Competitive Alternatives** — direct, indirect, status quo, internal workaround
3. **Differentiated Capabilities** — what's meaningfully different (not just technically)
4. **Differentiated Value** — time saved, money made, risk reduced, status gained
5. **Purchase Context** — struggling moment, switching forces, objections, WTP clues
6. **Market Category / Positioning Frame** — the frame that makes your value easiest to buy
7. **Sales Pitch Handoff** — audience, alternatives, capability-to-value chain, category, champion/stakeholders, objections, proof, and open tests for Step 9 and Run Sales

<HARD-GATE>
Do NOT proceed to Phase C until user approves positioning.
Use AskUserQuestion: "Positioning complete. Approve?"
Options: [Approve — proceed to pricing architecture, Revise positioning, Research deeper on a specific area]
Approval means the positioning inputs are grounded in buyer evidence or labeled assumptions, and the Sales Pitch handoff records what still needs validation.
</HARD-GATE>

---

## Phase C — Pricing, Packaging & Offer Architecture

Branch based on monetization category from Phase A.

### If SaaS / Digital Product

**Required decisions:**
1. **Value metric** — what usage or outcome proxy aligns with customer value? Why is this better than feature gating?
2. **Packaging** (a16z model) — Core / Upgrade Tier / Add-On? What's in each?
3. **Tier design** — what's unlocked, expanded, or metered at each level?
4. **Upgrade path** — starter → pro → team (or equivalent). Expansion logic, overages, trials, downgrades.
5. **Commitment / risk reversal** — trial, refund policy, SLA, or none? State the operational conditions, cost, and support burden. Do not promise an outcome outside operator control.

### If High-Ticket

**Required decisions:**
1. **Value ladder position** — where does this offer sit? (front-end, core, back-end, peak)
2. **Stack Slide components** — which 6 elements? Each must kill a specific objection.
3. **Funnel type** — Ascension, Webinar, or VSL + Application? Why?
4. **Price hypothesis** — price, buyer alternative, willingness-to-pay evidence, delivery cost, and margin/capacity scenario.
5. **Commitment** — conditional, refund-window, SLA, or performance-based only when its terms are measurable and operable.
6. **Scarcity / urgency** — cohort close date, limited seats, enrollment window? Must be real.

### If AI-Native

**Required decisions:**
1. **Pricing archetype** (Chargebee triangle) — Outcome-based, Action/Workflow, or Hybrid?
2. **Value attribution** — how clearly does output tie to customer outcomes?
3. **Cost structure** — LLM/infra COGS per request? Margin constraints?
4. **Credit/metering design** — credit burn table, resolution counting, or usage tiers?
5. **Soft caps and alerts** — how do you prevent bill shock?
6. **Commitment** — SLA, resolution-rate target, or satisfaction-based policy only when its terms are measurable and operable.

### For all categories

Apply Hormozi Value Equation as a heuristic:
- Record the evidence or test for Dream Outcome, Perceived Likelihood, Time Delay, and Effort & Sacrifice.
- If a term is weak, choose a proportionate response such as stronger proof, faster onboarding, simpler workflow, narrower audience, or a smaller commitment. Do not manufacture guarantees.

Apply Grand Slam Offer check:
- Does each component address a buyer objection or increase confidence?
- Are commitments real, measurable, and supported by capacity and operating controls?
- What channel and buyer-behavior test will validate the offer, packaging, and next-step path?
- What must be true for the offer to continue, expand, down-sell, or be withdrawn?

<HARD-GATE>
Do NOT proceed to Phase D until user approves pricing architecture.
Use AskUserQuestion: "Pricing and offer architecture complete. Approve?"
Options: [Approve — map product impact, Revise pricing, Adjust packaging/tiers]
Approval means prices, packaging, commitments, channel behavior, and unit-economics scenarios are explicit hypotheses with tests and operating constraints.
</HARD-GATE>

---

## Phase D — Entitlements & Product Impact

Translate pricing decisions into product, data, billing, and UX consequences.

### If SaaS / AI-Native — map these implications:

**Schema:** subscriptions, plan membership, credits, seats, quotas, overages, ledgers, usage records
**Billing:** payment provider, plan changes, trial/grace handling, renewal/cancellation
**Entitlements:** what's capped, gated, metered, unlocked per tier
**Product UX:** pricing page, upgrade prompts, usage dashboard, limit states, paywall behavior
**Architecture sync:** what Step 2 must absorb, what Step 8/11 must implement

For AI-native offers, add cost variance, metering attribution, model/provider dependency, and support/escalation behavior when those affect the offer. Omit fields that do not apply.

### If High-Ticket — map these implications:

**Funnel infrastructure:** landing page (Step 9), application form, booking system, email sequences
**Delivery platform:** course hosting, community platform, coaching call scheduling
**Payment:** one-time vs payment plans, deposit + balance, high-ticket payment processor
**Content delivery:** module structure, drip schedule, bonus access gating
**Architecture sync:** what Step 2 must absorb (may be minimal for info products)

### pricing-config.json (conditional — SaaS/AI-native only)

Create only when structured monetization needs machine-readable representation.

```json
{
  "$schema": "pricing-config-v1",
  "model": "hybrid",
  "value_metric": "resolution",
  "tiers": {
    "starter": {
      "monthly_price": 29,
      "annual_price": 290,
      "entitlements": { "resolutions_monthly": 100, "team_members": 1, "ai_features": "core" }
    },
    "pro": {
      "monthly_price": 99,
      "annual_price": 990,
      "entitlements": { "resolutions_monthly": 1000, "team_members": 5, "ai_features": "all" }
    }
  },
  "overages": { "enabled": true, "rate_per_unit": 0.10, "unit": "resolution" },
  "trial": { "days": 14, "requires_payment_method": false },
  "guarantee": { "type": "money-back", "window_days": 30 }
}
```

Do NOT create pricing-config.json for high-ticket offers. Use the OFFER_ARCHITECTURE.md narrative sections instead.

<HARD-GATE>
Do NOT proceed to Phase E until user approves product impact mapping.
Use AskUserQuestion: "Product impact mapped. Approve?"
Options: [Approve — write final documents, Revise entitlements, Adjust architecture impact]
Approval means the entitlement, billing, data, UX, and support consequences are explicit for the selected model; implementation remains downstream work.
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Weak positioning or unsupported pricing claims
- Missing entitlement rules or undefined edge cases
- Contradictions between OFFER_ARCHITECTURE.md and MASTER_PRD.md
- Unsupported price, packaging, or commitment claims

Fix findings before presenting for approval.

### Write `docs/specs/OFFER_ARCHITECTURE.md`

```markdown
# [Project Name] — Offer Architecture

## Monetization Category
- **Category:** [SaaS / High-Ticket / AI-Native / Hybrid]
- **Model:** [Specific model from Phase A]
- **Research confidence:** [full / reduced]

## Best-Fit Customer & Purchase Context
- Best-fit customer: [specific persona]
- Struggling moment: [what triggered the search]
- Switching forces: [push/pull factors]
- Willingness-to-pay signals: [evidence or assumptions]
- Current alternatives: [what they'd do without this]

## Positioning Frame
- Competitive alternatives: [list]
- Differentiated capabilities: [what you do that alternatives can't]
- Differentiated value: [time saved, money made, risk reduced]
- Market category: [the frame that makes value easiest to understand]

## Sales Pitch Handoff
- Audience, champion, and stakeholders: [who must be persuaded]
- Alternatives and status quo: [buyer-visible choices]
- Capability → value chain: [what is distinct and why it matters]
- Proof, objections, and open tests: [evidence and remaining uncertainty]

## Pricing Model
- Model: [subscription / usage / outcome / high-ticket / hybrid]
- Value metric: [what proxy for customer value]
- Rationale: [why this model fits the customer and purchase context]

## Packaging / Tier Design
[Table of tiers with entitlements — or value ladder tiers for high-ticket]

## Money Model Paths
| Buyer Stage | Offer / Next Decision | Evidence | Channel Behavior Test | Capacity / Unit-Economics Constraint | Continue, Expand, Downsell, or Exit Condition |
|-------------|-----------------------|----------|-----------------------|--------------------------------------|-----------------------------------------------|

## Value Stack (if high-ticket)
| Component | What It Is | Objection It Kills | Standalone Value |
|-----------|-----------|-------------------|-----------------|

## Commitment / Risk Reversal
- Type: [trial / refund window / conditional / SLA / performance-based / none]
- Operational terms: [what is measured, who can fulfill it, and support/refund exposure]
- Why it is credible: [evidence or test; do not present a promise as proof]

## Scarcity / Urgency
- [Only real drivers — cohort close, limited seats, enrollment window. Do NOT invent fake scarcity.]

## Funnel Architecture (if high-ticket)
- Funnel type: [Ascension / Webinar / VSL + Application]
- Entry point → qualification → conversion mechanism

## Unit Economics
- COGS: [relevant cost notes — LLM inference, delivery, support]
- Margin and capacity scenarios: [conversion, refund, support, utilization, and AI-cost variance when relevant]
- Price hypothesis and evidence: [buyer alternative, willingness-to-pay evidence, and remaining assumptions]

## Product / Architecture Impact
- Schema consequences: [what data models change]
- Billing consequences: [payment provider, plan logic]
- Entitlement consequences: [what's gated, metered, capped]
- UX consequences: [pricing page, upgrade prompts, limits states]
- What Step 2 must inherit: [architecture requirements]
- What Step 8/11 must implement: [implementation requirements]

## Do NOT Build in This Step
- Landing page copy or full conversion messaging (Step 9)
- Billing integration implementation (Step 8/11)
- UX flows or wireframes (Step 3/5)
- Sales scripts or outbound sequences (marketing commands)

## Sync Summary
- MASTER_PRD sections updated: [list]
- stack-profile fields updated: [list]
- pricing-config.json created: [yes/no + why]
```

### Sync actions

- Update `MASTER_PRD.md` monetization section with locked pricing decisions
- Update `docs/stack-profile.json` with payments, pricing, entitlement fields
- Ensure no contradictions between narrative (OFFER_ARCHITECTURE.md) and machine-readable (pricing-config.json)

### Writing Standards (embedded — apply to ALL Step 1.5 outputs)

- No stock AI phrases: "Let's dive in", "Game-changing", "Seamless", "Robust", "Delve", "Navigate challenges"
- Start with decisions, not industry commentary
- Commit to pricing rationale — no "might work" / "could potentially" hedging
- No breathless enthusiasm about the offer — let the value stack speak
- Write like a pricing strategist with conviction, not a blog post about pricing

### Success Criteria

- [ ] Step 1 state and Decision 6 were read and used
- [ ] Monetization category and model explicitly classified
- [ ] Positioning is evidence-backed or clearly labeled assumptions
- [ ] Sales Pitch handoff records alternatives, proof, objections, and open tests
- [ ] Purchase context and deal champion are explicit
- [ ] Pricing model and value metric are justified
- [ ] Commitment or risk reversal is operable, measurable where relevant, and does not invent a guarantee
- [ ] Money Model paths include only applicable attraction, expansion, downsell, and continuity decisions
- [ ] Channel behavior and unit-economics tests are explicit before a price or package is treated as settled
- [ ] Product/architecture consequences are explicit
- [ ] pricing-config.json created only when structured monetization requires it
- [ ] MASTER_PRD.md synchronized
- [ ] stack-profile.json synchronized
- [ ] $holes pass completed
- [ ] User approved before Step 2
- [ ] Linear tier issues created (when configured)

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 2 without explicit approval.
Use AskUserQuestion: "Step 1.5 complete. Ready for Step 2 — Architecture?"
Options: [Proceed to Step 2, Revise offer architecture, Run additional research]
Approval means commercial hypotheses, product consequences, and follow-up tests are explicit enough for architecture; it does not authorize billing implementation or promise external outcomes.
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 1.5 Verification Schema

### Required Files (24 points)

| File | Path | Requirement | Points |
|------|------|-------------|--------|
| Offer Architecture | docs/specs/OFFER_ARCHITECTURE.md | Required | 12 |
| MASTER_PRD sync | docs/specs/MASTER_PRD.md | Monetization section updated | 6 |
| Stack profile sync | docs/stack-profile.json | Pricing/payments state updated | 6 |

### Conditional Files (8 points)

| File | Path | Requirement | Points |
|------|------|-------------|--------|
| Pricing Config | docs/specs/pricing-config.json | Required only for structured SaaS/AI monetization | 8 |

### Content Quality (48 points)

| Check | Points |
|-------|--------|
| Competitive alternatives are explicit (Dunford) | 6 |
| Differentiated value is explicit (not just capabilities) | 6 |
| Purchase context with struggling moment and switching forces (JTBD) | 6 |
| Pricing model and rationale present | 6 |
| Value metric or packaging logic justified | 6 |
| Commitment / risk reversal is operable or explicitly omitted | 6 |
| Value Equation assessment completed (Hormozi) | 4 |
| Product/entitlement consequences documented | 4 |
| Negative requirements ("Do NOT build") section present | 2 |
| Build order implications for Step 2 documented | 2 |

### Sync & Approval (20 points)

| Check | Points |
|-------|--------|
| MASTER_PRD and OFFER_ARCHITECTURE agree on monetization | 5 |
| stack-profile reflects pricing decisions | 5 |
| $holes pass completed | 5 |
| User approved final output | 5 |
| Linear tier issues created (when configured) | 1 |

### Scoring

- **95+/100** = ready for Step 2
- **80-94** = revise before proceeding
- **<80** = incomplete
- If Step 1.5 is not required: report `Skipped (Not monetized)` — do not fail the workflow.
</verification>

$END$
