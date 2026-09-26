# Fusion — Cross-Harness Adapter Contract

How Claude Code, Codex, and Cursor all reach the **same** fusion
primitive. One core, one shell spine, thin per-surface adapters — the
shared-core + adapter doctrine. Any shell-capable tool can shell out to the same
entrypoint.

## Layers

```
┌─ harness surfaces (thin adapters) ──────────────────────────────┐
│  Claude Code   /fusion command  (commands/fusion.md)              │
│  Codex         shell-out / skill → scripts/fusion/fusion.sh     │
│  any shell     shell-out         → scripts/fusion/fusion.sh     │
└──────────────────────────────┬──────────────────────────────────┘
                               │  every adapter calls ONE entrypoint
┌──────────────────────────────▼──────────────────────────────────┐
│  spine     scripts/fusion/fusion.sh                              │
│            normalizes task input (inline / file / stdin),        │
│            tags the harness (detect-cli.sh), forwards flags      │
└──────────────────────────────┬──────────────────────────────────┘
┌──────────────────────────────▼──────────────────────────────────┐
│  core      scripts/fusion/fusion.mjs                             │
│            panel (cross-family) → synthesizer; graceful degrade  │
│  config    scripts/fusion/setup-providers.mjs → providers.config │
│  detect    scripts/fusion/detect-providers.mjs → providers.json  │
└──────────────────────────────────────────────────────────────────┘
```

**Rule:** never call `fusion.mjs` directly from a harness adapter — go through
`fusion.sh`. The spine owns task-normalization, harness tagging, temp-file
hygiene, and injection safety, so each surface stays a one-liner.

## The one entrypoint

```bash
scripts/fusion/fusion.sh --task "TEXT" [--json] [--panel ...] [--synthesizer ...] [--timeout ms] [--max-panel n]
scripts/fusion/fusion.sh --task-file FILE [flags...]
echo "TEXT" | scripts/fusion/fusion.sh [flags...]      # task from stdin
```

Contract: task delivered to the core via a **file path only** (never eval'd, so a
malicious task body cannot execute); flags passed as an argv array; exit `0` ok,
`2` usage/empty-task error, otherwise the core's exit code. `--json` emits
`{ answer, panel, synthesizer, dropped, families, single_model_degrade, cost }`.

## Per-harness adapters

| Harness | Adapter surface | How it reaches the core |
|---------|-----------------|-------------------------|
| **Claude Code** | `/fusion` (`commands/fusion.md`) | command body runs `bash scripts/fusion/fusion.sh …` |
| **Codex** | shell-out (Codex has Bash) or a skill that wraps it | `bash scripts/fusion/fusion.sh …`. Codex itself is also a **voice** in the panel (`codex` CLI). |
| **Any shell tool** | shell-out from a task/agent | `bash scripts/fusion/fusion.sh …` against the stable contract below. |

External tools shell out to the stable `fusion.sh` contract above rather than
importing this code. That keeps the boundary clean: Sigma owns the primitive, the
caller owns the orchestration around it.

## Provider config interplay

- `detect-providers.mjs` writes `.sigma/providers.json` (ARRAY) — what is
  available on this machine (cache).
- `setup-providers.mjs` (Step-0 Phase B.2) writes `.sigma/providers.config.json`
  (OBJECT) — which voices are **enabled** + the synthesizer + which API-key
  env-var **names** to expect. The core honors it: panel is scoped to enabled
  voices, synthesizer defaults to the configured one. No config → all detected
  voices, `claude` synthesizer.

## Backends

The core has two interchangeable backends (`--backend`, or `FUSION_BACKEND` env):

| Backend | What runs the panel + synthesis | Setup |
|---------|----------------------------------|-------|
| **`byo`** (default) | Local: your CLIs + opt-in API voices → local synthesizer. | none — CLI-first |
| **`openrouter`** | OpenRouter's hosted Fusion (`model: openrouter/fusion`): its own panel + judge. | `OPENROUTER_API_KEY` |

`openrouter` is opt-in and **degrades gracefully** — missing key or a failed call falls back to the BYO panel with a logged reason, so an external paid dependency can never hard-fail a gate. Endpoint/model are env-overridable (`OPENROUTER_FUSION_URL` / `OPENROUTER_FUSION_MODEL`) to survive API drift. The `--json` output carries a `backend` field for A/B comparison. Honest caveat: OpenRouter Fusion's published evidence is one deep-research benchmark with no long-horizon results — A/B it against `byo` before trusting it on a gate; don't hard-wire a gate to it.

## C2 judge gate (pipeline entrypoint)

The sprint-pipeline / gap-analysis flow invokes the cross-family judge through
`scripts/pipeline/run-step-judge.sh` (a `.sh` gate like the others), NOT
`step-judge.mjs` directly:

```bash
scripts/pipeline/run-step-judge.sh --artifact <step-output> --gate <name> [--rubric <f>] [--enforce]
```

It runs `step-judge.mjs` over the artifact via fusion (cross-family panel →
synthesizer verdict), prints a pipeline-log summary, and records the verdict to
`.sigma/judge/<gate>.json`. **Advisory by default** (a FAIL never blocks; exit 0)
— it blocks (exit 1) only when the judge is `calibrated:true` AND cross-family
AND `--enforce` is set. This is the gap-analysis exit gate (#7) + the C1c CRAFT
semantic scorer. Calibration to flip advisory→blocking: `judge-calibration.mjs`
(golden-set, bal-acc ≥0.85 / TNR ≥0.80 / n≥40).

## Security

- **CLI-first, no keys required.** CLI voices use each CLI's own auth.
- **Names only, never secrets.** Config stores API-key env-var NAMES; the setup
  engine refuses any non-id input, so a key can never be persisted (SECURITY.md).
- **Injection-safe.** The task is always passed as a file; harness adapters that
  forward user text through `fusion.sh` inherit this.

## When to use

Tier it. Fusion is for judgment-heavy phases — the C2 judge, gap-analysis
verdicts, divergence synthesis, hard planning/spec calls — not every step. One
run = N voice calls + a synthesis; budget accordingly.
