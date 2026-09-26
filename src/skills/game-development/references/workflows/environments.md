# Environments: world rules to engine handoff

Generated from catalog 1.0.0.

Build a playable space from readable world rules through decomposition, blockout, modular kit, hidden-surface culling, material and bake contracts, assembly order, lighting, collision, navigation, streaming and engine validation. 2D tile, vector, text-room and abstract-board equivalents are named per phase.

Applicability: Applies to games with spaces, boards or settings the player perceives: 3D worlds, 2D tile maps, vector scenes, isometric boards, text-described rooms and audio-described navigable places. Games without a meaningful spatial or setting model mark the workflow not-applicable with a reason; audio-only or card-based presentation alone does not establish that. Background spaces may skip phases per asset level with a recorded reason.

Atlas stages: 3, 4, 5, 6, 7, 8, 10, 11. Canonical steps: 3, 4, 5, 6, 7, 8, 10, 11, 11.5.

## world-rules-scale — World rules and scale for this space

### Creator questions

- **purpose**: What does this space do for play (teach, test, rest, reveal, connect) and which experience goal it serves?
- **scale**: Real-unit scale references present in the space (door, stair, human, vehicle; for 2D: tile size and character height in tiles). What is the play camera or view and its field of view?
- **readable-rules**: Which world rules must be readable here (material language, what is climbable, what is deadly) and how are they shown without text?
- **traversal-targets**: Target traversal times or path lengths between key points, and why those numbers?

### inputs

- Narrative world rules
- Play camera or view from Step 3
- Space inventory

### activities

- Write the space brief
- Fix scale references and camera before any geometry
- Set traversal targets

### tools

- Atlas document editor

### skills

- game-world-design

### roles

- creator
- game-design-lead
- game-art-director

### outputs

- Space brief with scale, camera, readable rules, traversal targets

### dependencies

- None specified.

### reviewCriteria

- Scale references are concrete
- Camera or view is fixed
- Traversal targets have reasons

### revisionRules

- A camera change re-opens blockout and hidden-surface-cull
- A world-rule change re-opens readable rules

### Evidence required

Brief only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [An Approach to Holistic Level Design (GDC 2017)](https://www.youtube.com/watch?v=CpOoTAVeEcU) — source-claim. Talk description and transcript snippets only; not frame-reviewed. Lee flags a 3D action-adventure and immersive-sim bias. Not a 2D, puzzle or management-game process.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.

## decomposition-map — Decomposition map

### Creator questions

- **chunks**: List every chunk of the space with a size class (anchor with known real size, volume, accessory) and a generation route (built by hand, kitbashed, image-to-3D high-poly, image-to-3D low-poly, primitive, cut from existing, tile set, hand-drawn). Every visible region of the concept belongs to exactly one chunk.
- **anchors**: Which chunks are anchors with a real size written down before anything is generated or drawn?
- **group-generation**: For grouped generation of small props, the expected count per group, so drift (asked four, got three) is caught.
- **2d-equivalent**: For tile maps or vector scenes: the tile or symbol inventory and which are unique versus repeated. Mark 3D routes not-applicable with that reason.
- **provenance**: Per chunk: source and license (own, purchased, generated with which tool)?

### inputs

- Space brief
- Concept image or sketch
- Art mode

### activities

- Annotate the concept into chunks
- Assign size class and route per chunk
- Record expected counts and provenance

### tools

- Image annotation tool
- Spreadsheet

### skills

- game-world-design
- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Decomposition map (annotated image plus chunk table)

### dependencies

- world-rules-scale

### reviewCriteria

- Every region belongs to one chunk
- Anchors have real sizes
- Expected group counts are written

### revisionRules

- A concept change re-opens the map
- A new chunk needs a route and provenance

### Evidence required

The annotated image and the table. Generated outputs are checked against expected counts in modular-kit. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.

## blockout — Blockout (or tile-map draft, or room graph for text)

### Creator questions

- **form**: Greybox volumes in an engine or DCC, a 2D tile draft, a paper map, or a text room graph? Why is that the cheapest playable form for this game?
- **playable**: Can a tester traverse it with the real camera and controls (or read it, for text)? Which routes and sightlines were checked?
- **traversal-measured**: Measured traversal times or path lengths versus targets.
- **wayfinding**: Did an outsider find the intended path without help? Where did they get lost?
- **no-hero-art**: Confirm no hero art or final materials were placed; what placeholder rule was used?

### inputs

- Space brief
- Decomposition map
- Level intent if a level owns this space

### activities

- Build the cheapest playable form
- Test the selected traversal and camera hypothesis with suitable participants; record self-test versus independent-player limitations
- Measure traversal and record wayfinding failures

### tools

- Engine or DCC greybox, tile editor, paper, or text

### skills

- game-world-design

### roles

- creator
- game-design-lead

### outputs

- Blockout with traversal measurements and wayfinding notes

### dependencies

- decomposition-map

### reviewCriteria

- Traversal targets met or revised with a reason
- The chosen traversal experiment has recorded evidence and participant limitations, or is explicitly not executed
- No hero art present

### revisionRules

- A failed wayfinding test re-opens the blockout, not the art plan
- A camera change re-runs the walk

### Evidence required

Recording or notes of the chosen traversal experiment, measurements where relevant, and who participated. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [An Approach to Holistic Level Design (GDC 2017)](https://www.youtube.com/watch?v=CpOoTAVeEcU) — source-claim. Talk description and transcript snippets only; not frame-reviewed. Lee flags a 3D action-adventure and immersive-sim bias. Not a 2D, puzzle or management-game process.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.

## modular-kit — Modular kit and starter pack

### Creator questions

- **pieces**: Which chunks become kit pieces on a grid with snapping (or tiles with edge rules), and which are unique?
- **manifest**: Per asset: source, triangle count before and after cleanup (tool-read), texture channels present, atlas membership, UV state (raw, unwrapped, packed), material name, license.
- **count-check**: Did generated groups deliver the expected count? Which drifted?
- **seams**: How are seams between modules handled (texel match, snap grid, tile edges) so there are no gaps or light leaks?

### inputs

- Decomposition map
- Budgets from Step 6
- Interchange contract

### activities

- Build or acquire pieces
- Fill the manifest from tool-read counts
- Check generated counts against expectations
- Test module seams

### tools

- DCC or tile editor
- Spreadsheet manifest

### skills

- game-art-pipeline

### roles

- creator
- game-art-director
- game-technical-director

### outputs

- Starter-pack manifest and kit pieces

### dependencies

- decomposition-map

### reviewCriteria

- Counts are tool-read
- No shared-atlas asset keeps a raw generated UV
- Seams tested

### revisionRules

- A budget change re-opens the manifest
- A new chunk adds a row

### Evidence required

The manifest with tool-read counts and a seam test screenshot. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [The Use of Blender in the Making of the Animated TV Series Deep Dive - Blender Conference 2025](https://www.youtube.com/watch?v=zJIlg3TxHNc) — source-claim. Auto-transcript snippets only; video not watched; speaker name not verified. TV animation, not games.
- [Texel Density and Edge Padding - Polycount wiki](http://wiki.polycount.com/wiki/Texel_Density) — source-claim. Search extracts of the texel and edge-padding pages; URL reconstructed. Community numbers, not engine guarantees.

## hidden-surface-cull — Hidden-surface cull and decimation pass

### Creator questions

- **threshold**: Which assets exceed the large-asset threshold and get an explicit decision?
- **decisions**: Per large asset: 'underside or backside removed' or 'kept because visible', with the method (knife, boolean, decimate ratio, tile trim) and before/after counts read from the tool.
- **silhouette-check**: After decimation, does each piece still read at its intended camera distance?
- **2d-equivalent**: For 2D: which off-screen or always-covered tiles and frames were removed from atlases? Mark 3D items not-applicable with that reason.

### inputs

- Kit pieces
- Play camera
- Large-asset threshold from budgets

### activities

- List large assets
- Cut or decimate with recorded counts
- Re-check silhouettes

### tools

- DCC edit tools

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Cull report with per-asset before/after counts

### dependencies

- modular-kit

### reviewCriteria

- Every large asset has a decision
- Counts are tool-read
- Silhouettes still read

### revisionRules

- A camera change re-opens cull decisions

### Evidence required

Before/after stats captures per asset. The one frame-verified example in the corpus is a single rock going from 922 to 448 vertices; that number is not a target. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [Topology - Polycount wiki](http://wiki.polycount.com/wiki/Topology) — source-claim. Search extract; community wiki, dated articles; URL reconstructed from the page title. Not an official engine standard.

## material-bake-contract — Material and bake contract

### Creator questions

- **per-material**: Per material: baked channels (from which high-poly), generated seamless tiles, painted channels, bake resolution, colour space.
- **corrections**: Which colour corrections live in node graphs and must be baked before export?
- **atlases**: Atlas membership and padding per texture size; UDIM or trim usage and export splitting.
- **normals**: Which decimated assets need baked normals to read as detailed at player distance?
- **2d-equivalent**: For 2D: palette lock, filtering choice, and atlas size. Mark bake items not-applicable with that reason.

### inputs

- Kit pieces
- Material budgets
- Interchange contract

### activities

- Write the per-material contract
- Bake and verify outputs exist
- Record provenance per texture

### tools

- DCC bake tools, painting tool, tile tool

### skills

- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Material and bake manifest with output files

### dependencies

- hidden-surface-cull

### reviewCriteria

- Every listed output exists
- Corrections are baked
- Padding matches size

### revisionRules

- A material count change re-opens the manifest
- A decimation change re-bakes normals

### Evidence required

Output files and one lit preview per material family. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [glTF 2.0 add-on (Blender Manual)](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Real-time transmission support uneven; physics, lights and material animation do not export.
- [Texel Density and Edge Padding - Polycount wiki](http://wiki.polycount.com/wiki/Texel_Density) — source-claim. Search extracts of the texel and edge-padding pages; URL reconstructed. Community numbers, not engine guarantees.

## set-dressing-assembly — Assembly order and set dressing

### Creator questions

- **first-chunk**: Which known-size anchor is placed first, and why not the enclosing volume?
- **order**: Order of volumes, then accessories last; one collection or layer per chunk so any chunk hides with one click.
- **reference-in-scene**: Is the reference image placed in the scene at scale?
- **dressing-beats**: Which narrative or world beats does dressing show, per area, and what is deliberately left bare?
- **reuse**: Which pieces are reused by cut and scale (for example stalactites from a rock) and which must be unique?

### inputs

- Blockout
- Kit pieces
- Space-to-beat map from narrative

### activities

- Place the anchor first
- Assemble volumes then accessories with per-chunk collections
- Dress against the beat map

### tools

- Engine or DCC scene tools

### skills

- game-world-design
- game-art-pipeline

### roles

- creator
- game-art-director
- game-design-lead

### outputs

- Assembly plan and dressed scene with per-chunk collections

### dependencies

- blockout
- modular-kit
- material-bake-contract

### reviewCriteria

- The plan starts from a known-size chunk
- Accessories are last
- Every chunk can be hidden alone

### revisionRules

- A blockout change re-opens the assembly
- A beat change re-opens dressing for that area

### Evidence required

Scene outliner or layer screenshot showing per-chunk collections and total object and triangle counts read from the tool. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [An Approach to Holistic Level Design (GDC 2017)](https://www.youtube.com/watch?v=CpOoTAVeEcU) — source-claim. Talk description and transcript snippets only; not frame-reviewed. Lee flags a 3D action-adventure and immersive-sim bias. Not a 2D, puzzle or management-game process.

## lighting-plan — Lighting for gameplay and mood

### Creator questions

- **function**: Which lights serve gameplay (readable path, cover, depth, danger) and which serve mood?
- **path**: Which lighting path does the engine use for this game (baked, dynamic, mixed; or 2D lights and shadows; or none)? Preview lights in a DCC are not the game's lighting.
- **budget**: Lightmap resolution or dynamic light count budget and the hardware class.
- **perception-test**: How will you test that players read path and danger from light alone?

### inputs

- Dressed scene
- Readability tokens
- Space brief

### activities

- Plan lights by function first
- Use the engine's lighting path for review
- Plan the perception test

### tools

- Engine lighting tools

### skills

- game-world-design
- game-art-pipeline

### roles

- creator
- game-art-director

### outputs

- Lighting plan with function map and budget

### dependencies

- set-dressing-assembly

### reviewCriteria

- Every light has a function
- The path is the engine's
- A perception test is planned

### revisionRules

- A readability token change re-opens the function map

### Evidence required

Engine screenshots at the game's lighting path; the perception test result is recorded in the quality workflow. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.

## collision-navigation-streaming — Collision, navigation and streaming

### Creator questions

- **collision**: Simplified hulls per piece or per chunk; which visual geometry is not collision; which verbs need precise collision (climb, vault)?
- **navigation**: If agents or companions move: navigation volumes and a path for every intended route. If none, not-applicable with that reason.
- **streaming**: Load units and their budgets; expected hitch when crossing a unit; what is always resident.
- **puzzle-state**: If the space holds puzzle or world state: explicit states, reset path and what a mid-state save restores.
- **2d-equivalent**: For 2D: tile collision layers, one-way platforms, and chunk loading. Mark 3D items not-applicable with that reason.

### inputs

- Dressed scene
- Technical spec streaming and collision policy
- Verb inventory

### activities

- Author collision and navigation
- Define load units and budgets
- Test every intended route

### tools

- Engine collision and navigation tools

### skills

- game-technical-production
- game-world-design

### roles

- game-technical-director
- creator

### outputs

- Collision, navigation and streaming report

### dependencies

- set-dressing-assembly

### reviewCriteria

- Every intended route has a path
- Collision matches verbs
- Load units have budgets

### revisionRules

- A new verb re-opens collision
- A new route re-opens navigation

### Evidence required

Route test results and, where streaming exists, a hitch measurement per unit crossing. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Lyra Sample Game in Unreal Engine](https://docs.unrealengine.com/lyra-sample-game-in-unreal-engine) — verified-source-text. Official docs extract. Unreal-specific. Sample version may lag engine (see G-UE-LYRA-VERSION). Full sample license not read.
- [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) — verified-source-text. README and LICENSE read. Demos are slices, not a production pipeline. Web builds are slower than native and not a ship oracle.
- [Saving games (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Teaching slice, not a production save schema.

## engine-handoff-validation — Engine handoff checklist and receipt

### Creator questions

- **materials-recreated**: Which materials must be recreated in the engine by hand, and were they, with import warnings listed?
- **engine-systems**: Which systems are left to the engine (water, sky, weather, grass, cloth, floating objects) and what does each depend on?
- **licensing**: License status of every non-AI dependency (engine add-ons, packs, fonts). Does any paid or restricted add-on contradict a 'free' or 'open' assumption?
- **receipt**: Receipt items: traversal times in engine, nav and collision result, mid-state save and load, streaming hitch versus budget, lighting at the game's path, performance sample on the hardware class.
- **unverified**: What has not been verified (collision on other platforms, target frame rate, packaging, multiplayer)?

### inputs

- All environment outputs
- Receipt schema
- Pinned engine
- Dependency list

### activities

- Import and recreate materials
- Fill the licensing table
- Attach receipt items
- List unverified properties

### tools

- Pinned engine
- Profiler
- Screenshot capture

### skills

- game-technical-production
- game-quality-planning

### roles

- game-technical-director
- game-quality-lead
- creator

### outputs

- Engine handoff checklist and environment receipt

### dependencies

- lighting-plan
- collision-navigation-streaming

### reviewCriteria

- Every dependency has a license status
- Receipt items exist as files
- Unverified list is honest

### revisionRules

- Engine version change re-runs the receipt
- A new dependency adds a license row

### Evidence required

Receipt files: import log, engine screenshots, route and save test results, hitch and performance samples. A licensing table with sources. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [Agent-assisted Unreal tutorial (Stefan 3D AI)](https://www.youtube.com/watch?v=iRcrZjOt5H8) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/video-evidence/agent-runner/REVIEW.md): captions, 12 overview frames and 12 exact frames (0.37 s) showing locomotion while a score advances. Does not establish geometry correction, physics stability, packaging, performance or multiplayer. Prices and capability rankings unverified. No plugin installed or game executed by Atlas.
- [Exporting projects (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) — verified-source-text. Full page read by the research seat (Godot 4.7 docs); URL reconstructed from the page title by the catalog author, re-check the version path. ZIP pack auto-discovery bug noted in the docs.
- [Performance Testing Package for Unity Test Framework](https://docs.unity3d.com/Packages/com.unity.test-framework.performance@latest) — verified-source-text. Official package page extract. Unity-only. Development player changes the thing you measure.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.
