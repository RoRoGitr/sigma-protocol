# Quality: playtests, test ladder, performance, accessibility, evidence grades and readiness

Generated from catalog 1.0.0.

Plan how the game is proven: named playtest types, an ordered test ladder from asset validation to soak, performance budgets measured on the target hardware class, accessibility verification with people, an evidence grade for every claim, defect triage, and a release-readiness review that lists what is unverified.

Applicability: Every game. Rungs that do not apply (no assets to validate in a text game, no packaging for a web toy) are marked not-applicable with a reason. Platform playtests (storefront playtest programs) are optional and conditional on the distribution class.

Atlas stages: 0, 5, 8, 9, 11, 14, 17, 18. Canonical steps: 0, 5, 8, 9, 11, 11.5, 14, 15.

## playtest-protocol — Playtest protocol and types

### Creator questions

- **types**: Which playtest types will this project use and what question each answers: friends (existence), strangers (truth), recruited target players (usability), platform playtest program (scale), accessibility experts and players with lived experience (barriers)?
- **hygiene**: Who facilitates and who observes; how designer presence is limited; what testers are told before and after.
- **log-format**: Playtest log fields: date, build or medium version, tester type and count, per-goal behaviour, evidence grade, storage path, next change.
- **confidentiality**: Confidential versus public tests: what leak risk is accepted, and which tests use closed keys instead of a public program?

### inputs

- Experience-goal sheet
- Capture path
- Distribution class

### activities

- Define types and questions
- Set facilitation hygiene
- Create the log format

### tools

- Playtest log
- Recording tools

### skills

- game-quality-planning

### roles

- game-quality-lead
- creator

### outputs

- Playtest protocol and log template

### dependencies

- None specified.

### reviewCriteria

- Every type names the question it answers
- Designer bias is limited by protocol
- Log fields include evidence grade

### revisionRules

- A new distribution class may add a platform playtest type

### Evidence required

Protocol only; sessions are recorded in the workflows that run them. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.
- [Steam Playtest (Steamworks Documentation)](https://partner.steamgames.com/doc/features/playtest) — verified-source-text. Partner docs read; feature not exercised (no partner account used). PC-storefront specific. Leak risk for unannounced games. Wishlist non-interference is Valve's claim, not measured here.

## test-ladder — Test ladder

### Creator questions

- **rungs**: Order the rungs and mark each automated or manual: asset validation (names, units, transforms, UVs, material count, triangle budgets, skeleton names, license sidecar); DCC deform tests; engine functional (boot, load, input, save and load, one contact set); content automation (screenshot turntables, navigation paths, audio events fire); performance samples; package, install, clean boot; soak of the vertical slice.
- **commands**: For each automated rung, the command or test type (placeholders until the engine is pinned).
- **not-applicable**: Which rungs do not apply to this game and why (no assets, no packaging)?
- **gate-use**: Which rungs close a PRD, which close a wave, which close a release?

### inputs

- Technical spec
- Receipt schema
- Asset budgets

### activities

- Order the rungs
- Attach commands or placeholders
- Bind rungs to gates

### tools

- Engine test frameworks
- Validators

### skills

- game-quality-planning
- game-technical-production
- testing

### roles

- game-quality-lead
- game-technical-director

### outputs

- Test ladder with gate bindings

### dependencies

- playtest-protocol

### reviewCriteria

- Rungs are ordered
- Every rung is automated, manual or not-applicable with a reason
- Gate bindings exist

### revisionRules

- A new asset class adds validation rules
- An engine change replaces commands

### Evidence required

Ladder only; rung results are attached to receipts and readiness. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Automation System in Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/automation-system-in-unreal-engine) — verified-source-text. Search extract read by the research seat; the exact URL was reconstructed from the page title by the catalog author and should be re-checked before external citation.
- [Gauntlet Automation Framework in Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/gauntlet-automation-framework-in-unreal-engine) — verified-source-text. Search extract; URL reconstructed from the page title, re-check before external citation. Console and mobile deploys need device interfaces implemented.
- [Performance Testing Package for Unity Test Framework](https://docs.unity3d.com/Packages/com.unity.test-framework.performance@latest) — verified-source-text. Official package page extract. Unity-only. Development player changes the thing you measure.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.

## performance-budgets — Performance budgets and measurement

### Creator questions

- **targets**: Frame time or frame rate, memory, load time and hitch budgets per hardware class, and the minimum-spec device named.
- **method**: Measurement method: profiler markers, warm-up, repeated samples, pinned quality level and VSync state, development-player caveats, and why sub-millisecond samples are ignored.
- **scenes**: The empty scene, one hero asset, one full room (or one full stage) samples, and what each isolates.
- **real-target**: Which measurements were taken on the real target class and which on a stand-in (browser builds and editor loops are not ship oracles)?

### inputs

- Design budgets
- Hardware class
- Engine profiler

### activities

- Set budgets per class
- Fix the method
- Take the three reference samples on the real target when possible

### tools

- Engine profiler
- Performance test package where available

### skills

- game-quality-planning
- game-technical-production

### roles

- game-quality-lead
- game-technical-director

### outputs

- Performance budget table with reference samples

### dependencies

- test-ladder

### reviewCriteria

- Budgets have a device
- Method pins quality and VSync
- Stand-in measurements are labelled

### revisionRules

- A hardware class change re-sets budgets
- A budget breach re-opens the offending asset or scene

### Evidence required

Profiler captures with settings recorded; stand-ins labelled as such. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Performance Testing Package for Unity Test Framework](https://docs.unity3d.com/Packages/com.unity.test-framework.performance@latest) — verified-source-text. Official package page extract. Unity-only. Development player changes the thing you measure.
- [Play mode and Editor profile samples (Unity)](http://docs.unity3d.com/Documentation/Components/profiler-play-edit-samples.html) — verified-source-text. Official docs extract; older docs host, newer manuals may differ.
- [Official Godot demos exported to Web](https://godotengine.github.io/godot-demo-projects/) — verified-source-text. Official page extract. Browser is not the ship target for most games.
- [Unity Performance Settings sample | Meta Horizon OS Developers](https://developers.meta.com/horizon/documentation/unity/unity-sample-performance-settings/) — verified-source-text. Official page extract (updated 2026-08-11). Quest-only; not a PC or console method.

## accessibility-verification — Accessibility verification with people

### Creator questions

- **who**: Who tested: accessibility experts, players with lived experience, or nobody yet (record the gap)?
- **barriers**: Barrier list per guideline area, with severity and whether each is a design change or an option.
- **options-check**: Each shipped option was used in a real session: remap, timer off, contrast, subtitles, narration. Which failed?
- **tags**: Which store tags are now honestly claimable, and which remain unclaimed?

### inputs

- Accessibility scoping table
- Build
- Playtest protocol

### activities

- Run sessions with the right people
- List barriers
- Verify options in play
- Update tag claims

### tools

- Build
- Playtest log

### skills

- accessibility-audit
- game-quality-planning

### roles

- game-quality-lead
- creator

### outputs

- Accessibility verification report and tag claims

### dependencies

- playtest-protocol

### reviewCriteria

- Testers are named by type or the gap is recorded
- Barriers have severity and route
- Tags match verified options

### revisionRules

- A new element re-opens scoping and verification
- A removed option removes its tag

### Evidence required

Session records with tester type, build, barriers found and options exercised. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.
- [Xbox-GDK-Samples (including AccessibilitySample)](https://github.com/microsoft/Xbox-GDK-Samples) — verified-source-text. README and LICENSE read. Requires the October 2025 GDK; many creators will never compile it. Sample telemetry sends the executable name unless removed. Not a design method.

## evidence-grading — Evidence grading

### Creator questions

- **grades**: Which grade does each claim carry: transcript-only or hearsay, sampled (stills, notes), exact (continuous recording, tool-read counts, logs), and reproduced in our own pipeline?
- **promotion**: Which claims may be promoted to 'demonstrated' (sampled or exact) and which stay 'claimed' until reproduced?
- **tutorial-rules**: For any rule taken from a video or tutorial: its grade, and what our own reproduction showed.

### inputs

- All receipts and playtest entries
- Video or tutorial-derived rules

### activities

- Grade every claim
- Promote only sampled or exact evidence
- Reproduce tutorial rules before relying on them

### tools

- Atlas document editor

### skills

- game-quality-planning
- verification-before-completion

### roles

- game-quality-lead

### outputs

- Evidence grade register

### dependencies

- None specified.

### reviewCriteria

- No claim above its grade
- Tutorial rules are reproduced or marked claimed

### revisionRules

- A new receipt updates the register

### Evidence required

The register; grades cite the underlying files. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [Agent-assisted Unreal tutorial (Stefan 3D AI)](https://www.youtube.com/watch?v=iRcrZjOt5H8) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/video-evidence/agent-runner/REVIEW.md): captions, 12 overview frames and 12 exact frames (0.37 s) showing locomotion while a score advances. Does not establish geometry correction, physics stability, packaging, performance or multiplayer. Prices and capability rankings unverified. No plugin installed or game executed by Atlas.

## defect-triage — Defect triage and unresolved list

### Creator questions

- **classes**: Defect classes: goal failure, unfair failure, readability, contact or deformation, performance, save, licensing, accessibility barrier. Which owner per class?
- **severity**: Severity rule: what blocks a PRD, a wave, a release?
- **unresolved**: The current unresolved list, including defects left by agent-assisted changes (for example collision or spacing an agent claimed to fix).

### inputs

- Receipts
- Playtest entries
- Performance samples

### activities

- Classify defects
- Apply severity
- Keep the unresolved list current

### tools

- Tracker

### skills

- game-quality-planning

### roles

- game-quality-lead
- ops-director

### outputs

- Defect triage rules and unresolved list

### dependencies

- evidence-grading

### reviewCriteria

- Every defect has a class, owner and severity
- Unresolved list is current

### revisionRules

- A resolved defect needs a receipt
- A new class needs an owner

### Evidence required

The list, with each resolution citing its receipt. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Agent-assisted Unreal tutorial (Stefan 3D AI)](https://www.youtube.com/watch?v=iRcrZjOt5H8) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/video-evidence/agent-runner/REVIEW.md): captions, 12 overview frames and 12 exact frames (0.37 s) showing locomotion while a score advances. Does not establish geometry correction, physics stability, packaging, performance or multiplayer. Prices and capability rankings unverified. No plugin installed or game executed by Atlas.
- [The Door Problem](https://web.archive.org/web/20231023231458/https://lizengland.com/blog/2014/04/the-door-problem/) — verified-source-text. Live blog URL returned a stub; Wayback 2023-10-23 and the Kotaku reprint (author-permitted) were used. Essay is an analogy, not a complete spec standard. Large-studio role map does not transfer 1:1 to solo.

## release-readiness — Release readiness review

### Creator questions

- **ladder-status**: Per rung: passed, failed, skipped with reason.
- **goals-held**: Which experience goals are held in the latest stranger playtest?
- **licensing**: Every shipped asset and dependency has a license that allows the target stores and monetization; list exceptions.
- **unverified**: What is unverified at this release (platforms, frame rate on min spec, multiplayer at scale, packaging on a clean machine)?
- **decision**: Ship, hold, or ship with stated caveats? Who decides?

### inputs

- Test ladder results
- Performance samples
- Accessibility report
- Unresolved list
- Licensing tables

### activities

- Assemble results
- Check licenses
- List unverified
- Record the decision

### tools

- Atlas document editor

### skills

- game-quality-planning
- gap-analysis

### roles

- game-quality-lead
- creator
- ops-director

### outputs

- Readiness report with unverified list

### dependencies

- test-ladder
- performance-budgets
- accessibility-verification
- defect-triage

### reviewCriteria

- Every rung has a status
- Unverified is honest
- A named person decided

### revisionRules

- Any new receipt or defect re-opens the review

### Evidence required

Links to the actual rung results, samples and reports; planned items are marked planned. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Gauntlet Automation Framework in Unreal Engine](https://dev.epicgames.com/documentation/en-us/unreal-engine/gauntlet-automation-framework-in-unreal-engine) — verified-source-text. Search extract; URL reconstructed from the page title, re-check before external citation. Console and mobile deploys need device interfaces implemented.
- [Exporting projects (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) — verified-source-text. Full page read by the research seat (Godot 4.7 docs); URL reconstructed from the page title by the catalog author, re-check the version path. ZIP pack auto-discovery bug noted in the docs.
- [Steam Playtest (Steamworks Documentation)](https://partner.steamgames.com/doc/features/playtest) — verified-source-text. Partner docs read; feature not exercised (no partner account used). PC-storefront specific. Leak risk for unannounced games. Wishlist non-interference is Valve's claim, not measured here.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.
