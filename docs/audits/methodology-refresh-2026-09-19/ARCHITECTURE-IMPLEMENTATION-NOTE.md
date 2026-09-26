# Architecture Method Implementation Note

**Date:** 2026-09-19
**Owned canonical steps:** 2, 8, 11, 14, 15
**Scope:** Architecture and runtime research ledger applied without changing gate boundaries or identifiers.

## Method applied

- Step 2 now requires an explicit product agent-runtime applicability decision and maps MCP, ACP, and A2A to their actual boundaries. It requires identity, tenant, scope, approval, idempotency, resume, and exit evidence where a runtime applies.
- Step 8 replaces a privileged design-generator assumption with an approved visual-source record (`kind`, path, snapshot, viewports, approval) and adds typed tool/workflow, authorization, cancellation, and durable-state contracts only for AI/tool-using features.
- Step 11 records model/fixture/tool versions and requires deterministic permission/schema plus side-effect, approval, and interruption evidence for agent features. The existing independent-model verifier requirement remains unchanged.
- Step 14 separates the coding-agent host from a product runtime, records protocol applicability and detected evidence, requires typed child results, and keeps approval on the sensitive effect boundary. No vendor runtime is required.
- Step 15 versions GenAI telemetry, separates operational traces from eval evidence, adds redaction and workflow correlation, and makes MCP/A2A/ACP fields conditional.

Primary-method links are located beside the relevant method sections in the five steps and were checked on 2026-09-19.

## Gate disposition

| Step | Existing HARD-GATE count | Disposition |
|------|--------------------------|-------------|
| 2 | 5 | Preserved. The import, driver, option, target-architecture, and final gates now require the selected runtime decision and evidence only when applicable. |
| 8 | 5 | Preserved. The import, implementation, frontend/backend, hardening, and final gates now include approved visual-source and AI/tool-workflow evidence when applicable. |
| 11 | 3 | Preserved. Target, per-feature, and final schema/approval gates retain the independent verifier and add deterministic/agent evidence. |
| 14 | 5 | Preserved. Inputs, plan, scaffold, wiring, and final gates now require detected host/runtime/protocol evidence; release, money, and human gates remain intact. |
| 15 | 3 | Preserved. Inventory, final contract, and GTM handoff gates now require version/redaction/correlation evidence only for applicable agentic features. |

**Total owned gates:** 21 preserved; 0 renamed, removed, collapsed, or automatically approved.

## Checks

- `rg -n '<HARD-GATE>|</HARD-GATE>' steps/step-{2,8,11,14,15}*` — confirms 21 opening and 21 closing tags.
- `bash scripts/lint-step-parity.sh` — correctly reports rendered-command and bundled-skill drift because this partition intentionally changes canonical `steps/` only; it reports 18 repository-wide mismatches and is not a pass condition until the rendering owner runs the sync.
