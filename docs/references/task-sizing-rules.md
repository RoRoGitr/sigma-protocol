# Task Sizing Rules

> **Version:** 1.0.0 | **Last Updated:** 2026-03-20
> Reference for kanban-md task creation and benchmark rubrics. Every task on the board must satisfy these constraints.

---

## Core Constraint: One Agent Session

A task must be completable by a single agent in a single session. If it can't, it needs to be split further.

---

## Size Limits

| Constraint | Limit | Why |
|-----------|-------|-----|
| **Lines of code touched** | 500 max | Beyond this, review quality drops and rollback risk increases |
| **Files modified** | 8 max | More files = more merge conflicts, harder review, wider blast radius |
| **Logical changes** | 1 per task | Single responsibility — one reason to revert, one thing to test |

"Lines touched" means lines added + lines modified + lines deleted, counted via `git diff --stat`.

---

## Acceptance Criteria Requirements

Every task must have testable acceptance criteria. Vague criteria are not criteria.

### Good criteria
- "The `/api/users` endpoint returns 200 with a JSON array of user objects"
- "Running `npm test` passes with no new failures"
- "The button is visible on screens >= 768px and hidden below"

### Bad criteria
- "It works correctly"
- "The code is clean"
- "Performance is improved"

**Rule:** If you can't write a test or a manual verification step for it, the criteria is too vague. Rewrite it.

---

## Complexity Estimates

Assign one of these to every task at creation time:

| Size | Lines | Files | Typical Duration | Example |
|------|-------|-------|-----------------|---------|
| **S** | < 100 | 1-2 | < 30 min | Fix a typo, add a config value, update a test assertion |
| **M** | 100-300 | 3-5 | 30 min - 1 hr | Add a new API endpoint, create a component, write a migration |
| **L** | 300-500 | 5-8 | 1-2 hr | Implement a feature slice, refactor a module, add auth to a route group |

Tasks that would exceed **L** must be decomposed into smaller vertical slices before they go on the board.

---

## Dependency Rules

- Every task must explicitly declare its dependencies via `depends_on` in the kanban-md frontmatter
- A task with unresolved dependencies stays in `todo` — agents must not pick it up
- Circular dependencies are a board error — resolve immediately
- If a dependency is outside the board (external API, another team), note it in the task body and flag as potentially blocked

### Declaring dependencies

```bash
kanban-md create --dir {workspace} \
  --title "Add user profile page" \
  --body "Depends on API endpoint from #12..." \
  --depends-on 12 \
  --priority medium
```

---

## Rollback Plan

Tasks rated **M** or **L**, or tasks that touch shared infrastructure, auth, payments, or data migrations, must include a rollback plan in the task body.

### Rollback plan template

```markdown
## Rollback Plan
- **Risk level:** low / medium / high
- **Revert method:** git revert / feature flag / manual steps
- **Data impact:** none / reversible / destructive (requires backup)
- **Steps:**
  1. {specific revert step}
  2. {verification step}
```

**S** tasks with isolated scope (single file, no data changes) are exempt from rollback plans.

---

## Splitting Oversized Tasks

When a task exceeds the limits above, split it using vertical slices:

1. **Identify the integration boundary** — where does the feature touch multiple layers?
2. **Cut thin slices** — each slice delivers a testable increment across all layers
3. **Order by risk** — put the most uncertain slice first to flush out unknowns early
4. **Declare dependencies** — later slices depend on earlier ones only where actually required

### Example: "Add user authentication"

Too large as a single task. Split into:
1. **S:** Add auth schema + migration (DB layer only)
2. **M:** Add login endpoint + JWT generation (API layer)
3. **M:** Add auth middleware + route protection (API layer)
4. **M:** Add login form + token storage (UI layer)
5. **S:** Add logout + token cleanup (full stack, thin)

Each slice is independently testable and reviewable.

---

## Benchmark Rubric Integration

When scoring task quality in benchmarks, apply these weights:

| Criterion | Weight | Pass Condition |
|-----------|--------|---------------|
| Single session completable | 20% | Agent finished without context overflow or handoff |
| Lines within limit | 15% | `git diff --stat` shows <= 500 lines |
| Files within limit | 15% | <= 8 files in the changeset |
| Clear acceptance criteria | 20% | Every criterion is testable — no vague language |
| Single responsibility | 15% | One logical change, one reason to revert |
| Dependencies declared | 10% | All upstream tasks listed in frontmatter |
| Rollback plan (M/L only) | 5% | Present and specific for medium/large tasks |

**Pass threshold:** 80% overall. Any criterion at 0% is a hard fail regardless of total score.
