# Research: Sales Team Onboarding → Run Track S1–S8

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Sources:** HubSpot onboarding guides (2026), RevBlack lifecycle/handoff guide (2026), SalesHive HubSpot vs Salesforce (2026), Salesforce pipeline management, HubSpot Community B2B SaaS pipeline (2026), existing [`sales/department.md`](../../.agents/departments/sales/department.md) canon.

---

## Executive summary

High-performing sales orgs onboard in **four layers** before reps dial:

1. **ICP + named accounts** — who we pursue, who we ignore
2. **CRM + pipeline architecture** — stages, required fields, SLAs
3. **Outbound + inbound playbooks** — sequences, discovery, DM routing
4. **Pipeline ops** — forecast weighting, loss reviews, manager cadence

The #1 failure mode is **CRM before process clarity** (HubSpot Community, RevBlack 2026): teams automate random stage names and reps stop updating records.

---

## SDR/AE onboarding week-by-week (HubSpot Sales pattern)

| Week | Focus | Outputs |
|------|-------|---------|
| 1 | Pipeline + lead object setup | 5–7 deal stages, exit criteria one sentence each |
| 1–2 | Sequences + Sales Workspace | 12-touch outbound, task queue |
| 2 | Workflows | Stage-change notifications, stale-deal tasks, manager alerts |
| 2–3 | Playbook doc | When to create deal, disqualify, log LinkedIn |
| 4+ | Stabilization | Adoption metrics, weekly pipeline review |

---

## S1–S8 mapping (Run Track spine)

### S1 — ICP + Named Accounts
**Agency/ops equivalent:** TAM scoring + top-50 account list  
**Reads from:** M2 avatar, Step 1.5 offer, `MASTER_PRD.md`  
**Outputs:** `docs/run-track/sales/S1-ICP-ACCOUNTS.md`, named account list (50/quarter)  
**Skills:** `icp-definition`, `lead-qualification`  
**Founder today:** Confirm industries to exclude; approve first 20 account names.

### S2 — CRM + Pipeline Setup
**Agency equivalent:** HubSpot Step 2 — CRM structure before records enter  
**Outputs:** `docs/run-track/sales/S2-CRM-PIPELINE.md`, stage definitions, required fields  
**Skills:** `crm-pipeline-setup` (new — reference only, routes to GHL/HubSpot)  
**Best practice:** Max 6–7 stages; each stage = a **decision**, not an activity (HubSpot Community 2026).

**Canonical stages (from sales canon — do not drift):**
New → Engaged → Discovery Booked → Qualified → Evaluation → Negotiation → Verbal → Closed Won/Lost

### S3 — Outbound Playbook
**Equivalent:** 12-touch / 21-day sequence (sales canon)  
**Outputs:** `docs/run-track/sales/S3-OUTBOUND-SEQUENCE.md`, CRM import CSV optional  
**Skills:** `outreach-sequencing`  
**Targets:** 8–15% reply rate cold; rewrite if below 5%.

### S4 — Discovery SOP
**Equivalent:** 30-min MEDDPICC/SPIN call structure  
**Outputs:** `docs/run-track/sales/S4-DISCOVERY-SOP.md`, call script + scorecard  
**Skills:** `discovery`, `lead-qualification`

### S5 — Proposal System
**Equivalent:** Three-tier pricing for deals > $5K ACV  
**Outputs:** `docs/run-track/sales/S5-PROPOSAL-TEMPLATE.md`  
**Skills:** `high-ticket-closing`, `pricing-psychology`, `pricing-strategy`

### S6 — Inbound + DM Routing
**Equivalent:** Keyword comment → DM funnel (creator/service motion)  
**Outputs:** `docs/run-track/sales/S6-INBOUND-DM.md`  
**Skills:** `dm-funnel`, `content-to-client`, `manychat-funnel-strategy`

### S7 — Follow-up System
**Equivalent:** Rule of 7, 5 client types, no-lead-untouched-48h  
**Outputs:** `docs/run-track/sales/S7-FOLLOWUP-CADENCE.md`  
**Skills:** `follow-up-system`

### S8 — Pipeline Ops
**Equivalent:** Forecast weighting + loss analysis (sales canon §7–9)  
**Outputs:** `docs/run-track/sales/S8-PIPELINE-OPS.md`, weekly review template  
**Skills:** sales canon methodology, `objection-handling` for loss patterns

---

## CRM setup best practices (research synthesis)

| Practice | Source | Run Track enforcement |
|----------|--------|----------------------|
| Define lifecycle stages before automation | RevBlack, HubSpot Admin 2026 | S2 gate: written definitions in data dictionary |
| SDR workspace first — minimal fields | SalesHive | S2: SDR view mock in doc |
| Required fields at SQL handoff | RevBlack | S4: qualification checklist |
| No manual lifecycle backward moves | HubSpot Admin 2026 | S2: separate "Re-engagement Status" property |
| Forecast by stage weight | sales canon | S8: weight table in doc |
| Loss review within 48h | sales canon | S8: loss review template |

---

## Tool connections (see TOOL-STACK-MATRIX.md)

| Function | Default tier-2 | Run step |
|----------|----------------|----------|
| CRM | GHL or HubSpot free | S2 |
| Outbound | Instantly / Gmail | S3 |
| Calendar | Google Calendar MCP | S4 |
| DM automation | ManyChat | S6 |
| Voice (v2) | VAPI / LiveKit | Out of S1–S8 v1 |

---

## HITL gates

| Gate | After step | Founder approves |
|------|------------|------------------|
| ICP lock | S1 | Negative ICP list |
| Pipeline stages | S2 | Stage exit criteria |
| Sequence live | S3 | First 20 sends |
| Discovery script | S4 | Qualification thresholds |
| Proposal tiers | S5 | Walk-away price |
| DM keywords | S6 | Keyword + auto-reply |
| Follow-up rules | S7 | 48h SLA |
| Forecast cadence | S8 | Weekly review slot |

---

## References

- [HubLead — HubSpot onboarding checklist for sales](https://www.hublead.io/blog/hubspot-onboarding-checklist)
- [RevBlack — Lifecycle and handoff in HubSpot/Salesforce](https://www.revblack.com/guides/lifecycle-stage-and-lead-management-in-hubspot-and-salesforce)
- [SalesHive — HubSpot vs Salesforce best practices](https://saleshive.com/blog/hubspot-vs-salesforce-best-practices-compared/)
- [HubSpot Community — B2B SaaS pipeline setup](https://community.hubspot.com/t/what-are-best-practices-for-b2b-saas-pipeline-setup-in-hubspot/146602)
