# Research: Marketing Agency Client Onboarding → Run Track M1–M10

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Sources:** Moxo (2025), 5day.io (2025), Scale Growth Digital (2026), Phloz (2026), AgencyPro (2025), DesignRush (2026), US Tech Automations (2026), Exa web search synthesis.

---

## Executive summary

Top-performing marketing agencies follow a **30–90 day onboarding arc**, not a single kickoff call. The pattern repeats across sources:

1. **Pre-kickoff prep** — internal brief, welcome kit, intake forms
2. **Discovery** — goals, KPIs, audience, competitors, approval chains
3. **Strategy sign-off** — 30/60/90 roadmap tied to KPIs
4. **Technical setup** — analytics, pixels, ad accounts, CRM, access checklist
5. **Team + rhythm** — roles, cadence, escalation paths
6. **Quick win** — first measurable deliverable in week 1–2
7. **Reporting loop** — dashboards, review cadence, feedback
8. **Optimization** — weekly metrics, monthly offer/channel revisit
9. **Retention** — lifecycle, community, win-back

Agencies with formal onboarding retain clients **~2.1× longer** (ClientSuccess 2024, cited by Scale Growth Digital).

---

## Universal agency phases (synthesized)

| Agency phase | Typical timeline | Key outputs | Sigma Run step |
|--------------|------------------|-------------|----------------|
| Pre-onboarding / internal prep | Day −7 to 0 | Welcome email, intake form, team assignments | **M1** (partial) |
| Discovery deep-dive | Week 1 | Pain, KPIs, tools, brand, stakeholders | **M1** |
| Strategy presentation | Week 1–2 | 90-day roadmap, channel mix, metrics | **M2** |
| Technical setup | Week 1–2 | GA4/PostHog, pixels, ad accounts, email | **M3** |
| Messaging / brand system | Week 2 | Voice, offer language, creative brief | **M4** |
| Channel architecture | Week 2–3 | Paid + organic plan, budget, exclusions | **M5** |
| Content engine | Week 2–4 | Editorial calendar, pillars, atomization | **M6** |
| Lifecycle email | Week 3–4 | Welcome, nurture, launch sequences | **M7** |
| Launch runbook | Week 3–4 | PLF/ORB phases, owners, exit criteria | **M8** |
| Optimize cadence | Ongoing | Weekly pipeline, A/B tests, CRO | **M9** |
| Retention loop | Month 2+ | Cohorts, community, reactivation | **M10** |

---

## M1–M10 mapping (Run Track spine)

### M1 — GTM Audit
**Agency equivalent:** Discovery + funnel audit + pre-kickoff prep  
**Reads from Build Track:** `MASTER_PRD.md`, Step 1 research, existing analytics if any  
**Outputs:** `docs/run-track/marketing/M1-GTM-AUDIT.md`, funnel map, competitor snapshot  
**Skills:** `01-market-research`  
**Founder today (max 3):** List top 3 competitors; share any existing ad/analytics login you have; confirm primary success metric (e.g. signups, revenue).

### M2 — Avatar + Positioning
**Agency equivalent:** ICP workshop + strategy approval  
**Outputs:** `docs/run-track/marketing/M2-AVATAR-POSITIONING.md`, project overlay update  
**Skills:** `02-customer-avatar`, `icp-definition`  
**Citations:** Blue Ocean + Hormozi value equation (existing canon).

### M3 — Stack + Tracking
**Agency equivalent:** Technical setup (Step 4 in Moxo 8-step framework)  
**Outputs:** `docs/run-track/marketing/M3-STACK-CHECKLIST.md`, `M03.001` PRD if tooling work needed  
**Skills:** `gtm-stack-setup` (new — routes to PostHog, your social scheduler, Meta docs; no API in skill)  
**Agency checklist items:** GA4/PostHog, Meta pixel, Google tag, email provider, CRM connection, UTM convention.

### M4 — Messaging System
**Agency equivalent:** Brand voice + offer language before creative  
**Skills:** `03-brand-voice`, `04-offer-architect`

### M5 — Channel Plan
**Agency equivalent:** 90-day channel roadmap in agency SOWs  
**Skills:** `08-ads-strategy`, `09-retargeting-strategy`

### M6 — Content Engine
**Agency equivalent:** Editorial calendar + first deliverable (Scale Growth #29)  
**Skills:** `12-content-ideation`, `13-content-matrix`  
**Execution:** `/content` department for scripts; M6 owns calendar.

### M7 — Lifecycle Email
**Agency equivalent:** Welcome + nurture sequences (AgencyPro Phase 2)  
**Skills:** `06-email-sequences`, `visual-email-sequences` (global)

### M8 — Launch Runbook
**Agency equivalent:** First campaign launch + quick win (Moxo Step 6)  
**Skills:** `10-launch-playbook`  
**Framework:** Five-phase ORB (existing CMO canon).

### M9 — Optimize Cadence
**Agency equivalent:** Reporting + feedback loop (Moxo Step 7)  
**Skills:** growth department canon, `09-retargeting-strategy`, `16-seo-content`

### M10 — Retention Loop
**Agency equivalent:** Handoff to account management + lifecycle  
**Skills:** `retention-engine`, `17-community-update`

---

## Daily task pattern (founder pain fix)

Agencies assign **one owner per workstream** with visible weekly cadence (Phloz 30-day plan). Run Track copies this:

- Each M-step emits **≤3 founder tasks for "today"**
- Each M-step emits **unlimited agent tasks** (research, drafts, checklists)
- SigmaHQ swimlane: `marketing` tag on all M-PRD cards

---

## HITL gates (non-negotiable)

| Gate | After step | Founder approves |
|------|------------|------------------|
| GTM direction | M1 | Funnel weakest link + metric |
| ICP lock | M2 | One primary avatar |
| Stack connected | M3 | Analytics firing on test event |
| Messaging lock | M4 | Positioning one-liner |
| Channel budget | M5 | Monthly ad/spend ceiling |
| Calendar | M6 | 30-day editorial plan |
| Sequences | M7 | Email copy before send |
| Launch date | M8 | Launch phase owners |
| Metrics cadence | M9 | Weekly review day/time |
| Retention targets | M10 | D7/D30 activation definition |

---

## References

- [Moxo — 8-step marketing client onboarding](https://www.moxo.com/blog/marketing-client-onboarding)
- [5day.io — Step-by-step agency onboarding](https://5day.io/blog/client-onboarding-for-marketing-agencies/)
- [Scale Growth — 34-point checklist](https://scalegrowth.digital/resources/agency/client-onboarding-checklist/)
- [Phloz — 30-day agency plan](https://phloz.com/blog/agency-client-onboarding-checklist)
- [AgencyPro — 30/60/90 playbook](https://agencypro.app/blog/client-onboarding-checklist)
