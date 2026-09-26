# Execution Loops — the standing loops that run your build (Orca-native)

> Part of **Step 14 (Agent Runtime Bootstrap)**. `@dev-loop` fires PRDs; THESE loops are how the coordinator seat actually runs the floor between "PRD dispatched" and "PR merged" — benched and locked 2026-07-11 against real production sessions (each rule below was bought with a real failure or saved by a real catch). Students run these through the **Orca CLI**; every command shown is real.

## The composed picture

```
ORCHESTRATOR TICK (L2, on TIMER L3)
 └─ per task: BUILD LOOP (L1)
     ├─ quality: GAP-ANALYSIS rounds → PR → PR-SWEEP habits (L4)
     └─ close-out: CLEANUP (L5, ownership ledger)
 └─ session end: settle-up / handoff
```

## L1 — BUILD LOOP (per task)

```
0.  BASE CHECK: git fetch origin dev — confirm the file you're about to edit
    matches origin/dev. Build in a dev-based worktree, NEVER a stale or
    server-serving checkout.
      orca worktree create --name <task-slug> --agent codex --prompt "<brief>"
    (Bought: a fix was nearly shipped from a checkout 301 commits behind dev —
     it would have silently reverted newer work.)
0.5 IS THE TASK STILL REAL? Verify the gap exists on dev (grep the code, run
    its tests) BEFORE building. Stale boards lie; tests don't.
    (Bought: two "open" issues were already fully built + tested — this check
     saved two duplicate builds in one afternoon.)
1.  DISPATCH with a written contract: brief + done_when + exact verify command
    + never-touch list. Record the seat in the ownership ledger (L5) WITH an
    expected-artifact path + cadence (feeds L2's heartbeat).
      orca orchestration task-create / orchestration dispatch
2.  worker_done arrives → GAP-CHECK: the coordinator re-runs the tests ITSELF
    and diffs the work against the brief. Worker evidence is an input to the
    judge, never the judge.
3.  PR → review gate: **bot code review (e.g. Greptile) + cross-model review +
    coordinator**. Bench your bots: count who actually posts reviews on your
    last 10 PRs — a green check with no review behind it is a false gate.
    Every P1/P2 gets fixed or refuted-with-proof, replied, resolved.
4.  MERGE at the bar → CLOSE-OUT (L5) → REFILL the freed seat with the next task.
EXIT: merged + cleaned. ANTI-STALL is a CLOCK, not a tick-count: no task sits blocked > **30 min** without being reassigned, escalated, or carrying a written blocker note naming exactly what it waits on.
```

## L2 — ORCHESTRATOR TICK (the heartbeat)

Each tick, in order:
1. **SWEEP BY ARTIFACTS FIRST, screens second.** Judge every seat by its git
   log / output files, not its terminal screen (screens repaint garbage; git
   doesn't lie). `orca worktree ps` + the ledger's expected-artifact cadence:
   any seat whose newest artifact is older than its cadence = flagged (default cadence: **20 min** — tight; the flag is a CHECK, never an auto-kill; long backtests will trip it and that's fine). Mechanical, not vibes.
2. **UNSTICK** wedged seats: a pasted-but-unfired brief needs a bare Enter
   (`orca terminal send --terminal <h> --enter`); "sent" ≠ "started" — read the
   screen until it shows Working. Rate-limited seat → leave it, re-nudge AFTER the reset.
3. **GAP-CHECK + merge** anything finished (L1 steps 2–4).
4. **CLEANUP** (L5).
5. **REFILL** every freed seat. A tick that finds nothing pulls from the
   backlog residual sweep — the loop never starves quietly.

## L3 — TIMER (locked cadence)

- Inside Orca: event-driven wait, 15-min checkpoint —
  `orca orchestration check --terminal <coord> --wait --types worker_done,escalation,decision_gate --timeout-ms 900000`
- Between coordinator sessions/ticks: 20–30-min self-wake.
- **Re-nudges and watchdogs live in `orca automations create` — they survive
  session death.** A session-local timer is only ever the redundant near-term copy.

## L4 — PR-SWEEP (bot-review convergence)

Sweep open PRs → queue every actionable bot comment → verify each claim against
the code (bots are right often enough to check, wrong often enough to refute) →
fix real ones WITH tests / refute wrong ones with proof → reply + resolve →
push that branch only → merge green+0-unresolved → **freshen every still-open
branch with dev after each merge** (drift compounds into conflicts). Expect
convergence over rounds: your fixes get P1s too.

## L5 — CLEANUP (ownership ledger — the most expensive lesson here)

- Keep a per-project ledger (e.g. `.claude/orca-briefs/SPAWNED-SEATS.md`):
  every seat/worktree YOU spawned, plus an explicit NEVER-CLOSE list.
- **Close ONLY handles recorded in the ledger. Never pattern-sweep terminals
  by title or path** — a terminal you didn't record belongs to the operator or
  another controller, even inside your own project.
  (Bought: a title-pattern sweep killed the operator's live sessions in three
   other projects. Twice.)
- Worktrees are reaped only AFTER their PR merges:
  `orca terminal stop` → `git worktree remove <path>` → ledger row updated →
  verify by re-listing.
- Session end: settle-up (commit WIP, push upstreams, write the handoff note
  with live seat state + any pending timers' manual fallbacks).

## Merge-gate & capped-lane policy (locked)

- **Gate = real bot review (Greptile-class) + cross-model second opinion +
  coordinator/human.** Advisory bots that post summaries without reviews never gate.
- When the cross-model lane is rate-capped: **LOW-RISK PRs may merge** on
  read-bot-review + tests green + written coordinator reasoning; the capped
  model re-reviews on its next sweep. **High-risk (money paths, auth/session,
  broker execution, accounting) ALWAYS waits** for full gates + a human.

## Advanced modules (adopt after the core five run clean)

Council (multi-model plan debate to consensus), UI-Validation
(`orca goto/snapshot/click/eval` measured PASS/FAIL per user journey), and
domain loops layer on top of L1–L5 without changing them. Domain conveyors
(e.g. a quant strategy-conversion gauntlet) run as a **PARALLEL ALWAYS-ON lane**:
one dedicated background agent permanently works that queue, independent of the
app loop's refill order — app seats never wait on the conveyor and vice versa.
