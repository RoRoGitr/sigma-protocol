# Game assets and technical production — reusable methodology

**Access date:** 2026-09-22
**Worker:** Grok research half (assets, pipelines, engine/tech)
**Scope:** Any game. No engine, team-size, genre, room-count, or title defaults.
**Evidence rule:** Only sources inspected in this research session. Search extracts are labeled `search-extract`. Full pages opened later in this session are labeled `full-page`. Videos are **not** claimed watched; parent owns exact-frame review. Atlas plans and prepares; it does not execute production.

**Status of this file:** Preservation draft plus bounded gap-fill (2026-09-22). Full-page upgrades: Blender 5.2 glTF/UV manuals, Godot 4.7 export/save/multiplayer, JetBrains rider-skills README+Apache-2.0 LICENSE, Unity Boss Room README+Companion License, Khronos glTF-Sample-Assets. Search-extract upgrades: Polycount topology/character/texel/padding, Epic Automation/Gauntlet/CQTest. Disney 12 Principles and Richard Williams book body remain unopened. Audio middleware manuals remain a gap.

## Verdict

A reusable game-asset and technical method is a **gated interchange contract**, not a tool list. Identity and proportions lock first. Individual multiview stills and named sheets (anatomy, components, clothing, props, materials) become the only legal references for modeling. Geometry, UVs, materials, bind skeleton, and animation contact states each have their own pass/fail evidence. The engine is a validation target, not the place where identity is invented. Portable principles (task layers, bind-versus-control, thread-safe anim update, measured performance tests, provenance sidecars) survive engine choice. Engine commands (Lyra AnimBP paths, Godot `project.godot` features, Unity `Measure.Method`, Unreal PIE/Gauntlet) stay behind a thin adapter.

Community editor MCP servers are **untested tools with full-editor authority**. Official engine samples and DCC studio pipelines are **demonstrated in their own productions**. Mapping those into Sigma Protocol 0–15 is a **proposed adaptation**.

## How to use this document

1. Treat every source row as one of: demonstrated evidence, source claim, untested tool, proposed adaptation, incomplete.
2. Copy the nested process contracts into Atlas planning only. Do not run DCC, editors, purchases, or installs from this research.
3. Run the small assumption-testing experiments in a throwaway sandbox after a human chooses engine and art mode (3D, 2D sprite, vector, hybrid).
4. Do not promote a fashionable MCP, auto-rigger, or marketplace character pack into the methodology.

---

## Evidence policy and limits of this pass

Inspected in session 1 via `web_search` page extracts (not independent full-page reads unless later upgraded):

- Blender Studio Asset Pipeline add-on page
- Blender Studio Project Storm production log #5
- Blender Conference 2025 *Deep Dive* YouTube listing + auto-transcript snippets (unwatched)
- Epic Lyra sample-game and Lyra animation documentation pages
- Ben Zeigler EOS+Lyra tutorial page
- Epic forum thread on Lyra / Game Animation Sample version pinning
- `godotengine/godot-demo-projects` README/releases extract
- Official Godot demos-on-web listing
- Unity Performance Testing Package, Profiler sample groups, Adaptive Performance / Meta sample pages
- JetBrains `rider-skills` README extract and Rider UE/Unity/Godot help pages
- Multiple community Unreal MCP repository READMEs
- Brian Tindall IMDb credits
- Gnomon / Gnomon Workshop rigging course pages (Maya, production)
- One non-Blender studio ADR (`lxsolutions/studio-foundation`) used only as a *contrast* on MCP policy

**Not claimed inspected as full primary method texts:** Disney 12 Principles original book pages, Richard Williams *Animator’s Survival Kit* body text, Khronos glTF *specification* HTML (sample-assets README was opened), FMOD/Wwise/MetaSounds manuals, Steamworks depot docs, platform TRC/TCR, Mixamo license terms, Spine runtime licenses. Those remain **research gaps**.

**X posts:** none independently traced to a primary talk/repo in this session. Discovery-only rule stands.

**Bounded gap-fill (same day):** full pages opened for Blender 5.2 UV + glTF, Godot 4.7 export/save/multiplayer, Godot demos MIT, JetBrains rider-skills README+Apache-2.0 LICENSE, Unity Boss Room README+Companion License, Khronos glTF-Sample-Assets. Search-extract upgrades for Polycount topology/character/texel/padding and Epic Automation/Gauntlet/CQTest/Horde.

---

## 1. Character identity, proportions, and reference law

### Portable principle

A character is not a mesh. It is a locked identity package: silhouette, proportion set, turnaround, material language, and a named list of parts that may change independently (head, body, hair, outfit, eyes, weapons, cloth layers). Downstream work is illegal until that package exists as stills a human can compare.

### What production sources actually do

Blender Studio’s Asset Pipeline add-on exists because multiple artists must touch one character without destroying each other’s data. The add-on tracks which data each artist owns and merges into a published asset. Default teaching example: a character `Bob` with `Bob.rigging.blend` and `Bob.shading.blend`, plus `publish/Bob.v001.blend`. Task layers are declared in JSON. Publish types include an **Active** publish that shot files may reference; older versions can remain for shots that must not jump. This is demonstrated inside Blender Studio’s own film pipeline, not proven for games. [G-BLENDER-STUDIO]

Project Storm (June 23, 2025 log) reused the Gold-era pipeline, needed project-specific tweaks, and split **body rig** and **face rig** into two tasks because the skills differ and the work can run in parallel. DogWalk did not use this pipeline. That is demonstrated studio practice and a warning: a pipeline that sat idle had to be re-learned. [G-BLENDER-STORM]

Conference transcript snippets from *Deep Dive* (Blender Conference 2025, unwatched) describe asset **levels**: high-level assets walk every pipeline stage; low-level assets skip stages. Level is chosen from how many scenes an asset appears in and what the shot requires. Character pipelines are the thickest; props and environments reuse the same skeleton of phases with fewer gates. The destination file (their “A” asset) is what shots link; it starts updating as soon as a low modeling stage exists so layout is not blocked. Treat this as **source claim from transcript extract**, not frame-reviewed method. [G-DEEPDIVE-YT]

Vendor “game-ready character” packs (example: Daz announcing FBX/GLB drop-in for Unreal/Unity/Blender, MetaHuman-compatible UVs, maps grouped by head/body/hair/outfit/eyes) are **source claims**. They are useful as a checklist of interchange pain (materials, UVs, unlabeled maps) and as a rights/provenance risk: marketplace identity is not your identity lock. [G-DAZ-CLAIM]

### Nested process contract (proposed adaptation)

| Gate | Artifact | Pass evidence | Fail |
|---|---|---|---|
| Identity lock | Named proportion sheet + silhouette | Two reviewers can pick the character from a lineup of lookalikes | “We’ll fix it in 3D” |
| Multiview refs | Individual stills: front, side, back, 3/4, optional top | Each view is a separate image file with scale bar / head-height units | One collage that cannot be loaded as a camera background |
| Sheet pack | Anatomy, components, clothing, props, materials | Every deformable part named; cloth layers listed; forbidden intersections listed | A single beauty render |
| Rights | Provenance sidecar | License, creator, source, AI-generation fields if any | Downloaded mesh with no paper trail |

**Assumption-testing experiment (small):** For one hero and one extra, produce the still pack only. Time-to-first-engine-proxy is not the metric. Metric: can a second person sculpt a clay or block mesh that matches the lineup without asking questions?

**Protocol map:** Step 1 (who the character is in product terms) → Step 3 (readable identity, silhouette at play scale) → Step 5 (per-flow stills, not a film bible dump) → Step 6 (material language as tokens) → Step 11 PRDs that forbid modeling before the still pack exists.

---

## 2. Geometry, topology, visual comparison

### Portable principle

Topology is a deformation and LOD budget, not a sculpting aesthetic. Edge flow follows joints and compression zones. Triangle/quad budgets are per platform tier. Visual comparison is a still-vs-still overlay (orthographic turntable, identical FOV, identical lighting) against the locked refs.

### Demonstrated / claimed

Storm’s log mentions a full UV pass with UDIM layout as a dated milestone alongside an initial shading turntable. That is demonstrated sequencing: UV before or with shading, visible as a named pass. [G-BLENDER-STORM]

Lyra ships optimized hand-crafted content and UE5 mannequins (Manny, Quinn) that share the MetaHuman core skeleton hierarchy, plus a UE4 mannequin with a retargeting setup. That is Epic demonstrating a **skeleton compatibility policy**: gameplay animation targets a shared hierarchy so meshes can swap. It is not a topology tutorial. [G-UE-LYRA] [G-UE-ANIM]

Gnomon production-rigging courses treat **model inspection** as a first rigging step (joint orientation, naming, whether the mesh can actually deform). Axel Stanley-Grossman’s course listing names model inspection, joint orientation, space switching, and **separation of deformation and control hierarchies**. Taylor Whitsett’s game-rigging workshop lists: character pipeline, bind skeleton, control rig, then automation. Perry Leijten’s creature workshop (secondary listing) starts the skeleton from a ZBrush blockout **before** clean topology is finished, then transfers. These are **source claims from course catalogs**, Maya-centric, not game-engine validation. Portable takeaway: inspect the mesh as a rigging input; do not wait for “final model” to discover it cannot bend. [G-GNOMON-RIG] [G-WHITSETT] [G-STANLEY-GROSSMAN]

Brian Tindall’s IMDb credits show Pixar “character modeling & articulation” and, on *The Incredibles*, “character rig development.” That is **demonstrated employment evidence**, not a published method. Do not invent a Tindall topology doctrine from credits. [G-TINDALL]

Polycount’s practitioner wiki (community, long-lived, not an official engine) is the closest public **game-mesh** method text inspected here. Topology is defined as vertex/edge layout for **framerate and deformation**. Three jobs have different laws: sculpt base (quads to avoid pinch), game-ready lowpoly (triangles fine if every edge earns its keep), subdivision cage (loops are law). Deformation topology matters most at crotch/hips, shoulders/armpits, mouth corners, knees, elbows, hands. Density follows curvature, then those joints. [G-POLYCOUNT-TOPO]

Typical character process on the Character page: concept stills first (cheaper than 3D) → blockout → rough sculpt → final sculpt → polypaint → **retopo** to the in-game mesh → unwrap → bake high to low (normal, AO) → shade → rig → animate. High-poly is a detail donor, not the runtime mesh. [G-POLYCOUNT-CHAR]

The BodyTopology gallery credits **Brian Tindall, Character Technical Director at Pixar**, for articulation topology examples. That is the Tindall lead, verified as an image credit on Polycount, still **not** a written Tindall doctrine. [G-POLYCOUNT-BODY] [G-TINDALL]

Texel is the engine’s in-flight texture sample, distinct from texture pixels and screen pixels. Edge padding (wiki examples: 2px@256, 4px@512, 8px@1024, 16px@2048; gutter ≈ 2× pad) exists because mipmaps bleed neighboring shells. Powers-of-two texture sizes remain the default engine assumption. [G-POLYCOUNT-TEXEL] [G-POLYCOUNT-PAD]

Modular characters (skankerzero writeup) add seam-vert alignment across parts, deform-loop alignment so sleeves do not pierce torsos, and UV scale locked across groups so density stays even. Those are **source claims from a dated wiki article**, still the right tests for kitbash bodies. [G-POLYCOUNT-MOD]

Re-topology is explicitly “new surface on a messy sculpt, bake the rest.” [G-POLYCOUNT-RETOPO]

### Nested process contract (proposed)

| Gate | Artifact | Pass evidence |
|---|---|---|
| Block mesh | Low-frequency volumes matching proportion sheet | Overlay vs front/side refs within agreed pixel error |
| Production mesh | Named topology checklist (poles, loops at joints, extra loops at compress) | Deform test poses: squat, reach, look-up, sit, weapon grip |
| LOD policy | LOD0–N with listed triangle counts | Each LOD still reads silhouette at its intended camera distance |
| Comparison stills | Turntable vs ref, same lighting | Side-by-side contact sheet checked into the asset record |

**Engine-specific (do not generalize as law):** Unreal Geometry Tools in Lyra were used to make parametric level-design pieces in Blueprints. That is a **level** technique, not character topology. [G-UE-LYRA]

**Protocol map:** Step 6 (budget tokens: triangle, texel, material count) → Step 7 (deform states = interface states for a body) → Step 8 (mesh/LOD/collision interchange) → Step 11 (per-character PRD with numeric budgets).

---

## 3. UV, textures, materials

### Portable principle

UVs are a measured resource (texel density per meter, island packing, UDIM vs atlas vs trim). Materials are a counted resource (how many unique shaders, how many texture sets, which maps are required). Shading artists and modelers need a task-layer split or they will overwrite each other.

### Demonstrated

Blender Studio task layers explicitly split shading from rigging. Storm’s Simon Thommes started character shading after re-learning the pipeline; UDIM layout is a named UV pass. [G-BLENDER-STUDIO] [G-BLENDER-STORM]

Daz’s marketing claim that maps grouped by head/body/hair/outfit/eyes saves hunting unlabeled files is a **source claim** that accidentally states the actual production failure mode: unlabeled texture dumps. [G-DAZ-CLAIM]

Lyra documents modular UMG and Niagara; it does not, in the inspected extracts, teach a UV method. Do not treat Lyra as a texturing bible. [G-UE-LYRA]

Blender 5.2 LTS UV introduction (full page): unwrap when geometry is mostly stable; new faces after unwrap need remapping; each mesh face can join multiple UV textures (hairline on face *and* scalp); workflow is mark seams → select → unwrap method → test image for distortion → edit islands. UVs are not automatic on new meshes. [G-BLENDER-UV]

Blender 5.2 LTS glTF 2.0 add-on (full page, enabled by default): glTF is a **GPU-buffer** format. Quads/n-gons triangulate on export. Discontinuous UVs and hard edges **split vertices**, so glTF vert counts rise versus the .blend. Curves must be meshed first. Core materials are metal/rough PBR (base color, metallic, roughness, baked AO, tangent-space normal +Y up, emissive). Metallic lives in **B**, roughness in **G**, occlusion in **R** if packed. Images must be PNG or JPEG (exporter converts, paying time). UDIM is **not** a glTF feature: the exporter splits tiles. Transmission (`KHR_materials_transmission`) is not alpha blend, and real-time support is still uneven. Skinning: many viewers only look correct at **4 or 8** bone influences. Animation export for games: stash each action on its own NLA track (Actions mode). Only object TRS, pose bones, and shape keys animate; physics/lights/materials do not. Formats: `.glb` (shareable one-file), separate `.gltf+.bin+images` (editable), embedded Base64 (least efficient). Khronos sample WaterBottle/Fox are the official visual oracles. [G-BLENDER-GLTF]

Khronos `glTF-Sample-Assets` (full README): curated models, CI glTF validation, **per-model licenses** in each README (not one repo-wide art license). REUSE.toml present. Some historical models were **removed for missing/unsuitable licenses**. Site/collection text © 2026 Khronos, CC-BY-4.0. Use samples as interchange tests; do not ship them as product art without reading that model’s README. [G-GLTF-SAMPLES]

### Nested process contract (proposed)

| Gate | Pass evidence |
|---|---|
| UV | No overlapping islands unless intended; density within ±N% of the project texel target; required UDIMs present |
| Textures | Named sets match the sheet pack; color space documented (sRGB vs linear); max size per platform tier |
| Materials | Count ≤ budget; no engine-unsupported nodes left in the DCC graph at export |
| Sidecar | License + generator (photo, painted, AI) recorded |

**Interchange (source claim from a third-party studio ADR, not Blender Studio):** `lxsolutions/studio-foundation` ADR 0006 (accepted 2026-07-19) pins Blender LTS, uses `blender -b --python` only, exports glTF/GLB, cooks KTX2/Basis later, and requires a JSON sidecar (id, license, source, creator, provenance including AI fields, LOD/collision/texture policies). Community Blender MCP is disabled by default. This is **one studio’s demonstrated policy text**, not a universal standard. Useful as a checklist, dangerous as a hidden engine default. [G-STUDIO-FOUNDATION-ADR]

**Protocol map:** Step 6 design tokens include texel density and material-count budgets. Step 8 lists interchange formats. Step 15 observes GPU memory and shader permutation count.

---

## 4. Rig, deformation, animation, contact states

### Portable principle

Two hierarchies: **bind/deform** (what the engine or renderer skins) and **control** (what an animator or gameplay pose drives). Facial and body rigs are different jobs. Animation that must play in a game is constrained by locomotion speed, yaw, and contact with ground/weapons/UI. “Looks good in a playblast” is not engine validation.

### Demonstrated (engine)

Lyra’s character animation is built on UE5 Animation Blueprint improvements. Inspected docs point at `Content/Characters/Heroes/Mannequin/Animations/AnimBP_Mannequin_Base`. Practices called out:

- Multi-threaded animation / Animation Fast Path; values calculated off the game thread
- Project setting: Allow Multi Threaded Animation Update
- Linked Anim Layers with Property Access and Anim Node Functions (`On Update`, `On Become Relevant`) for selection (example: directional start when a node becomes relevant)
- Distance matching + stride warping for variable move speed
- Orientation warping for variable move angle
- Turn-in-place when yaw exceeds what an upper-body twist can hide
- Linked layers also used for memory: unused layers need not stay loaded

These are **Epic-demonstrated in the Lyra sample**. They are Unreal-specific commands wrapped around portable ideas: keep pose-decision work off the game thread; select clips by relevance; warp, don’t author every speed. [G-UE-ANIM] [G-UE-LYRA-TALK]

Version friction is demonstrated: a June 2025 Fab/launcher user found Lyra and Game Animation Sample listing UE 5.6 support while the launcher only offered 5.4 until local content was removed. Sample version ≠ engine version. Pin both in Step 0. [G-UE-LYRA-VERSION]

### Demonstrated (DCC studio)

Storm split body vs face rigging. Asset Pipeline merge is the collaboration mechanism. [G-BLENDER-STORM]

Blaze AutoPose (vendor, 2026-09-22 listing) states hard limits: humanoid only, FK body controls, no fingers/face, Blender 4.5+. That is useful as a **limitation card** for auto-pose tools, not as a pipeline. [G-BLAZE-AUTOPOSE]

### Source claims (education)

Gnomon paths: animator-friendly controls + natural skin/cloth behavior as the two objectives of a rig. Game workshops emphasize bind skeleton, control rig, IK/FK switch, space switching, scripted automation. Software in those courses is Autodesk Maya. Transfer to Blender Rigify/CloudRig or Unreal Control Rig is **untested in this research**. [G-GNOMON-PATH] [G-WHITSETT]

Walt Disney 12 Principles and Richard Williams *Animator’s Survival Kit* were **leads not fully opened**. Animation Mentor blog URL 404’d this session; Khan Academy Pixar-in-a-Box page returned an empty shell. Do not cite them as inspected method texts. Parent may frame-review legitimate education videos. Game deformation practice in this file rests on Polycount + Lyra + Gnomon course listings instead.

### Contact states (proposed, because sources name the problem without a universal checklist)

Minimum gameplay contact set for a biped (adapt for other body plans):

- Idle (loop, no foot slide)
- Start / stop (Lyra explicitly selects directional starts)
- Walk / run at the project’s speed bands (distance match / warp)
- Pivot / turn-in-place
- Jump / land / fall
- Interaction: pickup, door, fire, hit-react
- Fail states: slip, blocked, death/down

Pass evidence: feet meet ground in engine at gameplay speeds; weapon IK meets sockets; no mesh explosion at LOD switch; facial rig does not fight body LOD.

**Assumption-testing experiment:** One dummy using the engine’s default mannequin/skeleton, one custom mesh retargeted onto it. Measure hours to first non-sliding walk. If custom mesh costs >N× dummy, the identity pack or topology gate failed.

**Protocol map:** Step 4 flow tree includes locomotion and interaction states. Step 7 state spec includes animation contact states. Step 8 names the skeleton contract. Step 11 PRDs include the contact-set table. Step 15 traces animation thread time.

---

## 5. Engine validation (the asset is not done in DCC)

### Portable principle

Done means: imported, skinned, animated, lit with the game’s lighting path, profiled at target resolution, with collision/LODs/materials that the engine actually uses.

### Demonstrated

Lyra is explicitly a **learning resource / sample** with Elimination, Control, Exploder modes, GAS, Niagara, modular UMG, mannequins, weapon system usable on any Pawn. Downloading currently goes through Fab → Epic Games Launcher. Using it as a ship foundation is a product choice, not a requirement of this methodology. EOS multiplayer is a **separate** tutorial (Zeigler; originally 2022-06-08, page last updated 2026-03-02) with extra command-line `-game -customconfig=EOS` and a warning that editor vs packaged tests differ. [G-UE-LYRA] [G-UE-EOS]

Godot official demos are MIT-licensed, version-branched (`master` tracks next 4.x; other branches match stables). Import all via project manager or one-by-one from Asset Store. Web builds exist for testing and are **explicitly slower** than native. A 2D platformer demo on `master` advertises Godot 4.7 features, pixel-art character+physics, slopes, bullets, enemies, one closed level, player invincible. Release notes extract for tag `4.7-6ad6167` (date on GitHub extract: 07 Jul, year not verified here) lists added demos including Skeleton2D, audio effects, rhythm game, GUI accessibility, XR, split-screen input, ragdoll, HLOD visibility ranges. [G-GODOT-DEMOS] [G-GODOT-WEB] [G-GODOT-PLATFORMER]

Unity Performance Testing Package extends Unity Test Framework: `Measure.Method`, raise `MeasurementCount` (example 7 → 20), `WarmupCount` to exclude init, avoid sub-1ms measurements, disable VSync and extra Quality levels when comparing, UTF always builds a **development player** which overrides the development-build UI bit. Profiler groups `PlayerLoop` vs `EditorLoop`; Play mode profiling that includes EditorLoop pollutes “Others.” Deep Profiling hooks both loops. [G-UNITY-PERF] [G-UNITY-PROFILER]

Epic Automation (official extracts): tests split into Unit (API), Functional (PIE, in-game, resolution), and content/stress. Tests that used to ship inside Engine/Editor were moved to plugins (RuntimeTests, EditorTests, EngineTest). Run from Editor **Tools > Test Automation**, Session Frontend (network instances), Unreal Frontend, or `-ExecCmds="Automation RunTest …;Quit"` with optional `Group:` filters and `+ExcludeTest` in `DefaultEngine.ini` (reason required; can be RHI-scoped). Screenshot comparison is a first-class result tab. [G-UE-AUTOMATION]

Gauntlet (UE 5.4–5.6 extracts) runs **sessions** (all processes a game needs — e.g. four clients + server). It does not require a particular game-side framework. `RunUAT RunUnreal` wrappers: `UE.BootTest` / `UE.EditorBootTest`, `UE.EditorAutomation` / `UE.TargetAutomation`, `UE.Networking`, `UE.ErrorTest`, `UE.PLMTest`. Console/mobile deploy needs device interfaces implemented. Controllers (`UGauntletTestController`) puppet runtime, especially net tests; `EndTest(ExitCode)` is the handoff to UAT. Horde Automation Hub is Epic’s internal-style result browser; the example graph packs **Lyra** and runs a Boot Test on a reserved device. [G-UE-GAUNTLET] [G-UE-HORDE]

CQTest (UE 5.8 API extract) is a Developer module with latent commands (`FWaitUntil`, `FRunSequence`), PIE network state restore, and actor spawn helpers — the type Rider’s `ue-test-authoring` skill names. [G-UE-CQTEST]

Unity Boss Room (full README): official co-op RPG sample on Netcode for GameObjects. Pins **Unity 6000.0.52 LTS**, **NGO 2.4.3**, sample **v3.0.0**. Server-authoritative with **latency-masking animations**; NetworkTransform for position/rotation. Patterns indexed in-repo: action anticipation, projectile spawn, RPCs, NetworkAnimator, NetworkRigidbody throw, persistent player, connection approval with reason, Relay vs IP, UGS Sessions/Auth **optional**. Git LFS required to clone. **Unity Companion License** (Unity-dependent, AS IS) — not MIT; shipping a fork is a legal Step 1.5/8 question. Windows zip path-length is a documented unpack failure. Min spec includes iPhone 6S / Galaxy J2 Core. [G-UNITY-BOSSROOM] [G-UNITY-BOSSROOM-LIC]

### Nested process contract (proposed)

An asset PRD is not closed until an **engine receipt** exists:

1. Import log with zero unknown-material warnings
2. Pose stills in-engine vs DCC vs ref (three-way)
3. Playback of the contact set at gameplay dt
4. One performance sample (see §11) on the target class of hardware
5. Provenance sidecar copied into the cooked record

**Protocol map:** Step 0 pins engine+sample versions. Step 8 writes the receipt schema. Step 11.5 tasks include the receipt. Step 14 may later bind editor MCP; until then, receipts are human or scripted, not agent-clicked.

---

## 6. Environment, world, level, puzzle — same granularity

### Portable principle

Environments get the same layering as characters: identity (readable world rules) → blockout (playable volumes) → kit pieces → materials/light → collision/navigation → streaming/LOD → engine validation. Puzzles are levels with extra state machines, not a separate art universe.

### Demonstrated

Lyra documents Geometry Tools used to build **parametric level-design geometry in Blueprints** and the workflow level designers use with those pieces. That is an engine-specific LD kit approach. [G-UE-LYRA]

*Deep Dive* transcript extract: environment and prop pipelines are thinner copies of the character pipeline; asset level still depends on how often the piece appears. [G-DEEPDIVE-YT]

Godot demos include isometric, hex, voxel, CSG, HLOD visibility ranges, navigation meshes — each demo is a **narrow slice**, MIT, version-pinned. Use as acceptance oracles for a technique, not as a world-building method. [G-GODOT-DEMOS]

**Gap:** Steve Lee / Level Design Book and environment art production bibles belong to the design-production half unless a technical constraint (budget, streaming, nav) is needed. This half owns: collision, navmesh, lightmap/GI budgets, streaming, HLOD, puzzle-state save.

### Nested process contract (proposed)

| Layer | Artifact | Pass evidence |
|---|---|---|
| World rules | Readable material language + scale (door, stair, cover) | Playable at the camera’s real FOV |
| Blockout | Grey volumes, no hero art | Target traversal times met |
| Kit | Modular pieces with snapped grid and matching texel | No light leaks at module seams |
| Collision / nav | Simplified hulls, nav volumes | Agent path exists for every intended route |
| Puzzle state | Explicit states + reset | Save/load restores mid-puzzle |
| Streaming | Load units + budgets | No hitch above budget when crossing a unit |

**Protocol map:** Step 4 flow tree = rooms/routes/puzzle states. Step 5 wireframe prototypes = blockouts. Step 8 = streaming and collision. Step 10 features = which spaces are PRD-worthy.

---

## 7. 2D, sprite, vector equivalents

### Portable principle

2D does not skip gates. Identity still locks with turnarounds (now: orthographic sheets, frame grids). “Topology” becomes silhouette pixel stairs, pivot placement, and skinning bones for deform sprites. “UV/material” becomes atlas packing, filtering (nearest vs linear), and palette/ramp rules. “Rig” becomes 2D bones / mesh-warp / swap sets. “Contact states” are the animation frame set plus hitboxes.

### Demonstrated

Godot’s official 2D platformer demo is a complete-enough slice: character controller, slopes, projectiles, enemies, tilemap, audio. Skeleton2D and 2D lights/shadows/particles appear as separate official demos. GUI accessibility is a listed 4.7-era demo. These demonstrate **engine capability**, not an art pipeline. [G-GODOT-DEMOS] [G-GODOT-PLATFORMER]

**Gap:** Aseprite docs, Spine/DragonBones licenses, vector (Flash-like / Rive) runtimes — not inspected. Do not assume skeletal 2D is free of runtime fees.

### Nested process contract (proposed)

Same table as 3D with renamed artifacts: sprite sheet / atlas, pivot document, hitbox document, frame-timing document, palette lock. Engine validation: one scene at target resolution with filtering that matches art intent (pixel art usually nearest, no unwanted mip smear).

**Protocol map:** identical step numbers; Step 6 tokens are pixels-per-unit, atlas size, max unique palettes.

---

## 8. Audio pipeline (technical half)

### Portable principle

Audio is an asset with the same provenance and budget rules: source (recording, synth, licensed pack, generative), sample rate, intensity peaks, memory, and **interactive states** (not a linear mix). Buses and attenuation are the “material system.” Music that follows gameplay is a state machine.

### Inspected

Godot demo set includes audio effects, BPM sync, generator, mic record, MIDI piano, rhythm game, spectrum — MIT slices. [G-GODOT-DEMOS]

Lyra lists “sounds” among optimized hand-crafted content. No MetaSounds method was read. [G-UE-LYRA]

**Gap (material):** FMOD, Wwise, Unreal MetaSounds, Unity Mixer/Audio Random Container, Brian Schmidt / Guy Whitmore practitioner texts — not inspected this session. Audio methodology in this file is a **proposed contract** pending those primaries.

### Nested process contract (proposed, pending gap-fill)

| Gate | Pass evidence |
|---|---|
| Source | License + loudness referenced to project LUFS |
| Implementation | Event names match gameplay contact states |
| Mix | Ducking/bus duck documented; no clip at peak combat |
| Memory | Uncompressed vs cooked size within budget |
| Fail | Mute/fail-soft if a bank missing |

**Protocol map:** Step 3 UX includes audible feedback. Step 7 states include audio states. Step 8 names middleware or native. Step 1.5 if audio packs are monetized DLC.

---

## 9. Architecture, engine/platform choice, input, saves, tools, build

### Portable principle

Engine choice is a Step 2 architecture decision with an exit criterion, not a brand preference. Pin **engine version + sample version + DCC version** together (Lyra launcher mismatch is the cautionary tale). Input is a platform matrix. Saves are a schema with migration. Tools are the asset pipeline (DCC background mode, importers, validators). Build is reproducible cooks.

### Demonstrated

- Lyra: sample ≠ product; EOS needs extra config; mannequin skeleton is a compatibility bet with MetaHuman. [G-UE-LYRA] [G-UE-EOS]
- Godot demos: branch per engine version; web is a worse performance oracle. [G-GODOT-DEMOS]
- Unity UTF performance tests: Quality levels and VSync must be pinned or comparisons lie; development player is always on under UTF. [G-UNITY-PERF]
- Rider: Unity support via bundled plugin + `JetBrains Rider Editor` UPM package; Godot 4.0+ GDScript via LSP to a running editor (runtime-created nodes have no completion); Godot C# full; Godot editor addon for Rider requires Godot 4.5+; Rider 2026.2+ Godot project templates. [G-RIDER-UNITY] [G-RIDER-GODOT]
- Third-party ADR: Blender background Python as the only legal automation; generated exports gitignored; pre-commit rejects edits to generated dirs. [G-STUDIO-FOUNDATION-ADR]

### Proposed engine-choice experiment (any game)

Build the same 30-second vertical slice three ways **only if** the architecture step has not yet locked an engine: (a) official sample of engine A, (b) official sample of engine B, (c) DCC-to-glTF dummy in both. Score: hours to input+save+one animated character+one packaged build. Do not score renderer beauty.

If the engine is already locked by the product, skip the bake-off. Run only the interchange experiment (glTF or FBX round-trip).

Godot 4.7 export (full page): presets live in committable `export_presets.cfg`; secrets in gitignored `.godot/export_credentials.cfg`. Export templates must be installed (ICU data extra for CJK/Thai/etc.). Resource modes include **dedicated server** (strips most visuals to placeholders). Dotfiles never pack. CLI: `godot --path <proj> --export-release "Windows Desktop" some_name.exe` — output path is **project-relative, not CWD**. PCK is uncompressed/fast; ZIP is smaller/moddable but a known bug means the binary will not auto-find a ZIP pack (need a launcher `--main-pack`). Texture compression differs by platform (desktop S3TC/BC vs mobile ETC). [G-GODOT-EXPORT]

Godot save tutorial (full page): identify persist objects (example: `"Persist"` group); each node returns a dict; JSON line-per-object under `user://`; load **destroys then recreates** instanced scenes. JSON cannot store Vector2/Color/etc. without packing; nested Persist children break NodePaths unless parents load first. Binary `store_var`/`get_var` is the alternative, serializing only `PROPERTY_USAGE_STORAGE`. ConfigFile is for settings, not game state. Official serialization demo lives in godot-demo-projects. [G-GODOT-SAVE]

Minimum save contract (proposed, now grounded): versioned schema, checksum, n-1 migration, explicit non-saved list (rng, mid-puzzle, accessibility). Godot JSON tutorial is a teaching slice, not a production schema.

**Protocol map:** Step 0 runtime + DCC pins. Step 2 engine/platform/backends. Step 8 input/save/build. Step 14 local tool runners (`blender -b`, engine CLI cooks). Never Step 14 as “agent has the editor.”

---

## 10. Conditional multiplayer, session, backend, monetization

### Portable principle

Multiplayer and live backends are **conditional**. Solo/local games skip them. When present, they are architecture (Step 2) and offer (Step 1.5), not an asset afterthought. Replication, authority, rollback vs delay, platform session APIs, and cheat surfaces are the technical objects.

### Demonstrated

Lyra was designed with online/multiplayer and EOS integration as a documented path. Testing in editor `-game` is not the same as a packaged client. [G-UE-EOS] [G-UE-LYRA]

Godot split-screen input appears as an official demo; that is local multiplayer, not networked. [G-GODOT-DEMOS]

Godot 4.7 high-level multiplayer (full page): SceneTree `MultiplayerAPI` + `MultiplayerPeer` (ENet default, also WebRTC/WebSocket). High-level API is UDP-based; **forward UDP**, not only TCP. Server peer id is always 1. RPCs need identical NodePaths and **identical @rpc signatures on client and server scripts** (checksum of all RPCs in the script); argument lists are *not* part of that checksum — a footgun. Default `@rpc` is authority / call_remote / reliable / channel 0. Channels keep chat from stalling gameplay. HTML5 lacks some high-level and raw TCP/UDP. Android needs `INTERNET` permission. Auth callback exists on SceneMultiplayer. **Security section is explicit:** clients must not author positions, combat, inventory, or match outcomes; validate RPC args; rate-limit; server is source of truth. Dedicated-server export is a separate doc; sample lobby code is **not** dedicated-server ready. Cites Gaffer on Games for UDP vs TCP. [G-GODOT-MP]

Unity Boss Room (above) is the NGO educational stack: host/client composition, Relay/Sessions optional, connection approval. Unreal Lyra+EOS remains the Unreal online path. None of these is a default for a local game.

### Monetization (proposed boundary)

Store IAP, ads, battle pass, cosmetic marketplace, and paid character packs all import **rights** into the asset sidecar. A MetaHuman-compatible UV or a Mixamo animation is not a license to ship. Step 1.5 owns the offer; this technical half owns: entitlement checks, restore-purchase, platform overlay, and the rule that generative or scraped textures cannot enter a shipped pack without provenance.

**Protocol map:** Step 1.5 offer. Step 2 online services. Step 8 entitlements. Step 11 PRDs for each networked feature. Skip the whole branch when the product is local-only.

---

## 11. Performance, test ladders, packaging, ops

### Portable principle

A test ladder is ordered evidence: data validation → unit/functional → content automation (turntables, nav, save) → performance samples on target class hardware → package/install/boot → soak. Packaging is a store/platform contract (signing, stripping debug, shader precompile, depot layout).

### Demonstrated

Unity Performance Testing Package is an official ladder rung: profiler markers, custom metrics, hardware metadata for cross-device compare. Tips: one Quality level, VSync off where legal, skip rendering if you are not measuring it, don’t trust sub-millisecond tests. [G-UNITY-PERF]

Unity Profiler: Play mode should be read through `PlayerLoop`. Editor samples in `EditorLoop` pollute. Deep Profiling is a different, heavier instrument. [G-UNITY-PROFILER]

Meta’s Unity Performance Settings sample (updated 2026-08-11 in the inspected page) shows runtime CPU/GPU levels, FFR, resolution scale, spacewarp, Job System stress — **Quest-specific**, Unity 6000.0.66f2+. Useful as “performance is a runtime control surface,” not as a PC/console bible. [G-UNITY-META-PERF]

Lyra animation docs treat Fast Path / thread-safe update as a performance practice, not a visual one. [G-UE-ANIM]

Godot web demos warn that browser performance is not native performance. Packaging tests must use the real target. [G-GODOT-WEB]

Gauntlet/Horde (above) fill the Unreal packaged-session rung. Godot CLI export fills a cook/package rung. Steamworks depots, console TRC/TCR, Unreal Insights, and Godot profiler pages remain **incomplete**.

### Proposed test ladder (any game)

1. **Asset validate** (names, units, transforms, UVs, material count, triangle budgets, skeleton names, license sidecar)
2. **DCC deform tests** (canonical poses)
3. **Engine functional** (boot, load, input, save/load, one contact-set)
4. **Content automation** (screenshot turntable, nav path exists, audio event fires)
5. **Performance sample** (official engine profiler +, if Unity, Performance Testing Package; pin quality/VSync)
6. **Package** (installable build, clean boot, no dev overlay)
7. **Soak / soak-lite** (30 min loop of the vertical slice)

**Protocol map:** Step 8 test strategy. Step 11 acceptance includes ladder rungs. Step 11.5 tasks emit the commands. Step 15 the production telemetry contract.

---

## 12. AI-assisted DCC, editor, and coding workflows

### Portable principle

Agents may **propose**. Official IDEs may **refactor with a real index**. Community MCP that drives a live DCC or game editor is a **privileged robot** with the same blast radius as a human clicking “delete.” Whitelist scripts (`blender -b --python`, engine commandlets, Rider semantic refactor) beat open-ended “run Python in the editor.”

### Demonstrated / official-adjacent

JetBrains `rider-skills` (full README on `master`, **8 commits**, Apache License 2.0, copyright 2026 JetBrains s.r.o.): Agent Skills call **Rider MCP** so rename/extract/safe-delete use the IDE index. Six skills: `refactoring-code`, `debugging-code`, `finding-tests`, `ue-code-authoring`, `ue-live-debugging`, `ue-test-authoring`. UE skills require a `.uproject` in the working directory. Runtime: load live MCP schemas (never guess param names); degrade to grep when MCP is disconnected and **document which IDE steps were skipped**. Install: Rider Settings → Tools → MCP Server → Auto-Configure; Claude `/plugin marketplace add JetBrains/rider-skills` or Codex marketplace. Official JetBrains GitHub badge. Effectiveness on a shipped game is still unmeasured here. [G-RIDER-SKILLS] [G-RIDER-LIC] [G-RIDER-UE-HELP] [G-RIDER-YT]

### Untested tools (community Unreal MCP — do not standardize)

Multiple unofficial servers exist, with conflicting architectures and security notes:

| Repo (inspected via README extract) | Mechanism | Stated requirement | Risk note in their own README |
|---|---|---|---|
| `db-lyon/ue-mcp` | TS server + C++ plugin; claims wrapping Epic 5.8 AI Toolset Registry (~830 `epic_*` tools) | UE 5.4–5.8 (marketing site) | Full editor drive; MIT claimed on site |
| `ChiR24/Unreal_mcp` | C++ Automation Bridge, HTTP/SSE or WS | UE 5.0–5.8 claimed | Native automation plugin |
| `runreal/unreal-mcp` | Built-in Python remote execution, no extra plugin | UE 5.4+ verified | **Not official**; agents get full Editor; review changes |
| `chongdashu/unreal-mcp` | Native TCP plugin | UE 5.5+, Python 3.12+ | Community |
| `sam-david/unreal-mcp` | Built-in Python + Remote Control | UE 5.3+; **multicast bind 0.0.0.0 after 5.3** | Tools “being validated against 5.6” |
| `flopperam/unreal-engine-mcp` | Plugin; project **acquired by Aura**; hosted vs thinner OSS | splits product | Hosted vs local are different trust surfaces |
| `gimmeDG/UnrealEngine5-mcp` | Plugin + RAG over Python API | UE 5.6+ | Community |

Epic 5.8 “AI Toolset Registry” is **claimed by community wrappers**. This session did not open an Epic primary page that defines that registry. Treat “830 official Unreal tools” as **unverified claim**. [G-UEMCP-*]

### Blender MCP

The connected Grok session had a Blender MCP server available. Studio-foundation ADR disables community Blender MCP and allows only whitelisted background scripts. Storm/Blender Studio pipeline is file-based task layers, not chat-driven viewport control. **Do not activate Blender MCP as part of this methodology.** Remote code execution into a DCC is a rights and safety issue (file overwrite, license-violating export, silent mesh mutation). [G-STUDIO-FOUNDATION-ADR]

### Agent-assisted video tutorials

YouTube leads encountered (parent frame-review only; **not watched here**):

- Blender Conference 2025 — *The Use of Blender in the Making of the Animated TV Series Deep Dive* — https://www.youtube.com/watch?v=zJIlg3TxHNc
- *Lyra Starter Game Overview* — State of Unreal 2022 — https://www.youtube.com/watch?v=Fj1zCsYydD8

### Nested process contract (proposed)

| Allowed without extra HITL | Requires HITL | Forbidden in Atlas execution |
|---|---|---|
| Rider semantic rename/tests on a local project the human opened | Any editor MCP that spawns/deletes actors or assets | Purchases, store upload, enabling Remote Execution on a shared editor |
| Read-only inspection of official sample docs | Whitelisted `blender -b` scripts the repo owns | Community MCP as a default install |
| Drafting PRDs/checklists | PIE/play-in-editor driven by an agent | Claiming a video was watched from a transcript snippet |

**Protocol map:** Step 12/13/14 may *prepare* skills that wrap official CLIs and Rider. Step 14 does not ship a live Unreal/Blender MCP as a default. Step 15 logs agent tool calls if they exist.

---

## 13. Mapping onto Sigma Protocol 0–15 (+1.5, 11.5)

This is a **proposed adaptation**. Canonical Protocol numbering stays. Game work nests inside steps; it does not add pseudo-steps.

| Step | Game-assets / technical nesting | HITL gate (examples) |
|---|---|---|
| **0 Environment** | Pin DCC LTS, engine version, official sample version, interchange format (glTF/FBX), OS/target hardware class. Doctor: can we open the official sample? | Approve pins |
| **1 Ideation** | Identity of *playable beings and spaces* as product, not art direction yet | Approve pillars; art mode 2D/3D/hybrid |
| **1.5 Offer** (conditional) | Cosmetic SKUs, IAP, marketplace packs, licensed audio/characters — provenance becomes a shipping constraint | Approve what is sold vs shipped |
| **2 Architecture** | Engine/platform, authority model, asset master store (DCC files vs engine native), online or local, middleware audio | Approve engine and interchange |
| **3 UX** | Readable silhouette at play camera, HUD/diegetic, audio feedback language | Approve readability tests |
| **4 Flow tree** | Locomotion + interaction + puzzle states = contact-set inventory; world routing | Approve state inventory completeness |
| **5 Wireframes / prototypes** | Block meshes, greybox levels, dummy mannequin, temp audio events | Approve playable blockout before hero art |
| **6 Design system** | Texel density, material count, palette/ramp, animation timing tokens, audio LUFS | Approve budgets as tokens |
| **7 Interface states** | Animation contact states, cloth/fail, loading, streaming hitch UX, mute/fail-soft audio | Approve empty/error/loading for worlds and bodies |
| **8 Technical spec** | Skeleton contract, task-layer JSON, sidecar schema, cook/CLI, save schema, test ladder, packaging | Approve interchange + test ladder |
| **9 Landing** (optional) | Trailer/capture pipeline uses the same provenance rules | — |
| **10 Feature breakdown** | Which characters, biomes, weapons, networked features deserve PRDs | Approve PRD-worthy rows |
| **11 PRD generation** | One PRD per shippable asset family or system, with numeric budgets and receipt | Approve PRDs |
| **11.5 Task handoff** | Tasks emit validator commands and receipt paths; no “make it look good” | Approve backlog |
| **12 Context engine** | AGENTS.md: asset law, no MCP-by-default, skeleton names, units | — |
| **13 Skillpack** | Project skills: validate-asset, cook, performance-sample; engine adapters | — |
| **14 Runtime bootstrap** | Whitelisted CLI tools only; Linear dispatch; **plan/prepare** editor automation | Human before enabling editor bridges |
| **15 Observability** | GPU mem, draw, anim thread, audio CPU, hitch traces, provenance of shipped assets | No ship without traces |

**Atlas:** may generate the nested checklists, sidecars, and PRD shells. May not run cooks, purchases, or editor MCP.

---

## 14. Execution-handoff contracts (testable, Atlas-prepares-only)

Each shipped asset family gets a folder:

```
assets-source/<id>/
  refs/                 # individual multiview stills, not collages
  sheets/               # anatomy, components, clothing, props, materials
  master.blend|ma|...   # DCC master (engine is not master unless architecture says so)
  <id>.meta.json        # provenance + budgets
assets-generated/       # gitignored cooks, turntables, reports
receipts/<id>/
  dcc-validate.json
  engine-threeway.png
  contact-set.md
  perf-sample.json
```

`meta.json` minimum fields (proposed): `id`, `license`, `source`, `creator`, `aiGenerated`, `lodPolicy`, `collisionPolicy`, `texelTarget`, `triBudget`, `skeleton`, `animationSet`, `engineMinVersion`, `dccMinVersion`.

**Acceptance evidence for a character PRD:**

1. Lineup test passed (identity)
2. Individual multiview files exist
3. Deform poses pass in DCC
4. Three-way visual comparison (ref / DCC / engine) attached
5. Contact-set plays at gameplay speed without foot slide beyond tolerance
6. Performance sample under budget on the pinned device class
7. Sidecar license allows the target stores

**Acceptance evidence for a level/puzzle PRD:**

1. Blockout traversal times
2. Nav/collision receipt
3. Mid-puzzle save/load
4. Streaming hitch ≤ budget
5. Lighting mode is the game’s, not a DCC viewport

Commands belong in 11.5 as placeholders until Step 0 pins the engine (`just asset-validate`, Unreal commandlets, Godot `--headless`, Unity Test Runner). Atlas writes the contract; humans enable the toolchain.

---

## 15. Conflicting alternatives (do not flatten)

| Topic | Alternative A | Alternative B | How a project chooses |
|---|---|---|---|
| Master DCC | Blender LTS + glTF | Maya/Max + FBX | Existing staff + interchange tests, not brand |
| Skeleton | Engine mannequin / MetaHuman hierarchy | Custom skeleton | Retarget cost experiment in §4 |
| Collaboration | Task-layer files (Blender Studio) | One file + locks | Team size; solo skips layers |
| Automation | Whitelisted CLI | Community editor MCP | Default CLI; MCP only under HITL |
| Animation source | Hand-authored + warp (Lyra) | Full mocap / marketplace | Contact-set quality in-engine |
| 2D deform | Frame swap | 2D bones (Skeleton2D, Spine) | License + look; Spine is not assumed free |
| Audio | Native engine | FMOD/Wwise | Interactive music complexity (gap: middleware docs) |
| Tests | Official samples as oracles | Home-grown | Prefer official sample techniques, then project tests |
| Multiplayer | None | EOS / Netcode / Godot RPC | Conditional on product |

---

## 16. Rights, provenance, version, security

- **Marketplace / MetaHuman / Mixamo / Daz:** UV or skeleton compatibility is not a ship license. Record license in sidecar. Mixamo and MetaHuman terms were **not** opened this session (gap).
- **Godot demos:** MIT, but still not your game’s art license if you copy assets.
- **Lyra / Epic samples:** Fab/launcher distribution; sample code is for learning; check Epic’s sample license before shipping derivatives (full EULA **not** pasted here — gap).
- **MCP:** Full editor access; Python Remote Execution; UE 5.3 multicast bind-address footgun (`127.0.0.1` → `0.0.0.0`) as stated by a community README. Enabling this on a machine with production content is a security decision.
- **AI textures/meshes:** Sidecar `aiGenerated` + source prompt/tool + whether training-rights allow commercial ship. Unknown if not recorded.
- **Version pins:** Engine, sample, DCC, Rider, Godot 4.5+ for some Rider addons, Unity 6000.x for some Meta samples. “Latest” is not a pin.

---

## 17. Small assumption-testing experiments

Run only after Step 0 pins tools. Atlas may write the script; humans run it.

1. **Still-pack experiment:** two characters, refs only, second artist block-mesh match rate.
2. **Skeleton experiment:** dummy mannequin vs custom mesh retarget, foot-slide delta.
3. **Task-layer experiment:** shading+rigging on one asset in parallel vs single file; count overwrite incidents.
4. **Interchange experiment:** glTF round-trip of one skinned, animated mesh into the pinned engine; list lost data (tangents, morphs, lights, UDIM tiles, >4 bone influences, unsampled constraints). Use a Khronos sample (WaterBottle or Fox) as a control.
5. **Profiler experiment:** empty scene vs one hero vs one full room; Unity users follow Performance Testing Package pinning rules; others use native profiler.
6. **MCP threat experiment (optional, isolated copy):** can a community Unreal/Blender MCP delete a mesh without a clear diff? If yes, it stays off the default path.
7. **2D atlas experiment:** nearest vs linear at target resolution; screenshot evidence.
8. **Save experiment:** kill process mid-puzzle; reload. On Godot, compare JSON line format vs `store_var` for Vector types and nested Persist nodes.
9. **RPC signature experiment (networked games only):** change an `@rpc` annotation on one peer only; confirm the checksum error appears before shipping.
10. **Export credentials experiment:** clone the repo on a second machine without `.godot/export_credentials.cfg` (or engine analog) and record which secrets must be restored.

---

## 18. Research gaps remaining

**Filled this bounded pass:** Polycount topology/character/texel/padding; Blender 5.2 UV + glTF manuals; Khronos sample-assets license shape; Godot 4.7 export/save/multiplayer; Unity Boss Room README + Companion License; JetBrains rider-skills Apache-2.0 LICENSE + 8-commit `master`; Epic Automation / Gauntlet / CQTest / Horde extracts; Godot demos MIT body.

**Still open (do not treat as demonstrated):**

1. Disney 12 Principles via a living legitimate education page (Animation Mentor URL 404; Khan Academy page returned an empty shell)
2. Richard Williams *Animator’s Survival Kit* publisher/body text
3. Mixamo and MetaHuman **license** pages
4. FMOD / Wwise / Unreal MetaSounds / Unity Audio Random Container manuals
5. Epic primary page defining the UE 5.8 “AI Toolset Registry” (community MCP count unverified)
6. Unreal Insights, Godot profiler, Steamworks depots, console TRC/TCR
7. Spine / DragonBones / Aseprite runtime licenses
8. Full Epic Lyra sample EULA text
9. Input-map manuals beyond Godot RPC/Android INTERNET and Unity NGO sample
10. Exact-frame video review (parent-owned): Deep Dive, Lyra 2022 talk

Audio middleware, store licensing, and Disney/Williams education texts are the largest remaining holes. Nested contracts there stay **proposed**.

---

## Source index (this half)

See `GROK-ASSETS-TECHNICAL-SOURCES.json` for machine records.

**Carefully checked primaries (18):** G-BLENDER-STUDIO, G-BLENDER-STORM, G-UE-LYRA, G-UE-ANIM, G-UE-EOS, G-GODOT-DEMOS, G-GODOT-EXPORT, G-GODOT-SAVE, G-GODOT-MP, G-UNITY-PERF, G-UNITY-BOSSROOM, G-RIDER-SKILLS, G-BLENDER-GLTF, G-BLENDER-UV, G-POLYCOUNT-TOPO, G-UE-GAUNTLET, G-GLTF-SAMPLES, G-POLYCOUNT-CHAR.

| ID | Title | Evidence status |
|---|---|---|
| G-BLENDER-STUDIO | Blender Studio Asset Pipeline add-on | search-extract, demonstrated in studio film work |
| G-BLENDER-STORM | Project Storm log #5 | search-extract, demonstrated |
| G-BLENDER-UV | Blender 5.2 UV unwrapping introduction | **full-page** official |
| G-BLENDER-GLTF | Blender 5.2 glTF 2.0 add-on | **full-page** official |
| G-DEEPDIVE-YT | Blender Conference 2025 Deep Dive | transcript extract; **video unwatched** |
| G-UE-LYRA | Lyra Sample Game docs | search-extract, official |
| G-UE-ANIM | Animation in Lyra | search-extract, official |
| G-UE-EOS | EOS + Lyra tutorial (Zeigler) | search-extract, official tutorial |
| G-UE-LYRA-VERSION | Fab/launcher version thread | search-extract, user-demonstrated friction |
| G-UE-AUTOMATION | Automation System / run tests | search-extract, official |
| G-UE-GAUNTLET | Gauntlet RunUnreal / controllers | search-extract, official |
| G-UE-CQTEST | CQTest API | search-extract, official API |
| G-UE-HORDE | Horde test automation tutorial | search-extract, official; Lyra boot test example |
| G-GODOT-DEMOS | godot-demo-projects README | search-extract, official repo |
| G-GODOT-LIC | godot-demo-projects LICENSE.md | **full-page** MIT |
| G-GODOT-WEB | Demos exported to web | search-extract, official |
| G-GODOT-PLATFORMER | 2D platformer project.godot extract | search-extract |
| G-GODOT-EXPORT | Exporting projects (Godot 4.7) | **full-page** official |
| G-GODOT-SAVE | Saving games (Godot 4.7) | **full-page** official |
| G-GODOT-MP | High-level multiplayer (Godot 4.7) | **full-page** official |
| G-UNITY-PERF | Performance Testing Package | search-extract, official |
| G-UNITY-PROFILER | Profiler Play/Editor samples | search-extract, official |
| G-UNITY-META-PERF | Meta Unity performance sample | search-extract, platform-specific |
| G-UNITY-BOSSROOM | Boss Room NGO sample README | **full-page** official |
| G-UNITY-BOSSROOM-LIC | Boss Room LICENSE.md | **full-page** Unity Companion License |
| G-RIDER-SKILLS | JetBrains/rider-skills README | **full-page** official; Apache-2.0; 8 commits |
| G-RIDER-LIC | rider-skills LICENSE | **full-page** Apache-2.0, Copyright 2026 JetBrains |
| G-RIDER-UE-HELP | Rider UE AI skills help | search-extract |
| G-RIDER-GODOT | Rider Godot help | search-extract |
| G-RIDER-UNITY | Rider Unity help | search-extract |
| G-RIDER-YT | RIDER-138629 | search-extract, JetBrains design claim |
| G-POLYCOUNT-TOPO | Topology - polycount wiki | search-extract, practitioner wiki |
| G-POLYCOUNT-CHAR | Character / Character Modeling | search-extract |
| G-POLYCOUNT-BODY | BodyTopology (Tindall image credit) | search-extract |
| G-POLYCOUNT-TEXEL | Texel | search-extract |
| G-POLYCOUNT-PAD | Edge padding | search-extract |
| G-GLTF-SAMPLES | Khronos glTF-Sample-Assets | **full-page** README; per-model licenses |
| G-UEMCP-DBLYON | db-lyon/ue-mcp | search-extract, untested community tool |
| G-UEMCP-RUNREAL | runreal/unreal-mcp | search-extract, untested; security warning |
| G-UEMCP-SAM | sam-david/unreal-mcp | search-extract, untested; 5.3 bind-address |
| G-UEMCP-FLOP | flopperam → Aura | search-extract, product split |
| G-TINDALL | Brian Tindall IMDb | credits; method still unpublished |
| G-GNOMON-RIG | Gnomon Character Rigging for Production | course listing, Maya |
| G-WHITSETT | Gnomon Workshop game rigging | course listing |
| G-STANLEY-GROSSMAN | Gnomon Workshop production rigging | course listing / AWN reprint |
| G-DAZ-CLAIM | Daz game-ready launch | vendor claim |
| G-BLAZE-AUTOPOSE | Blaze AutoPose | vendor limits, useful as limitation card |
| G-STUDIO-FOUNDATION-ADR | ADR 0006 Blender master pipeline | other-studio policy; contrast on MCP |

