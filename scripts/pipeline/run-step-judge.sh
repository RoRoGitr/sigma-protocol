#!/usr/bin/env bash
# run-step-judge.sh — pipeline entrypoint for the C2 sigma-step-judge.
#
# The sprint-pipeline / gap-analysis flow calls THIS (a .sh gate, like the other
# pipeline gates) rather than step-judge.mjs directly. It runs the cross-family
# judge over a step artifact via fusion, surfaces a pipeline-log-friendly verdict
# line, and records the verdict to .sigma/judge/<gate>.json (step-judge.mjs does
# the write — dual-LLM quarantine: the judge model never writes state).
#
# ADVISORY by default: a FAIL verdict does NOT block (exit 0). It only blocks
# (exit 1) when the judge is CALIBRATED + cross-family AND --enforce is passed —
# enforced by step-judge.mjs itself, this wrapper just forwards the flag.
#
# Usage:
#   run-step-judge.sh --artifact <file> [--gate <name>] [--rubric <file>] [--enforce]
#
# Exit: 0 advisory (always, even on FAIL) · 1 only on a BLOCKING FAIL (calibrated
#       + cross-family + --enforce) · 2 usage error.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # scripts/pipeline
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"                  # repo root (scripts/pipeline → scripts → repo)
JUDGE="$REPO_ROOT/scripts/fusion/step-judge.mjs"

ARTIFACT=""; GATE="step-judge"; RUBRIC=""; ENFORCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    --gate)     GATE="${2:-}"; shift 2 ;;
    --rubric)   RUBRIC="${2:-}"; shift 2 ;;
    --enforce)  ENFORCE="--enforce"; shift ;;
    -h|--help)  sed -n '2,22p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "run-step-judge: unknown flag: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ARTIFACT" ]] || { echo "run-step-judge: --artifact <file> is required" >&2; exit 2; }
[[ -f "$ARTIFACT" ]] || { echo "run-step-judge: artifact not found: $ARTIFACT" >&2; exit 2; }
[[ -f "$JUDGE" ]]    || { echo "run-step-judge: judge not found: $JUDGE" >&2; exit 2; }

# Build the step-judge argv (array — injection-safe).
ARGS=(--artifact "$ARTIFACT" --gate "$GATE" --json)
[[ -n "$RUBRIC" ]]  && ARGS+=(--rubric "$RUBRIC")
[[ -n "$ENFORCE" ]] && ARGS+=(--enforce)

echo "run-step-judge[$GATE]: judging $(basename "$ARTIFACT") via fusion (cross-family panel)…"

# step-judge.mjs prints the verdict JSON to stdout (captured) and writes
# .sigma/judge/<gate>.json; its logs + fusion warnings flow to stderr. No `set -e`
# is active (top is `set -uo pipefail`), so a nonzero exit is captured, not fatal.
VERDICT="$(node "$JUDGE" "${ARGS[@]}")"
rc=$?

if [[ -n "$VERDICT" ]]; then
  # Surface a pipeline-log-friendly summary (parse with node — always available here).
  node -e '
    let r; try { r = JSON.parse(process.argv[1]); } catch { console.log("run-step-judge: (no parseable verdict)"); process.exit(0); }
    const tag = r.advisory ? "ADVISORY" : "BLOCKING";
    const xf  = r.crossFamily ? "cross-family" : "SAME-family";
    console.log(`run-step-judge[${r.gate}]: ${r.status} (${tag}, ${xf}, calibrated=${r.calibrated})`);
    if (r.advisory_reason) console.log(`  advisory: ${r.advisory_reason}`);
    for (const c of (r.criteria||[]).filter(c=>c.met===false)) console.log(`  FAIL ${c.id}: ${c.notes||c.evidence||""}`.slice(0,160));
  ' "$VERDICT"
else
  echo "run-step-judge[$GATE]: judge produced no verdict (see stderr) — treating as advisory skip"
fi

# Propagate step-judge's exit: 0 advisory (incl. FAIL) · 1 only on a blocking FAIL.
exit "$rc"
