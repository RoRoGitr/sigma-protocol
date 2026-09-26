# Research: Startup CFO / Finance Ops → Run Track Fn1–Fn7

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Sources:** a16z startup finance guides, SaaS Capital benchmarks, Hormozi unit economics canon, Exa synthesis on first CFO finance stack for seed startups.

---

## Executive summary

Finance ops for early-stage companies sequences: **unit economics → pricing architecture → forecast → cost audit → runway → spend gates → data room (if raising)**. Without spend gates, marketing scale outruns runway silently.

Sigma uses **`Fn` prefix** for Finance Run PRDs — never `F` (Build Track feature PRDs).

---

## Universal finance ops phases

| Phase | Outputs | Run step |
|-------|---------|----------|
| Unit economics | CAC, LTV, margin baseline | **Fn1** |
| Pricing architecture | Tiers, anchors, floor | **Fn2** |
| 3-scenario forecast | Base/upside/downside | **Fn3** |
| Monthly cost audit | Cloud, tools, burn | **Fn4** |
| Runway + triggers | Months left, cut/hire rules | **Fn5** |
| Spend approval gates | Who approves what | **Fn6** |
| Fundraise data room | Investor metrics pack | **Fn7** (conditional) |

---

## Fn1–Fn7 mapping

### Fn1 — Unit Economics Baseline
**Skills:** `cost-optimizer`  
**Reads:** MASTER_PRD, M1 audit  
**Founder today:** Confirm gross margin assumption.

### Fn2 — Pricing Architecture
**Skills:** `04-offer-architect`, `pricing-psychology`  
**Reads:** Fn1, M4 messaging  
**Founder today:** Approve published price points.

### Fn3 — 3-Scenario Forecast
**Skills:** `estimation-engine`  
**Reads:** Fn2, S8 pipeline

### Fn4 — Monthly Cost Audit
**Skills:** `cost-optimizer`  
**Cadence:** Monthly review calendar.

### Fn5 — Runway + Triggers
**Document:** Cut/hire/pause-ad thresholds.

### Fn6 — Spend Approval Gates
**Reads:** Fn5, M5 channel plan  
**Founder today:** Approve ad budget ceiling.

### Fn7 — Fundraise Data Room
**Conditional:** Skip if not raising.  
**Reads:** Fn3 forecast, Fn5 runway.

---

## Trigger

After **Step 1.5** (offer architecture) — before scaling paid spend (M5/Fn6 gate).

---

## Sales / marketing handoffs

| From | To Fn |
|------|-------|
| S8 pipeline forecast | Fn3 revenue inputs |
| M5 ad budget | Fn6 spend gate |
| S5 proposals | Fn2 pricing floor |

---

## Citations

- SaaS Capital — Benchmarking reports
- Hormozi — CAC/LTV stall predictor (finance-director canon)
