# Audio: role, buses, core sounds, adaptive music, provenance and validation

Generated from catalog 1.0.0.

Treat audio as an interactive system with buses, states and budgets: decide its role, design the bus architecture, put core-verb sounds into the feel prototype, plan adaptive music only after the loop's emotional arc is known, record provenance and loudness, and validate in engine.

Applicability: Every game with sound, including audio-first games where audio is the primary interface. Silent games mark the workflow not-applicable with that reason. Adaptive music applies only when music must follow gameplay state; a fixed soundtrack marks it not-applicable. Middleware choice is a technical decision that stays open until the creator answers; native engine audio is a valid answer.

Atlas stages: 1, 3, 6, 7, 8, 10, 11. Canonical steps: 1, 3, 6, 7, 8, 10, 11.

## audio-role — Audio role and constraints

### Creator questions

- **role**: What does audio do for this game: feedback for the core verb, danger and navigation cues, mood, narrative voice, the primary interface (audio-first), or minimal? Which goal each role serves.
- **must-hear**: Which cues must be heard to play fairly, and which visual fallback each has?
- **constraints**: Platform loudness targets, memory budget, headphone versus speaker assumptions, and whether players can mute categories.
- **middleware**: Native engine audio, middleware, or undecided with a revisit condition? What complexity drives the choice?

### inputs

- Experience-goal sheet
- Feedback language
- Accessibility scoping

### activities

- Define roles per goal
- List must-hear cues with fallbacks
- Record constraints and the middleware decision state

### tools

- Atlas document editor

### skills

- game-audio-design

### roles

- creator
- game-design-lead

### outputs

- Audio role sheet

### dependencies

- None specified.

### reviewCriteria

- Every role serves a goal
- Must-hear cues have fallbacks
- Middleware is decided or explicitly open

### revisionRules

- A goal change re-opens roles
- A must-hear cue added in a level needs a fallback

### Evidence required

Sheet only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Gamer's Brain - GDC talks and book record](https://www.youtube.com/watch?v=XIpDLa585ao) — source-claim. Talk metadata and transcript snippets; not frame-reviewed. Books not read. Neuroscience framing can be over-claimed if used as authority rather than as testable guidelines. Fortnite-scale UX org does not transfer to solo.
- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.

## bus-architecture — Bus architecture and mix rules

### Creator questions

- **buses**: Which buses exist (music, critical SFX, ambient, voice, narration, chat, UI) and which cue lives on which? Critical cues must not share a bus with music.
- **ducking**: Which buses duck which (voice over music, critical over ambient) and by how much?
- **player-control**: Which buses the player can control separately, and the defaults.
- **fail-soft**: What happens when a bank or file is missing or fails to load: silence with a log, fallback cue, or block? Never a crash.
- **peak**: How is clipping prevented at the loudest moment (limiter, headroom target)?

### inputs

- Audio role sheet
- State spec audio states

### activities

- Design buses and routing
- Define ducking and player controls
- Define fail-soft

### tools

- Engine mixer or middleware design

### skills

- game-audio-design
- game-technical-production

### roles

- creator
- game-technical-director

### outputs

- Bus and mix specification

### dependencies

- audio-role

### reviewCriteria

- No critical cue shares a bus with music
- Player controls exist per bus
- Fail-soft is defined

### revisionRules

- A new cue class needs a bus
- A platform change re-opens loudness targets

### Evidence required

Specification only; the bus-mute experiment result lives in interface-playtest or audio-validation. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.
- [GDC 2014 - Guy Whitmore interactive music slides (archive.org)](https://archive.org/download/GDC2014Whitmore/GDC2014-Whitmore.pdf) — source-claim. Slide deck present on archive.org; the talk was not watched and the deck was only located, not studied page by page, by the research seat. Middleware manuals (FMOD, Wwise, MetaSounds) were not inspected.

## core-verb-sounds — Core-verb sounds in the feel prototype

### Creator questions

- **set**: Which sounds belong to the feel prototype now: footstep or movement, confirm, fail, hit, pickup, door, UI select? Placeholder is fine; list what is placeholder.
- **timing**: Sound onset relative to input and to animation contact (for example hit sound on the contact frame), within the timing tokens.
- **event-names**: Event names matching the contact states so implementation and animation agree.
- **voice-placeholder**: If voice exists: placeholder policy (text-to-speech, scratch recordings) and what marks it as placeholder.

### inputs

- Feel specification
- Contact-state inventory
- Bus specification

### activities

- Name events per contact state
- Set onset timing
- Put placeholders into the feel prototype

### tools

- Any audio editor
- Engine event system

### skills

- game-audio-design

### roles

- creator
- game-design-lead

### outputs

- Core-verb sound event list with timing

### dependencies

- bus-architecture

### reviewCriteria

- Every contact state has an event name
- Onset timing is specified
- Placeholders are marked

### revisionRules

- A new contact state adds an event
- A timing token change re-opens onsets

### Evidence required

The event list; whether the sounds improved feel is recorded in the feel-track playtest. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Game Feel: A Game Designer's Guide to Virtual Sensation](https://www.taylorfrancis.com/books/mono/10.1201/9781482267334/game-feel-steve-swink) — source-claim. Publisher pages and Library of Congress table of contents only; book body not read. Does not apply cleanly to turn-based, menu-driven or non-spatial games. 2008 input-hardware examples.
- [Lyra Sample Game in Unreal Engine](https://docs.unrealengine.com/lyra-sample-game-in-unreal-engine) — verified-source-text. Official docs extract. Unreal-specific. Sample version may lag engine (see G-UE-LYRA-VERSION). Full sample license not read.
- [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) — verified-source-text. README and LICENSE read. Demos are slices, not a production pipeline. Web builds are slower than native and not a ship oracle.

## adaptive-music-plan — Adaptive music plan

### Creator questions

- **applies**: Must music follow gameplay state? If a fixed soundtrack or no music, mark not-applicable with that reason.
- **states**: Which gameplay states drive music (calm, alert, combat, victory, loss), and which parameters modulate within a state?
- **transitions**: How do phrases transition (on beat, on bar, crossfade, stinger), and what is the maximum acceptable delay for a state change to be heard?
- **scope**: How many cues, layers or stems for the vertical slice, and what waits for the full arc?

### inputs

- Tuning loop result (emotional arc known)
- Bus specification
- Progression model

### activities

- Map music states to gameplay states
- Define transition rules
- Scope the slice

### tools

- Middleware or engine music system design
- Diagram tool

### skills

- game-audio-design

### roles

- creator
- game-design-lead

### outputs

- Adaptive music state graph

### dependencies

- core-verb-sounds

### reviewCriteria

- Applies or not-applicable with a reason
- States map to gameplay
- Transition delay is a number

### revisionRules

- A new gameplay state adds a music state
- A revoked proven-loop declaration pauses full-score work

### Evidence required

Graph only; in-game transition timing is measured in audio-validation. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [GDC 2014 - Guy Whitmore interactive music slides (archive.org)](https://archive.org/download/GDC2014Whitmore/GDC2014-Whitmore.pdf) — source-claim. Slide deck present on archive.org; the talk was not watched and the deck was only located, not studied page by page, by the research seat. Middleware manuals (FMOD, Wwise, MetaSounds) were not inspected.
- [A Theory of Fun for Game Design - author page and 2003 slides](https://www.raphkoster.com/gaming/theoryoffun.shtml) — verified-source-text. Author page and hosted 2003 slides read; the book was not read cover to cover. Weak on fellowship, atmosphere and submission aesthetics. Games-are-not-stories claim is incomplete for presence-driven games.

## asset-provenance-loudness — Audio asset provenance and loudness

### Creator questions

- **sources**: Per asset: recorded, synthesized, licensed pack, commissioned, generated (which tool and prompt)? License terms and whether they allow the target stores and any monetized use.
- **loudness**: Integrated loudness and peak per asset class against the project target; sample rate and format.
- **memory**: Uncompressed versus cooked size per bank and the total against budget.
- **naming**: Naming convention that matches event names.

### inputs

- Event list
- Music plan
- Sidecar schema

### activities

- Fill the provenance sidecar per asset
- Measure loudness
- Track bank sizes

### tools

- Loudness meter
- Spreadsheet

### skills

- game-audio-design
- game-technical-production

### roles

- creator
- game-technical-director

### outputs

- Audio asset manifest with provenance and loudness

### dependencies

- core-verb-sounds

### reviewCriteria

- Every asset has a license entry
- Loudness measured, not assumed
- Total size within budget or exception recorded

### revisionRules

- A monetization change re-checks licenses
- A budget change re-opens sizes

### Evidence required

The manifest with measured numbers. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [ADR 0006: Blender master-asset pipeline (lxsolutions/studio-foundation)](https://github.com/lxsolutions/studio-foundation/blob/main/docs/adr/0006-blender-master-asset-pipeline.md) — source-claim. One company's ADR, not Blender Studio and not this repository's engine choice. Useful as a contrast and a sidecar field list.
- [Accessibility Features (Steamworks Documentation)](https://partner.steamgames.com/doc/accessibility_features) — verified-source-text. Docs read. Tags are communication after features exist, not a design method. Wizard answers can be gamed. ESA Accessible Games Initiative tags may change the landscape.

## audio-validation — Audio validation in engine

### Creator questions

- **events-fire**: Did every event fire on its contact state in engine, with onset within tolerance? Which failed?
- **bus-mute**: With each bus muted in turn, which critical cues were lost? Any critical cue on the wrong bus?
- **music-transitions**: Measured delay from state change to audible transition versus the target.
- **peak**: Peak level at the loudest scripted moment; any clipping?
- **fail-soft**: With a bank removed, did the game continue with a logged fallback?
- **cpu**: Audio thread or mixer cost on the target hardware class.

### inputs

- Bus specification
- Event list
- Music graph
- Pinned engine

### activities

- Run event, bus-mute, transition, peak, fail-soft and cost checks in engine
- Record failures by event name

### tools

- Engine audio debugger or middleware profiler
- Recording

### skills

- game-audio-design
- game-quality-planning

### roles

- game-technical-director
- game-quality-lead
- creator

### outputs

- Audio receipt

### dependencies

- bus-architecture
- core-verb-sounds
- asset-provenance-loudness

### reviewCriteria

- Every check has a result
- Failures name the event
- Hardware class is stated

### revisionRules

- An engine or middleware change re-runs the receipt
- A new event adds a check

### Evidence required

Receipt files: engine logs, recordings of the mute passes, measured delays and peaks, profiler sample. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Xbox Accessibility Guidelines V3.2](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines) — verified-source-text. Official Learn page read (v3.2 published 2023-06-08; page updated 2026-08). Xbox-example-heavy. Explicitly not a legal compliance checklist. Not every guideline body was fully read.
- [GDC 2014 - Guy Whitmore interactive music slides (archive.org)](https://archive.org/download/GDC2014Whitmore/GDC2014-Whitmore.pdf) — source-claim. Slide deck present on archive.org; the talk was not watched and the deck was only located, not studied page by page, by the research seat. Middleware manuals (FMOD, Wwise, MetaSounds) were not inspected.
- [Play mode and Editor profile samples (Unity)](http://docs.unity3d.com/Documentation/Components/profiler-play-edit-samples.html) — verified-source-text. Official docs extract; older docs host, newer manuals may differ.
