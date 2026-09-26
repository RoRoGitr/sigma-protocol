# Game-development domain: step mapping

Human-readable companion to `catalog.json` (format `sigma-game-development`, version `1.0.0`). The JSON is canonical; this file explains it. Nothing here claims the Atlas integration is built or that any game was validated. Contract: `docs/research/game-development/INTEGRATION-CONTRACT.md`. Decision: `docs/research/game-development/ARCHITECTURE-DECISION.md`.

## How to read the catalog

- **Canonical steps** are Sigma Protocol Steps 0-15 plus conditional 1.5 and 11.5. Each entry points at its authoritative source file under `steps/` and says whether the game domain **reuses**, **adapts**, or treats the step as **conditional**. No step is not-applicable for games.
- **Atlas steps** are the twenty planning stages of the Atlas app (0, 1, 1.5, 2-18). Stages 0-11 map to canonical steps; 12-14 are operating-company stages with no single canonical equivalent and are preserved in full; 15-18 map to canonical 12-15.
- **Workflows** are twelve nested planning tracks. Each phase is a planning contract: inputs, creator questions, activities, tools, skills, roles, outputs, same-workflow dependencies, review criteria, revision rules, the external evidence required, and source IDs. Phases plan and verify; they never execute a game tool.
- **Sources** carry an evidence status: `verified-source-text` (a research seat read the page or PDF), `observed-footage` (frames were inspected in this commission), `source-claim` (listing, extract, transcript or press only), `untested-integration` (tool not run), `proposed-adaptation` (our own method). Reading documentation is never a runtime demonstration.

## Canonical Steps 0-15 (+1.5, 11.5)

| Step | Source file | Treatment | Game adaptation in one line | Workflows |
|---|---|---|---|---|
| 0 | `steps/step-0-environment-setup` | adapt | Record available prototype media, pin versions of tools already chosen, set the playtest capture path. No engine required. | discovery, technical, quality |
| 1 | `steps/step-1-ideation` | adapt | Lock experience goals as felt situations, aesthetic mix, core verb, interesting decision, kill-assumptions; idea packs and synthesis attach here. | discovery, systems, narrative, production, team |
| 1.5 | `steps/step-1.5-offer-architecture` | conditional | Runs only when the creator says the game is monetized or platform economics matter; undecided defers with a revisit condition. | technical, production |
| 2 | `steps/step-2-architecture` | adapt | Interaction model, art mode, engine ADR or bounded bake-off, simulation authority, save model, online scope. | systems, narrative, technical |
| 3 | `steps/step-3-ux-design` | adapt | Journeys include first session, fail, recovery, optional, ending; readability as a perception problem; direction studies as constraints. | narrative, characters, environments, interface, audio |
| 4 | `steps/step-4-flow-tree` | adapt | Add space, verb, interactable and contact-state inventories to the screen inventory. | systems, narrative, characters, environments, levels, interface |
| 5 | `steps/step-5-wireframe-prototypes` | adapt | First prototypes are the cheapest medium that can fail the goals; greybox, block mesh, dummy body and temp audio are legitimate. | discovery, systems, narrative, characters, environments, levels, quality |
| 6 | `steps/step-6-design-system` | adapt | Readability tokens with non-colour backups plus numeric asset budgets that become acceptance numbers. | characters, environments, interface, audio |
| 7 | `steps/step-7-interface-states` | adapt | World, body, puzzle and audio states join UI states, each with recovery and announcement. | characters, environments, levels, interface, audio |
| 8 | `steps/step-8-technical-spec` | adapt | Interchange contract, skeleton or rig contract, sidecar schema, input, save, buses, streaming, test ladder, engine receipt schema. | characters, environments, levels, audio, technical, quality |
| 9 | `steps/step-9-landing-page` | conditional | Store page, trailer and playtest policy; copy from goals only; coming-soon waits for a playable slice. | interface, quality, production |
| 10 | `steps/step-10-feature-breakdown` | adapt | Systems as proof rows, content packs as volume rows gated on proofs; asset levels; cuts cite the failed test. | systems, narrative, characters, environments, levels, audio, production |
| 11 | `steps/step-11-prd-generation` | adapt | PRDs carry door-problem answers, playtest protocol, budgets, accessibility answers and the receipt that closes them. | systems, characters, environments, levels, interface, audio, quality, production |
| 11.5 | `steps/step-11.5-task-handoff` | conditional | Tasks name the existing asset, narrow change, rollback, receipt command, dependency licensing and what stays unverified. | characters, environments, technical, quality, production |
| 12 | `steps/step-12-context-engine` | adapt | AGENTS.md game law: reference pack first, receipts before done, held decisions, evidence locations, no editor MCP by default. | technical, production, team |
| 13 | `steps/step-13-skillpack-generator` | adapt | Game skills cite catalog sources; thin adapters around official CLIs; planned game roles assigned to named holders. | technical, production, team |
| 14 | `steps/step-14-agent-runtime-bootstrap` | adapt | Whitelisted runners only; playtest and receipt ingest; editor bridges off until a recorded human decision. | technical, quality, production |
| 15 | `steps/step-15-observability-contract` | adapt | Goal events, decision histograms, performance traces on the hardware class, accessibility usage, provenance manifest. | systems, technical, quality |

## Atlas stages 0-18

| Atlas | Title | Canonical | Game addition | Workflows |
|---|---|---|---|---|
| 0 | Project setup | 0 | Creator-mode hint (solo default), prototype media, pins, capture path | discovery, technical, quality |
| 1 | Discovery | 1 | Experience goals, verb, decision, primary proof, kill-assumptions; profile and idea-pack documents live here | discovery, systems, narrative, production, team |
| 1.5 | Offer architecture | 1.5 | Monetization model or explicit undecided; sold-asset provenance | technical, production |
| 2 | Architecture | 2 | Interaction model, art mode, engine decision, authority, save, online | systems, narrative, technical |
| 3 | UX direction | 3 | First session, readability rules, HUD and feedback | narrative, characters, environments, interface, audio |
| 4 | Flow atlas | 4 | Space, verb, interactable and contact-state inventories | systems, narrative, characters, environments, levels, interface |
| 5 | Screen prototypes | 5 | Per-proof prototype PRDs and playtest protocols | discovery, systems, narrative, characters, environments, levels, quality |
| 6 | Design system | 6 | Readability and budget tokens | characters, environments, interface, audio |
| 7 | States and motion | 7 | World, body, puzzle and audio states; contact-state table | characters, environments, levels, interface, audio |
| 8 | Technical specification | 8 | Interchange losses, receipt schema, test ladder, conditional sections | characters, environments, levels, audio, technical, quality |
| 9 | Landing page | 9 | Store surface, lie test, playtest policy | interface, quality, production |
| 10 | Feature breakdown | 10 | Proof/volume tags, asset levels, cuts | systems, narrative, characters, environments, levels, audio, production |
| 11 | PRDs and work planning | 11, 11.5 | Prerequisite documents, acceptance receipts, task shape, licensing | systems, characters, environments, levels, interface, audio, technical, quality, production |
| 12 | Company operating map | (operating) | Rights and provenance owner, playtest operations owner, community owner; every function retained for any game | production, team |
| 13 | People and bot roles | (operating) | Planned game roles; contributors; the reserved synthesis document is saved here | production, team |
| 14 | Workflows and go-to-market | (operating) | Playtest SOP, release cadence, GTM tied to a playable slice, live-ops only if the offer says so | quality, production |
| 15 | Shared context | 12 | Game law block, held decisions, evidence paths | technical, production, team |
| 16 | Skills and playbooks | 13 | Game skills with source provenance; adapters around official CLIs | technical, production, team |
| 17 | Harness handoffs | 14 | Whitelisted runners, forbidden actions, editor-bridge decision | technical, quality, production |
| 18 | Readiness and handoff | 15 | Goal events, traces, unverified-properties list, provenance manifest | systems, technical, quality, production |

## The twelve workflows

Phase IDs are unique within a workflow; dependencies point only at earlier phases in the same workflow and are acyclic (validated). Reserved IDs: `discovery.profile`, `discovery.idea-pack`, `team.synthesis`.

| Workflow | Phases | Phase IDs in order | Applies when |
|---|---|---|---|
| discovery | 8 | profile, idea-pack, experience-goals, primary-proof, kill-assumptions, first-playtest, production-hold-list, discovery-synthesis-handoff | Every game |
| systems | 8 | interaction-model, verb-object-inventory, decision-audit, feel-track, progression-economy, class-to-class-rules, tuning-loop, systems-instrumentation | Every game; feel-track only with real-time control; class-to-class only for systemic or hybrid models |
| narrative | 6 | narrative-load, world-rules, story-structure, delivery-channels, environmental-storytelling, narrative-playtest | Any narrative or fictional world; abstract games mark load as none |
| characters | 12 | identity-proportions, view-sheets, component-sheets, geometry-plan, multiview-comparison, uv-layout, texture-material-channels, rig-plan, deformation-validation, locomotion-action-animation, contact-intermediate-states, engine-validation | Any visible or controlled being; each phase names its 2D, sprite, vector or text equivalent |
| environments | 10 | world-rules-scale, decomposition-map, blockout, modular-kit, hidden-surface-cull, material-bake-contract, set-dressing-assembly, lighting-plan, collision-navigation-streaming, engine-handoff-validation | Any perceived space or board, including tile maps and text rooms |
| levels | 10 | level-intent, constraints-inventory, solution-graph, door-problem-sheets, layout, blockout-playtest, teaching-fairness, recovery-fail-states, scripting-save-state, art-pass-readiness | Any bounded play unit, spatial or not |
| interface | 6 | readability-channels, hud-philosophy, onboarding-first-session, ui-perception-states, accessibility-scoping, interface-playtest | Any visual or audio interface, including text |
| audio | 6 | audio-role, bus-architecture, core-verb-sounds, adaptive-music-plan, asset-provenance-loudness, audio-validation | Any game with sound; adaptive music only when music follows state |
| technical | 9 | version-pins, engine-platform-decision, interchange-contract, input-matrix, save-schema, multiplayer-conditional, monetization-entitlements, build-packaging, ai-tooling-policy | Every game; multiplayer and entitlements conditional |
| quality | 7 | playtest-protocol, test-ladder, performance-budgets, accessibility-verification, evidence-grading, defect-triage, release-readiness | Every game |
| production | 7 | scope-appetites, asset-leveling, proof-before-volume, task-receipt-discipline, company-functions, risk-register, distribution-store-plan | Every game, including free solo games |
| team | 4 | contributors, synthesis, decision-record, revision-propagation | Every game; solo may synthesize alternatives alone |

### Character workflow, phase by phase

1. **identity-proportions**: role in play, silhouette, proportion set in a stated unit, material language, mutable parts, provenance. Evidence: a two-reviewer lineup test.
2. **view-sheets**: front, back, side and three-quarter as separate files with a shared scale bar and eye line; 2D facing sheet as the equivalent.
3. **component-sheets**: anatomy, components, clothing layers, props with sockets, materials with a count against budget.
4. **geometry-plan**: triangle or sprite budget per LOD, deformation zones for this body plan, high/low strategy, hidden-surface decisions.
5. **multiview-comparison**: orthographic overlays against each view file, tool-read counts, deform test poses, accept or return.
6. **uv-layout**: seams, measured texel density, atlas or UDIM or trim with export split plan, padding; sprite atlas and pivots for 2D.
7. **texture-material-channels**: channel manifest, colour spaces, bake contract, sizes, provenance per texture.
8. **rig-plan**: skeleton policy from a retarget experiment, bind versus control hierarchies, model inspection, face versus body, influence cap, tool limits.
9. **deformation-validation**: pose set with per-pose stills and accepted defects.
10. **locomotion-action-animation**: clip set for the contact-state inventory, timing tokens, source and license, export manifest.
11. **contact-intermediate-states**: transition matrix, ground-contact tolerance, socket and hitbox table, fail and recovery visibility, LOD switch behaviour.
12. **engine-validation**: import log, three-way stills, contact playback, performance sample on the hardware class, sidecar copy, unverified list.

### What was deliberately not adopted from the research inputs

- No fixed pillar or aesthetics count. The creator selects the experience goals and diagnostic lenses that the concept needs; each goal has an observable test or an explicit uncertainty.
- No universal paper-prototype rule. The primary proof picks the cheapest medium for the actual uncertainty; a pure-feel game starts in a greybox.
- No blanket art or narrative freeze and no "downstream illegal" rule. The hold list is a set of creator choices with release proofs, and early volume work is allowed when it is cheaper or the creator needs the practice.
- No assumption that a document proves quality. Every `evidenceRequired` string separates prepared plans from actual external results.
- No 3D pipeline as a requirement. Every asset phase names its 2D, sprite, vector, text or audio equivalent or a not-applicable path with a reason.
- No Mazerance, 30-day, V1, one-room or two-player constraints. Nothing in the catalog inherits them.
- No engine, genre, platform, multiplayer or monetization default. These stay unknown until the creator answers; unknown work stays unresolved, never silently skipped.

## Evidence honesty

- 65 sources: 35 verified-source-text, 22 source-claim, 5 untested-integration, 2 observed-footage, 1 proposed-adaptation.
- Several technical-page URLs (Blender manual, Godot docs, Unreal automation, Polycount, Unity Boss Room) were read by the Grok seat as full pages but not recorded with URLs in its source JSON; the catalog author reconstructed those URLs from page titles and says so in each `limitations` field. Re-check before external citation.
- The two `observed-footage` sources are the only runtime demonstrations. Their frame coverage is 0.44 s and 0.37 s respectively; everything else about those videos is transcript-only and is labelled that way.
- Company editor MCP servers appear only as `untested-integration` and only to justify the default-off policy.
