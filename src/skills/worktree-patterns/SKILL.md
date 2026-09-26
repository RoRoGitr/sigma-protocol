---
name: worktree-patterns
description: "Coordinate parallel repository work under the host checkout policy. Use for shared-checkout ownership planning or explicit questions about Git worktree capabilities. The local operator profile forbids worktrees and uses disjoint-file workers in the main checkout; generic worktree examples are reference only where host policy permits them."
department: engineering
triggers:
  - git worktree
  - worktree
  - parallel branches
  - parallel agents
  - isolated checkout
  - branch isolation
  - worktree add
  - worktree cleanup
---

# Worktree Patterns

Choose the operating profile from the current host instructions before using any recipe below. Keywords help discover this skill; load it only when checkout coordination or worktree behavior is relevant to the task.

## Local operator profile: one shared checkout

For Dallion King's repositories, `~/AGENTS.md`, the nearest repository instructions and CURRENT `~/.claude/ROUTING.md` govern. Worktrees are forbidden. Use the existing main checkout on its prescribed integration branch (normally `main`; SigmaVue uses `dev`). Confirm the full path and current branch before edits; a mismatch is not permission to switch another worker's checkout.

- Partition workers by dependency and exact file ownership. Disjoint file edits may run in parallel; overlapping files run sequentially after an explicit handoff.
- Record inherited dirty files and preserve them. Do not stash, reset, replace shared files, switch branches, or stage unrelated changes to manufacture isolation.
- Keep commits scoped to the owned paths and follow the repository's review, push and deploy gates. One worker's completion does not authorize another worker's cleanup or a deployment.
- Serialize shared mutable operations such as dependency/lockfile changes and builds that write the same output directory. Use an isolated read-only source export for base inspection when needed; do not create a Git worktree.
- Verify the requested behavior and report the actual result. Shared-checkout status is context, not proof that all changes belong to your task.

Local acceptance checks:
- [ ] Correct main checkout and prescribed integration branch confirmed.
- [ ] Each worker has an explicit file scope; overlaps and shared outputs are serialized.
- [ ] Inherited changes remain intact; commits contain only authorized owned work.
- [ ] Repository verification, review and release gates are followed.
- [ ] No worktree creation, removal or pruning was performed.

## Generic Git worktree reference (inactive under the local profile)

The remaining sections explain Git capabilities for hosts whose policy permits worktrees. They do not authorize worktree use, branch switching, secret copying, cleanup or deletion in a host that forbids those actions. For the local operator profile above, use the shared-checkout procedure and do not execute these examples or apply their quality checklist.

### When another host may use a worktree

A worktree solves exactly one problem: two processes need to operate on the **same repository** at the **same time** without seeing each other's dirty files.

Use a worktree when:
- Two or more agent workers are implementing different features in parallel and a file edit from one would appear in the other's `git diff`, breaking its validation or deploy step
- A CI step needs to run against a clean checkout of a specific branch while another branch is actively being developed
- A deploy process reads the working tree (e.g., `npm run build`) and must not pick up uncommitted changes from another stream

Do NOT use a worktree when:
- The two streams edit completely different directories — standard branch checkouts on a shared tree are fine when no file overlaps
- You need speed over isolation — `git stash` + `git switch` is faster for sequential one-at-a-time context switches
- The repository is very large — each worktree needs its own full checkout of tracked files (not objects, which are shared in `.git`)

## Generic capability patterns

### Creating a worktree

```bash
# Add a worktree checked out to a new branch (most common)
git worktree add ../my-app-feature-auth -b feature/auth

# Add a worktree from an existing branch
git worktree add ../my-app-hotfix origin/hotfix/payment-bug

# Add a detached HEAD worktree (for read-only CI inspection)
git worktree add --detach ../my-app-sha abc1234

# Convention: name the directory <repo>-<purpose> or <repo>-<branch-slug>
# so it is clear which repo and which stream it belongs to
```

The new worktree directory is a sibling of the main working tree (not inside it). Git creates a `.git` file (not a directory) pointing back to the shared `.git` object store.

### Listing worktrees

```bash
git worktree list
# main     /path/to/my-app             abc1234 [main]
# feature  /path/to/my-app-feature-auth def5678 [feature/auth]
# hotfix   /path/to/my-app-hotfix       789abcd [hotfix/payment-bug]
```

### Removing a worktree

Always remove worktrees explicitly. Abandoned worktrees hold branch locks that prevent the branch from being checked out elsewhere.

```bash
# Remove when done (directory must be clean or use --force)
git worktree remove ../my-app-feature-auth

# Force-remove (discards uncommitted changes — confirm before using)
git worktree remove --force ../my-app-feature-auth

# Prune stale worktree metadata (e.g., directory was deleted manually)
git worktree prune

# List all worktrees including stale ones
git worktree list --porcelain
```

### Branch-per-worktree convention

One branch lives in exactly one worktree at any time. Git enforces this — you cannot check out the same branch in two worktrees. Design your branch naming to match:

```
Worktree directory              Branch
my-app/                         main
my-app-feature-auth/            feature/auth
my-app-feature-payments/        feature/payments
my-app-hotfix-login/            hotfix/login-crash
```

When an agent finishes its slice:
1. Commit inside the worktree (`git -C /path/to/my-app-feature-auth commit ...`)
2. Open a PR from that branch
3. Remove the worktree (`git worktree remove ../my-app-feature-auth`)

### Parallel agent workflow

This is the primary use case. Each agent gets its own worktree so dirty files from one never appear in another's validation step.

```bash
# Orchestrator: spin up two worktrees before spawning workers
REPO_ROOT="/path/to/my-app"
git -C "$REPO_ROOT" worktree add "${REPO_ROOT}-worker-a" -b feature/worker-a
git -C "$REPO_ROOT" worktree add "${REPO_ROOT}-worker-b" -b feature/worker-b

# Each worker operates in its own directory — no shared working tree
# Worker A writes to: ${REPO_ROOT}-worker-a/
# Worker B writes to: ${REPO_ROOT}-worker-b/

# After both complete:
git -C "$REPO_ROOT" worktree remove "${REPO_ROOT}-worker-a"
git -C "$REPO_ROOT" worktree remove "${REPO_ROOT}-worker-b"
```

### Gotchas

**Shared `.git/hooks`**

All worktrees share the same `pre-commit`, `pre-push`, and other hooks from `.git/hooks`. This is usually fine but means a hook that uses hardcoded absolute paths to the main working tree will break in other worktrees. Hooks should use `$(git rev-parse --show-toplevel)` to find the working tree root.

```bash
# Bad hook (hardcoded path)
cd /home/user/my-app && npm run lint

# Good hook (dynamic working tree path)
cd "$(git rev-parse --show-toplevel)" && npm run lint
```

**Lockfiles (package-lock.json, pnpm-lock.yaml, yarn.lock)**

Lockfiles are tracked, so they appear in every worktree. If two workers run `npm install` concurrently, they will both write to their own copies of the lockfile — the copies can diverge. Avoid running `npm install` in worktrees during parallel operations. Instead, run the install once in the main working tree before creating worktrees, or use `--frozen-lockfile` in each worktree to prevent writes.

**`node_modules/` is NOT shared**

Each worktree gets its own `node_modules/` directory. Shared object store means only `.git` objects are shared — file content in the checkout is not. This means each worktree needs its own `npm install`. Factor this into startup time.

**`.env` files and secrets**

`.env` files are typically gitignored and therefore NOT in the worktree checkout. Copy or symlink them explicitly before running application code in the worktree.

```bash
# After creating worktree, copy .env
cp /path/to/my-app/.env /path/to/my-app-worker-a/.env
```

**CI and worktrees**

CI systems clone into a single directory — worktrees are for local/parallel use. In CI, use separate jobs (each with its own clone) rather than worktrees. Worktrees become relevant in CI only if a single job must build multiple branches simultaneously (rare).

### Merge and cleanup discipline

```bash
# 1. Work is done in the worktree
git -C /path/to/my-app-feature-auth add src/auth.ts
git -C /path/to/my-app-feature-auth commit -m "feat(auth): implement JWT middleware"

# 2. Push the branch from anywhere in the repo
git -C /path/to/my-app push origin feature/auth

# 3. After PR is merged, delete the remote branch and the worktree
git -C /path/to/my-app push origin --delete feature/auth
git -C /path/to/my-app worktree remove /path/to/my-app-feature-auth
git -C /path/to/my-app branch -d feature/auth   # local branch is now safe to delete
```

Enforce cleanup: abandoned worktrees accumulate, hold branch locks, and confuse `git worktree list`. Run `git worktree prune` periodically to remove metadata for directories that were deleted without `git worktree remove`.

## Generic worktree anti-patterns

- Creating worktrees inside the main repository directory — the worktree directory must be outside the main tree; git will reject a worktree path that is a subdirectory of another worktree
- Two workers sharing a worktree and a branch — the entire point of the isolation breaks down; one worker's uncommitted changes appear in the other's `git status`
- Using a worktree for sequential context switches — `git switch` or `git checkout` is faster and leaves no cleanup debt
- Forgetting to remove worktrees after the branch is merged — stale worktrees hold branch locks and fill up disk over time
- Hardcoding the main working tree path in `.git/hooks` — hooks run in all worktrees; use `git rev-parse --show-toplevel`
- Checking out the same branch in two worktrees — git prevents this explicitly; create a new branch from the same base commit instead

## Generic worktree quality gates (permitted hosts only)

- [ ] Each parallel worker has its own worktree directory and its own branch; no two workers share a working tree
- [ ] Worktrees are removed (`git worktree remove`) after the associated branch is merged; no stale worktrees remain
- [ ] `git worktree prune` is run if any worktree directory was deleted manually
- [ ] Hooks use `$(git rev-parse --show-toplevel)` — no hardcoded absolute paths to the main checkout
- [ ] `.env` and other gitignored files are explicitly copied or symlinked into new worktrees before running application code
- [ ] `npm install` (or equivalent) is run inside each new worktree before any build step
- [ ] CI uses separate job clones, not worktrees; worktrees are a local-parallel primitive only
