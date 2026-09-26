# Run Track Continuation (post Build Track)

**When this applies:** After **Step 15** is approved — context engine, agent runtime, and observability contract exist.

**Conductor:** `/gtm` is the natural entry after Step 15 — it owns the launch motion and sequences these Run Tracks (see `steps/step-15-observability-contract` § Go-To-Market handoff). This partial defines the walkthrough engine `/gtm` conducts.

**Command:** `@continue --source=run-track` (or `/continue --source=run-track`)

**Engine:** `python3 scripts/run-track-continue.py`

---

## Gate (same as Step 1 → 1.5 pattern)

Do **not** offer Run Track walkthrough until Build Track gate passes:

| Required artifact | Step |
|-------------------|------|
| `AGENTS.md` | 12 |
| `docs/specs/AGENT-RUNTIME.md` | 14 |
| `docs/observability/INSTRUMENTATION-CONTRACT.md` | 15 |

If missing → tell the founder which Build step to finish. Do not skip to `/run-marketing`.

---

## HITL walkthrough order

After gate passes, offer **one department at a time** (founder must say yes):

1. `/run-legal` — L0 entity formation first (LLC/S-Corp advisor)
2. `/run-finance`
3. `/run-marketing`
4. `/run-sales`
5. `/run-growth`
6. `/run-content`
7. `/run-community`
8. `/run-ops`

When a department completes all steps → run `@continue --source=run-track` again for the next offer.

If founder skips a department → `python3 scripts/run-track-continue.py --mark-declined {dept}`

---

## Step 15 final gate copy

After Step 15 approval, **must** run:

```bash
python3 scripts/run-track-continue.py
```

Present the output verbatim. Use AskUserQuestion:

- **Yes** → invoke the suggested `/run-*` command
- **Not yet** → `@dev-loop` or pause
- **Skip** → mark declined and re-run continue script

---

## Orchestrator completion

When an orchestrator finishes **all** steps in its department, Phase E:

1. Congratulate briefly
2. Run `python3 scripts/run-track-continue.py`
3. Present next department offer — do not auto-start without approval

---

## In-progress resume

If founder returns mid-department, `@continue --source=run-track` should resume the **same** `/run-*` orchestrator at the next missing step id in `.sigma/run-track.json`.
