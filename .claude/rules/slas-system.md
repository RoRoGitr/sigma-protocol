# Sigma Protocol - Self-Learning Agent System (SLAS)

SLAS enables AI agents to learn from session history and adapt to developer preferences. Session learnings feed back into agent DNA and skill definitions through a classify → propose → review pipeline.

## SLAS Surfaces

SLAS runs through the session hooks below — there is no separate CLI. Distillation is a hook-driven pipeline: `session-end-summary.sh` logs each session, and `dna-classifier.sh` classifies accumulated patterns into proposals under `.claude/dna-proposals/` for human review.

## SLAS Session Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `session-start-context.sh` | SessionStart | Inject preferences + recent context |
| `session-end-summary.sh` | SessionEnd | Log session metadata |
| `dna-classifier.sh` | Post-distill | Classify patterns as DNA vs skill vs one-off |

## SLAS Workflow

```
1. Session Start -> Inject developer preferences
2. Work Session -> Normal development
3. Session End -> session-end-summary.sh hook captures session metadata
4. Periodically -> dna-classifier.sh distills accumulated patterns into proposals
5. Post-distill -> dna-classifier.sh classifies findings
6. Review -> Human reviews DNA proposals in .claude/dna-proposals/
7. Merge -> Approved proposals merge into agent/skill definitions
```

## DNA Feedback Pipeline

Session-distill outputs are classified into three buckets:

| Classification | Criteria | Action |
|---------------|----------|--------|
| **DNA-worthy** | Recurring (3+ sessions), methodology-level, tech-stack-agnostic | Proposal → `.claude/dna-proposals/` → merge into agent definition |
| **Skill-worthy** | Framework-specific, reusable, technical knowledge | Proposal → `.claude/dna-proposals/` → create/update skill |
| **One-off** | Project-specific, one-time, already in git | No action |

### Proposal Format

```markdown
---
type: dna | skill
target: [agent-name or skill-name]
priority: high | medium | low
evidence: [session IDs or dates where pattern appeared]
---

## Proposed Change
[What to add/modify]

## Why
[Why this is recurring and worth embedding]

## Where
[Exact file path and section to modify]
```

### Review Cadence

- After each distillation pass: check `.claude/dna-proposals/` for new proposals
- Weekly: batch-review accumulated proposals
- Approved proposals: apply changes, delete proposal file
- Rejected proposals: delete with a note in commit message

## SLAS Directory Structure

```
.claude/hooks/slas/              # Session hooks
  session-start-context.sh       # Injects preferences at session start
  session-end-summary.sh         # Logs metadata at session end
  dna-classifier.sh              # Classifies distill output
  lib/                           # Shared utilities
.claude/dna-proposals/           # Pending DNA/skill proposals (human review)
.claude/skills/core/session-continuity/  # Session continuity skill
docs/sessions/
  logs/                          # Session summaries (JSONL)
  preferences/                   # Developer profile
  patterns/                      # Pattern cache from distillation
```

## Auto-Generated Artifacts

SLAS generates:
- **Developer Preferences Skill**: Communication style, autonomy level
- **DNA Proposals**: Classified patterns for agent/skill improvement
- **Platform Rules**: Cursor rules
- **CLAUDE.md Section**: Injected preferences summary
- **Hook Recommendations**: Based on frustration patterns

## Integration with Self-Evolution Protocol

SLAS feeds the Self-Evolution Protocol in CLAUDE.md:
- SLAS detects patterns → classifies as DNA/skill/one-off
- DNA proposals → reviewed → merged into agent definitions
- Skill proposals → reviewed → created via skill-writer methodology
- The Self-Evolution Protocol section in CLAUDE.md describes when to auto-create skills/agents
- SLAS provides the data; Self-Evolution provides the rules
