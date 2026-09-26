# Foundation methodology research: Steps 0, 11.5, 12, and 13

Date: 2026-09-19  
Scope: research and trace only; no protocol or global installation changes made.  
Status: evidence-backed recommendations for the all-steps reverse-engineering pass.

## Method and limits

This report compares the live step sources and their gates with primary or owner-maintained sources. Local evidence is cited by file and line. External sources are linked directly. The available tools in this session did not include an authenticated Grok/X search connector, so no claim below says that Grok searched X. A Grok/X lane remains useful for discovering practitioner discussions, but its findings must be treated as leads and verified against primary documentation before entering a Sigma skill.

The first refresh already corrected several mechanical issues. This pass concerns methodology: whether the gate still measures the intended outcome, whether the attribution is defensible, and what acceptance evidence should replace vague completion language.

## Cross-cutting findings

1. **Use current primary sources for runtime claims.** The portable Agent Skills specification requires a directory with `SKILL.md`, `name`, and `description`; it recommends progressive disclosure and `skills-ref validate`. Host-specific fields must remain extensions. See [Agent Skills specification](https://github.com/agentskills/agentskills/blob/main/docs/specification.mdx).
2. **Do not use the deprecated OpenAI skills catalog as current guidance.** The repository now says it is deprecated and points to OpenAI Plugins for current examples. See [openai/skills README](https://github.com/openai/skills/blob/main/README.md). The current Codex sample still provides useful authoring mechanics: concise entrypoints, optional `references/`, `scripts/`, `assets/`, `agents/openai.yaml`, and `quick_validate.py`; see [Codex skill-creator](https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md).
3. **Context engineering is now the right umbrella for Step 12.** Anthropic describes it as curating the complete evolving context state, including instructions, tools, MCP, external data, and message history, with retrieval just in time rather than stuffing everything into a static prompt. See [Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) and [Claude context windows](https://platform.claude.com/docs/en/build-with-claude/context-windows).
4. **Acceptance must test observable behavior.** EARS is a reasonable notation for requirements, but it is not a queue protocol or a proof that a task is ready. The source attribution should be Mavin, Wilkinson, Harwood, and Novak, RE'09; a maintained implementation reference is [Microsoft HVE Core's EARS guide](https://github.com/microsoft/hve-core/blob/main/.github/skills/project-planning/requirements-author/references/prd/ears-acceptance.md).
5. **Agent work needs traces and evaluator separation.** OpenAI Agents SDK's maintained tracing model records generations, tool calls, handoffs, guardrails, and custom events; see [Agents SDK tracing](https://github.com/openai/openai-agents-python/blob/main/docs/tracing.md). This is useful evidence for Steps 11.5, 13, and 14, but it is not a reason to require the SDK in every project.

## Step 0 — Environment Bootloader

### Gate A — mode detection and runtime health

**Old purpose and provenance.** Detect `protocol-dev`, `boilerplate-project`, or `custom-project`; verify the canonical step, skill, renderer, and wiring surfaces. The live contract is `steps/step-0-environment-setup:69-119`. This is Sigma's own bootloader pattern; no external framework attribution is recorded.

**Primary-source comparison.** Codex's current AGENTS guidance treats instruction files as scoped, hierarchical repository policy, with deeper files taking precedence; see [Codex base instructions](https://github.com/openai/codex/blob/main/codex-rs/protocol/src/prompts/base_instructions/default.md). Anthropic's current Claude guidance likewise distinguishes always-on project context, rules, skills, subagents, and hooks; see [Steering Claude Code](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more).

**Keep / revise.** Keep the three Sigma modes and canonical-surface checks. Revise the gate to record an explicit **project baseline**: repository root, dirty state, branch/HEAD, package-manager/runtime versions, applicable instruction files, existing generated artifacts, and whether the project is greenfield or brownfield. A healthy Sigma renderer is not proof that a consuming project's runtime is healthy. Add a `baseline_evidence` object with command, timestamp, and result; never infer a mode from folder names alone.

**Acceptance.** PASS only when the report contains: detected root; mode with the exact predicate used; current branch/HEAD and dirty-state summary; applicable AGENTS/CLAUDE/rules files; runtime versions; canonical-surface checks; and explicit unknowns. A brownfield project without a codebase map must be `WARN / map-codebase required`, not silently treated as greenfield.

### Gate B — research stack

**Old purpose and provenance.** Classify `full`, `reduced`, or `blocked` research and detect optional design tools (`step-0:123-165`). The provider-neutral rule is sound and aligns with the repository's current preference for native web and documentation tools.

**Keep / revise.** Keep provider neutrality. Replace the binary “documentation lookup available” test with a **source-quality matrix**: official docs, maintained owner repository, standards/specification, peer-reviewed research, practitioner material, and search-only lead. Record freshness date, version/ref, URL, and confidence. A search result alone cannot graduate a framework into a skill. Add design-tool discovery for Pen, Taste, Designscape, browser/rendering tools, and host-native preview capability only when present; do not make any one vendor a required runtime.

**Acceptance.** PASS when each research category has an available path, source classes are recorded, and all claims used downstream have a source URL and verification date. `reduced` must list the missing source class and the claims that are therefore held. `blocked` means no path can verify a decision-relevant claim.

### Gate B.2 — fusion providers

**Old purpose and provenance.** Optionally detect CLI/API voices and persist provider IDs and env-var names (`step-0:169-203`). This is Sigma-specific orchestration policy.

**Keep / revise.** Keep keys out of files. Add provenance and privacy fields: provider, model/version, auth path, data-retention mode if known, enabled capabilities, and whether the provider is allowed to see repository contents. “Cross-model” should mean a genuinely distinct model/provider or a documented reason otherwise. Never imply that panel count itself improves quality.

**Acceptance.** PASS when the baseline names enabled voices, synthesizer, auth mechanism without secrets, data boundary, and an explicit skip reason. A fusion panel is optional and cannot waive human approval or source verification.

### Gate C — stack integrations

**Old purpose and provenance.** Infer integrations from boilerplate or repository markers and defer ambiguity to Step 2 (`step-0:205-236`). The mappings are Sigma's catalog assumptions, not universal architecture rules.

**Keep / revise.** Keep non-blocking recommendations. Replace hard-coded template-to-provider mappings with evidence from lockfiles, package manifests, deployment config, environment names, and import graphs. Record “configured,” “present but unused,” “planned,” and “unknown” separately. Do not install a dependency during detection.

**Acceptance.** PASS when every recommendation links to a detected file/symbol or is explicitly marked a proposal. No integration is called active solely because a boilerplate name matches.

### Gate C.1 — scaffold and dependency install

**Old purpose and provenance.** Scaffold only for new projects and install platform dependencies (`step-0:309-621`). This is a high-impact mutation boundary.

**Keep / revise.** Keep it conditional. Add package-manager and lockfile detection, exact version resolution, compatibility checks against the chosen framework's current official support matrix, and a dry-run diff before install. The gate must distinguish “scaffold prepared,” “dependency install executed,” and “smoke-tested.”

**Acceptance.** PASS when the user-approved stack profile, package manager, exact commands, lockfile diff, and smoke-test output are recorded. If compatibility cannot be verified, stop at PREPARED.

### Gate D/E — baseline and persisted state

**Old purpose and provenance.** Create minimal directories and write human/machine state (`step-0:664-749`).

**Finding.** The embedded JSON example contains `generated_at: "2026-03-19T00:00:00Z"` despite the file's 2026-09-19 refresh (`step-0:707-725`). That is a stale example and can seed false state.

**Keep / revise.** Keep the minimal baseline and no-downstream-surface rule. Replace the 95/100 absolute score with applicable checks plus hard blockers; a score must not make a failed evidence check look healthy. Generate timestamps at execution time and include schema/version plus evidence references.

**Acceptance.** PASS requires valid JSON, current timestamp, mode/runtime/research values, baseline evidence, blockers, and a report whose status is one of VERIFIED, WARN, PREPARED, or BLOCKED. Step 1 can proceed only if blockers are absent or explicitly accepted.

## Step 11.5 — Task Handoff

### Gate A — PRD import and dependency extraction

**Old purpose and provenance.** Import only approved PRDs and extract requirements, files, dependencies, and tests (`step-11.5:206-244`). EARS attribution is Mavin et al.; the queue and “zero clarification” doctrine are Sigma's own.

**Keep / revise.** Keep verbatim extraction and approval filtering. Add immutable source references: PRD commit/blob hash, section and requirement IDs, extraction timestamp, parser version, and a `source_status`. Do not promise “zero clarification” when the PRD is ambiguous; emit `BLOCKED / clarification required` with the exact ambiguity.

**Acceptance.** PASS when every task maps to an approved PRD section and requirement, every source line/ID is recoverable, and unresolved ambiguity is visible rather than filled in by the generator.

### Gate B — priority and dependency graph

**Old purpose and provenance.** Assign P0–P3 and topologically sort structural and declared dependencies (`step-11.5:118-148,246-276`). Priority labels are Sigma policy; dependency extraction is a useful graph transformation but not a substitute for domain review.

**Keep / revise.** Keep cycle detection and explicit `none`. Add dependency edge provenance (`declared`, `structural`, `inferred`) and confidence. Do not infer that table creation always blocks every reader if migrations, feature flags, or mocks make the relationship conditional. P0–P3 should remain release policy, not pretend to be universal product prioritization.

**Acceptance.** PASS when the graph is acyclic, every edge has a source and reason, inferred edges are reviewable, and topological order is deterministic. A cycle or unresolved edge blocks generation.

### Gate C — TASKS.md generation

**Old purpose and provenance.** Emit a durable Markdown queue with EARS criteria, files-to-touch, files-not-to-touch, claims, tests, and notes (`step-11.5:66-114,278-347`).

**Keep / revise.** Keep `TASKS.md` canonical and JSON optional. Add task identity, source hash, owner scope, allowed mutation class, expected artifacts, verification command, and evidence receipt fields. `Files-NOT-to-Touch` is useful but cannot guarantee isolation by itself; the runtime/worktree/coordinator must enforce it. EARS should support all five patterns, including unwanted behavior and optional features, rather than only WHEN/WHILE/IF examples.

**Acceptance.** PASS when a task can be validated from the manifest and source PRD without invented requirements; all paths are normalized; test commands are executable or marked NOT-EXECUTED with reason; and optional JSON is semantically equivalent to Markdown.

### Gate D — loop contract and hardening

**Old purpose and provenance.** Run `$holes`, sync tracker state, and document `/next-task` selection/claim semantics (`step-11.5:348-415`).

**Keep / revise.** Keep the crucial distinction that selection does not reserve a task. Revise “atomic” claiming: a Markdown commit conflict is not universally atomic, and two agents can both begin work before the conflict is observed. Require a coordinator, transactional tracker claim, lock, or isolated worktree reservation before implementation. Add lease/expiry and recovery semantics, and require an owner-approved policy for reclaiming abandoned work.

**Acceptance.** PASS when the consumer project has a demonstrated reservation mechanism, a deterministic idle result, a claim receipt, and a recovery path. If only TASKS.md exists, status must say `QUEUE_ONLY / concurrent execution unsupported`; it must not advertise an overnight autonomous loop.

## Step 12 — Context Engine

### Gate A — context import and surface detection

**Old purpose and provenance.** Load upstream artifacts, detect canonical surfaces, and bridge project memory (`steps/step-12-context-engine:35-70,75-87`). The single-store doctrine is Sigma policy.

**Keep / revise.** Keep one canonical project store and preservation of user-authored policy. Add a precedence map per host: system/developer/user/project/local instruction sources, path scope, conflict rule, and whether the host actually imports the file. Codex documents hierarchical AGENTS.md scope and deeper-file precedence; Anthropic documents CLAUDE.md, rules, skills, hooks, subagents, and memory as distinct controls. Do not claim that `CLAUDE.md` imports `AGENTS.md` unless a runtime probe proves it.

**Acceptance.** PASS when the report includes a loaded/unloaded probe for each target runtime, a scope table, a source-of-truth map, and a conflict-resolution rule. Unloaded or unsupported imports are explicit.

### Gate B — section plan and DNA/skills split

**Old purpose and provenance.** Keep AGENTS.md concise and push detail to skills/docs (`step-12:45-48`). This aligns with Anthropic context engineering and the Agent Skills progressive-disclosure specification.

**Keep / revise.** Keep the split, but replace a fixed token/file-size target with measured cumulative context budget and retrieval cost. Put stable constraints and startup routing in always-on instructions; put conditional procedures in skills; put large references in on-demand files. Include provenance and freshness metadata for project facts.

**Acceptance.** PASS when every instruction has an owner, scope, freshness status, and destination; AGENTS/CLAUDE content stays within a measured budget; references are one-hop discoverable; and no duplicated policy conflicts across stores.

### Gate C — synthesis

**Old purpose and provenance.** Generate AGENTS.md and project constraints from Steps 0–11. This is Sigma's context-engine implementation.

**Keep / revise.** Keep synthesis. Require a “source versus inference” label, contradiction report, and explicit unknowns. Contextual retrieval research supports adding document context before chunks and evaluating retrieval; see [Anthropic contextual retrieval](https://www.anthropic.com/engineering/contextual-retrieval). Do not auto-promote unverified conversation history or memory into hard policy.

**Acceptance.** PASS when each generated rule maps to a source artifact or a recorded operator decision, contradictions are surfaced, and a fresh runtime can load the intended instructions without relying on hidden session state.

### Gate D — memory bridge and tracker wiring

**Old purpose and provenance.** Update the project memory bridge and optionally sync Linear (`step-12:54-60,75-79`).

**Keep / revise.** Keep no-second-store and no-secret-storage rules. Add memory write permissions, retention, provenance, redaction, and rollback. Memory writes must be explicit and reviewable; provider auto-memory is host behavior, not a portable Sigma guarantee. Tracker wiring remains optional and should be a receipt-producing adapter, not a required context source.

**Acceptance.** PASS when reads/writes identify source, scope, timestamp, and authorization; secrets and sensitive data are excluded; sync failure leaves the project usable; and no duplicate store is created.

### Gate E — verification and handoff

**Old purpose and provenance.** Run `$holes`, produce a report, and hand off to Steps 13/14.

**Keep / revise.** Keep runtime probes and handoff. Add fresh-session tests at repository root and nested directories, instruction conflict tests, and a context-budget report. Anthropic explicitly describes just-in-time retrieval as a way to avoid stale indexing; the test should verify retrieval behavior rather than only file existence.

**Acceptance.** PASS requires root/nested load receipts, no unresolved path references, no contradictory managed blocks, and a report of what was loaded, omitted, or held.

## Step 13 — Skillpack Generator

### Gate A — inventory

**Old purpose and provenance.** Load AGENTS, design/technical/runtime docs, PRDs, indexes, skills, agents, and tickets (`step-13:174-206`).

**Keep / revise.** Keep canonical-source-first inventory. Add installed-host discovery: repository `.agents/skills`, `.claude/skills`, user/admin/system scopes, plugin manifests, and duplicate-name collisions. Codex's current source distinguishes skill authorities and visibility; see [Codex skill catalog types](https://github.com/openai/codex/blob/main/codex-rs/ext/skills/src/catalog.rs). Anthropic's maintained skills repo states that skills are self-contained directories and warns that examples may differ from runtime behavior; see [anthropics/skills](https://github.com/anthropics/skills).

**Acceptance.** PASS when each skill/agent has canonical owner, host scopes, version/ref, license, dependencies, activation surface, and collision status.

### Gate B — plan, DNA classification, and eval baseline

**Old purpose and provenance.** Separate immutable DNA from project skills and pressure-test each skill (`step-13:210-292`). TDD-for-skills is Sigma's adaptation of software TDD.

**Keep / revise.** Keep activation tests and negative controls. Replace “10 prompts per skill” as a universal threshold with risk-proportional evals: deterministic checks for files/commands/schema, behavioral cases for decision quality, negative/scope cases, and model-judge scoring only where deterministic assertions cannot work. Record generator/judge model IDs and rubric versions. Avoid embedding vendor-specific behavior in DNA.

**Acceptance.** PASS when each skill has trigger, non-trigger, expected artifact, failure behavior, deterministic checks where possible, judge rubric where needed, and a reproducible eval command. Threshold is declared per skill risk, not assumed to be 95/100 globally.

### Gate component-library bundle

**Old purpose and provenance.** Add shadcn, RN, agentic UI, companion, and motion skills when stack profile matches (`step-13:296-312`).

**Keep / revise.** Keep conditional bundles. Add provenance and upstream freshness checks for design/rendering tools. Pen, Taste Code, Designscape, and Claude Design should be modeled as optional host/tool adapters with capability detection; remove any claim that one is the canonical renderer until an owner source and local probe confirm it. The skill should output a portable design artifact and a tool receipt, then allow HTML/native rendering through whatever approved tool is available.

**Acceptance.** PASS when the bundle is selected from detected stack/profile evidence, each external tool has an owner URL/ref and version, and a missing tool produces a portable fallback rather than a blocked protocol.

### Gate C — authored source generation

**Old purpose and provenance.** Generate portable Agent Skills under `src/`, retain only `name`/`description` as portable core, keep host extensions separate, and use references/scripts for progressive disclosure (`step-13:316-386`). This is strongly supported by the Agent Skills spec and current Codex skill-creator guidance.

**Keep / revise.** Keep the portable core and canonical source. Add `license`, `compatibility`, `metadata`, and optional `allowed-tools` only when supported by the target host. Remove the unconditional `!command` dynamic-context claim; it is host-specific and must be adapter-scoped. Replace the absolute “under 500 lines” rule with the upstream recommendation of under 500 lines as a guideline, plus measured context cost.

**Acceptance.** PASS when `skills-ref validate` (or the host's documented validator) passes, description is discriminating, references resolve one level deep, scripts have executable tests, and host-specific metadata is isolated.

### Gate D — agent assignment

**Old purpose and provenance.** Map issues to agents via domain and a recorded `Agent:` field (`step-13:390-435`). This is Sigma/Linear policy.

**Keep / revise.** Keep explicit mapping and user review. Add assignment evidence: issue snapshot/hash, matching rule, owner scope, concurrency/isolation mode, and fallback when no tracker exists. Do not write to external trackers merely because they are configured; require the gate's recorded authorization and preserve dry-run mode.

**Acceptance.** PASS when every assignment is reproducible from the issue and index, duplicate ownership is flagged, and no assignment is claimed as a Linear/GitHub assignee when it is only metadata.

### Gate E — verification and handoff

**Old purpose and provenance.** Validate indexes, run `$holes`, and hand off canonical skill/agent sources to Step 14 (`step-13:438-495`).

**Keep / revise.** Keep index coherence and boundary checks. Add supply-chain checks: source URL/ref, checksum or commit, license, changed-file review, allowed tools, secret/network behavior, and rollback. Anthropic warns that skills can execute code and recommends using trusted sources; see [Anthropic Skills](https://www.anthropic.com/research/skills). The Agent Skills specification recommends the official validator; use it as a structural check, not a behavioral proof.

**Acceptance.** PASS when all active entries validate structurally, have provenance and license, pass their risk-appropriate evals, have no unresolved dependencies, and produce a Step 14 receipt that names the exact source and version. A plugin or remote skill is `UNVERIFIED` until reviewed and pinned.

## Immediate ledger items for the all-steps pass

| ID | Finding | Evidence | Disposition |
|---|---|---|---|
| FND-0-01 | Embedded Step 0 baseline timestamp is stale | `steps/step-0-environment-setup:707-725` | Revise example and require runtime generation |
| FND-0-02 | Runtime health is Sigma-surface health, not consuming-project health | `steps/step-0-environment-setup:93-113` | Add project baseline and evidence receipt |
| FND-11.5-01 | Markdown conflict is not a sufficient atomic claim mechanism | `steps/step-11.5-task-handoff:152-187` | Require coordinator/lock/transaction or mark queue-only |
| FND-11.5-02 | “Zero clarification” overclaims what an ambiguous PRD can support | `steps/step-11.5-task-handoff:51-62` | Emit explicit ambiguity blockers |
| FND-12-01 | Runtime import behavior must be probed per host | `steps/step-12-context-engine:45-60` | Add root/nested fresh-session receipts |
| FND-12-02 | Static token/file targets need measured cumulative budget | `steps/step-12-context-engine:45-48` | Replace fixed target with budget report |
| FND-13-01 | Dynamic context syntax is host-specific | `steps/step-13-skillpack-generator:328-351` | Move to adapters and document support |
| FND-13-02 | Universal 10-prompt/95 score is not risk proportional | `steps/step-13-skillpack-generator:265-286,519-542` | Declare eval policy per skill risk |
| FND-13-03 | External skill/tool supply chain lacks required provenance fields | `steps/step-13-skillpack-generator:316-386,438-475` | Add ref/license/checksum/tool-risk receipt |

## What this report does not establish

No current primary source was found in this pass proving that “Taste Code,” “Designscape,” “Pen.dev,” “Hermes,” “EVE,” “OpenClaw,” or ACP should become required Sigma components. They should enter the next all-steps ledger as candidate tools with owner URL/repository, release/ref, license, capability probe, and fallback behavior. The same applies to new Hormozi material: the existing Hormozi skills should not be called current until an official, dated source is identified and its claims are checked individually.

