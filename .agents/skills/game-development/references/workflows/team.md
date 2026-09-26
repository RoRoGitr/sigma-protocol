# Team: contributors, explicit synthesis, decision record and revision propagation

Generated from catalog 1.0.0.

Let a solo creator or a small group ideate independently and converge explicitly: name contributors, synthesize selected idea packs with agreements, disagreements, alternatives, chosen direction and reasons, unresolved matters and next experiments, record decisions, and define how revisions propagate to dependent documents.

Applicability: Every game. Solo creators may write several alternative packs and synthesize them alone; team mode adds creator-selected contributors with no fixed team size or timebox. Synthesis must select at least one same-project idea-pack revision; the helper records source revisions and dependencies. Imported references never bind to foreign or missing records.

Atlas stages: 1, 12, 13, 15, 16. Canonical steps: 1, 12, 13.

## contributors — Contributors and independence rules

### Creator questions

- **who**: Who contributes idea packs (names or handles as they wish to be attributed)? Solo: yourself, possibly with alternative packs.
- **independence**: Rule that packs are written without reading each other's packs until synthesis; how that is honoured in a shared workspace (packs are visible, not private; independence is a discipline, not access control).
- **selection-rule**: Who selects which packs enter a synthesis, and can a contributor decline to be synthesized?
- **attribution**: How attribution and dissent are preserved in every downstream document.

### inputs

- Creator profile
- Role roster

### activities

- Name contributors
- State the independence discipline
- Set selection and attribution rules

### tools

- Atlas document editor

### skills

- game-team-synthesis

### roles

- creator
- game-design-lead

### outputs

- Contributor list and independence rules

### dependencies

- None specified.

### reviewCriteria

- Contributors are named
- Independence is a discipline, not a privacy claim
- Dissent preservation is stated

### revisionRules

- Adding a contributor never rewrites existing packs

### Evidence required

List only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Art of Game Design: A Book of Lenses (studio hub)](https://schellgames.com/art-of-game-design/) — source-claim. Official studio page fetched; book text not read cover to cover. Deck and app are untested tools. Using all lenses as a checklist is a misuse the method itself warns against.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).

## synthesis — Explicit synthesis of selected idea packs

### Creator questions

- **agreements**: Where do the selected packs agree (experience goals, verb, proof, aesthetic mix)? Quote or cite each pack by contributor.
- **disagreements**: Where do they disagree, and what does each side hold? Preserve the dissent verbatim or by faithful citation; do not average.
- **alternatives**: Which alternatives were considered, including ones no pack proposed, and which were rejected with reasons?
- **chosen-direction**: The chosen direction and the reasons it was selected over the alternatives. Whose pack contributed which part?
- **unresolved**: What remains unresolved, who owns it, and by what condition it is revisited?
- **next-experiments**: Which experiments run next to test the chosen direction and the unresolved matters, in what order, and what result would reverse the choice?
- **door-implications**: Which door-problem or discipline implications (art, audio, technical, quality, company) follow from the chosen direction?

### inputs

- Selected idea-pack artifacts at exact revisions (recorded by the helper as source revisions and dependencies)
- Contributor rules

### activities

- Open every selected pack completely; do not synthesize from partial or truncated inputs
- Write agreements, disagreements, alternatives, chosen direction, unresolved matters and next experiments
- Keep contributor attribution on every merged statement
- Hand the chosen direction to discovery.experience-goals

### tools

- Atlas document editor with the selected packs open

### skills

- game-team-synthesis
- game-discovery

### roles

- creator
- game-design-lead

### outputs

- Synthesis record depending on the selected idea-pack revisions

### dependencies

- contributors

### reviewCriteria

- At least one same-project idea pack is selected
- Every selected pack is cited by contributor
- Dissent is preserved, not averaged
- The chosen direction has reasons
- Next experiments have reversal conditions

### revisionRules

- Any selected pack revision invalidates this synthesis review through artifact dependency propagation
- A new pack may be added only by a new synthesis revision that selects it

### Evidence required

The synthesis cites the exact pack revisions it read. No automatic synthesis from truncated context is acceptable; if inputs were incomplete, the record must say so and remain unready. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [The Art of Game Design: A Book of Lenses (studio hub)](https://schellgames.com/art-of-game-design/) — source-claim. Official studio page fetched; book text not read cover to cover. Deck and app are untested tools. Using all lenses as a checklist is a misuse the method itself warns against.
- [The Door Problem](https://web.archive.org/web/20231023231458/https://lizengland.com/blog/2014/04/the-door-problem/) — verified-source-text. Live blog URL returned a stub; Wayback 2023-10-23 and the Kotaku reprint (author-permitted) were used. Essay is an analogy, not a complete spec standard. Large-studio role map does not transfer 1:1 to solo.
- [GDC 2012: Sid Meier on interesting decisions](https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions) — verified-source-text. Contemporary write-up read; the GDC video was not frame-reviewed. Meier states rhythm and some puzzle games are a weaker fit. Civilization-heavy examples.
- [Game Design Workshop, 5th Edition - playcentric excerpt](https://www.gamedeveloper.com/design/book-excerpt-game-design-workshop) — verified-source-text. Author-posted excerpt (2024-04-18) read; the full 5th edition was not read cover to cover. Physical prototypes under-serve real-time feel (see S06). Friend playtests bias results (Fulton, in S08).
- [Sigma Protocol game-development adaptation (architecture decision and integration contract)](../SIGMA-GAME-ADAPTATION.md) — proposed-adaptation. Our proposal, not an external practitioner method. Nothing here proves a game is good. Every phase's evidence must come from an authorized external experiment and a human review, never from the existence of a document.

## decision-record — Decision record and held decisions

### Creator questions

- **decisions**: List the decisions now held by the creator (experience goals, interaction model, art mode, engine if locked, hold list) with the document that holds each.
- **change-rule**: Who may change each held decision and what evidence or reason must be recorded.
- **agent-boundary**: Which held decisions agents may never change on their own, restated for AGENTS.md.

### inputs

- Synthesis record
- Architecture ADRs
- Hold list

### activities

- List held decisions
- Set change rules
- Publish the agent boundary

### tools

- Atlas document editor

### skills

- game-team-synthesis
- decisions-patterns

### roles

- creator
- game-design-lead
- game-technical-director

### outputs

- Held-decision record for the context engine

### dependencies

- synthesis

### reviewCriteria

- Every held decision names its document
- Change rules exist
- Agent boundary is explicit

### revisionRules

- A changed held decision updates this record in the same revision

### Evidence required

Record only. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Conversations From GDC Europe: Harvey Smith on systemic level design](https://www.gamedeveloper.com/marketing/conversations-from-gdc-europe-bill-fulton-zeno-colaco-harvey-smith) — verified-source-text. 2002 interview read. Deus Ex-era examples. Original GDC slides not recovered first-party. Production and QA cost of systemic design not quantified.
- [Sigma Protocol game-development adaptation (architecture decision and integration contract)](../SIGMA-GAME-ADAPTATION.md) — proposed-adaptation. Our proposal, not an external practitioner method. Nothing here proves a game is good. Every phase's evidence must come from an authorized external experiment and a human review, never from the existence of a document.

## revision-propagation — Revision propagation and review invalidation

### Creator questions

- **map**: Which documents depend on which (view sheets on identity; geometry on view sheets; receipts on everything upstream; synthesis on packs; PRDs on prerequisite documents)? Are those dependencies recorded on the artifacts so the existing invalidation propagates?
- **stale-handling**: When an upstream document changes, what happens to downstream reviews (invalidated, re-review required), and who re-reviews?
- **foreign-refs**: Rule that imported or foreign references never bind: what happens when a dependency is missing or from another project?
- **evidence-refresh**: Which receipts must be re-run after which upstream changes (engine version, budgets, proportions, skeleton policy)?

### inputs

- Artifact dependency graph
- All workflow documents

### activities

- Record dependencies on artifacts
- State invalidation and re-review
- List receipt re-run triggers

### tools

- Atlas artifact dependencies

### skills

- game-team-synthesis
- game-quality-planning

### roles

- creator
- game-quality-lead

### outputs

- Revision propagation rules for this project

### dependencies

- decision-record

### reviewCriteria

- Dependencies are recorded, not implied
- Re-run triggers are listed
- Foreign references fail rather than bind

### revisionRules

- A new document class adds its dependency rule

### Evidence required

Rules only; the artifact model enforces invalidation. Evidence text must separate what was planned from what actually happened; the existence of this document proves nothing about the game.

### Sources

- [Sigma Protocol game-development adaptation (architecture decision and integration contract)](../SIGMA-GAME-ADAPTATION.md) — proposed-adaptation. Our proposal, not an external practitioner method. Nothing here proves a game is good. Every phase's evidence must come from an authorized external experiment and a human review, never from the existence of a document.
