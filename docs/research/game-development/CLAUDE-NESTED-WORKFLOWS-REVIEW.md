# Nested preproduction workflows for game development — Claude production-method review

Status: research review, not methodology. Written 2026-09-22 by the Claude Code production-method reviewer under `briefs/claude-production-review.md`. Parent compares this against the Grok lanes (`GROK-ASSETS-TECHNICAL.md`, `GROK-DESIGN-PRODUCTION.md`) before any methodology is authored.

Scope: general methodology for ANY game. Solo default, optional team mode. No Mazerance, room-count, player-count, V1, engine or deadline defaults are inherited. Nothing here installs, builds, imports, renders or validates an asset. Atlas plans; humans, DCC tools and engines execute.

## 0. How to read this document

Three evidence labels are used throughout. They are never mixed inside one sentence.

| Label | Meaning |
|---|---|
| **SOURCE** | A fetched, read primary or practitioner page says this. Source IDs in brackets (C = characters, E = environments, L = level/puzzle/prototyping/accessibility, A = audio, P = pipeline/review). Register in Appendix A. |
| **ADAPTATION** | My proposal for how Sigma Protocol should nest this. Not claimed to be documented practice anywhere. |
| **NOT-EXECUTED** | A step whose real evidence can only come from a DCC tool, an engine, a playtest or a human. A generated document never satisfies it. |

Video rule: no video was watched. Where a GDC Vault, Blender Studio or IndieCade page is cited, the evidence is the page description, transcript or slides, and the register says which. Sid Meier's "33 percent rule" and Hayashida's kishōtenketsu framing, for example, do **not** appear on the Vault pages and are cited only from secondary text (L23) or not at all.

Research method: four parallel research lanes (characters, environments, level/puzzle/prototyping/accessibility, audio+pipeline) plus 12 anchor sources I fetched and read myself. Every register entry was fetched and read on 2026-09-22. Firecrawl search was permission-denied in this session, so discovery used WebSearch and retrieval used WebFetch/Exa. Failed fetches are listed under gaps, never as sources.

## 1. Executive summary

The research supports eight conclusions strongly enough to build methodology on.

1. **Every discipline already has a documented "test before you invest" gate.** Blockout before art (E06, E07, L02), sculpt as design before retopo (C06), publishable first playable before production (L38), vertical slice before production (L41), question-driven prototypes before features (L36, L37). The nested workflows below are all shaped around that gate.
2. **The unit of review is a versioned publish with a status, not a document.** Blender Studio's Asset Pipeline add-on publishes Active / Staged / Sandbox versions with task-layer ownership (C45/P05); Kitsu tracks NR → TODO → WIP → WFA → DONE with RTK for retakes (P06, P12); Perforce and Unity VCS roll back by writing a new forward revision (P20, P21). A Sigma nested workflow must record status and version, and rollback must be "publish the previous version again," not "delete."
3. **Engine acceptance is a checklist the engine can partly enforce.** Unreal Data Validation runs on save and in CI (E45/P13), Godot import suffixes act automatically (C36), Unity presets apply import settings per folder (E47). Atlas can author the checklist; only the engine can run it.
4. **Metrics come before layout.** Player metrics are measured in-engine; building metrics are chosen by the designer (E03, E02, L10, L07). Every environment and level workflow starts with a metrics sheet, and the sheet is invalid until a real capsule has walked the blockout.
5. **Puzzle and level intent is a graph, not prose.** Ron Gilbert's puzzle dependency chart (L13), Daniel Cook's skill chains (L25), Hayashida's four-beat level structure (L23) and Emilia Schatz's affordance language (L07) are all graph- or table-shaped. Sigma's AI-native output rule already demands tables over prose.
6. **Accessibility is a tiered checklist with primary sources.** Game Accessibility Guidelines Basic / Intermediate / Advanced (L43–L45), Xbox Accessibility Guidelines with per-guideline scoping questions (L46, A19), and AbleGamers APX patterns (L47). These map cleanly onto Step 7's accessibility phase.
7. **Audio has a middleware-shaped structure and real loudness numbers.** Events, banks, parameters, buses and snapshots are common vocabulary across Wwise, FMOD, Unreal, Unity and Godot (A02, A06, A10–A13). Sony's ASWG-R001 sets −24 LKFS (home) and −1 dBTP (A14); EBU R 128 sets −23 LUFS (A16). Atlas can plan a mix target; only a loudness meter can prove it.
8. **The solo-to-team question is a synthesis problem, not a workflow problem.** Studios solve it with ownership (task layers, exclusive checkout) and with review rituals (dailies, playlists, retakes). The idea-pack contract in §8 borrows those two mechanisms rather than inventing a voting scheme.

Two honest limitations up front. First, environment art bibles, prop lists, density passes and audio QA checklists are described in the sources only as practice, never as published templates; the templates in this document are ADAPTATION. Second, several vendor pages (Wwise Help deep pages, Unreal glTF import, Unity model scale) could not be fetched and are in the gaps list.

## 2. What the Sigma canon already fixes

I read `AGENTS.md`, `steps/README.md`, the HITL gate partial, and the goal blocks of Steps 2, 3, 5, 7, 10, 11 and 11.5. The following constraints shape every nested workflow proposed below.

- **Step shape.** Frontmatter, mission, a phase table with named outputs, phases ending in `>>> CHECKPOINT` hard gates, a final review gate, and a 100-point verification rubric with a 95 threshold. Nested workflows must produce phase tables and rubric rows in the same shape or they will not render through `scripts/sync-steps-to-platforms.sh`.
- **HITL gate contract.** One gate per phase, never batched; silence is not approval; unattended runs need an explicit up-front opt-in. Nested workflows therefore add gates only at real creator decisions (identity lock, blockout approval, kit lock, mix target) and never at mechanical sub-steps.
- **AI-native output rule.** Downstream consumers are agents. Every nested output must be a table, predicate list or JSON mirror. Prose-only artefacts fail.
- **Execution standard.** "Done" requires the command and real output in the same message. For assets this means: a document is never "done" for an asset. The doc can be APPROVED-AS-PLAN; the asset is NOT-EXECUTED until external evidence is attached.
- **Existing hooks.** Step 5 already has a Canvas / Direct track split with a "never invent browser review, an export, authentication, or approval when the selected tool is unavailable" rule. That rule is the template for every DCC/engine evidence field below.
- **Step 11.5 blocking rule.** Ambiguous PRDs produce `BLOCKED / clarification required` tasks with the exact missing decision. Creator questions in the nested workflows are written so that an unanswered one produces exactly that.
- **Atlas.** Per `docs/plans/2026-09-20-sigma-atlas-direction.md`, Sigma Atlas is planning only; external harnesses execute. The Atlas proposal absorbs 11.5 into Step 11 and adds canvas-linked records for Steps 3–7; canonical Protocol still has 11.5. This review maps to the canonical numbering and flags the Atlas alignment as an open item for the parent.

## 3. Common nested-workflow contract (ADAPTATION)

Every discipline workflow in §4 uses the same record. This is the proposed schema, kept deliberately close to Step 11.5's task manifest so the parent can merge rather than invent.

```
NESTED-WORKFLOW <id>
  parent_step:        Step N (canonical 0–15, 1.5, 11.5)
  domain:             character | environment | level | puzzle | audio | 2d | a11y | prototype
  inputs:             named upstream artefacts (paths) + creator answers
  creator_questions:  ordered; each has an id, options, default=NONE, and the
                      consequence of not answering (which downstream stage blocks)
  stages:             ordered; each has {name, owner_role, outputs, gate?, evidence_kind}
  outputs:            named files under docs/game/<domain>/...
  dependencies:       edges to other nested workflows (by id) — never implicit
  review:             who reviews, against which checklist, status vocabulary
  rollback:           what "previous version" means for each output, and who may trigger it
  roles:              Sigma agents/departments (existing) + PROPOSED roles
  company_function:   which department owns the budget, the schedule, the rights
  external_evidence:  the exact artefact a human/DCC/engine must attach before
                      status can move past PLANNED (render, import log, playtest notes, meter reading)
```

Status vocabulary (SOURCE-derived, ADAPTATION-applied): `NR` not ready, `TODO`, `WIP`, `WFA` waiting for approval, `RTK` retake, `DONE`, `GO` (P06). For assets, `DONE` is only reachable when `external_evidence` is non-empty. The Blender Studio publish states `sandbox` / `staged` / `active` (C45/P05) are used for asset *versions*; the Kitsu statuses are used for *tasks*. Keeping the two vocabularies separate is itself a SOURCE finding: the studio does exactly that.

Rollback rule (SOURCE-derived): rollback is a new forward publish of an older version (P20, P21). Every output therefore carries `version` and `supersedes`. Deleting a version is never a workflow action.

## 4. Discipline workflows

### 4.1 Characters (3D)

#### What the sources document

- **Identity and proportion are design work, done with sculpt and 2D together.** Blender Studio's Sprite Fright lead writes that "Sculpting is primarily a design task, not a production step!" and advises presenting sculpts posed and lit, checking the character can do its story actions from the required camera angles, and writing a style guide covering emotional range and deformation needs before handover (C06). The film's design language was codified as shape rules applied to all characters and props ("chunkification", C01). Lineup deliverables on that production were turntable renders, wireframe turntables, expression sheets, silhouette studies and palette locks (C02). Heads-tall proportion canons are documented only in a reference encyclopedia (C04); no practitioner canon page was verified.
- **Reference views are an in-tool feature, not a separate discipline.** Blender image empties display front/back/side references with depth and axis-alignment options (C07). Blender Studio renders its own orthographic model sheets from the .blend for proportion review, and warns those views are "terrible for judging appeal" (C05). SOURCE therefore says: keep separate reference views, but never approve identity from orthographic views alone.
- **Component sheets** (outfit, expression, prop, material) exist as production artefacts (C02, C08) but no source publishes a template. Spine "skins" are the 2D equivalent of an outfit sheet (C09).
- **Topology** rules are stable across sources: edge loops at deformation hot spots, quads for sculpt/skin workflows, triangulate before bake and export, silhouette first (C10, C12, C13, C14). Budgets are deferred to the lead artist (C12); no current numeric budget page was verified.
- **UV and materials.** Fewest seams with least stretch, hide seams, mirror-share texture space (C15). PBR conventions: metallic treated as binary, roughness 0–1, specular default 0.5 in Unreal (C16); Unity calibration charts (C17). Texel density is defined only (C18); the standard guide could not be fetched.
- **Rig and deformation.** Rigify builds rigs from meta-rig blocks and does not skin the mesh (C20); CloudRig extends it and is Blender Studio's production rig (C21, C22); Snow is a free CC-BY example of a finished production rig with IK/FK snapping, stretch, hinge toggles and layered face controls (C47, C48). Engine-side: Unreal Control Rig (C23), Unity Humanoid avatar mapping with required vs optional bones (C24), Godot BoneMap and "Overwrite Axis" retargeting (C25).
- **Animation and contact states.** Lyra's locomotion state machine (Idle / Start / Cycle / Stop / Pivot) with distance matching, stride and orientation warping (C28); root motion must be authored on the root bone (C29); Godot AnimationTree exposes root-motion deltas (C30). The twelve principles are cited only via an encyclopedia (C27).
- **Engine acceptance.** Unreal FBX skeletal pipeline: single root bone, triangulated, FBX 2020.2, one animation per file, pivot at root (C31; my own fetch confirms the version shown is UE 5.8). LOD import per mesh (C32). Unity: export FBX directly into Assets, Rig tab Humanoid vs Generic (C33). Godot: glTF 2.0 recommended, Y-up, face +Z, triangulate, rest pose, apply transforms (C34, C35; my own fetch confirms), and name suffixes like `-col` and `-loop` act on import (C36). Blender's glTF exporter maps Principled BSDF to metal/rough and triangulates n-gons (C19).
- **Studio pipeline.** Blender Studio's pipeline overview names the asset-creation stages (modeling, sculpting, shading, rigging, animation testing) and the principle "use Blender as much as possible, add-ons only when needed" (C44/P02). Its Asset Pipeline add-on gives task-layer ownership and push/pull publishing (C45/P05; my own fetch confirms the Active / Staged / Sandbox publish types and the ownership rule).

#### Practitioner comparison and limitations

| Approach | Where documented | Strength | Limitation |
|---|---|---|---|
| Film-style: design in sculpt, lineup consistency, style guide before handover | Blender Studio (C01, C02, C06) | Strongest published evidence of the review artefacts | Film, not game; polycount and engine acceptance absent |
| Game-art wiki: concept → sculpt → retopo → bake → texture → rig | Polycount (C03, C10, C12) | Tool-agnostic, names the deformation hot spots | Undated, community-edited, budget numbers deferred |
| Engine-first: import rules and validators define "done" | Epic, Unity, Godot docs (C31–C36, E45) | Enforceable by machine | Says nothing about appeal, identity or story fit |
| Auto rig then hand-skin | Rigify / CloudRig (C20–C22) | Fast, regenerable, production-proven | Blender-only; skinning still manual; rig-to-engine retarget is a second job |

None of these alone is a game character pipeline. SOURCE supports combining film-style identity review with engine-first acceptance; the join is ADAPTATION.

#### Proposed nested workflow NW-CHAR (ADAPTATION)

Parent step: Step 3 (identity, design DNA) → Step 5 (reference and blockout artefacts) → Step 8 (engine acceptance contract) → Step 11 (per-character PRD). Dependencies: NW-ENV for scale reference, NW-PROTO if the character's core verb is unproven.

| # | Stage | Inputs | Creator questions (id) | Outputs | Gate | Review / rollback | Owner | External evidence (NOT-EXECUTED until attached) |
|---|---|---|---|---|---|---|---|---|
| 1 | Identity and proportion | Step 1 MASTER_PRD, Step 3 DESIGN.md, world rules (NW-ENV.1) | CH-1 heads-tall canon and silhouette family; CH-2 story actions the body must perform; CH-3 required camera angles | `docs/game/characters/<id>/IDENTITY.md` (shape rules, actions, camera list, palette) | HARD-GATE identity lock | Reviewer compares posed, lit sculpt or 2D turn against CH-2/CH-3; retake = new version | design-director, PROPOSED character-art-lead | Posed and lit render or sketch set, not orthographic (C05, C06) |
| 2 | Separate reference views | IDENTITY.md | CH-4 which views (front/side/back/three-quarter) and at what resolution | `reference/` image set + `REFERENCE-MANIFEST.json` (view, file, scale mark) | none | Manifest completeness check; identity not re-judged here (C05) | character-art-lead | Image files with a scale marker visible |
| 3 | Component sheets | IDENTITY.md, references | CH-5 outfit set; CH-6 expression set and range; CH-7 prop list; CH-8 material callouts | `SHEETS.md` (tables per outfit/expression/prop/material) | HARD-GATE only if outfits or props affect scope | Cross-check against Step 10 scope; unresolved item → BLOCKED | character-art-lead, product-owner | Sheet images or a canvas board export |
| 4 | Topology plan | IDENTITY, SHEETS, engine choice (Step 2) | CH-9 tri budget per LOD; CH-10 deformation hot spots that matter for CH-2 | `TOPOLOGY-PLAN.md` (budget table, loop map, LOD chain) | none | Budget within Step 8 performance contract; retake if over | tech-artist (PROPOSED), lead-architect | Wireframe turntable + triangle count from the DCC |
| 5 | Multiview validation | Model, references | CH-11 which silhouettes must read | `VALIDATION-CHECKLIST.md` rows: silhouette per view, proportion vs reference, story-action pose test | HARD-GATE model approval | Kitsu-style WFA → DONE/RTK; previous version stays published (P05, P12) | design-director | Turntable render + overlay comparison images |
| 6 | UV / textures / materials | Approved model, Step 6 design tokens (palette) | CH-12 texture set count and resolution; CH-13 PBR convention (engine) | `MATERIAL-SPEC.md` (sets, texel target, PBR ranges per C16/C17) | none | Seam and stretch review; metallic binary check | tech-artist | Checker-texture render and texture set files |
| 7 | Rig and deformation | Approved model, CH-2 actions, engine retarget target | CH-14 rig tool (Rigify/CloudRig/engine control rig); CH-15 face rig depth | `RIG-SPEC.md` (control list, IK/FK, retarget map to engine skeleton profile) | HARD-GATE rig approval | Deformation test poses from CH-2; retake on mesh tearing | tech-artist | Pose test renders; skinning weights exported |
| 8 | Animation and contact states | RIG-SPEC, gameplay verbs (Step 4 flow tree) | CH-16 locomotion set; CH-17 root motion vs in-place; CH-18 contact states (foot plant, grab, hit) | `ANIM-STATES.md` (state machine table modelled on Lyra C28; per-state contact rule) | none | State coverage vs verbs = 100 percent or BLOCKED | animator (PROPOSED), ux-director | Engine state-machine screenshot and clip list |
| 9 | Engine acceptance | Export, engine import rules (C31–C36) | CH-19 format (glTF/FBX); CH-20 naming and suffix scheme | `ENGINE-ACCEPTANCE.md` checklist + validator rules for Data Validation / import presets | HARD-GATE ship-to-engine | Automated validator result attached; failure = RTK | lead-architect, qa-engineer | Import log, validator output, in-engine screenshot |

Company-function links: design (identity, review), engineering (acceptance, validators), finance (outsourcing budget if the creator is not the artist), legal (rig and reference licences: Snow is CC-BY, C47; Loomis and Williams texts were not verified as free), ops (schedule).

### 4.2 Environments (3D)

#### What the sources document

- **Scale and units.** Unreal uses centimetres (E01); its designer course gives worked metrics in cm: 1.8 m character, 0.5 m jump, 2–3 m hallways, 1–1.5 m × 2 m doors (E02). The Level Design Book splits **player metrics** (measured in engine) from **building metrics** (designer-chosen) and warns "You cannot measure your way to a good game experience" (E03). Blender's Unit Scale affects display only (E04). Godot's metre unit is implied, not stated on a fetched page (gap).
- **Blockout.** Cheap to throw away, playtestable, and "99% of the time, your blockout will not survive a playtest" (E06/L02). Critique after every phase: layout, blockout, scripting, art (E07). Build in the engine, not the DCC, with a scale figure (E08). Tools: ProBuilder (E10), Godot CSG for prototyping only (E11), Lyra's parametric geometry tools that bake to static meshes (E12). Naughty Dog / Respawn blockmesh discipline is on a Vault description only (E09).
- **Modular kits.** Kit planning sequence: percentages and granularity, blockout the kit without variants, human-scale metric prototypes, standard module types, footprint, naming, stress tests (loopback, stack, gap), then art pass (E13, sourced from Burgess). "Kits, first and foremost, are systems" that "snap together using a grid system" (E14, transcript). Trim sheets keep draw calls and texel density under control (E16). Godot GridMap is a 3D tilemap with per-item collision and lightmap rules (E17).
- **Set dressing.** Art pass waits for a mature blockout; plan theme, emphasis, palette and production order; paint over blockout screenshots (E18). Environmental storytelling tools are props, scripted events, texturing, lighting, composition (E19 description; E20; E21). Naughty Dog hands blockmesh to environment artists and keeps design intent via consistent shape language (E21/L07).
- **Lighting and materials.** Lumen is dynamic and disables lightmaps (E23); Lightmass is the baked lane with importance volumes (E24); Godot LightmapGI needs UV2 (E25, E26); Unity lighting is a realtime-vs-baked choice (E27).
- **Collision and navigation.** Simple vs complex collision and the "use simple as complex" memory trade (E28); Godot recommends concave shapes for whole levels on static bodies (E29); Unity NavMesh Surface bake and re-bake rule (E30); Godot NavigationServer regions and agent radius (E31); blocking volumes in E02.
- **Performance.** Budgets framed as frame-time at target FPS on target hardware (E32); draw calls "the biggest contributor to low graphical performance," with worked ceilings (E33); World Partition streaming and HLOD (E34, E35); Nanite removes manual LOD with listed limits (E36); City Sample's min spec shows what a demo budget looks like (E37); Unity occlusion, LOD and draw-call docs (E38–E41); Godot's advice that "you may have to adapt your level design to add more occlusion opportunities" (E42, E43).
- **Review and acceptance.** Data Validation for naming, budgets and dependencies, on save and in CI (E45); Epic's recommended `Prefix_AssetName_Descriptor_Variant` convention (E46) and the community MIT-licensed Allar guide (P14); Unity presets per folder (E47); Godot `.import` sidecars and reimport (E48).

#### Practitioner comparison and limitations

| Approach | Documented in | Strength | Limitation |
|---|---|---|---|
| Kit-first (Bethesda) | E13, E14 | Scales a few artists across many designers; grid discipline | Overhead for small or one-off spaces; transcript is 2013 |
| Blockout-first, art waits (Level Design Book, Naughty Dog) | E06, E07, E18, E21 | Playtest before spend; shape language survives art pass | Public testers cannot read blockouts (E07) |
| Parametric tools that bake (Lyra) | E12 | Non-destructive resize, Nanite-ready | Experimental plugin, UE-only |
| Engine-enforced acceptance | E45–E48 | Machine-checkable | Rules must be written per project; none ship |

#### Proposed nested workflow NW-ENV (ADAPTATION)

Parent step: Step 2 (engine and performance profile) → Step 4 (space inventory, analogous to screen inventory) → Step 5 (blockout as the "wireframe") → Step 6 (kit as design system) → Step 8 (lighting, collision, navigation, performance contract).

| # | Stage | Inputs | Creator questions | Outputs | Gate | Review / rollback | Owner | External evidence |
|---|---|---|---|---|---|---|---|---|
| 1 | World rules and metrics | Step 1 PRD, Step 2 engine choice | EN-1 unit and up-axis; EN-2 player metrics list to measure; EN-3 building metrics to choose | `docs/game/environments/METRICS.md` (two tables per E03) | HARD-GATE metrics lock | Invalid until player metrics are measured in engine (EN-2) | level-designer (PROPOSED), lead-architect | In-engine measurement capture (capsule height, jump, step) |
| 2 | Layout and blockout | METRICS, NW-LEVEL intent | EN-4 blockout tool; EN-5 which spaces must be walkable in v1 | `BLOCKOUT-PLAN.md` (space list, massing notes, wayfinding intent) | HARD-GATE blockout approval | Self-playtest then peer critique; art pass BLOCKED until approval (E07, E18) | level-designer | Walkthrough capture + playtest notes |
| 3 | Modular kit | Approved blockout, palette | EN-6 kit percentage vs unique; EN-7 module footprint and grid; EN-8 naming scheme | `KIT-PLAN.md` (module table, footprint, stress tests per E13) | HARD-GATE kit lock | Loopback / stack / gap tests recorded; retake on any failure | environment-art-lead (PROPOSED), design-systems-architect | Kit stress-test screenshots in engine |
| 4 | Set dressing | Kit, story beats (Step 1/3) | EN-9 theme and emphasis per space; EN-10 prop list; EN-11 density target | `DRESSING-PLAN.md` (prop table, density per space, paintover refs) | none | Paintover reviewed against blockout screenshot; shape language check (E21) | environment-art-lead, content-director (narrative props) | Paintovers and dressed-space renders |
| 5 | Lighting and materials | Engine GI choice (Step 2/8) | EN-12 baked vs dynamic; EN-13 lookdev reference | `LIGHTING-PLAN.md` (mode, key lights per space, material library list) | none | Lookdev render reviewed; UV2 present if baked (E25) | environment-art-lead, tech-artist | Lookdev render + bake log |
| 6 | Collision and navigation | Blockout, agents list | EN-14 collision complexity policy; EN-15 agent radii and step heights | `COLLISION-NAV.md` (per-asset collision type, nav bake settings) | none | Nav bake result and stuck-spot playtest | level-designer, qa-engineer | Nav mesh overlay capture + collision debug view |
| 7 | Performance budget | Step 2 target hardware | EN-16 target FPS and hardware; EN-17 draw-call and texture ceilings | `PERF-BUDGET.md` (frame-time, draw calls, streaming cells) | HARD-GATE budget lock | Profiler capture vs budget; over budget = RTK on the offending stage | lead-architect, observability-engineer | Profiler screenshot (stat unit / Profiler / Godot monitor) |
| 8 | Review and acceptance | All above | EN-18 validator rules to encode | `ENV-ACCEPTANCE.md` + validator rule list | HARD-GATE ship | Data Validation / preset / import check attached | qa-engineer | Validator output log |

Company-function links: design, engineering, ops (schedule per space), finance (asset purchases; marketplace licences), legal (kit and texture licences).

### 4.3 Level and puzzle design

#### What the sources document

- **Intent.** One-page designs replace unread GDDs with an annotated diagram (L04 description, L05 slides exist, L06 editorial). Holistic level design treats gameplay, presentation and story together (L08 description). Level design is constraint resolution across systems, tech and art (L09). Combat metrics are set by controlled playtests before opening the editor (L10). Weekly one-hour "design huddles" as practice ritual (L11).
- **Constraints.** Rational Level Design quantifies atomic parameters and fits difficulty curves to fail-rate data; "linear increases in complexity tend to create exponential increases in game difficulty" (L12). Affordance language: every object is walkable or not; ambiguous metric bands are banned (L07).
- **Solution graphs.** Puzzle dependency charts are a DAG built backwards from chain endings, shaped as diamonds between act bottlenecks; "dependency charts are great if you're trying to design a game" (L13). Gilbert's 1989 rules: objective clear, sub-goals obvious, no death-to-learn, no backwards puzzles (L14). Puzzle taxonomy and fairness (L18). Blow and ten Bosch: derive puzzles from consequences of a rule, not combinatorics (L16 talk page, L17 press). Elyot Grant's 30 lessons exist on the Vault (L15, description only). Zachtronics open-ended puzzles (L19, members-only description). PuzzleScript docs document rule execution order for rule-based puzzles (L20).
- **Teaching.** Valve's Portal commentary describes gates that force the player to stop and notice, and dialogue added when playtesters abandoned the box (L21 transcript). Hayashida's four-beat structure: learn, harder, twist, mastery (L23 interview quotes). Skill atoms chained into skill chains (L25). Hodent's onboarding: cognitive load, learning by doing, show the lock before the key (L26).
- **Fairness and recovery.** Celeste's ten forgiveness mechanics widen timing and position windows (L27). Autosave and difficulty options appear in accessibility tiers (L44, L43).
- **Playtests.** Level Design Book: self → peer → public; watch the screen, note behaviour, collect telemetry, do not over-explain (L03). Playcentric process (L29). Vault descriptions for attention metrics (L34) and datalogging (L35). Sid Meier's page says gameplay is psychological, "2/1 is not equal to 20/10" (L31); the 33 percent rule is not on the page.

#### Proposed nested workflow NW-LEVEL (ADAPTATION)

Parent step: Step 3 (experience goals) → Step 4 (flow tree becomes the level/puzzle graph) → Step 5 (blockout PRD per level) → Step 7 (fail and recovery states) → Step 10/11 (per-level PRDs).

| # | Stage | Inputs | Creator questions | Outputs | Gate | Review / rollback | Owner | External evidence |
|---|---|---|---|---|---|---|---|---|
| 1 | Intent one-pager | Step 1 pillars, Step 3 goals | LV-1 the one sentence the level proves; LV-2 emotional beat; LV-3 verbs available at entry | `docs/game/levels/<id>/ONE-PAGE.md` (diagram ref + ≤10 annotations, per L04–L06) | HARD-GATE intent approval | Reviewer states the intent back without reading prose; mismatch = retake | level-designer, cpo | Diagram image (canvas export) |
| 2 | Constraint sheet | METRICS (NW-ENV.1), verb list | LV-4 atomic parameters and ranges (L12); LV-5 affordance table (L07); LV-6 budget (time to build, tri budget) | `CONSTRAINTS.md` (parameter table, affordance table, banned bands) | none | Every parameter has a measured source or is marked ASSUMED | level-designer | Measurement captures |
| 3 | Solution graph | Intent, constraints | LV-7 puzzle or encounter nodes; LV-8 bottlenecks per act; LV-9 forbidden shapes (linear chains, dead ends) | `SOLUTION-GRAPH.json` + rendered chart (DAG per L13; skill chain per L25) | HARD-GATE graph approval | Automated checks: acyclic, no orphan nodes, diamond width ≥2 between bottlenecks (ADAPTATION threshold) | level-designer, devils-advocate | Graph file passes lint; chart image |
| 4 | Teaching plan | Graph | LV-10 first safe encounter per mechanic; LV-11 four-beat sequence (L23); LV-12 gate points (L21) | `TEACHING.md` (mechanic × beat table) | none | Every mechanic in the graph has beat 1 before any beat 2 use | level-designer, ux-director | Blockout walkthrough capture |
| 5 | Fairness and recovery | Graph, Step 7 state spec | LV-13 forgiveness windows (L27); LV-14 fail state and checkpoint policy; LV-15 hint escalation | `FAIRNESS.md` (window table, checkpoint map, hint ladder) | HARD-GATE only when death or loss exists | Cross-check with Step 7 recovery patterns and L43/L44 tier items | level-designer, ux-director | Playtest fail-rate log |
| 6 | Playtest protocol | Blockout | LV-16 tester tiers (self/peer/public); LV-17 telemetry to log; LV-18 stop rule | `PLAYTEST-PROTOCOL.md` + `playtests/<date>.md` notes | HARD-GATE per playtest round | Notes in behaviour form (L03); decision: keep / revise / kill | level-designer, community-lead (recruiting), qa-engineer | Session notes, telemetry export, recording |

Company-function links: product (intent), design (teaching, fairness), community (tester recruiting), ops (playtest schedule), qa (telemetry).

### 4.4 Audio

#### What the sources document

- **Structure.** Wwise organises Events, Switches, RTPC parameters, States, Actor-Mixers, buses and SoundBanks (A02 syllabus; A01 TOC only). FMOD separates Studio authoring from the runtime engine, with events, sheets, instruments, parameters and banks; events must be explicitly assigned to banks (A06, A07). Unreal MetaSounds Source vs Patch and presets (A10), Audio Modulation buses (A11). Unity Audio Mixer groups and snapshots (A12). Godot buses with the rename-reroutes-to-Master trap (A13).
- **Naming.** Audiokinetic's blog gives a concrete formula `type_category_?subcategory_?action_?01` with examples (A04).
- **Adaptive music.** Vendor vocabulary is horizontal re-sequencing and vertical re-orchestration (A03 syllabus IDs); Phillips defines horizontal resequencing as segment rearrangement (A21); Whitmore's Vault description says adaptive parts must be "mixed in the console, dynamically" (A20).
- **Dialogue.** FMOD's programmer-instrument plus audio-table pattern for localisation (A08); Wwise container-based narration in Unity (A05); Unreal dialogue voices and waves with context (A24, verified with a 403-titled fetch).
- **Loudness.** ASWG-R001 v1.10: −24 ±2 LKFS home, −18 ±2 portable, −1 dBTP, measure ≥30 min of representative play (A14, mirror copy; A15 interview gives the rationale). EBU R 128: −23 LUFS (A16).
- **Accessibility.** Separate volume controls (A17), no essential information by sound alone (A18), Xbox subtitle and caption spec with line length, scaling and on-by-default rules (A19).
- **QA.** The only citable audio-bug taxonomy is academic (A23). Source control for the FMOD project itself: shared bank output path, assets outside the repo (A09).
- **Middleware decision.** No vendor-authored decision doc exists (gap); only community explainers (A22).

#### Proposed nested workflow NW-AUDIO (ADAPTATION)

Parent step: Step 2 (middleware vs native, an architecture decision with an ADR) → Step 7 (audio states and captions per screen/space) → Step 8 (bus, bank and loudness contract) → Step 11 (per-feature audio PRD sections) → Step 15 (audio telemetry: bank load failures, voice starvation).

| # | Stage | Inputs | Creator questions | Outputs | Gate | Review / rollback | Owner | External evidence |
|---|---|---|---|---|---|---|---|---|
| 1 | Audio direction and middleware ADR | Step 1 pillars, engine | AU-1 middleware vs native (with the feature reasons from A06/A10–A13); AU-2 music model (linear / horizontal / vertical) | `docs/game/audio/AUDIO-DIRECTION.md` + `ADR-audio-middleware.md` | HARD-GATE ADR | ADR lists licence cost and platform support | audio-director (PROPOSED), lead-architect, finance-director | Licence terms captured (link) |
| 2 | Asset list and naming | Direction, level and character verbs | AU-3 naming formula (A04); AU-4 event list per verb and state | `ASSET-LIST.csv` (event, category, trigger, bank, priority) | none | Every Step 4 transition and NW-CHAR contact state has an event row or `none` | audio-director | none at plan stage |
| 3 | Bus, bank and mix contract | Asset list | AU-5 bus tree and snapshots; AU-6 bank split and load points; AU-7 loudness target (A14/A16) and true-peak ceiling | `MIX-CONTRACT.md` (bus table, bank table, targets) | HARD-GATE mix targets | Targets are numbers with a meter standard named | audio-director | Loudness meter reading over ≥30 min capture (A14) |
| 4 | Adaptive music plan | Direction | AU-8 segments and transition rules; AU-9 stems/layers and driving parameters | `MUSIC-PLAN.md` (segment graph, layer × parameter table) | none | Every gameplay parameter used exists in Step 8 data contract | audio-director, composer (PROPOSED) | Middleware project screenshot |
| 5 | Dialogue and localisation | Script, languages | AU-10 line table; AU-11 localisation pattern (A08) | `DIALOGUE-TABLE.csv` | none | Line IDs stable; languages listed | content-director, audio-director | Audio table build log |
| 6 | Audio accessibility and QA | Step 7 states | AU-12 caption spec (A19); AU-13 sound-off test plan (A18); AU-14 bug taxonomy rows to track | `AUDIO-A11Y-QA.md` | HARD-GATE ship | Sound-off playthrough completed and logged | ux-director, qa-engineer | Playthrough notes with sound muted |

Company-function links: engineering (integration), finance (middleware licence), legal (music and voice rights), content (dialogue), design (captions).

### 4.5 2D and sprite equivalents

SOURCE mapping of each 3D stage to its documented 2D counterpart:

| 3D stage | 2D equivalent | Source |
|---|---|---|
| Identity and proportion | Same identity gate; pixel-size and proportion guidance has no verified official doc (gap) | — |
| Reference views | Sprite-sheet import with offset, size, padding (Aseprite) | C37 |
| Component sheets | Spine skins (outfit/equipment sets sharing animations) | C09 |
| Topology | Spine mesh attachments; deform with weights not deform keys; keep vertex counts low | C38, C39 |
| Rig | Spine skeleton (bones, slots, attachments); Unity 2D Animation Skinning Editor | C40, C41 |
| Animation states | AnimatedSprite2D vs Sprite2D + AnimationPlayer in Godot | C43 |
| Engine acceptance | Unity Sprite Atlas packing and padding; Pixel Perfect Camera prep (same PPU, point filter, no compression) | C42, E54 |
| Environments / kits | Godot TileSet and TileMapLayer (set tile size before atlas; bake navigation separately); Unity Tilemap; parallax scroll scales | E49, E50, E51, E52, E53 |
| Resolution | Godot design size and stretch modes | E55 |

ADAPTATION: NW-CHAR and NW-ENV carry a `dimension: 2d|3d` field; 2D swaps stages 4–7 of NW-CHAR for a single "sprite/skeletal plan" stage whose evidence is a sprite sheet or Spine export, and NW-ENV stage 3 becomes "tileset plan" with tile size locked before any atlas is drawn (E49).

### 4.6 Accessibility (cross-cutting)

SOURCE: Game Accessibility Guidelines Basic items include remappable controls, subtitles for all important speech, interactive tutorials, wide difficulty choice, no information by fixed colour alone (L43; my own fetch confirms). Intermediate adds macros, autosave, captions on before first sound (L44). Advanced adds no essential precise timing without alternatives and audio description (L45). Xbox Accessibility Guidelines give per-guideline goal, scoping questions, key areas and player impact, and state they are "not intended to act as a checklist to validate any type of compliance" (L46). APX gives 12 access and 10 challenge patterns (L47). Engines: Unreal screen reader and text-to-speech (L49), Godot AccessibilityServer (L50, no tutorial page).

ADAPTATION: NW-A11Y is not a separate workflow. It is a required row set inside Step 7 Phase C ("Recovery Patterns & Accessibility") and a required column in NW-LEVEL.5, NW-AUDIO.6 and NW-CHAR.8 (input remap for contact-state verbs). Output: `docs/game/accessibility/A11Y-MATRIX.md` listing each GAG Basic item as PLANNED / NOT-APPLICABLE-WITH-REASON / DEFERRED, with Intermediate and Advanced items opted in per creator answer AC-1. Evidence: the only acceptable proof is a sound-off, colour-filtered, remapped-controls playthrough log, which is NOT-EXECUTED by Atlas.

### 4.7 Iterative risk prototypes

SOURCE: Hecker and Gingold's "Tower of Tuning" says stay as low on the flexibility ladder as you can and "don't take it until you need to" (L36; my own fetch confirms). Gingold's prototyping rules: ask a question with a testable hypothesis, stay falsifiable via early testing, work fast (two days to two weeks), decompose (L37). Experimental Gameplay Project: under seven days, one person, one theme, "If You Can Get Away With it, Fake it" (L39). Cerny: preproduction ends at a publishable first playable of two shipping-quality levels and a five-page macro (L38, third-party slides). Vertical slice as the preproduction-to-production gate (L41) and the term's ambiguity (L42). Supercell: survivable failure enables risk (L40). Blender Studio's Gold ramp-up: director plus two or three concept artists, previs, R&D, storyboards (P24).

#### Proposed nested workflow NW-PROTO (ADAPTATION)

Parent step: Step 1 (risk register in MASTER_PRD) → Step 2 (architecture options each carry a prototype question) → runs alongside Steps 3–8, gating them. This is the workflow the parent should treat as Sigma's game-specific "Step 1.5 equivalent" for feasibility, without adding a numbered step.

| # | Stage | Inputs | Creator questions | Outputs | Gate | Review / rollback | Owner | External evidence |
|---|---|---|---|---|---|---|---|---|
| 1 | Risk register | MASTER_PRD pillars | PR-1 the three assumptions that kill the game if false | `docs/game/prototypes/RISK-REGISTER.md` (assumption, kill condition, owner) | HARD-GATE | Each assumption is falsifiable (L37) or rejected | cpo, devils-advocate | none |
| 2 | Prototype brief | One risk | PR-2 question; PR-3 hypothesis; PR-4 time box (≤2 weeks, L37; ≤7 days solo, L39); PR-5 tower rung (L36) | `P-<n>/BRIEF.md` | none | Brief ≤1 page; more than one question = split | cpo | none |
| 3 | Build and test | Brief | PR-6 who plays it and how many | `P-<n>/RESULT.md` (kept / killed / changed; measured answer) | HARD-GATE keep/kill | Result must cite play evidence; "felt good" alone = RTK | creator, qa-engineer | Playable build or capture + notes |
| 4 | First playable / slice gate | All P-n results | PR-7 definition of first playable for this game (L38/L41: name the levels and the quality bar) | `FIRST-PLAYABLE.md` with pass predicates | HARD-GATE preproduction exit | Every RISK-REGISTER row is closed or accepted | cpo, lead-architect | Build hash + walkthrough capture |

Company-function links: product (owns the register), engineering (tower rung, throwaway code policy), finance (time box is money), ops (calendar).

## 5. Review, versioning and rollback model (cross-cutting)

SOURCE facts the model rests on:

- Blender Studio versions binary .blend files with SVN or Git LFS, with `local/`, `shared/`, `svn/` roots and `pro/assets/{cam,chars,props,sets}` (P03; my own fetch of the project overview confirms).
- Asset Pipeline publish states are Active (production-ready, multiple versions), Staged (single version, collaborative testing) and Sandbox (local), with owner-only edits per task layer (P05).
- Kitsu: WFA plus preview to request review; reviewer sets Retake or Done; previous revisions retained; annotations and frame tags; supervisor "My Checks" queue and playlists as dailies (P10–P12; my own fetch confirms Retake / Done and retained revisions).
- Perforce exclusive lock for `.uasset`, `.umap` and Unity binaries via typemap (P17, P18); mandatory changelist description on check-in (P19); `p4 undo` and Unity VCS "revert to changeset" both create a new forward revision (P20, P21). Git LFS pointer files and size limits (P22).
- Unreal Data Validation runs on save and via commandlet in CI (P13/E45).

ADAPTATION, the Sigma rule set:

1. Every nested output has `version`, `supersedes`, `status`, `publish_state` (sandbox / staged / active) and `evidence[]`.
2. Status can reach DONE only with non-empty `evidence[]` for asset-producing stages. Plan-only stages (one-pagers, ADRs, risk registers) may reach DONE on human approval alone.
3. Rollback = re-publish an older `active` version with a reason. Nothing is deleted. The Linear issue (repo rule: tasks live in Linear) carries the reason.
4. Solo mode collapses the reviewer role onto the creator with a mandatory 24-hour cool-off between WFA and DONE for identity, blockout, kit and mix-target gates. This is ADAPTATION; no source documents solo review cadence, and the parent may reject the number.
5. Team mode assigns exclusive ownership per output using task-layer language (P05) and exclusive checkout language (P17) so two contributors never edit one binary.

## 6. Mapping to Steps 0–15 (+1.5, 11.5)

| Canonical step | Game-specific nested work (ADAPTATION) | Nested workflow IDs |
|---|---|---|
| 0 Environment | Engine and DCC versions recorded; validator/preset tooling availability checked; VCS for binaries chosen (SVN / Git LFS / Perforce) | NW-ENV.8, §5 |
| 1 Ideation | Pillars, player fantasy, risk register | NW-PROTO.1 |
| 1.5 Offer architecture | Unchanged; monetisation only if monetised | — |
| 2 Architecture | Engine, renderer and GI lane, middleware ADR, performance profile, tower-of-tuning policy | NW-AUDIO.1, NW-ENV.7, NW-PROTO.2 |
| 3 UX design | Experience goals per level; character identity as design DNA; accessibility tier opt-in (AC-1) | NW-CHAR.1, NW-LEVEL.1, §4.6 |
| 4 Flow tree | Space inventory and level/puzzle graph replace screen inventory for non-UI surfaces; UI screens keep the existing flow tree | NW-ENV.2, NW-LEVEL.3 |
| 5 Wireframe prototypes | Blockout per space and reference/sheet set per character are the "wireframes"; Canvas/Direct track rule reused verbatim for DCC/engine evidence | NW-CHAR.2–3, NW-ENV.2, NW-LEVEL.6 |
| /prd-json prototype | Blockouts and prototype briefs enter the prototype backlog | NW-PROTO.2–3 |
| 6 Design system | Modular kit, material library, palette tokens, audio bus tree as "tokens" | NW-ENV.3, NW-CHAR.6, NW-AUDIO.3 |
| 7 Interface states | Fail/recovery/checkpoint states, captions and audio states, accessibility matrix | NW-LEVEL.5, NW-AUDIO.6, §4.6 |
| 8 Technical spec | Engine acceptance checklists, collision/nav contract, perf budget, mix contract, rig retarget map | NW-CHAR.7–9, NW-ENV.5–8, NW-AUDIO.3 |
| 9 Landing page | Unchanged; store page can reuse turntables and captures as evidence assets | — |
| 10 Feature breakdown | Per-character, per-space, per-level and per-audio-system rows in the PRD eligibility table | all |
| 11 PRD generation | One PRD per character / space / level / audio system with the evidence fields from §3 | all |
| /prd-json implementation | Unchanged | — |
| 11.5 Task handoff | Tasks carry `evidence_kind` and `BLOCKED / clarification required` when a creator question is unanswered | all |
| 12 Context engine | Adds game glossary (metrics, statuses, publish states) to AGENTS.md | §5 |
| 13 Skillpack | Generates the PROPOSED skills in §7 | §7 |
| 14 Runtime bootstrap | Adds validator and import-log parsers as tools (planning-side readers only) | NW-CHAR.9, NW-ENV.8 |
| 15 Observability | Audio bank-load and voice-starvation events, streaming-cell load times, playtest telemetry names | NW-AUDIO, NW-LEVEL.6 |

Atlas note for the parent: the Atlas direction doc proposes canvas-linked records for Steps 3–7 and folds 11.5 into 11. Every row above still works if 11.5 is absorbed, because the evidence fields live on the PRD and task records, not on the step number.

## 7. Skill and role assignments, company-function links

Existing Sigma agents used above (from `.claude/agents/` and the roster): design-director, ux-director, design-systems-architect, lead-architect, cpo / product-owner, qa-engineer, devils-advocate, gap-analyst, content-director, community-lead, observability-engineer, ops-director, finance-director, general-counsel, media-gen (reference imagery only, never a substitute for a modelled asset).

PROPOSED roles (not in the roster; Step 13 output if adopted): character-art-lead, environment-art-lead, tech-artist, animator, level-designer, audio-director, composer, accessibility-lead. In solo mode all PROPOSED roles resolve to the creator; the record still names the role so the review column stays meaningful.

PROPOSED skills (Step 13 output if adopted), each pointing at the SOURCE pages rather than embedding them:

| Skill | Backed by |
|---|---|
| `game-metrics-sheet` | E02, E03, L10, L07 |
| `blockout-playtest` | E06–E08, L02, L03 |
| `modular-kit-plan` | E13, E14, E17 |
| `character-identity-review` | C01, C02, C05, C06 |
| `topology-uv-material-checklist` | C10, C12, C15, C16, C17, C19 |
| `rig-retarget-map` | C20–C25, C47 |
| `engine-acceptance-validators` | C31–C36, E45–E48, P13 |
| `puzzle-dependency-graph` | L13, L14, L18, L25 |
| `level-teaching-beats` | L21, L23, L26 |
| `forgiveness-and-recovery` | L27, L43, L44 |
| `audio-mix-contract` | A04, A06, A07, A12–A14, A16 |
| `game-accessibility-matrix` | L43–L47, A17–A19 |
| `risk-prototype-brief` | L36–L39, L41 |
| `asset-publish-and-rollback` | P05, P06, P12, P17–P21 |

Company-function matrix (which department owns what in the LLC model):

| Function | Owns in game preproduction |
|---|---|
| Product (cpo) | Pillars, risk register, first-playable definition, PRD eligibility |
| Design (design-director, ux-director) | Identity, teaching, fairness, accessibility matrix, review of visual gates |
| Engineering (lead-architect, qa) | Engine, validators, acceptance, perf budget, VCS choice |
| Content (content-director) | Narrative props, dialogue tables, store assets |
| Community (community-lead) | Playtester recruiting and session logistics |
| Ops (ops-director) | Schedule, playtest calendar, status hygiene in Linear |
| Finance (finance-director) | Middleware and marketplace licences, outsourcing budget, time-box cost |
| Legal (general-counsel) | Asset, rig, font, music and voice licences; contributor IP terms for team mode |
| Marketing / GTM | Consumes turntables and captures; no preproduction ownership |

## 8. Solo-to-team idea-pack and synthesis contract (ADAPTATION)

Problem: solo is the default, but a creator may invite contributors for ideation on any nested workflow (a level's one-pager, a character's identity, a puzzle graph). The sources do not document an "idea pack" process. They do document two mechanisms the contract borrows: exclusive ownership of a slice (task layers, P05; exclusive checkout, P17) and review with retained history and dissent visible as annotations (P12).

Contract:

1. **Pack.** A contributor submits `docs/game/<domain>/<id>/packs/<contributor>-<date>.md`. Required sections: proposal (the same table shape as the target stage), evidence (what they tested or referenced, with URLs), assumptions, and "what I would kill." Packs are immutable once submitted; a revision is a new file with `supersedes`.
2. **Ownership.** Exactly one person owns the synthesis for a stage (solo: the creator). Owners never edit packs; they write `SYNTHESIS.md`.
3. **Synthesis record.** `SYNTHESIS.md` has four mandatory tables: adopted (item, from which pack, why), merged (items combined, from which packs), rejected (item, pack, reason), and **dissent** (contributor, disagreement in their words, status: open / accepted-risk / resolved-by-evidence). A synthesis with an empty dissent table and more than one pack is flagged for devils-advocate review.
4. **Attribution persists.** Adopted items keep `origin: <pack>` through the PRD and the Linear issue. The Step 11 PRD's agentic notes section lists contributors by pack ID.
5. **Dissent resolution is evidence-only.** An open dissent may be closed only by a prototype result (NW-PROTO.3) or a playtest log (NW-LEVEL.6), never by the owner's restatement.
6. **Team-mode gates.** The stage's HARD-GATE is asked once, to the owner, after synthesis. Contributors are not gate answerers; this keeps the HITL contract's "one gate per phase" rule intact.
7. **Exit to solo.** Removing contributors leaves packs and dissent tables in place. Nothing is rewritten.

## 9. Comparison of approaches and where they conflict

| Tension | Side A | Side B | Recommendation |
|---|---|---|---|
| Film review vs engine acceptance | Judge appeal posed and lit (C05, C06) | Judge import and validator pass (C31, E45) | Both, as separate gates (NW-CHAR.5 and .9) |
| Kit-first vs unique spaces | Kits as systems (E14) | Blockout then art per space (E18) | Kit lock only after the blockout of two spaces survives playtest |
| Dynamic vs baked lighting | Lumen default (E23) | Lightmass / LightmapGI for low-end (E24, E25) | Decide in Step 2 from target hardware; record UV2 need |
| Vertical slice as gate | Preproduction exit criterion (L38, L41) | Term ambiguous, plan cannot tell you fun (L42) | Define FIRST-PLAYABLE predicates per game; never reuse a generic slice |
| Linear vs branching puzzles | Diamonds between bottlenecks (L13) | Consequence-derived single-idea puzzles (L16, L17) | Graph lint enforces acyclic and no orphans; width is a creator choice |
| Middleware vs native | Feature scope favours middleware (A06, A10–A13) | Licence and complexity cost; no vendor decision doc (gap) | ADR with licence terms attached; default native for solo 2D unless adaptive music is a pillar |
| Rollback semantics | New forward revision (P20, P21) | "Delete the bad version" instinct | Forward revision only |

## 10. Source counts and open gaps

### Counts

| Lane | Verified (fetched and read) | Fetch failed or unverified |
|---|---|---|
| Characters and 2D (C) | 48 | 2 |
| Environments and 2D tilemaps (E) | 55 | 4 |
| Level, puzzle, teaching, playtest, prototyping, accessibility (L) | 50 | 3 |
| Audio (A) | 25 | 1 |
| Pipeline, review, versioning (P) | 26 | 0 |
| Reviewer anchor fetches (overlap with lanes) | 12 | 2 |

Unique verified URLs after removing the overlaps I could identify: **about 200**. The per-lane counts are exact; the unique total is approximate because the same page sometimes appears under two IDs (for example the Level Design Book blockout page is E06 and L02, Data Validation is E45 and P13, Asset Pipeline is C45 and P05).

Evidence kinds among verified sources: official engine or tool docs, Blender Studio docs and blog, practitioner articles and transcripts, GDC Vault page descriptions (never video), one academic abstract, two third-party mirrors (ASWG-R001 PDF, Cerny slides) flagged as such.

### Open gaps (what the parent still needs)

1. **Wwise Help deep pages** (SoundBanks, Events, Dialogue Events, interactive music, naming): every fetcher returned 403. Only the TOC and course syllabi are verified. Needs a browser-lane fetch.
2. **Texel density**: the standard Iezzi guide 404s; only a definition page (C18) and a forum mention (E16) are verified. No numeric texel targets should be quoted yet.
3. **Numeric polycount and draw-call budgets per platform**: sources defer to the lead artist (C12) or give enterprise-style ceilings (E33). Budgets remain creator inputs.
4. **Environment art bible, prop list, density pass, audio QA checklist templates**: practice described, no template published. All templates here are ADAPTATION.
5. **Pixel-art proportion and sprite-size guidance**: no official doc found.
6. **Unreal glTF import, Unity model-tab scale factor, Unity NavMesh Surface agent settings, Godot "units are metres" page, Godot accessibility tutorial**: not fetched or do not exist.
7. **Primary texts not verified**: Thomas and Johnston, Richard Williams, Loomis, Fullerton's process chapters, Schell's lenses, Swink's game feel (only the site landing page), Elyot Grant's 30 lessons, Zachtronics (members-only), Blow/ten Bosch (no transcript), Sid Meier's rules (not on the Vault page), Hayashida's structure (interview only), Celeste Assist Mode design notes, Alan Hazelden essays.
8. **Vendor middleware-vs-native decision doc**: does not exist; decision must be derived.
9. **Blender Studio SVN commit and rollback conventions**: SVN use is documented (P03); conventions are not.
10. **Solo review cadence**: no source; the 24-hour cool-off in §5 is a proposal.
11. **Atlas stage alignment**: Atlas has twenty stages through 18 per the work ledger; this review maps to canonical 0–15 only. The parent owns the crosswalk.
12. **Grok comparison**: this review has not seen `GROK-ASSETS-TECHNICAL.md` or `GROK-DESIGN-PRODUCTION.md`; overlaps and conflicts are for the parent to reconcile.

Execution status of this document: PLANNED-ONLY for every workflow; NOT-EXECUTED for every evidence field. No asset, build, import, render, playtest or meter reading was produced or claimed.

## Appendix A — Source register

Format: ID — URL — author/org — type — date shown (n.d. if none). All fetched and read 2026-09-22. Vault entries are page descriptions only.

### C — Characters and 2D character equivalents

- C01 — https://studio.blender.org/blog/chunkification-creating-a-design-language-for-sprite-fright/ — Christian Bunyan, Blender Studio — studio blog — 2021-02-01
- C02 — https://studio.blender.org/projects/sprite-fright/character_lineup/ — Blender Studio — production asset index — n.d. (mostly subscriber-gated)
- C03 — http://wiki.polycount.com/wiki/Character — Polycount wiki — community wiki — n.d.
- C04 — https://en.wikipedia.org/wiki/Body_proportions — Wikipedia — reference — n.d.
- C05 — https://studio.blender.org/blog/automatic-model-sheets/ — Julien Kaspar, Blender Studio — studio blog — 2024-01-15
- C06 — https://studio.blender.org/blog/sprite-fright-sculpting-advice-for-production/ — Julien Kaspar — studio blog — 2021-12-14
- C07 — https://docs.blender.org/manual/en/latest/modeling/empties.html — Blender manual 5.2 LTS — official doc
- C08 — https://studio.blender.org/training/stylized-character-workflow/chapter/5d3583da84e830f1f7fee8e1/ — Julien Kaspar — training gallery — n.d.
- C09 — http://en.esotericsoftware.com/spine-skins — Esoteric Software — official doc
- C10 — http://wiki.polycount.com/wiki/Topology — Polycount wiki — last modified 2017-03-07
- C11 — http://wiki.polycount.com/wiki/BodyTopology — Polycount wiki — gallery
- C12 — http://wiki.polycount.com/wiki/Polygon_Count — Polycount wiki
- C13 — https://studio.blender.org/training/stylized-character-workflow/ — Julien Kaspar — training course (Blender 2.8 era)
- C14 — https://studio.blender.org/training/stylized-character-workflow/5e600b3ffa0f94ccd11063ec/ — Julien Kaspar — CC-BY cheat sheet
- C15 — https://docs.blender.org/manual/en/latest/modeling/meshes/uv/unwrapping/introduction.html and https://docs.blender.org/manual/en/latest/modeling/meshes/uv/unwrapping/seams.html — Blender manual 5.2 LTS
- C16 — https://dev.epicgames.com/documentation/en-us/unreal-engine/physically-based-materials-in-unreal-engine — Epic — UE 5.8
- C17 — https://docs.unity3d.com/Manual/StandardShaderMaterialCharts.html — Unity 6.6 manual
- C18 — http://wiki.polycount.com/wiki/Texel — Polycount wiki — last modified 2021-06-01
- C19 — https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html (also 4.1 path) — Blender manual
- C20 — https://docs.blender.org/manual/en/4.1/addons/rigging/rigify/introduction.html — Blender manual 4.1 (my own fetch of the 4.2 path returned HTTP 200 with a TOC-only body; the "latest" path 404s)
- C21 — https://studio.blender.org/tools/addons/cloudrig/introduction — Blender Studio tools docs
- C22 — https://studio.blender.org/blog/rigging-sprite-fright-video-introduction/ — Christian Bunyan — video post, page text only — 2021-05-25
- C23 — https://dev.epicgames.com/documentation/en-us/unreal-engine/control-rig-in-unreal-engine — Epic — UE 5.8
- C24 — https://docs.unity3d.com/Manual/AvatarCreationandSetup.html and https://docs.unity3d.com/Manual/class-Avatar.html — Unity 6.6
- C25 — https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html — Godot 4.7
- C26 — https://docs.blender.org/manual/en/latest/sculpt_paint/weight_paint/introduction.html — Blender manual (thin fetch; pointer only)
- C27 — https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation — Wikipedia — secondary for Thomas and Johnston
- C28 — https://dev.epicgames.com/documentation/en-us/unreal-engine/animation-in-lyra-sample-game-in-unreal-engine — Epic — UE 5.8
- C29 — https://dev.epicgames.com/documentation/en-us/unreal-engine/root-motion-in-unreal-engine — Epic — UE 5.8
- C30 — https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html — Godot 4.7
- C31 — https://dev.epicgames.com/documentation/en-us/unreal-engine/fbx-skeletal-mesh-pipeline-in-unreal-engine — Epic — UE 5.8 (also my own fetch)
- C32 — https://dev.epicgames.com/documentation/en-us/unreal-engine/importing-skeletal-mesh-lods-using-fbx-in-unreal-engine — Epic — UE 5.8
- C33 — https://docs.unity3d.com/Manual/ImportingModelFiles.html — Unity 6.6
- C34 — https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html — Godot 4.7
- C35 — https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html — Godot 4.7 (also my own fetch)
- C36 — https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html — Godot 4.7
- C37 — https://www.aseprite.org/docs/sprite-sheet/ — Igara Studio — official doc
- C38 — http://en.esotericsoftware.com/spine-meshes — Esoteric Software
- C39 — http://en.esotericsoftware.com/spine-weights — Esoteric Software
- C40 — http://en.esotericsoftware.com/spine-skeletons — Esoteric Software
- C41 — https://docs.unity3d.com/Packages/com.unity.2d.animation@10.1/manual/SkinningEditor.html — Unity 2D Animation 10.1.4
- C42 — http://docs.unity3d.com/Manual/sprite/atlas/sprite-atlas-reference.html — Unity 6.6
- C43 — https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html — Godot 4.7
- C44 — https://studio.blender.org/tools/pipeline-overview/introduction — Blender Studio tools docs (same as P02)
- C45 — https://studio.blender.org/tools/addons/asset_pipeline — Blender Studio tools docs (same as P05; also my own fetch)
- C46 — https://studio.blender.org/characters/ — Blender Studio character library
- C47 — https://studio.blender.org/characters/snow/v2/ — Demeter Dzadik — 2022-03-11 — Blender 3.1, CC-BY
- C48 — https://studio.blender.org/blog/introducing-snow/ — Francesco Siddi — 2022-03-10

Unverified in this lane: Leonardo Iezzi texel density PDF (404); hippydrome.com (no content); Blender Studio concept-and-design pipeline page (placeholder).

### E — Environments and 2D tilemaps

- E01 — https://dev.epicgames.com/documentation/en-us/unreal-engine/units-of-measurement-in-unreal-engine — Epic — UE 5.8
- E02 — https://dev.epicgames.com/documentation/unreal-engine/designer-01-project-setup-and-level-blockout-in-unreal-engine — Epic Designer Track — UE 5.8
- E03 — https://book.leveldesignbook.com/process/blockout/metrics — The Level Design Book — n.d.
- E04 — https://docs.blender.org/manual/en/latest/scene_layout/scene/properties.html — Blender manual 5.2 LTS
- E05 — https://docs.blender.org/manual/en/latest/editors/3dview/controls/snapping.html — Blender manual 5.2 LTS
- E06 — https://book.leveldesignbook.com/process/blockout — The Level Design Book (same as L02; also my own fetch)
- E07 — https://book.leveldesignbook.com/process/blockout/playtesting — The Level Design Book (same as L03)
- E08 — https://www.blog.radiator.debacle.us/2017/09/how-to-graybox-blockout-3d-video-game.html — Robert Yang — 2017-09-15
- E09 — https://www.gdcvault.com/play/1025360/Level-Design-Workshop-Invisible-Intuition — David Shaver, Robert Yang — Vault description
- E10 — https://docs.unity3d.com/Packages/com.unity.probuilder@6.0/manual/overview.html — Unity ProBuilder 6.0.9
- E11 — https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html — Godot 4.7 (page flagged possibly outdated)
- E12 — https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-geometry-tools-in-unreal-engine — Epic — UE 5.8
- E13 — https://book.leveldesignbook.com/process/blockout/metrics/modular — The Level Design Book
- E14 — http://blog.joelburgess.com/2013/04/skyrims-modular-level-design-gdc-2013.html — Joel Burgess, Nate Purkeypile — transcript — 2013-04-19
- E15 — http://wiki.polycount.com/wiki/Modular_environments — Polycount wiki
- E16 — https://polycount.com/discussion/210492/tutorial-trim-textures-for-environment-art-and-props — Tim Simpson — 2019-04-12
- E17 — https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html — Godot 4.7
- E18 — https://book.leveldesignbook.com/process/env-art — The Level Design Book
- E19 — https://www.gdcvault.com/play/1012647/What-Happened-Here-Environmental — Harvey Smith, Matthias Worch — Vault description — 2010
- E20 — https://andrewyoderdesign.blog/2015/09/24/environmental-storytelling-and-gone-home/ — Andrew Yoder — 2015-09-24
- E21 — https://80.lv/articles/defining-environment-language-for-video-games — Emilia Schatz — 2017-06-27 (same as L07)
- E22 — https://www.gdcvault.com/play/1024310/Art-Direction-Bootcamp-Cinematic-Environment — Naughty Dog — Vault description
- E23 — https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-global-illumination-and-reflections-in-unreal-engine — Epic — UE 5.8
- E24 — https://dev.epicgames.com/documentation/en-us/unreal-engine/lightmass-basics-in-unreal-engine — Epic — UE 5.8
- E25 — https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html — Godot 4.7
- E26 — https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/introduction_to_global_illumination.html — Godot 4.7
- E27 — https://docs.unity3d.com/Manual/LightingOverview.html — Unity 6.5
- E28 — https://dev.epicgames.com/documentation/en-us/unreal-engine/simple-versus-complex-collision-in-unreal-engine — Epic — UE 5.8
- E29 — https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_3d.html — Godot 4.7
- E30 — https://docs.unity3d.com/Packages/com.unity.ai.navigation@2.0/manual/CreateNavMesh.html — Unity AI Navigation 2.0.14
- E31 — https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_3d.html — Godot 4.7
- E32 — https://dev.epicgames.com/documentation/en-us/unreal-engine/introduction-to-performance-profiling-and-configuration-in-unreal-engine — Epic — UE 5.8
- E33 — https://dev.epicgames.com/documentation/en-us/unreal-engine/guidelines-for-optimizing-rendering-for-real-time-in-unreal-engine — Epic — UE 5.8
- E34 — https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine — Epic — UE 5.8
- E35 — https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition---hierarchical-level-of-detail-in-unreal-engine — Epic — UE 5.8
- E36 — https://dev.epicgames.com/documentation/en-us/unreal-engine/nanite-virtualized-geometry-in-unreal-engine — Epic — UE 5.8
- E37 — https://dev.epicgames.com/documentation/en-us/unreal-engine/city-sample-project-unreal-engine-demonstration — Epic — UE 5.8
- E38 — https://docs.unity3d.com/Manual/OcclusionCulling.html — Unity 6
- E39 — https://docs.unity3d.com/Manual/LevelOfDetail.html — Unity 6.5
- E40 — https://docs.unity3d.com/Manual/optimizing-draw-calls.html — Unity
- E41 — https://docs.unity3d.com/Manual/Profiler.html — Unity
- E42 — https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html — Godot 4.7
- E43 — https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html — Godot 4.7
- E44 — https://docs.godotengine.org/en/stable/tutorials/performance/index.html — Godot 4.7
- E45 — https://dev.epicgames.com/documentation/en-us/unreal-engine/data-validation-in-unreal-engine — Epic — UE 5.8 (same as P13; also my own fetch)
- E46 — https://dev.epicgames.com/documentation/en-us/unreal-engine/recommended-asset-naming-conventions-in-unreal-engine-projects — Epic — UE 5.8
- E47 — https://docs.unity3d.com/Manual/Presets.html — Unity 6.5
- E48 — https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html — Godot 4.7
- E49 — https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html — Godot 4.7
- E50 — https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html — Godot 4.7
- E51 — https://docs.unity3d.com/Manual/Tilemap.html — Unity 6.5
- E52 — https://docs.unity3d.com/Manual/class-Tilemap.html — Unity 6.5
- E53 — https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html — Godot 4.7
- E54 — https://docs.unity3d.com/Packages/com.unity.2d.pixel-perfect@5.1/manual/index.html — Unity 2D Pixel Perfect 5.1.1
- E55 — https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html — Godot 4.7

Unverified in this lane: Polycount texel density page (not found); Unity lighting-choose page (404); Unity isometric tilemap intro (404); Unity NavMesh Surface settings page (not fetched).

### L — Level, puzzle, teaching, playtest, prototyping, accessibility

- L01 — https://book.leveldesignbook.com/ — The Level Design Book — CC BY-NC-SA 4.0
- L02 — https://book.leveldesignbook.com/process/blockout — (same as E06)
- L03 — https://book.leveldesignbook.com/process/blockout/playtesting — (same as E07)
- L04 — https://gdcvault.com/play/1012356/One-Page — Stone Librande — Vault description, free — 2010 (also my own fetch)
- L05 — https://archive.org/details/one-page-designs-gdc-2010 — third-party upload of the slides — 2022-09-09 (binary not opened)
- L06 — https://www.gamedeveloper.com/design/video-one-page-designs — Danielle Riendeau — editorial — 2023-08-08
- L07 — https://80.lv/articles/defining-environment-language-for-video-games — Emilia Schatz — 2017-06-27
- L08 — https://gdcvault.com/browse/gdc-17/play/1024301 — Steve Lee — Vault description — 2017
- L09 — https://andrewyoderdesign.blog/2020/03/21/what-do-we-even-mean-by-level-design/ — Andrew Yoder — 2020-03-21
- L10 — https://www.gamedeveloper.com/design/level-design-for-combat — Max Pears — 2019-08-14
- L11 — https://peterfieldis.wixsite.com/peter-field-design/level-design-huddles — Peter Field — n.d.
- L12 — https://www.gamedeveloper.com/design/the-rational-design-handbook-an-intro-to-rld — Luke McMillan — 2013-08-06
- L13 — https://grumpygamer.com/puzzle_dependency_charts/ — Ron Gilbert — 2014-08-10 (also my own fetch)
- L14 — https://grumpygamer.com/why_adventure_games_suck/ — Ron Gilbert — posted 2004-05-12, written 1989
- L15 — https://gdcvault.com/play/1027306/30-Puzzle-Design-Lessons-From — Elyot Grant — Vault description — 2021
- L16 — https://marctenbosch.com/news/2011/11/designing-to-reveal-the-nature-of-the-universe/ — Marc ten Bosch, Jonathan Blow — talk page — 2011-11-03
- L17 — https://www.gamedeveloper.com/design/indiecade-inside-jonathan-blow-s-puzzle-design-process — Mathew Kumar — press — 2011-10-08
- L18 — http://www.lucasstyle.com/tutorials/Designing_The_Puzzle.pdf — Bob Bates, GDC 1997 — third-party mirror
- L19 — https://gdcvault.com/play/1025715/Open-Ended-Puzzle-Design-at — Zach Barth — Vault description, members-only — 2019
- L20 — https://www.puzzlescript.net/Documentation/documentation.html — increpare — official docs
- L21 — https://theportalwiki.com/wiki/Portal_developer_commentary — Valve staff, fan transcript
- L22 — https://www.gdcvault.com/play/1015833/Thinking-In-3D-The-Development — Koichi Hayashida — Vault description — 2012 (no kishōtenketsu on page)
- L23 — https://www.gamedeveloper.com/design/the-secret-to-i-mario-i-level-design — Christian Nutt interviewing Hayashida — 2012-04-13
- L24 — https://w.itch.io/level-design-lessons — Anna Anthropy — store page (PDF not opened)
- L25 — https://lostgarden.com/2007/07/19/the-chemistry-of-game-design/ — Daniel Cook — 2007-07-19
- L26 — https://celiahodent.com/gamers-brain-ux-onboarding/ — Celia Hodent — author's talk summary — 2016-03-22
- L27 — https://maddythorson.medium.com/celeste-forgiveness-31e4a40399f1 — Maddy Thorson — 2022-04-25 archive of 2020 thread
- L28 — https://celiahodent.com/the-gamers-brain/ — Celia Hodent — book page (text reads like a talk recap)
- L29 — https://www.gamedesignworkshop.com/ — Tracy Fullerton — book site, 5th ed.
- L30 — http://www.game-feel.com/ — Steve Swink — book site (minimal content)
- L31 — https://gdcvault.com/play/1012186/The-Psychology-of-Game-Design — Sid Meier — Vault description — 2010
- L32 — https://schellgames.com/art-of-game-design — Jesse Schell — book page, 3rd ed.
- L33 — https://gdcvault.com/play/1015821/Creating-a-Sequel-to-a — Faliszek, Wolpaw — Vault description — 2012
- L34 — https://www.gdcvault.com/play/1015745/Attention-Not-Immersion-Making-Your — Richard Lemarchand — Vault description — 2012
- L35 — https://gdcvault.com/play/1015581/Playtesting-and-Metrics-Getting-the — Jordan Lynn — Vault description — 2012
- L36 — https://chrishecker.com/Advanced_Prototyping — Chris Hecker, Chaim Gingold — slides and MP3 linked — GDC 2006 (also my own fetch)
- L37 — https://www.levitylab.com/blog/2011/01/catastrophic-prototyping-and-other-stories/ — Chaim Gingold — 2011-01-20
- L38 — https://www.slideshare.net/holtt/cerny-method — Mark Cerny, D.I.C.E. 2002 — third-party slide upload
- L39 — https://www.gamedeveloper.com/game-platforms/how-to-prototype-a-game-in-under-7-days — Gabler, Gray, Kucic, Shodhan — 2005-10-26
- L40 — https://supercell.com/en/news/learning-from-failures/ — Supercell — 2026-01-15
- L41 — https://gdcvault.com/play/1022328/The-Vertical-Slice — Greg Donovan — Vault description — 2015
- L42 — https://www.gamedeveloper.com/design/why-we-should-stop-saying-vertical-slices- — Clinton Keith — 2011-12-01
- L43 — https://gameaccessibilityguidelines.com/basic/ — Game Accessibility Guidelines (also my own fetch)
- L44 — https://gameaccessibilityguidelines.com/intermediate/ — Game Accessibility Guidelines
- L45 — https://gameaccessibilityguidelines.com/advanced/ — Game Accessibility Guidelines
- L46 — https://learn.microsoft.com/en-us/gaming/accessibility/guidelines — Microsoft — XAG v3.2 (2023-06-08), page updated 2026-08
- L47 — https://accessible.games/accessible-player-experiences/ — AbleGamers APX
- L48 — https://ian-hamilton.com/a-history-of-game-accessibility-guidelines/ — Ian Hamilton — 2021-06-16
- L49 — https://dev.epicgames.com/documentation/en-us/unreal-engine/designing-ui-for-accessibility-in-unreal-engine — Epic — UE 5.8
- L50 — https://docs.godotengine.org/en/latest/classes/class_accessibilityserver.html — Godot 4.7 class reference (companion: https://godotengine.org/releases/4.5/)

Unverified in this lane: Alan Hazelden essays; Celeste Assist Mode notes; Blow/ten Bosch transcript; Sid Meier 33 percent rule; Steve Lee text-first material (video only).

### A — Audio

- A01 — https://www.audiokinetic.com/en/library/edge/?id=concept_events.html — Audiokinetic — Wwise Help TOC only (deep pages 403)
- A02 — https://www.audiokinetic.com/en/courses/wwise101/?id=adding_an_event_to_soundbank — Audiokinetic — Wwise-101 syllabus (Wwise 2024.1)
- A03 — https://www.audiokinetic.com/en/courses/wwise201/?id=lesson_2_re_orchestration_using_vertical_approach/ — Audiokinetic — Wwise-201 syllabus (2025.1)
- A04 — https://www.audiokinetic.com/naming-convention-best-practices/ — Can Uzer, Audiokinetic blog — 2025-01-23
- A05 — https://www.audiokinetic.com/en/blog/dialogue-narration-in-wwise-and-unity/ — Jake Gamelin — 2021-08-27
- A06 — https://www.fmod.com/docs/2.03/studio/fmod-studio-concepts.html — Firelight — FMOD Studio 2.03 manual
- A07 — https://www.fmod.com/docs/2.03/studio/getting-events-into-your-game.html — Firelight — 2.03
- A08 — https://www.fmod.com/docs/2.03/studio/dialogue-and-localization.html — Firelight — 2.03
- A09 — https://www.fmod.com/docs/2.03/studio/using-source-control.html — Firelight — 2.03
- A10 — https://dev.epicgames.com/documentation/unreal-engine/metasounds-reference-guide-in-unreal-engine — Epic — UE 5.8
- A11 — https://dev.epicgames.com/documentation/en-us/unreal-engine/audio-modulation-overview-in-unreal-engine — Epic — UE 5.8
- A12 — https://docs.unity3d.com/Manual/AudioMixerOverview.html — Unity 6.6 (build 2026-09-21)
- A13 — https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html — Godot 4.7
- A14 — http://gameaudiopodcast.com/ASWG-R001.pdf — Sony ASWG-R001 v1.10 — August 2013 — third-party mirror
- A15 — https://designingsound.org/2012/07/30/video-games-and-loudness-standards-interview-with-sonys-garry-taylor/ — Designing Sound — 2012-07-30
- A16 — https://tech.ebu.ch/publications/r128 — EBU R 128 v5.0 — November 2023
- A17 — https://gameaccessibilityguidelines.com/provide-separate-volume-controls-or-mutes-for-effects-speech-and-background-music/ — GAG
- A18 — https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-sounds-alone/ — GAG
- A19 — https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/104 — Microsoft — XAG 104 — updated 2026-06-17
- A20 — https://www.gdcvault.com/play/1020240/Peggle-2-Live-Orchestra-Meets — Guy Whitmore — Vault description — 2014
- A21 — https://www.gamedeveloper.com/audio/horizontal-resequencing-and-dynamic-transitions-for-game-music-composers — Winifred Phillips — 2021-09-15
- A22 — https://www.gameaudiolearning.com/knowledgebase/audio-middleware-and-how-to-use-it — Greg Lester — community explainer — May 2022
- A23 — https://arxiv.org/abs/2311.16645 — Butt et al. — academic abstract — 2023-11-28
- A24 — https://dev.epicgames.com/documentation/en-us/unreal-engine/using-dialogue-voices-and-waves-in-unreal-engine?application_version=5.4 — Epic — UE 5.4 (fetch title carried "Error: 403"; body read; re-fetch before quoting at length)
- A25 — https://www.gamesoundcon.com/blog-1 — Brian Schmidt — blog index only

Unverified in this lane: Wwise Help deep pages (403); Phillips vertical-layering companion article (not fetched); Sony-hosted ASWG copy (not found).

### P — Pipeline, review, versioning

- P01 — https://studio.blender.org/tools/ — Blender Studio (also my own fetch)
- P02 — https://studio.blender.org/tools/pipeline-overview/introduction — Blender Studio
- P03 — https://studio.blender.org/tools/pipeline-overview/infrastructure — Blender Studio — updated 2023-04-30
- P04 — https://studio.blender.org/tools/pipeline-overview/quick-start/usage — Blender Studio — 2023-10-15
- P05 — https://studio.blender.org/tools/addons/asset_pipeline — Blender Studio (also my own fetch)
- P06 — https://studio.blender.org/tools/user-guide/kitsu — Blender Studio
- P07 — https://studio.blender.org/tools/addons/blender_kitsu — Blender Studio
- P08 — https://studio.blender.org/blog/the-blender-studio-pipeline/ — Francesco Siddi — 2021-07-13
- P09 — https://studio.blender.org/blog/kitsu-addon-for-blender/ — Paul Golter — 2021-07-21
- P10 — https://kitsu.cg-wire.com/guides/review-publishing/update-task-progress/ — CGWire
- P11 — https://kitsu.cg-wire.com/guides/review-publishing/publish/ — CGWire
- P12 — https://kitsu.cg-wire.com/guides/review-publishing/review/ — CGWire (also my own fetch; companion https://kitsu.cg-wire.com/supervisor-tasks/)
- P13 — https://dev.epicgames.com/documentation/unreal-engine/data-validation-in-unreal-engine — Epic — UE 5.8
- P14 — https://github.com/Allar/ue5-style-guide — Michael Allar — MIT — community
- P15 — https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html — Godot 4.7
- P16 — https://unity.com/how-to/organizing-your-project — Unity
- P17 — https://help.perforce.com/helix-core/quickstart/current/Content/quickstart/admin-create-typemap.html — Perforce
- P18 — https://dev.epicgames.com/documentation/en-us/unreal-engine/using-perforce-as-source-control-for-unreal-engine — Epic — UE 5.8
- P19 — https://dev.epicgames.com/documentation/unreal-engine/source-control-in-unreal-engine — Epic — UE 5.8 (companion: collaboration-and-version-control hub)
- P20 — https://help.perforce.com/helix-core/server-apps/cmdref/current/Content/CmdRef/p4_undo.html — Perforce 2026.1 (companion P4V undo page)
- P21 — https://docs.unity.com/en-us/unity-version-control/vcs-plugins/unityeditor-plugin/revert-to-changeset — Unity Version Control
- P22 — https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage — GitHub (companion https://git-lfs.com/)
- P23 — https://studio.blender.org/projects/charge/production-log/197/ — Blender Studio — 2022-07-11
- P24 — https://studio.blender.org/blog/production-log-a-new-project/ — Fiona Cohen — 2023-10-13
- P25 — https://gdcvault.com/play/1026613/Independent-Games-Summit-Crafting-A — Adam Robinson-Yu — Vault description — 2020
- P26 — https://studio.blender.org/projects/wing-it/3c32f6870225b6/ — Blender Studio — video listing, descriptions only

### Reviewer anchor fetches (my own, 2026-09-22)

Blender Studio tools landing (P01); Blender Studio artist-guide project overview https://studio.blender.org/tools/artist-guide/project_tools/project-overview (folder layout `local/ shared/ svn/`, SVN or Git LFS, `pro/assets/`); Asset Pipeline add-on (P05); grumpygamer puzzle dependency charts (L13); chrishecker.com Advanced Prototyping (L36); GAG Basic (L43); Level Design Book blockout (E06/L02); Unreal Data Validation (E45/P13); Rigify 4.2 introduction path (HTTP 200, TOC-only body; latest path 404); Kitsu home https://kitsu.cg-wire.com/ and review page (P12); GDC Vault One-Page Designs (L04); Godot model export considerations (C35); Unreal FBX skeletal mesh pipeline (C31). Failed: two `latest` Rigify paths (404).
