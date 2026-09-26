# Levels and puzzles: intent to art-pass readiness

Generated from catalog 1.0.0.

Design a level, encounter, puzzle or scene as a graph of verbs, states and spaces: intent, constraints, solution graph, door-problem sheets, layout, blockout playtest, teaching and fairness, recovery, scripting and save state, and the gate that allows an art pass.

Applicability: Applies to any bounded play unit: a 3D level, a 2D stage, a puzzle, a card scenario, a text chapter, a board setup, a multiplayer map. Phases about spaces are marked not-applicable with a reason for spaceless units; the solution graph, door sheets, teaching, fairness and recovery apply to every unit. Combat-specific work applies only when combat exists.

Atlas stages: 4, 5, 7, 8, 10, 11. Canonical steps: 4, 5, 7, 8, 10, 11.

## level-intent — Level intent

### Creator questions

- **goal**: Which experience goal does this unit serve, and what should a player feel at its start, middle and end?
- **verbs-featured**: Which verbs are featured, which are introduced for the first time, which are combined for the first time?
- **beat**: Which narrative beat, if any, this unit carries.
- **success**: What observable tester behaviour means this unit works?

### inputs

- Experience-goal sheet
- Verb-object matrix
- Beat sheet
- Space inventory

### activities

- Write the intent in one page
- Name featured and first-time verbs
- Write the success behaviour

### tools

- Atlas document editor

### skills

- game-world-design
- game-systems-design

### roles

- creator
- game-design-lead

### outputs

- Level intent sheet

### dependencies

- None specified.

### reviewCriteria

- One goal, named
- First-time verbs are explicit
- Success is a behaviour

### revisionRules

- A cut verb re-opens intent
- A goal change re-opens intent

### Evidence required

Intent only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [An Approach to Holistic Level Design (GDC 2017)](https://www.youtube.com/watch?v=CpOoTAVeEcU) — source-claim. Talk description and transcript snippets only; not frame-reviewed. Lee flags a 3D action-adventure and immersive-sim bias. Not a 2D, puzzle or management-game process.
- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.

## constraints-inventory — Constraints inventory

### Creator questions

- **world**: Which world rules constrain this unit (no elevators, water deadly, doors rare)?
- **technical**: Streaming, memory, agent count, physics object budget, and any multiplayer symmetry or spawn constraints.
- **accessibility**: Which accessibility scoping answers bind this unit (no forced timers, remappable input, no colour-only signal, motion limits)?
- **combat**: Does combat exist here? If yes, define the fight before mapping it (enemy classes, ranges, cover needs). If no, mark not-applicable with that reason.

### inputs

- Level intent
- World rules
- Technical budgets
- Accessibility scoping

### activities

- Collect constraints from world, technical and accessibility documents
- Define combat if present

### tools

- Atlas document editor

### skills

- game-world-design
- game-technical-production

### roles

- creator
- game-design-lead
- game-technical-director

### outputs

- Constraints inventory with combat definition if any

### dependencies

- level-intent

### reviewCriteria

- Every constraint cites its source document
- Combat is defined or excluded with a reason

### revisionRules

- A budget change re-opens technical constraints
- A new accessibility answer re-opens the inventory

### Evidence required

Inventory only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.

## solution-graph — Solution graph

### Creator questions

- **states**: List the unit's states (locked, open, powered, discovered, solved, failed) and the transitions the player's verbs cause.
- **intended-solutions**: Which solutions are intended, which are emergent and accepted, which are blocked, which are taught?
- **critical-path**: The shortest path from entry to goal, and every optional branch with its reward.
- **dead-ends**: Which states are unrecoverable without reset? Each needs a recovery plan in recovery-fail-states or a reason to keep it.

### inputs

- Level intent
- Constraints
- Class-to-class rules if systemic

### activities

- Draw the state graph
- Mark intended, emergent, blocked, taught
- Find dead ends

### tools

- Diagram tool
- Spreadsheet

### skills

- game-systems-design
- game-world-design

### roles

- creator
- game-design-lead

### outputs

- Solution graph with critical path and dead-end list

### dependencies

- level-intent
- constraints-inventory

### reviewCriteria

- Every state is reachable and leaves
- Emergent solutions have a keep/block/teach mark
- Dead ends are listed

### revisionRules

- A blocked class-to-class trick re-opens the graph
- A new verb may add transitions

### Evidence required

Graph only; tester paths are recorded in blockout-playtest. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.
- [Would the Real Emergent Gameplay Please Stand Up? (GDC 2004)](https://www.gdcvault.com/play/1013560/Would-the-Real-Emergent-Gameplay) — source-claim. GDC Vault listing and an unofficial 2017 slide-plus-audio reconstruction; not frame-reviewed. Randy Smith's separate object-oriented level design essay was not found at a stable URL.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [The Door Problem](https://web.archive.org/web/20231023231458/https://lizengland.com/blog/2014/04/the-door-problem/) — verified-source-text. Live blog URL returned a stub; Wayback 2023-10-23 and the Kotaku reprint (author-permitted) were used. Essay is an analogy, not a complete spec standard. Large-studio role map does not transfer 1:1 to solo.

## door-problem-sheets — Door-problem sheets for every interactable

### Creator questions

- **sheet-per-class**: For each interactable class in this unit: can it be used, by whom, when, how does the player know, what is locked or gated, how do enemies or companions treat it, what unloads behind it, what sound or animation plays, how is it tested?
- **unanswered**: Count the unanswered items per sheet. Those are hidden scope; who owns each?
- **role-map**: Which role (design, art, audio, technical, quality) owns each answer for this project? A solo creator lists themself and the order they will answer.

### inputs

- Solution graph
- Interactable inventory
- Role roster

### activities

- Fill one sheet per interactable class
- Count unanswered items as scope
- Map owners

### tools

- Atlas document editor or spreadsheet

### skills

- game-world-design
- game-systems-design

### roles

- creator
- game-design-lead

### outputs

- Door-problem sheets with hidden-scope counts

### dependencies

- solution-graph

### reviewCriteria

- Every interactable class has a sheet
- Unanswered items are counted, not hidden
- Owners exist

### revisionRules

- A new interactable class adds a sheet
- An unanswered item that blocks implementation blocks the PRD

### Evidence required

The sheets. The first unanswered-item count on the most boring interactable is the experiment result to record. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Door Problem](https://web.archive.org/web/20231023231458/https://lizengland.com/blog/2014/04/the-door-problem/) — verified-source-text. Live blog URL returned a stub; Wayback 2023-10-23 and the Kotaku reprint (author-permitted) were used. Essay is an analogy, not a complete spec standard. Large-studio role map does not transfer 1:1 to solo.

## layout — Layout plan

### Creator questions

- **form**: 2D plan, node map, board diagram, or scene list? Why this form for this unit?
- **placement**: Where are entry, goal, key states, optional branches, sightlines to the goal or its promise, and rest points?
- **pacing**: Intended pacing curve (tension, release) along the critical path, in plain words.
- **multiplayer**: If multiplayer: symmetry, spawn fairness, and spectator or downed-player views. If not, not-applicable with that reason.

### inputs

- Solution graph
- Constraints
- Space brief if a space exists

### activities

- Draw the plan as communication
- Place states and sightlines
- Describe pacing

### tools

- Drawing tool
- Diagram tool

### skills

- game-world-design

### roles

- creator
- game-design-lead

### outputs

- Layout plan

### dependencies

- solution-graph
- constraints-inventory

### reviewCriteria

- Every graph state has a place
- Sightlines to the goal or its promise exist
- Pacing is described

### revisionRules

- A graph change re-opens the plan

### Evidence required

Plan only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [An Approach to Holistic Level Design (GDC 2017)](https://www.youtube.com/watch?v=CpOoTAVeEcU) — source-claim. Talk description and transcript snippets only; not frame-reviewed. Lee flags a 3D action-adventure and immersive-sim bias. Not a 2D, puzzle or management-game process.

## blockout-playtest — Blockout playtest of the unit

### Creator questions

- **form**: Playable greybox, paper walk-through, card scenario, or text draft? Why is this the cheapest form that can fail the intent?
- **testers**: Who will play, or has played, how many, and which facilitation approach fits the question? Record the participant selection limits and any intervention.
- **paths-taken**: Which paths did testers take versus the critical path? Where did they get lost, stuck, or bored, by their behaviour?
- **intent-held**: Did the intended feelings at start, middle and end appear in tester behaviour or words?
- **next-change**: What changes in the layout or graph next, and why?

### inputs

- Layout
- Environment blockout if a space exists
- Playtest capture path

### activities

- Build the cheapest playable form
- Run the chosen experiment with suitable participants and record the limits of any creator-only test
- Record paths, stuck points and words
- Change layout or graph, not intent, unless the owner records an intent change

### tools

- Engine greybox, paper, cards, or text
- Playtest log

### skills

- game-world-design
- game-quality-planning

### roles

- creator
- game-design-lead
- game-quality-lead

### outputs

- Blockout playtest entries with paths and stuck points

### dependencies

- layout

### reviewCriteria

- Tester type is named
- Paths are recorded against the critical path
- Changes trace to observations

### revisionRules

- Each session appends
- A layout change re-runs the test before an art pass

### Evidence required

Actual sessions: build or draft version, tester type and count, recorded paths, stored notes or recording. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.

## teaching-fairness — Teaching and fairness

### Creator questions

- **teach-by-doing**: For each first-time verb or rule here: how is it taught by doing, in a safe context, before it is tested under pressure?
- **no-text-test**: Did testers learn it without a text dump in the first attempt? What failed?
- **fairness**: Which failures are the player's fault by the game's own rules, and which are the level's (invisible hazard, ambiguous signal, timing the player could not read)?
- **difficulty-options**: Which options (assist, timer off, remap, contrast) change this unit, and is the unit still meaningful with each on?

### inputs

- Blockout playtest
- Verb inventory first-teach map
- Accessibility scoping

### activities

- Map teach-before-test per verb
- Score fairness from tester failures
- Check the unit under each accessibility option

### tools

- Playtest log

### skills

- game-world-design
- game-quality-planning
- accessibility-audit

### roles

- creator
- game-design-lead
- game-quality-lead

### outputs

- Teaching and fairness report

### dependencies

- blockout-playtest

### reviewCriteria

- Every first-time verb is taught before tested
- Unfair failures are fixed or accepted with a reason
- Options were checked

### revisionRules

- A new verb adds a teach step
- An accessibility answer change re-checks options

### Evidence required

Tester failure list with fault classification, from real sessions. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.

## recovery-fail-states — Recovery and fail states

### Creator questions

- **fail-states**: Every way the player can fail or get stuck here, and how the game shows it.
- **recovery**: For each: the recovery path (checkpoint, reset, hint, fail-forward route) and its cost to the player.
- **stuck-detection**: How does the game detect or let the player declare 'stuck' or 'lost', and what does it do?
- **save-boundaries**: Where can the player save or quit, and what state is restored?

### inputs

- Solution graph dead ends
- State spec world states
- Teaching report

### activities

- List fail states with recovery
- Design stuck handling
- Set save boundaries

### tools

- Atlas document editor

### skills

- game-world-design
- game-quality-planning

### roles

- creator
- game-design-lead

### outputs

- Recovery and fail-state table

### dependencies

- solution-graph
- teaching-fairness

### reviewCriteria

- Every dead end has a recovery or a reason
- Stuck is handled
- Save boundaries are explicit

### revisionRules

- A new dead end adds a row
- A save schema change re-opens boundaries

### Evidence required

Table only; kill-and-reload testing is recorded in scripting-save-state. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [Saving games (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Teaching slice, not a production save schema.

## scripting-save-state — Scripting, events and save state

### Creator questions

- **events**: Which scripted events, triggers, spawns and dialogue hooks exist, in which states they fire, and which door-sheet answers they implement?
- **persist**: Which unit state persists in a save, which resets, and which is deliberately not saved (mid-animation, random state)?
- **kill-reload**: Plan the kill-and-reload experiment: quit mid-state, reload, compare. What must be identical?
- **rework**: When the layout changes, which scripts and story hooks must be rewritten? Is anything placed here that is cheap to move?

### inputs

- Solution graph
- Door sheets
- Recovery table
- Save schema from Step 8
- Delivery channels

### activities

- Write the event list against states
- Define persisted state
- Run kill-and-reload when a build exists

### tools

- Engine scripting or text engine
- Save inspector

### skills

- game-technical-production
- game-world-design

### roles

- game-technical-director
- creator

### outputs

- Event and save-state specification with kill-reload result

### dependencies

- door-problem-sheets
- recovery-fail-states

### reviewCriteria

- Every event maps to a state and a door-sheet answer
- Persisted state is explicit
- Kill-reload passed or failures are listed

### revisionRules

- A layout change re-opens the event list
- A save schema change re-opens persisted state

### Evidence required

Kill-and-reload result from a real build: what was compared and what differed. Planned experiments are recorded as planned. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [The Door Problem](https://web.archive.org/web/20231023231458/https://lizengland.com/blog/2014/04/the-door-problem/) — verified-source-text. Live blog URL returned a stub; Wayback 2023-10-23 and the Kotaku reprint (author-permitted) were used. Essay is an analogy, not a complete spec standard. Large-studio role map does not transfer 1:1 to solo.
- [Saving games (Godot docs)](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) — verified-source-text. Full page read by the research seat; URL reconstructed from the page title. Teaching slice, not a production save schema.

## art-pass-readiness — Art-pass readiness gate

### Creator questions

- **playtested**: Which blockout playtest entries show wayfinding and pacing held for the current layout?
- **stable**: What is still expected to change in layout or graph, and is an art pass on those areas premature?
- **scope**: Which areas receive art now (and at which asset level) and which stay grey with a reason?
- **release**: Which hold-list items does this gate release?

### inputs

- Blockout playtest entries
- Teaching report
- Recovery table
- Hold list

### activities

- Cite the playtest entries
- Mark stable versus unstable areas
- Release held art work per area

### tools

- Atlas document editor

### skills

- game-world-design
- game-development

### roles

- creator
- game-design-lead
- game-art-director

### outputs

- Art-pass readiness decision per area

### dependencies

- blockout-playtest
- teaching-fairness
- recovery-fail-states

### reviewCriteria

- Playtest entries are cited, not assumed
- Unstable areas stay grey
- Released items are listed

### revisionRules

- A later layout change revokes readiness for the changed areas

### Evidence required

Citations to actual playtest entries. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
