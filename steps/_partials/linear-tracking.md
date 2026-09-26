<!-- linear-tracking: canonical task-tracking block. Linear is primary when detected; GitHub Issues is the default fallback board (the SigmaHQ kanban was retired 2026-07-11). Included by steps under their own heading. -->

Task tracking has two supported boards — use whichever the user has:

**Linear (primary when detected).** Linear is configured when BOTH hold:
- `security find-generic-password -s LINEAR_API_KEY -w` returns a key (GraphQL endpoint `https://api.linear.app/graphql`, header `Authorization: <key>`, no Bearer prefix)
- `runtime-baseline.json` shows `linear.project: "<Linear project name>"` (each repo maps to exactly one Linear project; team is derived from the project)

When configured, mirror step progress as issues in `linear.project` via GraphQL `issueCreate` / `issueUpdate` (see Step 0 → Linear Operations Reference for the concrete queries): create a tracking issue when the step starts (state In Progress) and move it to Done when the step's primary output lands.

**GitHub Issues (default fallback).** When Linear is not configured, GitHub Issues is the task board — create wave-labeled issues in the project repo (`gh issue create --label "wave:W0" --title "…"`) and close them as work lands. This is a first-class path, not a degraded one: many protocol users run entirely on GitHub. File-based artifacts (`TASKS.md`, `.prd-status.json`) remain the offline fallback where a step defines one.

**Wave labels are MANDATORY on every created issue — an unlabeled issue is a defect** (same labels on either board). Planning/status issues (Steps 0–10, Run Track) carry `wave:W0`; execution issues carry their build-sequence wave (`wave:W1`, `wave:W2`, …) from Step 10 sequencing / Step 11.5 waves. Also label issues with the step name (e.g. `step-3`) so later steps can find them.

Never write task tracking to the retired SigmaHQ kanban (`~/.commandboard`, frozen 2026-07-11) — that board is dead for everyone. GitHub always owns the PR/branch/review/merge loop regardless of which board you track on; when Linear is connected, its issues two-way-sync to GitHub once the operator enables per-repo issue sync in the GitHub<->Linear integration (PR-linkback only today).
