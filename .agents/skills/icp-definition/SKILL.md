---
name: icp-definition
department: sales
description: "Build an Ideal Customer Profile + Negative-ICP + 100-point scorecard, sorted by Sheila's whale-vs-goldfish and poor-vs-wealthy buyer contrast. Use when defining who to sell to, building an ICP, deciding who to disqualify, or sorting buyers by value. Triggers on 'ideal customer profile','ICP','negative ICP','who to sell to','buyer persona','whale vs goldfish','target customer','disqualify customers'."
triggers:
  - icp
  - ideal-customer-profile
  - negative-icp
  - buyer-persona
  - customer-sorting
---

# ICP Definition

## When to Use

- Defining who to sell to before any outbound activity begins.
- Building an Ideal Customer Profile, its negative counterpart, and a usable scorecard.
- Deciding which buyers to chase and which to deliberately repel.
- Sorting an existing book by value (whales vs goldfish) to find where the revenue actually is.

A precise ICP is the foundation of all outbound. Without it, reps chase unqualified leads, write generic messages, and lose deals they should never have pursued. The `lead-qualification` skill scores an individual prospect; this skill defines the profile that scoring runs against.

## Core DNA (operators behind this)

**Sheila Bella** — sort buyers by value, then deliberately repel the wrong ones.

**Whales vs. Goldfish:**
> "$20k/mo = 1,000 goldfish @ $20 **or** 10 whales @ $2,000. **The clients you lose by raising prices are the ones you want to lose.**" Raising prices is a marketing strategy — it filters for the clients you want.

**Poor-vs-Wealthy buyer contrast (ICP-sorting, reels `DY3Y25wJQsT`, `DZEiLiksZPR`):**
> "You price based on transformation… not your insecurity." "Your price is your posture." "Your DMs are just a door." "Desperation is loud, silence is strategy."

| Poor buyer (repel — Negative ICP) | Wealthy buyer (attract — ICP) |
|-----------------------------------|-------------------------------|
| Competitor-compares ("the girl down the street does it cheaper") | Doesn't know your competitor's price — not looking |
| Hourly / price-anchored | Outcome-priced — "the result has a price" |
| Wants a discount; pre-negotiates | Needs no convincing — the **3-message DM** ("Hey I'd love to book" / "here's my link" / done) |
| 47-message DM, ghosts, "I'll think about it" | Three messages, books, pays |
| "Book me, please" energy repels money | Treats it as "two adults making a transaction" |

The poor-vs-wealthy contrast IS the ICP/Negative-ICP sorting line: the wealthy buyer is the positive ICP, the poor buyer is the Negative ICP. You're not pricing for what you think people can afford — you're pricing for the transformation and letting the wrong buyers self-remove.

## Frameworks

### The 6 ICP dimensions (repo `sales-icp/`)

Define each with concrete numbers, named tools, specific titles — never "mid-market".

1. **Firmographic** — revenue range, employee range, primary + secondary verticals (ranked), geography, stage, growth rate. Table columns: Criteria · Ideal Range · Why It Matters · Red Flag If Missing.
2. **Technographic** — current stack signals, technical sophistication (1–5), integration readiness, adoption patterns, digital maturity.
3. **Behavioral** — content consumption, event attendance (named), community membership, buying patterns, social signals, hiring patterns.
4. **Pain-point map** — top 3–5 pains, each with severity (Critical/High/Medium), how it manifests, business impact, trigger events, current workaround, your solution angle.
5. **Budget qualification** — revenue thresholds, funding stage, tech-spend %, deal-size sweet spot, budget-cycle timing, price sensitivity, ROI expectations, budget-authority signals.
6. **Channel preferences** — research channels, preferred contact methods (ranked), decision process, content preferences, engagement cadence, trust signals.

### Negative ICP (≥8–10 disqualifiers — as important as the positive)

Document the red flag AND why it disqualifies: too small · too large · wrong industry · wrong tech stack · wrong stage · no budget signals · cultural misfit · long-sales-cycle risk · high churn risk · competitive lock-in. The whale-vs-goldfish sort means goldfish-only buyers (price-anchored, discount-seeking, competitor-comparing) belong in the Negative ICP — "the clients you lose by raising prices are the ones you want to lose."

### 100-point scorecard (repo)

| Category | Max | What it scores |
|----------|-----|----------------|
| Firmographic Fit | 25 | Size, industry, geography, stage |
| Technographic Fit | 15 | Stack, sophistication, integration readiness |
| Pain Point Alignment | 20 | Severity, urgency, workaround inadequacy |
| Budget Capacity | 20 | Revenue, funding, tech spend, deal-size fit |
| Contact Access | 10 | Decision maker identified, warm path |
| Timing Signals | 10 | Trigger events, budget cycle, urgency |

Each category defines what scores 0% / 25% / 50% / 75% / 100% so a rep can score a lead in under 5 minutes.

**Grade bands:** A+ (90–100) drop everything · A (75–89) high priority · B (60–74) good fit, don't over-invest · C (40–59) marginal, nurture only · D (0–39) does not fit, no sales time.

**60-second checklist:** target industry? · ideal size? · growth signals? · likely pain point? · decision maker findable? — 5 Yes ≈ A, 3–4 ≈ B, 1–2 ≈ C, 0 ≈ D.

### Buyer personas (2–3, repo)

Each: archetype name · demographic profile · day-in-the-life · goals/KPIs · pains (their language) · information diet · top objections (their words + underlying concern) · resonant messaging · what turns them off · how to win them over. Apply the wealthy-buyer lens: the positive personas should be outcome-priced buyers who need a door, not a discount.

## Anti-Patterns

- Pricing/targeting for "what you think people can afford" instead of the transformation (poor-buyer sorting error).
- A positive ICP with no Negative ICP — repelling the wrong buyers is half the work.
- Chasing goldfish (1,000 @ $20) when the same revenue is 10 whales @ $2,000.
- Generic firmographics ("mid-market") instead of exact ranges and named verticals.
- Treating discount-seeking, competitor-comparing buyers as ICP rather than Negative-ICP.
- A scorecard a rep can't run in under 5 minutes.

## Quality Gates

- [ ] All **6 ICP dimensions** defined with concrete numbers / named tools / specific titles.
- [ ] **Negative ICP** lists ≥8 disqualifiers, each with the red flag AND why it disqualifies.
- [ ] **100-point scorecard** with 0/25/50/75/100% anchors per category + grade bands.
- [ ] 60-second qualification checklist included.
- [ ] Buyers explicitly sorted **whale vs goldfish** — goldfish-only profiles routed to Negative ICP.
- [ ] Positive personas are **wealthy-buyer / outcome-priced** (need a door, not a discount).
- [ ] 2–3 buyer personas with objections in their own language.


## Transcript-grounded upgrade
**Account-first ICP fields** — define the account before the persona, and make it observable so an agent (or an
AI SDR) can actually build the list:

| field | definition | agent-usable test |
|---|---|---|
| exact customer | the specific company type, not a category | could you name 20 real ones |
| actual problem | the concrete pain they already feel | they'd describe it unprompted |
| observable trigger | the event that opens the buying window | hiring / funding / tech change / ad spend (src: rPvCd0qp8KY) |
| role relevance | who owns the problem | title + responsibility, not seniority alone |
| current system | what they use now | competitor-displacement read |
| buying event | what forces a decision | deadline / mandate / pain threshold |
| bad-fit rule | the disqualifier that kills the account | protects the list from waste (src: _0FmtxcBm3w) |
| data-quality score | how clean/verifiable the record is | low score → bad-data, not wrong-ICP |
| proof requirement | the evidence this segment needs | case study / number / referral |

**Build step:** before any outbound, assemble the **first 50–100 target accounts** that pass every field —
this is the readiness input `ai-sdr-readiness-gate` checks first. A weak ICP scales failure no matter how good the
model (src: c89JJ4RnMcc, vCx9Sm6gF9A). Distinguish a **wrong-ICP** miss (targeting) from **bad-data** (list quality)
and route to `lead-qualification` accordingly.

**Owners:** ross (account-first system), braun (trigger sourcing), general (governance).
