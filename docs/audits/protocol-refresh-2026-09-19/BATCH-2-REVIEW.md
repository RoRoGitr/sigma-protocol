# Batch 2 skill review — 2026-09-19

This batch covers all 78 paths in `coverage-batch-2.json` (27,093 lines). Each entrypoint was consumed in full for structural coverage, then checked for execution-path references, host portability, gate wording, destructive operations, model/provider claims, and dated examples. This is a bounded repository review. It does not independently certify every external framework claim or current vendor API.

## Actionable findings

### B2-01 — `db-migrate` teaches destructive shared-checkout rollback

`.agents/skills/db-migrate/SKILL.md:771-778` stages every change, creates a commit/tag, and advertises `git reset --hard` as rollback. The same instruction appears at line 959. This conflicts with the repository rule forbidding reset-hard and broad staging in a shared checkout, and it can erase unrelated user work. The skill needs a scoped, non-destructive rollback contract and an explicit human approval boundary before applying a migration. The Supabase MCP call at lines 783-795 also needs provider detection and a CLI/manual fallback before it is presented as executable.

### B2-02 — `system-health` still treats optional MCPs and Cursor paths as universal

`.agents/skills/system-health/SKILL.md:32-40` calls `ref`, `exa`, `supabase`, and `21st-devmagic` required while the current project contract says integrations are optional. Lines 58-62 require Cursor command files and `perplexity` backup tools, and the sample output at lines 101-102 claims `18/18` compliance without evidence. This can fail or misreport on Claude/Codex projects. Replace with detected capabilities and a PASS/MISS/SKIP receipt tied to files actually present.

### B2-03 — `memory-systems` mandates automatic persistent-context loading

`.agents/skills/memory-systems/SKILL.md:203-216` says to automatically load persistent memory at every session start, then lines 222-241 show unguarded `createEntity`/`createRelation` calls. That conflicts with provider history contracts, user-controlled memory policy, and the repository’s context-engine rules. Make loading opt-in or host-adapted, preserve user policy, and require a visible source/permission check before reading or writing memory.

### B2-04 — Run Track gate wording remains host-specific

The following 16 Run Track entrypoints all declare `AskUserQuestion` in `allowed-tools` and say “Use AskUserQuestion” at their final gate (for example `.agents/skills/run-c-1-brief-intake/SKILL.md:97-103`): C1, C8, Co3, Fn1, Fn4, G1, G4, G8, L5, L7, M3, M9, O1, S1, S7, and `run-growth`. The canonical gate contract now requires a native question adapter with an ordinary-turn fallback and honors explicit unattended authorization. These skills need the same portable wording; the tool name may be an implementation detail.

### B2-05 — `cost-optimizer` contains executable obsolete model guidance

`.agents/skills/cost-optimizer/SKILL.md:157-175` recommends `gpt-3.5-turbo` and `gpt-4`, and uses fixed historical prices to calculate savings. It is inside an implementation recipe, so this is more than a dated example: copying it can select unavailable/deprecated model IDs and produce false cost projections. Use detected provider/model IDs and current project pricing receipts; leave historical numbers explicitly labeled as an example.

### B2-06 — `accessibility-audit` defaults to an absolute filesystem path and ships stale milestone output

`.agents/skills/accessibility-audit/SKILL.md:122-143` uses `/docs/...` as the default output and rollback locations, which resolves to the host filesystem root rather than the project. The embedded report at lines 927-973 contains completed 2025 dates, a claimed 89% score, and “on track” status. The dated sample is not itself a defect, but the default path is operationally unsafe and the sample must be clearly marked non-evidence. Use project-root-relative paths and receipt-backed status.

### B2-07 — `webhook-patterns` overstates queue delivery guarantees

`src/skills/webhook-patterns/SKILL.md:124-128` says “the queue guarantees delivery” while no queue provider, durability mode, retry policy, dead-letter behavior, or idempotency boundary is specified. Delivery is provider/configuration dependent. Reword as an assumption to verify and require retry/dead-letter/idempotency evidence before acknowledging a webhook.

## Framework/provider claims needing verification

These were retained as research or examples, not promoted to defects without a primary-source check: UI Healer’s Hormozi weighting and browser-engine matrix; accessibility touch-target and WCAG automation claims; React/Swift/Expo/Android guidance; x402, Arcads, NotebookLM, OpenCode, Sentry, and Supabase/Drizzle examples; commercial practitioner frameworks; and all historical dates, sample scores, prices, or generated report timestamps. Verify them in the consuming project against current primary documentation before execution.

## Per-file coverage

| Entrypoint | Lines | Result |
|---|---:|---|
| `.agents/skills/ui-healer/SKILL.md` | 1840 | Covered; see findings above where applicable |
| `.agents/skills/maintenance-plan/SKILL.md` | 1244 | Covered; see findings above where applicable |
| `.agents/skills/db-migrate/SKILL.md` | 1136 | Covered; see findings above where applicable |
| `.agents/skills/accessibility-audit/SKILL.md` | 996 | Covered; see findings above where applicable |
| `.agents/skills/email-sequence/SKILL.md` | 945 | Covered; see findings above where applicable |
| `.agents/skills/docs-update/SKILL.md` | 908 | Covered; see findings above where applicable |
| `.agents/skills/analyze/SKILL.md` | 860 | Covered; see findings above where applicable |
| `.agents/skills/new-feature/SKILL.md` | 820 | Covered; see findings above where applicable |
| `.agents/skills/status/SKILL.md` | 804 | Covered; see findings above where applicable |
| `.agents/skills/swift-concurrency/SKILL.md` | 765 | Covered; see findings above where applicable |
| `src/skills/pricing-strategy/SKILL.md` | 730 | Covered; see findings above where applicable |
| `.agents/skills/saas-security-patterns/SKILL.md` | 702 | Covered; see findings above where applicable |
| `.agents/skills/test-review/SKILL.md` | 667 | Covered; see findings above where applicable |
| `.agents/skills/cost-optimizer/SKILL.md` | 656 | Covered; see findings above where applicable |
| `.agents/skills/monorepo-architecture/SKILL.md` | 606 | Covered; see findings above where applicable |
| `.agents/skills/marketing-ideas/SKILL.md` | 597 | Covered; see findings above where applicable |
| `.agents/skills/content-atomizer/SKILL.md` | 550 | Covered; see findings above where applicable |
| `.agents/skills/react-performance/SKILL.md` | 548 | Covered; see findings above where applicable |
| `.agents/skills/memory-systems/SKILL.md` | 521 | Covered; see findings above where applicable |
| `.agents/skills/direct-response-copy/SKILL.md` | 496 | Covered; see findings above where applicable |
| `.agents/skills/marketing-psychology/SKILL.md` | 484 | Covered; see findings above where applicable |
| `.agents/skills/creating-opencode-plugins/SKILL.md` | 462 | Covered; see findings above where applicable |
| `.agents/skills/applying-brand-guidelines/SKILL.md` | 457 | Covered; see findings above where applicable |
| `.agents/skills/retrofit-sync/SKILL.md` | 431 | Covered; see findings above where applicable |
| `.agents/skills/compound-engineering/SKILL.md` | 416 | Covered; see findings above where applicable |
| `src/skills/companion-system/SKILL.md` | 388 | Covered; see findings above where applicable |
| `src/skills/audit-verify-prd/SKILL.md` | 356 | Covered; see findings above where applicable |
| `.agents/skills/superdesign-integration/SKILL.md` | 355 | Covered; see findings above where applicable |
| `.agents/skills/remembering-conversations/SKILL.md` | 343 | Covered; see findings above where applicable |
| `.agents/skills/specialized-validation/SKILL.md` | 334 | Covered; see findings above where applicable |
| `.agents/skills/x402-integration/SKILL.md` | 332 | Covered; see findings above where applicable |
| `src/skills/webhook-patterns/SKILL.md` | 312 | Covered; see findings above where applicable |
| `src/skills/monetization/SKILL.md` | 308 | Covered; see findings above where applicable |
| `.agents/skills/subagent-driven-development/SKILL.md` | 298 | Covered; see findings above where applicable |
| `.agents/skills/brainstorming/SKILL.md` | 273 | Covered; see findings above where applicable |
| `.agents/skills/discord-bot-development/SKILL.md` | 255 | Covered; see findings above where applicable |
| `src/skills/shadcn/SKILL.md` | 240 | Covered; see findings above where applicable |
| `.agents/skills/differential-review/SKILL.md` | 232 | Covered; see findings above where applicable |
| `.agents/skills/media-generation/SKILL.md` | 210 | Covered; see findings above where applicable |
| `src/skills/worktree-patterns/SKILL.md` | 208 | Covered; see findings above where applicable |
| `.agents/skills/notebooklm-workflow/SKILL.md` | 202 | Covered; see findings above where applicable |
| `.agents/skills/performance-patterns/SKILL.md` | 196 | Covered; see findings above where applicable |
| `.agents/skills/discord-community-management/SKILL.md` | 189 | Covered; see findings above where applicable |
| `src/skills/outreach-sequencing/SKILL.md` | 173 | Covered; see findings above where applicable |
| `.agents/skills/reducing-entropy/SKILL.md` | 150 | Covered; see findings above where applicable |
| `src/skills/discovery/SKILL.md` | 148 | Covered; see findings above where applicable |
| `src/skills/decisions-patterns/SKILL.md` | 146 | Covered; see findings above where applicable |
| `src/skills/pricing-psychology/SKILL.md` | 131 | Covered; see findings above where applicable |
| `src/skills/ad-creative-generation/SKILL.md` | 119 | Covered; see findings above where applicable |
| `.agents/skills/system-health/SKILL.md` | 111 | Covered; see findings above where applicable |
| `.agents/skills/run-c-8-publish-handoff/SKILL.md` | 110 | Covered; see findings above where applicable |
| `.agents/skills/run-c-1-brief-intake/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-fn-1-unit-economics/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-g-1-funnel-map/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-g-8-seo-organic-loop/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-l-5-vendor-dpa/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-m-3-stack-tracking/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-o-1-ops-baseline/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-s-1-icp-accounts/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/tdd/SKILL.md` | 109 | Covered; see findings above where applicable |
| `.agents/skills/run-co-3-content-rhythm/SKILL.md` | 108 | Covered; see findings above where applicable |
| `.agents/skills/run-fn-4-cost-audit/SKILL.md` | 108 | Covered; see findings above where applicable |
| `.agents/skills/run-g-4-ab-test-spec/SKILL.md` | 108 | Covered; see findings above where applicable |
| `.agents/skills/run-l-7-incident-narratives/SKILL.md` | 108 | Covered; see findings above where applicable |
| `.agents/skills/run-m-9-optimize-cadence/SKILL.md` | 108 | Covered; see findings above where applicable |
| `.agents/skills/run-s-7-followup-system/SKILL.md` | 108 | Covered; see findings above where applicable |
| `.agents/skills/executing-plans/SKILL.md` | 99 | Covered; see findings above where applicable |
| `.agents/skills/market-state-awareness/SKILL.md` | 84 | Covered; see findings above where applicable |
| `src/skills/agentic-ui/SKILL.md` | 80 | Covered; see findings above where applicable |
| `.agents/skills/dev-loop/SKILL.md` | 69 | Covered; see findings above where applicable |
| `.agents/skills/run-growth/SKILL.md` | 66 | Covered; see findings above where applicable |
| `.agents/skills/map-codebase/SKILL.md` | 65 | Covered; see findings above where applicable |
| `.agents/skills/repair-manifest/SKILL.md` | 64 | Covered; see findings above where applicable |
| `src/skills/electron/SKILL.md` | 50 | Covered; see findings above where applicable |
| `.agents/skills/entity-formation-setup/SKILL.md` | 50 | Covered; see findings above where applicable |
| `src/skills/sentry/SKILL.md` | 39 | Covered; see findings above where applicable |
| `.agents/skills/trading/SKILL.md` | 28 | Covered; see findings above where applicable |
| `.agents/skills/content-production-queue/SKILL.md` | 10 | Covered; see findings above where applicable |
