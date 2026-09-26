---
name: lead-qualification
department: sales
description: "Point-scored lead qualification using BANT, MEDDIC, a confidence ladder, and a CAC-to-LTV stall check. Use when scoring or grading a lead, deciding whether to pursue it, or computing an opportunity quality score."
triggers:
  - lead-qualification
  - bant
  - meddic
  - lead-scoring
  - disqualification
---

# Lead Qualification

## When to Use

- You have a prospect (URL, company, contact) and need a 0–100 quality score + letter grade.
- You're deciding pursue vs. nurture vs. drop, and need a deterministic rubric, not a gut call.
- You want a confidence level attached to a score (so weak data doesn't masquerade as a strong lead).
- You're checking for disqualification signals before investing rep time or building a proposal.

This is scoring/grading. Live diagnosis happens in the `discovery` skill; this skill turns signals into a number and a decision.

## Core DNA (operators behind this)

**Alex Hormozi** — the CAC-to-LTV stall predictor identifies a structural disqualifier the rubrics miss.
> "Drop low, go high. The middle's just a dead zone where everyone dies." (`jqo0lVveh98` 12:38)

The repo's BANT/MEDDIC machinery scores fit. Hormozi's stall predictor catches a prospect that scores "fine" on fit but sits in a band that structurally won't convert/retain — a disqualification signal at the qualify stage.

## Frameworks & Rubrics

### BANT — point-scored (0–100, four dimensions × 25)

| Dimension | What it measures | 25-pt anchor | 0-pt anchor |
|-----------|------------------|--------------|-------------|
| **Budget** | Financial capacity + willingness | Recent funding / clear enterprise spend, high confidence | Early-stage, cost-conscious, or financial distress |
| **Authority** | Decision maker identified + reachable | Clear buying authority, direct path to DM | Cannot identify decision makers from public data |
| **Need** | Problem you solve + awareness | Clear, validated pain, actively seeking | No visible need; solution premature |
| **Timeline** | Urgency / decision timeframe | Active buying process or trigger in last 30 days | No urgency detected; long-term nurture |

`BANT Score = Budget + Authority + Need + Timeline` (0–100).

### MEDDIC — completeness (% of 6 elements at medium+ confidence)

Metrics · Economic Buyer · Decision Criteria · Decision Process · Identify Pain · Champion.
`MEDDIC Completeness = (elements with Medium+ confidence / 6) × 100`.

### Confidence ladder (attach to every signal)

| Confidence | Definition | Example |
|-----------|-----------|---------|
| **High** | Directly stated / clearly observable | Pricing page shows $499/mo enterprise tier |
| **Medium** | Reasonable inference from data | 5 open eng roles → growing tech team |
| **Low** | Indirect signal needing interpretation | Blog post on "scaling challenges" |
| **Inferred** | Educated guess from company profile | Series B → likely $500K+ software budget |

If BANT < 25 AND confidence is Low/Inferred across all dimensions → recommend manual research before any outreach.

### Opportunity Quality Score + grade

```
Opportunity Quality Score = BANT × 0.50 + MEDDIC_Completeness × 0.30 + Urgency_Modifier × 0.20
```

| Grade | Score | Label | Action |
|-------|-------|-------|--------|
| **A** | 75–100 | Sales Qualified Lead | Senior rep, personalized outreach now, multi-thread, prepare custom proposal |
| **B** | 50–74 | Marketing Qualified Lead | Standard sequence, discovery call, fill MEDDIC gaps, nurture |
| **C** | 25–49 | Information Qualified Lead | Long-term nurture, thought leadership, re-qualify in 60–90 days |
| **D** | 0–24 | Unqualified | Do not pursue actively; awareness only |

### Repeatable scoring

Use the equations and anchors above to make the score reproducible. This repository does not ship a `lead_scorer.py`; do not claim a tool-generated score unless the current project provides and runs a scorer. Record the underlying signals and their confidence with every score so another operator can recalculate it.

### Unit economics evidence

Assess acquisition cost, gross margin, retention and service capacity using the prospect's actual cohorts. Pricing bands alone do not predict churn or business viability. The historical Hormozi “SMB middle band” example is a hypothesis, not an automatic disqualifier. Record missing data and uncertainty; change a lead's grade only when documented fit or economic evidence justifies it. Prepayment changes cash timing and commitments; it does not prove retention or profitability.

## Anti-Patterns

- Grading a lead from a gut feel instead of the documented point-scored rubric.
- Reporting a score without a confidence level — weak data masquerading as a strong lead.
- Building a custom proposal for a C/D lead (proposal is paid expertise — see `discovery` qualify-first gate).
- Overriding measured customer economics with a universal pricing-band rule.
- Pursuing a D lead with rep time instead of marketing awareness.
- Treating MEDDIC as filled when elements are only Low/Inferred confidence.

## Quality Gates

- [ ] BANT scored across all four dimensions (each 0–25, total 0–100).
- [ ] MEDDIC completeness computed (% of 6 at medium+ confidence).
- [ ] Every signal carries a **confidence level** (High / Medium / Low / Inferred).
- [ ] Opportunity Quality Score + letter grade assigned via the 75/50/25 cutoffs.
- [ ] Score is derived from the documented equations and recorded signals, not a freehand number.
- [ ] Unit economics checked from cohort evidence; no price-band-only downgrade or disqualification.
- [ ] If BANT < 25 with Low/Inferred confidence → manual research recommended before outreach.


## Transcript-grounded upgrade
**Canonical qualification field set** — every lead the agent touches carries these (write to CRM):

| field | what it captures | why it gates the deal |
|---|---|---|
| trigger | the observable event that made now the time | no trigger = nurture, not pursue (src: a2a6KYS2sDw) |
| pain | the named problem in the buyer's words | discovery anchor |
| consequence | cost of NOT solving it | builds urgency (src: m_ZDKTdwuWE) |
| authority | can THIS person decide | routes to `stakeholder-authority-mapping` |
| partner/boss involvement | who else signs off | prevents the late partner objection |
| budget range | rough order of magnitude | fit vs. waste |
| start window | when they'd begin | real timing vs. stall |
| proof need | what evidence they require | de-risks the close |
| current provider | what they use now | competitor-comfort read |
| implementation capacity | time/people to actually use it | post-sale success signal |
| disqualifier | the one fact that kills it | kill fast, protect calendar |
| next state | the single next CRM move | no dead ends |

**Traffic-light disposition:** 🟢 green (trigger + authority + budget + window all present → pursue) ·
🟡 yellow (2–3 present → diagnostic call to fill gaps) · 🔴 red (no trigger or hard disqualifier → nurture/drop).

**Bad-data vs wrong-ICP split (do not confuse them):** if the contact bounces / wrong-role / dead number →
*bad data* (list-quality problem, route to `ai-sdr-readiness-gate`). If reachable but a structural no-fit →
*wrong ICP* (targeting problem, route to `icp-definition`). Scaling either without fixing the root scales failure (src: B-2OMCcB-io).

**Owners:** ross (systems/fields), miner (consequence depth), general (governance). The qualification write-up is
internal → runs without a gate; only outreach to a new contact is queued for approval.
