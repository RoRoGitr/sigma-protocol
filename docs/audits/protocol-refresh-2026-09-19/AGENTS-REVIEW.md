# Agent roster review — 2026-09-19

Scope: semantic and runtime review of all 62 files under `.claude/agents/` and all 12 authored examples under `src/agents/`. This review is read-only; it records findings for the parent audit and makes no agent changes.

## Verdict

The Claude registry is internally resolvable. `node scripts/validate-cascade.mjs` passed, and `node --test scripts/tests/test-cascade-registry.mjs scripts/tests/test-ladder-resolution.mjs` passed all 5 tests. The resolver intentionally walks `.claude/agents/` and maps registry slugs to local files by basename (`.claude/lib/resolve-cascade.mjs:59-72`); it does not require a one-to-one mapping to `src/agents/`. There are no duplicate basenames within either tree. The previously reported seven missing agent paths are therefore not reproduced by the current resolver or validators.

The main defects are frontmatter/runtime safety and stale hard-coded orchestration instructions, rather than missing registry entries.

## Findings

### A1 — unrestricted permissions on two writable agents (high)

`.claude/agents/engineering/observability-engineer.md:5` and `.claude/agents/qa/verification-loop.md:5` set `permissionMode: bypassPermissions` while both agents have `Write`, `Edit`, and `Bash` in their tool allowlists. This removes the normal approval boundary for agents whose prompts explicitly modify code or run verification commands. The repository’s own operating rule says money/release safety boundaries must be preserved.

Action: replace with the least permissive mode required by the workflow, normally `acceptEdits` or `default`, and make any exceptional bypass a caller-controlled setting rather than a checked-in agent default.

### A2 — `memory: none` is not a documented Claude subagent value (medium)

The following four files use `memory: none`: `.claude/agents/qa/verification-loop.md:6`, `.claude/agents/security/security-infra.md:5`, `.claude/agents/security/security-mobile.md:5`, and `.claude/agents/security/security-web-api.md:5`. Current Claude Code documentation lists `user`, `project`, and `local` as the supported persistent-memory scopes. Omit `memory` when persistence is undesired, or choose `local` when session-local memory is intended. Do not rely on `none` as a portable disable value.

### A3 — 45 color values do not match Claude’s documented enum (low, broad)

The current docs allow the named values `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, and `cyan`. Forty-five Claude agent files use hex colors or unsupported names such as `gold`, `amber`, `coral`, and `indigo` (for example `.claude/agents/community/community-lead.md:4`, `.claude/agents/engineering/observability-engineer.md:20`, and `.claude/agents/qa/verification-loop.md:19`). These values are presentation metadata and may be ignored or rejected by the runtime.

Action: normalize to the documented enum or omit `color`. Do not spend prompt budget treating color as a semantic routing signal.

### A4 — required GitNexus MCP is not declared by this repository (high portability)

Seven runtime prompts require `mcp__gitnexus__query` as the “PRIMARY” search tool: `community/community-lead.md:23`, `community/discord.md:25`, `community/notebooklm.md:24`, `community/research-media.md:26`, `community/telegram.md:25`, `engineering/backend-engineer.md:143`, and `qa/qa-engineer.md:147`. The repo-local MCP list in `AGENTS.md` names Firecrawl, EXA, Ref, Context7, and Task Master AI; GitNexus is not listed. Their `tools` frontmatter also does not scope a GitNexus server. A fresh install can therefore receive an instruction to call a tool it cannot access.

Action: make semantic search capability-dependent: use available repository search first, use GitNexus only when the server is present, and record the fallback. If GitNexus is a supported optional integration, document and detect it rather than making it mandatory in agent prompts.

### A5 — QA cross-model gate is pinned to a stale model name (medium)

`.claude/agents/qa/qa-engineer.md:95` and `:122` hard-code `codex exec -m gpt-5.4`. This is now a stale, provider-specific invocation and conflicts with the current local routing policy and the user’s requested Fable/Astra refresh. It also assumes the executable and model ID exist on every consuming machine.

Action: route through the repository/provider configuration (or an explicit `SIGMA_CROSS_MODEL_COMMAND`/documented equivalent), record the selected canonical model in the receipt, and fail with a useful capability message when no second model is available. Keep the cross-model gate, but remove the frozen model string.

### A6 — QA reference is not an agent and is silently skipped by Claude (medium)

`.claude/agents/qa/qa-engineer-reference.md` has no YAML frontmatter (`:1`), while `qa-engineer.md:95` tells the agent to consult it. This is correctly excluded from the 62-agent runtime roster, but its location makes it look like a discoverable subagent and its instructions mention mandatory GitNexus/Greptile/Codex commands. Move it to a clearly named reference directory or document it as a static companion file; do not count or invoke it as an agent.

## Model and frontmatter review

All 62 Claude files have parseable frontmatter with `name`, `description`, `model`, and a non-empty `tools` list. The configured `model` values are only `opus` and `sonnet`; both are valid family aliases under the current Claude subagent contract. No blanket model replacement is justified: the documented model order supports explicit aliases and `inherit`, and model selection should remain workload-specific. The 12 `src/agents/` files are authored examples, not a second Claude runtime roster; the canonical-source split in `docs/CANONICAL-SOURCES.md:14-17` is correct.

The combined Claude descriptions are approximately 4.1k tokens, below the documented 15k description-warning threshold. The registry validator confirms 13 departments, 62 runtime agents, and local skill resolution. The `Task`/`Agent` entries in `security/security-lead.md` are not themselves a defect: current Claude documentation states that `Task` was renamed to `Agent` and remains an alias.

## Coverage ledger

Every file below was included in the metadata, body, delegation-boundary, and unsupported-reference sweep. `OK` means no additional high-confidence defect was found in this pass; findings are listed above by ID.

### `.claude/agents/` — 62 runtime files

| Department | Files reviewed | Result |
|---|---|---|
| community | `community-lead`, `cs-director`, `discord`, `media-gen`, `notebooklm`, `research-media`, `telegram` | A4 on community-lead, discord, notebooklm, research-media, telegram |
| design | `design-director`, `design-systems-architect`, `ux-director` | OK |
| engineering | `backend-engineer`, `compound-engineer`, `devops`, `dream-engineer`, `frontend-engineer`, `harness-architect`, `lead-architect`, `mobile-developer`, `observability-engineer`, `x402-engineer` | A1 observability; A4 backend |
| finance | `due-diligence-analyst`, `finance-director`, `pricing-strategist`, `unit-economics-analyst` | OK |
| legal | `donna-paulsen`, `general-counsel`, `harvey-specter`, `jessica-pearson`, `louis-litt`, `mike-ross`, `rachel-zane` | OK |
| marketing | `cmo`, `content-director`, `copywriter`, `growth-engineer`, `landing-page-specialist`, `manychat`, `paid-media-director` | OK |
| ops | `ops-director` | OK |
| product | `cpo`, `product-owner`, `venture-studio-partner` | OK |
| qa | `devils-advocate`, `knowledge-distiller`, `qa-engineer`, `verification-loop` | A1/A2 verification-loop; A5 qa-engineer; A6 companion reference |
| sales | `cso`, `discovery-specialist`, `follow-up-systemizer`, `negotiation-specialist`, `outbound-systems-architect` | OK |
| security | `security-ai-safety`, `security-compliance`, `security-infra`, `security-lead`, `security-mobile`, `security-web-api` | A2 infra/mobile/web-api; A4 none |
| trading | `chief-trading-officer`, `market-data-engineer`, `quant-strategist` | OK |

### `src/agents/` — 12 authored examples

`engineering/client-engineer`, `engineering/design-lead`, `engineering/frontend-engineer`, `sales/aaron-ross`, `sales/ari-gold`, `sales/belfort`, `sales/chris-voss`, `sales/cole-gordon`, `sales/cso`, `sales/jeremy-miner`, `sales/josh-braun`, and `sales/sheila-bella` were reviewed as authored examples. No Claude runtime frontmatter defect was assigned to these files. Their duplicate names (`cso` and `frontend-engineer`) are cross-surface by design and do not collide inside `.claude/agents/`.

## Verification commands

```text
node scripts/validate-cascade.mjs
  validate-cascade passed; departments: 13; agents: 62

node --test scripts/tests/test-cascade-registry.mjs scripts/tests/test-ladder-resolution.mjs
  5 tests, 0 failures
```

Source: [Claude Code custom subagents documentation](https://code.claude.com/docs/en/sub-agents), especially supported frontmatter fields, model aliases, memory scopes, tools, and permission modes. Documentation was checked on 2026-09-19.
