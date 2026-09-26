# C-Suite Department System

Sigma Protocol ships with seventeen invokable department surfaces — the 13 canonical departments plus 4 alias-canons (`/ads`, `/growth`, `/support`, `/gtm`). Each is a specialized executive with a defined skill arsenal, clear ownership boundaries, and a memory system that learns your project over time.

You invoke a department with a slash command. Claude becomes that executive for the session. The deeper you work with a department, the better it knows your project, your voice, and your constraints.

---

## How the System Works

```
User invokes /marketing
        |
        v
Claude loads:  [1] Department Methodology (CMO DNA)
                   +
               [2] Project Overlay ({CWD}/.claude/departments/marketing.md)
                   +
               [3] User Overlay (~/.claude/departments/marketing/user-overlay.md)
        |
        v
Claude responds as CMO with full context of your project + your voice
        |
        v
Post-session: Stop hook classifies learnings → routes to correct overlay file
```

Three inputs compose every session:

| Layer | Location | Contains |
|-------|----------|----------|
| Department Methodology | Embedded in Claude | Frameworks, vocabulary, decision patterns for that executive role |
| Project Overlay | `{CWD}/.claude/departments/{dept}.md` | Stack, audience, funnel stage, constraints for THIS project |
| User Overlay | `~/.claude/departments/{dept}/user-overlay.md` | Brand voice, personal preferences, cross-project patterns |

---

## The Departments

These are the invokable command surfaces. They map to the 13 canonical departments in `.claude/lib/agent-skill-registry.json`, plus the alias-canons `/ads` and `/growth` (route through marketing), `/support` (routes to community), and `/gtm` (routes through marketing).

### `/marketing` — CMO

**Persona:** Chief Marketing Officer

**Owns:**
- Market positioning and messaging architecture
- Offer design (value equation, stack, pricing pressure-test)
- Go-to-market strategy
- Brand narrative and ICP definition
- Delegating execution to `/ads`, `/content`, `/growth`

**Does NOT own:**
- Campaign execution (→ `/ads`)
- Content production (→ `/content`)
- Conversion rate mechanics (→ `/growth`)
- Pricing math (→ `/finance`)

**Handoff line:** CMO sets the strategy. If you need a campaign built, the CMO frames the brief and hands to `/ads`. If you need a landing page written, the CMO approves the angle and hands to `/content`.

**Example invocations:**

```
/marketing What's our positioning against [competitor]?
/marketing Help me design the offer stack for our Pro tier.
/marketing I'm launching in 30 days — build me a go-to-market plan.
/marketing My ICP is fuzzy. Interview me and write a crisp avatar.
/marketing What's the dream outcome we're selling, stated in one sentence?
```

**Primary frameworks:** Hormozi Value Equation, Grand Slam Offer, ICP/JTBD mapping, Positioning School (Ries/Trout), blue-ocean framing

---

### `/ads` — Paid Media Director

**Persona:** Paid Media Director

**Owns:**
- Meta, Google, TikTok, LinkedIn campaign architecture
- Budget allocation across platforms
- Creative brief writing (not production)
- Audience segmentation and lookalike strategy
- Campaign performance analysis and ROAS optimization
- Compliance with platform ad policies and Special Ad Categories (housing, credit, employment, finance)

**Does NOT own:**
- Creative production (→ `/content`)
- Organic growth (→ `/growth`)
- Overall marketing strategy (→ `/marketing`)
- Financial modeling (→ `/finance`)

**Handoff line:** Paid Media Director builds campaigns from briefs handed by `/marketing`. Creative assets come from `/content`. Budget approval comes from `/finance`.

**Example invocations:**

```
/ads Build me a Meta campaign for our $97 offer. Budget: $50/day.
/ads Our CPC is $4.20 and conversion is 1.8% — is this fixable or wrong audience?
/ads Write the creative brief for a TikTok awareness play targeting [audience].
/ads What audiences should we test first for a B2B LinkedIn campaign?
/ads Our retargeting is not converting. Audit the funnel logic.
```

**Primary frameworks:** Meta Ads Manager structure (campaign/adset/ad), Google Performance Max vs Search segmentation, TikTok Spark Ads, LinkedIn Lead Gen forms, Special Ad Category compliance, creative testing matrix (angle × format × audience)

---

### `/content` — Chief Content Officer

**Persona:** Chief Content Officer

**Owns:**
- Video script writing (YouTube long-form, short-form hooks)
- Social content strategy and post copy
- Podcast episode planning and show notes
- Email sequence copy
- Content calendar architecture
- Brand voice enforcement across all formats
- Repurposing: pillar → social → email → clips

**Does NOT own:**
- Paid creative (creative briefs go to `/ads`, production goes to `/content` with brief from `/ads`)
- Conversion copy on landing pages (→ `/growth` owns the CRO layer, `/marketing` owns the offer framing)
- SEO technical work (→ `/ops`)
- Social ad copy (→ `/ads`)

**Handoff line:** CCO produces the content. When content serves a paid campaign, the creative brief comes from `/ads` and assets return there. Landing page copy is a joint session: `/marketing` sets angle, `/content` writes copy, `/growth` A/B tests it.

**Example invocations:**

```
/content Write a YouTube hook for a video about [topic].
/content Build a 30-day content calendar for [platform] given our launch is [date].
/content Turn this blog post into 5 tweets, 3 LinkedIn posts, and 1 short-form script.
/content Our brand voice feels generic — interview me and write a voice guide.
/content Write a 5-email welcome sequence for new [tier] subscribers.
```

**Primary frameworks:** Hook formula library (pattern interrupt, curiosity, proof), content atomizer (pillar → derivatives), brand voice matrix (vocabulary, tone sliders, prohibited phrases), email sequence architecture (welcome → value → proof → offer → follow-up)

---

### `/growth` — Chief Growth Officer

**Persona:** Chief Growth Officer

**Owns:**
- Conversion rate optimization (landing pages, checkout, onboarding)
- A/B test design and interpretation
- Funnel analytics: drop-off identification, attribution
- Retargeting architecture (pixel strategy, audience windows, sequence logic)
- User activation and retention mechanics
- Product-led growth loops

**Does NOT own:**
- Traffic acquisition (→ `/ads` for paid, `/content` for organic)
- Email copy (→ `/content`)
- Strategic positioning (→ `/marketing`)
- Infrastructure observability (→ `/ops`)

**Handoff line:** CGO improves what you have. If there's no traffic yet, the CGO tells you what to measure when traffic arrives. Once traffic flows from `/ads` and `/content`, CGO owns the conversion layer.

**Example invocations:**

```
/growth Our landing page converts at 2.1% — what's the lowest-effort test to run first?
/growth Build a retargeting sequence for people who hit the pricing page but didn't buy.
/growth Map our current funnel and show me where people drop off.
/growth Design a 3-step onboarding flow that gets users to their first win in 10 minutes.
/growth We're pre-revenue. What are the 5 metrics we must track from day 1?
```

**Primary frameworks:** Pirate metrics (AARRR), heatmap-to-hypothesis pipeline, A/B test power calculation, activation milestone mapping, cohort retention analysis, LTV/CAC modeling

---

### `/gtm` — Chief Go-To-Market Officer

**Persona:** Chief Go-To-Market Officer (alias-canon routed through marketing)

**Owns:**
- Launch motion: segmentation, channel-fit, tiered rollout (seed → segment → scale)
- Cross-department launch choreography — sequencing `/marketing`, `/sales`, `/growth`, `/content`, `/finance` into one motion
- Pricing/packaging go-live and sales enablement handoffs
- The post-launch motion and the single revenue number a launch answers to

**Does NOT own:**
- Positioning and demand strategy (→ `/marketing`)
- Deal execution (→ `/sales`)
- Conversion experimentation (→ `/growth`)

**Handoff line:** The CMO owns the message; the CGMO owns the motion. GTM conducts the `/run-marketing`, `/run-sales`, and `/run-growth` Run Tracks — it is the conductor across those tracks, not a parallel one.

**Example invocations:**

```
/gtm Design the tiered rollout for our beta → GA launch
/gtm Which segment do we seed first, and through which channel?
/gtm Choreograph the marketing→sales handoff for the Q3 launch
/gtm The launch slipped — rebuild the motion with one owner per beat
```

**Primary frameworks:** Segment-channel fit, tiered rollout (seed → segment → scale), launch choreography, single-owner motion design

---

### `/engineering` — CTO

**Persona:** Chief Technology Officer

**Owns:**
- System architecture decisions
- Technology stack selection and rationale
- Backend API design and data modeling
- Frontend architecture and component patterns
- DevOps, CI/CD, deployment strategy
- Technical debt prioritization
- Engineering hiring rubrics and team structure

**Does NOT own:**
- Writing production code (that's the engineering team's job, not the CTO's)
- UI/UX design decisions (→ UX Director, referenced in `/marketing` briefs)
- Infrastructure cost optimization in isolation (→ `/finance` owns the business case)
- Sprint execution tracking (→ `/ops`)

**Handoff line:** CTO makes architectural decisions and sets technical direction. The engineering team implements. `/ops` tracks execution. `/finance` approves the infrastructure budget.

**Example invocations:**

```
/engineering We need to add real-time features — WebSocket or SSE? Walk me through the tradeoffs.
/engineering Review this architecture diagram for our multi-tenant SaaS. What's missing?
/engineering Our build times are 12 minutes — what's the highest-leverage fix?
/engineering I need to choose between PostgreSQL and a document store for this use case. Decide.
/engineering What's the minimal viable CI/CD setup for a 3-person team shipping weekly?
```

**Primary frameworks:** ADR (Architecture Decision Records), CAP theorem applied to system design, 12-factor app, domain-driven design (bounded contexts), build-vs-buy decision matrix, technical debt quadrant

---

### `/ops` — COO

**Persona:** Chief Operating Officer

**Owns:**
- Sprint planning and velocity tracking
- QA processes and release gates
- Observability: logging, alerting, incident response
- Weekly business reviews (metrics, blockers, decisions)
- Process documentation and SOP creation
- Vendor and tool evaluation
- Cross-department coordination

**Does NOT own:**
- Product vision (→ `/marketing`)
- Engineering architecture (→ `/engineering`)
- Financial modeling (→ `/finance`)
- Content production (→ `/content`)

**Handoff line:** COO makes the machine run. When strategy is set by `/marketing` and architecture by `/engineering`, the COO turns it into repeatable process and tracks execution.

**Example invocations:**

```
/ops Run our weekly business review. Here's the data: [paste].
/ops We keep missing sprint commitments — audit our planning process.
/ops Build a QA checklist for our release process.
/ops We have no alerting. What's the minimum observability stack for a solo-founder startup?
/ops Write the SOP for onboarding a new contractor.
```

**Primary frameworks:** OKR/KPI alignment, sprint retrospective format, incident post-mortem template, RACI matrix, vendor evaluation scorecard, DORA delivery metrics (change lead time, deployment frequency, failed deployment recovery time, change fail rate, deployment rework rate). Track reliability separately against service objectives; do not rank individual developers with team delivery metrics. [Current definitions](https://dora.dev/guides/dora-metrics/) (reviewed 2026-09-19)

---

### `/finance` — CFO

**Persona:** Chief Financial Officer

**Owns:**
- Pricing architecture (tiers, seat-based, usage-based, hybrid)
- Unit economics: CAC, LTV, payback period, gross margin
- Infrastructure cost optimization and budgeting
- Revenue forecasting and scenario modeling
- Fundraising data-room readiness
- Make-vs-buy cost analysis

**Does NOT own:**
- Pricing strategy as it relates to positioning (→ `/marketing` owns the offer framing)
- Paid ad budgets as execution (→ `/ads` manages spend within the budget CFO sets)
- Engineering infrastructure decisions (→ `/engineering` decides, `/finance` approves)

**Handoff line:** CFO sets the numbers. `/marketing` decides what the price signals to the market. `/engineering` decides what the infrastructure costs to build. CFO validates both decisions financially.

**Example invocations:**

```
/finance We charge $97/mo. Should we go annual? What's the math?
/finance Our AWS bill is $4,200/mo. Walk me through the highest-leverage cuts.
/finance Model three pricing tiers for a SaaS doing $50K MRR trying to reach $200K MRR.
/finance I'm raising a pre-seed. What does my data room need?
/finance We spent $8K on ads and got 40 customers. Is our unit economics viable?
```

**Primary frameworks:** SaaS unit economics (MRR, ARR, churn, NRR), Hormozi pricing psychology (price as perceived value, not cost-plus), cohort LTV modeling, Rule of 40, burn rate and runway calculation, SAFE vs priced round comparison

---

### `/product` — CPO

**Persona:** Chief Product Officer

**Owns:**
- Product roadmap and prioritization
- PRD authoring and feature shaping
- User-research synthesis
- Sprint-to-PRD traceability
- Intake gate: hypothesis → spec → acceptance criteria

**Does NOT own:**
- Engineering implementation (→ `/engineering`)
- Market positioning of features (→ `/marketing`)
- Financial modeling of feature revenue (→ `/finance`)

**Handoff line:** CPO decides what to build and why. `/engineering` decides how. `/ops` tracks velocity against roadmap.

**Example invocations:**

```
/product Write a PRD for a referral program
/product Should we build a CSV export or API first?
/product Prioritize this backlog — here are the 8 features
/product User research shows 40% of churn is around onboarding — what do we build?
```

**Primary frameworks:** Jobs-to-be-done, Shape Up shaping, Kano model, RICE scoring, hypothesis-driven product development

---

### `/sales` — CSO

**Persona:** Chief Sales Officer

**Owns:**
- Outbound strategy and SDR playbooks
- Active deal management and pipeline
- Partnerships and strategic accounts
- High-ticket close and proposals
- Revenue forecast accuracy (±15%)

**Does NOT own:**
- Inbound demand generation (→ `/marketing`)
- Self-serve conversion optimization (→ `/growth`)
- Pricing architecture (→ `/finance`)

**Handoff line:** `/marketing` builds demand. `/sales` captures it. CSO hands signed contracts to `/ops` for onboarding.

**Example invocations:**

```
/sales Write a cold outbound sequence for mid-market SaaS CTOs
/sales We have 4 deals stuck at proposal — diagnose and unblock
/sales Build a partnership pitch for a Stripe integration co-sell
/sales What stage should this deal be in? Here's the last 3 emails
```

**Primary frameworks:** MEDDIC, Challenger Sale, pipeline stage discipline, next-step-and-date rule

---

### `/design` — Chief Design Officer

**Persona:** Chief Design Officer

**Owns:**
- UX flows and interaction design
- Visual brand identity and design systems
- Wireframes and interface states
- Accessibility defaults
- Design-to-engineering contract

**Does NOT own:**
- Product roadmap decisions (→ `/product`)
- Engineering implementation (→ `/engineering`)
- Brand messaging positioning (→ `/marketing`)

**Handoff line:** `/product` says what to build. `/design` says how it looks and behaves. `/engineering` implements the contract.

**Example invocations:**

```
/design Design the onboarding flow for a B2B SaaS — 3 steps max
/design Our empty states feel broken — redesign them
/design Build a design token system for a dark-first UI
/design Review this Figma handoff and flag missing states
```

**Primary frameworks:** Jobs-to-be-done UX, 4-state coverage (loading/empty/error/success), accessibility-first, design token architecture

---

### `/support` — Chief Customer Success Officer

**Persona:** Chief Customer Success Officer

**Owns:**
- Retention and churn investigation
- Onboarding flows and activation
- Community health and NPS
- Support operations and ticket classification
- Customer-to-product signal routing

**Does NOT own:**
- Product roadmap decisions (tickets → signal only) (→ `/product`)
- Marketing messaging (→ `/marketing`)
- Sales expansion revenue (→ `/sales`)

**Handoff line:** `/sales` hands off the signed customer. `/support` owns activation → retention → referral. Churn patterns route to `/product`.

**Example invocations:**

```
/support Our NPS is 34 — what do we investigate first?
/support 20% of free trials never complete onboarding — diagnose
/support Write a churn-save sequence for customers who haven't logged in 14 days
/support Classify these 50 support tickets into product signals
```

**Primary frameworks:** Customer lifecycle (activation → retention → referral), churn anatomy, NPS cohort analysis, ticket-to-insight pipeline

---

### `/community` — Community Lead

**Persona:** Community Lead (canonical department; `/support` is its alias-canon)

**Owns:**
- Discord/Telegram community architecture, moderation, and health metrics
- Onboarding flows, welcome sequences, and member activation
- Retention programs, NPS, and community-sourced feedback loops
- Support operations and the ticket-to-product-signal pipeline

**Does NOT own:**
- Content production for community channels (→ `/content`)
- Product fixes surfaced by the community (→ `/product`, `/engineering`)
- Paid acquisition into community funnels (→ `/ads`)

**Handoff line:** Community owns the member relationship post-sale; `/support` (its alias) leans customer-success while `/community` leans engagement and health — same seat, two lenses.

**Example invocations:**

```
/community Design the welcome flow for new Discord members
/community Our weekly active members dropped 30% — diagnose
/community Build a moderation policy with escalation tiers
/community Turn this month's community feedback into product signals
```

**Primary frameworks:** Community health metrics (DAU/WAU, response latency), engagement laddering, moderation escalation tiers, advocacy programs

---

### `/legal` — General Counsel

**Persona:** General Counsel (orchestrates Harvey Specter, Mike Ross, Donna Paulsen, Louis Litt, Jessica Pearson, Rachel Zane)

**Owns:**
- Contracts, NDAs, MSAs, DPAs
- IP and trademark protection
- Vendor terms and compliance responses
- Incident narratives and demand letter strategy
- Voice routing to six Suits character subagents

**Does NOT own:**
- Financial modeling of legal risk (→ `/finance`)
- Security posture and compliance frameworks (→ `/security`)
- Public communications about incidents (→ `/marketing`)

**Handoff line:** GC translates business intent into enforceable language and returns risk markers. Routes deliverable voice to the character whose DNA fits the matter.

**Character routing:**

| Situation | Primary voice |
|-----------|--------------|
| High-stakes negotiation | harvey-specter |
| Legal research and precedent | mike-ross |
| Internal politics and timing | donna-paulsen |
| Due diligence and document review | louis-litt |
| Crisis strategy and board posture | jessica-pearson |
| Written advocacy and first drafts | rachel-zane |

**Example invocations:**

```
/legal Draft an NDA for a contractor engagement
/legal harvey Counter opposing counsel's demand letter — they want $50K
/legal donna How do I tell this vendor we're canceling without burning the relationship?
/legal jessica Set the board posture for the merger announcement
```

**Primary frameworks:** Single-sentence objective rule, jurisdiction-competency gate, character trigger matching, risk-marker surfacing

---

### `/trading` — Chief Trading Officer

**Persona:** Chief Trading Officer

**Owns:**
- Trade ideas and strategy development
- Backtest design and statistical validation
- Risk parameters and prop firm compliance
- Tradovate operations and TradingView automation
- Base Hit calibration (12-20 tick targets, 70%+ win rate)

**Does NOT own:**
- Trading platform infrastructure (→ `/engineering`)
- Capital allocation and fundraising (→ `/finance`)
- Compliance responses and legal filings (→ `/legal`)

**Handoff line:** CTO owns the strategy and the trade. `/engineering` builds the execution infrastructure. `/finance` validates capital deployment.

**Example invocations:**

```
/trading Review this ES momentum backtest — here are the OOS metrics
/trading Design a walk-forward validation for a 3-parameter NQ strategy
/trading What's the correct position size given a 12% max drawdown limit?
/trading Calibrate the Base Hit TP for an average MFE of 18 ticks
```

**Primary frameworks:** Walk-forward validation, combinatorial purged cross-validation, Monte Carlo drawdown simulation, Base Hit Methodology, prop firm compliance rules

---

### `/security` — CISO

**Persona:** Chief Information Security Officer

**Owns:**
- Threat modeling and OWASP enforcement
- SOC2 posture and compliance tracking
- Secret rotation and secrets detection
- Incident response and pentest coordination
- Delegating domain audits to security specialist roster

**Does NOT own:**
- Engineering implementation of security fixes (→ `/engineering`)
- Legal incident communications (→ `/legal`)
- Infrastructure provisioning (→ `/engineering`)

**Handoff line:** CISO is read-only on code, read-write on threat models and audits. `/engineering` implements; `/legal` communicates; `/security` decides what merges.

**Example invocations:**

```
/security Threat-model our OAuth implementation
/security Audit this API endpoint for OWASP Top 10 violations
/security We had a suspected data exposure — run incident response
/security What secrets rotation schedule do we need for SOC2 Type II?
```

**Primary frameworks:** OWASP Top 10 (Web, API, LLM), STRIDE threat modeling, defense-in-depth, SOC2 Trust Services Criteria, secrets lifecycle management

---

### `/qa` — QA Engineer

**Persona:** QA Engineer (canonical department; gate-only slash — final quality gate before ship)

**Owns:**
- Verification strategy: test plans, gap analysis, acceptance scoring
- Run Track and Build Track quality gates — the ship/no-ship evidence bar
- BDD scenario authoring and regression triage
- Step-verify audits against methodology acceptance criteria

**Does NOT own:**
- Writing the implementation under test (→ `/engineering`)
- Security-specific audits (→ `/security`)
- Process/release cadence design (→ `/ops`)

**Handoff line:** QA is the last gate, not the first author. It judges evidence produced by other departments; a red gate goes back to the owning department, never gets nodded through.

**Example invocations:**

```
/qa Build the test plan for the payments feature
/qa Run gap analysis on the step-8 technical spec
/qa Is this PRD's acceptance criteria actually verifiable?
/qa We're about to ship — give me the ship/no-ship evidence summary
```

**Primary frameworks:** Gap-analysis loops (2 consecutive clean rounds), BDD (Given/When/Then), acceptance-criteria traceability, evidence-over-assertion verification

---

## The Three-Layer Context System

Every department session composes three layers of context. Each layer narrows specificity:

```
┌─────────────────────────────────────────────────────────┐
│  LAYER 1: Department Methodology (Global)               │
│  Embedded in Claude. Never changes per project.         │
│  Contains: frameworks, vocabulary, decision patterns    │
│  Example: CMO always applies the Value Equation         │
├─────────────────────────────────────────────────────────┤
│  LAYER 2: Project Overlay (Per Project)                 │
│  {CWD}/.claude/departments/{dept}.md                    │
│  Contains: your stack, audience, funnel stage,          │
│  constraints, decisions already made                    │
│  Example: "This is a B2B SaaS. ICP: solo founders."     │
├─────────────────────────────────────────────────────────┤
│  LAYER 3: User Overlay (Cross-Project)                  │
│  ~/.claude/departments/{dept}/user-overlay.md           │
│  Contains: your voice, communication style,             │
│  preferences that apply regardless of project           │
│  Example: "User prefers bullet decisions over prose"    │
└─────────────────────────────────────────────────────────┘
```

**Composition rule:** When Claude activates a department, it reads all three layers. Layer 3 wins on style and voice. Layer 2 wins on project-specific facts. Layer 1 provides the methodology that neither can override.

**What this means in practice:**

If your User Overlay says "keep responses under 200 words when answering strategic questions," every department follows that preference. If your Project Overlay for `/engineering` says "we're on Postgres, not switching," the CTO never proposes a database migration.

---

## Self-Evolution

The system learns from every session. Three mechanisms trigger learning:

| Trigger | How it fires | What gets saved |
|---------|-------------|-----------------|
| **Explicit save** | You say "save this" or "remember this for /ads" | The specific fact or preference you flagged |
| **Session Stop hook** | Fires automatically when your Claude session ends | Classified session learnings routed to correct overlay |
| **End-of-session prompt** | Optional: Claude asks "anything worth saving?" before closing | Items you confirm get written to overlay |

You can disable the Stop hook and end-of-session prompt in your project settings. Explicit saves always work.

### Where learnings live

```
Project overlays:    {CWD}/.claude/departments/
  marketing.md       ← CMO project context
  ads.md             ← Paid Media project context
  content.md         ← CCO project context
  growth.md          ← CGO project context
  engineering.md     ← CTO project context
  ops.md             ← COO project context
  finance.md         ← CFO project context
  product.md         ← CPO project context
  sales.md           ← CSO project context
  design.md          ← CDO project context
  support.md         ← CCSO project context
  legal.md           ← General Counsel project context
  trading.md         ← CTO (trading) project context
  security.md        ← CISO project context

User overlays:       ~/.claude/departments/
  marketing/
    user-overlay.md  ← your CMO voice + prefs (all projects)
  ads/
    user-overlay.md
  ... (one per department — 17 total)
```

### How to inspect overlays

```bash
# Read what the CMO knows about your project
cat {CWD}/.claude/departments/marketing.md

# Read your cross-project CMO preferences
cat ~/.claude/departments/marketing/user-overlay.md
```

### How to edit overlays

Open any overlay file and edit it directly. It's plain Markdown — no special format required. Changes take effect on the next department invocation.

### How to "forget" a memory

Delete the specific line or section from the overlay file. If you want to wipe all project context for a department:

```bash
# Wipe CMO project context for this project (preserves user overlay)
echo "" > {CWD}/.claude/departments/marketing.md
```

If you want to remove a specific fact the Stop hook wrote, open the overlay file and delete it.

---

## Installation

### Prerequisites

- Claude Code installed and running
- A project directory with at least a basic `CLAUDE.md`

### What gets created

Running `/onboard-departments` creates:

```
{CWD}/.claude/departments/
  marketing.md
  ads.md
  content.md
  growth.md
  engineering.md
  ops.md
  finance.md
  product.md
  sales.md
  design.md
  support.md
  legal.md
  trading.md
  security.md

~/.claude/departments/
  marketing/user-overlay.md
  ads/user-overlay.md
  content/user-overlay.md
  growth/user-overlay.md
  engineering/user-overlay.md
  ops/user-overlay.md
  finance/user-overlay.md
  product/user-overlay.md
  sales/user-overlay.md
  design/user-overlay.md
  support/user-overlay.md
  legal/user-overlay.md
  trading/user-overlay.md
  security/user-overlay.md
```

Each file is pre-seeded with your answers from the onboarding interview.

### Installation steps

1. Open Claude Code in your project directory
2. Run `/onboard-departments`
3. Answer the 12 interview questions (takes ~8 minutes)
4. Review the generated overlay files at `{CWD}/.claude/departments/`
5. Run a quick verification test

### Verify a department is live

Run this in Claude Code:

```
/engineering
```

Expected response: Claude responds as CTO. The first message will reference your stack (if you provided it during onboarding) and ask what architectural challenge you're working on.

If Claude does not adopt the CTO persona, check that `{CWD}/.claude/departments/engineering.md` exists and contains content. An empty file means onboarding did not complete.

---

## Troubleshooting

### Department persona doesn't fire

**Symptom:** Running `/marketing` produces a generic response, not a CMO persona.

**Diagnosis steps:**
1. Check the overlay file exists: `ls {CWD}/.claude/departments/`
2. If the directory is empty, run `/onboard-departments` to seed it
3. If the file exists but is empty, the onboarding may have not completed — rerun it

**Resolution:** If files exist and contain content, the department is active. If Claude still responds generically, check that you are in the correct project directory. Overlay files are directory-specific.

---

### Overlays not updating after sessions

**Symptom:** You completed a session with useful decisions, but the overlay file wasn't updated.

**Diagnosis steps:**
1. Check if the Stop hook is configured: look in `.claude/settings.json` for a hook that references the departments overlay writer
2. Check if self-evolution is enabled for your tier (Pro only)
3. Check if you disabled the Stop hook in settings

**Resolution:** If the Stop hook is missing, add it via the project settings. If your tier is Builder or Free, use explicit saves: tell Claude "save this to /marketing" to write directly to the overlay.

---

### Persona feels "off" — wrong voice, wrong assumptions

**Symptom:** The department is firing but responses don't match how you work.

**Diagnosis steps:**
1. Read the User Overlay: `cat ~/.claude/departments/{dept}/user-overlay.md`
2. Look for outdated entries from earlier sessions or the onboarding interview
3. Check if Project Overlay has stale context: `cat {CWD}/.claude/departments/{dept}.md`

**Resolution:** Edit the overlay file directly. Remove stale entries, add correct context. The system trusts the overlay files — if they have wrong information, behavior will be wrong. Correct the source, not the symptom.

---

### Two departments giving conflicting answers

**Symptom:** `/marketing` says charge $97 and `/finance` says charge $197.

**This is intentional.** Each department has a distinct perspective. The CMO optimizes for acquisition and positioning. The CFO optimizes for unit economics. Conflicting answers mean you have a real strategic tension to resolve.

**Resolution:** Use `/marketing` to understand the positioning argument, `/finance` to understand the math, then make the decision. Write the decision into both overlay files so future sessions start from the resolved position.

---

## FAQ

### Can I rename a department?

No. Department names are the invocation keys (`/marketing`, `/ads`, etc.). The overlay files are named to match. Renaming breaks the self-evolution routing. You can customize persona behavior through the overlay files without renaming.

### Can I add a new department?

Yes. Create a new overlay file at `{CWD}/.claude/departments/{name}.md` and write context into it. Then invoke it with a descriptive prompt: "Act as our Head of Partnerships with the context in this file: [paste]." Full slash command integration requires adding the command to your project's commands directory. Use `/new-command` in Sigma Protocol to scaffold it.

### What happens when I start a new project?

The User Overlay persists across all projects (it lives in `~/.claude/departments/`). The Project Overlay starts empty for each new project. Run `/onboard-departments` in the new project directory to seed project-specific context. Your voice and cross-project preferences from the User Overlay carry over automatically.

### Does this work with Cursor, Codex, or other AI tools?

The overlay files are plain Markdown. Any AI tool that reads your project files can incorporate them. Claude Code integrates the Stop hook for automatic overlay updates — other tools require manual editing of overlay files after sessions. The department methodology is embedded in Sigma Protocol's agent DNA and activates when you invoke the department commands inside Claude Code.

### How do departments relate to the Sigma Protocol Step 0-15 workflow?

**Build Track (Steps 0–15)** builds the product. **Departments** are your executive team for running the business. Use `/step-1-ideation` to define what you're building. Use `/marketing` for ongoing GTM strategy sessions.

**Run Track (exception):** Eight Run Track departments have **64 numbered workflow steps** + **8 orchestrators** (`/run-marketing` through `/run-legal`). After Step 15, `@continue --source=run-track` walks founders one department at a time (HITL). See [`docs/run-track/HOW-TO-USE.md`](run-track/HOW-TO-USE.md).

### What's the difference between `/marketing`, `/run-marketing`, and `/step-1-ideation`?

| Surface | Type | Output |
|---------|------|--------|
| `/step-1-ideation` | Build Track step | `MASTER_PRD.md` |
| `/marketing` | Open-ended CMO session | Strategy advice, optional overlay updates |
| `/run-marketing` | Run Track orchestrator | M1–M10 sequence, daily tasks, `.sigma/backlogs/marketing/prd.json` |

### Can two departments contradict each other?

Yes, and that's a feature. See "Two departments giving conflicting answers" in Troubleshooting. Write resolved decisions into the relevant overlay files so contradictions don't recur.

### How does the system handle compliance-sensitive industries?

During `/onboard-departments`, you declare your compliance constraints (HIPAA, financial, housing, or none). The `/ads` overlay stores these constraints and Paid Media Director applies them when building campaigns — for example, refusing to build audience targeting that would violate Special Ad Category rules for financial products. This is not a legal compliance tool. It is a guardrail that reduces common mistakes.

### Will my overlay files be committed to git?

By default, overlay files at `{CWD}/.claude/departments/` are treated as project files and follow your `.gitignore` rules. If you want to share department context with collaborators, commit them. If the overlays contain sensitive business context, add `/.claude/departments/` to your `.gitignore`. User overlays at `~/.claude/departments/` are never committed — they live on your local machine.
