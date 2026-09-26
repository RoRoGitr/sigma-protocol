<!-- LOOP-CONTRACT:start -->
## 🔁 Loop Contract (applies to every Sigma loop)

A **loop** is a pre-built iterate-until-done cycle. Invoking one is the user's explicit opt-in for the loop's *inner* iterations to run without asking — under these rules:

1. **The exit is an external check, never your opinion.** A loop ends when the verifier/score/engine says so (e.g. `@step-verify` ≥ threshold, 2 consecutive clean gap rounds, run-track engine says done) — not when the work "looks good."
2. **Hard bounds.** Every loop has a max-round ceiling. Hitting the ceiling = STOP and report honestly (`ceiling-hit`, findings attached) — never silently keep going, never declare success.
3. **Gates still belong to the user.** A loop may iterate on *work*; it may never answer a `<HARD-GATE>` question. If the loop reaches a gate, it pauses and asks — the HITL Gate Contract outranks this one.
4. **Evidence at every exit.** A loop's final message is a round-by-round table: round #, what changed, check command, real result. No output = round didn't happen.
5. **One loop at a time.** Never nest loops without the user asking.
<!-- LOOP-CONTRACT:end -->
