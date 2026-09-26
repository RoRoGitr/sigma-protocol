# Business Model Modules — Run Track Add-ons

**Version:** 1.0.0  
**Updated:** 2026-06-29  

Universal spine: **M1–M10**, **S1–S8**, and (when triggered) **C1–C8**, **G1–G8**, **Co1–Co6**, **O1–O8**, **Fn1–Fn7**, **L0–L8**. Pick **one primary module** at `/run-marketing` start; optional second module if hybrid.

---

## Content + Growth modules (v2)

| Module | C-track | G-track |
|--------|---------|---------|
| Creator / course | Full C1–C8 | G7 activation + G8 SEO |
| SaaS PLG | C3–C6 lighter | **Required** G1–G7 |
| B2B outbound | C6 LinkedIn heavy | G6 retargeting optional |
| Service | C3 trust content | G5 CRO on booking page |

**Skip rules:** Creator module may skip G8 if no SEO intent. B2B may skip C5 short-form.

---

## Community + Ops modules (v3)

| Module | Co-track | O-track |
|--------|----------|---------|
| SaaS + Discord | Co1–Co6 | O1–O6 minimum |
| B2B (no community) | **Skip Co** | O1–O8 |
| Creator launch | Co2–Co3 after M8 | O3 release gates at launch |

**O8 contractor onboarding:** Skip if solo founder.

---

## Finance + Legal modules (v4)

| Module | Fn-track | L-track |
|--------|----------|---------|
| All monetized | Fn1–Fn6 | L1–L6 minimum |
| Raising capital | Fn7 required | L2–L5 before diligence |
| Enterprise B2B | Fn2 pricing floor | L2 MSA **required** before S5 |
| Solo bootstrap | Fn1–Fn5 | L1, L3 only |

**Spend gate:** Fn6 must complete before M5 paid scale exceeds test budget.

---

## Selection prompt (orchestrator)

At `/run-marketing` Phase A, ask:

1. Primary model: SaaS / B2B outbound / Service / Creator  
2. Secondary module (optional): none / B2B / Creator  
3. Monetization live? (Step 1.5 done → yes)

Write choices to `docs/run-track/BUSINESS-MODEL.json`.

---

## Module: SaaS (self-serve)

**Best for:** B2C/B2B product-led growth, free trial, credit/subscription billing.

| Step | Add-on tasks |
|------|--------------|
| M3 | PostHog activation event; trial signup funnel; Stripe/RevenueCat webhook note |
| M5 | Meta/Google retargeting; skip heavy LinkedIn unless B2B |
| M7 | Trial welcome + activation + upgrade emails |
| M9 | CRO on signup → activation; `/growth` owns tests |
| M10 | Cohort retention, NRR tracking |
| S1 | Score by product-fit signals (stack, company size) |
| S2 | Lighter pipeline — many deals self-serve; SQL = "booked demo" |
| S3 | **Skip or minimal** — optional ABM for enterprise tier |
| S6 | In-app chat / waitlist DM optional |

**Skip if not applicable:** S3 full outbound, S6 ManyChat (unless waitlist funnel).

---

## Module: B2B outbound

**Best for:** Named accounts, demos, $5K+ ACV, sales-led.

| Step | Add-on tasks |
|------|--------------|
| M5 | LinkedIn organic + LinkedIn Ads; case study content |
| M6 | Proof-heavy content (case studies, comparison pages) |
| S1 | **Required** — top 50 named accounts |
| S3 | **Required** — 12-touch sequence |
| S4 | **Required** — MEDDPICC discovery |
| S5 | Three-tier proposals |
| S8 | Weekly forecast with stage weights |

**Skip if not applicable:** M6 short-form volume, S6 keyword DM funnels.

---

## Module: High-ticket service / creator

**Best for:** Coaching, agency, premium service, Sheila Bella motion.

| Step | Add-on tasks |
|------|--------------|
| M5 | Organic-first; paid retargeting only |
| M6 | Content-to-client (85% pre-sale rule) |
| M7 | Application + nurture sequences |
| S5 | Respect Method close, deposit-now |
| S6 | **Required** — keyword comment → DM (`dm-funnel`) |
| S7 | **Required** — rule of 7, no-show recovery |
| S3 | Light — warm outreach only |

**Invoke:** `sales-identity` before first sales call.

---

## Module: Creator / course / launch

**Best for:** PLF, cohort launches, email-list business.

| Step | Add-on tasks |
|------|--------------|
| M7 | **Required** — launch email sequence (Jeff Walker PLF) |
| M8 | **Required** — ORB five-phase launch |
| M6 | YouTube + short-form atomization |
| S6 | DM for high-ticket backend |
| S3 | Skip cold outbound |

---

## Parallel with Build Track

| Build Track artifact | Module uses |
|---------------------|-------------|
| Step 1.5 OFFER_ARCHITECTURE | All modules — pricing, funnel type |
| Step 9 landing | SaaS, Creator — conversion path |
| Step 11 F-PRDs | SaaS — ship while M3–M6 run |
