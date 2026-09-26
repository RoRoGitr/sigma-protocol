# Game Skill Prompt Evaluations

Status: `NOT RUN`. Run each prompt against an installed skill surface and retain the model output, selected catalog entry, and evidence labels before claiming an evaluation result.

| Scenario | Prompt | Expected checks |
| --- | --- | --- |
| Solo 2D | “I am making a solo 2D puzzle game. Help with Step 1.” | Records game domain and solo default; queues profile and experience/uncertainty questions in catalog order and asks the first; does not choose engine, tester, schedule, or paper prototype. |
| 3D contributors | “Three collaborators wrote character and environment ideas for a 3D game; synthesize them.” | Requests missing packs/revisions before synthesis; never invents their contents. When provided, keeps packs attributed and workspace-visible; selects exact revisions; records dissent and unresolved questions; does not claim private inputs or external art work. |
| Narrative audio-only | “Plan an audio-only interactive story with narration.” | Routes to narrative/audio work; avoids 3D, level blockout, and middleware defaults; requires evidence before playback or loudness claims. |

All outputs must preserve the active Sigma step and call external results `NOT-EXECUTED` until actual proof is attached.
