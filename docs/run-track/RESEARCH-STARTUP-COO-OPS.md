# Research: Startup COO / Ops Onboarding → Run Track O1–O8

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Sources:** High Output Management (Grove), Stripe Press ops essays, YC startup ops checklists, Exa synthesis on first COO 90-day plans, Sigma 8-gate pipeline canon.

---

## Executive summary

Early-stage ops is not bureaucracy — it is **rhythm + gates + visibility**. The COO function at seed/Series A covers: task source of truth, sprint cadence, release gates, observability minimum, incidents, weekly business review, vendor/SOP registry, contractor access.

Sigma **O-track coordinates `@dev-loop` and `@ship-*`** — it does not replace implementation.

---

## Universal startup ops phases

| Phase | Outputs | Run step |
|-------|---------|----------|
| Ops baseline | Tools, kanban path, gaps | **O1** |
| Sprint rhythm | Standup, groom, sprint length | **O2** |
| Release + QA gates | 8-gate checklist | **O3** |
| Observability minimum | Logs, alerts, Sentry | **O4** |
| Incident response | Severity, comms, commander | **O5** |
| Weekly business review | WBR agenda + metrics | **O6** |
| SOP + vendors | Registry, renewals | **O7** |
| Contractor onboarding | Access, NDA, offboard | **O8** |

---

## O1–O8 mapping

### O1 — Ops Baseline Audit
**Skills:** `system-health`, `doctor-fix`  
**Founder today:** Confirm the Linear project mapping (linear.project in runtime-baseline.json).

### O2 — Sprint + Backlog Rhythm
**Reads:** `.sigma/backlogs/implementation/prd.json`  
**Skills:** `sprint-plan`, `backlog-groom`, `daily-standup`

### O3 — Release + QA Gates
**Skills:** `qa-plan`, `release-review`, `quality-gates`  
**Note:** Mandatory devils-advocate + QA on every sprint (Sigma canon).

### O4 — Observability Minimum
**Reads:** M3 stack  
**Skills:** `observability`, `system-health`

### O5 — Incident Response
**Skills:** `maintenance-plan`, `doctor-fix`  
**Handoff to Legal L7** for breach narratives.

### O6 — Weekly Business Review
**Reads:** S8 pipeline, G2 baseline  
**Skills:** `weekly-review`

### O7 — SOP + Vendor Registry
**Skills:** `maintenance-plan`

### O8 — Contractor Onboarding (optional module)
**Reads:** L2 MSA baseline  
**Skip if:** solo founder, no contractors.

---

## Trigger

After **Step 11** PRDs approved OR first **`@dev-loop`** sprint — whichever comes first.

---

## Build Track boundary

| O-track owns | Build Track owns |
|--------------|------------------|
| When to release | Writing feature code |
| Gate checklist | PRD implementation |
| WBR cadence | Architecture decisions |

---

## Citations

- Andy Grove — High Output Management (meeting cadence, OKRs)
- Sigma Protocol — 8-gate pipeline (Anti-Slop → Greptile)
