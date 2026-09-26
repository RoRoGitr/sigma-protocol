# Systems: interaction model, verbs, decisions, feel and economy

Generated from catalog 1.0.0.

Turn the core verb into a proven loop: name the interaction model, inventory verbs and objects, test decisions for interest, prove feel where real-time control exists, plan progression or economy, write class-to-class rules for systemic play, and run the tuning loop with playtests.

Applicability: Every game has at least a verb inventory and a decision audit. The feel track applies only when the player controls a body or object in real time. Class-to-class rules apply only to systemic or hybrid interaction models. Economy and progression apply when the game has resources or a mastery curve; a short authored work may mark them not-applicable with a reason.

Atlas stages: 1, 2, 4, 5, 10, 11, 18. Canonical steps: 1, 2, 4, 5, 10, 11, 15.

## interaction-model — Interaction model decision

### Creator questions

- **model**: Authored beats, systemic possibility space, or hybrid? Give one concrete example of how a moment is produced under the chosen model.
- **class-rule-example**: If systemic or hybrid: one class-to-class rule (any X plus any Y produces Z) and one second-order consequence you would accept without scripting it.
- **special-cases**: Which moments are deliberately special-case (a scripted exit, a set piece) even in a systemic game?
- **cost**: What production and QA cost does the chosen model imply, and does capacity from the creator profile cover it?

### inputs

- Experience-goal sheet
- Idea pack references

### activities

- Decide the model from the experience goals and the capacity
- Write the architecture ADR text for Step 2
- List special cases explicitly so they are not mistaken for missing systems

### tools

- Atlas document editor

### skills

- game-systems-design
- decisions-patterns

### roles

- creator
- game-design-lead
- lead-architect

### outputs

- Interaction-model ADR text for ARCHITECTURE.md

### dependencies

- None specified.

### reviewCriteria

- The model has a concrete example
- Cost is compared to capacity
- Special cases are listed

### revisionRules

- Changing the model re-opens class-to-class-rules, levels.solution-graph and narrative.story-structure

### Evidence required

Decision only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.
- [Would the Real Emergent Gameplay Please Stand Up? (GDC 2004)](https://www.gdcvault.com/play/1013560/Would-the-Real-Emergent-Gameplay) — source-claim. GDC Vault listing and an unofficial 2017 slide-plus-audio reconstruction; not frame-reviewed. Randy Smith's separate object-oriented level design essay was not found at a stable URL.
- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.

## verb-object-inventory — Verb and object inventory

### Creator questions

- **verbs**: List every player verb, the object classes it acts on, and the resistance or cost each verb meets.
- **first-teach**: For each verb, where and how it is taught by doing, without a text dump.
- **verb-count-check**: Which verbs could be removed without losing an experience goal? Remove them or justify them.

### inputs

- Experience-goal sheet
- Interaction model
- Flow tree if it exists

### activities

- Enumerate verbs and object classes as a matrix
- Attach the first-teach location per verb
- Cut verbs that serve no goal

### tools

- Spreadsheet or table in the document

### skills

- game-systems-design

### roles

- creator
- game-design-lead

### outputs

- Verb-object matrix feeding the Step 4 flow tree

### dependencies

- interaction-model

### reviewCriteria

- Every verb serves a goal
- Every verb has a first-teach location
- Object classes are classes, not one-off instances

### revisionRules

- Adding a verb re-opens decision-audit and levels.teaching-fairness
- Removing a verb re-opens every level document that used it

### Evidence required

Inventory only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.
- [The Door Problem](https://web.archive.org/web/20231023231458/https://lizengland.com/blog/2014/04/the-door-problem/) — verified-source-text. Live blog URL returned a stub; Wayback 2023-10-23 and the Kotaku reprint (author-permitted) were used. Essay is an analogy, not a complete spec standard. Large-studio role map does not transfer 1:1 to solo.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.

## decision-audit — Decision audit

### Creator questions

- **decisions**: List the decisions the player makes around the core verb, each with its tradeoff, what makes it situational, and how the game acknowledges it.
- **always-a**: For each decision, the always-A test: could one option dominate? What evidence (playtest picks) do you have?
- **random-pick**: For each decision, could the pick be random without loss? What evidence?
- **information**: Does the player have enough information to choose without paranoia, and how is it shown?
- **cuts**: Which decisions stay uninteresting after tuning and are cut, and which test killed them?

### inputs

- Verb-object matrix
- Prototype results

### activities

- Run always-A and random-pick tests in the cheapest medium
- Record pick counts from real testers
- Cut or rewrite decisions that fail; do not schedule them for later polish

### tools

- Cards or spreadsheet prototype
- Playtest log

### skills

- game-systems-design
- game-quality-planning

### roles

- creator
- game-design-lead
- game-quality-lead

### outputs

- Decision audit table with pick evidence and cuts

### dependencies

- verb-object-inventory

### reviewCriteria

- In a small test no option is chosen unanimously or never without a situational reason
- Every decision is acknowledged by the game
- Cuts cite the test

### revisionRules

- New tester data that shows dominance re-opens the decision and any economy that depended on it

### Evidence required

Pick counts from real sessions (who, how many, which build) at a stated evidence grade. A predicted distribution is a plan, not a result. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).

## feel-track — Feel track (real-time control only)

### Creator questions

- **applies**: Does the player control a body or object in real time? If not, mark this phase not-applicable with that reason.
- **feel-metrics**: Input-to-motion latency target, acceleration and deceleration shape, camera behaviour, hit-stop and juice budget, and the body metaphor testers should describe.
- **latency-experiment**: Plan the same greybox at two latencies (for example 50 ms and 150 ms). What behaviour difference would prove feel matters for this game?
- **temp-audio**: Which placeholder sounds (footstep, confirm, fail, hit) are part of the feel prototype?

### inputs

- Primary-proof decision
- Verb-object matrix
- Pinned prototype tools

### activities

- Build or specify a greybox with realistic input latency and placeholder audio
- Select a suitable latency experiment and participants; distinguish creator self-tests from independent player evidence
- Record whether testers can control the object untutored and describe the metaphor

### tools

- Greybox scene in any engine or framework
- Input recording
- Playtest log

### skills

- game-systems-design
- game-audio-design

### roles

- creator
- game-design-lead
- game-technical-director

### outputs

- Feel specification with metrics and the latency experiment result

### dependencies

- verb-object-inventory

### reviewCriteria

- Not-applicable carries a reason
- Metrics are numbers with a device class
- The selected latency experiment has an execution receipt, or remains explicitly not executed with its participant limits recorded

### revisionRules

- Engine change re-opens the latency experiment
- A camera or control change re-opens the feel metrics

### Evidence required

Recorded sessions at both latencies with tester behaviour and the input log or build id. Planned experiments are recorded as planned. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Animation in Lyra Sample Game in Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/animation-in-lyra-sample-game-in-unreal-engine?lang=en-US) — verified-source-text. Official docs extract. Unreal AnimBP commands wrap portable ideas; does not define contact-state art.

## progression-economy — Progression and economy plan

### Creator questions

- **applies**: Does the game have progression (mastery curve, unlock tree, resource economy, narrative gating)? If not, mark not-applicable with a reason.
- **progression-type**: Which one is the player supposed to feel primarily: a learning curve, a decision tree that stays interesting, or an economy? Naming all three without a primary is the treadmill risk.
- **refresh**: When the pattern is mastered, what refreshes the possibility space (permutation, competition, player-authored content, new layers of the same verb)? Or is the game meant to end?
- **model**: Which spreadsheet or simulation model tests the curve before content is built?

### inputs

- Experience-goal sheet
- Decision audit

### activities

- Name the primary progression feeling
- Model the curve in a spreadsheet or simple simulation
- Decide whether the game ends or refreshes

### tools

- Spreadsheet
- Simple simulation script

### skills

- game-systems-design

### roles

- creator
- game-design-lead

### outputs

- Progression and economy model with the primary feeling named

### dependencies

- decision-audit

### reviewCriteria

- One primary progression feeling
- The model exists before content volume
- Refresh or ending is explicit

### revisionRules

- A changed decision audit re-opens the model
- Adding a resource adds a model column

### Evidence required

Model runs (spreadsheet or script output) at the stated version, not projected numbers. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [A Theory of Fun for Game Design - author page and 2003 slides](https://www.raphkoster.com/gaming/theoryoffun.shtml) — verified-source-text. Author page and hosted 2003 slides read; the book was not read cover to cover. Weak on fellowship, atmosphere and submission aesthetics. Games-are-not-stories claim is incomplete for presence-driven games.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [MDA: A Formal Approach to Game Design and Game Research](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) — verified-source-text. Full 5-page PDF read by the Grok design seat. 2004 workshop paper; later critiques not surveyed. Not a formula for fun and says so. Says nothing about production scheduling.

## class-to-class-rules — Class-to-class rules (systemic or hybrid only)

### Creator questions

- **applies**: Is the model systemic or hybrid? If authored, mark not-applicable with that reason.
- **stimuli**: Which general stimuli exist (fire, noise, water, money, light) and which object classes listen to each?
- **rules**: List the class-to-class rules in the form 'any X plus any Y produces Z'.
- **keep-block-teach**: From the spark experiment, which emergent tricks are kept, which are blocked, which are taught?

### inputs

- Interaction model
- Verb-object matrix

### activities

- Write rules as class relations, not object pairs
- Run the class-to-class spark experiment (two mechanics listening to one stimulus for ten minutes)
- Decide keep, block or teach per emergent trick

### tools

- Prototype scene or tabletop
- Playtest log

### skills

- game-systems-design

### roles

- creator
- game-design-lead

### outputs

- Class-to-class rule table with keep/block/teach decisions

### dependencies

- interaction-model
- verb-object-inventory

### reviewCriteria

- Rules reference classes
- At least one second-order consequence was observed or the systems are still special-case
- Keep/block/teach is recorded

### revisionRules

- A new object class must list which stimuli it listens to
- A blocked trick re-opens levels.solution-graph if levels relied on it

### Evidence required

The spark experiment session: what two mechanics, what stimulus, what happened, recorded at a stated grade. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.
- [Would the Real Emergent Gameplay Please Stand Up? (GDC 2004)](https://www.gdcvault.com/play/1013560/Would-the-Real-Emergent-Gameplay) — source-claim. GDC Vault listing and an unofficial 2017 slide-plus-audio reconstruction; not frame-reviewed. Randy Smith's separate object-oriented level design essay was not found at a stable URL.

## tuning-loop — Tuning loop across mechanics, dynamics and aesthetics

### Creator questions

- **cascade**: For the last change to a mechanic, which dynamics changed and which aesthetic moved? Record the cascade.
- **goal-check**: Which experience goals does the current build hold, by tester behaviour, and which fail?
- **next-lever**: Which single mechanic, rule or number changes next, and which goal it serves?
- **stop-condition**: What result would mean the loop is proven and content volume may start?

### inputs

- Decision audit
- Feel specification
- Progression model
- Playtest log

### activities

- Change one lever, playtest, record the cascade
- Score goals by behaviour each round
- Stop when the stop condition holds and release held items

### tools

- Playtest log
- Prototype build

### skills

- game-systems-design
- game-quality-planning

### roles

- creator
- game-design-lead
- game-quality-lead

### outputs

- Tuning log with cascades and the proven-loop declaration

### dependencies

- decision-audit
- progression-economy

### reviewCriteria

- One lever per round
- Goals scored by behaviour
- The stop condition is stated before the round

### revisionRules

- A proven-loop declaration releases hold-list items; a later failed goal revokes it by recorded decision

### Evidence required

Per-round playtest entries with build id, testers and per-goal behaviour. The declaration cites the entries. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [MDA: A Formal Approach to Game Design and Game Research](https://users.cs.northwestern.edu/~hunicke/MDA.pdf) — verified-source-text. Full 5-page PDF read by the Grok design seat. 2004 workshop paper; later critiques not surveyed. Not a formula for fun and says so. Says nothing about production scheduling.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [A Theory of Fun for Game Design - author page and 2003 slides](https://www.raphkoster.com/gaming/theoryoffun.shtml) — verified-source-text. Author page and hosted 2003 slides read; the book was not read cover to cover. Weak on fellowship, atmosphere and submission aesthetics. Games-are-not-stories claim is incomplete for presence-driven games.

## systems-instrumentation — Systems instrumentation plan

### Creator questions

- **events**: Which events expose each decision's pick distribution and each goal's occurrence in real play?
- **thresholds**: Which distributions would trigger a design revisit after release (for example one option above 80 percent)?
- **privacy**: What is not collected, and how are players told?

### inputs

- Decision audit
- Progression model
- Experience-goal sheet

### activities

- List decision and goal events for Step 15
- Set revisit thresholds
- Record privacy limits

### tools

- Atlas document editor

### skills

- game-systems-design
- observability

### roles

- game-design-lead
- observability-engineer

### outputs

- Systems section of the instrumentation contract

### dependencies

- decision-audit
- tuning-loop

### reviewCriteria

- Every audited decision has an event
- Thresholds exist
- Privacy limits are stated

### revisionRules

- A new decision adds an event

### Evidence required

Plan only; real distributions arrive after release. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
