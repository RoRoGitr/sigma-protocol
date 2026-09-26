# Run Track — How to Use (Plain English)

## Step counts by department

| Dept | Command | Steps | IDs |
|------|---------|------:|-----|
| Marketing | `/run-marketing` | 10 | M1–M10 |
| Sales | `/run-sales` | 8 | S1–S8 |
| Content | `/run-content` | 8 | C1–C8 |
| Growth | `/run-growth` | 8 | G1–G8 |
| Community | `/run-community` | 6 | Co1–Co6 |
| Ops | `/run-ops` | 8 | O1–O8 |
| Finance | `/run-finance` | 7 | Fn1–Fn7 |
| Legal | `/run-legal` | 9 | **L0–L8** (L0 = LLC/S-Corp formation) |

**Total:** 64 numbered steps + 8 orchestrators (`/run-marketing` … `/run-legal`).

---

## Recommended order (not automatic)

Run Track does **not** auto-fire the next department when a Build step finishes. Triggers in `.sigma/run-track.json` are **hints** for humans and orchestrators.

```text
Build: Step 1 (idea) ──────────────────────────────┐
         Step 1.5 (pricing) ────┐                   │
                                ▼                   ▼
Legal L0–L8 ◄── after Step 1    Finance Fn1–Fn7 ◄── after Step 1.5
                                │
Marketing M1–M10 ◄── after Step 1 or 11
    ├── Growth G1–G8 ◄── after M3 (analytics)
    ├── Sales S1–S8 ◄── after M2
    ├── Content C1–C8 ◄── after M6 (calendar)
    └── Community Co1–Co6 ◄── after M2 or M8
Ops O1–O8 ◄── after Step 11 or first @dev-loop sprint
Build: @dev-loop (F-PRDs) ◄── parallel throughout
```

---

## How a session works

1. Finish **Build Track Step 15** (brain + observability contract).
2. Run **`@continue --source=run-track`** — same HITL pattern as Step 1 → 1.5.
3. Say **yes** to start **`/run-legal`** (L0 = LLC/S-Corp advisor) → then Finance → Marketing → Sales → …
4. After each **department** completes, run `@continue --source=run-track` again for the next offer.
5. Within a department, re-run the same `/run-*` orchestrator to resume the next step.

**Engine:** `python3 scripts/run-track-continue.py`

**Not automatic:** Build steps do not chain into Run Track without `@continue --source=run-track` or Step 15 handoff.

---

## Build Track departments (no `/run-*`)

| Dept | Use | Command |
|------|-----|---------|
| Product | PRDs, roadmap | `step-1`, `step-10`, `step-11` |
| Design | UX, wireframes, tokens | `step-3`–`step-7`, `step-9` |
| Engineering | Architecture, code, ship | `step-2`, `step-8`, `step-14`, `@dev-loop` |

---

## Gate-only departments (no numbered Run Track)

| Dept | Use |
|------|-----|
| QA | `/qa`, `@gap-analysis`, 8-gate pipeline |
| Security | `/security` reviews |
| Trading | `/trading` |

---

## Entity formation (LLC / S-Corp)

**Role:** *Corporate Formation Counsel* (under General Counsel / Legal).

**Run Track step:** **L0** — `/run-l-0-entity-formation`  
**Atom skill:** `entity-formation-setup` (checklist: entity type, state, EIN, registered agent — not legal advice).

Run **before or with L1** when you have not formed the company yet.
