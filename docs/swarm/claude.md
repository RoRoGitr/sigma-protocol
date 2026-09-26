# Swarm on Claude Code

`sigma swarm` supports Claude Code by generating a per-run set of runbooks and a small `team.json` summary.

## What Gets Generated

After a non-dry-run swarm, look under:

```
.tracking-db/swarm/<run-id>/
```

Claude-specific artifacts:
- `.tracking-db/swarm/<run-id>/claude/team.json`

Per-stream runbooks:
- `.tracking-db/swarm/<run-id>/streams/stream-N/WORKER.md`
- `.tracking-db/swarm/<run-id>/streams/stream-N/DA.md`
- `.tracking-db/swarm/<run-id>/streams/stream-N/GA.md`

## Launch Commands

When `--launch` is used, the plan includes one command per stream. Each command instructs Claude to read a runbook and execute it from the project root.

Example shape:

```bash
cd "<project-root>" && claude --permission-mode delegate "Read .tracking-db/swarm/<run-id>/streams/stream-1/WORKER.md and execute."
```

Optional power-mode launch (explicit opt-in):

```bash
cd "<project-root>" && claude --permission-mode delegate --dangerously-skip-permissions "Read .tracking-db/swarm/<run-id>/streams/stream-1/WORKER.md and execute."
```

Enable this mode by either:
- Passing `--claude-skip-permissions` on `sigma swarm`
- Persisting config during setup/install:
  - `sigma init --claude-skip-permissions`
  - `sigma install --claude-skip-permissions`
  - or `sigma config set platforms.claude.custom.dangerously_skip_permissions true`

## DA/GA Protocol

Per stream:
1. Worker completes PRDs in `WORKER.md`
2. Devil's Advocate runs `DA.md`
3. Gap Analyst runs `GA.md` and closes gaps 100%

## Frontend Validation Policy

For frontend PRDs:
- Default browser tool is `agent-browser`
- Playwright is exception-only and requires PRD frontmatter:

```yaml
allow_playwright: true
```
