---
name: self-healing-loop
description: 'Audit a user''s system + AI-CLI harness for recurring failures and build them a self-healing loop — one that detects a failure, diagnoses the repeating pattern, proposes a fix, REGRESSION-TESTS the proposal, then applies it (auto only for proven-safe classes, human-gated for everything risky). Built for skeptics: self-healing is a bounded loop with an external gate, not magic. Triggers on "self-healing loop", "self-healing harness", "make my system self-heal", "build a self-healing loop", "auto-remediation", "agents that fix themselves", "self-repairing agents", "comment HEAL".'
---

# Self-Healing Loop

Build a system that fixes its own recurring failures — without becoming a system that "fixes" itself into garbage. The difference is entirely in the gate.

> The frontier name for this is **Self-Harness** (mine your own failure modes → propose a harness change → regression-test it → accept). The skeptic's fear — "an AI editing itself unsupervised" — is the failure mode this skill is *designed to prevent*, not enable.

## For the skeptic (read this first)

If you have engineers who don't believe in self-healing loops, they're right about the dangerous version and wrong that it's the only version. Be precise:

- A self-healing loop is **not** "the AI rewrites itself whenever it feels like it."
- It **is**: detect a *repeating* failure → diagnose the pattern → propose a narrow fix → **prove the fix doesn't break anything (regression test)** → apply it only if it's a pre-approved safe class, otherwise hand a human a one-tap approve.
- It's an on-call engineer that never sleeps and never ships an unproven change. The human still signs the risky ones — they just sign something already proven green.

## The one law (never violate)

**No fix is applied until it's been regression-tested, and no risky fix is applied without a human.** A proposal the loop can't prove safe is escalated, not shipped. If you can't write the test that proves the fix, the fix stays a proposal.

## Hard boundaries (non-negotiable)
- **Never auto-heal money, trades, payments, deletions, or destructive ops.** These are always human-gated, full stop.
- **Circuit breaker.** If the same thing fails N times in a window (e.g. 3 in 5 min), STOP and escalate — a crash-loop is not a healing opportunity, it's an alarm.
- **Fail-closed.** Unknown failure class → escalate to a human, never "try a fix and see."

## Procedure

### Phase 0 — Orient
Find where failures are recorded. Check what exists (skip what's absent):
- Logs: app logs, CI logs, crash logs, configured session/sprint history, and error trackers (Sentry). Inspect only stores that exist in the current runtime.
- Health: existing monitors, healthchecks, uptime data, test-run history.
- The harness: hooks, gates, the test suite (the regression oracle you'll need).
State in one line what failure signal they actually have.

### Phase 1 — Mine the recurring failures
Read the failure record and cluster by **signature** (error type + location + message shape), newest first. You're looking for the *repeats* — a one-off isn't a healing candidate; the same failure 3+ times is. Output a ranked list: *signature · count · last-seen · is-it-machine-diagnosable*.

### Phase 2 — Classify each cluster
- **Transient** (restart/retry fixes it: a flaky network call, a dead worker) → candidate for **auto-restart** with a circuit breaker.
- **Systematic** (a real bug: same assertion fails) → candidate for a **proposed code/config fix**, regression-tested, human-gated.
- **Config/drift** (a stale path, a changed key) → **proposed config fix**, gated.
- **Unknown / money / destructive** → **escalate only**, never auto-heal.

### Phase 3 — Design the healing loop
For each healable cluster, specify:
- **Detect**: the signal that fires it (log pattern, exit code, failing test, health probe).
- **Diagnose**: how it identifies the pattern (signature match against the cluster).
- **Propose**: the narrow fix (restart / patch / config change) — one change, not a rewrite.
- **Verify (the keystone)**: the regression test the proposal must pass *before* anything is applied. No oracle → it's a proposal, not a fix.
- **Apply**: auto **only** for the pre-approved safe class (e.g. restart a dead non-critical worker); everything else → write a one-tap human approval.
- **Bound**: circuit breaker (N fails / window → stop), max proposals per run, dedup window so it doesn't re-propose the same fix.
- **Record**: every detect/propose/apply to a trace the loop can learn from next time (the hill-climbing input).

### Phase 4 — Interview (autonomy slider — use AskUserQuestion)
1. **Which failure class first?** (highest-count, machine-diagnosable from Phase 1)
2. **Autonomy level?** *Alert-only* (just tell me) · *Propose* (draft the fix, I approve) · *Auto-safe* (auto-apply the proven-safe class, escalate the rest).
3. **What's off-limits?** Confirm the hard boundaries for their system (anything touching money/customers/prod data stays human-gated).

### Phase 5 — Scaffold
Generate:
- A **watcher/supervisor** that detects + restarts the safe class with a circuit breaker.
- A **meta-loop** that mines the failure record, clusters, regression-tests proposals, and queues the human-gated ones.
- A **HEALING.md** registry: each healing rule · its trigger · its gate · auto-or-human.
End with a **PASS/MISS** line per rule: detect wired? regression oracle defined? gate set? boundary respected?

## Rule template

For each rule, record: failure signature; evidence source; classification; proposed change; regression oracle; approval boundary; circuit-breaker threshold; and trace location. Keep this template in the project that owns the healing loop.

## Anti-slop
- No fix applied without a passing regression test. Paste the test result.
- Never auto-heal money/trades/deletions. If unsure whether something is destructive, it's human-gated.
- A crash-loop is an alarm, not a healing opportunity — circuit-break and escalate.
- If you can't write the oracle that proves the fix, say so and keep it a proposal.
