---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing. Requires running verification commands and confirming output before making any success claims. Evidence before assertions always."
version: "1.0.0"
source: "@obra/superpowers"
triggers:
  - ship-check
  - ship-prod
  - ship-stage
  - pr-review
  - qa-report
  - test-review
  - completion-claim
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

---

## The Gate Function

```markdown
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

---

## Common Failures

| Claim | Requires | NOT Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, "logs look good" |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |
| External send done (email / DM / post / payment) | The **provider's OWN log** confirms it (Resend `delivered`, platform message id, Stripe charge id) | App returned `sent:true`, agent said "sent", a DM that *says* "sending it" |

---

## Red Flags - STOP

Stop immediately if you're about to:

- Use "should", "probably", "seems to"
- Express satisfaction before verification ("Great!", "Perfect!", "Done!")
- Commit/push/PR without verification
- Trust agent success reports
- **Trust an app's `sent:true` or a "sending it now" message as proof an external send actually fired** — verify the provider's own log
- Rely on partial verification
- Think "just this once"
- Feel tired and want work over
- **Use ANY wording implying success without having run verification**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler ≠ tests |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

---

## Key Patterns

### Tests

```markdown
✅ CORRECT:
[Run test command]
[See: 34/34 pass]
"All tests pass"

❌ WRONG:
"Should pass now"
"Looks correct"
```

### Regression Tests (TDD Red-Green)

```markdown
✅ CORRECT:
Write test → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)

❌ WRONG:
"I've written a regression test" (without red-green verification)
```

### Build

```markdown
✅ CORRECT:
[Run build]
[See: exit 0]
"Build passes"

❌ WRONG:
"Linter passed" (linter doesn't check compilation)
```

### Requirements

```markdown
✅ CORRECT:
Re-read plan → Create checklist → Verify each → Report gaps or completion

❌ WRONG:
"Tests pass, phase complete"
```

### Agent Delegation

```markdown
✅ CORRECT:
Agent reports success → Check VCS diff → Verify changes → Report actual state

❌ WRONG:
Trust agent report
```

### External Effects (Outbound Sends)

A self-reported success is NOT proof an external side-effect happened. The app's
return value (`sent: true`), an agent's "I sent it", or a user-facing message
that *says* "sending it now" can all be true while the provider never received
the request. Reconcile against the provider's OWN ground-truth log.

```markdown
✅ CORRECT:
Send email → query Resend /emails for that recipient → status delivered/sent
Post to platform → fetch the post id back from the platform API
"Sent — Resend shows delivered to <addr>"

❌ WRONG:
"email_sent: True, so it's delivered"
The DM bot says "I'll send the breakdown" → assume it was sent
```

**Lesson (2026-06-25):** ~32% of lead-magnet emails the DM bot "promised" in IG DMs
never reached Resend at all — the promise was logged, the send never fired
(operator-owned threads, engine-failure cycles, manual "resending" notes). Caught
ONLY by cross-checking emails leads gave in DMs vs Resend's actual recipient list.
Any flow that sends / posts / charges externally needs a reconcile against the
provider, ideally scheduled — see `services/factory/dm_email_reconcile.py` (daily).

---

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

---

## Integration with SSS Protocol

### /ship-check, /ship-stage, /ship-prod
Run full verification suite before any deployment claim.

### /pr-review
Verify all claims in PR description match actual test output.

### /qa-report
Every "pass" must have corresponding verification evidence.

### /test-review
Verify tests actually test what they claim.

---

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

---

*Remember: "I'm confident it works" is not verification. Run the command.*
