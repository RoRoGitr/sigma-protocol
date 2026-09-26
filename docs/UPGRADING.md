# Upgrading

When you pull a new release, run the upgrade workflow to update the install, refresh hooks, and surface migration prompts.

## Slash command (preferred)

```bash
/sigma:upgrade              # interactive — prompts before pulling
/sigma:upgrade --dry-run    # show what would change, don't apply
/sigma:upgrade --yes        # unattended (overnight pattern)
```

Works in any agent CLI — import `commands/sigma/upgrade.md` as a slash command, or run the script directly.

## Direct script (any environment)

```bash
bash scripts/sigma-upgrade.sh           # interactive
bash scripts/sigma-upgrade.sh --dry-run # preview
bash scripts/sigma-upgrade.sh --yes     # unattended
bash scripts/sigma-upgrade.sh --from 2.9.0  # override the "from" version
```

## What the upgrade does

1. Reads `.sigma/installed-version` to find the prior version + commit
2. `git fetch origin main` — does NOT pull yet
3. Shows the `CHANGELOG.md` section for the diff + `git log` since your last install (capped at 30 lines)
4. Prompts to confirm (unless `--yes`)
5. `git pull --ff-only origin main` — refuses on conflict
6. Re-runs `bash scripts/install-sigmahq.sh --no-open` (idempotent — preserves your user hooks)
7. Re-renders `commands/` via `bash scripts/sync-steps-to-platforms.sh --prune`
8. Runs `python3 scripts/migrate-prds-to-3.0.py --dry-run` and surfaces upgradeable-PRD count

## Manual fallback

```bash
git pull origin main
bash scripts/install-sigmahq.sh --no-open
bash scripts/sync-steps-to-platforms.sh --prune
python3 scripts/migrate-prds-to-3.0.py --dry-run   # then --apply if needed
```

The install script has been idempotent since 3.0 — re-running it is always safe.

## Resolving conflicts

If `git pull` reports a conflict, you have local changes that diverged from the release:

```bash
# Option A: keep your changes, then upgrade
git stash
bash scripts/sigma-upgrade.sh
git stash pop

# Option B: discard your changes, then upgrade (destructive)
git reset --hard HEAD
bash scripts/sigma-upgrade.sh
```

## Rollback

The upgrade does not auto-rollback. If an upgrade misbehaves, revert manually:

```bash
git log --oneline -5      # find the commit BEFORE the pull
git revert <commit-from-pull>
bash scripts/install-sigmahq.sh --no-open
```

## Version awareness

After every install or upgrade, `.sigma/installed-version` records the version + commit + install method:

```bash
bash scripts/install-sigmahq.sh --print-marker
```

The full `CHANGELOG.md` at the repo root lists every release.
