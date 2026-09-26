# Research: Entity Formation (LLC / S-Corp / C-Corp) → Run Track L0

**Version:** 1.0.0  
**Updated:** 2026-06-30  
**Role:** *Corporate Formation Counsel* (General Counsel department — educational checklist, **not legal advice**)  
**Sources:** IRS entity guidance, SBA business structure overview, YC startup legal primers, Clerky/Stripe Atlas founder docs, state secretary-of-state filing patterns (synthesized).

---

## Executive summary

Most solo and small-team software founders choose between **LLC** and **S-Corp (often LLC taxed as S-Corp)** in year one. **C-Corp** is the default path if you plan **VC equity rounds** soon. The wrong choice is usually fixable later — but **re-filing, new EIN workflows, and investor cleanup** cost time and lawyer fees.

**L0 output:** a one-page decision in plain English + filing checklist for the founder's state.

---

## Decision matrix (by product model)

| Your situation | Usually start with | Why |
|----------------|-------------------|-----|
| Solo founder, services or info product, no investors yet | **Single-member LLC** (home state or DE/WY if advised) | Simple, flexible, pass-through taxes, low admin |
| Profitable solo/consulting, paying self >$60–80k/yr from the business | **LLC + S-Corp election** (Form 2553) | Reduce self-employment tax on distributions (CPA required) |
| SaaS with co-founders, no VC for 12+ months | **Multi-member LLC** or **C-Corp** if equity split is complex | LLC = flexible; C-Corp if you want standard stock/options now |
| Raising priced VC / SAFE stack with counsel | **Delaware C-Corp** | Investors and counsel expect it; QSBS potential |
| Mobile app / consumer subscription, bootstrapped | **LLC** until revenue justifies S-Corp election | Don't over-corporate before product-market fit |
| Agency selling high-ticket B2B | **LLC** early; S-Corp when net profit stable | Liability shield + eventual tax optimization |
| Side project, no revenue, testing idea | **Wait** or LLC only if liability exposure (marketplace, health, fintech) | Formation has annual fees; don't form "just because" |

**Read from Build Track:** `docs/specs/MASTER_PRD.md` (revenue model), Step 1.5 pricing, co-founder count, planned fundraise.

---

## Entity types (sixth-grade version)

### LLC (Limited Liability Company)
- **What it is:** A legal wrapper that separates *your* money from the *business* money for lawsuits and debts.
- **Taxes:** By default "pass-through" — profits hit your personal return (Schedule C or partnership return).
- **Good for:** Most bootstrapped founders, agencies, early SaaS.
- **Downside:** Investors rarely invest directly into LLCs; self-employment tax on all LLC profits unless S-Corp strategy.

### S-Corp (tax status, not a separate "thing" you incorporate)
- **What it is:** A **tax election** (IRS Form 2553) — often an LLC or corporation that elects S-Corp treatment.
- **Taxes:** Pay yourself a **reasonable W-2 salary**; take extra profit as **distributions** (often lower SE tax on distributions — CPA models this).
- **Good for:** Profitable businesses with steady net income.
- **Downside:** Payroll compliance, stricter IRS scrutiny on "reasonable salary," not ideal with multiple investor classes.

### C-Corp
- **What it is:** The classic "Inc." company with stock.
- **Taxes:** Company pays corporate tax; you pay tax again on salary/dividends (double taxation) — often acceptable when optimizing for **growth + investment**, not distributions.
- **Good for:** VC-backed startups, large equity pools, acquirers who want clean cap tables.
- **Downside:** More admin, Delaware franchise tax, need cap table tool + counsel early.

---

## State of formation

| Choice | When |
|--------|------|
| **Home state** | Default for bootstrapped LLCs — simplest, one state to file |
| **Delaware** | C-Corp for VC; some LLCs for legal familiarity |
| **Wyoming/Nevada** | Rarely needed for software startups; hype > benefit for most |

If you form in DE but operate elsewhere, you usually **foreign qualify** in your home state → extra fees. Ask counsel if multi-state.

---

## Filing checklist (L0 artifact sections)

1. **Chosen entity + state** — one sentence why
2. **Registered agent** — name + annual cost
3. **Articles of organization / incorporation** — filed or scheduled date
4. **EIN** — IRS (free); after formation
5. **Operating agreement / bylaws + cap table stub** — even solo LLCs benefit from OA
6. **Business bank account** — separate from personal (required for clean books)
7. **BOI report** (FinCEN beneficial ownership) — if applicable to your formation date/rules
8. **S-Corp election deadline note** — if LLC: Form 2553 within **75 days** of formation or tax year start if considering S-Corp
9. **CPA handoff** — `/run-finance` Fn1 for unit economics + tax posture

---

## Project-specific prompts (agent asks founder)

1. Solo or co-founders? Equity split documented?
2. Revenue in next 12 months — none / <$100k / $100k+?
3. VC fundraise in next 18 months?
4. Liability exposure (user data, health, money movement, marketplace)?
5. Home state and where you operate?

---

## Run step mapping

| L0 section | Skill |
|------------|-------|
| Decision matrix | `entity-formation-setup` |
| Filing checklist | `entity-formation-setup` |
| Escalation to counsel | `/legal` for redlines; licensed attorney for filings |

**Next step after L0:** L1 Intake + BATNA (`/run-l-1-intake-batna`)

---

## Disclaimer

Sigma Run Track produces **education and checklists**. It is **not** a law firm. Founders must confirm filings with a licensed attorney and tax choices with a CPA.
