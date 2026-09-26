# Interface: readability, HUD, onboarding, states and accessibility

Generated from catalog 1.0.0.

Make the player perceive the intended design: readability channels with non-colour backups, HUD philosophy, first-session onboarding by doing, UI and perception failure states, accessibility scoping alongside the experience, and interface playtests with hypotheses.

Applicability: Every game with any visual or audio interface, including text games (readability of text, pacing, input affordances). Phases that assume a screen are adapted for audio-first games (audio cues as the interface). Accessibility scoping questions are answered for elements that exist; elements that do not exist are marked not-applicable with that reason.

Atlas stages: 3, 4, 6, 7, 9, 11. Canonical steps: 3, 4, 6, 7, 9, 11.

## readability-channels — Readability channels

### Creator questions

- **channels**: For interactable, danger, path, focus, ally and enemy: which visual channel marks it (shape, silhouette, motion, contrast, position) and which non-colour backup exists?
- **play-distance**: At the real play camera, resolution and device class, what is the minimum size or contrast at which each channel still reads?
- **consistency**: Which mappings must never change across the game (a shape that always means interactable), and which may vary by area?
- **test**: How will readability be tested with participants suited to the target experience, and what observation counts as pass? State recruitment limits.
- **audio-first-equivalent**: If audio is the primary interface, how do players orient, distinguish critical cues from narration/music, repeat information, know focus and recover from a missed cue? Specify timing, interruption rules, localization, and an alternate channel where feasible. Mark visual-only questions not applicable with a reason.

### inputs

- Direction studies
- Verb inventory
- Readability tokens from Step 6

### activities

- Assign channels with backups
- Set minimum sizes and contrasts per device class
- Plan the readability task

### tools

- Design tool
- Contrast checker

### skills

- game-art-pipeline
- ux-psychology-pro
- accessibility-audit

### roles

- creator
- game-art-director
- ux-director

### outputs

- Readability channel table with test plan

### dependencies

- None specified.

### reviewCriteria

- Every channel has a non-colour backup
- Minimums are per device class
- A test is planned
- For audio-first play, critical cues, navigation/focus, repetition and recovery have an explicit audio interaction plan; visual-only criteria are scoped with reasons.

### revisionRules

- An art-mode change re-opens channels
- A new faction or interactable class adds a row

### Evidence required

Table only; the outsider task result is recorded in interface-playtest. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.

## hud-philosophy — HUD and feedback philosophy

### Creator questions

- **hud**: Diegetic, minimal, full, or switchable? Which information must always be available and which may be hidden by option?
- **acknowledgement**: For the core verb and each audited decision: the visual, audio and haptic acknowledgement, and its timing.
- **cognitive-load**: At the busiest moment, how many things compete for attention, and which are dropped or delayed?
- **input-prompts**: How are inputs prompted per device (glyphs, remapping display), and how are remaps reflected?
- **audio-first-equivalent**: If audio is the primary interface, how do players orient, distinguish critical cues from narration/music, repeat information, know focus and recover from a missed cue? Specify timing, interruption rules, localization, and an alternate channel where feasible. Mark visual-only questions not applicable with a reason.

### inputs

- UX brief
- Feedback language
- Feel specification

### activities

- Choose the HUD stance
- Specify acknowledgements with timing
- Audit the busiest moment

### tools

- Design tool

### skills

- game-art-pipeline
- ux-psychology-pro

### roles

- creator
- game-design-lead
- ux-director

### outputs

- HUD and feedback specification

### dependencies

- readability-channels

### reviewCriteria

- Every decision is acknowledged
- Busiest moment is audited
- Remaps are reflected in prompts
- For audio-first play, critical cues, navigation/focus, repetition and recovery have an explicit audio interaction plan; visual-only criteria are scoped with reasons.

### revisionRules

- A new decision adds an acknowledgement
- A device class change re-opens prompts

### Evidence required

Specification only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.

## onboarding-first-session — Onboarding and first session

### Creator questions

- **first-minutes**: Minute by minute for the first ten minutes: what the player does, what they learn, and what is deliberately withheld.
- **no-text-dump**: Where would a designer be tempted to add a text dump, and what replaces it?
- **skip-and-return**: Can returning or expert players skip or shorten onboarding without losing required knowledge?
- **teach-test**: Choose an onboarding experiment that respects the target input and accessibility needs. If teaching without tutorial text is the hypothesis, explain why and what behavior means pass.

### inputs

- First-session journey
- Verb first-teach map
- Teaching reports from levels

### activities

- Script the first session
- Replace text dumps with doing
- Plan the experiment

### tools

- Atlas document editor

### skills

- game-discovery
- ux-psychology-pro

### roles

- creator
- game-design-lead

### outputs

- First-session script with the teach experiment plan

### dependencies

- hud-philosophy

### reviewCriteria

- Every verb is taught by doing
- Skip path exists
- Experiment is planned

### revisionRules

- A new first-time verb re-opens the script

### Evidence required

Plan; the experiment result is recorded in interface-playtest. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).

## ui-perception-states — UI and perception failure states

### Creator questions

- **ui-states**: Standard UI states (empty, loading, error, disconnected, paused) with recovery and announcement for each screen or overlay.
- **perception-states**: 'Cannot parse the space', 'cannot read the UI', 'cannot hear the cue': how each is detected or self-declared, and what the game offers (contrast mode, text size, visual cue for audio, slow mode).
- **motion**: Motion and camera comfort states (motion sickness, screen shake off, field-of-view options) and their defaults.
- **announcements**: Which state changes are announced to screen readers or narration where supported?
- **audio-first-equivalent**: If audio is the primary interface, how do players orient, distinguish critical cues from narration/music, repeat information, know focus and recover from a missed cue? Specify timing, interruption rules, localization, and an alternate channel where feasible. Mark visual-only questions not applicable with a reason.

### inputs

- State spec
- Readability table
- Audio bus plan

### activities

- List states with recovery
- Design perception fallbacks
- Set motion defaults

### tools

- Atlas document editor

### skills

- accessibility-audit
- game-quality-planning

### roles

- creator
- ux-director
- game-quality-lead

### outputs

- UI and perception state table

### dependencies

- readability-channels
- hud-philosophy

### reviewCriteria

- Every state has recovery and announcement
- Perception fallbacks exist
- Motion defaults are stated
- For audio-first play, critical cues, navigation/focus, repetition and recovery have an explicit audio interaction plan; visual-only criteria are scoped with reasons.

### revisionRules

- A new screen adds states
- A new audio cue needs a visual fallback

### Evidence required

Table only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.

## accessibility-scoping — Accessibility scoping and priorities

### Creator questions

- **elements**: Which elements does the game contain: timers, quick-time events, chat, motion, haptics, colour signals, small text, precise input, audio-only cues, flashing? For each present element, the guideline area it triggers.
- **experience-level**: Which accessibility features are part of the intended player experience from its first release, and which are deferred with rationale and a revisit condition?
- **design-bugs**: Which scoping answers reveal design bugs in the slice (colour-only signal, unreadable timer) rather than polish tickets?
- **tags**: Which store or platform accessibility tags could honestly be claimed once features exist, and which must not be claimed (for example 'playable without vision' when only menus are narrated)?
- **testing**: Who with lived experience or expertise will test, and when? If nobody yet, record the gap.

### inputs

- Experience-goal sheet
- Verb inventory
- Constraints from levels
- Distribution class

### activities

- Answer scoping questions for present elements only
- Sort features into v1-experience versus later
- Plan honest tags and expert testing

### tools

- Xbox Accessibility Guidelines scoping questions
- Steam accessibility feature list

### skills

- accessibility-audit
- game-quality-planning

### roles

- creator
- game-quality-lead
- game-design-lead

### outputs

- Accessibility scoping and priority table

### dependencies

- ui-perception-states

### reviewCriteria

- Only present elements are scoped
- Design bugs are routed to design, not polish
- Tags match planned features

### revisionRules

- A new element (timer, chat) re-opens scoping
- A removed feature removes its tag

### Evidence required

Scoping answers; expert or lived-experience test results are recorded in quality.accessibility-verification. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.
- [Xbox-GDK-Samples (including AccessibilitySample)](https://github.com/microsoft/Xbox-GDK-Samples) — verified-source-text. README and LICENSE read. Requires the October 2025 GDK; many creators will never compile it. Sample telemetry sends the executable name unless removed. Not a design method.

## interface-playtest — Interface playtests with hypotheses

### Creator questions

- **hypotheses**: Which hypotheses were tested (players find interactables within N seconds; players learn verb X without text; players notice danger cue Y)?
- **who**: Who played (strangers preferred), how many, on which device class and build?
- **results**: Per hypothesis: pass, fail, or inconclusive, with the behaviour or measurement observed.
- **bus-mute**: If audio cues exist: with music muted, then SFX muted, then voice muted, which critical cues were lost?
- **next-change**: Which channel, prompt or onboarding beat changes next?

### inputs

- Readability test plan
- Teach experiment plan
- Perception states
- Playtest capture path

### activities

- Run the selected readability, onboarding and audio-isolation experiments with suitable participants; distinguish self-tests from independent evidence
- Record per-hypothesis results
- Change the interface, not the goal

### tools

- Playtest log
- Recording

### skills

- game-quality-planning
- ux-psychology-pro

### roles

- creator
- game-quality-lead
- ux-director

### outputs

- Interface playtest entries

### dependencies

- onboarding-first-session
- readability-channels

### reviewCriteria

- Hypotheses were stated before the session
- Results are behaviours or measurements
- Tester type and device are named

### revisionRules

- Each session appends
- A failed hypothesis re-opens its channel or beat

### Evidence required

Actual session records with build id, device class, tester type, per-hypothesis observation and stored recording or notes. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
