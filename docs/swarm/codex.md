# Swarm on Codex

Codex support uses one Codex session per stream. `sigma swarm` generates runbooks and a Codex-specific README describing the handoff protocol.

## What Gets Generated

After a non-dry-run swarm:

```
.tracking-db/swarm/<run-id>/
```

Codex-specific:
- `.tracking-db/swarm/<run-id>/codex/README.md`

Per-stream runbooks:
- `.tracking-db/swarm/<run-id>/streams/stream-N/WORKER.md`
- `.tracking-db/swarm/<run-id>/streams/stream-N/DA.md`
- `.tracking-db/swarm/<run-id>/streams/stream-N/GA.md`

## Launch Commands

Example shape:

```bash
codex -C "<project-root>" "Read .tracking-db/swarm/<run-id>/streams/stream-1/WORKER.md and execute."
```

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

