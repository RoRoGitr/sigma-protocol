# Technical: pins, engine decision, interchange, input, saves, online, entitlements, build and tool policy

Generated from catalog 1.0.0.

Make the technical decisions with exit criteria and bounded experiments: version pins, engine and platform decision or bake-off, interchange contract with a control asset, input matrix, save schema with migration, conditional multiplayer, conditional entitlements, build and packaging, and the AI-tooling policy that keeps editor automation off by default.

Applicability: Every game. Engine, platform, multiplayer and monetization are unknown until the creator answers; phases for unknown items stay unresolved with a revisit condition rather than skipped. Multiplayer and entitlement phases are marked not-applicable with a reason for local, free games. Interchange applies to any art mode, including sprite atlases and audio banks.

Atlas stages: 0, 1.5, 2, 8, 11, 15, 16, 17, 18. Canonical steps: 0, 1.5, 2, 8, 11.5, 12, 13, 14, 15.

## version-pins — Version pins

### Creator questions

- **pins**: Exact versions for every chosen tool: engine, official sample projects, DCC, IDE and plugins, middleware, export templates, build tools. 'Latest' is not a pin. Unchosen tools are listed as unchosen.
- **mismatch-check**: Did the pinned sample actually open in the pinned engine? Marketplace listings and launcher caches can disagree.
- **secrets**: Which credentials or export secrets exist, where they live outside the repository, and what a second machine needs restored.

### inputs

- Creator profile fixed facts
- Step 0 baseline

### activities

- Record pins
- Open each pinned sample and record the result
- Separate committed presets from ignored credentials

### tools

- Package managers
- Launchers

### skills

- game-technical-production

### roles

- game-technical-director
- creator

### outputs

- Pin table with open-check results

### dependencies

- None specified.

### reviewCriteria

- Every chosen tool has an exact version
- Samples were opened, not assumed
- Secrets are outside the repo

### revisionRules

- Any pin change re-opens every receipt that cited it

### Evidence required

Open-check results: which sample opened in which engine version, with the launcher or console output. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Lyra Starter Game and Game Animation Sample only allows UE 5.4 despite listing 5.6](https://forums.unrealengine.com/t/lyra-starter-game-and-game-animation-sample-only-allows-ue-5-4-despite-listing-support-for-5-6/2546643/1) — source-claim. Single user thread, self-resolved. Not Epic engineering confirmation.
- [Exporting projects (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) — verified-source-text. Full page read by the research seat (Godot 4.7 docs); URL reconstructed from the page title by the catalog author, re-check the version path. ZIP pack auto-discovery bug noted in the docs.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.

## engine-platform-decision — Engine and platform decision or bake-off

### Creator questions

- **locked**: Is an engine or framework locked by the product, team skills or existing code? If yes, record it and skip the bake-off. If no, what candidates?
- **bake-off**: If not locked: the same short slice built on each candidate's official sample (input, save, one animated thing or one sprite, one packaged build). Score hours to each milestone, not renderer beauty. What is the exit criterion?
- **platform-class**: Distribution and hardware class (PC storefront, console, mobile, web, handheld) as a class, not a brand, and what it constrains.
- **license**: Engine, sample and dependency licenses: do they allow the intended distribution and monetization? Which are unread (record the gap)?
- **ide**: IDE and agent-coding integration: which official integrations exist for the engine, and what needs the editor running?

### inputs

- Architecture inputs
- Creator profile
- Art mode
- Kill-assumptions

### activities

- Lock or run the bake-off with exit criteria
- Choose the platform class
- Check licenses or record the gap

### tools

- Official engine samples
- Timer

### skills

- game-technical-production
- decisions-patterns

### roles

- game-technical-director
- lead-architect
- creator

### outputs

- Engine ADR or bake-off result with exit criterion

### dependencies

- version-pins

### reviewCriteria

- Decision has an exit criterion or a lock reason
- Platform is a class
- Licenses are checked or gaps listed

### revisionRules

- A bake-off result locks the engine and re-opens pins
- A platform class change re-opens budgets and input matrix

### Evidence required

Bake-off timings and packaged builds per candidate if run; otherwise the lock reason. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Lyra Sample Game in Unreal Engine](https://docs.unrealengine.com/lyra-sample-game-in-unreal-engine) — verified-source-text. Official docs extract. Unreal-specific. Sample version may lag engine (see G-UE-LYRA-VERSION). Full sample license not read.
- [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) — verified-source-text. README and LICENSE read. Demos are slices, not a production pipeline. Web builds are slower than native and not a ship oracle.
- [Unity Boss Room co-op sample (Netcode for GameObjects)](https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop) — verified-source-text. Full README and license read by the research seat; URL reconstructed by the catalog author from the sample name, re-check. Unity Companion License, not MIT; Git LFS required.
- [Godot support | JetBrains Rider Documentation](https://www.jetbrains.com/help/rider/Godot.html) — verified-source-text. Official help extract. Runtime-created nodes have no completion; add-on floor Godot 4.5.
- [Game development for Unity | JetBrains Rider Documentation](https://www.jetbrains.com/help/rider/Unity.html) — verified-source-text. Official help extract. Does not cover DCC tooling.
- [Introduce Unreal Engine AI Skills: RIDER-138629](https://youtrack.jetbrains.com/issue/RIDER-138629) — source-claim. Issue-tracker design text, not a measured study.

## interchange-contract — Interchange contract and round-trip experiment

### Creator questions

- **formats**: Which formats carry meshes, rigs, animation, sprites, atlases, audio and data into the engine?
- **known-losses**: From documentation: which data does each format lose or transform (triangulation, vertex splits at UV seams or hard edges, bone influence caps, UDIM splitting, unsupported nodes, unsampled constraints, physics or lights)?
- **round-trip**: Plan the round-trip experiment: one skinned animated asset (or one sprite atlas and one audio bank) through the pipeline into the pinned engine, with a known-good control asset. What will be compared?
- **sidecar**: The provenance and budget sidecar schema fields and where the sidecar travels.

### inputs

- Engine decision
- Art mode
- Asset master store decision

### activities

- Choose formats
- List documented losses
- Run the round-trip with a control
- Define the sidecar

### tools

- DCC exporter
- Engine importer
- Control assets

### skills

- game-technical-production

### roles

- game-technical-director
- creator

### outputs

- Interchange contract with round-trip results and sidecar schema

### dependencies

- engine-platform-decision

### reviewCriteria

- Losses come from documentation or experiment, not assumption
- The control asset imported as expected
- Sidecar fields are defined

### revisionRules

- An engine or exporter version change re-runs the round-trip

### Evidence required

Round-trip results: import logs, comparison stills, list of lost data, for both the project asset and the control. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [glTF 2.0 add-on (Blender Manual)](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Real-time transmission support uneven; physics, lights and material animation do not export.
- [KhronosGroup/glTF-Sample-Assets](https://github.com/KhronosGroup/glTF-Sample-Assets) — verified-source-text. README read by the research seat. Use as interchange controls, not as shippable product art without reading each model README.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.

## input-matrix — Input matrix

### Creator questions

- **devices**: Which input devices are supported per platform class, and which is primary for testing?
- **mapping**: Verb-to-input mapping per device, with remapping rules and conflicts.
- **latency**: Input-to-response latency budget per device and how it is measured.
- **accessibility**: Hold-to-toggle alternatives, single-input modes, dead zones, and other input accessibility answers from scoping.

### inputs

- Platform class
- Verb inventory
- Accessibility scoping

### activities

- Build the matrix
- Set latency budgets
- Apply accessibility answers

### tools

- Spreadsheet
- Input recorder

### skills

- game-technical-production
- accessibility-audit

### roles

- game-technical-director
- creator

### outputs

- Input matrix with latency budgets

### dependencies

- engine-platform-decision

### reviewCriteria

- Every verb maps on every supported device
- Remapping exists
- Latency has a measurement method

### revisionRules

- A new verb adds a row
- A new device class adds a column

### Evidence required

Matrix; measured latencies are recorded in quality.performance-budgets. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.

## save-schema — Save schema and migration

### Creator questions

- **schema**: Versioned schema: what is saved, what is never saved (random state, mid-animation, accessibility preferences stored separately), and the checksum or integrity check.
- **format**: Text or binary, and why; how engine-specific types (vectors, colours, node paths) are represented.
- **migration**: n-1 migration rule and how a corrupt or future-version save is handled without a crash.
- **experiment**: Plan the kill-and-reload experiment across a mid-puzzle or mid-progress state.

### inputs

- Architecture save model
- Level persisted-state lists
- Progression model

### activities

- Write the schema
- Define migration and corruption handling
- Run kill-and-reload

### tools

- Engine serialization
- Save inspector

### skills

- game-technical-production

### roles

- game-technical-director
- creator

### outputs

- Save schema with migration rule and experiment result

### dependencies

- engine-platform-decision

### reviewCriteria

- Never-saved list exists
- Corrupt saves do not crash
- Kill-and-reload passed or failures listed

### revisionRules

- A new persisted field bumps the schema version and adds a migration

### Evidence required

Kill-and-reload result from a real build with the compared fields. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Saving games (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Teaching slice, not a production save schema.

## multiplayer-conditional — Multiplayer and online (conditional)

### Creator questions

- **applies**: Does the game have online play, asynchronous play, or online services? If none, mark not-applicable with that reason and stop here.
- **authority**: Where is truth: host, dedicated server, relay, peer? Which state may a client never author (position, combat, inventory, outcomes)?
- **transport**: UDP or TCP, channels for chat versus gameplay, NAT or relay strategy, platform session APIs, and what the web or mobile targets lack.
- **cheat-surface**: RPC argument validation, rate limits, signature or checksum mismatches between peers, and how they are tested.
- **packaged-test**: Editor tests are not packaged tests: plan the packaged multi-client session test (clients plus server) and what is measured.

### inputs

- Architecture online scope
- Offer decision
- Platform class

### activities

- Decide authority
- Choose transport and services
- List cheat surfaces and tests
- Plan the packaged session test

### tools

- Engine networking docs
- Packaged builds
- Multiple machines or instances

### skills

- game-technical-production

### roles

- game-technical-director

### outputs

- Multiplayer architecture and test plan, or a not-applicable record

### dependencies

- engine-platform-decision
- save-schema

### reviewCriteria

- Not-applicable carries a reason
- Clients never author outcomes
- A packaged session test is planned

### revisionRules

- A change from local to online re-opens architecture and every level's multiplayer constraints

### Evidence required

Packaged session test results (client count, server, measured desync or disconnect behaviour) when run. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [High-level multiplayer (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Sample lobby code is not dedicated-server ready. HTML5 lacks some transport features.
- [Unity Boss Room co-op sample (Netcode for GameObjects)](https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop) — verified-source-text. Full README and license read by the research seat; URL reconstructed by the catalog author from the sample name, re-check. Unity Companion License, not MIT; Git LFS required.
- [Using Epic Online Services with Lyra Starter Game](https://dev.epicgames.com/community/learning/tutorials/375e/unreal-engine-using-epic-online-services-with-lyra-starter-game) — verified-source-text. Official tutorial extract (updated 2026-03-02). EOS-specific; not executed here.
- [Gauntlet Automation Framework in Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/gauntlet-automation-framework-in-unreal-engine) — verified-source-text. Search extract; URL reconstructed from the page title, re-check before external citation. Console and mobile deploys need device interfaces implemented.

## monetization-entitlements — Entitlements and store integration (conditional)

### Creator questions

- **applies**: Is anything sold, unlocked or licensed (paid app, extras, subscription, ads)? If none, mark not-applicable with that reason.
- **entitlements**: Entitlement checks, restore-purchase, offline grace, and platform overlay requirements.
- **provenance-gate**: Rule that no generated or scraped asset ships in a sold pack without recorded provenance and rights; how it is enforced in the build.
- **platform-cert**: Certification or store review requirements known so far, and what is unread (record the gap).

### inputs

- Offer decision (Step 1.5)
- Platform class
- Sold-asset provenance

### activities

- Specify entitlements
- Enforce the provenance gate
- List certification requirements or gaps

### tools

- Platform SDK docs

### skills

- game-technical-production

### roles

- game-technical-director
- finance-director
- general-counsel

### outputs

- Entitlement specification or a not-applicable record

### dependencies

- engine-platform-decision

### reviewCriteria

- Not-applicable carries a reason
- Provenance gate is enforced, not advisory

### revisionRules

- An offer change re-opens this phase

### Evidence required

Specification; entitlement tests are recorded in quality.test-ladder. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.
- [Steam Playtest (Steamworks Documentation)](https://partner.steamgames.com/doc/features/playtest) — verified-source-text. Partner docs read; feature not exercised (no partner account used). PC-storefront specific. Leak risk for unannounced games. Wishlist non-interference is Valve's claim, not measured here.

## build-packaging — Build and packaging

### Creator questions

- **reproducible**: Headless or CLI build command, committed presets, ignored credentials, and the output path rule (some tools resolve relative to the project, not the shell).
- **strip**: What is stripped from shipping builds (debug overlays, development player flags, editor-only data) and how it is verified?
- **texture-audio-cook**: Per-platform texture compression and audio cook settings.
- **clean-boot**: Plan the clean-machine install and boot test.
- **second-machine**: What a fresh clone on another machine needs restored to build (credentials, templates, LFS)?

### inputs

- Engine decision
- Platform class
- Pins

### activities

- Script the build
- Verify stripping
- Run clean boot and second-machine experiments

### tools

- Engine CLI
- Clean VM or second machine

### skills

- game-technical-production
- ci-cd-patterns

### roles

- game-technical-director
- devops

### outputs

- Build and packaging specification with experiment results

### dependencies

- version-pins
- engine-platform-decision

### reviewCriteria

- Build is a command
- Stripping is verified
- Clean boot passed or failures listed

### revisionRules

- An engine or platform change re-runs clean boot

### Evidence required

Build logs, the packaged artifact hash, and clean-boot results. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Exporting projects (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) — verified-source-text. Full page read by the research seat (Godot 4.7 docs); URL reconstructed from the page title by the catalog author, re-check the version path. ZIP pack auto-discovery bug noted in the docs.
- [Performance Testing Package for Unity Test Framework](https://docs.unity3d.com/Packages/com.unity.test-framework.performance@latest) — verified-source-text. Official package page extract. Unity-only. Development player changes the thing you measure.
- [Gauntlet Automation Framework in Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/gauntlet-automation-framework-in-unreal-engine) — verified-source-text. Search extract; URL reconstructed from the page title, re-check before external citation. Console and mobile deploys need device interfaces implemented.
- [Unity Boss Room co-op sample (Netcode for GameObjects)](https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop) — verified-source-text. Full README and license read by the research seat; URL reconstructed by the catalog author from the sample name, re-check. Unity Companion License, not MIT; Git LFS required.

## ai-tooling-policy — AI-assisted tooling policy

### Creator questions

- **allowed**: Which agent actions are allowed without extra approval: drafting documents, read-only inspection, IDE-indexed refactors on a project the human opened, whitelisted background scripts the repository owns?
- **gated**: Which require a recorded human decision each time: any live editor bridge that spawns or deletes actors or assets, play-in-editor driven by an agent, remote code execution into a DCC?
- **forbidden**: Which are forbidden on this project: purchases, store uploads, enabling remote execution on a shared editor, community editor MCP as a default install, claiming a video was watched from a transcript?
- **evidence**: For any agent-produced change: what evidence must accompany it (diff, render, playtest clip, unresolved defects list)?

### inputs

- Creator profile
- Engine decision
- Runtime bootstrap plan

### activities

- Write the allowed, gated and forbidden lists
- Require evidence per agent change
- Record any bridge decision with owner, isolated copy and rollback

### tools

- Atlas document editor

### skills

- game-technical-production
- harness-engineering

### roles

- game-technical-director
- creator

### outputs

- AI-tooling policy for AGENTS.md and the runtime

### dependencies

- engine-platform-decision

### reviewCriteria

- Editor bridges are gated, not default
- Evidence is required per change
- Forbidden list exists

### revisionRules

- Enabling a bridge is a recorded revision of this policy

### Evidence required

Policy only. Agent-produced changes carry their own evidence. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [JetBrains/rider-skills](https://github.com/JetBrains/rider-skills) — verified-source-text. README and Apache-2.0 LICENSE read by the research seat. Requires Rider plus MCP. Effectiveness on a shipped game unmeasured.
- [Introduce Unreal Engine AI Skills: RIDER-138629](https://youtrack.jetbrains.com/issue/RIDER-138629) — source-claim. Issue-tracker design text, not a measured study.
- [runreal/unreal-mcp](https://github.com/runreal/unreal-mcp) — untested-integration. Not run. Not official Epic. Full editor authority is a footgun; never a Protocol default.
- [sam-david/unreal-mcp](https://github.com/sam-david/unreal-mcp) — untested-integration. Not run. Comparison tables are competitive marketing. Fragmented ecosystem.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.
- [Agent-assisted Unreal tutorial (Stefan 3D AI)](https://www.youtube.com/watch?v=iRcrZjOt5H8) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/video-evidence/agent-runner/REVIEW.md): captions, 12 overview frames and 12 exact frames (0.37 s) showing locomotion while a score advances. Does not establish geometry correction, physics stability, packaging, performance or multiplayer. Prices and capability rankings unverified. No plugin installed or game executed by Atlas.
