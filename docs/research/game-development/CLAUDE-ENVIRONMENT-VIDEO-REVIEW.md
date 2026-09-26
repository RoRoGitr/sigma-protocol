# Environment tutorial video review — Stefan 3D AI, "I Built a Whole Game Level Using Only FREE AI"

Source: https://www.youtube.com/watch?v=6Ytluv_DiSo (31:24, 1280x720 AV1, 25 fps constant, 47,097 frames).
Reviewed 2026-09-22 by a bounded Claude Code worker. Brief: `briefs/claude-video-review.md`.
Purpose: evidence for a reusable ANY-game environment-production method. This is an environment tutorial. It is not proof of character or rigging capability.

## 1. Coverage truth

| Evidence stream | What was actually examined | Gaps |
|---|---|---|
| Transcript | Full auto-caption track, 800 segments, 00:02 to 31:22, read end to end | Auto captions with rolling duplicate lines and product-name artifacts (see §6). Silence 23:04 to 23:25 is a timelapse. |
| Overview frames | All 12 keyframes listed in `/tmp/sigma-game-videos-environment-report.md`, each opened with Read | 12 frames across 31 minutes is one frame per ~157 s. 18 near-duplicates were dropped by the tool. Anything between keyframes is unseen unless listed below. |
| Single-frame probes | 14 extra frames pulled with ffmpeg at transcript-cued times (17:01, 22:26 to 22:35, 27:20), stored under `/tmp/sigma-game-videos/environment-detail/probe/` | Single stills, not continuity. Nine are cropped to the Blender stats overlay only. |
| Exact consecutive frames | Source frames 33714 to 33725 (12 frames, t=1348.56 s to 1349.00 s), every PNG opened individually | 0.44 s of real screen time. One state change captured. |

Timing derivation: `ffprobe` reports `r_frame_rate=25/1`, `avg_frame_rate=25/1`, `nb_frames=47097`, and decoded `pts_time` steps of exactly 0.040 s around the chosen range. Frame N sits at N × 0.04 s.

Not observed anywhere in this review: gameplay, frame rate or performance numbers, collision, navigation, LOD setup, lightmap UVs, packaging, Unity or Godot, any rig or skeleton for the level, any character work for this level.

## 2. What the video shows, in order (transcript + frames)

| Time | Transcript claim | Visual evidence | Verdict |
|---|---|---|---|
| 00:02–01:30 | Three-phase plan: building blocks → assemble in Blender → set up in engine | frame_0001 (t=0.00): dark Blender viewport with grid and sailboat silhouette. Intro only. | Plan stated, not yet shown. |
| 01:31–03:22 | Free Nano Banana in Google AI Studio; split the concept into chunks; circle parts on the image; generate small props as groups; generate textures | frame_0043 (t=126.04): `edited-image.jpg`, grey cave concept render with hand-drawn red outlines around rock chunks. frame_0084 (t=169.48): Gemini chat, prompt asks for four pillars of different heights (50 cm to 200 cm) in a row on white, and the output shows three graded wooden posts. | Decomposition by annotation is demonstrated. Group-generation is demonstrated. Prompt asked for four pillars; the visible output shows three, so output fidelity is not guaranteed. |
| 03:22–05:30 | Hunyuan gives 20 free daily generations; high-poly for big objects, "smart topology" low-poly for simple ones; sponsor segment for Tripo (captions render it "Topo Pie 2") with quad topology | frame_0127 (t=305.84): Tripo workspace, quad-topology stylised head, topology stats readable in the top-right (Quad, ~2.1k faces). | Sponsor demo on a character head, not on this level's assets. Proves the tool exists and outputs quads. Proves nothing about the cave. |
| 05:30–06:38 | Blender as free assembly tool; one plane split into four papers sharing one material; fishnet the same way | No overview frame lands here. | Transcript only. |
| 06:38–09:31 | Export GLB, retexture in a free AI texturing tool (captions: "Motive"/"Modif"), inpaint broken areas, regenerate crate sides, retexture anchor from a reference, "add as layer" projects a view | frame_0169 (t=508.20): web texturing tool, white untextured anchor in the viewport, reference-image strip with crate and rope thumbnails, Layers panel with "Base texture", Generate panel Single/Multiview, status "Loading...". | Tool UI and the untextured anchor are visible. The improved anchor texture itself is not in any inspected frame. |
| 09:31–10:36 | Blender clone brush for small artifacts; save textures | No overview frame lands here. | Transcript only. |
| 10:36–13:43 | Color-correct in shader nodes, join two crates, duplicate to high/low, new material "box", UV Packer add-on to unwrap and pack, bake Diffuse (no direct/indirect) selected-to-active with cage into one atlas | frame_0219 (t=753.60): Blender 4.3.2, two white crates (materials stripped), outliner shows `low` collection plus `barrels_high`, `crate_high` and similar, Shift+A node-add menu open, Principled BSDF present, stats Objects 1/1, Vertices 3,304, Faces 6,143, Triangles 6,143. | The join-and-strip step is visible with real counts. The bake result itself is not in any inspected frame. |
| 13:43–14:18 | Course promotion | frame_0262 (t=943.92) is later; nothing here. | Skip. |
| 14:18–15:19 | Paint roughness and metallic maps with fill brush in Texture Paint, non-color data | No overview frame lands here. | Transcript only. |
| 15:19–20:12 | Cave built from rock chunks, not a tiled surface; Decimate to ~0.1 twice (claims ~1M polys → ~1k per rock); manual seams; bake 4K normal from high to low; Gemini seamless color/roughness; Node Wrangler mapping scale 4; bake final Diffuse and Roughness | frame_0262 (t=943.92): UV Editing workspace, dark cobblestone tile texture, plus an overlaid "GAME IN 72 HOURS AI" thumbnail. This is the previous Souls-like video being referenced, not this level. probe_t1021 (t=1021): Edit Mode, object `wall_low` under `rock_low`, Edge context menu open with "Mark Seam" highlighted, low-poly rock visible, status bar reads Verts 19/681, Faces 0/1,358, Tris 1,358. | Seam marking on a decimated rock is visible with counts. The 1M→1k claim, the normal bake and the Gemini textures are not in any inspected frame. |
| 20:12–23:04 | Reference image in scene; start with known-size chunks (piers, ladders, huts); hotkeys; 80–90% is moving things; knife-cut the never-visible bottom of big rocks to save polygons | Exact-frame batch 33714–33725 and probes (see §3). frame_0310 (t=1151.72) is a motion-blur transition and proves nothing. | Knife cut and face deletion are proven at frame level. |
| 23:25–24:18 | "1 hour later" for the pier chunk; accessories last | Timelapse. No frame inspected inside it. | Time claim unverifiable. |
| 24:18–25:26 | Cave assembled from big chunks in "around 25 minutes"; stalactites are a cut and scaled rock reusing the same texture | Timelapse. No frame inspected inside it. | Time claim unverifiable. Reuse claim is consistent with the shared `rocks_inside` material seen in §3 but not directly shown. |
| 25:26–28:04 | Lights for preview; collections per chunk; accessories; rope from a Bézier curve with depth, converted to mesh, seam cut, Gemini tile rope texture | frame_0394 (t=1533.12): Camera Perspective, material preview of the cave interior with water, sailboat, pier, barrels, huts, ladders; stats Objects 2/399, Vertices 8/356,124, Edges 8/870,708, Faces 7/539,017, Triangles 4/533,599; active object `rocks_low.118`. probe_t1640 (t=1640): Edit Mode on `BézierCurve` with material `rope_mat`, Extrude Curve and Move panel open, rope mesh threading through a hook above a boat, rocks with baked-looking texture behind. | Whole-scene poly budget is readable: about 534k triangles across 399 objects before engine import. Curve rope is visible mid-edit. |
| 28:04–30:46 | Export to Unreal; recreate each PBR material by hand; water, sky and weather are engine-side (Ultra Dynamic Sky and Ultra Dynamic Weather named); about 2 hours in Unreal for lights, VFX, boat float animation | frame_0435 (t=1725.24): Unreal Engine 5 level `AI_Cave`, outliner shows `Ultra_Dynamic_Sky`, `BP_OceanWater`, `PlayerStart`, `boat`, `boat_water`, `SK_Boat_Anim`; content browser shows `Material`, `Texture`, `boat_water`, `cave`, `boat_water_Physics...`; viewport is a mostly white water plane with a warning banner. | Import into Unreal is proven. Materials, lights, animation and VFX setup are not shown at frame level. The named sky and weather add-ons are paid marketplace products as far as this reviewer knows, which contradicts the "only free" framing outside the AI steps. Not verified here. |
| 30:46–31:22 | Final result | frame_0478 (t=1876.76): Unreal render, cave mouth backlit, sailboat, pier, barrels, lantern, hanging boat on rope with hook. | Final quality is real and matches the concept. It is the creator's own beauty shot, not gameplay. |

## 3. Exact consecutive frame evidence

Chosen detail: the knife cut that removes the never-visible underside of a big rock chunk, transcript 22:12 to 22:36. Chosen because it is the one place where editable geometry, a real poly-saving decision and a readable before/after count all sit in the same half-second.

Batch: `python3 .../watch.py video.mp4 --frame-range 33714:33725 --resolution 1024 --no-whisper --out-dir /tmp/sigma-game-videos/environment-detail`.
Manifest: `/tmp/sigma-game-videos/environment-detail/frames/native_33714_33725_manifest.json`.

Scene in every frame: Blender 4.3.2, Edit Mode, Front Orthographic (Local), object `plate_low.003`, material slot `rocks_inside` (Principled BSDF with `rocks_inside_BaseColor` and `rocks_inside_Roughness` textures), outliner collections `rock`, `details`, `wood_balk`, `wood_box`, `wood_big_details`, `more_details`, `ref`, `water`. Wireframe view of a long flat rock slab with red UV seam lines and one red horizontal knife stroke drawn across the upper third.

| Source frame | t (s) | Visible state |
|---|---|---|
| 33714 | 1348.56 | Knife tool active. Status bar shows knife hints (Cut, Close, Stop, Confirm, Cancel, Undo, Angle Constraint). Key overlay "X, C". Stats Vertices 0/922, Edges 0/2,758, Faces 0/1,838, Triangles 1,838. Transform panel: "Nothing selected". |
| 33715 | 1348.60 | Identical to 33714. |
| 33716 | 1348.64 | Identical to 33714. |
| 33717 | 1348.68 | Identical to 33714. Last pre-confirm frame. |
| 33718 | 1348.72 | Cut confirmed. Key overlay "C, Return". Status bar reverts to Select / Rotate View / Call Menu. Stats Vertices 205/1,125, Edges 205/3,166, Faces 0/2,043, Triangles 2,244. Transform panel now shows a Median (X 0.0046 m, Y 0.0125 m, Z 0.1233 m). Orange selected vertices trace the cut line across the slab. |
| 33719 | 1348.76 | Identical to 33718. |
| 33720 | 1348.80 | Identical to 33718. |
| 33721 | 1348.84 | Identical to 33718. |
| 33722 | 1348.88 | Identical to 33718. |
| 33723 | 1348.92 | Identical to 33718 (presenter's head moves, viewport static). |
| 33724 | 1348.96 | Identical to 33718. |
| 33725 | 1349.00 | Identical to 33718. |

What this proves: the knife stroke added 203 vertices and 205 faces to a decimated AI rock and left the 205 new vertices selected. That is real, editable, engine-agnostic mesh topology on an AI-generated asset. The cut is a single straight line; it is not sculpting or retopology.

What it does not prove on its own: that polygons were saved. That comes from the follow-on single-frame probes, which are stills, not continuity:

| Probe | t (s) | Visible state |
|---|---|---|
| probe_t1346 | 1346.0 | Key overlay "Shift+Z, K" (wireframe toggle, knife). Stats 0/922 verts, 0/1,828 faces. |
| probe_t1352 | 1352.0 | Key overlay "3, X". Face select mode, underside faces selected in orange, Delete menu open with "Faces" highlighted. Stats 876/1,125 verts, 1,436/2,042 faces. |
| stats_t1352.5 | 1352.5 | Vertices 0/448, Edges 0/1,052. Underside deleted. |
| stats_t1353 | 1353.0 | Object Mode, `water | plate_low.003`, 448/448 verts, 1,052/1,052 edges. |
| stats_t1354 | 1354.0 | Zoomed out, Objects 1/84, scene Vertices 448/135,284, Edges 1,052/316,488. Textured rock visible. |

Net for this one rock: 922 vertices before the cut, 448 after the underside was removed. That is a 51% vertex reduction on a single asset, measured from on-screen stats. The transcript says "a lot of polygons"; the numbers back it for this asset only.

## 4. Demonstrated versus claimed

| Area | Creator claim | Demonstrated in inspected evidence | Gap |
|---|---|---|---|
| Asset decomposition | Circle parts of a concept and generate each; group small props | frame_0043 annotated cave, frame_0084 grouped pillars | Solid. Output count can drift from the prompt (four asked, three shown). |
| 3D generation | Hunyuan free 20/day; high-poly vs smart-topology low-poly; Tripo quads | Tripo UI on a sponsor head only | No frame shows a Hunyuan generation or this level's raw AI output. Tool claims are transcript-only. |
| Editable geometry | Decimate, knife, boolean, curve-to-mesh | Knife cut at frame level (§3), seam marking (probe_t1021), curve rope (probe_t1640), crate join (frame_0219) | Decimate ratios and the 1M→1k claim not observed. |
| UV and material channels | Unwrap, pack, bake Diffuse/Normal/Roughness into atlases, paint Roughness/Metallic | Seams visible, Principled BSDF with BaseColor and Roughness textures visible on `rocks_inside`, materials stripped for bake on crates | No bake output, no UV layout, no normal map, no atlas image seen. |
| Color consistency | Shader color nodes then bake | Shift+A menu at the Color submenu (frame_0219) | Correction result not seen. |
| Composition | Reference in scene, known-size anchors first, big volumes, accessories last, collections per chunk | frame_0394 shows the finished Blender scene with 399 objects and the outliner collections named by chunk | Assembly itself is timelapsed. Order of operations is transcript-only. |
| Poly budget | Implied "optimized" | ~534k triangles for the whole Blender scene (frame_0394); one rock 922→448 verts | No engine-side budget, no LODs, no performance figure. |
| Engine import | Works in Unreal, Unity, Godot; materials recreated by hand; dynamic water/sky/weather engine-side | Unreal only (frame_0435, frame_0478) | Unity and Godot are assertions. Ultra Dynamic Sky and Weather are paid products as far as this reviewer knows, so "only free" holds for the AI steps but not for the shown engine scene. Not verified. |
| Time | ~1 h piers, ~25 min cave, ~2 h Unreal, whole level in one video | All three windows are timelapsed or off-camera | Unverifiable. Treat as lower bounds from an experienced user with a prepared asset list. |
| Pricing | Nano Banana free via AI Studio, Hunyuan free tier, texturing tool free, Blender free, Tripo affiliate discount | Tool UIs seen; no pricing pages seen | Transcript-only. Free tiers change; re-verify at planning time. |
| Quality | "Amazing", concept-faithful | frame_0478 is a strong render and does match the concept | Beauty shot from the author's camera. No gameplay camera, no player scale check, no collision. |

## 5. Portable rules for our method (our adaptation, not source claims)

These are written for the Sigma planning and handoff layer. Names are ours. Each rule states its output artifact and what a reviewer checks. Nothing here inherits the creator's timings, the pirate cave, or any single-room constraint.

**R1 Decomposition map.**
Output: an annotated concept image plus `decomposition.md` listing every chunk with a size class (anchor / volume / accessory), a generation route (image→3D high-poly, image→3D low-poly, primitive, cut-from-existing), and whether it is a group generation.
Review: every visible region of the concept belongs to exactly one chunk; every anchor has a real-world size written down before anything is generated; group generations name the expected count so drift is caught (source showed a four-asked, three-delivered case).

**R2 Starter-pack manifest.**
Output: `starter-pack.json` with one row per asset: source, tri count before and after cleanup, texture channels present (BaseColor, Normal, Roughness, Metallic, Alpha), atlas membership, UV state (raw / unwrapped / packed), material name.
Review: no asset ships with a raw AI UV if it shares an atlas; per-asset tri counts are read from the tool, not estimated; every channel listed exists as a file.

**R3 Hidden-surface cull pass.**
Output: a before/after tri count per large asset and a one-line note of the cut method (knife, boolean, decimate ratio).
Review: any asset over the project's large-asset threshold has an explicit "underside or backside removed" or "kept because visible" decision. The source's single measured case was 922→448 vertices on one rock.

**R4 Channel and bake contract.**
Output: per material, which channels are baked (and from which high-poly), which are generated seamless tiles, and the bake resolution.
Review: baked normals exist for every decimated asset that must read as detailed at player distance; color corrections done in shader nodes are baked before export, since node graphs do not travel to the engine.

**R5 Assembly order and scene hygiene.**
Output: `assembly-plan.md` naming the first known-size chunk, the order of volumes, and the accessory pass; one Blender collection per chunk; the reference image placed in-scene.
Review: the plan starts from a chunk whose real size is known, never from the enclosing volume; accessories are last; every chunk can be hidden with one click.

**R6 Engine handoff checklist.**
Output: per engine, the list of materials to recreate, the systems left to the engine (water, sky, weather, grass, cloth, boat float), and the licensing status of every non-AI dependency.
Review: "free" claims are checked against the actual dependency list; any paid add-on is named before the build starts; the checklist records what has not been verified (collision, nav, LOD, lightmaps, target frame rate).

**R7 Evidence grade for any video-derived rule.**
Output: each rule carries a tag: transcript-only, sampled-frame, or exact-frame.
Review: only exact-frame or sampled-frame rules may be promoted to "demonstrated"; transcript-only rules stay "claimed" until reproduced in our own pipeline.

## 6. Limits and honesty notes

- Auto captions garble product names. Readings used here: "Hunian/Hunan/Huang Neng" = Hunyuan; "Topo Pie 2" = Tripo (confirmed by the UI in frame_0127); "Motive/Modif" = the AI texturing web tool seen in frame_0169, name not readable on screen; "Patina / poll.ai" = unresolved.
- Three time claims sit inside timelapses or off-camera. None were verified.
- The Tripo segment is a sponsor demo on a character head. It is the only character-shaped thing in the video and it proves nothing about rigging, animation or characters for this level.
- Twelve overview frames leave most of the Blender detail unseen. Sections marked "transcript only" in §2 were not visually checked.
- The exact-frame batch covers 0.44 s. It proves one knife confirm. Everything else about the cut sequence comes from single stills.
- No engine-side performance, collision, LOD, lightmap or packaging evidence exists in this video.
- The final render is a creator-authored camera view, not gameplay.

## 7. Nested workflow implications for Sigma

- Environment production fits as a nested track under the existing Steps 8, 10 and 11 contracts: the decomposition map (R1) is a Step 8 technical-spec input, the starter-pack manifest (R2) is the Step 10 feature-breakdown analogue for assets, and each chunk's cull, bake and assembly rules (R3 to R5) become per-chunk PRD acceptance criteria at Step 11.
- The engine handoff checklist (R6) belongs at the Step 11.5 task-handoff boundary and must record licensing of non-AI dependencies, since the source's "only free" framing does not survive the engine scene.
- The evidence grade (R7) should be applied to every rule in the game-development adaptation, and the same three grades (transcript-only, sampled-frame, exact-frame) should be the required vocabulary in future video reviews so claims are never promoted past their evidence.
- Nothing in this review supports a character, rig or animation contract. That needs its own source and its own exact-frame check.

## 8. Evidence paths

- Overview report and transcript: `/tmp/sigma-game-videos-environment-report.md`
- Overview frames: `/private/tmp/sigma-game-videos/environment/frames/frame_{0001,0043,0084,0127,0169,0219,0262,0310,0352,0394,0435,0478}.jpg`
- Exact frames and manifest: `/tmp/sigma-game-videos/environment-detail/frames/native_33714_33725_0001..0012.png`, `native_33714_33725_manifest.json`
- Single-frame probes: `/tmp/sigma-game-videos/environment-detail/probe/probe_t{1021,1346,1349.4,1352,1640}.jpg` and `stats_t{1347,1348,1348.5,1349,1352.5,1353,1353.5,1354,1355}.jpg`
- Source video (already downloaded, not re-fetched): `/tmp/sigma-game-videos/environment/download/video.mp4`
