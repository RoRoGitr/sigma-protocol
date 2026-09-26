# Agent Goal Prompt Doctrine — 5-block contract

**Canonical reference for `agent-goal-skill`. Project-agnostic version. Load before shaping any goal.**

---

## Why this exists

GPT-5.5 (Codex CLI 0.128+) and Claude Opus 4.7 are different from GPT-4-class models. OpenAI's own guidance for GPT-5.5: *"Treat 5.5 as a new model family — start with the smallest prompt that preserves the product contract; don't carry over GPT-5.x instructions."* Sam Altman: *"expert vs college student"* — you don't tell an expert how to think, you tell them what's true at the end.

This file is the prompt format we use whenever a CLI agent is the executor — both interactive (`/goal <objective>` typed into a CLI) and non-interactive (`agent exec ...` from a subprocess).

---

## The 5-block template

Use this exact structure. Markdown headers, not XML tags. Hard rules at the **bottom** of the block — GPT-5.5 and similar models have strong recency bias on instruction following.

```
# Goal
<one-line outcome — what is true at the end. Verifiable, not aspirational.>

# Context
<facts the model can't derive from the codebase: paths, prior decisions, mission slug,
PRD ID, the specific commit/branch, pinned dependencies, the user's autonomy level.
Cite file paths absolutely.>

# Constraints
<hard rules and anti-patterns. What NOT to touch. Forbidden flags. Files that are
out-of-scope. Sandbox boundaries. License restrictions on referenced patterns.>

# Done when
1. <binary pass/fail criterion — a shell command or a file existence check ideal>
2. <binary pass/fail criterion>
3. <binary pass/fail criterion>

# On block
FAIL FAST. If any required input is missing or any criterion can't be satisfied
without my approval, write the question to a pending-questions file and exit
with non-zero status. Non-interactive run — never ask for approval inline.
```

---

## Rules of the doctrine

| Rule | Why |
|---|---|
| **Markdown headers, not XML** | XML works but markdown is cheaper to tokenize. Models also handle markdown more reliably across versions. |
| **One Goal per block** | If you have two goals, you need two blocks. Multi-objective goals cause agent thrash. |
| **`# Goal` is one line** | Forces clarity. If you can't compress the outcome to one line, you don't know the outcome yet. |
| **`# Context` cites absolute paths** | Relative paths break when the agent's cwd shifts. Always `~/path/...` or `/abs/path/...`. |
| **`# Constraints` lists what NOT to do** | Models bias toward action. Explicit "don't touch X" is more reliable than "focus on Y". |
| **`# Done when` is binary** | "Code is clean" is not binary. "`ruff check .` exits 0" is binary. Prefer shell commands. |
| **3-5 done-when items max** | More than 5 = scope too large. Split the goal. |
| **`# On block` is mandatory** | Without a fail-fast clause, agents stall waiting for approval and burn budget. |
| **Hard rules at the bottom** | GPT-5.5 recency bias means the last instructions weight strongest. Put the unforgivable rules last. |
| **Block under 1.5K tokens** | Sweet spot for `xhigh` reasoning per OpenAI's GPT-5.5 troubleshooting guide. Over 2K tokens degrades. |
| **No slop words** | "robust", "leverage", "seamless", "delve", "harness", "game-changing", "cutting-edge" — strip before transcribing. Add nothing, remove obstacles. |
| **Never invent context** | Unknown paths/IDs get `<TODO: user fills in>`. Fabricated facts make the agent execute against fiction. |

---

## Out-of-band hints (always emit alongside the block)

After the block, three additional hints help the target agent run efficiently:

### Sandbox

| Sandbox | When |
|---|---|
| `read-only` | Audit, research, planning, exploration. No file writes. |
| `workspace-write` | Code edits in one repo. The default for feature work. |
| `danger-full-access` | Cross-repo edits, system config, external service writes, dependency installs. Use sparingly. |

### Reasoning effort

| Effort | When |
|---|---|
| `medium` | Default. Most single-feature work. |
| `high` | Multi-step refactors, complex debugging, architecture exploration. |
| `xhigh` | Multi-hour autonomous runs, hard problems with multiple plausible approaches. |

### Token budget

| Budget | Scope |
|---|---|
| 500K – 2M | Single feature, single PRD, single bug fix |
| 2M – 5M | Sprint backlog, multi-PR feature, refactor across a module |
| 5M – 10M | Multi-day mission, cross-cutting refactor, architectural migration |

---

## Common failure modes the doctrine closes

| Failure | How the doctrine prevents it |
|---|---|
| Agent wanders into irrelevant areas | `# Constraints` lists out-of-scope explicitly |
| Agent stalls on missing context | `# On block` mandates fail-fast with question logging |
| Agent declares victory too early | `# Done when` is binary + verifiable, must pass every criterion |
| Agent runs out of budget mid-task | Token budget is sized to scope upfront |
| Agent runs in wrong sandbox | Sandbox is named explicitly, never inferred |
| Agent invents file paths | `Never invent context` rule + `<TODO>` placeholder convention |
| Agent burns reasoning on aspirational goals | `# Goal` is one verifiable line — forces clarity before dispatch |

---

## Example: a well-shaped goal

```
/goal

# Goal
Migrate the project's Postgres schema from `users.email` (text) to `users.email_normalized` (citext) with a backfill, and update all read sites.

# Context
- Repo: ~/code/myapp
- Branch: feat/email-normalization (already created)
- Migration target: db/migrations/2026_05_12_email_citext.sql
- Affected read sites identified by: `rg "users\.email[^_]" --type ts` (32 hits)
- Test suite: `bun test`
- Existing migrations use `goose` syntax — see db/migrations/2026_04_28_*.sql for template

# Constraints
- Do NOT drop the `email` column; add `email_normalized` alongside, then deprecate `email` in a follow-up PR
- Backfill must be idempotent (re-runnable)
- Do NOT touch tests/fixtures/ — that's a fixture-data update, separate PR
- Do NOT skip pipeline gates (--no-verify is forbidden)
- Output must pass `bun typecheck` and `bun test` cleanly

# Done when
1. `db/migrations/2026_05_12_email_citext.sql` exists and contains both ADD COLUMN and backfill
2. `rg "users\.email[^_]" --type ts` returns 0 hits
3. `bun typecheck && bun test` exits 0
4. Atomic commit with message format `feat(db): citext email_normalized + backfill`

# On block
FAIL FAST. If goose syntax differs from the template, write the question to ~/.code/.pending.md and exit. Non-interactive run.

Token budget: 1M
```

**Sandbox:** `workspace-write`
**Reasoning effort:** `medium`

---

## Anti-example: a poorly-shaped goal

> "Update the user model to handle emails better, make sure it's robust and clean."

Why it fails:
- No `# Goal` — "handle emails better" is not a verifiable outcome
- No `# Context` — no paths, no branch, no migration template
- No `# Constraints` — agent will refactor adjacent areas
- No `# Done when` — "robust and clean" is not binary
- No `# On block` — agent will stall on first ambiguity
- Slop words: "robust", "clean"
- No token budget, no sandbox, no reasoning effort

The shaper's job: take the bad version, produce the good version.

---

## Versioning

This doctrine is intentionally project-agnostic. Forks may add project-specific rules (custom pipeline gates, custom kanban paths) on top — but the 5-block contract and the rules table above are the immutable substrate.

When in doubt: smallest prompt that preserves the contract.
