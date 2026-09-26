# Research: Growth Team Ops Onboarding → Run Track G1–G8

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Sources:** PostHog experimentation docs (2025), Reforge growth loops, Brian Balfour growth model, Exa synthesis on startup growth team onboarding, CXL CRO playbooks.

---

## Executive summary

Growth teams that ship learnings (not just dashboards) follow: **instrument → baseline → hypothesize → test → CRO → retarget → cohorts → SEO loop**. Teams without a named **weakest funnel step** waste 60%+ of experiment cycles (Reforge internal benchmark, cited in growth onboarding literature).

Sigma **G-track** owns **CRO and experiment execution**. Marketing **M9** owns **review cadence only** — not test specs or landing changes.

---

## Universal growth ops phases

| Phase | Key outputs | Run step |
|-------|-------------|----------|
| Funnel map + events | Stage names, PostHog/GA4 events | **G1** |
| Baseline metrics | Conversion rates, weakest step | **G2** |
| Hypothesis backlog | ICE-scored test list | **G3** |
| A/B test spec | Hypothesis, metric, duration | **G4** |
| CRO sprint | Landing/signup changes | **G5** |
| Retargeting architecture | Audience tiers | **G6** |
| Activation + cohorts | Activation event, retention triggers | **G7** |
| SEO + organic loop | Keywords tied to M6 calendar | **G8** |

---

## G1–G8 mapping

### G1 — Funnel Map + Events
**Reads:** M3 stack, M1 audit  
**Skills:** `funnel-instrumentation-setup` (new atom skill)  
**Founder today:** Approve event names list.

### G2 — Baseline Metrics
**Skills:** `funnel-instrumentation-setup`  
**Founder today:** Confirm weakest-link metric.

### G3 — Hypothesis Backlog
**Skills:** `ab-test-spec`  
**Founder today:** Approve top 3 tests for this month.

### G4 — A/B Test Spec Pack
**Skills:** `ab-test-spec`  
**Routes to:** PostHog experiments, feature flags

### G5 — CRO Sprint
**Reads:** G4, Step 9 landing page  
**Skills:** `ab-test-spec`  
**Founder today:** Approve copy/layout change for active test.

### G6 — Retargeting Architecture
**Reads:** M5 channel plan, G2 baseline  
**Skills:** `09-retargeting-strategy`

### G7 — Activation + Cohorts
**Skills:** `retention-engine`, `06-email-sequences`  
**Founder today:** Lock activation event definition.

### G8 — SEO + Organic Loop
**Reads:** M6 calendar, G2 baseline  
**Skills:** `16-seo-content`

---

## Trigger

Start `/run-growth` after **M3** (analytics connected) — can run parallel with M4–M6.

---

## Tool stack

| Tool | G-step | MCP/CLI |
|------|--------|---------|
| PostHog | G1–G5 | Docs + project API via founder login |
| GA4 | G1–G2 | gtm-stack-setup checklist |
| Meta Ads | G6 | `/ads` for execution |

---

## M9 boundary (doc-only)

M9 **Optimize Cadence** = when you review metrics weekly.  
G3–G5 = what you change and how you measure it.

---

## Citations

- PostHog — Experimentation best practices (2025)
- Reforge — Growth loops and activation metrics
- CXL — CRO sprint methodology
