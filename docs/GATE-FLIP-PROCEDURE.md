# Gate Flip Procedure

Gates start **advisory** — they report findings but do not block commits. This document covers what flip-eligibility means, how to read the status tool, and the exact steps to flip an eligible gate to blocking.

---

## What "advisory → blocking" means

An advisory gate runs, logs its verdict, and emits a `gate_fired` telemetry event, but `commit_allowed` is unaffected if the gate fires negatively. A blocking gate holds `commit_allowed=false` until it passes.

Flipping is irreversible in practice. A gate that blocks incorrectly (false positive) stops all commits until cleared. The eligibility bar exists to prevent premature flips on gates without enough real-world data.

---

## Two gate tiers — two flip bars

### Deterministic gates

Gates whose logic is rule-based and does not depend on an LLM judge:

| Gate | What it checks |
|------|---------------|
| `anti_slop` | Banned markers (TODO/FIXME/NotImplemented/xfail) in staged diff |
| `ui_validation` | Frontend visual assertions (automated) |
| `greptile_score` | Greptile static analysis score threshold |

**Flip bar:** the A5 firing-canary shows the gate fired on **≥10 eligible runs** with a **≤5% false-positive rate**.

- "Eligible run" = a `gate_fired` telemetry event for this gate.
- "False positive" = an operator-confirmed wrong fire, recorded via `--record-fp`.
- FP rate = confirmed FPs ÷ total fires.

### Judge gates

Gates that use an LLM judge to evaluate artifacts:

| Gate | What it judges |
|------|---------------|
| `gap_analysis` | Requirements traceability gaps |
| `cross_model_review` | Cross-family code review verdict |
| `devils_advocate` | Adversarial post-implementation review |
| `qa_verification` | QA sign-off |

**Flip bar:** the calibration report (`judge-calibration.mjs`) says `calibrated: true`.

Calibration requires (all must hold):
- n ≥ 40 HITL-labeled examples
- ≥ 15 positive (human=FAIL) and ≥ 15 negative (human=PASS)
- Balanced accuracy ≥ 0.85
- True-negative rate (TNR) ≥ 0.80 — the "don't cry wolf" guard
- Every example cross-family (reviewer model family ≠ implementer model family)

HITL labels are captured from operator overrides — no extra human burden. Every time an operator disagrees with a judge verdict, `judge-calibration.mjs --record` captures a labeled example.

---

## Reading `gate-flip-status --json`

```bash
node scripts/verify/gate-flip-status.mjs --json
```

Output shape:

```json
{
  "generated_at": "2026-06-15T10:00:00.000Z",
  "telemetry_events_loaded": 47,
  "fp_log_path": ".sigma/flip/false-positives.jsonl",
  "thresholds": {
    "FLIP_MIN_FIRES": 10,
    "FLIP_MAX_FP_RATE": 0.05
  },
  "gates": [
    {
      "gate": "anti_slop",
      "tier": "deterministic",
      "eligibleToBlock": true,
      "reason": "ELIGIBLE — flip via STEP_VERIFY_GATE_ENFORCE=1 or <!-- VERIFY-ENFORCE --> in step doc",
      "total_fires": 14,
      "eligible_fires": 14,
      "fp_count": 0,
      "fp_rate": 0.0,
      "calibrated": null,
      "calibration_n": null,
      "calibration_balanced_accuracy": null,
      "calibration_tnr": null
    },
    {
      "gate": "gap_analysis",
      "tier": "judge",
      "eligibleToBlock": false,
      "reason": "NOT calibrated — advisory — n=12 < 40; balAcc=0.880 < 0.85",
      "total_fires": null,
      "eligible_fires": null,
      "fp_count": null,
      "fp_rate": null,
      "calibrated": false,
      "calibration_n": 12,
      "calibration_balanced_accuracy": 0.88,
      "calibration_tnr": 0.82
    }
  ],
  "summary": {
    "total": 7,
    "eligible": 1,
    "not_eligible": 6
  },
  "errors": []
}
```

Key fields per gate entry:

| Field | Meaning |
|-------|---------|
| `eligibleToBlock` | `true` = safe to flip; `false` = do not flip yet |
| `reason` | Human-readable explanation; starts with `ELIGIBLE —` or `NOT eligible —` or `NOT calibrated —` |
| `total_fires` | (deterministic) raw event count from telemetry |
| `fp_count` | (deterministic) operator-confirmed false positives |
| `calibrated` | (judge) boolean from the calibration report; `null` for deterministic |
| `calibration_n` | (judge) labeled example count |

The tool is **fail-open**: any I/O error is collected in `errors[]` and the tool exits 0. A non-empty `errors` array means the data may be incomplete.

---

## Flip procedure — deterministic gate

**Precondition:** `eligibleToBlock: true` from `gate-flip-status --json`.

**Flip options (choose one):**

### Option A — environment variable (global, all runs)

```bash
# Add to your shell profile or CI environment:
export STEP_VERIFY_GATE_ENFORCE=1
```

With this set, the step-verify gate switches from advisory to blocking for every invocation.

### Option B — per-step annotation (scoped, single step)

Add the marker comment to the step document that owns this gate:

```markdown
<!-- VERIFY-ENFORCE -->
```

The step-verify hook reads this marker and enforces blocking for that step only.

**After flipping:**

1. Run a pipeline pass end-to-end to confirm the gate blocks on a real failure.
2. If the gate produces an unexpected block, record it as a false positive:

```bash
node scripts/verify/gate-flip-status.mjs --record-fp --gate anti_slop
```

3. Monitor the FP rate. If it exceeds 5% post-flip, investigate and fix the gate logic before continuing.

---

## Flip procedure — judge gate

**Precondition:** `calibrated: true` in both `gate-flip-status --json` and the calibration report at `.sigma/calibration/<gate>.json`.

Judge gates auto-block once calibrated **and** the `--enforce` flag is passed to the judge invocation. The calibration report is authoritative.

**Steps:**

1. Verify calibration:

```bash
node scripts/verify/judge-calibration.mjs --gate gap_analysis --json
# Confirm: "calibrated": true
```

2. Pass `--enforce` to the step-judge invocation (done in the gate runner script — set the flag in your pipeline configuration or gate runner).

3. Run a pipeline pass. The judge will now return exit 1 on FAIL verdicts, which sets `commit_allowed=false`.

**To record a HITL label** (after disagreeing with a judge verdict):

```bash
node scripts/verify/judge-calibration.mjs \
  --record \
  --gate gap_analysis \
  --artifact path/to/artifact.md \
  --judge FAIL \
  --human PASS \
  --reviewer-family openai \
  --implementer-family anthropic
```

Accumulate ≥40 labeled examples across both verdict classes to reach calibration.

---

## Recording false positives (deterministic gates)

When a deterministic gate fires on a run you believe was correct (a false positive):

```bash
node scripts/verify/gate-flip-status.mjs --record-fp --gate <gate_name>
# Optional note:
node scripts/verify/gate-flip-status.mjs --record-fp --gate anti_slop --note "flagged minified vendor file"
```

This appends to `.sigma/flip/false-positives.jsonl`. The FP rate is recomputed on the next `gate-flip-status` run.

---

## Threshold overrides (CI / hermetic environments)

All thresholds are env-overridable. Do not lower them in production — these exist for test isolation only.

| Variable | Default | Meaning |
|----------|---------|---------|
| `FLIP_MIN_FIRES` | `10` | Minimum eligible fires for deterministic gates |
| `FLIP_MAX_FP_RATE` | `0.05` | Maximum FP rate (5%) |
| `SIGMA_TELEMETRY_DIR` | `.sigma/telemetry/sessions/` | Telemetry event source |
| `SIGMA_CALIBRATION_DIR` | `.sigma/calibration/` | Calibration report directory |
| `SIGMA_FLIP_DIR` | `.sigma/flip/` | FP log directory |

---

## Non-negotiables

- **Flipping is operator-initiated.** The tool reports eligibility; it never flips automatically.
- **Never flip without the data.** Thin telemetry → "NOT eligible — needs N more clean fires". No exceptions.
- **Release gates stay human.** The HITL checkpoints defined in `CLAUDE.md` (Step 1 before architecture, Step 11 before execution, etc.) are not pipeline gates and are not subject to this procedure.
- **A red gate is not a reason to bypass.** `SKIP_PIPELINE_CHECK=1` exists for docs/config commits only. Using it to escape a blocking gate that fired correctly is a process violation.
