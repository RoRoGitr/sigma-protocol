# Batch 4 skill review — 2026-09-19

Scope: all 78 entrypoints in `coverage-batch-4.json` (27,098 lines). Each entrypoint was read in bounded groups, then checked for runtime references, host/tool assumptions, stale framework claims, and conflicts with the refreshed protocol contracts. This is a source review; current external versions were not inferred from dates alone.

## Actionable findings

### B4-01 — `legal` points at a non-existent support tree

`.agents/skills/legal/SKILL.md:24-40` tells the runner to read `privacy-policy/SKILL.md` and exposes `generators/consent-flow`, `generators/account-deletion`, `generators/permission-priming`, and `monetization/`. None of those paths exists under `.agents/skills/` in this checkout. The first legal request therefore dead-ends after activation. Either package the referenced support skills or change this entrypoint to a self-contained workflow with links to real skills.

### B4-02 — `conversion-optimization` points at a non-existent support tree

`src/skills/conversion-optimization/SKILL.md:10-19` routes six optimization targets to `sections/*.md`, but the directory contains only `SKILL.md`; no `sections/` files exist. The router cannot load the promised content. Package the sections or replace the router with inline, real references.

### B4-03 — `implement-prd` uses filesystem-root paths in executable examples

`.agents/skills/implement-prd/SKILL.md:434-446,693-694,774,820,864-866,1092` uses paths such as `/docs/prds/.implementation-checkpoint.json`, `/docs/design/ui-profile.json`, and `/docs/flows/TRACEABILITY-MATRIX.md` inside `readFile`, `writeFile`, and `fileExists` examples. These resolve to the machine filesystem root, not the consuming project's checkout. The same skill's prose uses project-relative `docs/...` paths at 220-223, so the contracts conflict. Resolve project root once and join relative paths, or state that examples are pseudocode and use the host's project-root file tool.

### B4-04 — `ship-check` has the same absolute-path execution bug

`.agents/skills/ship-check/SKILL.md:148-164` assigns required artifacts to `"/docs/..."` and `FEATURE_BREAKDOWN="/docs/..."`. Shell checks against these values inspect `/docs` at the filesystem root and will report false misses in ordinary project checkouts. Use `docs/...` relative to the detected project root.

### B4-05 — `qa-run` is still Cursor-only despite cross-runtime packaging

`.agents/skills/qa-run/SKILL.md:7-18,33-53,178-211` makes Cursor browser MCP tools mandatory and describes all visual/manual validation as Cursor-only. It has no agent-browser/browser fallback, and its allowed-tools metadata omits the host-neutral question/tool adapter. On Claude or Codex the command cannot execute its advertised visual/manual modes. Route through the available browser capability and leave an explicit blocked gate when none is available.

### B4-06 — quality report ships a fabricated CVE placeholder as evidence

`.agents/skills/code-quality-report/SKILL.md:192` states `sharp@0.32.0` has `CVE-2024-XXXX`. `XXXX` is not an identifier and the sample report presents it as a finding. Replace with a real scanner receipt or an explicit example placeholder that cannot be mistaken for an observed vulnerability.

### B4-07 — API security example emits an expired deprecation date

`.agents/skills/owasp-api-security/SKILL.md:594` hard-codes `Sunset: Sat, 01 Mar 2025`. Copied into an API this date is already expired as of this audit. Make the date an operator-supplied project value and require verification against the actual retirement plan.

### B4-08 — plan skill still hard-requires an optional provider

`.agents/skills/plan/SKILL.md:3,12-24,124` says “Exa-first research” and requires every non-trivial decision to have Exa MCP citations. The refreshed repository contract makes external MCPs optional and explicitly provides host search/read fallbacks. This is a direct portability conflict. Change Exa to an optional capability and require evidence from whatever approved source is available.

### B4-09 — sales roster contains unresolved skill identities

`.agents/skills/sales/SKILL.md:13-14,46-57` names `/support`, `competitor-alternatives`, and `pricing-strategy`, while `/support` and `competitor-alternatives` do not exist in the installed skill pool. `email-sequence` exists under `.agents/skills/email-sequence/` and `pricing-strategy` exists, so those two are valid. Replace or add the missing identities; otherwise delegation silently fails.

## Framework/provider/version claims needing verification

These are recorded as verification work, not asserted defects:

- `notebooklm-format`, `contract`, `copywriting`, `brand`, `launch-strategy`, `manychat-funnel-strategy`, `high-ticket-closing`, `icp-definition`, `dm-funnel`, and `content-to-client` contain practitioner, market, or conversion claims. Treat the claims as hypotheses and refresh them against dated primary/first-party evidence before relying on them.
- `estimation-engine` (`:11,108,541,550,660`) uses an uncited “70%” estimate-accuracy claim, Exa/Ref-specific research, and fixed US 2025 rates. Rates and recommendation quality must be sourced per project and date.
- `owasp-web-security` uses the OWASP Top 10 2021 taxonomy (`:3,14,28`) and `owasp-api-security` uses API Top 10 2023 (`:3,14,28`). The taxonomy labels are historical and usable for coverage, but current OWASP guidance and project-specific controls must be checked before an audit is called current.
- `swiftui-patterns` (`:3,23,126,331,672-708`) claims iOS 26/Liquid Glass and an Xcode MCP bridge. Verify the installed Xcode/SDK and actual bridge commands before execution.
- `vercel-deploy` (`:28,63,98`) anchors Vercel CLI/config, Fluid, and Next.js 16 behavior to a 2026-06-04 snapshot. Recheck the installed CLI and project framework; do not treat the snapshot as a universal upgrade instruction.
- `better-auth-best-practices` (`:28-30,165-190`) assumes current CLI subcommands and a Cursor MCP installer. Verify against the installed Better Auth CLI and selected host.
- `platform-sync` and `x-twitter-research` describe external changelogs and APIs. The documents provide research procedures, not current availability receipts.
- `programmatic-seo` and `brand` reference EXA/MCP or missing named companion skills. These are capability/provider assumptions; use the host's actual search and installed skill index.
- `pptx`, accessibility, QA, backlog, and code-quality files contain 2025 example dates and sample reports. Dates alone are not treated as defects, but generated artifacts must use the current run date and observed receipts.

## Gate/tooling consistency

The 18 Run Track entrypoints in this batch (`run-fn-2`, `run-c-2`, `run-fn-3`, `run-g-5`, `run-l-0`, `run-m-1`, `run-m-4`, `run-o-5`, `run-s-4`, `run-c-4`, `run-co-4`, `run-fn-5`, `run-l-1`, `run-l-8`, `run-o-7`, `run-s-8`, `run-ops`, and `funnel-instrumentation-setup`) consistently name the host question adapter and preserve approval-before-continuation language. Their `scripts/run-track-continue.py` reference exists. No additional gate contradiction was found in this batch.

`verification-before-completion`, `prd-patterns`, `sprint-patterns`, `holes`, `quality-gates`, `karpathy-guidelines`, `writing-clearly`, `architecture-template`, `theme-factory`, `sigma-continue`, `telegram-bot-development`, `expo-deployment`, `x-twitter-research`, `webapp-testing`, `session-continuity`, `wireframe`, `funnel-instrumentation-setup`, and the remaining listed entrypoints were reviewed with no additional introduced, line-specific runtime failure found. Their external framework and version references remain project/date dependent where noted above.

## Per-file coverage

All entries below were reviewed. `C` = concrete issue above; `V` = claims needing current/project verification; `—` = no additional actionable finding.

| Entry points | Result |
|---|---|
| `notebooklm-format`, `contract`, `implement-prd` | V; C (B4-03) |
| `audit-accessibility-audit`, `estimation-engine`, `owasp-web-security`, `api-docs-gen`, `tech-debt-audit` | V |
| `code-quality-report`, `swiftui-patterns`, `qa-run`, `owasp-api-security` | C (B4-05, B4-06, B4-07); V |
| `prompt-handoff`, `programmatic-seo`, `ship-check`, `docx-generation`, `analytics-tracking`, `brand`, `pptx`, `secrets-detection`, `backlog-groom` | C (B4-04); V |
| `copywriting`, `harness-creator`, `opencode-agent-generator`, `vercel-deploy`, `quality-gates`, `launch-strategy`, `error-handling-patterns`, `billing-patterns`, `simplify`, `agent-browser-validation`, `dream-consolidation`, `plan` | C (B4-08); V |
| `motion-landing-design`, `manychat-funnel-strategy`, `writing-clearly`, `telegram-bot-development`, `verification-before-completion`, `expo-deployment`, `platform-sync`, `x-twitter-research`, `high-ticket-closing`, `better-auth-best-practices`, `webapp-testing`, `session-continuity` | V |
| `sprint-patterns`, `wireframe`, `prd-patterns`, `icp-definition`, `dm-funnel`, `content-to-client`, `holes`, `theme-factory`, `karpathy-guidelines`, `architecture-template`, `conversion-optimization` | C (B4-02); V |
| `run-fn-2-pricing-architecture`, `run-c-2-video-research`, `run-fn-3-forecast`, `run-g-5-cro-sprint`, `run-l-0-entity-formation`, `run-m-1-gtm-audit`, `run-m-4-messaging-system`, `run-o-5-incident-response`, `run-s-4-discovery-sop`, `run-c-4-thumbnails-titles`, `run-co-4-moderation`, `run-fn-5-runway`, `run-l-1-intake-batna`, `run-l-8-demand-playbook`, `run-o-7-sop-vendors`, `run-s-8-pipeline-ops`, `run-ops`, `funnel-instrumentation-setup` | — |
| `sales`, `gtm-stack-setup`, `sigma-continue`, `legal` | C (B4-01, B4-09); V |

No skill files were edited by this review. Findings are intentionally appended to the parent ledger for disposition; historical dates and named practitioners were not upgraded or removed merely because they are old.
