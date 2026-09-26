# Sigma Protocol — Positioning

> Most AI-dev methodologies gate on *"did the spec get built / do the tests pass?"*
> Sigma also gates on **"is it any good?"** — deterministically, before every commit, on any LLM CLI.

This is the one-pager for "Sigma vs Kiro / Spec Kit / BMAD / Tessl / Claude-Code-native." It's
honest about what Sigma is *not* — read the last section before you decide.

---

## The category problem

Spec-driven development (Kiro, GitHub Spec Kit, Tessl) fixed *"the AI built the wrong thing"* by
gating on a spec and tests. That's real progress. But it leaves a second failure mode untouched:
**the AI builds the right thing, badly.** Developers *believe* AI makes them ~20% faster; a
controlled 2026 study (METR) measured them **19% slower** — the delta is invisible quality debt:
code and UI that *look* finished but aren't. Left to itself, AI averages toward the median — the same
Inter font, the same AI-purple, the same three-equal-cards, the same "Get Started" hero, the same
plausible-but-wrong code a single model grades as correct.

A spec gate and a passing test suite do not catch median convergence or a model rubber-stamping its
own work. **That gap is the thing Sigma gates.**

---

## What Sigma adds (the three differentiators)

1. **A gate on craft, not just completion.** A deterministic Stop-hook *fails* a design step whose
   output carries generic AI tells (default Inter/Roboto, the AI-purple hex band, `1fr 1fr 1fr`
   cards, "Get Started"/"Trusted by" filler) and requires a divergence-protocol proof — fresh
   references → named directions → **you** pick — before it proceeds. The model cannot grade its way
   past it because the check is deterministic, not a self-score.
2. **A second model reviews the first.** Cross-model review (e.g. Codex reviewing Claude's code) is
   wired into the pipeline; a cross-family judge tier scores quality with an injection-defended,
   evidence-quote-required rubric. A single AI grading its own work is a single point of failure;
   Sigma removes it.
3. **It gates the part nothing else covers — steps 1–10.** Every spec-driven tool starts at code.
   Sigma runs gated ideation, offer architecture, UX, flow-tree, wireframes, design-system, interface
   states, technical spec, landing page, and feature breakdown *before* a line is written — each with
   its own verification.

…and it does all of this **portably**: the same methodology + gates run across Claude Code, Codex, and
any supported CLI (one `/sigma-dispatch` → the CLI's native `/goal`), not locked to one
tool's plan mode.

---

## Head-to-head

| You've used… | Its strength | What Sigma adds |
|---|---|---|
| **AWS Kiro** | spec → design → tasks, IDE-integrated; gate on the spec | a **craft gate** + cross-model review *after* the spec, + the pre-code steps (ideation/UX/offer), + multi-CLI portability |
| **GitHub Spec Kit** | open spec-driven scaffold (`/specify`→`/plan`→`/tasks`) | the **enforcement layer** — deterministic anti-slop + judge gates, not just a spec workflow |
| **Tessl** | spec-as-source-of-truth, spec registry | gates on **output quality + craft**, not only spec fidelity; covers design steps Tessl doesn't |
| **BMAD / agent crews** | a flat team of agent roles (PM, architect, dev) | an **invocable 13-department C-suite** with skill-cascade auto-routing + the gate pipeline on top |
| **Claude Code / Cursor native** | one tool's subagents / plan mode | the **same methodology + gates across Claude Code, Codex, and Droid**, plus the Step 0-15 pre-code spine |
| **Devin / autonomous agents** | end-to-end autonomy | mandatory **HITL taste-gates** + deterministic quality checks — autonomy with a quality floor, not in place of one |

Respectful framing: each of these is good at what it does. Sigma is **complementary** to spec-first
tools — it's the quality-enforcement layer you add *on top of* "did it get built."

---

## The proof (real artifacts, not claims)

- **Cross-model review caught real bugs in Sigma's own code.** Building the fusion primitive, a
  cross-model gap-analysis (Codex reviewing Claude's gate scripts) found **6 HIGH-severity
  secret-leak / opt-in defects across four review passes** that the unit tests passed over — fixed
  before merge (fixes in commits `c6f772b` / `8257273`; the raw cross-model audit log is a runtime
  artifact under `.sigma/confidence/`, not committed).
- **The craft gate fails generic output deterministically** — see `references/award-standard.md` +
  the `craft_antislop` / `divergence_proof` assertions in `.claude/hooks/step-verify-gate.cjs`.
- **A live E2E run caught a latent bug a stub had hidden** — the discipline ("stub-passing ≠
  live-working") surfaced a real stdin-delivery defect in the primitive.

---

## Honest status (read this)

- The **deterministic gates are live, advisory-first** — they report + log every firing now, and flip
  to **blocking** once a canary shows clean fires (≤5% false-positive over ≥10 runs).
- The **cross-family judge tier is wired (advisory)**; it flips to blocking only after calibration
  (balanced-accuracy ≥0.85, true-negative-rate ≥0.80, n≥40 labeled examples, cross-family). Until
  then it informs, it doesn't block.
- **HITL checkpoints are mandatory by design** — you make the creative calls; the gates create the
  *conditions* for higher quality, they don't guarantee it.
- **Distribution:** source-available. It runs on the AI CLIs you already pay for — no separate
  SaaS to host.

---

## When Sigma is NOT the right tool

- **A throwaway script or a quick spike.** The Step 0-15 spine is overhead you don't need; use the
  CLI directly.
- **You want full autonomy with no human in the loop.** Sigma's HITL taste-gates are deliberate and
  non-negotiable — that's the point, not a limitation to remove.
- **You only care about "does it run."** If craft, design quality, and cross-model verification aren't
  problems you have, a spec-first tool alone is lighter.
- **You're not on a supported CLI** (Claude Code / Codex / Cursor).

If those describe you, use the lighter tool — and come back when "looks finished but isn't" starts
costing you.
