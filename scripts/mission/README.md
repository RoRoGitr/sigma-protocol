# Mission System Scripts

Three scripts that power the Sigma Protocol mission system. Students install these into `~/.claude/` via `install-hooks.sh`.

## Files

### `mission-stack.py`

Mission DAG validator, active leaf resolver, and halt cascade engine.

**CLI:**
```bash
# Validate a mission's DAG invariants (cycle check, reciprocal edges, status constraints)
python3 mission-stack.py --validate my-saas-launch

# Print the active mission slug for a workspace
python3 mission-stack.py --resolve-active products-my-saas

# Cascade-halt a mission and all active descendants
python3 mission-stack.py --halt my-saas-launch --reason "pivoting to new approach"

# Pretty-print the mission tree for a workspace
python3 mission-stack.py --list-tree products-my-saas

# Output per-node status as JSON
python3 mission-stack.py --node-states products-my-saas --json

# Run inline doctests (25 tests)
python3 mission-stack.py --doctest
```

**Install location:** `~/.claude/scripts/mission-stack.py`

**Data:** Reads/writes `${SIGMAHQ_HOME:-~/.commandboard}/missions/*/mission.json`

**Requirements:** Python 3.9+ (stdlib only — no third-party dependencies)

---

### `mission-autoresearch.py`

Per-mission Exa-powered research agent. Scans active missions with `auto_research.enabled=true`, searches configured keywords via Exa REST API, scores relevance with Claude Haiku, and appends findings to `research-findings.jsonl`.

**CLI:**
```bash
# Research all stale active missions (>24h since last run)
python3 mission-autoresearch.py

# Force-research one specific mission
python3 mission-autoresearch.py --mission my-saas-launch

# Dry run — print what would run, no API calls
python3 mission-autoresearch.py --dry-run
```

**Install location:** `~/.claude/scripts/mission-autoresearch.py`

**Requirements:** Python 3.9+, `requests`, `anthropic` packages. API keys: `EXA_API_KEY` + `ANTHROPIC_API_KEY` (in environment or `~/.claude/.env`).

**Note:** This script is invoked by the My-AI-Brain autoresearch loop. It works standalone too — run it manually or via cron.

---

### `mission-session-start.sh`

SessionStart hook that injects the active mission banner into each Claude Code session. Completes in <2 seconds (cached read only, no filesystem scans).

**Install location:** `~/.claude/hooks/mission-session-start.sh`

**Workspace detection (in priority order):**

1. `CLAUDE_CODE_WORKSPACE_SLUG` env var — fastest, set in shell rc or `.envrc`
2. `.commandboard-workspace` file — place in project root, contains slug on one line
3. Directory name scan — matches CWD path segment against `${SIGMAHQ_HOME:-~/.commandboard}/workspaces/{category}/{name}/`

**Setup for a project:**
```bash
# Option A: env var (add to .envrc or shell rc)
export CLAUDE_CODE_WORKSPACE_SLUG=products-my-saas

# Option B: sentinel file in project root
echo "products-my-saas" > .commandboard-workspace
echo ".commandboard-workspace" >> .gitignore
```

---

## Installation

Run the provided installer (called automatically by `scripts/install-sigmahq.sh`):

```bash
bash scripts/mission/install-hooks.sh
```

The installer:
- Copies `mission-stack.py` + `mission-autoresearch.py` to `~/.claude/scripts/`
- Copies `mission-session-start.sh` to `~/.claude/hooks/`
- Appends the SessionStart hook entry to `~/.claude/settings.json` (idempotent)
- Safe to re-run — existing files are not clobbered without `--force`

## Mission Data Format

Missions live at `${SIGMAHQ_HOME:-~/.commandboard}/missions/{slug}/mission.json`. See `templates/commandboard/missions/_schema/` for the full JSON schema and a starter template.

## Workspace Slugs

A workspace slug identifies the kanban workspace that a mission belongs to. Format: `{category}-{name}` where category is one of `products`, `tools`, `clients`, `personal`, or any custom category you define under `~/.commandboard/workspaces/`.

Examples:
- `products-my-saas` → `${SIGMAHQ_HOME:-~/.commandboard}/workspaces/products/my-saas/`
- `tools-my-cli` → `${SIGMAHQ_HOME:-~/.commandboard}/workspaces/tools/my-cli/`
- `personal` → `${SIGMAHQ_HOME:-~/.commandboard}/workspaces/personal/`
