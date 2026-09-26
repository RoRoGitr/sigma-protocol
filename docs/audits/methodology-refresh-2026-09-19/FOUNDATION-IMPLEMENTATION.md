# Foundation implementation: Steps 0, 11.5, 12, and 13

Date: 2026-09-19  
Scope: local methodology-source updates only. No global installation, rendered-command sync, or commit was performed.

This implements the applicable recommendations in [FOUNDATION-RESEARCH.md](FOUNDATION-RESEARCH.md). The existing hard gates remain in place; this update changes the evidence each gate must review, rather than adding gates.

| Step and gate | Retained | Change made | Evidence required at the gate |
|---|---|---|---|
| 0 A — mode and runtime | Three-mode classification and canonical-surface check | Requires a consuming-project baseline before mutation: root, branch/HEAD, dirty state, instructions, generated artifacts, package manager, lockfile, runtime versions, commands, timestamps, and results. Mode records its predicate. | Baseline evidence and canonical-surface status; brownfield without a map is visible. |
| 0 B — research stack | Provider-neutral research | Replaces a tool-presence test with source quality, freshness, ref/version, URL, and confidence. Adds optional Pen, Taste, Designscape, and host-preview probes without selecting a universal renderer. | Source-quality matrix and held claims for reduced research. |
| 0 B.2 — fusion | Optional provider setup and no committed secrets | Retained. Existing provider/privacy receipt requirements remain the evidence boundary. | Provider, model/version, authorization path, data boundary, capability, and explicit skip reason. |
| 0 C — integrations | Non-blocking integration recommendations | Boilerplate suggestions must be checked against manifests, lockfiles, deployment config, environment names, and imports; state is configured, present-but-unused, planned, or unknown. | Detected file/symbol or explicit proposal; no detection-time install. |
| 0 C.1 — scaffold | New-project-only scaffold path | Requires package-manager/lockfile detection, exact versions, official compatibility check, expected diff, and separate PREPARED, EXECUTED, and SMOKE_TESTED states. | Approved stack/profile, command and diff, compatibility evidence, smoke-test receipt or PREPARED status. |
| 0 D — minimal baseline | Minimal owned directories | Retained; mutation remains scoped to Step 0-owned paths. | Created-path evidence and unchanged downstream surfaces. |
| 0 E — state | Human and machine baseline records | Adds baseline evidence, source quality, execution-time timestamps, and VERIFIED/WARN/PREPARED/BLOCKED status. | Valid JSON, current execution timestamp, blockers, and evidence references. |
| 11.5 A — PRD import | Approved PRD filtering and verbatim extraction | Ambiguity becomes `BLOCKED / clarification required`, and entries carry recoverable source hashes and extraction metadata. | Approved PRD section/requirement mapping and ambiguity list. |
| 11.5 B — dependencies | Cycle detection and explicit `none` | Dependency edges carry declared/structural/inferred provenance and confidence; conditional relations are not overstated. | Deterministic acyclic graph with source/reason for every edge. |
| 11.5 C — TASKS.md | Markdown queue and optional JSON mirror | Adds source, reservation receipt, lease/recovery policy, and `NOT-EXECUTED` test reasons. | Each task can be traced to source and validated without invented requirements. |
| 11.5 D — loop and hardening | Selection does not reserve a task | Removes the false last-writer-wins atomic-claim rule. Concurrent execution now requires an existing coordinator, transactional tracker claim, lock, or isolated-worktree reservation; otherwise the queue is explicitly queue-only. | Reservation receipt, deterministic idle result, recovery policy, or `QUEUE_ONLY / concurrent execution unsupported`. |
| 12 A — context import | Upstream artifact import and managed-surface detection | Requires root and nested loading probes, per-host scope/precedence maps, and explicit loaded/unloaded results. | Probe receipt, source-of-truth map, conflict rule, and unsupported imports. |
| 12 B — section plan | DNA/skills separation and concise managed context | Replaces informal brevity with measured cumulative context/retrieval cost. Each instruction records owner, scope, freshness, destination, and source-versus-inference status. | Budget report, one-hop references, contradiction and unknowns report. |
| 12 C — synthesis | Managed-block-only AGENTS synthesis and policy preservation | A CLAUDE adapter is written only when a loading probe supports it. Visual output uses detected source-of-truth paths and optional renderer receipts. | Fresh-runtime load receipt and rule-to-source or authorized-decision mapping. |
| 12 D — memory bridge | No second project store and no secrets | Memory writes now carry authorization, provenance, retention, redaction, and rollback metadata; user entries are preserved absent authorized migration. | Reviewable write receipt and usable project state after sync failure. |
| 12 E — verification | Runtime verification and Step 13/14 handoff | Adds root/nested loading, context-budget, contradiction, and source/inference checks. | No unresolved paths or contradictory managed blocks; loaded, omitted, and held state reported. |
| 13 A — inventory | Canonical-source-first inventory | Adds host-scope, plugin, collision, source/ref, license, dependency, and activation-surface inventory. | Owner, scope, version/ref, license, dependency, activation, collision record per active item. |
| 13 B — plan and eval baseline | DNA/skills classification and trigger testing | Replaces universal prompt counts with risk-proportionate positive and negative cases, deterministic checks where possible, and reproducible evaluation evidence. | Trigger/non-trigger, artifact, failure behavior, rubric/fixture version, and receipt. |
| 13 component bundle | Stack-conditional methodology bundle | Rendering tools are optional adapters with owner source and local capability proof; no mandatory renderer is introduced. | Capability probe, portable artifact, tool receipt, and fallback. |
| 13 C — authored source | Portable Agent Skills core and progressive disclosure | Adds pinned upstream/ref or checksum, license, support, tool/secret/network risk, changed-file review, rollback, and host-scoped dynamic context. | Structural validation plus provenance and risk receipt. |
| 13 D — agent assignment | Tracker-aware mapping | Retained; tracker behavior remains conditional on configured capability. | Approved mapping or documented manual fallback. |
| 13 E — verification/handoff | Index coherence, boundary checks, and Step 14 handoff | Adds supply-chain and risk-proportionate evaluation verification. | Active entries validate structurally and have provenance, license, evaluation evidence, and no unresolved dependency. |

## References applied

- [Foundation research](FOUNDATION-RESEARCH.md): Step 0 gates A–E, Step 11.5 gates A–D, Step 12 gates A–E, and Step 13 gates A–E.
- [Agent Skills specification](https://github.com/agentskills/agentskills/blob/main/docs/specification.mdx): portable `SKILL.md` core and progressive disclosure.
- [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents): measured context and just-in-time detail.
- [Anthropic contextual retrieval](https://www.anthropic.com/engineering/contextual-retrieval): source/inference separation and retrieval evaluation.
- [OpenAI Agents SDK tracing](https://github.com/openai/openai-agents-python/blob/main/docs/tracing.md): evidence receipts as an optional, not universal, runtime model.

## Local checks

- `bash tests/test_step_skill_gate.sh` — verifies the existing hard-gate contract.
- `bash scripts/lint-step-parity.sh` — verifies canonical step/rendered-command parity only after an explicit sync; not run here because rendered commands are outside this partition.
- `rg -n "QUEUE_ONLY|baseline_evidence|source-versus-inference|capability probe" steps/step-0-environment-setup steps/step-11.5-task-handoff steps/_partials/step12-canonical-body.md steps/step-13-skillpack-generator` — confirms the foundation requirements are present in the canonical sources.
