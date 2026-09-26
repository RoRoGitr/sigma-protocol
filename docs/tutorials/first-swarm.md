# First Swarm (Tutorial)

This tutorial walks you through running your first `sigma swarm` end-to-end.

## 1. Dry Run (Plan Only)

Dry-run builds a deterministic plan (dependency graph + stream distribution) and prints it.
It does **not** write artifacts and does **not** launch anything.

From the repo root:

```bash
cd go
go run ./cmd/sigma swarm --dry-run --prds docs/prds/wave-4 --strategy balanced
```

What to look for:
- Stream assignments
- Dependency edges
- Quality Gates (DA/GA) per stream
- Agent assignments per stream

## 2. Generate Artifacts (No Launch)

Run without `--dry-run` to write swarm artifacts under:

```
.tracking-db/swarm/<run-id>/
```

Example:

```bash
cd go
go run ./cmd/sigma swarm --prds docs/prds/wave-4 --backend task
```

This writes:
- `plan.json` (full plan)
- `README.md` (run overview)
- `streams/stream-N/WORKER.md` (worker runbooks)
- `streams/stream-N/DA.md` (Devil's Advocate runbook)
- `streams/stream-N/GA.md` (Gap Analysis runbook)

It also updates:
- `docs/prds/.prd-status.json` (PRD orchestration compatible format)

## 3. Launch Workers (Optional)

Add `--launch` to spawn one worker per stream using your selected backend:
- `iterm` (macOS iTerm2)
- `tmux`
- `task` (prints commands only)

Example (tmux):

```bash
cd go
go run ./cmd/sigma swarm --prds docs/prds/wave-4 --backend tmux --launch
```

Claude power-mode launch (explicit opt-in):

```bash
cd go
go run ./cmd/sigma swarm --prds docs/prds/wave-4 --launch --claude-skip-permissions
```

To persist this default for future swarms:

```bash
go run ./cmd/sigma config set platforms.claude.custom.dangerously_skip_permissions true
```

## 4. How Work Flows (Per Stream)

Each stream follows the same sequence:
1. Execute PRDs in `WORKER.md` order
2. Run Devil's Advocate review (`DA.md`)
3. If DA passes, run Gap Analysis (`GA.md`) and close gaps 100%

## 5. Frontend Validation Policy

For frontend PRDs:
- Default browser tool is `agent-browser`
- Playwright is blocked-by-default unless the PRD frontmatter explicitly sets:

```yaml
allow_playwright: true
```

## 6. TUI Notes

In interactive terminals:
- Running `sigma` opens the full-screen TUI.
- Running `sigma --help` opens the TUI and shows help inside the app (unless `--no-tui`).
