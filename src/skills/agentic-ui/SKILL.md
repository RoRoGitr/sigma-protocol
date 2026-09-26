---
name: agentic-ui
description: "Agentic UI and Generative UI patterns — intent preview, autonomy dial, explainable rationale, confidence signals, audit/undo, escalation. Use when Step 3 Decision 3 is Yes/Partially or PRDs include AI agent surfaces. Triggers on 'agentic ui', 'generative ui', 'ai agent ux', 'autonomy dial', 'intent preview', 'agent interface'."
triggers:
  - agentic ui
  - generative ui
  - ai agent ux
  - autonomy dial
  - intent preview
  - agent interface
  - confidence signal
---

# Agentic UI Skill

Design and specify interfaces where AI agents act on behalf of users. Use in **Step 3 Phase D** when agentic features are in scope, and in **Steps 7, 8, 11** when PRDs define agent surfaces.

## When to invoke

| Step | Trigger |
|------|---------|
| **3** | Decision 3: Yes or Partially for AI agent features |
| **4** | Flow inventory includes agent chat, tool approval, or autonomy settings screens |
| **7** | State specs for agent loading, plan preview, undo, escalation |
| **8** | Technical spec for agent orchestration UI boundaries |
| **11** | PRD vertical slice includes agent interaction |

## Core patterns (required when agentic)

| Pattern | Purpose | UX requirement |
|---------|---------|----------------|
| **Intent Preview** | Show plan before execution | Plain-language step list + approve / edit / run manually |
| **Autonomy Dial** | Progressive authorization | Observe → Suggest → Confirm → Autonomous (per task type) |
| **Explainable Rationale** | Trust for autonomous actions | "Because you said X, I did Y" — no black-box copy |
| **Confidence Signal** | Calibrate user trust | Visible certainty (not fake percentages); green/yellow/red or equivalent |
| **Action Audit & Undo** | Reversibility | Persistent timeline + undo window where technically feasible |
| **Escalation Pathway** | Avoid silent failure | Clarifying question, option picker, human handoff — never guess on high-stakes |

## Generative UI contract (DESIGN.md)

The design system is a **dual-audience contract** (human + coding agent):

- DNA invariants must be **machine-enforceable** (named fonts, color logic, motion physics, density).
- Anything an agent could guess wrong must be explicit in `DESIGN.md` / `ui-profile.json`.
- Step 6 exports tokens; Step 3 must eliminate aesthetic ambiguity before token work.

Record in `docs/design/ui-profile.json` when agentic:

```json
{
  "agenticUi": {
    "enabled": true,
    "defaultAutonomy": "confirm",
    "patterns": ["intent-preview", "autonomy-dial", "explainable-rationale", "confidence-signal", "action-audit", "escalation"]
  }
}
```

## Research (when needed)

Use **standard web search** for current patterns — do not require Exa or Firecrawl.

Example queries:
- `"agentic AI UX patterns" site:smashingmagazine.com OR site:nngroup.com`
- `"generative UI design system agent" 2025 2026`

## Anti-patterns

- Autonomous actions with no preview on irreversible operations
- Fake "AI confidence" percentages with no grounding
- Hiding agent errors behind generic "Something went wrong"
- Mixing agent chat UI with unrelated marketing components without DNA amplitude tags (`marketing` vs `app`)

## Sigma handoffs

- **Step 4:** Add screens — agent plan preview, autonomy settings, action log, escalation modal
- **Step 7:** Loading (planning), empty (no actions yet), error (tool failure), success (completed with undo)
- **Step 11:** BDD scenarios for approve/deny/edit-plan flows

Cross-reference: `companion-system` for gamification/collectibles (different domain from task agents).
