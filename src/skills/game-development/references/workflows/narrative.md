# Narrative and world: load, rules, structure and delivery

Generated from catalog 1.0.0.

Decide how much story the game carries and how it is delivered, write world rules as constraints for art and levels, structure beats as pressure on verbs, and test narrative with readers and players before cinematic or dialogue volume is produced.

Applicability: Applies when the game has any narrative or a fictional world, including environmental storytelling with no text. A purely abstract game marks narrative-load as none and the remaining phases not-applicable with that reason. World rules still apply to any game with a setting, even without story.

Atlas stages: 1, 2, 3, 4, 5, 10. Canonical steps: 1, 2, 3, 4, 5, 10.

## narrative-load — Narrative load decision

### Creator questions

- **load**: None, environmental, quest or dialogue, cinematic, or authored-linear? Pick the primary and name secondary channels.
- **why**: Which experience goal needs this load? A goal of presence or fellowship may need less text than a goal of narrative.
- **cost**: What does this load cost in writing, voice, scripting and rework when levels change, against capacity?
- **games-not-stories-test**: If the fiction were removed, what remains? If nothing, the loop is not yet proven and this is a stress test result, not a failure of the story.

### inputs

- Experience-goal sheet
- Interaction model

### activities

- Choose the load from the goals and capacity
- Run the fiction-removed stress test honestly
- Feed the load into Step 2 and the level workflow (scripting weight)

### tools

- Atlas document editor

### skills

- game-world-design
- game-discovery

### roles

- creator
- game-design-lead

### outputs

- Narrative load decision

### dependencies

- None specified.

### reviewCriteria

- Load matches a goal
- Cost is compared to capacity
- The stress test was answered

### revisionRules

- Changing the load re-opens levels.scripting-save-state and audio.core-verb-sounds (voice)

### Evidence required

Decision only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [A Theory of Fun for Game Design - author page and 2003 slides](https://www.raphkoster.com/gaming/theoryoffun.shtml) — verified-source-text. Author page and hosted 2003 slides read; the book was not read cover to cover. Weak on fellowship, atmosphere and submission aesthetics. Games-are-not-stories claim is incomplete for presence-driven games.
- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.
- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.

## world-rules — World rules and constraints

### Creator questions

- **rules**: What are the world's readable rules: scale references (door, stair, human, vehicle), material language, technology level, what cannot exist?
- **constraints-for-art**: Which rules constrain characters and environments (silhouette language, palette, era) and which are free?
- **constraints-for-levels**: Which rules constrain spaces (no elevators, water is deadly, doors are rare) and become door-problem inputs?
- **bible-size**: What is the smallest bible that serves art and levels now? What is deliberately not written yet?

### inputs

- Narrative load
- Direction studies from Step 3

### activities

- Write rules as constraints, not lore volume
- Hand constraints to characters.identity-proportions and environments.world-rules-scale
- Keep the bible small and dated

### tools

- Atlas document editor
- Reference board

### skills

- game-world-design

### roles

- creator
- game-design-lead
- game-art-director

### outputs

- World-rules sheet with art and level constraints

### dependencies

- narrative-load

### reviewCriteria

- Every rule is usable by art or levels
- Scale references are concrete
- Volume is deferred with a reason

### revisionRules

- Changing a rule re-opens every character and environment identity document that cited it

### Evidence required

Constraints only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [An Approach to Holistic Level Design (GDC 2017)](https://www.youtube.com/watch?v=CpOoTAVeEcU) — source-claim. Talk description and transcript snippets only; not frame-reviewed. Lee flags a 3D action-adventure and immersive-sim bias. Not a 2D, puzzle or management-game process.
- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [Game Design: Theory & Practice (2nd edition) - author site](http://paranoidproductions.com/gamedesign/) — source-claim. Author site only; book not read. 2004 platform and live-ops chapters are historical. Risk of document-first culture if used before a prototype exists.

## story-structure — Story structure as pressure on verbs

### Creator questions

- **beats**: List the beats (development, conflict, climax, resolution or the structure you chose) and, for each, which verb it pressures and how.
- **player-agency**: Where does the player's choice change the story, where does it not, and how is that honest to the player?
- **systemic-fit**: If the game is systemic, which beats are special-case and which emerge from rules?
- **ending**: How does the game end (or refresh), and which goal the ending serves?

### inputs

- Narrative load
- Verb-object matrix
- World rules

### activities

- Write beats as pressure on verbs, not as cutscene volume
- Mark authored versus emergent beats
- Define the ending

### tools

- Beat board
- Atlas document editor

### skills

- game-world-design
- game-systems-design

### roles

- creator
- game-design-lead

### outputs

- Beat sheet mapped to verbs

### dependencies

- narrative-load
- world-rules

### reviewCriteria

- Every beat pressures a verb
- Agency is honest
- The ending exists

### revisionRules

- A cut verb re-opens the beats that pressured it
- A changed interaction model re-opens authored/emergent marks

### Evidence required

Beat sheet only; reader and player tests are recorded in narrative-playtest. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.
- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.
- [A Theory of Fun for Game Design - author page and 2003 slides](https://www.raphkoster.com/gaming/theoryoffun.shtml) — verified-source-text. Author page and hosted 2003 slides read; the book was not read cover to cover. Weak on fellowship, atmosphere and submission aesthetics. Games-are-not-stories claim is incomplete for presence-driven games.

## delivery-channels — Delivery channels and scripting weight

### Creator questions

- **channels**: Which channels deliver story: environment, item text, dialogue, voice, cinematics, UI, music? What share does each carry?
- **scripting-weight**: For dialogue, quests or cinematics: which scripting, branching and localization cost does each channel add to levels and technical work?
- **rework-risk**: When a level changes after story is placed, what gets rewritten? Which channels are cheapest to rework?
- **voice**: Voice acting: none, placeholder, final later? If final later, what is the placeholder rule?

### inputs

- Story structure
- Narrative load

### activities

- Assign shares per channel
- Estimate scripting and rework cost per channel
- Prefer cheap-to-rework channels while levels are unstable

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

- Delivery-channel plan with scripting weight

### dependencies

- story-structure

### reviewCriteria

- Channel shares sum to the load
- Rework risk is stated
- Voice policy is explicit

### revisionRules

- Changing a channel share re-opens levels.scripting-save-state and audio.core-verb-sounds

### Evidence required

Plan only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.
- [Game Design: Theory & Practice (2nd edition) - author site](http://paranoidproductions.com/gamedesign/) — source-claim. Author site only; book not read. 2004 platform and live-ops chapters are historical. Risk of document-first culture if used before a prototype exists.

## environmental-storytelling — Environmental storytelling plan

### Creator questions

- **applies**: Does the environment carry story? If the game has no spaces, mark not-applicable with that reason.
- **set-dressing-beats**: For each space, which beat or rule is shown by dressing, lighting or damage, with one sentence per space.
- **readability-check**: How will you test that players read the intended story from the space without text (playtest question list)?

### inputs

- World rules
- Delivery channels
- Space inventory

### activities

- Map beats to spaces
- Write the playtest question list
- Hand dressing beats to environments.set-dressing-assembly

### tools

- Atlas document editor

### skills

- game-world-design

### roles

- creator
- game-design-lead
- game-art-director

### outputs

- Space-to-beat map with playtest questions

### dependencies

- world-rules
- delivery-channels

### reviewCriteria

- Each space has at most a few beats
- The playtest questions are written before dressing starts

### revisionRules

- A removed space re-opens its beats
- A changed beat re-opens the dressing plan

### Evidence required

Plan only; player reading is recorded in narrative-playtest. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [An Approach to Holistic Level Design (GDC 2017)](https://www.youtube.com/watch?v=CpOoTAVeEcU) — source-claim. Talk description and transcript snippets only; not frame-reviewed. Lee flags a 3D action-adventure and immersive-sim bias. Not a 2D, puzzle or management-game process.
- [The Level Design Book - How to make a level](https://book.leveldesignbook.com/process/overview) — verified-source-text. Process page read. CC BY-NC-SA 4.0 living document, self-labelled under construction and shooter-weighted. Not authored by Steve Lee. Structure may change.

## narrative-playtest — Narrative read-through and player test

### Creator questions

- **read-through**: Who read or heard the beats (strangers preferred), and which beats landed, confused or bored, by their words?
- **in-play**: In a playable build, did players reconstruct the intended story? Ask them to retell it and record the gaps.
- **agency-felt**: Did players feel the choices mattered where they were meant to, and not where they were not?
- **next-change**: Which beat, channel or space changes next and why?

### inputs

- Beat sheet
- Delivery plan
- Playtest capture path

### activities

- Run a read-through and, when a build exists, a retell test
- Score beats by tester words
- Change beats or channels, not goals, unless the owner records a goal change

### tools

- Playtest log
- Beat board

### skills

- game-world-design
- game-quality-planning

### roles

- creator
- game-design-lead
- game-quality-lead

### outputs

- Narrative playtest entries

### dependencies

- story-structure
- delivery-channels

### reviewCriteria

- Testers are named by type
- Retell gaps are recorded verbatim
- Changes trace to gaps

### revisionRules

- Each session appends; earlier entries stand

### Evidence required

Actual sessions with tester type, build or draft version, retell text and stored notes or recording. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [A Game Design Vocabulary](https://www.oreilly.com/library/view/a-game-design/9780133155181) — source-claim. Publisher listings, sample pages and a 2015 practitioner review only; book not read. Less operational for large live economies.
