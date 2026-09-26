---
version: "1.0.0"
last_updated: "2026-06-10"
description: "Step 15: Observability Contract — wire per-feature instrumentation contracts before every ship; no feature leaves staging without traces and evals"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --feature-id
---

<!-- HITL-GATE-POLICY:start -->
## ⛔ HITL Gate Contract (read before running any phase)

This step is **human-in-the-loop**. Every `<HARD-GATE>` below is a **hard stop**. Obey these rules exactly — they override any default to "keep going."

**Runtime adapter:** `AskUserQuestion` below means the host's supported user-question mechanism, not a required tool identifier. Use an available structured question tool only when it permits this kind of question. Otherwise ask in a normal response and end the turn at the gate. A tool that cannot collect approval is not an approval substitute. Frontmatter controls are host-specific: supported `allowed-tools` can preapprove tool access. Tool access does not authorize actions outside the user's scope or satisfy a phase, release or production approval.

1. **Ask, then wait.** At each `<HARD-GATE>` you MUST call `AskUserQuestion` and receive an **actual answer from the user** before starting the next phase. Producing the analysis for a phase is allowed; *advancing past its gate* is not, until the user answers.
2. **A non-answer is NOT approval.** If `AskUserQuestion` returns no response, times out, or says the user is away — **PAUSE the step and wait**. Do not "proceed on best judgment," do not draft the remaining phases, do not infer approval from silence. Save what you have, tell the user the step is paused at Phase _X_ awaiting their answer, and stop. Re-ask when they return.
3. **One gate per phase — never collapse them.** Ask each phase's gate at its own phase boundary (A, then B, then C…). Do not batch several phases into a single question, and do not run multiple phases and ask once at the end. The founder decides at every boundary.
4. **The only way to skip gates** is an explicit, up-front instruction from the user in *this* run — e.g. "run all phases without stopping," "autonomous mode," or "don't ask me, just draft it." Absent that explicit opt-in, gates are mandatory. Being mid-task, low on time, or unattended is never such an opt-in.
5. **Everything before an approval is a draft.** Nothing a gate guards is "locked" or "done" until the user has approved it at that gate.

**Explicit unattended runs:** Record the user's opt-in and its scope once. Complete authorized phases and local verification without repeatedly asking for the same permission. Mark decisions made under that delegation as assumptions or delegated decisions, not fabricated user answers. Unattended drafting does not grant release, spending, destructive-action or production authority. A genuine missing decision may block one part while independent authorized work continues.

> If you find yourself about to write the next phase without a user answer to the current gate, STOP — that is the exact failure this contract prevents.
<!-- HITL-GATE-POLICY:end -->

<!-- GAME-DOMAIN:start -->
## Conditional game-domain adaptation

Apply this section only when `docs/stack-profile.json` records `projectDomain: "game"`. A missing value means `general`; do not infer a game domain from product language. Keep this step's number, phases, outputs, gates, business functions, GTM, context, and handoff intact.

Read the selected entry from the canonical game-development catalog when it is available. Use only the workflows and questions applicable to the recorded game profile. If applicability is unknown, record it as unresolved; defer or skip work only with a reason. The catalog adapts this step. It does not create an alternate numbered sequence.

- Default to a solo creator. Contributor idea packs are separately authored, workspace-visible planning inputs; synthesis is an explicit creator decision that preserves selected revisions, attribution, disagreement, and rejected alternatives.
- Treat prototypes, art, audio, engine setup, imports, builds, performance measurements, multiplayer checks, and playtests as external execution. This Protocol step may prepare a decision, brief, checklist, or evidence requirement. Mark execution evidence `NOT-EXECUTED` until real evidence is attached and reviewed.
- Choose the smallest experiment that tests the current uncertainty. Do not require paper prototypes, outside testers, fixed art freezes, an engine, a team size, a schedule, or a downstream production method unless the creator records why it applies.
- Keep claims classified: source text, observed evidence, source claim, untested integration, or proposed adaptation. Preserve the catalog source IDs and linked research when creating game artifacts.

<!-- GAME-DOMAIN:end -->

<!-- SKILLS-INVOKE:start -->
## Required skills — invoke the live skills (do NOT rely on embedded summaries)

This step's output quality depends on these skills. **Invoke each via the host's installed Skill catalog by name at the relevant phase.** If the host cannot resolve that name, read the project source at `src/skills/<skill>/SKILL.md`, then the bundled `.agents/skills/<skill>/SKILL.md` when present. Do not rely on embedded summaries.

- `game-development` — conditional when `projectDomain: "game"`; select this step's catalog entry and applicable workflow

- `observability`
- `quality-gates`

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-15-observability-contract — Per-Feature Instrumentation Contract

**On start, announce:** "Running Step 15: Observability Contract. I'll write an Instrumentation Contract for every feature before it ships — defining success metrics, trace points, eval set references, and kill conditions. No feature leaves staging without this contract."

# Runtime policy (platform-agnostic)

Sigma Protocol ships as **canonical sources**, not per-vendor mirrors:

| Layer | Path | Role |
|-------|------|------|
| Steps | `steps/` | Canonical step contracts (phases, HARD-GATEs, SKILLS-INVOKE) |
| Rendered commands | `commands/` | Expanded step files (partials inlined) for slash-command import |
| Authored skills | `src/skills/<category>/<skill>/SKILL.md` | Invoke via Skill tool at the phase listed in each step |
| Authored agents | `src/agents/<category>/<agent>.md` | Project agent definitions for Step 14 dispatch |
| Project brain | `AGENTS.md` | Cross-agent project context (Step 12 output) |
| Runtime state | `.sigma/runtime/`, `.sigma/memory/`, `.sigma/tools/` | Step 14 scaffold |

**Do not** duplicate canonical content into per-vendor mirror trees. Native discovery adapters are allowed: a thin `CLAUDE.md` containing `@AGENTS.md`, skill installation into a supported discovery directory, and host-specific agent configuration. Keep one instruction body; record adapter ownership. Operators control CLI permissions, hooks, models and MCP configuration.

**Skill invocation rule:** Resolve listed skills from the installed catalog. This repository authors skills in `src/skills/` and also ships bundled-only skills in `.agents/skills/`; generated projects may use category directories. Read only the skill and references relevant to the phase. Missing skill → state the gap; do not silently pretend it ran. Claude tool names in examples map to the current host's equivalent capabilities; never invent a tool or grant permissions from a document.

**Research rule:** Use built-in web search. Do not require Exa, Firecrawl, or operator-local storage paths.

**Evidence and freshness:** Verify changing framework, model, library and legal claims against primary sources. Record the URL, publication/version when available, review date, and the concrete decision affected. Distinguish a foundational method from a new revision; do not label an entire skill current because one source was checked. Illustrative dates and numbers must not become live receipts.

<goal>
You are the Observability Lead. Execute ALL phases (A through D) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Feature Import & Instrumentation Inventory | Confirmed feature list + existing trace coverage gap |
| B | Contract Design per Feature | Success metric, leading indicators, cost meter, trace points, eval ref |
| C | INSTRUMENTATION-CONTRACT.md Generation | Master contract doc + per-feature entries |
| D | Ship Gate Verification + Hardening | Gate check, $holes pass, CI wire-up notes |

Required Outputs:
- `docs/observability/INSTRUMENTATION-CONTRACT.md` (master contract + per-feature entries)
- Per-feature trace point stubs referenced in TASKS.md / PRD Section 12 agentic notes

Quality gate: every feature has a kill condition and at least one success metric with a pass threshold.

**Ship gate (non-negotiable):** A feature that passes the Step 14 runtime checks but has no Instrumentation Contract is not shippable. The contract is the difference between "we deployed it" and "we know it's working."
</goal>

---

## Step Boundary

- **Step 15 owns:** Instrumentation Contract per feature, success metrics, leading indicators, cost budgets, eval set references, trace point specifications (tool calls, model calls with tokens/latency/cost, HITL checkpoints), dashboard URL stubs, kill conditions, and the ship gate.
- **Step 15 does NOT own:** implementation of the traces (that is the implementing agent's job per Section 12 of each PRD), eval golden task authorship (Step 11's Eval Contract section), runtime wiring (Step 14), or dashboard creation.
- **Do NOT** duplicate PRD content. The Instrumentation Contract cross-references PRD sections — it does not re-author them.

---

## Observability Hierarchy

Every feature contract covers three layers:

### Layer 1: Business Success Metrics
What does "working" look like to the user and the business?

| Field | Definition |
|-------|-----------|
| `success_metric` | The primary KPI — a single, measurable number (e.g., "7-day retention ≥ 40%") |
| `pass_threshold` | The value that means the feature is working (e.g., "> 35% at D7") |
| `leading_indicators` | Signals visible within hours, not weeks (e.g., "onboarding completion > 70%") |
| `kill_condition` | If this threshold is breached, the feature is rolled back immediately |

### Layer 2: Cost Budget
Every agent-assisted feature has a cost dimension.

| Field | Definition |
|-------|-----------|
| `cost_meter` | Unit: cost per primary action (e.g., "≤ $0.003 per AI generation") |
| `token_budget` | Max tokens per session/request for model-calling features |
| `cost_alert_threshold` | Percentage above cost_meter that triggers an alert |

### Layer 3: Trace Points
What must be instrumented at the code level?

| Trace Type | What to Capture |
|------------|----------------|
| **Tool calls** | Tool name, input size, output size, latency ms, success/error |
| **Model calls** | Model id, prompt tokens, completion tokens, total cost, latency ms, error rate |
| **HITL checkpoints** | Checkpoint id, user action (approve/reject/modify), latency to response |
| **Feature entry** | Feature id, user id (hashed), session id, timestamp |
| **Feature exit** | Feature id, outcome (success/error/abandoned), duration ms |

For agentic features, also correlate `workflow_id`, `task_id`, `parent_task_id`, `agent_id`, subject/tenant, tool server, approval checkpoint, retry attempt, and outcome. Keep operational telemetry separate from eval telemetry: traces show what occurred in production; eval fixtures decide whether behavior meets the PRD. Apply the project's data policy before export: redact prompts, tool arguments, tokens, and PII as required.

Use a versioned telemetry vocabulary. Record the selected OpenTelemetry semantic-convention version and label experimental GenAI attributes as opt-in; do not assume `gen_ai.*` fields remain stable. Reference checked 2026-09-19: [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/).

---

## INSTRUMENTATION-CONTRACT.md Specification

### Master file header

```markdown
# Instrumentation Contract
<!-- generated by step-15-observability-contract -->
<!-- updated: YYYY-MM-DD -->

## Ship Gate Policy

No feature leaves staging without a completed Instrumentation Contract entry here.
Deployment pipeline check: `docs/observability/INSTRUMENTATION-CONTRACT.md` must
contain a `status: contracted` entry for every feature being deployed.

## Summary

| Feature | Success Metric | Kill Condition | Status |
|---------|----------------|----------------|--------|
| F01-auth | Login success rate ≥ 99% | < 95% for 10 min | contracted |
```

### Per-feature contract entry format

```markdown
## [F-ID]: [FEATURE-NAME]

**PRD:** docs/prds/F[N]-[FEATURE-NAME].md
**Status:** contracted | pending | waived (requires operator sign-off)
**Contracted on:** YYYY-MM-DD
**Telemetry convention:** OpenTelemetry GenAI [version] | experimental attributes: [none/list]
**Data policy:** [redaction policy and retention owner]

### Success Metric
- **Primary:** [single measurable KPI]
- **Pass threshold:** [value that means working]
- **Measurement window:** [e.g., "first 48h post-deploy", "rolling 7-day"]
- **Data source:** [where this number comes from — analytics dashboard, log query, etc.]

### Leading Indicators
[2-3 signals measurable within hours of deploy]
- [Indicator]: target [value], alert if [threshold]
- [Indicator]: target [value], alert if [threshold]

### Cost Budget (if model-calling or tool-invoking)
- **Cost per primary action:** ≤ $[N]
- **Token budget per request:** [N] prompt + [N] completion
- **Cost alert threshold:** alert if > [N]% above budget for [N] consecutive requests
- **Cost tracking:** [where: e.g., "LLM observability span `gen_ai.usage.*`"]

### Kill Condition
> If [condition], roll back feature flag for this feature within [time window].

Examples:
- Error rate > 5% for 10 consecutive minutes → auto-rollback
- Cost > 2× budget for > 100 requests → pause + alert operator
- Primary success metric < [kill threshold] at [measurement window] → escalate + manual review

### Eval Set Reference
- **Eval contract location:** PRD Section [N] — Eval Contract
- **Golden task file:** docs/evals/[feature-id]-golden.json (if authored)
- **Judge model:** [model id] (must differ from generator model)
- **CI gate:** eval suite must pass before staging deploy

### Trace Points

#### Workflow correlation (agentic features only)
| Trace name | Required attributes | Redaction / alert condition |
|------------|---------------------|-----------------------------|
| `workflow.[operation]` | `workflow_id`, `task_id`, `parent_task_id`, `agent_id`, `subject_hash`, `tenant_id`, `retry_attempt`, `outcome` | No raw prompt/tool payload; alert on retry/cancel policy breach |

#### Tool calls
| Trace name | Span attributes | Alert condition |
|------------|----------------|-----------------|
| `tool.[name]` | `tool.name`, `input.tokens`, `output.tokens`, `duration_ms`, `error` | error rate > 2% |

#### Model calls
| Trace name | Span attributes | Alert condition |
|------------|----------------|-----------------|
| `gen_ai.[operation]` | `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.prompt_tokens`, `gen_ai.usage.completion_tokens`, `gen_ai.usage.cost_usd`, `duration_ms` | cost > budget; latency > [N]ms p95 |

#### HITL checkpoints
| Checkpoint id | What user decides | Latency target | Escalation if no response |
|---------------|------------------|----------------|--------------------------|
| `[checkpoint-id]` | [approve/reject/modify] | ≤ [N] min | [escalation action] |

#### Protocol-specific traces (only when applicable)
- MCP: tool server, authorization result, error class, and latency.
- A2A: task lifecycle, Agent Card/version, authentication result, and artifact delivery.
- ACP: session and permission events for an IDE integration.

### Dashboard URL
[URL to the feature's observability dashboard — e.g., PostHog feature flag dashboard, Grafana panel, Datadog notebook]

If dashboard not yet created: `PENDING — create before first production deploy.`

### Implementation Notes for Agents
When implementing this feature (per PRD Section 12), the implementing agent MUST:
1. Wrap every model call with an OpenTelemetry `gen_ai.*` span (attributes above).
2. Wrap every tool call with a `tool.*` span.
3. Emit a feature-entry event at the first user interaction.
4. Emit a feature-exit event with outcome and duration.
5. Respect the token budget — truncate context before exceeding it and log the truncation.
6. Never catch-and-swallow errors silently — all errors must emit a span with `error: true`.
7. Keep production spans and eval-run records distinct; both link to the contract version without copying sensitive payloads.
```

---

## Phase A — Feature Import & Instrumentation Inventory

### Upstream Requirements

| Artifact | Source Step | Required |
|----------|-----------|----------|
| `docs/prds/F[N]-[FEATURE-NAME].md` | Step 11 | **Yes** — Eval Contract section (Section 13, added in v3.0+) |
| Tracker issues (`wave:*`, `eng-task`) — or `.sigma/backlogs/implementation/TASKS.md` for offline tracking | Step 11.5 | Conditional — task list for contract status cross-check. If Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json), read the wave-labeled Linear issues per `steps/_partials/linear-tracking.md`; otherwise read the project's wave-labeled GitHub Issues or fall back to `TASKS.md`. Never the retired SigmaHQ kanban. |
| `docs/specs/AGENT-RUNTIME.md` | Step 14 | Advisory — understand what runtime tooling is already wired |
| `docs/observability/INSTRUMENTATION-CONTRACT.md` | Step 15 (prior run) | Conditional — if file exists, update it rather than overwrite |

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read all `docs/prds/F[N]-*.md` — extract feature IDs and check for Eval Contract sections.
3. If `docs/observability/INSTRUMENTATION-CONTRACT.md` exists: read it, identify features already contracted, flag gaps.
4. If no PRDs exist → halt: "Step 15 requires approved Step 11 PRDs. Run Step 11 first."

**Gap report:** For each feature, report:
- `has_eval_contract`: yes | no (from PRD Section 13 or equivalent)
- `has_trace_points`: yes | no (from PRD Section 12)
- `has_kill_condition`: yes | no (from PRD Section 11)
- `contract_status`: contracted | pending

<HARD-GATE>
Do NOT proceed to Phase B until user approves the feature + gap inventory.
Use AskUserQuestion: "Found [N] features needing contracts. [M] have partial instrumentation. Proceed?"
Options: [Proceed — write all contracts, Write P0/P1 features only, Write specific feature (--feature-id), Review gaps first]
</HARD-GATE>

---

## Phase B — Contract Design per Feature

For each feature (in priority order P0 first):

1. Read PRD Section 1 (Problem & Outcome) → derive `success_metric` and `pass_threshold`.
2. Read PRD Section 11 (Rollout, Metrics & Risks) → import `success metrics` and `risks` — these inform `leading_indicators` and `kill_condition`.
3. Read PRD Section 6 (API / Server Action Contract) → identify all model calls and tool invocations → enumerate trace points.
4. Read PRD Section 13 (Eval Contract, if present) → import eval set reference.
5. Check PRD Section 9 (Security) → identify HITL checkpoints (any action requiring user confirmation before execution).
6. If the feature calls a language model: compute the token budget from the PRD context window spec or Step 8 technical spec.
7. For agentic features, define workflow/task correlation and required redaction. Add MCP, A2A, or ACP fields only when Step 2/8 selected that boundary.

### Cost budget derivation

If the PRD does not specify a token budget:
- S appetite features: default to 2,000 prompt + 500 completion per request.
- M appetite features: default to 8,000 prompt + 2,000 completion per request.
- L appetite features: default to 32,000 prompt + 8,000 completion per request.
- Note: "Defaulted from appetite. Update when actual usage data is available."

---

## Phase C — INSTRUMENTATION-CONTRACT.md Generation

Write or update `docs/observability/INSTRUMENTATION-CONTRACT.md`.

**Create `docs/observability/` if it does not exist.**

Writing order: P0 features first, then P1, P2, P3 within each group.

**Update behavior:** If the file already exists, append new feature entries and update the summary table. Never overwrite contracted entries — only update entries with `status: pending`.

### Cross-reference into PRD agentic notes

For each PRD that has a new Instrumentation Contract, add a cross-reference to PRD Section 12:

```markdown
**Observability Contract:** docs/observability/INSTRUMENTATION-CONTRACT.md#[F-ID]-[FEATURE-NAME]
The implementing agent MUST instrument all trace points listed there before opening a PR.
```

This is a write-back — update the PRD file with the cross-reference line. If the PRD already has this line, skip.

---

## Phase D — Ship Gate Verification + Hardening

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` on each contract entry to find:
- Missing kill conditions (every feature must have one).
- Success metrics with no pass threshold.
- Trace points with no alert condition.
- Model-calling features with no cost budget.
- Agentic features missing telemetry convention/version, workflow correlation, redaction, or applicable protocol lifecycle evidence.
- HITL checkpoints with no escalation path.
- Dashboard URLs marked PENDING (flag — they must be created before first production deploy).

Fix all findings before proceeding.

### CI Wire-up Notes

Add a `docs/observability/CI-WIRE-UP.md` stub (or update it if it exists) with:

```markdown
# Observability CI Wire-Up Notes

## Ship Gate Check

Before any staging deploy, the pipeline MUST verify:
1. `docs/observability/INSTRUMENTATION-CONTRACT.md` contains `status: contracted`
   for every feature being deployed.
2. The eval suite for each contracted feature passes (see Eval Contract in each PRD).
3. No model-calling feature is deployed without `gen_ai.*` spans in the diff.
4. Agentic features declare telemetry convention/version, redaction, workflow correlation, and only the protocol fields that apply.

## Instrumentation Checklist (per feature PR)

- [ ] Feature entry/exit events emitted
- [ ] All model calls wrapped with `gen_ai.*` spans
- [ ] All tool calls wrapped with `tool.*` spans
- [ ] Token budget respected (add truncation log if exceeded)
- [ ] HITL checkpoints emit spans with user action + latency
- [ ] Kill condition is reachable (the metric that triggers it is being measured)
- [ ] Production telemetry and eval evidence are stored and judged separately
```

### Writing Standards

- Kill conditions use concrete numbers: "error rate > 5% for 10 consecutive minutes" — not "error rate is too high."
- Cost budgets are unit-denominated: "≤ $0.003 per AI generation" — not "should be cheap."
- Dashboard URLs are real paths or `PENDING` — never placeholder text.
- No AI-isms: no "comprehensive observability," "robust monitoring," "seamless tracing."

### Success Criteria

- [ ] One contract entry per Step 11 PRD-eligible feature
- [ ] Every entry has a success metric with a pass threshold
- [ ] Every entry has a kill condition with a concrete trigger
- [ ] Every model-calling feature has a cost budget and token budget
- [ ] Every HITL checkpoint is listed with escalation path
- [ ] All trace point spans use OpenTelemetry `gen_ai.*` / `tool.*` naming
- [ ] Agentic entries record telemetry version, redaction, workflow correlation, and applicable protocol traces
- [ ] Dashboard URLs present (or PENDING with a note)
- [ ] CI-WIRE-UP.md updated
- [ ] PRD Section 12 cross-references written back
- [ ] $holes pass completed
- [ ] User approved the contract

<HARD-GATE>
FINAL GATE — Do NOT mark Step 15 complete without explicit approval.
Use AskUserQuestion: "Instrumentation Contracts complete for [N] features. Ready to ship?"
Options: [Approve — proceed to deploy, Review specific feature contract, Revise cost budgets, Update dashboard URLs]
</HARD-GATE>

### Downstream Handoff

Step 15 produces artifacts consumed by:

| Artifact | Consumed By | Purpose |
|----------|-------------|---------|
| `docs/observability/INSTRUMENTATION-CONTRACT.md` | Implementing agents (PRD Section 12), deploy pipeline, operator | Ship gate, runtime accountability |
| `docs/observability/CI-WIRE-UP.md` | CI/CD pipeline | Pre-deploy checklist |
| PRD Section 12 cross-references | Implementing agents | Trace point implementation requirements |

### Go-To-Market handoff → `/gtm` (natural next phase)

After Step 15 approval, the **Build Track is complete** — the product is planned end to end. The methodology now flows into go-to-market the same way Step 1 flows into Step 1.5: the natural next move is **`/gtm`**, the Go-To-Market conductor.

`/gtm` owns the launch motion and sequences the Run Tracks (`/run-marketing`, `/run-sales`, `/run-growth`, and the rest) — it is the conductor across them, not a parallel track. Under the hood the walkthrough engine still drives one `/run-*` department at a time.

<HARD-GATE>
Do NOT auto-start go-to-market. Run the continuation engine, then ask:

```bash
python3 scripts/run-track-continue.py
```

Use AskUserQuestion: "Build Track complete. Move into go-to-market with `/gtm` now?"

- **Yes → `/gtm`** — hand off to the GTM conductor, which sequences the Run Tracks (starts with `/run-legal` L0 entity formation).
- **Not yet** → `@dev-loop` or pause.
- **Skip a department** → `python3 scripts/run-track-continue.py --mark-declined {dept}`

This gate obeys the HITL Gate Contract at the top of this step: a non-answer is a pause, not a proceed.
</HARD-GATE>

Full rules: `steps/_partials/run-track-continuation.md` · `@continue --source=run-track`

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 15 Verification Schema

### Required Outputs (40 points)
| Item | Path | Points |
|------|------|--------|
| Instrumentation contract | docs/observability/INSTRUMENTATION-CONTRACT.md | 20 |
| CI wire-up notes | docs/observability/CI-WIRE-UP.md | 10 |
| PRD Section 12 cross-refs | docs/prds/*.md | 10 |

### Quality (35 points)
| Check | Points |
|-------|--------|
| Success metric + kill condition per feature | 12 |
| OTel span naming on trace points | 8 |
| Cost/token budgets on AI features | 8 |
| $holes pass completed | 7 |

### Pass Threshold
95/100 minimum.
</verification>

$END$
