# Architecture and Agent Runtime Research

**Date:** 2026-09-19  
**Scope:** Steps 2, 8, 11, 14, and 15  
**Status:** Research ledger; no source-step edits made in this pass.

This pass separates durable method from vendor tooling. A project should add an agent runtime only when its product or operations require autonomous, multi-step, tool-using work. Next.js, Eve, Hermes, OpenClaw, ACP, A2A, and MCP are different layers and must not be treated as interchangeable.

## Protocol map

| Protocol or product | Boundary it addresses | Maturity observed on 2026-09-19 | Sigma treatment |
|---|---|---|---|
| MCP | Model/client to tools, resources, and prompts | Current protocol family; 2026 release candidate adds stateless core, Tasks, MCP Apps, and authorization hardening | Use for tool/resource integration when the project needs it. Keep OAuth and per-tool authorization explicit. |
| A2A | Agent-to-agent task exchange and discovery | Released 1.0 is documented; async tasks, Agent Cards, artifacts, auth, and tracing are part of the model | Use only for independently deployed agents. Do not use it for local subagents or ordinary service calls. |
| ACP | Code editor/client to coding-agent session | ACP v1 is stable; ACP v2 is explicitly draft/experimental | Consider at an IDE integration boundary. Do not call it an agent-to-agent protocol. |
| Vercel eve | Filesystem-first framework for durable agents on Vercel | Public preview; Vercel documents durable execution, sandboxing, approvals, subagents, and evals | Optional Step 8/14 implementation choice. Never make it the architecture default or call it a Next.js replacement. |
| Hermes Agent | Provider-agnostic personal/coding agent with skills, tools, memory, and channels | Active open-source project; its own docs recommend proving a clean base chat before layering features | Research reference for local operator control, allowlisted toolsets, and memory. No hard dependency. |
| OpenClaw | Open-source assistant/gateway project | Active project with rapid releases; operational maturity and security posture vary by deployment | Treat as an external runtime to evaluate, not a Sigma primitive. Require a threat and maintenance review before adoption. |

Primary sources: [MCP overview](https://modelcontextprotocol.io/specification/2025-06-18/server), [MCP 2026 release candidate](https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/), [A2A 1.0 specification](https://github.com/a2aproject/A2A/blob/main/docs/specification.md), [ACP protocol overview](https://github.com/agentclientprotocol/agent-client-protocol/blob/main/docs/protocol/v2/overview.mdx), [Vercel eve](https://vercel.com/blog/introducing-eve), [eve subagents and typed output](https://vercel.com/kb/guide/how-to-use-eve-subagents), [Hermes Agent quickstart](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/getting-started/quickstart.md), [OpenClaw](https://openclaw.ai/).

## Step 2 — Architecture

### Current gate trace

- Phase A approval: `steps/step-2-architecture:233-237`.
- Driver inventory and agentic constraints: `steps/step-2-architecture:241-278`, especially line 253.
- Options gate: `steps/step-2-architecture:282-311`.
- Required output includes deployment/runtime, trust boundaries, and an “Agentic Architecture Overlay”: `steps/step-2-architecture:395-420`.
- Success criteria require Step 14 handoff but do not require a reasoned “no agent runtime” decision: `steps/step-2-architecture:432-447`.
- Final approval: `steps/step-2-architecture:449-453`.

### Findings

1. **Retain evolutionary architecture, C4, ADRs, quality scenarios, and trust boundaries.** They are vendor-neutral and remain the right decision structure. The gap is that the current “Agentic Overlay” can sound mandatory even for a conventional product.

2. **Add an explicit agent-runtime applicability decision.** At Phase B, require one of: `none`, `embedded feature`, `internal automation`, or `independently deployed agent system`. The decision must name the trigger, data boundary, operator, and kill condition. A project with no autonomous workflow should record `none` and skip agent protocol design.

3. **Separate layers and protocols.** The architecture output should distinguish: frontend/experience, application/backend, workflow engine, model gateway, MCP tool servers, local coding-agent interface (ACP), and remote agent collaboration (A2A). MCP tools are model-controlled primitives; A2A exposes remote agent tasks and artifacts; ACP carries editor-agent sessions. This follows the primary protocol definitions above.

4. **Require identity propagation per user and per tool call.** The current trust-boundary language is good, but agent systems need an explicit subject, tenant, scopes, consent/approval state, and audit correlation ID at every tool boundary. MCP authorization documentation describes both server-level and per-tool OAuth patterns; A2A Agent Cards declare authentication requirements.

5. **Treat durable execution as a quality attribute, not a framework choice.** If work can outlive a request, require a resumable state machine, idempotent steps, cancellation, retry policy, and human approval resume point. Eve and A2A demonstrate the pattern, but the implementation may be a project-native queue/workflow system.

6. **Add protocol and vendor exit criteria to ADRs.** For each external runtime, record version, beta/preview status, data residency, auth model, deployment lock-in, export path, and replacement plan. Eve is explicitly public preview, while ACP v2 is explicitly draft.

### Acceptance evidence to add to the gate

- A one-page boundary diagram labels frontend, backend, agent runtime (if any), MCP, A2A, and ACP correctly.
- A table maps each tool/remote agent to caller identity, scopes, approval requirement, data touched, and audit ID.
- If an agent runtime is selected, a failure test demonstrates resume after process restart and safe retry of an idempotent step.
- If no agent runtime is selected, the architecture records the reason and shows Step 14 as deferred/skipped.

## Step 8 — Technical specification

### Current gate trace

- Step 5 visual source detection only recognizes Claude Design bundles or HTML screens: `steps/step-8-technical-spec:129-156`, especially lines 142-153.
- Stack research directives: `steps/step-8-technical-spec:291-301`.
- Frontend/backend/contracts gate: `steps/step-8-technical-spec:305-404`.
- Security, testing, and operations gate: `steps/step-8-technical-spec:408-488`.
- Final gate: `steps/step-8-technical-spec:558-562`.

### Findings

1. **Replace the vendor-specific visual-source assumption with a visual-source registry.** The current wording makes `claude-design` Track A a privileged source. The technical spec should accept an approved source such as Pen, Taste Code, Figma export, generated HTML, or a repository-native prototype, with a path, version/date, viewport set, and acceptance status. Parent audit owns the design-tool decision; this ledger records the architecture impact.

2. **Keep Next.js conditional.** Vercel’s current agent material presents eve alongside Next.js and other frameworks. Eve is a durable-agent framework, not a replacement for frontend frameworks. Step 8 should choose Next.js, another web stack, or eve only from the stack profile and runtime need.

3. **Add typed tool and workflow contracts when applicable.** For an agent feature, specify tool input/output schemas, side effects, auth context, approval mode, timeout, retry/idempotency key, cancellation, and durable state. Vercel’s eve guidance specifically recommends typed child output schemas and says delegation is not an approval boundary.

4. **Make auth subject and tenant context part of backend contracts.** “Auth” must define how the authenticated user/tenant is carried through route → workflow → model/tool/A2A call, and how authorization is rechecked at the side-effect boundary. Do not treat a model or subagent identity as the user’s authorization.

5. **Add an agent-runtime separation section to the implementation blueprint.** It should state whether model calls run inline, in a durable workflow, or in a sandbox; what belongs in frontend streaming; and which actions require human approval. This prevents backend, frontend, and agent runtime concerns from being merged into one vague “AI” layer.

### Acceptance evidence to add to the gate

- Contract tests validate schemas and reject unknown/high-risk tool arguments.
- An auth test proves a user cannot access another tenant through a tool or remote agent.
- A restart/cancellation test proves durable work resumes or stops according to policy.
- The visual source table names the source tool without making that tool a runtime dependency.

## Step 11 — PRD generation

### Current gate trace

- PRD is treated as executable spec and requires an independent verifier: `steps/step-11-prd-generation:88-104`.
- Target approval: `steps/step-11-prd-generation:532-547`.
- Eval contract and per-feature review: `steps/step-11-prd-generation:575-585`.
- Verifier requirements: `steps/step-11-prd-generation:602-625`.
- `approved: true` requires verifier plus operator approval: `steps/step-11-prd-generation:668-678`.
- Final schema/approval gate: `steps/step-11-prd-generation:912-916`.

### Findings

1. **Retain the judge/generator separation and golden-task structure.** OpenAI’s current API documentation supports eval runs, structured data sources, and model/tool configuration; OpenAI also recommends pinned model versions and evals because prompting behavior can change between snapshots. Add model snapshot, tool version, and fixture version to the Eval Contract.

2. **Do not require a different vendor as a universal rule.** Independence is the goal. A different model, a deterministic checker, or a dedicated verifier can satisfy the role when documented. The current “structurally different” wording may overfit provider diversity and can make offline projects impossible to verify.

3. **For agent features, extend golden tasks beyond final text.** Include tool-call arguments, authorization decisions, approval pauses, retry/resume behavior, side-effect idempotency, and trace assertions. A PRD should state whether the feature is an agent at all.

4. **Keep PRDs vendor-neutral.** A PRD may select eve, Hermes, OpenClaw, MCP, A2A, or ACP only when the architecture and stack profile have already made that boundary decision. The PRD must preserve a fallback or explicitly document lock-in.

### Acceptance evidence to add to the gate

- Eval fixture records generator model snapshot, verifier, tool schemas, and expected side effects.
- At least one adversarial task attempts prompt injection or unauthorized tenant access when tools are exposed.
- At least one interrupted-task fixture checks resume/cancel semantics for durable work.
- A deterministic schema/permission check can run without a model; model judging is not the only evidence.

## Step 14 — Agent runtime bootstrap

### Current gate trace

- Host capability detection and runtime-input gate: `steps/step-14-agent-runtime-bootstrap:123-139`.
- Cross-model evaluation policy: `steps/step-14-agent-runtime-bootstrap:275-304`.
- Current Magentic/concurrent/maker-checker framing: `steps/step-14-agent-runtime-bootstrap:306-314`.
- MAESTRO threat pass: `steps/step-14-agent-runtime-bootstrap:316-325`.
- Compound-learning approval boundary: `steps/step-14-agent-runtime-bootstrap:469-483`.
- Metadata-first skill loading and graph gates: `steps/step-14-agent-runtime-bootstrap:618-637`.
- Pass threshold: `steps/step-14-agent-runtime-bootstrap:790-799`.

### Findings

1. **Retain capability detection, bounded loops, independent review, circuit breakers, human-gated learning, and evidence-bearing completion.** These are strong harness practices and do not depend on a vendor.

2. **Split “local coding-agent host” from “product agent runtime.”** Claude Code and Codex are operator/development hosts. Eve, Hermes, OpenClaw, or a project-native workflow are product/runtime choices. Step 14 must not imply that installing a coding-agent host creates a production agent runtime.

3. **Clarify protocol selection.** Use ACP for editor↔coding-agent sessions; use MCP for tool/resource exposure; use A2A for remote agent task exchange. Local subagents can use the host’s native task primitive and do not need A2A.

4. **Make typed outputs and approval placement mandatory for delegated work.** Eve’s primary guidance says child agents should return structured output and that delegation itself is not an approval boundary. Sigma should require schema-validated child results and put approval on the sensitive tool/route/session boundary.

5. **Do not hardcode “Microsoft’s three patterns” as the only runtime model.** Keep the useful behaviors—dynamic task ledger, parallel isolation, maker-checker—but describe them as selectable orchestration patterns. Record why a pattern applies and its rollback/escalation behavior.

6. **Downgrade unverified numeric claims.** The line tying vulnerability rates to a “CodeRabbit 2025 study” is not a primary normative source. Keep the threat register requirement, but make the claim source-backed or remove the multiplier.

7. **Graph gates are conditional.** `impact()`, `detect_changes()`, `query()`, and `context()` are useful if the host/project actually exposes those functions. The current “when graph engine is available” qualifier is correct; acceptance must prove availability rather than assume it.

### Acceptance evidence to add to the gate

- Runtime manifest records detected host, task primitive, isolation, approval, event/wait, and model capabilities with command/UI evidence.
- Every delegated task has a typed result schema, scope, timeout, retry policy, and escalation path.
- A sensitive tool call pauses for approval even when invoked by a child agent.
- A fixture demonstrates circuit-breaker behavior after repeated failures and proves no silent self-modification.
- Protocol choice is recorded as `native`, `MCP`, `A2A`, or `ACP` with applicability evidence.

## Step 15 — Observability contract

### Current gate trace

- Contract ownership and ship gate: `steps/step-15-observability-contract:40-63`.
- Per-feature metrics, costs, eval reference, and trace points: `steps/step-15-observability-contract:125-180`.
- Gap approval gate: `steps/step-15-observability-contract:220-227`.
- CI ship checks: `steps/step-15-observability-contract:275-310`.
- Final approval and downstream handoff: `steps/step-15-observability-contract:335-347`.

### Findings

1. **Retain the contract/ship-gate model.** It correctly requires success metrics, kill conditions, cost budgets, eval references, model/tool traces, and HITL latency.

2. **Version the telemetry vocabulary.** OpenTelemetry currently separates GenAI semantic conventions from the general registry and documents stability/version selection. The contract should record the chosen semantic-convention version and mark development/experimental attributes as opt-in. Do not assume every `gen_ai.*` field is stable forever.

3. **Add workflow and agent identity correlation.** For agentic features, trace `workflow_id`, `task_id`, `parent_task_id`, `agent_id`, `tenant/user subject`, `tool server`, `approval checkpoint`, retry attempt, and outcome. Redact prompts, tool arguments, tokens, and PII according to the project’s data policy.

4. **Separate operational telemetry from eval telemetry.** Production traces show what happened; golden/eval runs show whether behavior is acceptable. A passing trace export is not an eval pass, and an eval pass is not proof of production health.

5. **Add protocol-specific ship checks only when applicable.** MCP calls need auth/error/latency traces; A2A needs task lifecycle, Agent Card/version, auth, and artifact delivery traces; ACP needs session/permission events if the project integrates an IDE. Ordinary features should not inherit these fields.

### Acceptance evidence to add to the gate

- CI checks telemetry schema/version and confirms required redaction fields.
- A trace fixture links parent workflow → child task → model call → tool call → approval → result.
- Alert and kill-condition tests show what happens when cost, latency, error rate, or eval score crosses threshold.
- Dashboard or query examples can locate a single user task without exposing sensitive prompt/tool payloads.

## Recommended ledger disposition

| Area | Disposition |
|---|---|
| Step 2 | Revise: add applicability decision, protocol boundary map, identity propagation, durable-workflow quality attribute, and vendor exit criteria. |
| Step 8 | Revise: generalize visual source, add typed tool/workflow/auth contracts, keep framework choice conditional. |
| Step 11 | Revise: pin model/tool versions, allow deterministic or same-vendor independent verification, extend agent evals to side effects and resume. |
| Step 14 | Revise: separate coding host from product runtime, define ACP/MCP/A2A correctly, require typed child results and approval at effect boundary, remove unsupported numeric claim. |
| Step 15 | Revise: version OTel GenAI conventions, correlate workflow/task/agent identity, separate eval from production telemetry, condition protocol fields. |

No framework should be added solely because it is prominent. The evidence required at each gate is the deciding mechanism.
