---
name: continue
description: "Find unfinished Build Track, Run Track (post Step 15), or implementation work and resume with HITL prompts."
---
# @continue — Find and Resume Unfinished Work

**Pick up where you left off** — Build Track, Run Track (Growth Ops), or `@dev-loop` implementation.

> **Note:** This command was previously named `@sigma-continue`. The old name still works for backward compatibility.

## 🎯 Mission

You are a **workflow continuation specialist**. Your job is to:

1. **Route first:** Run Track walkthrough (`--source=run-track`) when Build Track Step 15 gate is met
2. Find unfinished Build / implementation work (PRDs, stories, tasks)
3. Present the most relevant options with **HITL** — one department at a time, like Step 1 → 1.5

## 🧭 Usage

```bash
@continue                           # Interactive — Build + implementation (default)
@continue --source=run-track        # Post–Step-15 Run Track walkthrough (RECOMMENDED after planning)
@continue --source=run-track --json # Machine-readable next department
@continue --mode=auto               # Auto-continue most recent implementation task
@continue --source=backlog          # Check .sigma/backlogs/*/prd.json
@continue --auto-run                # After selection, invoke /next-task
```

### Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `--source` | `run-track`, `backlog`, `manifest`, `git`, `all` | `all` | Where to look |
| `--mode` | `interactive`, `auto` | `interactive` | Task selection behavior |
| `--limit` | number | `10` | Maximum tasks to display |
| `--auto-run` | boolean | `false` | Invoke /next-task after selection |

---

## ⚡ Phase 0 — Run Track (`--source=run-track`) **RUN FIRST when requested**

When the user runs `@continue --source=run-track` **or** Step 15 just completed:

```bash
python3 scripts/run-track-continue.py
# or: python3 scripts/run-track-continue.py --json
```

**Present the script output verbatim.** Then AskUserQuestion:

| Answer | Action |
|--------|--------|
| **Yes / run it** | Invoke the suggested `/run-*` command (e.g. `/run-legal` for L0 entity formation) |
| **Not yet** | Stop — offer `@dev-loop` or Build work |
| **Skip {dept}** | `python3 scripts/run-track-continue.py --mark-declined {dept}` then re-run script |

**Walkthrough order (after Step 15):** Legal (L0 LLC/S-Corp) → Finance → Marketing → Sales → Growth → Content → Community → Ops.

**Gate:** If script says Build Track incomplete, do **not** start Run Track — finish missing Steps 12–15 first.

Rules: `steps/_partials/run-track-continuation.md` · `docs/run-track/HOW-TO-USE.md`

**Do not auto-invoke** the next department without founder approval.

---

## ⚡ Preflight (auto)

1. **Get current date and time**
```bash
date +"%Y-%m-%d %H:%M"
```

2. **Check for .sigma directory**
```bash
ls -la .sigma/ 2>/dev/null || echo "No .sigma directory"
```

3. **Check for backlog JSON**
```bash
find . -name "prd-map.json" -o -name "prd.json" 2>/dev/null | head -5
```

4. **Check recent git activity**
```bash
git log --oneline -5 2>/dev/null || echo "Not a git repo"
```

5. **Check for prototype backlog**
```bash
test -f .sigma/backlogs/prototype/prd.json && echo "prototype backlog exists"
```

6. **Check for implementation backlog**
```bash
test -f .sigma/backlogs/implementation/prd.json && echo "implementation backlog exists"
```

7. **Check for unconverted markdown PRDs**
```bash
find . -path "./docs/prds/*.md" -type f 2>/dev/null | head -5
```

---

## 🔄 Core Workflow

### Phase A — Gather Pending Work Sources

#### Source 1: backlog PRD Map (`.sigma/backlogs/prd-map.json`)

```typescript
interface PRDMap {
  version: string;
  generated: string;
  prds: Array<{
    original_prd: string;
    json_backlog: string;
    status: "pending" | "in_progress" | "completed";
    stories: {
      total: number;
      completed: number;
      pending: number;
    };
  }>;
}
```

**Check for:**
- PRDs with `status: "in_progress"` (highest priority - resume these first)
- PRDs with `status: "pending"` and `stories.pending > 0`

#### Source 2: Individual prd.json Files

Search for canonical backlog files:
```bash
find . -path "./.sigma/backlogs/**/prd.json" 2>/dev/null
```

**Parse each prd.json for pending stories:**
```typescript
interface BacklogStory {
  id: string;
  title: string;
  status: "pending" | "in_progress" | "completed" | "blocked";
  acceptanceCriteria: string[];
}
```

#### Source 3: Sigma Manifest (`.sigma-manifest.json`)

```typescript
interface SigmaManifest {
  active_work?: {
    current_prd: string;
    current_story_id: string;
    last_activity: string;
  };
  commands_run: Record<string, {
    ran_at: string;
    output_files: string[];
  }>;
}
```

**Check for:**
- `active_work` field (explicit continuation point)
- Recent `commands_run` with incomplete outputs

#### Source 4: Git Status

```bash
# Check for in-progress work branches
git branch --list "feat/*" "feature/*" "wip/*" 2>/dev/null

# Check for uncommitted changes
git status --porcelain 2>/dev/null

# Check recent commits for context
git log --oneline -10 2>/dev/null
```

#### Source 5: Prototype Backlog JSON

Check for prototype backlog created by `/prd-json --mode prototype`:

```bash
test -f .sigma/backlogs/prototype/prd.json && echo "prototype backlog exists"
```

**Note:** These are early-stage PRDs from wireframing/prototyping. Lower priority than implementation backlogs.

#### Source 6: Implementation Backlog JSON

Check for implementation backlog created by `/prd-json --mode implementation`:

```bash
test -f .sigma/backlogs/implementation/prd.json && echo "implementation backlog exists"
```

**Note:** These are production-ready PRDs. Should be prioritized for implementation.

#### Source 7: Unconverted Markdown PRDs

Check for markdown PRDs that haven't been converted to JSON:

```bash
find docs/prds -name "*.md" -type f 2>/dev/null
```

**If found, suggest conversion:**
```markdown
Found unconverted PRD: docs/prds/auth.md

Convert to backlog JSON with:
  /prd-json --mode implementation --input=docs/prds/auth.md

Or for prototype flow PRDs:
  /prd-json --mode prototype --input=docs/prds/flows/...
```

### Phase B — Prioritize and Rank Tasks

Create a ranked list of continuation options:

```typescript
interface ContinuationOption {
  id: string;
  title: string;
  source: "backlog" | "manifest" | "git" | "prd";
  priority: number;  // 1 = highest
  context: {
    lastActivity?: string;
    progress?: string;  // "3/10 stories"
    location?: string;  // file path
  };
  action: string;  // what to do to continue
}
```

**Priority Ranking:**
1. **P1** - Explicit `active_work` in manifest
2. **P2** - `in_progress` stories in backlog prd.json
3. **P3** - PRDs with partial completion (some stories done)
4. **P4** - Step 11a implementation PRDs (production-ready)
5. **P5** - Pending PRDs (no stories started)
6. **P6** - Step 5b prototype PRDs (early-stage)
7. **P7** - Git work-in-progress branches
8. **P8** - Unconverted markdown PRDs (need conversion first)

### Phase C — Present Options (Interactive Mode)

```markdown
## 🔄 Unfinished Work Found

### Currently In Progress (Resume First)

| # | Task | Progress | Last Activity | Source |
|---|------|----------|---------------|--------|
| 1 | User Authentication Flow | 3/10 stories | 2 hours ago | backlog |
| 2 | Dashboard Components | 1/5 stories | Yesterday | backlog |

### Pending (Ready to Start)

| # | Task | Stories | PRD Location |
|---|------|---------|--------------|
| 3 | Payment Integration | 8 stories | .sigma/backlogs/implementation/prd.json |
| 4 | Settings Page | 4 stories | .sigma/backlogs/implementation/prd.json |

---

**Enter number to continue, or:**
- `r` - Run /next-task on selection
- `a` - Show all (including completed)
- `q` - Quit
```

### Phase D — Execute Continuation

Based on user selection:

#### Option: Direct Implementation
```markdown
## Continuing: [Task Title]

**PRD:** [path to prd.json]
**Story:** [current story]
**Status:** [X/Y completed]

### Current Story Details

**ID:** story-003
**Title:** Implement password reset flow

**Acceptance Criteria:**
- [ ] Reset email sends within 30 seconds
- [ ] Token expires after 1 hour
- [ ] User can set new password

### Implementation Notes

[Read progress.txt for context]

---

Ready to implement. Starting with:
1. [First acceptance criterion]
```

#### Option: Invoke /next-task (`--auto-run`)
```markdown
## Starting /next-task

**Target:** `.sigma/backlogs/implementation/prd.json` or `.sigma/backlogs/<mode>/TASKS.md`

### Command

\`\`\`bash
/next-task
\`\`\`

Starting execution loop...
```

### Phase E — Update Tracking

After selection, update `.sigma-manifest.json`:

```json
{
  "active_work": {
    "current_prd": ".sigma/backlogs/implementation/prd.json",
    "current_story_id": "story-003",
    "last_activity": "2026-01-11T10:30:00Z"
  }
}
```

---

## 📁 Output

No separate output file. Updates:
- `.sigma-manifest.json` (active_work tracking)
- Console output with continuation options

---

## 🧠 Auto Mode Behavior

When `--mode=auto`:

1. Find highest priority unfinished task
2. Skip interactive menu
3. Immediately begin implementation OR invoke /next-task (if `--auto-run`)

**Use Case:** Continuing work after a break without decision fatigue.

```bash
# "Just continue where I left off"
@continue --mode=auto

# "Run /next-task on whatever's next"
@continue --mode=auto --auto-run
```

---

## 🔗 Integration with /next-task

When `--auto-run` flag is set:

1. Select the target backlog or `TASKS.md`; inspect `TASKS.json` only when the optional machine-readable mirror exists.
2. Verify `.sigma/backlogs/` exists
3. Prompt user to confirm
4. Execute:

```bash
/next-task
```

The execution loop will:
- Read prd.json
- Find next pending story
- Implement with verification
- Update story status
- Commit changes
- Continue to next story

---

## 🚫 Edge Cases

### No Pending Work Found
```markdown
## ✅ Build + implementation caught up!

No pending implementation work found.

**If Step 15 is done**, run Run Track walkthrough:
```bash
@continue --source=run-track
```

**Otherwise start something new:**
- Run `@step-11-prd-generation` to create new PRDs
- Run `@step-5-wireframe-prototypes` for early prototyping
```

### Multiple Active Work Items
```markdown
## ⚠️ Multiple items in progress

You have 3 items marked "in_progress". This may indicate:
- Interrupted work sessions
- Parallel implementation

**Recommendation:** Complete one before starting another.

Pick one to focus on, or mark others as "paused".
```

---

## 🔗 Related Commands

- `@continue --source=run-track` — Post–Step-15 Growth Ops walkthrough (Legal → Marketing → Sales…)
- `@run-marketing` … `@run-legal` — Run Track orchestrators
- `@dev-loop` — Implement F-PRDs after planning
- `@gap-analysis` — Verify implementation completeness
- `@status` — Full workflow status check

---

## 💡 Tips

1. **Run at session start** - Quick way to pick up where you left off
2. **Use `--auto-run` for long sessions** - Let /next-task handle multiple stories
3. **Check `--source=git`** - Find work-in-progress branches you forgot about
4. **Update manifest** - Keep `active_work` current for better continuity

