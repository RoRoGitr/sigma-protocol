---
name: entity-formation-setup
description: "Run Track atom skill — checklist and routing only; does NOT call APIs."
department: legal
---

# entity-formation-setup

**Corporate Formation Counsel** — educational advisor for Run Track **L0** (not legal advice).

## Required reading

1. `docs/run-track/RESEARCH-ENTITY-FORMATION.md` — decision matrix + filing checklist
2. `docs/specs/MASTER_PRD.md` — revenue model, co-founders, liability
3. Step 1.5 outputs if present (`docs/specs/OFFER_ARCHITECTURE.md`, pricing)

## Session flow

### 1. Interview (≤5 questions)

Ask founder: solo vs co-founders, 12-month revenue band, VC plan, liability exposure, home state.

### 2. Recommend ONE primary path

Use the matrix in RESEARCH-ENTITY-FORMATION.md. Explain in **sixth-grade English**:

- **LLC** — simple shield, pass-through tax
- **LLC + S-Corp election** — when profitable enough that CPA tax savings beat payroll admin
- **C-Corp (often DE)** — VC / standard equity

State **why for this project**, not generic pros/cons.

### 3. Write artifact

`docs/run-track/legal/L0-ENTITY-FORMATION.md` with sections:

- What we picked and why (2–3 short paragraphs)
- Your tasks today (≤3): e.g. pick registered agent, file articles, schedule CPA call
- Filing checklist (from research doc)
- What **not** to DIY (investor docs, multi-state, S-Corp salary modeling)

### 4. Escalation

- Tax / S-Corp / runway → `/run-finance` Fn1
- Contract templates → L2+ `/run-legal`
- Licensed filings → external attorney

## Triggers

`llc`, `s-corp`, `incorporate`, `ein`, `entity formation`, `/run-l-0`
