# Characters: identity to engine receipt

Generated from catalog 1.0.0.

Take a playable being or creature from a locked identity through separate reference views, part sheets, geometry, comparison, UV, materials, rig, deformation, animation, contact states and engine validation. Each phase names its 2D, sprite, vector or text equivalent so the workflow does not assume a 3D mesh.

Applicability: Applies to any character, creature, vehicle-as-character or avatar the player sees or controls. Games with no visible characters (text, abstract, pure UI) mark this workflow not-applicable with that reason. Background characters may skip phases according to their asset level from Step 10, each skip recorded with a reason. Art mode from the architecture decision picks the artifact names in each phase; 3D is never assumed.

Atlas stages: 3, 4, 5, 6, 7, 8, 10, 11. Canonical steps: 3, 4, 5, 6, 7, 8, 10, 11, 11.5.

## identity-proportions — Identity and proportion lock

### Creator questions

- **role**: Who is this character in play terms: what the player does with or against them, and which experience goal they serve?
- **silhouette**: Describe the silhouette in one sentence a stranger could draw from. What makes it distinct from every other character at play distance?
- **proportions**: Proportion set in head-heights or a stated unit (for 2D: pixel height at native resolution and grid). Include scale references from the world rules.
- **material-language**: Material or palette language: which surfaces, which colours or ramps, what is forbidden?
- **mutable-parts**: Which parts may change independently later (head, hair, outfit, weapon, cloth layers, palette swaps)?
- **provenance**: Where did the design come from (own drawing, commissioned, generated, marketplace)? What license and provenance record exists?

### inputs

- World rules
- Experience-goal sheet
- Asset level (hero, supporting, background)
- Art mode

### activities

- Write the identity package before any modelling or spriting
- Run the lineup test: two reviewers pick this character from lookalikes using only the sheet
- Record provenance in the sidecar draft

### tools

- Drawing or painting tool
- Atlas document editor

### skills

- game-art-pipeline
- game-world-design

### roles

- creator
- game-art-director
- game-design-lead

### outputs

- Identity and proportion sheet
- Provenance sidecar draft

### dependencies

- None specified.

### reviewCriteria

- Two reviewers pass the lineup test
- Proportions are in a stated unit with world scale references
- Provenance is recorded, not 'we'll find out'

### revisionRules

- Changing proportions or silhouette re-opens every later character phase for this subject
- A palette change re-opens texture-material-channels only

### Evidence required

Lineup test result: who reviewed, which lookalikes, pass or fail. Planned lineups are recorded as planned. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Character - Polycount wiki](http://wiki.polycount.com/wiki/Character) — source-claim. Search extract; URL reconstructed from the page title. Dated community text; adapt for stylised and 2D work.
- [Daz 3D launches game-ready character assets (Creative Bloq)](https://www.creativebloq.com/3d/daz-3d-launches-game-ready-character-assets-to-make-unreal-unity-and-blender-easier) — source-claim. Marketing. Rights and provenance not reviewed; drop-in claims untested.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.

## view-sheets — Separate reference views: front, back, side, three-quarter

### Creator questions

- **views**: Which views exist as separate image files: front, back, left or right side, three-quarter, and optionally top? Each must be loadable alone as a camera background or sprite guide.
- **scale-bar**: Does each view carry the same scale bar or head-height ticks and the same eye line?
- **consistency**: Do the views agree with each other (feature heights line up across front and side)? Which discrepancies were found and fixed?
- **2d-equivalent**: For sprite or vector work: the orthographic sheet and facing set (for example 4 or 8 directions) that replaces 3D views. Mark 3D views not-applicable with that reason.

### inputs

- Identity and proportion sheet

### activities

- Produce each view as its own file, not a collage
- Align feature heights across views with guide lines
- For 2D, produce the facing set at native resolution

### tools

- Drawing tool with guide lines
- Image editor

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Separate view files (front, back, side, three-quarter) or the 2D facing sheet

### dependencies

- identity-proportions

### reviewCriteria

- Each view is a separate file with a scale reference
- Feature heights agree across views
- Views match the identity sheet in the lineup test

### revisionRules

- A changed view re-opens geometry-plan and multiview-comparison

### Evidence required

The files exist and a reviewer overlaid front and side at the eye line; note the discrepancies found. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Character - Polycount wiki](http://wiki.polycount.com/wiki/Character) — source-claim. Search extract; URL reconstructed from the page title. Dated community text; adapt for stylised and 2D work.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.

## component-sheets — Component, clothing, prop and material sheets

### Creator questions

- **anatomy**: Anatomy or structure sheet: which deformable regions exist (joints, jaw, cloth, tail, wheels) and which are rigid?
- **components**: Component sheet: every named part (head, hair, torso, hands, feet, accessories) with its boundary and whether it is swappable.
- **clothing**: Clothing sheet: layers in order, which layer covers which, forbidden intersections, and what is separate geometry versus painted.
- **props**: Prop sheet: held or attached items with attachment points, sockets or pivot names, and which hand or slot.
- **materials**: Material sheet: per part the material or palette entry, roughness or shading style, emissive or special cases, and the target material or palette count.

### inputs

- View sheets
- Identity sheet
- Mutable parts list

### activities

- Produce one sheet per family; a single beauty render is not a sheet pack
- Name every deformable part and every socket
- Set the material or palette count against the Step 6 budget

### tools

- Drawing tool
- Spreadsheet for part and material lists

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Anatomy, component, clothing, prop and material sheets

### dependencies

- view-sheets

### reviewCriteria

- Every deformable part is named
- Cloth layers and forbidden intersections are listed
- Material or palette count is within budget or an exception is recorded

### revisionRules

- Adding a part re-opens geometry-plan, uv-layout, rig-plan
- A material count change re-opens texture-material-channels

### Evidence required

The sheets use consistent part names. Record who reviewed them, what was checked and any independent review still needed. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Character - Polycount wiki](http://wiki.polycount.com/wiki/Character) — source-claim. Search extract; URL reconstructed from the page title. Dated community text; adapt for stylised and 2D work.
- [Daz 3D launches game-ready character assets (Creative Bloq)](https://www.creativebloq.com/3d/daz-3d-launches-game-ready-character-assets-to-make-unreal-unity-and-blender-easier) — source-claim. Marketing. Rights and provenance not reviewed; drop-in claims untested.
- [#5 Testing the Asset Pipeline - Project Storm - Blender Studio](https://studio.blender.org/projects/storm/production-log/310/) — verified-source-text. Production log extract (2025-06-23). Open-movie production, not games. Some media behind subscription.

## geometry-plan — Geometry, topology and LOD plan

### Creator questions

- **budget**: Triangle budget per LOD (or sprite size and frame count for 2D) with the hardware class it was set for.
- **topology-law**: Where must edge loops or density serve deformation (hips, shoulders, mouth corners, knees, elbows, hands, or the equivalent for this body plan)? For 2D: pivot placement and silhouette pixel rules.
- **high-low**: Is there a high-poly detail donor and a retopologised runtime mesh, or a single mesh? For AI-generated or scanned sources: what decimation and cleanup plan?
- **hidden-surfaces**: Which surfaces are never visible at the play camera and will be removed (undersides, interior faces)?
- **lod-policy**: LOD levels and the camera distance each must still read at; for 2D, mip or scaling policy.

### inputs

- View sheets
- Component sheets
- Budgets from Step 6
- Art mode

### activities

- Write the plan before modelling
- Set density by curvature then joints
- Plan hidden-surface removal and decimation with before/after counts to record

### tools

- DCC (any) or sprite editor
- Spreadsheet

### skills

- game-art-pipeline
- game-technical-production

### roles

- creator
- game-art-director
- game-technical-director

### outputs

- Geometry plan with budgets, topology law, LOD policy

### dependencies

- component-sheets

### reviewCriteria

- Budgets are numbers tied to a hardware class
- Deformation zones are named for this body plan
- Hidden-surface decisions are explicit

### revisionRules

- A budget change from Step 6 re-opens this plan
- A new mutable part re-opens the LOD policy

### Evidence required

Plan only. Actual counts are recorded in multiview-comparison and engine-validation. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Topology - Polycount wiki](http://wiki.polycount.com/wiki/Topology) — source-claim. Search extract; community wiki, dated articles; URL reconstructed from the page title. Not an official engine standard.
- [Character - Polycount wiki](http://wiki.polycount.com/wiki/Character) — source-claim. Search extract; URL reconstructed from the page title. Dated community text; adapt for stylised and 2D work.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [Brian Tindall - IMDb](https://www.imdb.com/name/nm2457314/) — source-claim. Credits only. Do not derive a rigging doctrine from credits.

## multiview-comparison — Multiview comparison of the built model against the references

### Creator questions

- **overlay**: For each view: was the model rendered orthographically at the same framing and overlaid on the reference view? Where did it deviate beyond the agreed pixel or percentage tolerance?
- **counts**: Actual vertex, triangle and object counts read from the tool per LOD, versus the plan.
- **deform-poses**: Which test poses were checked (squat, reach, look-up, sit, grip, or this body plan's equivalents) and which regions pinched or tore?
- **decision**: Accept, fix and re-compare, or return to geometry-plan?

### inputs

- Built block mesh or production mesh (or sprite set)
- View sheets
- Geometry plan

### activities

- Render orthographic stills at identical framing and lighting
- Overlay against the separate view files and mark deviations
- Read counts from the tool, never estimate
- Pose the mesh in test poses before rigging

### tools

- DCC orthographic camera or sprite overlay
- Image editor for overlays

### skills

- game-art-pipeline

### roles

- creator
- game-art-director
- game-technical-director

### outputs

- Comparison contact sheet with counts and deviations

### dependencies

- geometry-plan
- view-sheets

### reviewCriteria

- Overlays exist for every view
- Counts are tool-read
- Deviations are within tolerance or a fix is scheduled

### revisionRules

- A failed comparison re-opens geometry-plan or view-sheets, whichever was wrong
- A changed reference view invalidates the comparison

### Evidence required

The contact sheet images and the tool-read counts. On-screen stats are acceptable evidence; remembered numbers are not. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Character - Polycount wiki](http://wiki.polycount.com/wiki/Character) — source-claim. Search extract; URL reconstructed from the page title. Dated community text; adapt for stylised and 2D work.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [Gnomon announces character rigging workshop (AWN press)](https://www.awn.com/news/gnomon-announces-character-rigging-workshop-tutorial) — source-claim. Press release, not the tutorial body. Original announcement year not verified.

## uv-layout — UV layout (or atlas and pivot layout for 2D)

### Creator questions

- **seams**: Where are the seams, and why there (hidden by clothing, under arms, along hard edges)?
- **density**: Measured texel density per region versus the target; which regions are intentionally denser (face, hands) and which sparser?
- **layout**: Atlas, UDIM tiles, or trim sheets? If UDIM, how will export split tiles for the engine? Edge padding per texture size?
- **2d-equivalent**: For sprites: atlas packing, pivot per frame, filtering (nearest or linear), and palette lock. Mark UV items not-applicable with that reason.
- **stability**: Is geometry stable enough to unwrap? Which parts are expected to change and will need remapping?

### inputs

- Accepted mesh
- Texel density target from Step 6
- Material sheet

### activities

- Unwrap when geometry is mostly stable
- Check distortion with a test image
- Measure density and record it
- Set padding by texture size

### tools

- DCC UV editor or sprite atlas packer

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- UV layout with density measurements and padding, or the sprite atlas and pivot document

### dependencies

- multiview-comparison

### reviewCriteria

- No unintended overlaps
- Density within the agreed tolerance of the target
- Padding matches texture size
- UDIM export plan exists if used

### revisionRules

- Geometry edits after unwrap require remapping and re-review
- A texel target change re-opens the layout

### Evidence required

Checker-image screenshot and the measured density numbers. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [UV Unwrapping introduction (Blender Manual)](https://docs.blender.org/manual/en/latest/modeling/meshes/uv/unwrapping/introduction.html) — verified-source-text. Full page read by the research seat (Blender 5.2 LTS manual); URL reconstructed from the page title by the catalog author. UVs are never automatic on new meshes.
- [Texel Density and Edge Padding - Polycount wiki](http://wiki.polycount.com/wiki/Texel_Density) — source-claim. Search extracts of the texel and edge-padding pages; URL reconstructed. Community numbers, not engine guarantees.
- [glTF 2.0 add-on (Blender Manual)](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Real-time transmission support uneven; physics, lights and material animation do not export.
- [#5 Testing the Asset Pipeline - Project Storm - Blender Studio](https://studio.blender.org/projects/storm/production-log/310/) — verified-source-text. Production log extract (2025-06-23). Open-movie production, not games. Some media behind subscription.

## texture-material-channels — Textures and material channels

### Creator questions

- **channels**: Per material: which channels exist (base colour, normal, roughness, metallic, occlusion, emissive, alpha; or palette and ramp for 2D), which are baked from a high-poly, painted, generated seamless, or photographed?
- **colour-space**: Which textures are sRGB and which are linear or non-colour data? Packed channel layout if packed?
- **bake-contract**: For baked channels: bake resolution, cage or ray distance, and which high-poly source. Are node-based colour corrections baked before export (node graphs do not travel)?
- **size-count**: Texture sizes per platform tier and the material count versus budget.
- **provenance**: Source and license per texture (photo, painted, generated with which tool and prompt, purchased pack)?

### inputs

- UV layout
- Material sheet
- Interchange contract from Step 8

### activities

- Bake or paint channels per the contract
- Document colour space and packing
- Bake corrections into textures before export
- Record provenance per texture in the sidecar

### tools

- DCC texture and bake tools, painting tool, or sprite palette tool

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Texture set with channel manifest, colour spaces, sizes and provenance

### dependencies

- uv-layout

### reviewCriteria

- Every listed channel exists as a file
- Colour spaces are documented
- No engine-unsupported node remains at export
- Provenance is complete

### revisionRules

- A material count change re-opens the manifest
- A changed interchange format re-opens packing and export settings

### Evidence required

The channel files and a rendered material preview at the intended lighting; bake logs where the tool provides them. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [glTF 2.0 add-on (Blender Manual)](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Real-time transmission support uneven; physics, lights and material animation do not export.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.
- [Texel Density and Edge Padding - Polycount wiki](http://wiki.polycount.com/wiki/Texel_Density) — source-claim. Search extracts of the texel and edge-padding pages; URL reconstructed. Community numbers, not engine guarantees.

## rig-plan — Rig plan: bind skeleton and control rig

### Creator questions

- **skeleton**: Shared engine skeleton, retargeted custom, or fully custom? Which retarget cost experiment justified it? For 2D: bones, mesh warp, frame swap, or none.
- **hierarchies**: Bind or deform hierarchy versus control hierarchy: what goes in each, and how are they kept separate?
- **model-inspection**: Rigging-input inspection: naming, joint orientation, symmetry, scale, whether the mesh can bend where the anatomy sheet says it must.
- **face-body**: Is facial rigging a separate task from body rigging? Which one, if either, is in scope for this asset level?
- **influences**: Bone influence cap for the interchange format (commonly 4 or 8) and how weights will be limited.
- **automation-limits**: Which auto-rig or auto-pose tools are used, and what are their stated limits (humanoid only, no fingers or face)?

### inputs

- Accepted mesh
- Anatomy sheet
- Skeleton contract from Step 8
- Contact-state inventory from Step 4

### activities

- Inspect the mesh as a rigging input before rigging
- Decide skeleton policy from the retarget experiment
- Separate deform and control hierarchies
- Scope face versus body

### tools

- DCC rigging tools, engine retarget tools, or 2D skeletal tool

### skills

- game-art-pipeline
- game-technical-production

### roles

- creator
- game-art-director
- game-technical-director

### outputs

- Rig plan with skeleton policy, hierarchy split, influence cap, inspection findings

### dependencies

- multiview-comparison
- component-sheets

### reviewCriteria

- Inspection findings are recorded before rigging
- Hierarchies are separated
- Influence cap matches the interchange contract
- Tool limits are recorded

### revisionRules

- A skeleton policy change re-opens deformation-validation, locomotion-action-animation and engine-validation
- A mesh change re-opens the inspection

### Evidence required

Inspection notes with the actual findings; the retarget experiment result (hours to first non-sliding walk on dummy versus custom) if run. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Gnomon announces character rigging workshop (AWN press)](https://www.awn.com/news/gnomon-announces-character-rigging-workshop-tutorial) — source-claim. Press release, not the tutorial body. Original announcement year not verified.
- [Character Rigging in Maya for Game Production | The Gnomon Workshop](https://www.thegnomonworkshop.com/workshops/character-rigging-in-maya-for-game-production) — source-claim. Paid workshop listing, not watched. Maya; transfer to Blender or engine control rigs untested.
- [Character Rigging for Production - Gnomon](https://www.gnomon.edu/academics/individual-courses/course-list/character-rigging-for-production/) — source-claim. Course listing only; paywalled, Maya-centric, not engine-specific.
- [Lyra Sample Game in Unreal Engine](https://docs.unrealengine.com/lyra-sample-game-in-unreal-engine) — verified-source-text. Official docs extract. Unreal-specific. Sample version may lag engine (see G-UE-LYRA-VERSION). Full sample license not read.
- [glTF 2.0 add-on (Blender Manual)](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Real-time transmission support uneven; physics, lights and material animation do not export.
- [Blaze AutoPose for Blender](https://blazeanimation.com/blaze-autopose) — untested-integration. Commercial tool listing; not run; not a studio standard.
- [#5 Testing the Asset Pipeline - Project Storm - Blender Studio](https://studio.blender.org/projects/storm/production-log/310/) — verified-source-text. Production log extract (2025-06-23). Open-movie production, not games. Some media behind subscription.

## deformation-validation — Deformation validation

### Creator questions

- **poses**: Which test poses were run (squat, reach, look-up, sit, grip, twist, or the body plan's set) and which regions collapsed, candy-wrapped, pinched or interpenetrated?
- **correctives**: Which corrective shapes, helper joints or weight fixes were applied, and which problems were accepted at this asset level?
- **cloth-props**: Do cloth layers and props follow the body without intersection in the test poses?
- **2d-equivalent**: For 2D bones or mesh warp: which stretch limits and swap sets were checked? For frame swap: not-applicable with that reason.

### inputs

- Rigged asset
- Rig plan
- Test pose list

### activities

- Run the pose set in the DCC or 2D tool
- Fix or accept per region with a reason
- Capture stills per pose

### tools

- DCC pose tools
- Image capture

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Deformation report with per-pose stills and accepted defects

### dependencies

- rig-plan

### reviewCriteria

- Every pose has a still
- Accepted defects carry a reason and asset level
- Cloth and props were posed too

### revisionRules

- A mesh or weight change re-runs the pose set
- A new pose in the contact set adds a test pose

### Evidence required

Per-pose stills from the tool. A written 'looks fine' is not evidence. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Character Rigging for Production - Gnomon](https://www.gnomon.edu/academics/individual-courses/course-list/character-rigging-for-production/) — source-claim. Course listing only; paywalled, Maya-centric, not engine-specific.
- [Character Rigging in Maya for Game Production | The Gnomon Workshop](https://www.thegnomonworkshop.com/workshops/character-rigging-in-maya-for-game-production) — source-claim. Paid workshop listing, not watched. Maya; transfer to Blender or engine control rigs untested.
- [Topology - Polycount wiki](http://wiki.polycount.com/wiki/Topology) — source-claim. Search extract; community wiki, dated articles; URL reconstructed from the page title. Not an official engine standard.

## locomotion-action-animation — Locomotion and action animation

### Creator questions

- **set**: Which clips exist: idle, start, stop, walk and run at the project's speed bands, pivot or turn-in-place, jump, land, fall, interactions (pickup, door, use, fire), hit-react, fail states (slip, blocked, down)? Adapt for non-biped body plans or 2D frame sets.
- **source**: Hand-keyed, motion captured, purchased, generated, or engine warping (distance match, stride and orientation warp) on fewer clips? What license applies to purchased or generated clips?
- **timing**: Frame counts or durations against the timing tokens (windup, hit-stop, recovery).
- **export**: One action per track or clip for export; which properties animate (transforms, bones, shape keys) and which do not travel through the interchange format?

### inputs

- Deformation report
- Contact-state inventory
- Feel specification
- Speed bands from systems

### activities

- Author or acquire the clip set
- Match timing tokens
- Prepare export per the interchange rules
- Record clip provenance

### tools

- DCC animation tools, mocap or clip library, sprite frame editor

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Clip set with timing, source and export manifest

### dependencies

- deformation-validation

### reviewCriteria

- The set covers the contact-state inventory
- Timing matches tokens or an exception is recorded
- Provenance per clip exists

### revisionRules

- A new verb adds clips
- A timing token change re-opens the set

### Evidence required

Playblasts or frame strips per clip and the export manifest. Playblast quality is not engine validation. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Animation in Lyra Sample Game in Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/animation-in-lyra-sample-game-in-unreal-engine?lang=en-US) — verified-source-text. Official docs extract. Unreal AnimBP commands wrap portable ideas; does not define contact-state art.
- [Lyra Starter Game Overview | Tech Talk | State of Unreal 2022](https://www.youtube.com/watch?v=Fj1zCsYydD8) — source-claim. Listing and transcript snippets; not frame-reviewed. 2022 talk; engine has moved.
- [glTF 2.0 add-on (Blender Manual)](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Real-time transmission support uneven; physics, lights and material animation do not export.
- [godot-demo-projects/2d/platformer/project.godot](https://github.com/godotengine/godot-demo-projects/blob/master/2d/platformer/project.godot) — verified-source-text. Project file extract. Invincible player, one level; not an art pipeline or netcode.

## contact-intermediate-states — Contact and intermediate states

### Creator questions

- **ground-contact**: How are feet or contact points kept on ground at each speed band (foot IK, distance matching, frame-locked pivots for 2D)? What foot-slide tolerance is accepted?
- **transitions**: For each pair of states that can follow each other (idle to run, run to jump, land to idle, any to hit-react), what plays in between and how long?
- **weapon-ui-contact**: Which sockets, hitboxes or hurtboxes must meet weapons, props or UI anchors, per state?
- **fail-and-recovery**: What do slip, blocked, down and get-up look like, and how does the player know they can act again?
- **lod-switch**: What happens to the pose and the face at LOD switches; can a facial rig fight a body LOD?

### inputs

- Clip set
- State spec body states from Step 7
- Level surface types

### activities

- Write the transition matrix
- Define contact tolerances and hitboxes
- Plan LOD and face behaviour at switches

### tools

- Engine animation graph or 2D state machine
- Spreadsheet for the matrix

### skills

- game-art-pipeline
- game-technical-production

### roles

- creator
- game-art-director
- game-technical-director

### outputs

- Transition matrix, contact tolerances, hitbox and socket table

### dependencies

- locomotion-action-animation

### reviewCriteria

- Every state pair that can occur has an intermediate
- Tolerances are numbers
- Fail and recovery are visible to the player

### revisionRules

- A new state from Step 7 adds a row and column
- A changed speed band re-opens contact tolerances

### Evidence required

Matrix and tables; actual in-engine playback is proven in engine-validation. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Animation in Lyra Sample Game in Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/animation-in-lyra-sample-game-in-unreal-engine?lang=en-US) — verified-source-text. Official docs extract. Unreal AnimBP commands wrap portable ideas; does not define contact-state art.
- [godot-demo-projects/2d/platformer/project.godot](https://github.com/godotengine/godot-demo-projects/blob/master/2d/platformer/project.godot) — verified-source-text. Project file extract. Invincible player, one level; not an art pipeline or netcode.
- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.

## engine-validation — Engine validation and receipt

### Creator questions

- **import**: Import log: unknown materials, missing textures, bone count, vertex count after interchange splits, warnings. Zero unknown-material warnings?
- **three-way**: Three-way comparison stills at the same pose: reference sheet, DCC render, engine render at the game's lighting path. Where do they differ?
- **contact-playback**: Did the full contact set play at gameplay speeds in engine with feet within tolerance, sockets meeting props, no mesh explosion at LOD switch? Which states failed?
- **performance**: One performance sample on the target hardware class (or the closest available, stated honestly): frame time, animation thread cost, GPU memory for this asset alone and in a representative scene.
- **sidecar**: Was the provenance sidecar copied into the cooked or imported record, with license allowing the target stores?
- **unverified**: What remains unverified (other platforms, multiplayer replication, final lighting)?

### inputs

- Exported asset
- Transition matrix
- Receipt schema from Step 8
- Pinned engine version

### activities

- Import into the pinned engine
- Capture the three-way stills
- Play the contact set and record failures
- Take the performance sample with pinned quality settings
- Attach the sidecar

### tools

- Pinned engine import and profiler
- Screenshot capture

### skills

- game-technical-production
- game-quality-planning

### roles

- game-technical-director
- game-quality-lead
- creator

### outputs

- Engine receipt for this character (import log, three-way stills, contact playback result, performance sample, sidecar copy)

### dependencies

- contact-intermediate-states
- texture-material-channels

### reviewCriteria

- Every receipt item exists as a file or log
- Failures are listed with the state name
- The hardware class of the sample is stated
- Unverified items are listed

### revisionRules

- Engine version change re-runs the receipt
- Any upstream character revision invalidates the receipt

### Evidence required

The receipt files themselves: import log, three-way stills, playback recording or frame captures, profiler sample, sidecar copy. A receipt produced by Atlas does not exist; Atlas only lists what must be attached. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Lyra Sample Game in Unreal Engine](https://docs.unrealengine.com/lyra-sample-game-in-unreal-engine) — verified-source-text. Official docs extract. Unreal-specific. Sample version may lag engine (see G-UE-LYRA-VERSION). Full sample license not read.
- [Animation in Lyra Sample Game in Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/animation-in-lyra-sample-game-in-unreal-engine?lang=en-US) — verified-source-text. Official docs extract. Unreal AnimBP commands wrap portable ideas; does not define contact-state art.
- [Performance Testing Package for Unity Test Framework](https://docs.unity3d.com/Packages/com.unity.test-framework.performance@latest) — verified-source-text. Official package page extract. Unity-only. Development player changes the thing you measure.
- [Play mode and Editor profile samples (Unity)](http://docs.unity3d.com/Documentation/Components/profiler-play-edit-samples.html) — verified-source-text. Official docs extract; older docs host, newer manuals may differ.
- [glTF 2.0 add-on (Blender Manual)](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Real-time transmission support uneven; physics, lights and material animation do not export.
- [KhronosGroup/glTF-Sample-Assets](https://github.com/KhronosGroup/glTF-Sample-Assets) — verified-source-text. README read by the research seat. Use as interchange controls, not as shippable product art without reading each model README.
- [Agent-assisted Unreal tutorial (Stefan 3D AI)](https://www.youtube.com/watch?v=iRcrZjOt5H8) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/video-evidence/agent-runner/REVIEW.md): captions, 12 overview frames and 12 exact frames (0.37 s) showing locomotion while a score advances. Does not establish geometry correction, physics stability, packaging, performance or multiplayer. Prices and capability rankings unverified. No plugin installed or game executed by Atlas.
