---
name: skill-optimizer
description: Run the Claude Code-only overnight agent DNA adherence evaluator when its local scripts and JSONL history exist. It reads recent Claude Code transcripts and emits a review report; it does not support Codex or other runtime transcripts.
allowed-tools: Bash
---

# Skill Optimizer — Agent DNA Adherence Evaluator

## Scope

This is an operator-local **Claude Code** tool. It depends on `~/.claude/scripts/skill-optimizer.py`, Claude Code JSONL history, and the report directory described below. Do not adapt it to another runtime by guessing at transcript formats; use that runtime's documented export or a separately implemented parser.

## When to Use

- **Nightly**: Run as part of overnight sessions to catch agent drift before it compounds.
- **Post-sprint**: After any sprint that used 10+ agent invocations, audit adherence before the next sprint.
- **Post-overnight-loop**: The overnight session ends — run this to generate a morning report.
- **When the user asks**: "are agents following their DNA?", "agent drift check", "optimize DNA", "evaluate agents".

Inspiration: an internal skill-autotune-loop write-up (operator-local).

---

## How to Invoke

```bash
# Standard nightly run (last 24h, cap 100 invocations)
uv run --directory ~/.claude/scripts python skill-optimizer.py

# Extended window (48h) with cost cap
uv run --directory ~/.claude/scripts python skill-optimizer.py --since-hours 48 --max-invocations 50

# Dry run — parse without calling API (free, validates pipeline)
uv run --directory ~/.claude/scripts python skill-optimizer.py --dry-run --since-hours 48 --max-invocations 5

# Custom output path
uv run --directory ~/.claude/scripts python skill-optimizer.py --output ~/Desktop/today-audit.md

# Small live test (cost depends on configured model and provider pricing)
ANTHROPIC_API_KEY=sk-ant-... uv run --directory ~/.claude/scripts python skill-optimizer.py --max-invocations 3
```

### CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--since-hours N` | 24 | Scan JSONLs modified within last N hours |
| `--max-invocations N` | 100 | Cap API calls (most recent N invocations) |
| `--dry-run` | false | Parse + plan without making any API calls |
| `--model MODEL` | Tool-configured default | Evaluation model; inspect the local script before selecting an identifier |
| `--output PATH` | `~/.claude/dna-proposals/YYYY-MM-DD-adherence-report.md` | Report output path |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Report written successfully |
| 1 | No relevant JSONLs found (window too narrow, or all daemon noise) |
| 2 | API errors exceeded 10% of invocations (check `ANTHROPIC_API_KEY`) |

---

## How to Interpret the Report

Report lives at `~/.claude/dna-proposals/YYYY-MM-DD-adherence-report.md`.

### Score Bands

| Band | Score | Action |
|------|-------|--------|
| **perfect** | 9-10 | Agent fully followed DNA. No action needed. |
| **minor_drift** | 7-8 | Small deviations. Monitor; update DNA if pattern repeats. |
| **significant_drift** | 4-6 | Meaningful gaps. DNA update candidate — review `AUTO_APPLY_CANDIDATE` findings. |
| **rewrite_needed** | 0-3 | Agent behavior diverged fundamentally. DNA rewrite needed (STAGE_FOR_REVIEW). |

### Finding Classifications

| Tag | Meaning | Phase 1 Action |
|-----|---------|----------------|
| `[AUTO_APPLY_CANDIDATE]` | New trigger phrase, gotcha, file path, quality-gate item | Review. Phase 2 will apply automatically. |
| `[STAGE_FOR_REVIEW]` | Rewrites or removals of existing DNA content | Human review required before applying. |
| `[DISCARD]` | One-off situational, not generalizable | Ignore. |

### Orphan Invocations

An **orphan** is an agent invocation where `subagent_type` doesn't match any file in `~/.claude/agents/` or the project's `.claude/agents/`. Common causes:
- `subagent_type: "Explore"` — built-in Claude Code capability, not a custom agent
- `subagent_type: "general-purpose"` — untyped invocation
- Agent was renamed or moved

Orphans are reported but not scored.

---

## Reading the Report

The report has three sections:

1. **Summary table** — total invocations, orphan count, mean score, finding classification counts.
2. **Per-agent sections** — top 3 divergences, novel patterns, and failures per agent with `session:line` anchors for tracing.
3. **Per-invocation appendix** (collapsible `<details>`) — full findings for every invocation.

To trace a finding back to the JSONL:
```bash
# Finding says: abc123:42 — open the session
ls ~/.claude/projects/**/abc123.jsonl
python3 -c "
import json
with open('path/to/abc123.jsonl') as f:
    for i, l in enumerate(f):
        if i == 42: print(json.loads(l))
"
```

---

## Phase 2 Roadmap

Phase 1 (current) = **read-only reporting**. No agent files are modified.

Phase 2 (after ~5 reports validate signal quality) will:
- Auto-apply `AUTO_APPLY_CANDIDATE` findings to agent DNA files (additive only).
- Queue `STAGE_FOR_REVIEW` items to `~/.claude/dna-proposals/staged/` for human review.
- Activate the `evolve_agent_dna(agent_path, findings)` stub in `skill-optimizer.py`.

Do NOT activate Phase 2 without the user's explicit "ship it" on the first 5 reports.

---

## Running Tests

```bash
uv run --directory ~/.claude/scripts python -m pytest test_skill_optimizer.py -v
```

Expected: 30 tests, all pass. No API key required for tests (mocked).
