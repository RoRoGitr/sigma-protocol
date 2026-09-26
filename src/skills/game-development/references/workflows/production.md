# Production: scope, asset levels, proofs versus volume, receipts, company functions, risk and distribution

Generated from catalog 1.0.0.

Run the project as a company at any size: appetites against capacity, asset levels that decide gates, proof rows before volume rows, task and receipt discipline, company functions and owners (finance, legal, marketing and GTM, community, support, operations, security, platform), a risk register, and the distribution and store plan.

Applicability: Every game, including a free solo game. Company functions are retained for any game; the solo creator holds them or records the gap. Live operations and monetized distribution phases follow the offer decision. No deadline, team size or timebox is assumed.

Atlas stages: 1, 1.5, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18. Canonical steps: 1, 1.5, 9, 10, 11, 11.5, 12, 13, 14.

## scope-appetites — Scope and appetites against capacity

### Creator questions

- **capacity**: Hours per week per person, for how long, and what else competes for them.
- **appetites**: Per feature row: the time budget and the smallest version that still serves its goal. Which rows are cut if the budget is exceeded?
- **whole-loop**: Can one person (or the current team) play the whole loop end to end with the planned scope? If not, what shrinks?
- **cut-rule**: When a slice does not feel right after its appetite, is it cut or shipped? Who decides?

### inputs

- Creator profile capacity
- Hold list
- Feature rows

### activities

- Compare appetites to capacity
- Shrink until the whole loop is playable by the team
- Set the cut rule

### tools

- Spreadsheet

### skills

- game-development
- sprint-patterns

### roles

- creator
- product-owner
- ops-director

### outputs

- Appetite table with cut rule

### dependencies

- None specified.

### reviewCriteria

- Appetites fit capacity
- The whole loop is playable at planned scope
- The cut rule is stated

### revisionRules

- A capacity change re-opens appetites
- A cut adds to the cut list with its reason

### Evidence required

Table only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [GQ profile - Eric Barone / Stardew Valley solo production](https://www.gq.com/story/stardew-valley-eric-barone-profile) — source-claim. Secondary journalism about one survivor case. Not a generalizable method; base rates for solo projects of that scope are unknown.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.

## asset-leveling — Asset leveling and gate sets

### Creator questions

- **levels**: Per asset family: hero, supporting or background, decided from how often and how closely it is seen or heard.
- **gate-sets**: Which workflow phases each level walks and which it skips, with the reason (a background prop skips deformation validation; a hero walks every phase).
- **low-res-first**: Which assets get a low-resolution master early so layout and levels are not blocked?

### inputs

- Character, environment, audio families
- Feature breakdown

### activities

- Assign levels
- Define gate sets per level
- Schedule low-res masters first

### tools

- Spreadsheet

### skills

- game-development
- game-art-pipeline

### roles

- game-art-director
- game-technical-director
- creator

### outputs

- Asset level table with gate sets

### dependencies

- scope-appetites

### reviewCriteria

- Every family has a level
- Skips have reasons
- Low-res masters unblock layout

### revisionRules

- A level promotion adds gates and re-opens the family's receipts

### Evidence required

Table only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Use of Blender in the Making of the Animated TV Series Deep Dive - Blender Conference 2025](https://www.youtube.com/watch?v=zJIlg3TxHNc) — source-claim. Auto-transcript snippets only; video not watched; speaker name not verified. TV animation, not games.
- [#5 Testing the Asset Pipeline - Project Storm - Blender Studio](https://studio.blender.org/projects/storm/production-log/310/) — verified-source-text. Production log extract (2025-06-23). Open-movie production, not games. Some media behind subscription.

## proof-before-volume — Proof rows before volume rows

### Creator questions

- **proof-rows**: Which rows are proofs (loop, feel, one space, one interactable, one character through the full pipeline)?
- **volume-rows**: Which rows are volume (acts, biomes, character sets, puzzle batches, full score) and which proof gates each?
- **status**: Which proofs have passed with cited evidence, releasing which volume rows?
- **exceptions**: Which volume work starts early anyway because it is cheaper or the creator needs practice, with the reason recorded?

### inputs

- Feature breakdown
- Hold list
- Tuning loop status

### activities

- Tag rows
- Gate volume on proofs
- Record exceptions with reasons

### tools

- Feature breakdown table

### skills

- game-development
- prd-patterns

### roles

- creator
- product-owner

### outputs

- Proof and volume table with release status

### dependencies

- scope-appetites

### reviewCriteria

- Every volume row names its proof
- Releases cite evidence
- Exceptions have reasons

### revisionRules

- A revoked proof re-blocks its volume rows

### Evidence required

Citations to the proof evidence. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.

## task-receipt-discipline — Task and receipt discipline

### Creator questions

- **task-shape**: Every task names the existing asset or scene, the narrow change, the rollback point, the command that produces the receipt, and the evidence to attach.
- **agent-tasks**: For agent-executed tasks: which evidence is mandatory (diff, render, playtest clip, unresolved defects), and who reviews before merge?
- **done-definition**: Done means the receipt exists and was reviewed; which receipt closes which task class?
- **licensing-row**: Every task that adds a dependency adds its license row.

### inputs

- PRDs
- Receipt schema
- Test ladder
- AI-tooling policy

### activities

- Template tasks
- Require evidence per agent change
- Bind receipts to done

### tools

- Tracker
- Task template

### skills

- game-technical-production
- sprint-patterns

### roles

- ops-director
- game-technical-director

### outputs

- Task template and receipt bindings

### dependencies

- proof-before-volume

### reviewCriteria

- No task without a receipt command
- Agent tasks require review
- Dependencies carry licenses

### revisionRules

- A new task class needs a receipt binding

### Evidence required

Template only; receipts themselves live with the tasks. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Agent-assisted Unreal tutorial (Stefan 3D AI)](https://www.youtube.com/watch?v=iRcrZjOt5H8) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/video-evidence/agent-runner/REVIEW.md): captions, 12 overview frames and 12 exact frames (0.37 s) showing locomotion while a score advances. Does not establish geometry correction, physics stability, packaging, performance or multiplayer. Prices and capability rankings unverified. No plugin installed or game executed by Atlas.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.

## company-functions — Company functions and owners

### Creator questions

- **owners**: For finance, legal and rights, marketing and GTM, community and creator relations, support, operations and release, security and data, platform and storefront relations: who or which bot owns it, or 'gap'?
- **rights-review**: Who reviews provenance and licenses for every asset family, music, font and engine add-on before it ships?
- **playtest-ops**: Who runs playtest recruitment, scheduling, consent and data handling?
- **gtm-timing**: Which marketing and community work waits for a playable slice and which starts now?
- **human-agent-split**: Which functions are human-only decisions (spending, publishing, legal commitments) and which may bots prepare?

### inputs

- Company operating map (Atlas 12)
- Role roster (Atlas 13)
- Offer decision

### activities

- Fill the owner table
- Assign rights review and playtest ops
- Split human-only from bot-prepared

### tools

- Atlas company map

### skills

- game-development
- hormozi-frameworks

### roles

- creator
- ops-director
- finance-director
- general-counsel
- cmo
- community-lead

### outputs

- Company function owner table for this game

### dependencies

- None specified.

### reviewCriteria

- Every function has an owner or a recorded gap
- Rights review exists
- Human-only decisions are listed

### revisionRules

- A new sold asset family adds a rights row
- A new platform adds a relations owner

### Evidence required

Table only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Steam Playtest (Steamworks Documentation)](https://partner.steamgames.com/doc/features/playtest) — verified-source-text. Partner docs read; feature not exercised (no partner account used). PC-storefront specific. Leak risk for unannounced games. Wishlist non-interference is Valve's claim, not measured here.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.
- [GQ profile - Eric Barone / Stardew Valley solo production](https://www.gq.com/story/stardew-valley-eric-barone-profile) — source-claim. Secondary journalism about one survivor case. Not a generalizable method; base rates for solo projects of that scope are unknown.

## risk-register — Risk register

### Creator questions

- **risks**: Top risks with likelihood, impact, the experiment or mitigation, and the owner: technical (interchange, performance), rights (unread licenses, generated content), people (capacity, burnout), market (distribution class assumptions).
- **tripwires**: What observation would trigger each mitigation?
- **review-cadence**: When is the register reviewed?

### inputs

- Kill-assumption register
- Licensing gaps
- Unresolved defects
- Capacity

### activities

- List risks with owners
- Set tripwires
- Set the cadence

### tools

- Spreadsheet

### skills

- game-development
- game-quality-planning

### roles

- creator
- ops-director

### outputs

- Risk register

### dependencies

- company-functions

### reviewCriteria

- Every risk has an owner and a tripwire
- Cadence exists

### revisionRules

- A falsified assumption moves from kill register to risk mitigation or closes

### Evidence required

Register only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [GQ profile - Eric Barone / Stardew Valley solo production](https://www.gq.com/story/stardew-valley-eric-barone-profile) — source-claim. Secondary journalism about one survivor case. Not a generalizable method; base rates for solo projects of that scope are unknown.
- [Lyra Starter Game and Game Animation Sample only allows UE 5.4 despite listing 5.6](https://forums.unrealengine.com/t/lyra-starter-game-and-game-animation-sample-only-allows-ue-5-4-despite-listing-support-for-5-6/2546643/1) — source-claim. Single user thread, self-resolved. Not Epic engineering confirmation.
- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.

## distribution-store-plan — Distribution and store plan

### Creator questions

- **channels**: Which storefronts, platforms or venues, with their onboarding costs, review requirements and account owners?
- **playtest-program**: Public playtest program, closed keys, demo, early access, or none yet; what each is for and what leak risk is accepted.
- **timing**: Coming-soon page and wishlist timing tied to a playable slice and held goals.
- **honesty**: Store copy from experience goals; tags from verified options; no unproven system named.

### inputs

- Distribution class
- Offer decision
- Playable slice status
- Accessibility tags

### activities

- Choose channels
- Choose the playtest and demo path
- Tie timing to the slice
- Run the store-page lie test

### tools

- Storefront partner docs

### skills

- game-development
- marketing-copywriting

### roles

- cmo
- creator
- game-quality-lead

### outputs

- Distribution and store plan

### dependencies

- company-functions
- proof-before-volume

### reviewCriteria

- Channels have owners
- Timing is tied to evidence
- Copy passes the lie test

### revisionRules

- A goal change re-opens copy
- A verified option change re-opens tags

### Evidence required

Plan; the lie-test result is a written pass or fail. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Steam Playtest (Steamworks Documentation)](https://partner.steamgames.com/doc/features/playtest) — verified-source-text. Partner docs read; feature not exercised (no partner account used). PC-storefront specific. Leak risk for unannounced games. Wishlist non-interference is Valve's claim, not measured here.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
