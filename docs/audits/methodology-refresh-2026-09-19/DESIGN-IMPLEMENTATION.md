# Design implementation disposition

Date: 2026-09-19. Scope: canonical Steps 3–7 only. Rendered commands and skill mirrors are deliberately not changed here.

## Gate disposition

| Step | Existing gates | Disposition | Concrete evidence at the gate |
|---|---:|---|---|
| 3 | 6 | Retained | Approved UX inputs; experience goals; journeys/IA; interaction and accessibility commitments; a short design read; `DESIGN.md` and `ui-profile.json`; final handoff. |
| 4 | 5 | Retained | Imported architecture/UX artifacts; approved flow model; screen/transition inventory; traceability and zero-omission results; final handoff. Agent-operated branches are required only when the product has agent behavior. |
| 5 | 6 | Retained | Selected Canvas or Direct artifact path; approved coverage plan; each flow's actual artifact and PRD; summary; zero-omission result; final handoff. Claimed renders, exports, and approvals must exist or be recorded as gaps. |
| 6 | 5 | Retained | Pattern audit and platform targets; approved token architecture; foundations/components; motion/accessibility/export strategy; DTCG output plus representative importer/render checks where available; final handoff. |
| 7 | 5 | Retained | State-surface classification; per-flow state model; recovery/accessibility behavior; cross-feature transitions; final state spec. Agent-output states apply only when such a surface exists. |

No gate was added. Existing approval rules remain authoritative.

## Artifact and consumer changes

| Change | Producers | Consumers | Check |
|---|---|---|---|
| Canvas path replaces the Claude-Design-specific path | Step 5 | Steps 6, 7, 11 | `visual-artifact/` has `VISUAL-ARTIFACT.md`, source path, actual export evidence when claimed, tool/provider/version, and approval evidence. |
| Direct path becomes platform neutral | Step 5 | Steps 6, 7, 11 | Inspect HTML, React Native, SwiftUI, or other recorded platform artifact; do not require HTML from native work. |
| Step 3 design read | Step 3 | Steps 4–6 | Direction comes from product, representative user/task, references and rejected defaults; Taste controls remain illustrative. |
| Agent-flow and agent-output coverage | Steps 4 and 7 | Steps 5, 8, 11 | Include preview, approval, execution, interruption, partial/refusal/uncertainty, recovery, audit/undo/escalation only where the product uses agent behavior. |
| Token provenance | Step 6 | Steps 7, 8, 11 | Validate DTCG syntax and the selected importer's actual format; inspect representative rendered components when possible. An exporter is optional. |

## Tool facts applied

- Pen is a suitable Canvas tool when available. Preserve a `.pen` source and a relevant actual export; do not imply the Pen CLI, authentication, or a particular export exists.
- Taste Skill supplies design-direction guidance. It does not make an artifact, render, approval, or business claim true.
- TasteCode is an optional beta desktop host. It is not a required protocol dependency or artifact format.
- Claude Design and Stitch remain operator-selected canvas adapters. They are not the default, a required prompt format, or a subscription/browser handoff.

## Checks run

```text
rg -n -i "claude design|claude-design|Track A|Track B|bundle|sliders|subscription" steps/step-{3,4,5,6,7}*
```

Result: no remaining Claude-Design-specific required flow, Track A/B branch, slider, subscription, or bundle contract in Steps 3–7. The remaining `Claude Design` mention identifies it only as an optional Canvas adapter. Dispatch "bundle" terminology remains unrelated to visual artifacts.

```text
rg -n "visual-artifact|Canvas|Direct|Agent-operated|Agent-output|design read" steps/step-{3,4,5,6,7}*
```

Result: the portable artifact, conditional agent-state, and brief-derived direction contracts are present across the affected canonical steps.

## Follow-up outside this partition

- Render the changed canonical sources into commands and skill-reference mirrors through the repository's normal sync process.
- Update the Step 9 landing-page path under its separate owner to match Canvas/Direct terminology.
- Validate an actual downstream implementation project before claiming that a specific DTCG importer, Pen export, or renderer works in that project.
