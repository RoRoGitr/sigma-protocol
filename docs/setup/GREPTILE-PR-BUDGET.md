# Greptile PR File Budget Policy

This project enforces a PR file budget so Greptile review remains reliable on every pull request.

## Known Limit

- Greptile bot has reported a hard review cap of `100 files` on this repository.
- To avoid hitting that cap, we enforce a stricter project budget of `90 files` per PR.

## Enforcement

- CI workflow: `.github/workflows/pr-file-budget.yml`
- Local script: `scripts/check-pr-file-budget.sh`
- Greptile config: `greptile.json` (`fileChangeLimit: 100`)
- Shared git hook (Claude Code + Codex): `.githooks/pre-push`
- Claude preflight hook on `gh pr create`: `.claude/hooks/pr-file-budget-preflight.sh`
- Codex exec-policy prompt on `gh pr create`: `.codex/rules/sigma-workflow.rules`

## One-Time Setup (Global Across Claude Code + Codex)

Enable repository git hooks once:

```bash
scripts/setup-git-hooks.sh
```

Verify:

```bash
git config --get core.hooksPath
```

Expected output: `.githooks`

## Local Check

Run before opening or updating a PR:

```bash
scripts/check-pr-file-budget.sh origin/main HEAD
```

## Splitting Strategy (when over budget)

1. Group changes into logical domains (core logic, command wiring, tests/docs).
2. Create stacked branches from the previous PR branch.
3. Keep each PR at or below 90 changed files.
4. Open PRs in dependency order and merge top-down.

Example:

```bash
# PR 1
git checkout -b codex/w4-swarm-core
# commit + push + PR

# PR 2 (stacked on PR 1)
git checkout -b codex/w4-swarm-cli
# commit + push + PR targeting codex/w4-swarm-core

# PR 3 (stacked on PR 2)
git checkout -b codex/w4-swarm-tests-docs
# commit + push + PR targeting codex/w4-swarm-cli
```
