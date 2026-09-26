---
description: "Loop post-implementation gap analysis until 2 consecutive clean rounds (bounded at 6, per-finding 2-fix limit, evidence-out)"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
parameters:
  - --scope
  - --max-rounds
---

# /gap-loop — Gap Analysis Until Verified-Clean

Pre-built loop around `@gap-analysis`: one clean round can be luck; **two consecutive clean rounds** is the exit. This is the same discipline the sprint pipeline uses, packaged as one command.

## 🔁 Loop Contract (applies to every Sigma loop)

A **loop** is a pre-built iterate-until-done cycle. Invoking one is the user's explicit opt-in for the loop's *inner* iterations to run without asking — under these rules:

1. **The exit is an external check, never your opinion.** A loop ends when the verifier/score/engine says so (e.g. `@step-verify` ≥ threshold, 2 consecutive clean gap rounds, run-track engine says done) — not when the work "looks good."
2. **Hard bounds.** Every loop has a max-round ceiling. Hitting the ceiling = STOP and report honestly (`ceiling-hit`, findings attached) — never silently keep going, never declare success.
3. **Gates still belong to the user.** A loop may iterate on *work*; it may never answer a `<HARD-GATE>` question. If the loop reaches a gate, it pauses and asks — the HITL Gate Contract outranks this one.
4. **Evidence at every exit.** A loop's final message is a round-by-round table: round #, what changed, check command, real result. No output = round didn't happen.
5. **One loop at a time.** Never nest loops without the user asking.


## Usage

```
/gap-loop                        # gap-check the current implementation vs its PRDs
/gap-loop --scope=F01.002        # limit to one PRD/feature
/gap-loop --max-rounds=4         # tighten the ceiling (default 6)
```

## The loop

1. **Round.** Run `@gap-analysis` fresh (no memory of what you "already fixed" — re-derive from the code).
2. **Clean?** Zero new findings AND score ≥ 95 → increment the clean-streak. **Streak = 2 → STOP, report PASS.**
3. **Findings?** Reset the clean-streak to 0. Fix each finding in the implementation.
   - Per-finding limit: the same finding gets at most **2 fix attempts**; after that record it `unresolved` and stop re-fixing it (prevents the death spiral).
4. Back to 1. **Ceiling:** `--max-rounds` (default 6) total rounds → STOP, report `ceiling-hit` with open findings.

## What this loop may NOT do

- Delete, skip, or loosen a test to make a round come back clean.
- Mark a finding fixed without the re-run output showing it gone.
- Cross into new scope — bugs found *outside* the scope become follow-up tasks, not silent loop work.

## Exit report (always)

| Round | New findings | Fixed | Clean streak |
|-------|--------------|-------|--------------|

Final line: `PASS (2 consecutive clean rounds)` or `CEILING-HIT (open: …)` — with the last round's real command output attached.
