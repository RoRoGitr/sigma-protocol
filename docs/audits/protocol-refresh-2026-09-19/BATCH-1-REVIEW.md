# Batch 1 skill review — 2026-09-19

Scope: all 78 entrypoints listed in `coverage-batch-1.json` (27,098 lines). Each file was read in full during this pass. This document is a semantic/runtime review record; it makes no skill edits.

## Actionable findings

### B1 — Project-relative paths are written as filesystem-root paths

Several skills document or implement paths such as `/docs/...`. In a normal project checkout this resolves to the machine root, not `<project>/docs`, so the examples can read the wrong files or write outside the repository. The same pattern is repeated across the older command-style skills and should be normalized to `docs/...` or an explicit project-root join.

Evidence: `.agents/skills/test-gen/SKILL.md:148-160,179-193` uses absolute `glob`/read paths; `.agents/skills/ship-stage/SKILL.md:66-74` and `.agents/skills/ship-prod/SKILL.md:80,114` define root output directories; `.agents/skills/proposal/SKILL.md:231-257`, `.agents/skills/performance-check/SKILL.md:154-184`, `.agents/skills/seo-audit/SKILL.md:22-38`, `.agents/skills/license-check/SKILL.md:22-58`, `.agents/skills/sprint-plan/SKILL.md:147,413`, `.agents/skills/client-handoff/SKILL.md:48-49,120-122`, and `.agents/skills/job-status/SKILL.md:157,296,449` repeat the contract.

### B2 — Run Track entrypoints still require a host-specific question tool

The Run Track entrypoints declare `AskUserQuestion` in `allowed-tools` and then say “Use AskUserQuestion.” The repository contract now defines a native question adapter plus ordinary-turn fallback, so these bundled entrypoints can fail or misroute on Codex and other hosts even though the phase itself is valid. Replace the named tool requirement with the shared host-question contract and retain the real-answer/HITL semantics.

Evidence: `.agents/skills/run-o-2-sprint-rhythm/SKILL.md:4-11,98-103`; the same two occurrences are present in `run-c-6-social-copy`, `run-o-4-observability`, `run-co-1-platform-audit`, `run-co-2-welcome-flow`, `run-co-6-advocacy`, `run-fn-7-data-room`, `run-g-3-hypothesis-backlog`, `run-g-7-activation-cohorts`, `run-l-4-ip-trademark`, `run-l-6-compliance`, `run-m-2-avatar-positioning`, `run-m-6-content-engine`, `run-m-8-launch-runbook`, `run-o-8-contractor-onboarding`, `run-s-3-outbound-playbook`, and `run-s-6-inbound-dm`.

### B3 — Mission dispatcher assumes private Claude-only state and helpers

The mission skill hard-codes `~/.commandboard/missions/` as the only writable store and calls `~/.claude/scripts/mission-stack.py`. A clean Codex install or another project cannot satisfy this contract, and the instruction conflicts with the repo's portable runtime surfaces. It also names `AskUserQuestion` directly. The skill needs runtime discovery/configuration and a portable fallback, or an explicit “Claude-only extension” boundary.

Evidence: `.agents/skills/mission/SKILL.md:29-38,45-67`.

### B4 — Production deployment example bypasses the protocol's approval boundary

`ship-prod` correctly describes user checkpoints, but its executable Vercel example runs `vercel --prod --yes` without showing how the required final approval is obtained or how the command is scoped to the validated project. In a skill that presents itself as production-safe, this is a concrete mismatch between the declared gate and the runnable snippet. The deploy adapter must require the recorded approval receipt and use detected project context; `--yes` should not be the default safety mechanism.

Evidence: `.agents/skills/ship-prod/SKILL.md:151-189` declares confirmation checkpoints; `.agents/skills/ship-prod/SKILL.md:524-531` runs `vercel --prod --yes`.

### B5 — Client handoff invokes removed/ambiguous step aliases

The orchestration list says `@step-1` through `@step-9`, while the active protocol exposes named step skills such as `$step-1-ideation` and the repository's command vocabulary no longer includes generic `@step-N` aliases. A handoff run can therefore call nonexistent commands or select the wrong surface.

Evidence: `.agents/skills/client-handoff/SKILL.md:165-181`.

### B6 — Research and performance skills advertise undeclared tool names as the preferred path

The repository declares external providers as optional and requires capability-aware fallback. `research` still instructs agents to try exact `mcp__ref__...`, `mcp__firecrawl__...`, and `WebSearch` names without a host capability probe; `performance-check` checks `web_search`/`read_file` and Cursor-only names as if these were portable tool identifiers. This is a runtime portability defect when the tools are absent, distinct from the provider/version claims themselves.

Evidence: `.agents/skills/research/SKILL.md:31-42,93-97`; `.agents/skills/performance-check/SKILL.md:60-109`.

### B7 — Verification skill retains a universal fixed pass score

The current root contract says each step owns its verification schema and a rubric score does not replace evidence or approval. This skill's example still hard-codes `passing_score: 80` and calls its purpose “scoring,” which can reintroduce the retired universal threshold when copied into a project without a step-specific schema.

Evidence: `.agents/skills/verification/SKILL.md:22-49`.

### B8 — Stale dated output examples are presented as generated defaults

Several entrypoints use `2025-11-06` in command defaults and output examples rather than a date placeholder or runtime date. This is a usability defect because generated artifacts can inherit a false historical date and confuse audit chronology.

Evidence: `.agents/skills/dependency-update/SKILL.md:48,341,1089-1090`; `.agents/skills/seo-audit/SKILL.md:30,38`; `.agents/skills/license-check/SKILL.md:50`; `.agents/skills/client-handoff/SKILL.md:49`.

### B9 — Ship-prod retains the superseded four-metric DORA framing

The skill presents deployment frequency, lead time, change failure rate, and time to restore service as the complete DORA set. The repository's refreshed framework decision uses the current five delivery measures and keeps reliability separate. This is an actual framework inconsistency in a high-impact release skill.

Evidence: `.agents/skills/ship-prod/SKILL.md:24-34`.

## Provider/framework review boundaries

The following were reviewed but not treated as defects solely because they contain a version, model, or practitioner claim. Their claims remain project-specific or require primary-source verification when used: Xcode 26.3 MCP behavior (`.agents/skills/xcode-intelligence/SKILL.md:1-20`), OWASP 2025 examples and `gpt-4` sample code (`.agents/skills/owasp-llm-security/SKILL.md:1-7,20-65`), Convex's `gpt-4o` example (`src/skills/convex/SKILL.md:431`), Tauri 2, React Native/Expo, Apple testing, CI/CD action versions, and the practitioner frameworks in proposal, sales, UX, marketing, and Run Track skills. No Fable 5.2 or Astra model migration was inferred from examples.

## Per-file coverage

All 78 files below were read in full. `B#` lists an actionable finding above; `reviewed` means no additional high-confidence defect was assigned in this pass. Framework/provider claims were recorded as bounded and unverified unless covered by the parent `SOURCES.md`/`FRAMEWORKS.md` decisions.

| File | Result |
|---|---|
| `.agents/skills/proposal/SKILL.md` | reviewed; dated/absolute output convention included in B1/B8 |
| `.agents/skills/dependency-update/SKILL.md` | reviewed; B6 tool assumptions, B8 dated examples |
| `.agents/skills/performance-check/SKILL.md` | reviewed; B1 absolute paths, B6 tool assumptions |
| `.agents/skills/nda/SKILL.md` | reviewed; B1 absolute legal output paths |
| `.agents/skills/seo-audit/SKILL.md` | reviewed; B1 absolute paths, B8 dated example |
| `.agents/skills/release-review/SKILL.md` | reviewed; B1 absolute report paths |
| `.agents/skills/client-handoff/SKILL.md` | reviewed; B1, B5, B6 |
| `.agents/skills/ship-prod/SKILL.md` | reviewed; B1, B4, B9 |
| `.agents/skills/test-gen/SKILL.md` | reviewed; B1 absolute reads/globs |
| `src/skills/frontend-design/SKILL.md` | reviewed; provider claims bounded |
| `.agents/skills/daily-standup/SKILL.md` | reviewed; B1 absolute tracking paths |
| `.agents/skills/license-check/SKILL.md` | reviewed; B1, B8 |
| `.agents/skills/sprint-plan/SKILL.md` | reviewed; B1 absolute tracking paths |
| `.agents/skills/pdf-manipulation/SKILL.md` | reviewed; install examples are optional dependencies, no defect assigned |
| `src/skills/ci-cd-patterns/SKILL.md` | reviewed; version claims bounded |
| `.agents/skills/owasp-llm-security/SKILL.md` | reviewed; illustrative model examples, no migration assigned |
| `src/skills/convex/SKILL.md` | reviewed; illustrative model example, no migration assigned |
| `.agents/skills/job-status/SKILL.md` | reviewed; B1 absolute paths |
| `.agents/skills/stream/SKILL.md` | reviewed; runtime helper names are illustrative and require host implementation |
| `.agents/skills/video-hooks/SKILL.md` | reviewed; practitioner claims bounded |
| `.agents/skills/gap-analysis/SKILL.md` | reviewed; auto-fix is explicit command behavior, caller must scope it |
| `.agents/skills/dependency-security/SKILL.md` | reviewed; package-manager guidance is conditional |
| `.agents/skills/harness-engineering/SKILL.md` | reviewed; architecture examples are not host claims |
| `src/skills/testing-apple/SKILL.md` | reviewed; provider/version claims bounded |
| `.agents/skills/senior-qa/SKILL.md` | reviewed; no additional high-confidence defect |
| `.agents/skills/skill-creator/SKILL.md` | reviewed; Claude-specific install surface is explicitly labeled |
| `src/skills/mobile-shipping/SKILL.md` | reviewed; project-specific build timing claims bounded |
| `src/skills/expo-cinematic-motion/SKILL.md` | reviewed; provider claims bounded |
| `.agents/skills/ship-stage/SKILL.md` | reviewed; B1 absolute output path |
| `.agents/skills/xlsx/SKILL.md` | reviewed; no additional high-confidence defect |
| `src/skills/tauri-patterns/SKILL.md` | reviewed; security guidance coherent |
| `src/skills/ux-designer/SKILL.md` | reviewed; framework claims bounded |
| `.agents/skills/ai-image-prompt/SKILL.md` | reviewed; provider claims bounded |
| `.agents/skills/react-native-patterns/SKILL.md` | reviewed; provider/version claims bounded |
| `.agents/skills/skill-registry/SKILL.md` | reviewed; orchestration defaults are documented policy |
| `.agents/skills/prd-orchestrate/SKILL.md` | reviewed; dry-run default is explicit |
| `src/skills/follow-up-system/SKILL.md` | reviewed; practitioner citations bounded |
| `src/skills/arcads-api/SKILL.md` | reviewed; external action approval is explicit |
| `.agents/skills/telegram-community-management/SKILL.md` | reviewed; API limits are project/provider-specific |
| `.agents/skills/verification/SKILL.md` | reviewed; B7 |
| `.agents/skills/xcode-intelligence/SKILL.md` | reviewed; version claims bounded |
| `.agents/skills/observability-architecture/SKILL.md` | reviewed; no additional high-confidence defect |
| `.agents/skills/greptile-pr-review/SKILL.md` | reviewed; provider-specific skill clearly scoped |
| `src/skills/marketing-copywriting/SKILL.md` | reviewed; framework claims bounded |
| `.agents/skills/auth-patterns/SKILL.md` | reviewed; no additional high-confidence defect |
| `src/skills/meta-ad-builder/SKILL.md` | reviewed; dependency install is project-scoped |
| `.agents/skills/research/SKILL.md` | reviewed; B6 |
| `.agents/skills/knowledge-synthesis/SKILL.md` | reviewed; recommendations are conditional patterns |
| `src/skills/sales-identity/SKILL.md` | reviewed; practitioner framing bounded |
| `.agents/skills/run-o-2-sprint-rhythm/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-c-6-social-copy/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-o-4-observability/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-co-2-welcome-flow/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-fn-7-data-room/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-g-7-activation-cohorts/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-l-4-ip-trademark/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-m-2-avatar-positioning/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-m-6-content-engine/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-o-8-contractor-onboarding/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-s-6-inbound-dm/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-co-1-platform-audit/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-co-6-advocacy/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-g-3-hypothesis-backlog/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-l-6-compliance/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-m-8-launch-runbook/SKILL.md` | reviewed; B2 |
| `.agents/skills/run-s-3-outbound-playbook/SKILL.md` | reviewed; B2 |
| `src/skills/web-design-guidelines/SKILL.md` | reviewed; provider claims bounded |
| `src/skills/macos-design/SKILL.md` | reviewed; platform guidance bounded |
| `.agents/skills/mission/SKILL.md` | reviewed; B3 |
| `.agents/skills/run-marketing/SKILL.md` | reviewed; direct `AskUserQuestion` reference is the same B2 contract issue |
| `.agents/skills/run-content/SKILL.md` | reviewed; direct `AskUserQuestion` reference is the same B2 contract issue |
| `.agents/skills/run-sales/SKILL.md` | reviewed; direct `AskUserQuestion` reference is the same B2 contract issue |
| `.agents/skills/crm-pipeline-setup/SKILL.md` | reviewed; no additional high-confidence defect |
| `.agents/skills/discuss-phase/SKILL.md` | reviewed; no additional high-confidence defect |
| `.agents/skills/cleanup-repo/SKILL.md` | reviewed; intentional deprecated alias |
| `.agents/skills/sigma-simplify/SKILL.md` | reviewed; intentional deprecated alias |
| `.agents/skills/ads/SKILL.md` | reviewed; session question and spend guard are explicit |
| `.agents/skills/weekly-review/SKILL.md` | reviewed; checklist-only scope is explicit |

## Verification

Coverage source: `coverage-batch-1.json`; all 78 listed files existed and were read completely. Search checks used `rg` for absolute paths, host-specific tools, model/provider names, deprecated aliases, approval terms, and placeholder markers. No files were edited by this batch review.
