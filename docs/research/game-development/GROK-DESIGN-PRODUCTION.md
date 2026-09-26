# Game design and production — Grok research synthesis

**Document:** `docs/research/game-development/GROK-DESIGN-PRODUCTION.md`  
**Companion:** `GROK-DESIGN-PRODUCTION-SOURCES.json`  
**Access date:** 2026-09-22  
**Scope:** reusable methodology for any game. No engine, team-size, room-count, player-count, deadline, or product-identity defaults.  
**Evidence classes used throughout:** demonstrated evidence (page/PDF/repo inspected this session), source claim (author’s published method, book not fully read), untested tool (platform feature or kit not exercised here), proposed adaptation (Sigma mapping, not yet implemented).

This file is original synthesis. Source passages are not reproduced. Source IDs `S01`–`S18` match the companion JSON.

---

## 1. What this research is for

Sigma Protocol already owns a numbered, HITL-gated planning spine (Steps 0–15 plus conditional 1.5 and 11.5). Game development does not need a parallel numbering system. It needs **domain overlays**: player-experience goals, playable prototypes, loop/feel proofs, space and verb inventories, accessibility as design rather than certification, and a production freeze that waits until those proofs exist.

The practitioners named in the brief do not form a ranking. They form **context-dependent methods**. A paper-prototype-first process (Fullerton, `S02`) and a systems-emergence process (Harvey Smith, `S08`) both work. They fail when applied to the wrong kind of game, or when applied too late.

The binding production rule that survives every conflict in this corpus:

**Lock intended player experience before features. Prove the core verb and the interesting decision in a cheap prototype. Treat every object as a door problem. Freeze art, narrative volume, and live-ops architecture until the loop holds under playtest.**

That rule is proposed adaptation. It is assembled from demonstrated methods, not from a single authority.

---

## 2. Method of this report

Live web search, page fetches, one full PDF inspection (`S01`), GitHub README/LICENSE/maintenance inspection (`S18`), Steamworks and Xbox official docs (`S15`–`S17`), and X semantic search used only as discovery. X posts were not treated as methods. Claims from X were traced back to Fullerton experience goals (`S02`) and Schell lenses (`S03`).

Videos are listed for parent exact-frame review. This seat inspected auto-generated transcript snippets and talk descriptions where search returned them. That is **not** a watched-video claim.

Books that could not be read cover-to-cover (`S03`, `S06`, `S12`, `S13`, Hodent’s full text in `S14`) are marked **source claim**. Publisher pages, tables of contents, author excerpts, and author sites were checked.

GitHub popularity was ignored. `S18` was kept because it has an MIT license, a current GDK version pin (October 2025), a dedicated Accessibility sample, and Microsoft ATG authorship. The Level Design Book (`S11`) is GitBook-hosted, CC BY-NC-SA 4.0, volunteer-maintained, and self-labeled “heavily under construction” with updates in January 2025 and November 2025.

---

## 3. Synthesis: games as unpredictable artifacts

Hunicke, LeBlanc, and Zubek (`S01`, AAAI 2004; PDF inspected) formalize a fact every later method in this set still depends on: a game is consumed unpredictably. Designers build **mechanics** (rules, data, algorithms). Play produces **dynamics** (runtime behavior). Players feel **aesthetics** (emotional responses). Designers work mechanics → dynamics → aesthetics. Players encounter the chain in reverse.

The paper’s aesthetic vocabulary (Sensation, Fantasy, Narrative, Challenge, Fellowship, Discovery, Expression, Submission) is a compass, not a formula. The authors say there is no grand unified mix that yields “fun.” Tuning is moving between the three layers and watching cascade effects. Their babysitter-game example shows that changing the intended aesthetic (discovery for young children versus challenge and fantasy for older players) rewrites dynamics and then mechanics, including whether AI can stay scripted.

**Proposed adaptation:** Step 1 of Sigma currently discovers problem, user, and outcome. For a game, the equivalent lock is **player experience goals plus two to five aesthetic targets**, written as felt situations, not feature lists. Features are later hypotheses about how to cause those situations.

Conflicting alternative: Meier (`S04`) treats games as series of interesting decisions. Koster (`S05`) treats fun as the brain’s reward for learning a pattern. Swink (`S06`) treats a subset of games as real-time virtual sensation. Anthropy and Clark (`S12`) treat games as verbs acting on objects in scenes. These are compatible if each is scoped:

| Method | Strong when | Weak when |
|---|---|---|
| MDA aesthetics first (`S01`) | Mixed-discipline teams need a shared vocabulary | Treated as a taxonomy to fill rather than a tuning loop |
| Interesting decisions (`S04`) | Strategy, RPG, management, any tradeoff-heavy play | Rhythm, pure twitch, some puzzle games (Meier says so himself) |
| Learning / pattern mastery (`S05`) | Skill games, combat encounters as puzzles, long-tail mastery | Games whose value is atmosphere, fellowship, or submission-as-pastime |
| Game feel (`S06`) | Real-time control of a virtual body or object | Turn-based, purely narrative, or menu-driven games without spatial simulation |
| Verbs and objects (`S12`) | Small authored games, teaching design, scene-level craft | Large live-service economies where “verb” is too small a unit |
| Lenses (`S03`) | Diagnosis when a prototype feels wrong | Used as a 100-item checklist instead of a few pointed questions |

The Protocol overlay should pick **one primary evaluation method per prototype**, named in the experience-goal document, and keep the others as diagnostic lenses.

---

## 4. Discipline findings

### 4.1 Ideation, player experience, pillars, feasibility

**Practitioners and methods**

Tracy Fullerton (`S02`, *Game Design Workshop* 5th ed., excerpt dated 2024-04-18; book pub. 2024-04-19, CRC/Routledge). Playcentric design: set **player experience goals** (felt situations, not features), paper-prototype the core immediately, playtest with target players, iterate against those goals before production. Iteration loop: goals → idea → prototype → playtest → evaluate against goals → prioritize changes → retest.

Jesse Schell (`S03`, *The Art of Game Design: A Book of Lenses*, 1st ed. 2008, 3rd ed. 2019; studio page live 2026). More than 100 question-sets drawn from psychology, architecture, theme parks, music, and film. A lens is a diagnostic checklist, not a production pipeline. The Deck of Lenses and companion app exist as **untested tools** in this research.

Richard Rouse III (`S13`, *Game Design: Theory & Practice*, 2nd ed. 2004). Process from brainstorming through focus, documentation, implementation, and playtesting, with a complete sample design document (*The Suffering*) in the second edition. Useful for **what a design document contains**. Dangerous if the document is treated as a novel that must be finished before anyone plays.

Anna Anthropy and Naomi Clark (`S12`, 2014). Shared language: verbs, objects, scenes, resistance, context. Liberates designers from genre cliché by talking about what the player *does*. Liz England’s 2015 review (`S07` adjacent) treats it as a short practical text, not a replacement dictionary.

**Feasibility that belongs in ideation, not architecture**

Fullerton’s physical prototype *is* the feasibility test for gameplay. A stack-profile or engine choice is a later feasibility test for shipping. Mixing them early produces engine tourism.

A pillar set of four or five “ingredients” is common industry talk (X discovery posts from working designers). Fullerton’s version is stricter: pillars are **experience goals that can fail a playtest**. “Immersion” as a pillar is not testable. “Players never trust each other even though they must cooperate to win” is testable.

**Proposed Step 1 overlay**

1. Name the player and the session (who plays, how long, on what kind of device — without locking an engine).
2. Write 3–7 experience goals as felt situations.
3. Pick 2–4 MDA aesthetics as the intended mix (`S01`).
4. Name the core verb (`S12`) and the interesting decision (`S04`).
5. Paper or tabletop prototype within the same working session.
6. Run one playtest against the goals before any digital production plan.
7. Record assumptions that would kill the game if false (input latency, reading load, session length, multiplayer requirement).

**Acceptance evidence for ideation**

- Experience goals exist as situations, not features.
- At least one outsider has played a prototype and the designer can say which goals held.
- A one-page “what we will not build until the loop is proven” freeze list exists.

### 4.2 Core loops, mechanics, game feel

**Loops.** A core loop is the smallest repeating verb cycle that produces an aesthetic. MDA says dynamics emerge from mechanics over time (`S01`). Koster says the loop dies when the pattern is mastered (`S05`, 2003 Austin Game Conference slides hosted by the author; 2004 book). Long-lived games refresh the puzzle: competition, permutation, player-authored content, or new layers of the same verb.

Meier (`S04`, GDC 2012; GDC YouTube 2018-09-27) gives operational tests for a loop’s decisions:

- If every player always picks option A, the computer should pick A.
- If the pick is random, the decision is not interesting.
- Interesting decisions have tradeoffs, are situational, persist, and match play style.
- Players need enough information to choose without paranoia.
- The game must acknowledge the choice (sound, text, visual). Silence after a decision is a failure.
- Cut decisions that stay uninteresting after tuning. Firaxis cut about a third of tried systems.

**Feel.** Steve Swink (`S06`, *Game Feel*, Morgan Kaufmann / CRC, 2008; TOC via Library of Congress). Game feel is real-time control of a virtual object with a consistent spatial simulation, plus polish (sound, juice, metaphor). Six components commonly cited from the book: real-time control, spatial simulation, polish, effect of the mechanic, metaphor, and rules. Without real-time control, Swink’s object of study is absent. Applying “juice” to a spreadsheet game is a category error.

**Revision rule for loops**

Prove the loop in the cheapest medium that can carry the decision or the feel. Card prototype for tradeoffs. Greybox + placeholder avatar for feel. Do not start content production (levels, economy, narrative acts) while the loop still requires a designer to explain why it is fun.

**Conflicting alternative:** production-first (build the world, hope the loop appears). Smith (`S08`) shows the opposite failure mode: special-case levels that cannot generate second-order consequences. Both failures are premature production.

### 4.3 Narrative, worldbuilding, progression, system design

**Authored story versus possibility space**

Harvey Smith (`S08`, GDCE 2002 interview, 2002-09-11): systemic level design uses **class-to-class** rules (any exploding enemy + any destructible container) rather than one-off triggers. Emergence is a second-order consequence the team did not script, that still feels rational. Goal completion is rewarded; methodology is not. Special-case moments still exist (“get to the exit”). The method is a mix, chosen per situation.

Harvey Smith and Randy Smith (`S09`, GDC 2004 “Would the Real Emergent Gameplay Please Stand Up?”; GDC Vault; unofficial YouTube reconstruction 2017-10-20). Practical claim: emergence increases when mechanics are **connected**. Isolated mechanics do not produce improvisation. Transcript snippets describe “listen to general stimuli” (fire, explosion) rather than hard-coded object pairs. Parent should frame-review the Vault copy.

Anthropy (`S12`) still wants scenes with development, conflict, climax. That is compatible with systems if scenes are **pressure on verbs**, not cutscene volume.

Rouse (`S13`) documents storytelling mode as an early decision and includes interviews with Sid Meier, Will Wright, Jordan Mechner, Doug Church. The book’s strength is process coverage; its 2004 vintage means platform and live-ops chapters are historical.

Koster (`S05`) is blunt: games are not stories. Fiction is dressing on a learning machine. That is a useful stress test for narrative-heavy pitches. It is incomplete for walking simulators, visual novels, and many immersive sims whose aesthetic *is* presence (`S08` later interviews).

**Progression**

Progression is either a learning curve (Koster), a decision tree that stays interesting (Meier), or an economy. Mixing all three without naming which one the player is supposed to feel produces treadmill. Fullerton would ask whether the experience goal is mastery, expression, or fellowship, then test.

**Proposed overlay for Steps 2 and 10**

- Architecture names the **interaction model**: authored beats, systemic possibility space, or hybrid, with examples of class-to-class rules.
- Feature breakdown treats **systems** (stealth, dialogue, crafting, traversal) as features, and **content packs** (acts, biomes, character sets) as later features gated on system proofs.
- Narrative bibles are allowed as world constraints. They do not authorize cinematic production.

### 4.4 Levels, puzzles, player journeys

**Correction to the brief’s lead.** “Steve Lee / The Level Design Book” is two sources.

- **Steve Lee** (`S10`): Arkane / Dishonored 2 level designer. GDC 2017 “An Approach to Holistic Level Design” (GDC YouTube 2017-07-18). Holistic means gameplay, presentation, and story are designed as one object. Informed by immersive-sim values. He cites architecture-school thinking. Applicable to 3D action-adventure and immersive sims; he flags that the talk is genre-informed.
- **The Level Design Book** (`S11`): founded by **Robert Yang**, with Andrew Yoder and other contributors. Free, CC BY-NC-SA 4.0, never paywalled. Self-described as usually about FPS/TPS action spaces, still useful for other genres. **Heavily under construction.** Process page inspected.

`S11` process (tailor; do not treat as universal):

1. Pre-production (experience goals, pillars, constraints). Group work needs more of this; solo hobbyists can travel lighter.
2. Combat design (optional) — define a fight before mapping fights.
3. Layout (2D plan as communication).
4. Blockout (playable rough 3D, playtest size/flow/balance).
5. Scripting (events, doors, AI). Door scripting is called out as one of the hardest problems.
6. Lighting (gameplay function: readable space, cover, depth).
7. Environment art (multiple art passes; premature art pass locks mistakes).
8. Release (documentation and audience; portfolio work that is not documented does not exist).

The book’s own conflict: combat/multiplayer maps need long blockout; story-heavy single-player maps suffer if blockout is treated as the whole job, because story changes force rework of scripting and art.

Liz England (`S07`, “The Door Problem,” 2014-04-21; Kotaku reprint 2016-05-03; Wayback snapshot used because the live blog fetch returned a stub). A designer’s job is answering the full question set around an apparently trivial object: which doors open, how the player knows, locks, multiplayer gating, enemy pathing, unloading, audio, QA. The second half of the essay maps **roles** (creative director, producer, designer, artist, audio, QA) onto the same object. That is a documentation method: every interactive object gets a door-problem sheet before implementation.

**Player journeys in Sigma terms**

Step 4’s screen inventory is necessary and insufficient. Games also need a **space inventory** (rooms, routes, fail-forward paths) and a **verb inventory** (what the player can do here). Puzzle games may be almost all verbs and almost no 3D space. Open-world games invert that. The flow tree should prove coverage of: first session, fail state, recovery, optional content, and the ending — plus every unique verb introduced.

**Revision rule:** no art pass on a space whose blockout has not been playtested for wayfinding and intended pacing.

### 4.5 Art direction and readable UI

Celia Hodent (`S14`, GDC 2015 “The Gamer’s Brain,” GDC YouTube 2017-08-13; *The Gamer’s Brain* 2017, 2nd ed. announced 2026). UX is making the player experience the intended design. Cognitive load, perception, attention, memory, and form-follows-function (visuals teach interaction) are the operational tools. She argues hypothesis testing with real people, not intuition theater. A 2nd edition (CRC, eBook listed 2026-03-05) exists as a source-claim update; this seat did not read the new edition.

Readable UI is therefore not a visual-identity problem first. It is a **perception problem**: contrast, focus, silhouette, consistent mapping, and not using color as the only channel (`S15` XAG 101–104, 109, 112–114; `S17` Steam feature tags).

Art direction that arrives before the verb is proven becomes a production trap (`S11` env-art warning). Direction *studies* (palette, silhouette language, reference board) can exist in Step 3/6 as constraints. Final asset production waits.

Randy Smith’s 2026 comments (secondary journalism, not a numbered source) argue immersive sims do not require AAA vista budgets if communication and vibe are clear. Treat as a **source claim via interview**, useful as a cost-control argument, not as a quality ceiling.

**Proposed overlay:** Step 6 tokens include gameplay-readability tokens (interactable vs decorative, danger, path, focus) in addition to brand color. Step 7 states include “cannot parse the space” and “cannot parse the UI” as first-class failures.

### 4.6 Audio

Brian Schmidt (GDC speaker bio, GameSoundCon founder, Xbox audio architecture, G.A.N.G. Lifetime Achievement 2008). Method: interactive mixing and tools (historical XACT), treating game audio as a real-time system with technical constraints, not a linear soundtrack drop.

Guy Whitmore (GDC 2014 slides on archive.org; adaptive music at Monolith: *Shogo*, *NOLF*). Method: state-based music, phrase graphs, RTPC-driven arrangement, mixing in the box as the game is played. The 2014 PDF is **demonstrated as a slide deck**; the live talk was not frame-reviewed here.

Hodent (`S14`) and XAG 105 (`S15`) plus Steam custom volume controls (`S17`) agree on a production rule: **separate buses** (music, critical SFX, ambient, VO, narration, chat) because players must hear different things. Swink (`S06`) treats sound as polish that completes feel.

**Revision rule:** audio implementation for the core verb (footstep, confirm, fail, hit) belongs in the feel prototype. Adaptive music graphs belong after the loop’s emotional arc is known. Do not commission a full score against an unproven structure.

**Limitation:** this seat did not inspect a maintained audio middleware sample repo at the same depth as `S18`. FMOD/Wwise are **untested tools** here, not recommendations.

### 4.7 Playtesting and accessibility

**Playtesting methods in conflict**

| Method | Who | What it measures | Risk |
|---|---|---|---|
| Designer-and-friends paper playtest | Fullerton `S02` | Are experience goals even present? | Friends perform enthusiasm |
| Structured usability with recruited players | Bill Fulton, Microsoft User-Testing Group, same 2002 interview as `S08` | Can the intended audience do the task? Halo case | Needs research hygiene; designers watching their own testers bias the room |
| Steam Playtest | Valve `S16` | Live-customer behavior at scale, gated, free | Not confidential; not a substitute for lab; not monetizable |
| Steam keys / release-override | `S16` | Closed groups, unannounced builds | Key limits; leak risk; NDA is the developer’s problem |
| Accessibility expert + disabled players vs XAG | Microsoft MGATS (official testing service description) | Barrier list against `S15` | Optional paid/partner service; **untested** in this research |

Fulton (2002): usability is getting the right people, at the right time, with methods that reduce demand characteristics. Designers are the wrong primary observers of their own tests. Donald Norman’s *Design of Everyday Things* is his recommended seed text — and England’s door essay is the game-shaped version of the same idea.

Fullerton still wants early, cheap, frequent tests. The synthesis: **friends for existence proofs, strangers for truth, platform playtests for scale, accessibility testers for barriers.** Each answers a different question. Collapsing them into “we playtested” is the defect.

**Accessibility as design**

Xbox Accessibility Guidelines v3.2 (`S15`, published 2023-06-08; Learn page `ms.date` 2026-08-14, `updated_at` 2026-08-18). Developed with industry experts and the Gaming & Disability Community. Explicitly **not** a legal compliance checklist. Each XAG has goal, overview, scoping questions, implementation guidelines, examples, player-impact table, resources.

Scoping questions are the Protocol-shaped part: they force a yes/no about whether the title even contains the element (timers, chat, motion, haptics). Implementation then follows only for present elements.

Steam Accessibility Features (`S17`) are **store-facing tags** produced by a wizard. They help players find games. They are not a design method. Mis-tagging (claiming “playable without vision” when only menus are narrated) is a documented failure mode in the same page.

Xbox-GDK-Samples (`S18`): MIT license, Microsoft ATG, requires October 2025 GDK, AccessibilitySample demonstrates cross-platform accessibility features. This is a **maintained official sample**, not a popularity contest. Limitation: GDK/console-oriented; many creators will never compile it. The value is the existence of a reference implementation, not a mandate to use GDK.

**Revision rule:** accessibility scoping (`S15`) runs at the same time as experience goals, because input, timing, and reading load are the experience. Bolting XAG 107 (input) and 116 (time limits) on after combat is tuned will rewrite combat.

### 4.8 Solo production, and optional independent team ideation with explicit synthesis

**Solo**

Eric Barone / ConcernedApe (GQ profile 2018-03-20; Game Developer IGF interview 2017-02-24; later PC Gamer interviews). Demonstrated case of one person performing design, code, art, music, and writing over years, iterating slices to ~80% then deepening, repeatedly redrawing art, and **cutting months of work** when a slice did not feel right. He describes the process as intuitive and scrappy, later calling himself an amateur even after success.

This is **demonstrated evidence of a possible path**, not a method to copy. It does not generalize to team games, live-ops, or licensed IP. It does support two Protocol-safe rules: keep the vision small enough that one person can play the whole loop; prefer cutting a bad slice over shipping it.

Anthropy’s broader zinester stance (`S12` and *Rise of the Videogame Zinesters*, not fully read) argues for small, personal, accessible creation tools. That is a different solo path: days or weeks, not years.

Fullerton’s paper prototype is the solo superpower: no art pipeline required to learn if the game exists.

**Optional independent team ideation → explicit synthesis**

Schell lenses (`S03`) and England’s role-mapped door problem (`S07`) give a way to diverge and reconverge:

1. Each contributor writes experience goals and a paper prototype **without** seeing the others (independent ideation).
2. A synthesis session maps agreements, conflicts, and door-problem implications.
3. One experience-goal document is locked by HITL. Dissent is recorded, not silently averaged.
4. Production does not start from a collage of everyone’s favorite features (Meier warns that combining fun parts of other games often fails).

This is proposed adaptation. It matches Sigma’s HITL gate contract: one gate per phase, no batching, silence is not yes.

### 4.9 Business, GTM, distribution, live operations

Steam Direct (`S16` family: partner.steamgames.com/steamdirect and app-fee docs). $100 USD per app, recoupable after $1,000 adjusted gross revenue. Paperwork, tax, identity. This is a **distribution onboarding cost**, not a design method.

Steam Playtest (`S16`, docs fetched 2026-09-22): child AppID, signup on the main store page, grant randomly (optionally by country), Open vs Limited signup, deactivate to “Not Playable,” cannot charge money, not under NDA, no unique store page, friend-invite experimental for multiplayer. Valve’s stated reason: studios were abusing demos and “prologues” to get live data. Playtest is the official, lower-risk path. Confidential unannounced tests should use release-override keys on the unreleased base app, with leak risk accepted.

Steam also documents Demos, Early Access, Coming Soon, wishlists, visibility rounds, and update best practices. Early Access is the paid work-in-progress path. Playtest is free and revocable. Those are different products.

Live operations (seasons, battle passes, live events) are **conditional**, equivalent to Sigma Step 1.5: only if the game is an ongoing service. Meier’s “interesting once is not interesting ten times” is the design test for a live loop. Koster’s pattern-mastery problem is why live games add permutation. Neither author tells you to build live ops.

Store page and trailer work map to Step 9, but for games the “landing page” is often the store listing plus a demo or playtest. Fullerton’s experience goals should be readable in the store copy (Dan Fornace’s 2021 X post discovered this; the underlying method is Fullerton + ordinary marketing).

**Revision rule:** Coming Soon and wishlists may go up after a playable slice exists and experience goals are still true. Live-ops architecture, season calendars, and monetization graphs wait for Step 1.5 and a proven retention loop.

---

## 5. Fine-grained planning workflows

These are proposed overlays on existing Sigma phases. They do not add numbered steps.

### 5.1 Experience-first spine (every game)

```
experience goals (felt situations)
    → aesthetic mix (MDA)
    → core verb + interesting decision
    → cheapest prototype that can fail the goals
    → playtest (friends → strangers)
    → door-problem sheets for every new interactable
    → greybox / blockout of one complete session
    → feel or decision proof (whichever the game actually is)
    → freeze list (what production is banned until proofs hold)
    → only then: content volume, art pass, score, store, live ops
```

### 5.2 Two prototype tracks (pick one primary)

**Decision track** (Meier/Fullerton/Rouse): paper, cards, spreadsheet, or tabletop. Success = players hesitate productively, then can explain the tradeoff.

**Feel track** (Swink): digital greybox with final-ish input latency. Success = testers can control the object without a tutorial, and can describe the body metaphor.

A game may need both. Sequence them. Do not build a vertical slice that mixes unproven feel with unproven economy.

### 5.3 Space track (if the game has spaces)

Use `S11` as a menu, not a law. Skip combat design if there is no combat. Skip 3D blockout if the game is a spreadsheet or a visual novel (replace with beat boards and UI states). Keep pre-production and release.

### 5.4 Systems track (if the game has interacting verbs)

Write class-to-class rules before placing unique set pieces (`S08`, `S09`). Playtest for second-order consequences. Decide which emergent tricks to keep, which to block, which to teach. Smith still uses special-case goals; the overlay is **when** to use each.

### 5.5 Documentation that stays small

England (`S07`) plus Rouse (`S13`) plus Fullerton (`S02`) yield three document types only:

1. **Experience-goal sheet** (one pager, living).
2. **Door-problem spec** per interactable or system (questions + answers + owner).
3. **Playtest log** (who, what build, which goals passed/failed, clips or notes).

A full design bible is optional and late. Rouse’s sample *Suffering* document is evidence that large docs exist in shipped games; it is not evidence they should precede a paper prototype.

### 5.6 Revision rules (production freeze)

1. If a playtest fails an experience goal, change the prototype, not the goal — unless HITL explicitly revises the goal.
2. If a decision is always or randomly chosen, cut or rewrite it (`S04`).
3. If testers need a designer speech to have fun, the mechanic is unfinished.
4. If art or narrative volume is being used to hide a dead loop, cut the volume.
5. If a new system does not connect to existing mechanics, it is content, not a system (`S09`).
6. If an object cannot survive a door-problem pass, it does not ship in the slice (`S07`).
7. If accessibility scoping (`S15`) says the game has timers, QTEs, or color-only signals, those are design bugs in the slice, not polish tickets.
8. Do not start Step 11-scale implementation PRDs for content packs while the core loop PRD is unproven.

---

## 6. Mapping onto canonical Protocol 0–15 + 1.5 / 11.5

Canonical spine from `AGENTS.md`:  
`0 → 1 → 1.5 (conditional) → 2 → 3 → 4 → 5 → prototype backlog → 6 → 7 → 8 → 9 → 10 → 11 → 11.5 → implementation backlog → optional orchestrate → 12 → 13 → 14 → 15`

| Step | Existing job | Game overlay (proposed) | Gate evidence |
|---|---|---|---|
| **0** Environment | Runtime, research stack, baseline | Playtest capture path, input devices you will actually test, accessibility machine settings. No engine lock required. | Baseline notes which prototype medium is available this week |
| **1** Ideation | MASTER_PRD, users, value | Experience goals, aesthetic mix, core verb, interesting decision, paper prototype, kill-assumptions | Outsider playtest vs goals; freeze list |
| **1.5** Offer | Monetization architecture | Only if paid, F2P, live ops, DLC, or platform fees matter. Steam Direct fee is not an offer. Battle pass is. | Explicit “no live ops” or a retention loop hypothesis |
| **2** Architecture | Boundaries, C4, ADR | Interaction model: authored / systemic / hybrid; class-to-class rules; possibility space; save model | ADR for systems vs set pieces |
| **3** UX | UX-DESIGN, journeys | Cognitive load, form-follows-function, first-session teaching, HUD philosophy (`S14`) | Journey that includes fail and recovery |
| **4** Flow tree | Screens, transitions, zero-omission | Add **spaces** and **verbs**. Puzzle/level graph. Door inventory. | Traceability: every verb has a first-teach space |
| **5** Wireframes / prototypes | Flow PRDs, Track A/B | Paper + greybox as the prototype PRDs. Vertical slice is a *later* prototype, not the first. | Playable greybox of one complete session |
| **prototype backlog** | `prd.json` prototype | Loop, feel, one space, one door-problem object | Backlog items are playable proofs |
| **6** Design system | Tokens, components | Readability tokens (interactable, path, danger, focus) plus brand | Contrast and silhouette tests |
| **7** States | STATE-SPEC | Death, stuck, lost, overloaded, motion-sick, cannot-hear-cue, cannot-read | Each state has a recovery |
| **8** Technical spec | Implementation blueprint | Input, save, simulation tick, audio buses, accessibility APIs. Engine choice happens here if still open. | Spec names the proven loop, not a fantasy feature list |
| **9** Landing | LANDING-PAGE | Store page, trailer, demo/playtest policy. Copy restates experience goals. | Coming Soon only after slice exists |
| **10** Feature breakdown | Appetites, PRD eligibility | Systems first, content packs second. Cut features that are uninteresting decisions. | Eligibility table marks “proof” vs “volume” |
| **11** PRD generation | Feature PRDs | Each PRD includes door-problem answers, playtest protocol, XAG scoping, feel/decision metrics | Agent can implement without inventing player experience |
| **11.5** Task handoff | TASKS.md | Tasks point at prototype evidence. No task is “make it fun.” | Tasks have observable playable outputs |
| **12** Context engine | AGENTS.md | Pillars, freeze list, verb list, accessibility scoping, playtest log location | Agents cannot re-open frozen production |
| **13** Skillpack | Project skills/agents | Game-specific: feel tuning, blockout, playtest facilitation, XAG audit | Skills cite this research’s methods, not tool fashion |
| **14** Runtime | Tools, memory, Linear | Playtest ingest, build-numbering, input recordings | A failed playtest is a first-class artifact |
| **15** Observability | Instrumentation | Funnel of first session, fail reasons, accessibility option usage, decision histograms (`S04`) | Events map to experience goals |

HITL remains one gate per phase. Game overlays do not batch “approve pillars, loop, and art direction” into one question.

---

## 7. Testable acceptance evidence (method-level)

These are tests of the **methodology overlay**, independent of any one game.

| ID | Claim | Pass if |
|---|---|---|
| A1 | Experience goals beat feature lists | A reviewer who has not seen the feature list can still describe the intended session |
| A2 | Prototype precedes production | A playable prototype timestamp precedes art-pass or full score work |
| A3 | Decisions are interesting | In a 5-person test, no option is chosen 5/5 or 0/5 without a situational reason (`S04`) |
| A4 | Door-problem completeness | A new interactable has a filled question sheet before implementation (`S07`) |
| A5 | Blockout before art | Layout/blockout playtest notes exist for a space that later receives an art pass (`S11`) |
| A6 | Accessibility scoped | XAG scoping questions answered for input, time, contrast, audio buses (`S15`) |
| A7 | Playtest type named | Log states whether the session was friends, strangers, Steam Playtest, or accessibility (`S02`,`S16`) |
| A8 | Freeze honored | Content-volume PRDs are blocked while loop PRD is unproven |
| A9 | Independent ideation synthesis | If multiple contributors ideated, a written synthesis exists; features were not unioned |
| A10 | Store honesty | Steam accessibility tags (`S17`) match actual options; “without vision” is not claimed for HUD-only narration |

---

## 8. Small assumption-testing experiments

Each experiment is cheap, time-boxed, and designed to kill a bad assumption. None require installing a new engine or activating a live service.

1. **Paper-loop hour.** Build the core verb with cards or spoken rules. Three players, one facilitator silent after rules. If the facilitator must intervene, the loop is not ready (`S02`).
2. **Always-A test.** Offer three mechanical options in a greybox. If all picks are A, delete B and C (`S04`).
3. **Latency feel test.** Same greybox at 50 ms vs 150 ms input-to-motion. If the “feel” vanishes, Swink’s real-time-control claim applies and the production plan must budget input (`S06`).
4. **Door sheet on one object.** Pick the most boring interactable. Answer England’s question list. Count unanswered items. Those items are hidden scope (`S07`).
5. **Class-to-class spark.** Take two existing mechanics and force them to listen to one shared stimulus (fire, noise, money). Play for ten minutes looking for a second-order trick. If none appears, the systems are still special-case (`S08`,`S09`).
6. **Teach-without-text.** First two minutes, no tutorial dump. If Hodent’s form-follows-function fails, the art/UI language is not doing design work (`S14`).
7. **Bus mute.** Mute music only, then SFX only, then VO only. If a critical cue lives on the wrong bus, XAG 105 / Steam custom volume is already a design bug (`S15`,`S17`).
8. **Timer removal.** Disable all time pressure for one session. If the game’s only remaining interest is panic, Challenge was a crutch (`S01`,`S15` XAG 116).
9. **Solo vs pair ideation.** Two people write experience goals separately, then synthesize. If the union is larger than either original, the project just grew without a player (`S03`,`S02`).
10. **Store-page lie test.** Write the Steam description from experience goals only. If it cannot be written without naming unproven systems, the pitch is a feature collage.

---

## 9. Frame-reviewable talks and videos (parent owns exact-frame review)

This seat did **not** watch these end-to-end with visuals. URLs are for parent.

| Talk | URL | Why it matters |
|---|---|---|
| Sid Meier, “Interesting Decisions,” GDC 2012 (GDC YouTube 2018-09-27) | https://www.youtube.com/watch?v=WggIdtrqgKg | Decision types, cutting systems, player types |
| Celia Hodent, “The Gamer’s Brain,” GDC 2015 (YouTube 2017-08-13) | https://www.youtube.com/watch?v=XIpDLa585ao | Perception, UX, intended vs actual experience |
| Celia Hodent, “The Gamer’s Brain, Part 2” | https://www.youtube.com/watch?v=Paf6B1jleCo | Onboarding |
| Celia Hodent, “The Gamer’s Brain, Part 3” (2017, YouTube 2020-01-24) | https://www.youtube.com/watch?v=CozTtfhwPX0 | Retention / engagement; includes a game-feel segment |
| Steve Lee, “An Approach to Holistic Level Design,” GDC 2017 | https://www.youtube.com/watch?v=CpOoTAVeEcU | Gameplay + presentation + story as one |
| Harvey Smith & Randy Smith, GDC 2004 emergent gameplay (Vault; unofficial slide+audio 2017-10-20) | https://www.gdcvault.com/play/1013560/Would-the-Real-Emergent-Gameplay and https://www.youtube.com/watch?v=yLVceaULKLU | Connect mechanics; stimuli vs hard-coded pairs |
| Jesse Schell interview on lenses (2024-02-20) | https://www.youtube.com/watch?v=Cc2YjcyRoMc | Origin of lenses; Christopher Alexander influence |
| Steamworks Quick Tips — Steam Playtest | https://youtu.be/0_HhCEJ_kZ0 | Official feature walkthrough (`S16`) |
| Liz England, Game Developer Podcast Ep. 53 (2025) | https://www.youtube.com/watch?v=aYd_qp6t7_4 | Door problem eleven years later; leadership of door problems |
| Polygon/related, “Why video game doors are so hard” (2021-09-03) | https://www.youtube.com/watch?v=AYEWsLdLmcc | Secondary; cites England |

Harvey Smith GDC 2025 short talk “Rules of the Game” (https://www.youtube.com/watch?v=UTE_bVUeHCQ) is a discovery lead for layered decision-rich spaces; parent should confirm against the 2002/2004 primary talks.

---

## 10. GitHub and official-kit notes

| Artifact | License / maintenance | Use in Protocol | Status |
|---|---|---|---|
| `microsoft/Xbox-GDK-Samples` (`S18`) | MIT; ATG; 52 commits on main as of fetch; **October 2025 GDK required**; AccessibilitySample present | Reference for platform accessibility APIs if shipping on GDK/Xbox/PC Game Pass | Demonstrated repo evidence; not a universal toolkit |
| Xbox Accessibility Guidelines (`S15`) | Official Microsoft Learn; v3.2 2023-06-08; page updated 2026-08 | Scoping questions + implementation guidelines as Step 1/7/11 checklists | Demonstrated docs |
| Steamworks Playtest + Accessibility Features (`S16`,`S17`) | Valve partner docs, live 2026-09-22 | Distribution and playtest policy; store tags | Demonstrated docs; features **untested** in this research |
| The Level Design Book (`S11`) | CC BY-NC-SA 4.0; volunteer; under construction; updates 2025-01 and 2025-11 | Process menu for spatial games | Demonstrated site; incomplete pages possible |
| Deck of Lenses app (`S03`) | Commercial companion | Optional workshop tool | Untested tool |
| FMOD / Wwise / game engines | — | Out of scope for this half of the research | Not evaluated |

Popularity (stars, sales, “best designer”) is not used as quality.

---

## 11. Practical choices that require creator input

The methodology cannot honestly default these. They change which practitioner methods apply.

1. **What is the intended session feeling**, in Fullerton’s situation language, not in genre labels?
2. **Is the primary proof a decision, a feel, a story beat, or a social space?** Pick one to prove first.
3. **Authored, systemic, or hybrid** interaction model (`S08`)?
4. **Does the game have spaces** that players walk, or is it boards, menus, text, or abstract UI?
5. **Does combat exist?** If no, delete the combat design phase (`S11`).
6. **Real-time control of a virtual body?** If no, Swink is diagnostic at most (`S06`).
7. **Single-player completeable work vs ongoing service?** Step 1.5 and live ops follow only from the second.
8. **Solo, tiny team, or optional independent ideation tracks?** Synthesis rules differ.
9. **Distribution target class** (PC storefront, console certification, mobile, physical, free web) — choose a class, not an engine.
10. **Which XAG/Steam accessibility tags are in-scope for v1** because they are the experience (e.g. no timers, remappable input), versus later?
11. **Confidential playtest vs public Steam Playtest** (`S16` leak warning)?
12. **Monetization:** none, paid once, optional extras, or live economy? “We’ll see” is an answer only until Step 1.5 is skipped or run.
13. **Narrative load:** environmental, quest, cinematic, or none? This changes blockout vs scripting time (`S11`).
14. **Multiplayer:** none, async, local, online. Friend-invite Playtest and netcode are irrelevant until this is yes.
15. **Who is allowed to change experience goals** after the first outsider playtest? HITL owner must be named.

---

## 12. Unresolved claims and research limitations

**Unresolved**

- Full texts of Schell 3rd ed., Swink, Anthropy/Clark, Rouse 2nd ed., and Hodent 2nd ed. were not read cover-to-cover. Methods above use excerpts, TOCs, author sites, and secondary practitioner reviews.
- Liz England’s live site returned a stub; the 2014 text was corroborated via Kotaku reprint (author-permitted) and Wayback. Exact live URL stability is uncertain.
- GDC Vault 2002 Harvey Smith audio+slides were not recovered as a first-party stream; 2002 interview (`S08`) and 2004 talk (`S09`) carry the method.
- Randy Smith’s “object-oriented level design” is widely attributed in community memory; this seat verified the 2004 joint talk and Thief credits, not a separate canonical essay with a stable URL.
- Whether MDA’s eight aesthetics are still the best vocabulary in 2026 is contested in game-studies literature (not fully surveyed here).
- Causal link from usability labs to sales was already unanswered by Fulton in 2002; still unanswered here.
- Barone’s solo path is one survivor case. Base rates for solo projects of that scope are not in this corpus.
- Steam Playtest’s effect on wishlists and reviews is Valve’s claim of non-interference; this research did not independently measure it.
- Accessible Games Initiative tags (ESA, announced GDC 2025) may eventually replace or sit beside Xbox and Steam tags. Mapping is incomplete.

**Limitations**

- No engine, DCC, or middleware bake-off (that is the assets/technical half).
- No frame-accurate video review.
- X keyword search on several practitioner handles returned no hits; semantic search returned sparse, mostly non-primary posts.
- Academic citation counts were not used as quality.
- Console certification books (TRC/XR/Lotcheck) were not ingested; they are platform-legal overlays, not design methods.
- Live-ops “best practices” from large service games were deliberately under-weighted so they do not masquerade as defaults.

**What would change this synthesis**

Parent frame-review of Meier, Hodent, Lee, and Smith/Smith talks; a cover-to-cover pass on Swink and Fullerton 5th ed.; a creator decision on the 15 practical choices above.

---

## 13. Source index (checked this session)

| ID | Practitioner / body | Method in one line | Date | Evidence class |
|---|---|---|---|---|
| S01 | Hunicke, LeBlanc, Zubek | MDA: tune across mechanics/dynamics/aesthetics | 2004-06 (AAAI workshop paper) | Demonstrated (PDF) |
| S02 | Tracy Fullerton | Playcentric: experience goals, paper proto, iterate | 2024-04-18 excerpt; 5th ed. book 2024-04-19 | Demonstrated excerpt; book source claim |
| S03 | Jesse Schell | 100+ diagnostic lenses | 2008; 3rd ed. 2019; studio page 2026 | Source claim + demonstrated studio page |
| S04 | Sid Meier | Interesting decisions; cut the rest | GDC 2012; write-up 2012-03-07; video 2018-09-27 | Demonstrated write-up; video not frame-reviewed |
| S05 | Raph Koster | Fun as learning/pattern mastery | 2003 talk; 2004 book; 2nd ed. 2013 | Demonstrated author page + slides PDF |
| S06 | Steve Swink | Game feel as real-time virtual sensation | 2008 | Source claim (publisher + TOC) |
| S07 | Liz England | Door-problem specs; role-mapped production | 2014-04-21 | Demonstrated via reprint/Wayback |
| S08 | Harvey Smith | Systemic vs special-case level design | GDCE 2002; interview 2002-09-11 | Demonstrated interview |
| S09 | Harvey Smith & Randy Smith | Connect mechanics to get emergence | GDC 2004 | Source claim + transcript snippets; video not frame-reviewed |
| S10 | Steve Lee | Holistic level design (play + look + story) | GDC 2017 | Demonstrated talk page/transcript snippets |
| S11 | Robert Yang et al. | Spatial process: prepro → blockout → art last | Living book; process page; updates 2025 | Demonstrated site |
| S12 | Anna Anthropy & Naomi Clark | Verbs, objects, scenes, resistance | 2014-02/03 | Source claim (publisher + review) |
| S13 | Richard Rouse III | Full process + sample GDD | 2001; 2nd ed. 2004-09 | Demonstrated author site; book source claim |
| S14 | Celia Hodent | Cognitive UX; intended experience; test hypotheses | GDC 2015–2017; book 2017; 2nd ed. 2026 | Demonstrated talk metadata; books source claim |
| S15 | Xbox / Microsoft | XAG v3.2 scoping + implementation | v3.2 2023-06-08; page 2026-08 | Demonstrated official docs |
| S16 | Valve Steamworks | Playtest child AppID; testing policy | Docs live 2026-09-22 | Demonstrated official docs |
| S17 | Valve Steamworks | Accessibility store tags + wizard | Docs live 2026-09-22 | Demonstrated official docs |
| S18 | Microsoft ATG | GDK samples incl. AccessibilitySample; MIT | README requires Oct 2025 GDK | Demonstrated GitHub README + LICENSE |

Supporting discovery (not counted in the 18): X posts by Dan Fornace (pillars should excite players, 2021-03-25) and Marina Díez (4–5 ingredients, 2021-07-09); GQ/PC Gamer Barone interviews; Brian Schmidt GDC speaker bio; Guy Whitmore GDC 2014 slides; Bill Fulton usability comments in the same 2002 article as `S08`.

---

*End of synthesis. No product code was written. No tools were installed. No external services were activated.*
