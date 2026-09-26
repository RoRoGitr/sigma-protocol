# Sigma Lite — your first win in under 10 minutes

Sigma's full power is the Step 0-15 gated methodology. **You don't need it to feel the point.**
Sigma Lite is the fast taste: one idea → a real spec → **watch a quality gate evaluate the AI's
output deterministically.** That last part is the "aha" — it's the thing no other AI workflow does.

This is NOT the methodology (that's [GETTING-STARTED.md](../GETTING-STARTED.md)). It's a 10-minute
on-ramp. Three commands.

> Prereq: Claude Code (or Codex / Cursor) + this repo cloned. One-time install:
> `bash scripts/install-claude-code.sh` (idempotent — wires the gates, runs a fail-open smoke test).

---

## Step 1 · Idea → spec (~3 min)

Pick a real idea. Run:

```bash
claude "/step-1-ideation a habit-tracker for developers that gamifies shipping"
```

You get `MASTER_PRD.md` — but framed through the **Hormozi value equation**
(dream outcome × likelihood ÷ time × effort), not a generic feature list. The step pauses at a
**HITL checkpoint** — you approve or redirect. (You're the taste; the AI is the speed.)

## Step 2 · Watch a gate evaluate it (~2 min) — the "aha"

```bash
claude "/step-verify step 1"
```

This is the moment. A **deterministic Stop-hook** reads the step's output and scores it against
machine-checkable assertions — required sections present, minimum substance, no banned markers, the
craft/anti-slop checks — and reports **PASS / FAIL with the specific reasons**. It is not a model
grading its own work; it's a check the model cannot talk its way past.

If your idea was thin, you'll see it **flag** the gaps. Fix, re-run, watch it go green. That loop —
*the gate decides, not the vibe* — is Sigma in one screen.

## Step 3 · Spec → machine-executable backlog (~4 min, optional)

```bash
claude "/step-11-prd-generation"     # turn the idea into an implementation PRD
claude "/prd-json --mode implementation"   # → .sigma/backlogs/implementation/prd.json
```

Now you have a structured, gated backlog an agent swarm can execute — with acceptance criteria the
verification gates check, not just prose.

---

## What you just saw

- AI output got **evaluated by a gate**, deterministically, before it counted as done.
- The methodology gates **the part before code** — ideation and spec — where the expensive mistakes
  actually start.
- You stayed in control at the **HITL checkpoint** — Sigma speeds you up without taking the wheel.

## Honest scope

- This skipped most of the 18 steps (0–15 + 1.5/11.5). The full path (architecture → UX → wireframes → design-system →
  interface-states → technical-spec → … ) adds the design **craft gate** (deterministic anti-slop) and
  cross-model review — the parts that catch "looks finished but isn't."
- The gates are **advisory-first** today (they report; they flip to blocking once calibrated), so Lite
  won't hard-stop you. That's intentional for a first run.

## Next

- Full walkthrough → [GETTING-STARTED.md](../GETTING-STARTED.md)
- Command reference → [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- Why Sigma vs the field → [POSITIONING.md](POSITIONING.md)
