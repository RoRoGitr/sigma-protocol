---
version: "7.2.0"
last_updated: "2026-09-19"
description: "Step 12: Context Engine — synthesize methodology into AGENTS.md and project runtime context"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
parameters:
  - --force
---

<!-- HITL-GATE-POLICY:start -->
## ⛔ HITL Gate Contract (read before running any phase)

This step is **human-in-the-loop**. Every `<HARD-GATE>` below is a **hard stop**. Obey these rules exactly — they override any default to "keep going."

**Runtime adapter:** `AskUserQuestion` below means the host's supported user-question mechanism, not a required tool identifier. Use an available structured question tool only when it permits this kind of question. Otherwise ask in a normal response and end the turn at the gate. A tool that cannot collect approval is not an approval substitute. Frontmatter controls are host-specific: supported `allowed-tools` can preapprove tool access. Tool access does not authorize actions outside the user's scope or satisfy a phase, release or production approval.

1. **Ask, then wait.** At each `<HARD-GATE>` you MUST call `AskUserQuestion` and receive an **actual answer from the user** before starting the next phase. Producing the analysis for a phase is allowed; *advancing past its gate* is not, until the user answers.
2. **A non-answer is NOT approval.** If `AskUserQuestion` returns no response, times out, or says the user is away — **PAUSE the step and wait**. Do not "proceed on best judgment," do not draft the remaining phases, do not infer approval from silence. Save what you have, tell the user the step is paused at Phase _X_ awaiting their answer, and stop. Re-ask when they return.
3. **One gate per phase — never collapse them.** Ask each phase's gate at its own phase boundary (A, then B, then C…). Do not batch several phases into a single question, and do not run multiple phases and ask once at the end. The founder decides at every boundary.
4. **The only way to skip gates** is an explicit, up-front instruction from the user in *this* run — e.g. "run all phases without stopping," "autonomous mode," or "don't ask me, just draft it." Absent that explicit opt-in, gates are mandatory. Being mid-task, low on time, or unattended is never such an opt-in.
5. **Everything before an approval is a draft.** Nothing a gate guards is "locked" or "done" until the user has approved it at that gate.

**Explicit unattended runs:** Record the user's opt-in and its scope once. Complete authorized phases and local verification without repeatedly asking for the same permission. Mark decisions made under that delegation as assumptions or delegated decisions, not fabricated user answers. Unattended drafting does not grant release, spending, destructive-action or production authority. A genuine missing decision may block one part while independent authorized work continues.

> If you find yourself about to write the next phase without a user answer to the current gate, STOP — that is the exact failure this contract prevents.
<!-- HITL-GATE-POLICY:end -->

<!-- GAME-DOMAIN:start -->
## Conditional game-domain adaptation

Apply this section only when `docs/stack-profile.json` records `projectDomain: "game"`. A missing value means `general`; do not infer a game domain from product language. Keep this step's number, phases, outputs, gates, business functions, GTM, context, and handoff intact.

Read the selected entry from the canonical game-development catalog when it is available. Use only the workflows and questions applicable to the recorded game profile. If applicability is unknown, record it as unresolved; defer or skip work only with a reason. The catalog adapts this step. It does not create an alternate numbered sequence.

- Default to a solo creator. Contributor idea packs are separately authored, workspace-visible planning inputs; synthesis is an explicit creator decision that preserves selected revisions, attribution, disagreement, and rejected alternatives.
- Treat prototypes, art, audio, engine setup, imports, builds, performance measurements, multiplayer checks, and playtests as external execution. This Protocol step may prepare a decision, brief, checklist, or evidence requirement. Mark execution evidence `NOT-EXECUTED` until real evidence is attached and reviewed.
- Choose the smallest experiment that tests the current uncertainty. Do not require paper prototypes, outside testers, fixed art freezes, an engine, a team size, a schedule, or a downstream production method unless the creator records why it applies.
- Keep claims classified: source text, observed evidence, source claim, untested integration, or proposed adaptation. Preserve the catalog source IDs and linked research when creating game artifacts.

<!-- GAME-DOMAIN:end -->

<!-- SKILLS-INVOKE:start -->
## Required skills — invoke the live skills (do NOT rely on embedded summaries)

This step's output quality depends on these skills. **Invoke each via the host's installed Skill catalog by name at the relevant phase.** If the host cannot resolve that name, read the project source at `src/skills/<skill>/SKILL.md`, then the bundled `.agents/skills/<skill>/SKILL.md` when present. Do not rely on embedded summaries.

- `game-development` — conditional when `projectDomain: "game"`; select this step's catalog entry and applicable workflow

- `memory-systems`
- `prompt-engineering-patterns`
- `sigma-protocol-guide`
- `decisions-patterns`
- `gotchas-patterns`

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-12-context-engine — Runtime-Native Context Engine

**On start, announce:** "Running Step 12: Context Engine. I'll synthesize everything from Steps 0-11 into AGENTS.md and the project memory bridge."

**Mission**
Synthesize everything learned through Step 11 into the project's cross-agent instruction surface. Step 12 owns `AGENTS.md` and the `.sigma/memory/` bridge. Step 13 supplies authored skills and agents under `src/`. Step 14 owns helper tools, manifests, memory expansion, and coordinator scaffolding.

# Runtime policy (platform-agnostic)

Sigma Protocol ships as **canonical sources**, not per-vendor mirrors:

| Layer | Path | Role |
|-------|------|------|
| Steps | `steps/` | Canonical step contracts (phases, HARD-GATEs, SKILLS-INVOKE) |
| Rendered commands | `commands/` | Expanded step files (partials inlined) for slash-command import |
| Authored skills | `src/skills/<category>/<skill>/SKILL.md` | Invoke via Skill tool at the phase listed in each step |
| Authored agents | `src/agents/<category>/<agent>.md` | Project agent definitions for Step 14 dispatch |
| Project brain | `AGENTS.md` | Cross-agent project context (Step 12 output) |
| Runtime state | `.sigma/runtime/`, `.sigma/memory/`, `.sigma/tools/` | Step 14 scaffold |

**Do not** duplicate canonical content into per-vendor mirror trees. Native discovery adapters are allowed: a thin `CLAUDE.md` containing `@AGENTS.md`, skill installation into a supported discovery directory, and host-specific agent configuration. Keep one instruction body; record adapter ownership. Operators control CLI permissions, hooks, models and MCP configuration.

**Skill invocation rule:** Resolve listed skills from the installed catalog. This repository authors skills in `src/skills/` and also ships bundled-only skills in `.agents/skills/`; generated projects may use category directories. Read only the skill and references relevant to the phase. Missing skill → state the gap; do not silently pretend it ran. Claude tool names in examples map to the current host's equivalent capabilities; never invent a tool or grant permissions from a document.

**Research rule:** Use built-in web search. Do not require Exa, Firecrawl, or operator-local storage paths.

**Evidence and freshness:** Verify changing framework, model, library and legal claims against primary sources. Record the URL, publication/version when available, review date, and the concrete decision affected. Distinguish a foundational method from a new revision; do not label an entire skill current because one source was checked. Illustrative dates and numbers must not become live receipts.

**Runtime-native policy**
- **AGENTS.md is the primary output.** It is the cross-agent project brain. Keep Step 12-managed blocks self-sufficient and concise; treat the runtime's cumulative instruction budget as constrained and push depth into `src/skills/` and `docs/`. Preserve user-authored policy outside Step 12-managed blocks.
- When Claude Code is a detected runtime, `CLAUDE.md` may be a thin native adapter that imports `@AGENTS.md`; it must not duplicate the managed body or overwrite operator-authored additions.
- Canonical skill/agent sources: `src/skills/`, `src/agents/` (Step 13)
- Rendered step commands: `commands/` (from `steps/` via sync script)
- Step 14 owns: `.sigma/tools/`, `.sigma/runtime/`, `.sigma/memory/` expansion
- Optional operator-local CLI config (hooks, MCP, permissions) is **not** generated by Sigma — document paths only if the operator already uses them

**Single-store consumption**

Step 12 reads from and writes to the shared memory layer when one is configured (per Step 0); it never creates a per-project second store. The context engine is the bridge between the project's knowledge (`.sigma/memory/project/`, `docs/`) and any shared layer. When no shared layer is configured, `.sigma/memory/` is the source of truth and that is fully supported.

**Consumption:** When generating `AGENTS.md`, if a shared memory layer is configured, confirm it is current via the tool's own status surface; if it has never synced this project, trigger its sync before proceeding. With no shared layer, read `.sigma/memory/` and `docs/` directly.

**Write-back:** After completing Step 12, update `.sigma/memory/project/README.md` with the Step 12 decision log (key architectural choices, runtime surface layout, token budget decisions). This feeds the next sync cycle (when a shared layer exists) so future agents inherit current context.

**No per-project second store:** If a `BRAIN.md` or stray per-project memory config exists at the project root from a previous setup, identify any duplicate content and propose a migration into `.sigma/memory/project/README.md`. Do not delete or rewrite arbitrary memory files automatically. Log the decision in CONTEXT.md.

**Single-agent rule**
This step must run in the primary session. Do not split Step 12 into subagents. If multiple perspectives are useful, simulate them inside the same response with labeled sections.

<goal>
You are the Runtime Context Architect. Execute ALL phases (A through E) in order.

CRITICAL:
- Do NOT skip any phase. Do NOT combine phases.
- If Step 0 reports `research_mode = blocked`, stop and ask user to repair environment.
- Each phase ends with a HARD-GATE — halt and wait for user approval.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Context Import & Surface Detection | Upstream artifacts + canonical surfaces confirmed |
| B | AGENTS.md Section Plan | Section map + DNA vs Skills split |
| C | Project Context Synthesis | AGENTS.md methodology + project constraints sections |
| D | Memory Bridge + Linear Wiring | `.sigma/memory/` bridge, optional Linear sync |
| E | Verification & Handoff | Step 12 report, $holes pass, Step 13/14 handoff |

Required Outputs:
- `/AGENTS.md` (Step 12 managed methodology + project sections, clearly labeled)
- `/.sigma/memory/project/README.md`
- `/.sigma/memory/local/.gitkeep`
- `/.sigma/memory/agents/README.md`

Quality gate: 95+/100 on verification schema.

**Core principle:** Runtime surfaces are consumed by AI agents, not read in meetings. Every instruction must be structured, unambiguous, and action-oriented.

Checkpoint slice rule:
- present only the current phase slice at each checkpoint
- summarize `What was decided`, `What changed`, and `What remains open`
- end with a clear approval or revision question for that slice only
</goal>

---

## Step Boundary

Step 12 OWNS:
- `AGENTS.md` Step 12 managed sections (methodology + project constraints + design artifacts)
- `.sigma/memory/` minimum bridge files (`project/`, `local/`, `agents/`)

Step 12 IMPORTS from Steps 0–11:
- MASTER_PRD, architecture, design system, technical spec, feature breakdown, PRD status, stack-profile

Step 12 does NOT OWN:
- `.sigma/tools/`, `.sigma/runtime/` (Step 14)
- Deep `.sigma/memory/` taxonomy beyond bridge files (Step 14)
- `src/skills/`, `src/agents/` (Step 13)
- Platform-specific mirror directories

---

## Phase A — Context Import & Surface Detection

### Upstream Requirements

| Artifact | Source Step | Required |
|----------|-----------|----------|
| `docs/specs/MASTER_PRD.md` | Step 1 | **Yes** |
| `docs/architecture/ARCHITECTURE.md` | Step 2 | **Yes** |
| `docs/design/DESIGN-SYSTEM.md` | Step 6 | **Yes** |
| `docs/technical/TECHNICAL-SPEC.md` | Step 8 | **Yes** |
| `docs/implementation/FEATURE-BREAKDOWN.md` | Step 10 | **Yes** |
| `docs/prds/F*-*.md` or `.prd-status.json` | Step 11 | **Yes** |

**Fallback:** If MASTER_PRD, ARCHITECTURE, or TECHNICAL-SPEC are missing, halt: "Step 12 requires upstream artifacts from Steps 1–11."

Read if present:
- `AGENTS.md`, `CLAUDE.md` (when present), `docs/stack-profile.json`, `docs/specs/constitution.md`
- `docs/specs/OFFER_ARCHITECTURE.md`, `docs/states/STATE-SPEC.md`
- `src/skills/`, `src/agents/`, `commands/` (rendered steps)
- `.sigma/runtime-baseline.json`

Absorb useful content from legacy `.sigma/rules/` if it exists — then retire or mark deprecated. Do **not** treat `.claude/`, `.codex/`, `.cursor/` as required outputs.

For every target runtime, probe instruction loading at the repository root and from a nested directory. Record the loaded/unloaded result, scope and precedence rule, command or UI evidence, and any unsupported import explicitly. Do not claim that one instruction file imports another unless the probe proves it.

<HARD-GATE>
Do NOT proceed to Phase B until user approves context scope.
Use AskUserQuestion: "Context imported. Approve AGENTS.md synthesis scope?"
Options: [Approve — plan AGENTS.md sections, Revise scope, Skip optional artifacts]
</HARD-GATE>

---

## Phase B — AGENTS.md Section Plan

**Goal:** Plan what goes into `AGENTS.md` before writing.

### Required sections (when upstream artifacts exist)

| Section | Source | Purpose |
|---------|--------|---------|
| Project identity | Step 1 MASTER_PRD | Name, outcome, constraints |
| Active workflow | Sigma canon | Steps 0–15 + backlog paths |
| Stack profile | Step 0/2/8 | Framework, component libraries, integrations |
| Project constraints | `constitution.md` | Immutable principles (verbatim) |
| Design artifacts | Steps 5/9 | Visual source-of-truth paths |
| Skill invocation | Step 13 preview | `src/skills/` + SKILLS-INVOKE convention |
| Memory bridge | Step 12 | `.sigma/memory/` + optional shared layer |
| Session resume | Step 12 | 3 constraints + sprint state path + cold-start file |

For each planned instruction, record its owner, scope, source or recorded operator decision, freshness status, destination, and whether it is a source fact or an inference. Surface contradictions and unknowns before synthesis; only an explicit authorized decision may promote an inference to policy.

### DNA vs Skills separation

- **DNA (in AGENTS.md):** anti-slop, HARD-GATE, verification thresholds, coordinator-first policy
- **Skills (in `src/skills/`):** stack patterns, component libraries, framework specifics — invoke per step phase

Do NOT duplicate full skill bodies into AGENTS.md. Point to paths and invoke phases.

### Context budget

- Measure the cumulative always-on context and retrieval cost for each target runtime; do not impose a fixed per-file target
- Push depth into `src/skills/` and `docs/`
- Preserve user-authored policy outside managed blocks. Use a thin `CLAUDE.md` adapter only when the detected runtime loading probe supports that import; otherwise record the supported native surface and do not duplicate the AGENTS body.
- Include compaction-survival "Session Resume" section

<HARD-GATE>
Do NOT proceed to Phase C until user approves the section plan.
Use AskUserQuestion: "AGENTS.md section plan ready. Approve synthesis?"
Options: [Approve — write AGENTS.md, Revise sections, Show DNA vs Skills split]
</HARD-GATE>

---

## Phase C — Project Context Synthesis

**Goal:** Write or update `AGENTS.md` with the planned sections. Regenerate only Step 12–managed blocks (clearly labeled comments or headers).

When a detected runtime loading probe supports it, create or update only the thin native `CLAUDE.md` adapter needed to import `@AGENTS.md`. Preserve operator-owned content and do not turn it into a second instruction source. If the probe does not support it, preserve the file and record the loaded native surface instead.

### Constitution (when `docs/specs/constitution.md` exists)

Copy principles **verbatim** under `## Project Constraints (from constitution.md v{VERSION})`. No summarizing.

### Design artifacts (when Step 5 or 9 outputs exist)

Emit the detected visual source-of-truth paths and their tool receipts. HTML/native artifacts are portable defaults; Pen, Taste, Designscape, or another renderer are optional adapters only when their local capability probe and owner source are recorded.

Skip section when none exist.

### Stack + component libraries

Reference locked choices from `docs/stack-profile.json` and `docs/references/CURATED-COMPONENT-LIBRARIES.md`. List which methodology skills to invoke (`shadcn`, `rn-component-library`, `agentic-ui`, `companion-system`, etc.).

<HARD-GATE>
Do NOT proceed to Phase D until user approves AGENTS.md synthesis.
Use AskUserQuestion: "AGENTS.md updated. Approve memory bridge wiring?"
Options: [Approve — create memory bridge, Revise AGENTS.md, Add missing section]
</HARD-GATE>

---

## Phase D — Memory Bridge + Linear Wiring

**Goal:** Create `.sigma/memory/` bridge and optional Linear milestone.

### Memory bridge (always)

Create or update:
- `.sigma/memory/project/README.md` — project name, synthesized steps, decisions, conventions, pointer to shared memory layer or "none", and source/authorization/retention/redaction/rollback metadata for each write
- `.sigma/memory/local/.gitkeep`
- `.sigma/memory/agents/README.md` — agent memory purpose; Step 14 may expand

Read `runtime-baseline.json -> memory_layer`. If `configured: false`, `.sigma/memory/` is the source of truth — valid pass.

Keep bridge files within the measured context budget. Tag entries: semantic / episodic / procedural, and preserve existing user entries unless an authorized migration explicitly changes them.

### Linear (when configured — Linear replaced the SigmaHQ kanban 2026-07-11)

If `linear.configured: true` (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json):
1. Verify Step 11 engineering issues (label `eng-task`) exist in `linear.project`
2. Record the repo → `linear.project` mapping in AGENTS.md so every runtime knows where task state lives (GitHub always owns the PR/branch/review/merge loop; the tracker board is Linear here)
3. Create a Step 12 completion milestone issue — labels `milestone`, `step-12`, `wave:W0` (wave labels are MANDATORY)

If not configured, use wave-labeled GitHub Issues as the task board (or file artifacts for offline tracking) — record the repo's board choice in AGENTS.md the same way. Never the retired SigmaHQ kanban.

<HARD-GATE>
Do NOT proceed to Phase E until user approves memory bridge.
Use AskUserQuestion: "Memory bridge complete. Run verification?"
Options: [Approve — verify and hand off, Revise memory bridge, Adjust Linear wiring]
</HARD-GATE>

---

## Phase E — Verification & Handoff

### Required verification
- `AGENTS.md` contains labeled Step 12 sections and a measured cumulative-context report
- root and nested runtime probes show which instruction surfaces load, their scope/precedence, and unresolved imports
- `CLAUDE.md`, when a detected runtime probe supports the adapter, is thin and does not duplicate the managed instruction body
- `.sigma/memory/project/README.md`, `local/.gitkeep`, `agents/README.md` exist
- Constitution and design-artifact sections present when upstream artifacts exist
- No requirement for `.claude/`, `.codex/`, or platform mirror directories
- Step 13/14 handoff paths documented in AGENTS.md
- generated rules distinguish source facts, recorded operator decisions, inferences, and unknowns; contradictions are reported rather than silently resolved

### Mandatory: Run $holes

Fix gaps before final gate.

### Downstream handoff

| Artifact | Consumed By | Purpose |
|----------|-------------|---------|
| `AGENTS.md` | Step 13, 14 | Project brain |
| `.sigma/memory/project/README.md` | Step 14 | Memory scaffold expansion |
| `.sigma/memory/agents/README.md` | Step 14 | Agent memory subfolders |

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 13 without explicit approval.
Use AskUserQuestion: "Step 12 complete. Ready for Step 13 — Skillpack Generator?"
Options: [Proceed to Step 13, Revise AGENTS.md, Review memory bridge]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 12 Verification Schema

### Required Files (40 points)
| File | Path | Points |
|------|------|--------|
| Project brain | /AGENTS.md | 20 |
| Project memory bridge | /.sigma/memory/project/README.md | 10 |
| Agent memory bridge | /.sigma/memory/agents/README.md | 5 |
| Local memory marker | /.sigma/memory/local/.gitkeep | 5 |

### Content Quality (35 points)
| Check | Points |
|-------|--------|
| Workflow steps 0–15 documented | 8 |
| Stack + skill invoke paths documented | 8 |
| Constitution verbatim when present | 7 |
| Design artifact paths when present | 6 |
| Session resume / compaction section | 6 |

### DNA Compliance (15 points)
| Check | Points |
|-------|--------|
| DNA vs Skills separation | 5 |
| Anti-slop in outputs | 5 |
| Linear project mapping documented when configured | 5 |

### Boundary Integrity (10 points)
| Check | Points |
|-------|--------|
| No platform mirror requirements | 4 |
| Step 14 handoff explicit | 3 |
| $holes pass completed | 3 |

### Pass Threshold
95/100 minimum.
</verification>

$END$
