---
name: retention-engine
description: "Post-sale retention architecture — cohort measurement, evidence-based onboarding milestones, Value Per Second (subtraction over addition), 10 True Regulars, and annual-plan conversion math. Use when designing retention, lowering churn, building onboarding milestones, converting to annual plans, or deciding what to subtract from an offer. Triggers on 'retention','reduce churn','churn benchmark','day 90','month 6','value per second','10 true regulars','annual plan','keep customers'."
department: marketing
triggers:
  - retention
  - churn
  - retention-cohort
  - value-per-second
  - annual-plan-conversion
---

# Retention Engine

## When to Use

- Designing the post-sale retention architecture for a subscription / membership / recurring offer.
- Churn is too high and you need the cohort lens, not a flat number.
- Building onboarding so a customer hits an early win, then locks in socially.
- Deciding what to **subtract** from an offer to raise perceived utilization.
- Converting monthly customers to annual plans (and pricing the discount).

This is the **marketing** post-sale layer (Hormozi = CMO). No existing marketing skill covers retention. Pairs with the sales-side `follow-up-system` (renewal trigger touches) — this skill owns the retention *architecture*, follow-up owns the *cadence*.

## Core DNA (operators behind this)

**Alex Hormozi** — churn is cohort-dependent; subtraction beats addition after the sale.
> "Don't ask 'how do I make churn go down' but 'how do I get someone to stay past day 90?'" (`-j8_YCWZ05Q` 04:29)
> "Value per second, not seconds of value. Someone is more likely to churn because you added more stuff — now they feel they're using not enough of it." (`-j8_YCWZ05Q` 12:02)

## Frameworks

### Retention cohorts and milestones

Measure retention and churn by acquisition cohort, segment, plan and observation window. Record denominator, cancellations, renewals and censoring; logo retention and revenue retention are different measures. There is no universal 90-day cliff or 6-month churn rate. Choose an early-value milestone and, where the product benefits from community, a voluntary peer connection. Test their effect against the project's baseline rather than assuming that timing causes retention.

### Value Per Second (subtraction > addition for retention)

More features can increase complexity or leave customers feeling they are not getting value. Interview customers and measure use before removing or adding features; either change can help or harm retention.

**Practitioner example:** simplified packaging may improve perceived value. The earlier Planet Fitness percentages are unverified here and must not be used as a forecast.

**Diagnostics:**
- "If I deleted everything, what one thing would you fight for?"
- "Which feature would you not miss?"

Optimize for **value per second, not seconds of value.** This is the post-sale counter-principle to offer-stacking (which applies before the sale).

### 10 True Regulars (social lock-in)

Spotlight your top-10 most-engaged members. Introduce them to every newcomer. New members anchor to the regulars → the month-6 peer-connection milestone gets engineered, not hoped for. Measure whether these introductions help this community; do not promise a universal retention effect.

### Annual-plan conversion (offsets CAC, locks the cohort)

Convert monthly → annual to lock the cohort and offset acquisition cost. The standard structure:

> **"buy 10, get 2 free"** — 12 months for the price of 10 ≈ a **16–17% discount** (2/12 ≈ 16.7%).

Annual prepay changes cash timing and contract duration. It does not establish engagement, realized lifetime value or renewal. Model margin, refund obligations and customer fit before offering a discount.

## Anti-Patterns

- Comparing churn percentages with different time windows or denominators.
- Treating contract duration as evidence of continued product use.
- Adding or removing features without customer evidence.
- Treating creator anecdotes as universal thresholds for ad spend, tier pricing or retention.

## Quality Gates

- [ ] Cohort, denominator, window and retention definition recorded.
- [ ] Milestones tied to observed first value and product fit.
- [ ] Intervention compared with the project's baseline; uncertainty is visible.
- [ ] Annual-plan economics and terms modeled before approval.
- [ ] Named practitioner guidance is a hypothesis, not a measured result for this project.
