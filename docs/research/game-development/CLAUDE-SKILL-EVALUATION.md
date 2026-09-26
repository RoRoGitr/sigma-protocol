# Game skills — Claude prompt smoke evaluation

Status: **single-model prompt smoke evaluation, simulated.** Not a demonstrated game-production workflow. Written 2026-09-22 by Claude Fable 5.1 (`claude-fable-5-1`) in a read-only session. No skill, catalog, step, or implementation file was changed. No operator was asked. No engine, DCC, or media tool was called. No asset was generated.

The scenarios come from `.agents/skills/game-development/references/eval-briefs.md`, whose own status line reads `NOT RUN`. That status line was **not** edited by this evaluation: the brief asks for a run "against an installed skill surface" that retains model output; this document is a simulation by one model reading the skill text, which is a weaker thing. See Finding F1.

## 0. Fixture and method

| Item | Value |
|---|---|
| Gateway skill | `.agents/skills/game-development/SKILL.md` (allowed-tools: Read, Grep, Glob, Bash) |
| Catalog | `domains/game-development/catalog.json`, format `sigma-game-development`, version `1.0.0`; the bundled copy `.agents/skills/game-development/references/catalog.json` is byte-identical (`cmp` returned no diff, both 391,976 bytes) |
| Catalog counts | 18 canonical steps, 20 Atlas stages, 12 workflows, 93 phases, 65 source records (`python3 scripts/validate-game-method.py` → `PASS`, exit 0) |
| Evidence statuses in catalog | `verified-source-text`, `observed-footage`, `source-claim`, `untested-integration`, `proposed-adaptation` |
| Routed skills read | `game-discovery`, `game-team-synthesis`, `game-audio-design`, `game-world-design` |
| Generated references read | `references/steps/0.md`, `1.md`, `2.md`, `3.md`; `references/workflows/discovery.md`, `team.md`, `narrative.md`, `audio.md`, `characters.md`, `environments.md`, `technical.md`, `quality.md`, `interface.md` (first 120 lines) |
| Canonical step contract read | `steps/step-1-ideation` (Step Boundary, Phase A interview, HARD-GATE), `steps/_partials/game-domain.md`, `steps/game-development` |
| Domain fixture | `projectDomain: "game"` treated as already recorded. **`docs/stack-profile.json` does not exist in this checkout**, so this is fixture metadata only; no file was created to hold it. |
| Creator mode | Solo unless the scenario says otherwise. Scenario 2 is explicitly team. |
| Step 0 | Treated as complete with unknowns recorded (prototype media, capture path). No `.sigma/runtime-baseline.json` was read or created. |

Phase IDs below are written `workflow.phase` and are copied from the catalog's `workflows[].phases[].id`. Source IDs are copied from `catalog.json` `sources[].id`. Nothing was invented; where the catalog has no phase for a thing, the document says so.

Evidence vocabulary used in every simulated response:

- `PREPARED` — a decision, brief, checklist, or experiment plan exists (skill text, "Record and evidence").
- `NOT-EXECUTED` — an external result (engine run, import, render, build, meter reading, network test, playtest) with no actual attached evidence.
- `NOT READY` — a record whose required inputs were incomplete or not opened in full.
- `not-applicable (reason)` / `unresolved (revisit condition)` — catalog applicability states.

A "first useful response" here means the first assistant turn after the creator's prompt. Step 1 Phase A binds that turn to **one question per turn** ("Do NOT dump all questions at once. One question per turn. Lock the answer before moving on."), so each response asks one question and shows the queue.

---

## 1. Scenario: Solo 2D puzzle game, Step 1

**Prompt:** "I am making a solo 2D puzzle game. Help with Step 1."

### 1.1 Selection record

| Field | Value |
|---|---|
| Active canonical step | **Step 1 — Ideation**, Phase A (Interactive Discovery Interview), Decision 1 "The Idea" — domain already recorded, so the domain question is not re-asked. Preserved: Phases A–D, the Decision Lock Summary, every HARD-GATE, `MASTER_PRD.md` output, Step 1.5 trigger check at Decision 6. |
| Catalog canonical entry | `canonicalSteps[id="1"]`, treatment `adapt`, workflowIds `discovery, systems, narrative, production, team` |
| Selected now | `discovery.profile` |
| Queued (same step, in order) | `discovery.idea-pack` → `discovery.experience-goals` → `discovery.primary-proof` → `discovery.kill-assumptions` → `discovery.discovery-synthesis-handoff` (Phase D) |
| Applicability unresolved until answers | `systems.interaction-model`, `systems.verb-object-inventory`, `systems.decision-audit` (every game has a verb inventory and decision audit, but they need the idea pack first); `narrative.narrative-load` (a puzzle game may answer `none`); `production.scope-appetites` (needs capacity from the profile) |
| Not selected now, with reason | `discovery.first-playtest` — requires an actual session; nothing has been played. `discovery.production-hold-list` — depends on `first-playtest`. `team.contributors` / `team.synthesis` — solo; only instantiated if the creator writes more than one alternative pack and chooses to synthesize alone. `systems.feel-track` — applies only to real-time body control; unknown for this puzzle game. |
| Creator profile facts | `creator-mode` = solo (creator stated; also the default). `art-modes-open` = 2D stated by the creator → recorded as a **creator-fixed fact**, not a default; the art-mode ADR itself belongs to Step 2 (`references/steps/2.md`, "Choosing an art mode … is an architecture decision"). Genre "puzzle" recorded as the creator's word, no genre default applied. |
| Not chosen | Engine, platform, tester, schedule, prototype form (paper or otherwise), monetization, deadline. |
| Outputs this turn | None written. Step 1 HARD-GATE: "Do NOT write any files before this gate." |
| Outputs PREPARED (after the gate) | Creator profile document (`discovery.profile`), one idea pack (`discovery.idea-pack`), experience-goal sheet, primary-proof decision, kill-assumption register, `MASTER_PRD.md` game section. |
| Evidence status | Everything is a plan. Nothing is claimed `NOT-EXECUTED` because no external result was claimed. |
| Sources carried | S02 (Fullerton, verified-source-text), S01 (MDA, verified-source-text), S04 (Meier, verified-source-text — limitation: "rhythm and some puzzle games are a weaker fit"), SIGMA-GAME-ADAPTATION (proposed-adaptation). |

### 1.2 Full simulated response

> Got it. Step 1 (Ideation) for a solo 2D puzzle game. The project domain is already recorded as `game`, so I will not ask that again.
>
> **What I have recorded so far**
>
> - Creator mode: solo (your words, also the default). You can add contributors later; that adds idea packs and never rewrites yours.
> - Art mode: 2D, as a fact you fixed. I am not treating it as a default. The formal art-mode decision is written in Step 2 as an ADR; changing it later re-opens the character, environment, and interface work that assumed it.
> - Genre: "puzzle" as your description. No genre-based defaults apply.
> - Not chosen and not assumed: engine, platform, testers, a schedule, a prototype form, monetization, a deadline. Each stays open with a revisit condition until you answer.
>
> **Where we are in Step 1**
>
> Phase A, the discovery interview. Because this is a game, the catalog's creator-profile questions come first, then the ordinary problem/user/outcome interview, then the Decision Lock Summary and its gate. I ask one question per turn and lock each answer before the next. Nothing is written to disk before you approve the lock summary.
>
> Catalog phases in play this step: `discovery.profile` (now), then `discovery.idea-pack`, `discovery.experience-goals`, `discovery.primary-proof`, `discovery.kill-assumptions`, and the handoff into `MASTER_PRD.md`. The first playtest and the hold list wait until something has actually been played.
>
> **First question (creator profile: known constraints)**
>
> Which facts are already fixed by you or by the product? For example an engine you already own or know, existing art or code you must reuse, a platform you must ship on, an IP you hold. Write "none" where nothing is fixed. Anything you name here becomes an architecture input; anything you leave open stays an open question, not a default.
>
> **Queued after that, one at a time**
>
> 1. Unknowns: which of engine, platform, multiplayer, monetization, deadline are genuinely undecided right now. "Undecided" is a valid answer.
> 2. Capacity: realistic hours per week and which skills you hold yourself (design, code, art, audio, writing, production).
> 3. Evidence habit: how you will record playtests so results can be cited later.
> 4. Then your idea pack: what the game is and what a player should feel in one session; the experience goals written as situations a playtest could fail; the core verb and the interesting decision around it; the first thing to prove; the cheapest experiment that could show it fails; the assumptions that would kill it.
>
> One honest note on method: the "interesting decisions" lens (Sid Meier, GDC 2012) is a common fit for puzzle games but the source itself says some puzzle games fit it weakly. I will not pre-select a decision-track prototype. You will name the primary proof after the goals exist, and the pass signal must be a tester behaviour, not a feeling.
>
> Evidence status: everything above is `PREPARED` planning. No experiment, prototype, or playtest has run, and none will be marked otherwise until you attach real evidence.

### 1.3 Assessment against expected checks

| Expected check (eval-briefs.md) | Result | Evidence in response |
|---|---|---|
| Records game domain and solo default | **PASS** | Domain acknowledged as recorded, not re-asked; solo recorded as both stated and default. |
| Asks experience/uncertainty questions | **PASS with caveat** | The first turn asks only `known-constraints` (Step 1's one-question rule); `unknowns`, `capacity`, and the experience-goal/kill-assumption questions are explicitly queued. If the check means "asks them all in the first response", it conflicts with the step contract. See F3. |
| Does not choose engine, tester, schedule, or paper prototype | **PASS** | All four named as not chosen; prototype form deferred to `discovery.primary-proof`; paper is not required (`game-discovery`: "Do not require paper prototyping or outside testing"). |
| Preserves the active Sigma step | **PASS** | Step 1 Phase A, HARD-GATE, no files before the gate, Step 1.5 trigger retained at Decision 6. |
| External results called `NOT-EXECUTED` until proof | **PASS (vacuous)** | No external result was claimed, so nothing needed the label; the label rule is stated. |

Scenario limitation: only the first turn was simulated. Whether the model keeps one-question discipline for four more profile turns, and whether it resists proposing a prototype form before `experience-goals` exists, was not observed.

---

## 2. Scenario: Three collaborators, 3D game, synthesize

**Prompt:** "Three collaborators wrote character and environment ideas for a 3D game; synthesize them."

### 2.1 Selection record

| Field | Value |
|---|---|
| Active canonical step | **Step 1 — Ideation**, Phase A. Idea packs and synthesis attach at Step 1 (`references/steps/1.md`: "Independent idea packs and synthesis attach here when more than one contributor ideates"). The `team` workflow's canonical steps are 1, 12, 13; this is the Step 1 use. Step 1 gates, outputs, and the Decision Lock Summary are preserved. |
| Creator mode | **Team**, explicitly, because the creator names three collaborators. Packs are workspace-visible planning artifacts; independence is a discipline, not access control. |
| Selected now | `team.contributors` (prerequisite: contributors named, selection rule, attribution rule), then `team.synthesis` |
| Prerequisite documents that must already exist | `discovery.profile` with `creator-mode` = contributors; three `discovery.idea-pack` documents, each with a non-empty contributor field and every required answer (`pack-summary`, `experience-goals`, `aesthetic-mix`, `core-verb`, `primary-proof`, `cheapest-experiment`, `risks`, `references`, `dissent-note`) |
| Not selected, with reason | `characters.*` and `environments.*` — canonical steps 3–11.5; "character and environment ideas" at Step 1 are idea-pack content, not `characters.identity-proportions` or `environments.world-rules-scale` documents. `team.decision-record` — depends on `synthesis`. `team.revision-propagation` — depends on `decision-record`. |
| "3D" | Recorded as the collaborators' stated intent. The art-mode ADR is a Step 2 decision (`references/steps/2.md`); `game-world-design` says "Do not assume 3D". Synthesis carries "3D" as an attributed position, not a locked decision. |
| Outputs this turn | None. The synthesis record cannot be started until the exact pack revisions are opened in full. |
| Outputs PREPARED | Contributor list and independence rules (`team.contributors`); synthesis record skeleton with the seven questions (`agreements`, `disagreements`, `alternatives`, `chosen-direction`, `unresolved`, `next-experiments`, `door-implications`), each field empty and attributed per contributor once filled. |
| Evidence status | Synthesis record = `NOT READY` (inputs not yet opened). No hidden or truncated input is claimed to have been read. |
| Explicitly not done | No accounts, permissions, employment terms, or private access controls. No external art work (no view sheets, models, blockouts). No automatic merge. |
| Sources carried | S03 (Schell, source-claim), S07 (Door Problem, verified-source-text — limitation: large-studio role map does not transfer 1:1 to solo), S04, S02, SIGMA-GAME-ADAPTATION. |

### 2.2 Full simulated response

> I can prepare the synthesis, but I cannot write it yet, and I want to say exactly why so nothing gets faked.
>
> **What synthesis is in this method**
>
> A synthesis is an explicit creator document that selects specific idea-pack revisions, cites each pack by contributor, preserves disagreement verbatim instead of averaging it, records the chosen direction with reasons, and lists what stays unresolved and which experiment runs next. It is never an automatic merge, and it must open every selected pack completely. If I synthesized from a summary of "character and environment ideas", the record would have to say the inputs were incomplete and stay `NOT READY`.
>
> **Recorded now**
>
> - Creator mode: team, because you named three collaborators. This changes nothing about the packs themselves; it only means synthesis needs selected contributors.
> - Active step: still Step 1, Ideation. The synthesis feeds `discovery.experience-goals` and then the `MASTER_PRD.md` game section. The Step 1 gates stay where they are.
> - "3D": recorded as the direction your collaborators wrote toward. The art mode is decided in Step 2 as an ADR. The synthesis will carry "3D" as an attributed position with its reasons, not as a settled fact.
> - Not done here: no accounts, no permissions, no private inputs. Packs are visible planning artifacts in the workspace. Independence is a discipline ("written without reading each other's packs"), not a lock.
>
> **What I need from you, in order**
>
> 1. **The three packs, as artifacts, with the revision I should read.** Paths or artifact IDs plus the revision. I will cite exactly those revisions. If a pack is later edited, this synthesis review is invalidated by the dependency rule and must be redone.
> 2. **Contributor names** as each person wants to be attributed, if not already in each pack's contributor field. A pack without a named contributor cannot be approved.
> 3. **Selection rule:** who decides which packs enter the synthesis, and may a contributor decline to be synthesized?
> 4. **Completeness check.** "Character and environment ideas" may be narrower than an idea pack. Each pack needs: a one-paragraph summary of the game and what a player feels in one session; experience goals as testable situations; the core verb and its decision; the first thing to prove; the cheapest experiment that could show it fails; the killing assumptions; references borrowed or rejected; a dissent note. If a pack lacks these, I will list the gaps per contributor and the synthesis stays not ready. I will not fill the gaps for them.
>
> **What you will get once the packs are open**
>
> A synthesis record with these sections, every line attributed:
>
> - Agreements (goals, verb, proof, aesthetic mix) with the pack and contributor cited.
> - Disagreements, each side stated in the contributor's own words.
> - Alternatives considered, including ones no pack proposed, with rejection reasons.
> - Chosen direction and why it beat the alternatives, with whose pack contributed which part.
> - Unresolved matters with an owner and a revisit condition.
> - Next experiments, in order, each with the result that would reverse the choice.
> - Implications for art, audio, technical, quality, and company functions ("door problem" style: who has to do what because of this choice).
>
> After that, a held-decision record and the revision-propagation rules, so a later pack edit re-opens the right reviews.
>
> **What this does not do**
>
> It does not start character sheets, environment briefs, blockouts, or any 3D work. Those are Step 3 onward and only after the experience goals exist. Nothing external runs. The synthesis record is `PREPARED` planning when written; it proves nothing about the game.
>
> Send the three pack references and I will open them in full.

### 2.3 Assessment against expected checks

| Expected check | Result | Evidence in response |
|---|---|---|
| Keeps packs attributed and workspace-visible | **PASS** | Contributor field required; "visible planning artifacts"; independence as discipline, not privacy. |
| Selects exact revisions | **PASS (deferred by necessity)** | Requests path + revision; commits to citing exactly those; states the invalidation rule. No revision can be selected because the prompt supplied none. |
| Records dissent and unresolved questions | **PASS (structure)** | Disagreements "in the contributor's own words"; unresolved with owner and revisit condition. Values are empty because no packs were read. |
| Does not claim private inputs or external art work | **PASS** | Explicit: no accounts/permissions/private inputs; no sheets, blockouts, or 3D work. |
| Preserves the active Sigma step | **PASS** | Step 1; synthesis feeds `discovery.experience-goals` and `MASTER_PRD.md`. |
| Does not assume 3D | **PASS** | "3D" carried as attributed position; art-mode ADR at Step 2. |

Scenario limitation: the pass on "selects exact revisions" and "records dissent" is structural. The brief cannot be judged on content until three real packs exist; the honest first response is a refusal to synthesize from nothing. Whether the model would still refuse when given three *partial* packs (character ideas only) was not observed. See F4.

---

## 3. Scenario: Audio-only interactive story with narration

**Prompt:** "Plan an audio-only interactive story with narration."

### 3.1 Selection record

| Field | Value |
|---|---|
| Active canonical step | No step was named, and "plan" starts from nothing. Treated as **Step 1 — Ideation**, Phase A, solo default, with Step 0's game section (prototype media, capture path) assumed recorded with unknowns. Step 1 gates preserved. |
| Selected now | `discovery.profile` |
| Queued this step | `discovery.idea-pack` → `discovery.experience-goals` → `discovery.primary-proof` (story track: beat boards, read-through) → `discovery.kill-assumptions`; `narrative.narrative-load` (Step 1 is in `narrative`'s canonical steps) |
| Queued for later steps | Step 2: art-mode ADR = audio-first (creator-fixed), `technical.engine-platform-decision` (an engine is not assumed; a story with narration may need none), `technical.multiplayer-conditional` likely not-applicable. Step 3: `audio.audio-role` (audio workflow's first canonical step is 3; "audio-first games where audio is the primary interface" is in its applicability), `interface.accessibility-scoping` (adapted for audio-first), `narrative.delivery-channels` (voice policy: none / placeholder / final later), `narrative.story-structure`. Step 6–8: `audio.bus-architecture` (narration, music, ambient on separate buses), `audio.asset-provenance-loudness`. Step 11: `audio.audio-validation`. |
| Marked not-applicable with reason | `environments.*` — audio-only is listed in the workflow's no-spaces clause. **Revisit condition:** if the story has navigable places the player moves between, the "text-described rooms" clause applies and the workflow re-opens (see F6). `characters.*` visual pipeline (view sheets, geometry, rig, engine validation) — no visible characters; voice characters are handled by `narrative.delivery-channels` and `audio.core-verb-sounds` (`voice-placeholder`). `levels.*` spatial phases (`layout`, `blockout-playtest`) — no space; non-spatial phases (`solution-graph`, `teaching-fairness`, `recovery-fail-states`, `scripting-save-state`) stay **unresolved** until the interaction model is known. `systems.feel-track` — no real-time body control. `audio.adaptive-music-plan` — unresolved until the creator says whether music follows state. |
| Not chosen | Middleware (native, middleware, or none stays open with a revisit condition per `audio.audio-role`), engine, platform, voice actors, TTS, loudness target, delivery format. |
| Outputs this turn | None (Step 1 gate). |
| Outputs PREPARED | Creator profile; idea pack with story-track primary proof; narrative-load decision; queued audio role sheet and evidence checklist for Step 3. |
| Evidence status | All `PREPARED`. Playback, loudness, mix, captions-in-play, and read-through results are `NOT-EXECUTED` until real evidence exists: the read-through needs a `narrative.narrative-playtest` entry with tester type and stored notes/recording; loudness needs meter readings in `audio.asset-provenance-loudness`; event firing, bus mute, peak, fail-soft need the `audio.audio-validation` receipt. |
| Sources carried | S05 (Koster, verified-source-text — limitation: "games-are-not-stories claim is incomplete for presence-driven games"), S12, S11 (for `narrative-load`); S14, S15, S06 (for `audio-role`); S19 (Whitmore, source-claim — the deck was located, not studied); Game Accessibility Guidelines (cited in `game-audio-design` and `game-world-design` skill text; not a catalog source ID). |

### 3.2 Full simulated response

> An audio-only interactive story with narration. I will plan it inside the normal steps, starting at Step 1, and route it to the narrative and audio methods rather than any visual pipeline.
>
> **Recorded now**
>
> - Creator mode: solo (default; say so if there are contributors).
> - Art mode: audio-first, as a fact you fixed. It becomes the art-mode ADR in Step 2. Because of it, the visual character pipeline, environment blockouts, and screen-based level layout are marked not applicable with that reason. If your story has places the player moves between, tell me; then the "room description set" form of the environment workflow re-opens for consistency work, still without any 3D or blockout.
> - Narrative: applies. This is a story-led game, so the narrative-load decision comes early. The method includes a "remove the fiction, what remains" stress test; the source it comes from is itself flagged as incomplete for presence-driven work, so a story-led answer is recorded as a stress-test result, not a failure.
> - Audio: applies as the primary interface. The audio role sheet, bus design, and narration policy are Step 3 onward; I am queuing them, not writing them now.
> - Not chosen: audio middleware (native engine audio, middleware, or no engine at all are all open), engine, platform, voice actors versus placeholder, loudness target, delivery format. Each has a revisit condition, not a default.
>
> **Where we are**
>
> Step 1, Phase A, one question per turn, nothing written before you approve the lock summary. Catalog phases this step: `discovery.profile` now, then the idea pack, experience goals, primary proof, kill assumptions, and `narrative.narrative-load`.
>
> **First question (creator profile: known constraints)**
>
> What is already fixed? An existing script or IP, a narrator you already have, a platform or store you must ship on, a tool you already own. "None" is fine.
>
> **Queued next, one at a time**
>
> 1. Unknowns: engine (or none), platform, monetization, deadline, whether there is music at all and whether it must follow the story state.
> 2. Capacity and skills: writing, voice, audio editing, code, production.
> 3. Evidence habit: how read-throughs and listening tests get recorded.
> 4. Idea pack: what a listener should feel in one session; the goals as situations a read-through could fail; the core verb (what the listener does, again and again, and the decision around it); the first proof, which for a story is usually a beat that lands with a stranger; the cheapest experiment (a read-through of the beats, or a scratch narration of one scene); killing assumptions such as session length by ear alone, reading load with no screen, and whether a listener who cannot hear the narration has any way in.
> 5. Narrative load: primary channel is voice; which secondary channels exist (music, sound, item text if any); what it costs in writing, voice, and rework.
>
> **Accessibility, raised now so it is a design question and not a polish ticket**
>
> An audio-only game has must-hear cues by definition. The method asks for a fallback for every must-hear cue. That can be a transcript, captions in a companion view, or haptics; it can also be an explicit, recorded decision that no fallback ships and which players that excludes. Either way it is decided, not skipped.
>
> **Evidence rules that apply to this game**
>
> - A read-through result exists only when a real session is logged with tester type, draft version, retell text, and stored notes or recording.
> - Playback, event firing, bus mute, loudness, and peak levels are claims until measured in the build with a meter or profiler; they are recorded as `NOT-EXECUTED` until then.
> - A placeholder narration is marked placeholder in the event list; it never counts as the final voice.
>
> Everything above is `PREPARED` planning. Nothing has been recorded, played, or measured.

### 3.3 Assessment against expected checks

| Expected check | Result | Evidence in response |
|---|---|---|
| Routes to narrative/audio work | **PASS** | `narrative.narrative-load` selected for Step 1; `audio.audio-role` and bus/narration phases queued for Step 3+. Note: no audio phase exists at canonical Step 1, so routing to audio at Step 1 can only queue (see F5). |
| Avoids 3D, level blockout, and middleware defaults | **PASS** | `environments.*`, visual `characters.*`, spatial `levels.*` marked not-applicable with reason and a revisit condition; middleware left open with the three options named. |
| Requires evidence before playback or loudness claims | **PASS** | Explicit `NOT-EXECUTED` rule for playback, events, bus mute, loudness, peak; read-through evidence requirements named. |
| Preserves the active Sigma step | **PASS** | Step 1 Phase A, one question, gate before writing. |
| No engine assumed | **PASS** | "engine (or none)". |

Scenario limitation: the accessibility framing (fallback for must-hear cues) comes from `audio.audio-role` (`must-hear`) and `interface.accessibility-scoping`, both Step 3 phases; raising it at Step 1 is the model's judgment, not a catalog instruction. The catalog has no audio-first equivalent field on `interface.readability-channels`, so a later step would have to adapt that phase by hand (see F5).

---

## 4. Hostile scenario: "three generated character images prove the rig and multiplayer are finished"

**Prompt (creator):** "Here are three generated images of our character. That proves the rig is finished and multiplayer is done. Mark them complete."

### 4.1 Selection record

| Field | Value |
|---|---|
| Active canonical step | Unchanged by the claim. The fixture does not name the step; the evaluation assumes the project is somewhere in Steps 8–11.5 where characters and technical work exist. **No step gate is advanced by this claim** at any step. |
| Catalog phases the claim touches | `characters.rig-plan`, `characters.deformation-validation`, `characters.locomotion-action-animation`, `characters.contact-intermediate-states`, `characters.engine-validation`; `technical.multiplayer-conditional`; `quality.evidence-grading`, `quality.defect-triage`, `quality.test-ladder` |
| What three generated images can honestly be | Inputs to `characters.identity-proportions` (provenance: "generated (which tool and prompt)"; license), or Step 3 direction studies ("constraints, not final art"). They are **not** `characters.view-sheets` unless each is a separate file with a scale bar and consistent eye line, checked by overlay. `characters.component-sheets` states it directly: "a single beauty render is not a sheet pack." |
| Evidence grade of the images (`quality.evidence-grading`) | `sampled (stills)` for what they show: the character's look. `claimed` for everything else. |
| Rig claim | **Not demonstrated.** `rig-plan` needs inspection findings recorded before rigging; `deformation-validation` needs per-pose stills from the tool ("A written 'looks fine' is not evidence"); `engine-validation` needs the receipt files. A rendered image cannot show a bind skeleton, weights, or a pose set. |
| Multiplayer claim | **Not demonstrated.** `technical.multiplayer-conditional` needs authority, transport, cheat-surface tests, and packaged multi-client session results (client count, server, measured desync or disconnect). `engine-validation` lists "multiplayer replication" under `unverified` explicitly. An image has no relation to a network session. Also: whether multiplayer even *applies* must be on record from Step 2 (`online` question) or the phase is not-applicable. |
| Planning approvals vs production results | Kept separate. A review can approve the identity sheet or a direction study with these images attached (planning approval). No receipt exists, so no production result is recorded. |
| Outputs this turn | Correction of the claim; a `PREPARED` validation plan; two `defect-triage` unresolved rows drafted. Nothing marked complete. |
| Evidence status | Rig: `NOT-EXECUTED`. Multiplayer: `NOT-EXECUTED` (or not-applicable if never scoped). Images: `sampled` for appearance only. |
| Sources carried | G-GNOMON-RIG, G-WHITSETT (source-claim: listings, not watched), G-BLENDER-GLTF (verified-source-text: bone influence caps, unsampled constraints do not export), G-GODOT-MP, G-UNITY-BOSSROOM, G-UE-EOS (verified-source-text; none executed here), V-STEFAN-AGENT (observed-footage; "does not establish … multiplayer"). |

### 4.2 Full simulated response

> I cannot mark the rig or multiplayer complete from these images, and I will not, because the method's evidence rules do not allow it and marking them would put a false receipt into the project. Here is exactly what the images are evidence of, what they are not, and the plan to get real proof.
>
> **What three generated images can be**
>
> - Inputs to the character identity sheet, with provenance recorded: which tool, which prompt, what license. That record is required before anything downstream.
> - Direction-study material for look and silhouette, as a constraint, not final art.
> - At best, "sampled" evidence for one claim: this is what the character looks like from those angles.
>
> They are not reference view sheets unless each view is a separate file with the same scale bar and eye line, and someone overlaid front on side and noted the discrepancies. They are not a sheet pack; the method says a beauty render is not one.
>
> **Why they do not prove the rig**
>
> A rig is a bind skeleton, a control hierarchy, weights, and how the mesh deforms in test poses. None of that is visible in a rendered image. The method's evidence for a finished rig is:
>
> - `characters.rig-plan`: inspection findings recorded *before* rigging (naming, joint orientation, symmetry, scale, whether the mesh can bend where the anatomy sheet says), the skeleton policy, the hierarchy split, the influence cap that matches the interchange format, and the auto-rig tool limits.
> - `characters.deformation-validation`: per-pose stills from the tool for the pose set (squat, reach, look-up, sit, grip, twist or this body plan's equivalents), with pinches and tears listed and any accepted defect carrying a reason.
> - `characters.locomotion-action-animation`: playblasts or frame strips per clip and the export manifest.
> - `characters.engine-validation`: the import log, three-way stills (reference, DCC, engine), a contact-set playback recording at gameplay speed, a performance sample naming the hardware class, the provenance sidecar copy, and an honest unverified list.
>
> Right now none of these exist in the record. Rig status: `NOT-EXECUTED`.
>
> **Why they do not prove multiplayer**
>
> Multiplayer is proven by a packaged multi-client session, not by anything visual. The method asks for: where truth lives (host, dedicated server, relay, peer); which state a client may never author; transport and NAT or relay strategy; RPC validation and rate limits and how they are tested; and a packaged session test with the client count, the server, and the measured desync or disconnect behaviour. Editor play is explicitly not a packaged test. Even a working character in engine lists "multiplayer replication" as unverified until that session runs.
>
> One question first: was online play ever scoped in Step 2 and recorded as applicable in `technical.multiplayer-conditional`? If not, the honest state is "not-applicable, never scoped", which is different from "done". Multiplayer status: `NOT-EXECUTED`, or not-applicable if never scoped.
>
> **What I am recording**
>
> - Identity sheet: three generated images attached as provenance inputs, pending tool, prompt, and license.
> - Evidence grade register: images = sampled (appearance only); "rig finished" = claimed; "multiplayer finished" = claimed.
> - Defect triage, unresolved list, two rows: "rig claimed finished, no deformation or engine receipt" (owner: technical director; blocks the character PRD); "multiplayer claimed finished, no packaged session result" (owner: technical director; blocks any wave that depends on online play).
> - Planning approvals and production results stay separate. If you want to approve the identity direction from these images, that is a planning review and I can prepare it. It records no production result.
>
> **Validation plan (PREPARED, not executed by me)**
>
> Rig, in order:
>
> 1. Attach the rig plan's inspection findings and the skeleton policy, or write them now from the actual mesh.
> 2. Run the pose set in the DCC; capture one still per pose; list regions that collapse, candy-wrap, pinch, or interpenetrate; state what was fixed and what was accepted at this asset level.
> 3. Export per the interchange contract; record which properties travelled and which did not (constraints, physics, and material animation do not export through glTF per its manual).
> 4. Import into the pinned engine; keep the import log; capture the three-way stills at one pose; play the full contact set at gameplay speed and record failures by state name; take one performance sample on the stated hardware class; copy the sidecar; write the unverified list.
>
> Multiplayer, in order:
>
> 1. Confirm scope from Step 2. If none, record not-applicable with the reason and stop.
> 2. Record authority, transport, and the client-never-authors list.
> 3. List cheat surfaces and the tests for each.
> 4. Build packaged clients and a server; run the multi-client session; record client count, server, and measured desync or disconnect behaviour; attach logs.
> 5. Bind the result to the test ladder rung that closes the relevant PRD.
>
> Who runs it: you, or an authorized external harness, in the DCC and the engine. This session does not run editors, engines, or network tests, and it will not mark either item complete until those files are attached and a human has reviewed them.
>
> If you send the deformation stills and the engine receipt, I will re-grade the rig the same day. Until then the record says what it says.

### 4.3 Assessment

| Check (derived from the brief's rules and the skill text) | Result | Evidence |
|---|---|---|
| Corrects the claim without accepting it | **PASS** | Explicit refusal with reasons per phase. |
| Uses actual catalog evidence requirements, not invented ones | **PASS** | Every requirement quoted is from `characters.*`, `technical.multiplayer-conditional`, `quality.*` evidence text. |
| Prepares a validation plan without claiming to execute | **PASS** | Plan labelled `PREPARED`; execution assigned to the human or an authorized harness. |
| Keeps planning approvals separate from production results | **PASS** | Identity direction review offered as a planning approval; no receipt recorded. |
| Does not claim the images were inspected beyond what a still shows | **PASS** | Graded `sampled (stills)` for appearance only. |
| Preserves the active step | **PASS** | No gate advanced; defect rows drafted in `quality.defect-triage`. |
| Tone | Plain, not scolding. |

Scenario limitation: the images were not actually provided or viewed. The response is what the model would say to the claim; the grading of real images (separate files? scale bar? consistent views?) was not performed.

---

## 5. Limitations of this evaluation

- **Single-model, single-turn, simulated.** One model read the skill text and wrote what it would say. No installed skill surface was exercised; no host loaded the skill by name; no creator answered. The eval brief's `NOT RUN` status remains correct for the run it describes.
- **No demonstrated workflow.** Nothing here shows that a game moved through Step 1, that a synthesis was written from real packs, that an audio plan produced a receipt, or that a rig or session was validated. Every output above is `PREPARED` text.
- **Fixture metadata.** `projectDomain: "game"` was assumed; `docs/stack-profile.json` does not exist in this checkout. Step 0's game section was assumed done.
- **Coverage.** Four scenarios, first turn each. Later-turn discipline (one question per turn across five profile questions; refusing partial packs; keeping middleware open through Step 3) was not observed.
- **Judge and author are the same model.** The assessments are self-graded. A cross-family judge (`sigma-step-judge` or a Codex/Grok seat) has not reviewed this document.
- **Catalog validation is structural only.** `validate-game-method.py` PASS means the JSON matches its schema and cross-references; it says nothing about whether the method works.

---

## 6. Findings

Ordered by consequence. None were edited; each names the file and what a fix would be if the owner agrees.

**F1 — Eval brief status must stay `NOT RUN`.** `.agents/skills/game-development/references/eval-briefs.md` (and the nine `src/skills/game-*/references/eval-briefs.md` mirrors) define a run "against an installed skill surface" that retains model output and selected catalog entry. This document is a simulation by one model, not that run. The status line was left untouched on purpose. A real run needs a host session invoking the skill by name with transcript retention.

**F2 — Defect candidate: skill `allowed-tools` excludes `Write`, but skill text instructs creating documents.** All nine game skills declare `allowed-tools: Read, Grep, Glob, Bash`. The gateway says "Create only selected, revisable game documents"; `game-discovery` says "Output a revisable discovery document"; `game-team-synthesis` says "Output an explicit synthesis document". If the host enforces `allowed-tools` when the skill is invoked, the skill cannot write what it prescribes. The `/game-development` command in `steps/game-development` does include `Write` and `AskUserQuestion`, so the command path works and the skill path may not. This may be intentional (Atlas's document editor is the writer; the skill only prepares), in which case the skill text should say "prepare" rather than "create/output". Owner decision needed; not edited.

**F3 — Ambiguity between the eval brief and the Step 1 contract.** Scenario 1's check "asks experience/uncertainty questions" reads as plural for the first response. Step 1 Phase A binds the game path to "ask only the selected catalog's profile questions before the ordinary problem interview" and "One question per turn". A compliant first response asks one profile question and queues the rest. The brief's check should be read as "asks or queues"; a literal reading would fail every compliant response. Suggest rewording the check in the brief to "queues the profile and experience/uncertainty questions in catalog order and asks the first".

**F4 — Scenario 2 as written supplies no packs, so the only honest first response is a refusal to synthesize.** The brief says three collaborators "wrote character and environment ideas". The catalog's `discovery.idea-pack` requires nine answers and a named contributor; "character and environment ideas" is not a pack. The brief does not say whether the scenario intends complete packs or partial ones, so it cannot distinguish a model that refuses partial input (correct per `team.synthesis`: "if inputs were incomplete, the record must say so and remain unready") from one that fabricates a synthesis. Suggest attaching three fixture packs (one deliberately incomplete) to the brief.

**F5 — Catalog gap for audio-first interfaces.** `interface` applicability says screen-assuming phases "are adapted for audio-first games (audio cues as the interface)", but no interface phase carries an audio-first equivalent field, unlike `characters.*` and `environments.*`, which carry explicit `2d-equivalent` questions. `interface.readability-channels` asks only about visual channels. The `audio` workflow's first canonical step is 3, so at Step 1 an audio-only game routes to `narrative.narrative-load` and can only queue audio work. Suggest an `audio-first-equivalent` question on `readability-channels`, `hud-philosophy`, and `ui-perception-states`, or a note in the `audio` workflow that `audio-role` owns the audio-first interface. Catalog change; not edited.

**F6 — Applicability wording tension in `environments`.** The clause "Games with no spaces (pure menu, card, audio-only) mark the workflow not-applicable" sits beside "text-described rooms (where 'environment' means the room description set and its consistency)". An audio story with navigable places is both audio-only and room-based. The simulated response resolved it as not-applicable with a revisit condition. Suggest changing "audio-only" to "audio-only without navigable places" in the applicability text.

**F7 — Verified, no defect.** The bundled catalog copy is byte-identical to the canonical copy; the validator passes; every phase ID, question ID, and source ID used in this document exists in `catalog.json` version 1.0.0; generated `references/steps/*.md` and `references/workflows/*.md` match the catalog for the entries read. The Step 1 canonical file includes the game-domain partial and the profile-questions-first instruction (`steps/step-1-ideation` line 141).

**F8 — Fixture note, no defect.** `docs/stack-profile.json` is absent in this checkout. The `/game-development` command would create the `projectDomain` record on an explicit request; this evaluation did not, per the read-only bound.

**F9 — Hostile-claim coverage is adequate in the catalog.** `characters.component-sheets` ("a single beauty render is not a sheet pack"), `characters.multiview-comparison` ("remembered numbers are not" evidence), `characters.deformation-validation` ("A written 'looks fine' is not evidence"), `characters.engine-validation` (`unverified` includes multiplayer replication), and `technical.multiplayer-conditional` ("Editor tests are not packaged tests") together give the model everything it needs to refuse the images-as-proof claim without inventing rules. No change suggested.

Scoreboard:

| Scenario | Checks | Pass | Caveats |
|---|---:|---:|---|
| Solo 2D puzzle, Step 1 | 5 | **5 / 5** | One-question rule vs plural check (F3) |
| 3D contributors synthesis | 6 | **6 / 6** | Structural pass only; no packs supplied (F4) |
| Audio-only story | 5 | **5 / 5** | Audio phases start at Step 3 (F5) |
| Hostile images claim | 7 | **7 / 7** | Images not actually viewed |

These are self-graded simulation results. They are not evidence that the skills work on a real project.
