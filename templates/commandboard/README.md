# SigmaHQ — Commandboard Template

This directory contains the starter files that `scripts/install-sigmahq.sh` copies to `~/.commandboard/` when a student installs SigmaHQ.

## What Is SigmaHQ?

SigmaHQ is your personal kanban + mission command center. It gives you:

- **Daily board** (`board.md`) — living session log, today's priorities, blockers
- **Kanban workspaces** — persistent task tracking via `kanban-md`, organized by project category
- **Active Missions** — north-star outcomes that survive compactions and drive `/continue`, `/dev-loop`
- **Brain Dumps** — quick brain dumps that get parsed into kanban tasks
- **Dashboard** — local HTML dashboard aggregating everything into one view

## Template Files

| File | Purpose |
|------|---------|
| `config.yml` | Default `kanban-md` config for the root board |
| `board.md.template` | Daily board template (placeholders substituted on install) |
| `dashboard.html` | Dashboard HTML template (data injected by sync-dashboard.sh) |
| `bin/hq` | Shared SigmaHQ command wrapper for Codex, Claude Code, and humans |
| `sync-dashboard.sh` | Scan workspaces → generate `briefing.json` → build `dashboard-live.html` |
| `install-daily-refresh.sh` | Install an 8 AM local refresh via launchd on macOS or cron on Linux |
| `state-maintenance.py` | Compact runtime state and recalculate local XP/rank |
| `lib/hq_state.py` | Shared state helpers for stats, leaderboard, themes, and sidebar settings |
| `workspaces/personal/` | Starter personal workspace with first tutorial task |
| `missions/_schema/` | Mission system schema, template, and contract docs |
| `dumps/` | Drop brain-dump `.md` files here; sync picks them up |
| `archive/` | Processed dumps and archived artifacts land here |

## How install-sigmahq.sh Uses This

`scripts/install-sigmahq.sh` does the following:

1. Copies the entire `templates/commandboard/` tree to `~/.commandboard/`
2. Substitutes `{{USER_NAME}}` → `$USER` and `{{TODAY_DATE}}` → today's date in `board.md`
3. Makes `sync-dashboard.sh` executable
4. Makes `install-daily-refresh.sh` executable
5. Makes `state-maintenance.py` executable
6. Optionally appends `SIGMAHQ_HOME`, `PATH`, and Claude compatibility env vars to the user's shell RC
7. Runs `hq sync --no-open` to generate `briefing.json`, `dashboard-live.html`, and `schedules/YYYY-MM-DD.{md,json}`

## After Install

Students interact with SigmaHQ via:

```bash
# Sync + rebuild dashboard
hq sync --no-open

# Optional: refresh every day at 8 AM
hq daily-refresh install --time 08:00

# Compact runtime state and recalculate local XP/rank
~/.commandboard/state-maintenance.py --all

# Show install health for Codex or Claude Code
hq health

# Create a task in a workspace
kanban-md create --dir ~/.commandboard/workspaces/personal --title "My task"

# Drop a brain dump (gets picked up on next sync)
echo "# Quick thought\nStuff I noticed today." > ~/.commandboard/dumps/$(date +%Y-%m-%d)-dump.md

# Open the live dashboard
hq board

# In Claude Code — set a north-star mission
/mission new
```

## Customizing

- Add workspace prefixes to `WORKSPACE_PREFIXES` in `dashboard.html` for cleaner ticket IDs
- Add content brands to the content calendar section in `dashboard.html`
- Adjust WIP limits and statuses in `config.yml`
- Use the dashboard theme switcher and sidebar resize handles; preferences are stored locally in `ui-settings.json`

## Dependency

Requires `kanban-md` CLI. Install: `npm install -g kanban-md` or `brew install kanban-md`.
The install script checks for this dependency before copying any files.
