# What Happens After Steps 0–15 (Plain English)

**Last updated:** 2026-06-29

You finished planning. This is what happens next — in order — without jargon overload.

---

## The big picture (three lanes)

Think of three train tracks that can run at the same time:

| Lane | What it is | When it starts |
|------|------------|----------------|
| **Build** | Write the app from F-PRDs | After Step 11 PRDs approved |
| **Run (GTM)** | Market + sell while you build | After Step 1 or Step 11 (your choice) |
| **Quality gates** | Prove each chunk is really done | During Build, after each PRD |

Steps 0–15 mostly fill the **planning filing cabinet**. After Step 15, you **execute**.

---

## Right after Step 15 — do these in order

### 1. Sanity check the plan (optional but smart)

```bash
/step-verify --step=0-15
```

**What it does:** Grades your step outputs (files exist? sections complete?). Fix gaps before you build.

**Brain version:** "Did we actually finish homework, or just say we did?"

---

### 2. Start go-to-market — /gtm conducts the Run Tracks

**After Step 15**, the natural next move is **`/gtm`** — the Go-To-Market conductor. It owns the launch motion and sequences the Run Tracks below (same HITL pattern as Step 1 → 1.5). The walkthrough engine underneath:

```bash
/continue --source=run-track
```

The script walks you **one department at a time** (you must say yes each time):

1. `/run-legal` — **L0** LLC/S-Corp advisor first  
2. `/run-finance`  
3. `/run-marketing`  
4. `/run-sales`  
5. `/run-growth` → `/run-content` → `/run-community` → `/run-ops`

When marketing finishes, run `/continue --source=run-track` again — it will offer sales next.

**Manual entry** (skip the walkthrough):

```bash
/run-marketing          # M1 → M10
/run-sales              # S1 → S8
/run-content            # C1 → C8
/run-growth             # G1 → G8
/run-community          # Co1 → Co6
/run-ops                # O1 → O8
/run-finance            # Fn1 → Fn7
/run-legal              # L0 → L8
```

**Important:** Run Track walkthrough unlocks after **Step 15**, entered via the `/gtm` conductor. Use `/continue --source=run-track` — see [`HOW-TO-USE.md`](run-track/HOW-TO-USE.md).

**What you get:**
- Plain-language docs in `docs/run-track/{dept}/`
- Task cards in `.sigma/backlogs/{dept}/prd.json` (copy from `prd.json.example` on fresh clone — see [`CLEAN-INSTALL.md`](run-track/CLEAN-INSTALL.md))
- SigmaHQ tasks if kanban is set up (`python3 scripts/sigmahq-sync-run-track.py --dept all`)

**Run Track cheat sheet (64 steps):**

| Marketing (M) | Sales (S) | Content (C) | Growth (G) |
|---------------|-----------|-------------|------------|
| M1 Audit funnel | S1 Named accounts | C1 Brief intake | G1 Funnel + events |
| M2 Avatar | S2 CRM pipeline | C2 Video research | G2 Baseline metrics |
| M3 Stack + tracking | S3 Outbound | C3 Long-form scripts | G3 Hypothesis backlog |
| M4 Messaging | S4 Discovery | C4 Thumbs + titles | G4 A/B spec |
| M5 Channels | S5 Proposals | C5 Short-form pack | G5 CRO sprint |
| M6 Content calendar | S6 Inbound DM | C6 Social copy | G6 Retargeting |
| M7 Email sequences | S7 Follow-up | C7 Atomization map | G7 Activation cohorts |
| M8 Launch runbook | S8 Pipeline ops | C8 Publish handoff | G8 SEO loop |
| M9 Review cadence | | | |
| M10 Retention | | | |

| Community (Co) | Ops (O) | Finance (Fn) | Legal (L) |
|----------------|---------|--------------|-----------|
| Co1 Platform audit | O1 Ops baseline | Fn1 Unit economics | L0 Entity formation |
| Co2 Welcome flow | O2 Sprint rhythm | Fn2 Pricing architecture | L1 Intake + BATNA |
| Co3 Community rhythm | O3 Release gates | Fn3 Forecast | L2 MSA/SOW |
| Co4 Moderation | O4 Observability | Fn4 Cost audit | L3 NDA strategy |
| Co5 Feedback loop | O5 Incidents | Fn5 Runway | L4 IP/trademark |
| Co6 Advocacy | O6 WBR | Fn6 Spend gates | L5 Vendor DPA |
| | O7 SOP + vendors | Fn7 Data room | L6 Compliance |
| | O8 Contractors | | L7 Incident narratives |
| | | | L8 Demand playbook |

Details: [`docs/run-track/HOW-TO-USE.md`](run-track/HOW-TO-USE.md) · [`docs/run-track/README.md`](run-track/README.md)

---

### 3. Turn PRDs into a build queue (if not done in Step 11.5)

```bash
/step-11.5-task-handoff
/prd-json --mode implementation    # machine backlog
/prd-orchestrate                   # optional: parallel groups
```

**Outputs:**
- `.sigma/backlogs/implementation/TASKS.md` — what agents claim next
- `.sigma/backlogs/implementation/prd.json`
- `.sigma/orchestration/*` — who can work in parallel

**Brain version:** "Turn the blueprint into a numbered to-do list with dependencies."

---

### 4. Build the app — `@dev-loop`

```bash
@dev-loop
# or one PRD at a time:
/sigma-dispatch F01.001
```

**When:** After Step 14 (runtime bootstrap). Step 15 (observability) tells each feature what to measure **before** it ships.

**What happens:**
1. Pick next unbuilt PRD (dependency order)
2. Agent implements it (`/goal` or native CLI primitive)
3. Run **8 gates** on every commit (see below)
4. Repeat until all F-PRDs are `done`

**Brain version:** "Contractors build room by room from the blueprint until the house is done."

---

### 5. `@gap-analysis` — after each PRD is built (not after Step 15 alone)

There is **no** separate "Step 16." Gap analysis runs **during** build, per feature.

```bash
@gap-analysis --spec=docs/prds/F01.001-your-feature.md
```

**What it does:**
1. Compare **code** vs **PRD** (traceability matrix)
2. List what's missing
3. **Auto-fix** up to 3 rounds
4. If UI changed → browser validation (UI Healer)

**Brain version:** "Inspector walks the finished room against the spec and fixes what's wrong before you sign off."

**Not the same as:**
- `@holes` — finds gaps in **plans** before coding
- `@step-verify` — grades **methodology steps** 0–15
- `@audit-step-verify` — deep audit of a single step artifact

`@dev-loop` calls `@gap-analysis` automatically when verification fails.

---

### 6. Ship pipeline (every commit during build)

Each PRD goes through **8 gates** before merge:

1. Anti-Slop  
2. UI Validation (if frontend)  
3. Expect / Browser  
4. Devil's Advocate  
5. **Gap Analysis** ← this is where `@gap-analysis` lives  
6. QA Verification  
7. Cross-Model Review  
8. CodeRabbit / Greptile  

**Brain version:** "Eight checkpoints so 'it's done' means evidence, not vibes."

---

### 7. Release

```bash
@ship-stage    # merge sprint branch → dev
@ship-prod     # release PR dev → main
/ops:sprint-plan # next wave of PRDs
```

---

## Timeline (one picture)

```text
Steps 0–15          Planning cabinet full
       │
       ├─► /run-marketing + /run-sales     (parallel, daily founder tasks)
       │
       ├─► step-11.5 + prd-json            (build queue)
       │
       └─► @dev-loop                       (build F-PRDs one by one)
              │
              each PRD ──► implement ──► @gap-analysis ──► 8 gates ──► merge
       │
       └─► @ship-stage / @ship-prod         (release)
```

---

## What you do vs what agents do

| You (founder) | Agents |
|---------------|--------|
| Approve step checkpoints (0–15) | Write docs, PRDs, code |
| Run Track: ≤3 tasks/day (logins, approvals) | Research, drafts, calendars, sequences |
| Connect tools (PostHog, the social scheduler, CRM) once | Checklists tell you exactly what to click |
| Approve launch copy, ad budget, walk-away price | Generate options; you pick |
| Review PRs at gates | Implement + fix loops |

---

## Quick command cheat sheet (post–Step 15)

| I want to… | Command |
|------------|---------|
| Know today's marketing tasks | `/run-marketing` or `/run-m-3-stack-tracking` |
| Know today's sales tasks | `/run-sales` or `/run-s-2-crm-pipeline` |
| Start building | `@dev-loop` |
| Build one feature | `/sigma-dispatch F01.001` |
| Check plan quality | `/step-verify --step=0-15` |
| Check code vs PRD | `@gap-analysis --spec=docs/prds/F01.001-....md` |
| Sync board | `python3 scripts/sigmahq-sync-run-track.py --dept <dept>` |
| Ship | `@ship-stage` → `@ship-prod` |

---

## Related docs

- [Run Track](run-track/README.md)
- [WORKFLOW-OVERVIEW.md](WORKFLOW-OVERVIEW.md) — full Steps 0–15
- [steps/dev-loop](../steps/dev-loop) — build loop
- [.agents/skills/gap-analysis/SKILL.md](../.agents/skills/gap-analysis/SKILL.md) — gap analysis skill
