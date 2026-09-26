# Commercial methodology implementation — 2026-09-19

Scope: implemented the verified commercial research in `steps/step-1-ideation`, `steps/step-1.5-offer-architecture`, and `steps/step-10-feature-breakdown`. This note records the gate changes without changing the workflow's gate count or approval policy.

## Sources applied

- [Teresa Torres: continuous discovery](https://www.producttalk.org/ship-value-weekly/) and [current training](https://learn.producttalk.org/train-your-team) — outcome, opportunity, interview, and assumption-test loop.
- [Christensen Institute: Jobs to be Done](https://www.christenseninstitute.org/theory/jobs-to-be-done/) and [Strategyn: ODI](https://strategyn.com/jobs-to-be-done-template/) — progress-in-context and quantitative outcome research are distinct methods.
- [Acquisition.com](https://shop.acquisition.com/) — Offers, Leads, and Money Models are current source material; commercial claims remain hypotheses until project evidence supports them.
- [April Dunford](https://www.aprildunford.com/books) — positioning alternatives, differentiated capability/value, best-fit customer, category, and the Sales Pitch handoff.
- [Basecamp Shape Up](https://basecamp.com/shapeup/) and [Set Boundaries](https://basecamp.com/shapeup/1.2-chapter-03) — appetite is a fixed time budget with variable scope and boundaries.
- [Jeff Patton: User Story Mapping](https://agilealliance.org/resources/books/user-story-mapping/) — journey backbone, walking skeleton, and release slices.

## Gate dispositions

| Step | Existing gate | Disposition | Acceptance added |
|------|---------------|-------------|------------------|
| 1 | Decision lock | Retained | Job/context, trigger, workaround, evidence type, and first assumption test are explicit; approval does not validate assumptions. |
| 1 | Research → feasibility | Retained | Evidence must show what decision changed; remaining assumptions require an owner and proportionate next test. Synthetic research is not customer proof. |
| 1 | Feasibility → PRD | Retained | Unresolved feasibility and commercial risks remain visible for Step 2 rather than becoming settled architecture. |
| 1 | Final PRD | Retained | Evidence, assumptions, and follow-up tests are sufficient for downstream work; hypotheses remain hypotheses. |
| 1.5 | Classification | Retained | Buyer, alternative, value metric, price hypothesis, delivery cost, capacity, proof, and conditional commitments are recorded. |
| 1.5 | Positioning | Retained | Buyer evidence or labeled assumptions plus a Sales Pitch handoff with proof, objections, and open tests. |
| 1.5 | Pricing/package | Retained | Packaging, commitment, channel behavior, and unit-economics scenarios are hypotheses with tests and operating constraints. |
| 1.5 | Product impact | Retained | Entitlement, billing, data, UX, and support consequences are explicit; implementation remains downstream work. |
| 1.5 | Final offer | Retained | Commercial hypotheses, consequences, and follow-up tests are clear enough for architecture; no billing implementation or external outcome promise is authorized. |
| 10 | Outcome map/story backbone | Retained | Outcome, opportunity, release slice, and walking skeleton are explicit; candidate solutions and assumptions stay visible. |
| 10 | PRD eligibility | Retained | Every Yes/No decision has user outcome, appetite, dependencies, and observable acceptance evidence. |
| 10 | Appetite/boundaries | Retained | Fixed time budget, variable scope, no-go boundary, rabbit holes, risk owner, and stop/reshape condition are explicit. |
| 10 | Dependency/sequence | Retained | First slice, integration owner, and verification point are explicit; agent handoff fields apply only to delegated work. |
| 10 | Final handoff | Retained | Selected work is outcome-led, bounded, and evidence-backed; task activity does not substitute for user-value acceptance. |

## Implemented method changes

### Step 1 — ideation

- Added continuous discovery framing: desired outcome → opportunity → candidate solution → assumption test.
- Expanded the evidence register with evidence type, decision impact, and next test.
- Added an opportunity-map and assumption-test section to the PRD shape.
- Marked the Value Equation as a heuristic requiring evidence or a proof plan.

### Step 1.5 — offer architecture

- Removed universal price bands, fixed funnel pricing, and “irresistible”/guaranteed-outcome language.
- Added Money Models paths for attraction, initial purchase, expansion, downsell, and continuity only where applicable.
- Added Dunford positioning inputs and a concise Sales Pitch handoff to Step 9 and Run Sales.
- Replaced blanket guarantee language with operable commitments, buyer/channel tests, unit-economics scenarios, and capacity constraints.
- Added AI cost variance, metering attribution, provider dependency, and escalation behavior only for AI-native offers where relevant.

### Step 10 — feature breakdown

- Kept Torres's opportunity work separate from Patton's story-map and release-slice work.
- Replaced fixed day-range appetites with a project-specific time budget and variable scope.
- Required meaningful user-outcome acceptance evidence for PRD-eligible work.
- Added no-go scope, risk owner, and stop/reshape condition for each selected bet.
- Limited AI execution context to tasks that will actually be delegated to agents.

## Validation

- `git diff --check -- steps/step-1-ideation steps/step-1.5-offer-architecture steps/step-10-feature-breakdown` — passed.
- No generated command mirrors, global installations, commits, or external state changed by this implementation pass.
