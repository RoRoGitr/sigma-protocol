# Discovery: player experience, verb, proof and idea packs

Generated from catalog 1.0.0.

Lock what the game must make a player feel, the verb and decision that cause it, the assumptions that could kill it, and the cheapest first experiment. Holds the reserved creator profile and independent idea-pack documents.

Applicability: Every game. The profile is answered once per project and revised when facts change. One idea pack per contributor; a solo creator writes one pack (or several alternatives) and may synthesize them alone. No engine, genre, platform, multiplayer or monetization answer is assumed; unknown answers stay unknown with a revisit condition.

Atlas stages: 0, 1, 5. Canonical steps: 0, 1, 5.

## profile — Creator profile

### Creator questions

- **creator-mode**: Are you working solo for now, or with contributors who will write their own idea packs? This can change later.
- **known-constraints**: Which facts are already fixed by the product or the people (existing engine, existing IP, existing assets, a platform you must ship on, a team you already have)? Write 'none' where nothing is fixed.
- **unknowns**: Which of these are genuinely undecided right now: engine, art mode, genre, platform, multiplayer, monetization, deadline? Undecided is a valid answer and keeps the related work unresolved rather than skipped.
- **art-modes-open**: Which art modes are you open to (3D, 2D sprite, vector, text, audio-first, abstract, mixed)? Do not pick yet unless the product already did.
- **capacity**: How many hours per week can you and any contributors realistically spend, and which skills do you hold yourself (design, code, art, audio, writing, production)?
- **evidence-habit**: How will you record playtests and experiments so results can be cited later (notes template, recordings, photos)?

### inputs

- Project setup answers (Atlas 0)
- Whatever the creator already knows about the game, including nothing

### activities

- Answer once, revise when facts change
- Convert 'fixed' facts into architecture inputs and 'undecided' facts into open questions with revisit conditions
- Record capacity so later appetites are honest

### tools

- Atlas document editor

### skills

- game-discovery

### roles

- creator

### outputs

- Creator profile document (setup preference, not the game specification)

### dependencies

- None specified.

### reviewCriteria

- Fixed versus undecided is explicit for engine, art mode, genre, platform, multiplayer, monetization and deadline
- No undecided item was turned into a default

### revisionRules

- Changing a fixed fact (for example the engine is now locked) re-opens technical.engine-platform-decision and any phase that cited the old answer
- Switching creator mode never deletes idea packs; it only changes whether synthesis needs selected contributors

### Evidence required

None beyond the answers. This document is a setup preference. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Sigma Protocol game-development adaptation (architecture decision and integration contract)](../SIGMA-GAME-ADAPTATION.md) — proposed-adaptation. Our proposal, not an external practitioner method. Nothing here proves a game is good. Every phase's evidence must come from an authorized external experiment and a human review, never from the existence of a document.

## idea-pack — Independent idea pack

### Creator questions

- **pack-summary**: In one paragraph, what is the game and what should a player feel in one session?
- **experience-goals**: Describe the player experiences this concept should create and how a playtest could challenge them.
- **aesthetic-mix**: Which MDA aesthetics, if useful, describe this concept, and how are they prioritized?
- **core-verb**: What does the player do, over and over, and what decision surrounds it?
- **primary-proof**: What must be proved first: a decision, a feel, a story beat, a social space, a space to explore, something else?
- **cheapest-experiment**: What is the cheapest experiment that could show the primary proof fails (cards, spoken rules, spreadsheet, greybox, beat board, chat room)?
- **risks**: Which assumptions would kill this idea if false?
- **references**: Which existing games, works or references shaped this, and what specifically was borrowed or rejected?
- **dissent-note**: Anything you expect other contributors to disagree with, and why you hold your position?

### inputs

- Creator profile
- Any references the contributor personally chose

### activities

- Write the pack without reading other contributors' packs
- Keep the pack to what one person actually believes; do not union features from other games
- Name the contributor in the document's contributor field (required for approval)

### tools

- Atlas document editor

### skills

- game-discovery
- brainstorming

### roles

- creator
- game-design-lead

### outputs

- One idea-pack document per contributor, workspace-visible and independently authored

### dependencies

- profile

### reviewCriteria

- Goals are situations, not features
- The primary proof matches the goals
- A contributor is named
- The pack was not edited to match another pack before synthesis

### revisionRules

- Editing a pack after a synthesis selected it invalidates that synthesis review through artifact revision propagation
- A contributor may add a second pack as an alternative instead of overwriting the first

### Evidence required

None required for a draft. Approval requires a non-empty contributor and every required answer. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [MDA: A Formal Approach to Game Design and Game Research](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) — verified-source-text. Full 5-page PDF read by the Grok design seat. 2004 workshop paper; later critiques not surveyed. Not a formula for fun and says so. Says nothing about production scheduling.
- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.
- [The Art of Game Design: A Book of Lenses (studio hub)](https://schellgames.com/art-of-game-design/) — source-claim. Official studio page fetched; book text not read cover to cover. Deck and app are untested tools. Using all lenses as a checklist is a misuse the method itself warns against.
- [Sigma Protocol game-development adaptation (architecture decision and integration contract)](../SIGMA-GAME-ADAPTATION.md) — proposed-adaptation. Our proposal, not an external practitioner method. Nothing here proves a game is good. Every phase's evidence must come from an authorized external experiment and a human review, never from the existence of a document.

## experience-goals — Experience-goal sheet

### Creator questions

- **goals**: Write the selected experience goals as situations, each with observable behavior that would show whether it held or failed.
- **primary-method**: Which evaluation method is primary for this game: interesting decisions, pattern mastery, game feel, verbs and scenes, or presence? Which stay as diagnostic lenses?
- **who-changes-goals**: Who is allowed to change a goal after the first playtest, and how is the change recorded?
- **session-shape**: Session length, setting, interruption tolerance and device class, in plain language.

### inputs

- Selected idea pack or synthesis record
- Creator profile

### activities

- Merge from the selected pack or synthesis; do not average dissent into mush
- Attach the observable behaviour per goal
- Name the primary method and the owner of goal changes

### tools

- Atlas document editor

### skills

- game-discovery

### roles

- creator
- game-design-lead

### outputs

- Experience-goal sheet (living one-pager) feeding MASTER_PRD

### dependencies

- idea-pack

### reviewCriteria

- A reader who has not seen a feature list can describe the intended session
- Each goal has a failing behaviour
- One primary method is named

### revisionRules

- A failed playtest changes the prototype; a goal changes only by a recorded owner decision with a reason
- Changing a goal re-opens primary-proof, kill-assumptions and every prototype that cited it

### Evidence required

None required beyond the sheet. Later phases cite this sheet; it is not itself proof. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [MDA: A Formal Approach to Game Design and Game Research](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) — verified-source-text. Full 5-page PDF read by the Grok design seat. 2004 workshop paper; later critiques not surveyed. Not a formula for fun and says so. Says nothing about production scheduling.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [A Theory of Fun for Game Design - author page and 2003 slides](https://www.raphkoster.com/gaming/theoryoffun.shtml) — verified-source-text. Author page and hosted 2003 slides read; the book was not read cover to cover. Weak on fellowship, atmosphere and submission aesthetics. Games-are-not-stories claim is incomplete for presence-driven games.
- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.
- [The Art of Game Design: A Book of Lenses (studio hub)](https://schellgames.com/art-of-game-design/) — source-claim. Official studio page fetched; book text not read cover to cover. Deck and app are untested tools. Using all lenses as a checklist is a misuse the method itself warns against.

## primary-proof — Primary proof and prototype track

### Creator questions

- **proof-type**: Decision track (cards, spoken rules, spreadsheet, tabletop), feel track (greybox with realistic input latency), story track (beat boards, read-through), social track (chat room, tabletop with strangers), space track (blockout walk), or another? Pick one primary.
- **pass-signal**: What tester behaviour means pass (players hesitate productively and can explain the tradeoff; testers control the object untutored and describe a body metaphor; a stranger finds the exit; a reader wants the next beat)?
- **sequence**: If a second track is needed, which comes second and why not now?
- **not-needed**: Which prototype forms are explicitly unnecessary for this game (for example no 3D greybox for a text game, no paper prototype for a pure-feel game), and why?

### inputs

- Experience-goal sheet
- Prototype media from Step 0

### activities

- Choose one primary track from the uncertainty, not from habit
- Write the pass signal as a behaviour
- Record which forms are unnecessary so no one builds them

### tools

- Cards, paper, spreadsheet, text editor, greybox scene, sprite editor, chat room, tabletop - whichever the track needs

### skills

- game-discovery
- game-systems-design

### roles

- creator
- game-design-lead

### outputs

- Primary-proof decision with pass signal and rejected forms

### dependencies

- experience-goals

### reviewCriteria

- The track matches the uncertainty (no feel track for a turn-based card game)
- The pass signal is observable
- Unnecessary forms are named, not silently skipped

### revisionRules

- A new primary uncertainty adds a proof decision; it does not overwrite the record of the old one

### Evidence required

None required before the experiment. After the experiment, the playtest log entry and its evidence grade are attached in first-playtest. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.

## kill-assumptions — Kill-assumption register

### Creator questions

- **assumptions**: List every assumption that would kill the game if false: input latency tolerance, reading load, session length, hardware class, a multiplayer requirement, a licensing dependency, the creator's own available hours.
- **test-per-assumption**: For each assumption, the cheapest bounded experiment that could falsify it, and its cost in hours.
- **order**: Which assumption is tested first and why (highest kill probability times lowest cost)?

### inputs

- Experience-goal sheet
- Creator profile unknowns

### activities

- Write each assumption as a falsifiable statement
- Attach a bounded experiment and cost to each
- Order by kill probability over cost; the first experiment becomes first-playtest or a technical experiment

### tools

- Atlas document editor

### skills

- game-discovery
- game-quality-planning

### roles

- creator
- game-design-lead
- game-technical-director

### outputs

- Kill-assumption register feeding MASTER_PRD and the quality workflow

### dependencies

- experience-goals

### reviewCriteria

- Every assumption is falsifiable
- Every assumption has a bounded experiment
- Nothing in the register is a feature wish

### revisionRules

- A falsified assumption re-opens experience-goals or architecture, whichever it kills, by recorded decision
- A new dependency (engine add-on, licensed music) adds an assumption

### Evidence required

Register only. Each experiment's outcome is recorded where it ran (first-playtest, technical.interchange-contract, quality.playtest-protocol) with its evidence grade. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [Lyra Starter Game and Game Animation Sample only allows UE 5.4 despite listing 5.6](https://forums.unrealengine.com/t/lyra-starter-game-and-game-animation-sample-only-allows-ue-5-4-despite-listing-support-for-5-6/2546643/1) — source-claim. Single user thread, self-resolved. Not Epic engineering confirmation.

## first-playtest — First evidence-focused playtest

### Creator questions

- **who-played**: Who will play, or has played, how many, and who facilitates? Explain why these participants fit the uncertainty and what familiarity, recruitment or accessibility biases limit the evidence.
- **build-or-medium**: Exactly what was played (deck version, rules text, greybox build id, beat board revision)?
- **goals-held**: For each experience goal: held, failed, or not observable in this medium, with the behaviour seen.
- **facilitator-speech**: Which facilitation method fits this test (silent observation, think-aloud, co-play or interview), and why? Record any actual intervention and whether it reveals a game issue, a test-design issue or an unresolved interpretation.
- **evidence-grade**: What evidence exists: notes only, photos, sampled recording, full recording? Where is it stored?
- **next-change**: What changes in the prototype next, and which goal does the change serve?

### inputs

- Primary-proof decision
- Kill-assumption register
- Capture path from Step 0

### activities

- Prepare a test with a named uncertainty, participant rationale and facilitation method; external execution is a separate authorized activity
- Log who, what, which goals held, and the evidence grade
- Change the prototype, not the goal, unless the owner records a goal change

### tools

- Playtest log
- Recording or notes per Step 0 capture path

### skills

- game-discovery
- game-quality-planning

### roles

- creator
- game-design-lead
- game-quality-lead

### outputs

- Playtest plan, or an actual session log with evidence grade and next change

### dependencies

- primary-proof
- kill-assumptions

### reviewCriteria

- The playtest type is named (friends, strangers, platform, accessibility)
- Goals are scored by behaviour, not by designer feeling
- Evidence grade and storage location are recorded

### revisionRules

- Each new session appends an entry; earlier entries are never rewritten
- A failed goal re-opens the prototype PRD; revise the goal itself only through a recorded creator decision with rationale

### Evidence required

An actual session must have happened: the log entry names players, medium, per-goal behaviour and the stored recording or notes. A planned session is recorded as planned, never as a result. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [I Built a Whole Game Level Using Only FREE AI (environment tutorial)](https://www.youtube.com/watch?v=6Ytluv_DiSo) — observed-footage. Reviewed 2026-09-22 (docs/research/game-development/CLAUDE-ENVIRONMENT-VIDEO-REVIEW.md): full transcript, 12 overview frames, 14 probes, and 12 exact consecutive frames covering 0.44 s. Only the knife cut (922 to 448 vertices on one rock) and scene counts (about 534k triangles, 399 objects) are frame-verified; bake outputs, decimate ratios, time claims and the free-only framing are transcript-only. Creator beauty shot, no gameplay, collision, LOD or performance evidence.

## production-hold-list — Production hold list

### Creator questions

- **held-work**: Which work does the creator choose to hold until a named proof passes (content volume, hero art, full score, store page, live-ops design)? Each item needs the proof that releases it.
- **released-work**: Which work may start now regardless (direction studies, tool pins, reference packs, accessibility scoping)?
- **hold-reasons**: For each held item, why is waiting cheaper than starting now? If starting now is cheaper (for example a solo artist who must practice), say so and release it.

### inputs

- Experience-goal sheet
- First playtest results
- Kill-assumption register

### activities

- Write the hold list as creator choices with release conditions, not as a blanket freeze
- Release anything whose early start is genuinely cheaper
- Feed held items to feature breakdown as volume rows gated on proofs

### tools

- Atlas document editor

### skills

- game-discovery
- game-development

### roles

- creator
- game-design-lead
- product-owner

### outputs

- Hold list with release conditions feeding MASTER_PRD and Step 10

### dependencies

- first-playtest

### reviewCriteria

- Every held item has a release proof
- No item is held by rule alone; each has a reason
- Released early work is listed too

### revisionRules

- A passed proof releases its items in the same revision
- Adding a held item requires a reason and a release proof

### Evidence required

None. The list is a plan; the release proofs are the evidence, recorded where those proofs ran. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [GQ profile - Eric Barone / Stardew Valley solo production](https://www.gq.com/story/stardew-valley-eric-barone-profile) — source-claim. Secondary journalism about one survivor case. Not a generalizable method; base rates for solo projects of that scope are unknown.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.

## discovery-synthesis-handoff — Handoff into MASTER_PRD

### Creator questions

- **prd-section**: Which discovery answers go into MASTER_PRD's game section (goals, aesthetic mix, verb, decision, primary proof, kill-assumptions, hold list) and which stay as working notes?
- **open-items**: Which items remain undecided (engine, art mode, platform, multiplayer, monetization) with a revisit condition each?
- **company-links**: Which company functions (finance, legal, marketing, community, operations) already have a decision or an owner from this discovery, and which are gaps?

### inputs

- All discovery documents
- Synthesis record when more than one pack exists

### activities

- Write the MASTER_PRD game section from approved documents only
- List undecided items with revisit conditions
- Hand company-function links to Atlas 12

### tools

- Step 1 command
- Atlas document editor

### skills

- game-discovery
- prd-patterns

### roles

- creator
- game-design-lead
- product-owner

### outputs

- MASTER_PRD.md game section
- Open-items list with revisit conditions

### dependencies

- experience-goals
- primary-proof
- kill-assumptions
- production-hold-list

### reviewCriteria

- Every PRD statement traces to an approved document
- Undecided items are listed, not defaulted
- Company function gaps are named

### revisionRules

- Any upstream discovery revision invalidates this handoff until re-reviewed

### Evidence required

None beyond traceability to approved documents. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design: Theory & Practice (2nd edition) - author site](http://paranoidproductions.com/gamedesign/) — source-claim. Author site only; book not read. 2004 platform and live-ops chapters are historical. Risk of document-first culture if used before a prototype exists.
- [Sigma Protocol game-development adaptation (architecture decision and integration contract)](../SIGMA-GAME-ADAPTATION.md) — proposed-adaptation. Our proposal, not an external practitioner method. Nothing here proves a game is good. Every phase's evidence must come from an authorized external experiment and a human review, never from the existence of a document.
