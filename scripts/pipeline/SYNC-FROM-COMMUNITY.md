# Pipeline Scripts — Lineage and Upstream Sync

## 1. Origin

The 15 scripts in this directory were imported from the author's upstream cross-model-agents repo (`community/`) on 2026-05-23. Sigma Protocol now owns them as a sovereign copy so the 8-gate pipeline is part of every fresh install, not an out-of-band artifact only present on the author's machine.

## 2. Why BUNDLED, not depended-on

- **Sovereignty over the differentiator.** The 8-gate pipeline is one of Sigma 3.0's strongest differentiators. Sigma owns it directly rather than soft-linking to a separate community repo.
- **Install simplicity.** A fresh user runs `git clone && bash install.sh` and gets the gates. No second clone, no environment variable, no upstream resolution step.
- **Version coupling.** A sigma-protocol tag pins the pipeline scripts that ship with it. One repo, one version, no compatibility matrix between sigma version N and cross-model-agents version M.

## 3. The 15 bundled files

| File | Purpose |
|------|---------|
| `compact-reinject.sh` | SessionStart hook that re-injects sprint position after Claude Code compaction. Reads `.sprint-state.json`, prints sprint context. |
| `git-pre-commit-hook.sh` | Git pre-commit hook that enforces pipeline gates for any repo with a `.pipeline-state.json`. Opt-in by file presence. |
| `pipeline-check.sh` | Reads `.pipeline-state.json` and reports which of the 8 gates are passing, failing, or pending. |
| `pipeline-gate.sh` | Records gate status into `.pipeline-state.json`. Usage: `pipeline-gate.sh <gate_name> <status> [score] [round]`. |
| `pipeline-init.sh` | Creates `.pipeline-state.json` in the current repo with all 8 gates pending. |
| `pipeline-reset.sh` | Clears pipeline state. `--all` flag clears across all repos plus legacy `/tmp/` artifacts. |
| `post-edit-reminder.sh` | PostToolUse hook that reminds Claude to run gates after file edits. |
| `pre-commit-gate.sh` | PreToolUse hook on `git commit` that blocks commits when gates are unmet. Skips in `CODEX_EXEC=1` review sessions. |
| `sprint-init.sh` | Creates `.sprint-state.json` for a new sprint. Accepts `--task-id`. |
| `sprint-step-guard.sh` | PreToolUse hook that blocks out-of-order sprint operations. Reads tool intent from hook JSON. |
| `sprint-step-tracker.sh` | PostToolUse hook that detects completion signals and advances sprint state. |
| `stop-gate.sh` | Stop hook that runs end-of-session checks. |
| `stop-pipeline.sh` | Parallel runner that fans out three Stop-hook scripts at once. Cuts worst-case from ~35s to ~15s. |
| `sync-worktree-state.sh` | Syncs pipeline state across git worktrees so all branches share one truth. |
| `track-file-change.sh` | Records which files changed in the current sprint. Inputs file path. |

Note: 14 of these came directly from upstream on 2026-05-23. `stop-pipeline.sh` is a local wrapper added during the bundle. The sync script below treats it as local-only.

## 4. How to check for upstream changes

The cross-model-agents repo continues to receive updates as Dallion improves the gate logic. To compare bundled files against upstream without modifying anything:

```bash
bash scripts/pipeline/sync-from-community.sh --check
```

Output is a per-file drift table:

- `=` checksum matches upstream
- `!` checksum differs (local edited, upstream edited, or both)
- `+` file exists upstream, not bundled here
- `-` file bundled here, not present upstream (local-only, e.g. `stop-pipeline.sh`)

## 5. How to pull upstream changes

```bash
bash scripts/pipeline/sync-from-community.sh --pull --backup
```

`--backup` is required, not optional. It copies the pre-pull state to `scripts/pipeline/.backup-<timestamp>/` so a bad sync is one `cp -R` away from reversal. The script refuses to run `--pull` without `--backup`.

After the pull, run the smoke test:

```bash
bash scripts/pipeline/sync-from-community.sh --check
```

All bundled files should now show `=`.

## 6. When to sync, when not

- **Sync when:** you are tracking a stable cross-model-agents tag, you have tested the upstream changes locally, or you want a specific upstream bug fix.
- **Do not sync when:** you have modified the bundled scripts for project-specific behavior. `--pull` overwrites local edits. A `--pull --merge` variant is not shipped yet; until it is, hand-port local changes back after sync.
- **Never sync mid-sprint.** Wait until `.sprint-state.json` is clean. Gate logic changing during an active sprint breaks step ordering.

## 7. Lineage cross-reference

- Historical home: the upstream `cross-model-agents` repo (`scripts/pipeline/`)
- Bug reports about gate logic itself (gate ordering, state schema, hook semantics) go upstream to cross-model-agents.
- Bug reports about the installer, the wiring into sigma-protocol's `settings.json`, or this sync script go to sigma-protocol.
- Bundle origin commit: sigma-protocol `e022d15` (2026-05-23, Slice 0g).
