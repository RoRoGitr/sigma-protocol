# Design skill refresh — 2026-09-22

## Scope and result

Applied local changes to five canonical design skills, Steps 2–7, and the design-lead agent. Synced those skill files and the evaluation briefs into the repository’s `.agents/skills/` bundle; rendered the six steps into `commands/` and their bundled references. Earlier unrelated checkout changes were preserved. No commit, push, global installation or vendor Emil edit was performed in this task. This is a methodology update; it does not constitute another Sigma Atlas app redesign or release.

## Problems corrected

The source audit found conflicting requirements: expressive marketing defaults applied to workspaces; fixed font, surface and animation prescriptions; HTML-only prototype wording despite component/native stacks; and mandatory novelty/divergence requirements even when the user had selected a direction. The refreshed instructions require actual reference observations, compatible components, a representative working slice, and separate visual and interaction evidence.

| Source | Change |
| --- | --- |
| `src/skills/frontend-design/SKILL.md` | Product-category routing; reference inspection; stack feasibility; working slice; real controls; draft/focus/resize preservation; independent acceptance results. |
| `src/skills/ux-designer/SKILL.md` | Task-centered journeys, entry/next action/recovery, onboarding versus approval, realistic states, applicable platform/input rules. |
| `src/skills/macos-design/SKILL.md` | Real native window behavior, system fonts when appropriate, adaptable panes, keyboard/menu behavior, purposeful custom motion, explicit host-validation limits. |
| `src/skills/design-taste/SKILL.md` | Reference Contract in existing DESIGN.md; concrete observation-to-decision mapping; preserve/change decisions; regression evaluation briefs. |
| `src/skills/web-design-guidelines/SKILL.md` | Currentness and fetch limits, actual rendered review, composer/form failure cases, target-size exceptions, separate visual and behavioral evidence. |
| `src/agents/engineering/design-lead.md` | Removes conflicting novelty and mandatory marketing-motion rules; correct DESIGN.md handoff; applicable state coverage. |

## Step changes

| Step | Change at existing gates |
| --- | --- |
| 2 — Architecture | Verify component-library and host compatibility before promising implementation. Distinguish installed components from authorized fallbacks. |
| 3 — UX | Record inspected references and a concrete Reference Contract; preserve the selected direction; compare alternatives only when direction is open. Remove universal marketing styling and novelty quotas, including embedded standards and scorecards. |
| 4 — Flow tree | Identify a representative core journey/high-risk interaction with stable screen and recovery references for Step 5. No new machine-schema field. |
| 5 — Prototypes | Prove one runnable slice in the selected stack before scaling. Canvas/static exports alone do not prove interactions. Separate visual and behavioral acceptance; preserve reference direction. |
| 6 — Design system | Formalize tokens from tested prototype evidence. Replace fixed palette, type, radius and motion recipes with traceable product/platform choices. |
| 7 — Interface states | Review rendered states and actual recovery behavior separately; preserve focus during asynchronous updates; use task-appropriate custom motion. |

Existing checkpoint/delegation rules remain in place. No additional approval gate was introduced.

Step 3 and Step 5 no longer invoke the universal `divergence_proof` assertion, whose contract requires three links and multiple creative directions. They instead use the existing supported `file_exists docs/design/DNA-REFERENCES.md` and `section_has DESIGN.md Reference Contract` assertions. These check artifact structure only; the documented review still owns evidence quality and acceptance. The shared hook and its legacy assertion remain unchanged.

## Verification receipts

| Check | Command or method | Observed result |
| --- | --- | --- |
| PASS | `node scripts/validate-skills.mjs` | 87 authored skills and 381 bundled skills valid; 53 agent skill references across 12 agents resolve. |
| PASS | `node scripts/verify/validate-step-wiring.mjs --strict` | Checked 18 steps (expected 18), 87 skills; PASS. |
| PASS | `bash scripts/lint-step-parity.sh` | 18 canonical step files match commands. |
| PASS | `bash tests/test_step_verify_gate.sh` | 26 passed, 0 failed. Includes missing heading/output blocking and existing legacy assertion behavior. |
| PASS | Byte comparison of the five changed source/bundled skill files and evaluation briefs | All six pairs match. |
| PASS | Relative Markdown link scan of 31 scoped paths | No missing relative link destinations. |
| PASS | `git diff --check -- <31 scoped paths>` | Exit 0, no whitespace errors. |
| PASS | Bounded independent contract review plus local closure check | Earlier five contradictions corrected; final embedded Step 3 conflict also corrected and re-rendered. |
| NOT RUN | Full generated UI evaluations | Three briefs supplied; no new rendered workspace/composer/form evaluation run in this task. |
| NOT RUN | Sigma Atlas desktop build or release | No application code changed by this task. |

Evaluation briefs: `src/skills/design-taste/references/evaluation-briefs.md` (also bundled locally). Cases cover a professional workspace, an IDE-style composer/model picker, and a complex asynchronous setup form. Record real visual and interaction results independently when running them. Their presence is not proof that a model will produce an acceptable UI.

## Availability

These changes are available in this repository’s canonical sources and local bundle. Other repositories, global installations, already-loaded skill context, and Sigma Atlas’s packaged methodology snapshot are not automatically refreshed by this edit. Refresh or reinstall those explicitly before claiming adoption there.
