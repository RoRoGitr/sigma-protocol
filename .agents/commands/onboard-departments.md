---
name: onboard-departments
description: Interactive interview that seeds all 14 department overlay files with project and user context. Run once per new project. Creates {CWD}/.claude/departments/*.md and optionally ~/\.claude/departments/*/user-overlay.md.
allowed-tools: Read, Write, Edit, Bash
---

# /onboard-departments

You are running a structured onboarding interview. Your goal: ask 12 questions, collect answers, and write seven project overlay files plus optionally a set of user overlay files.

Do not summarize, do not skip questions, do not answer on the user's behalf. Ask one question at a time. Wait for the answer before asking the next. Keep the interview conversational — not a form.

After all 12 questions, confirm the answers with the user, then write the files.

---

## Before You Start

Check whether overlay files already exist:

```bash
ls {CWD}/.claude/departments/ 2>/dev/null
```

If files exist and contain content, tell the user:
> "Department overlays already exist for this project. Running this interview will overwrite them. Do you want to continue, or just update specific departments?"

If the user says update specific departments, ask which ones and only rewrite those files.

---

## The Interview (12 Questions)

Introduce the interview with:

> "I'm going to ask you 12 questions to set up your executive team. This takes about 8 minutes. I'll write everything to your overlay files when we're done. Let's start."

---

**Q1 — Role and industry**

> "What's your role, and what industry or market are you building in? A one-sentence answer is fine."

*Routes to:* All user overlays as general professional context.

---

**Q2 — Project description**

> "What are you building in this project? Describe it in 2-3 sentences — what it does, who it's for, and what problem it solves."

*Routes to:* All project overlays as `project_description`.

---

**Q3 — Customer definition**

> "Who is your customer? Give me one sentence — their role, their situation, and what they're trying to accomplish."

*Routes to:* `/marketing` project overlay as `icp_statement`, `/content` as `target_audience`, `/ads` as `primary_audience`.

---

**Q4 — Paid advertising**

> "Do you run paid ads, or are you planning to? (Yes / No / Planning to)"

If Yes or Planning to, ask:

> "Which platforms? (Meta, Google, TikTok, LinkedIn — pick all that apply) And roughly what monthly budget range are you working with — under $1K, $1K–$5K, $5K–$20K, or $20K+?"

If No:

> "Got it. I'll skip the paid ads deep-context for now. You can run /onboard-departments again when you start running ads."

*Routes to:* `/ads` project overlay as `platforms` and `monthly_budget_tier`.

---

**Q5 — Tech stack**

> "What's your tech stack? Just the main pieces — frontend framework, backend language, and where you deploy."

*Routes to:* `/engineering` project overlay as `stack`.

---

**Q6 — Funnel stage**

> "Where are you in the business? Pick the closest:
> (a) Pre-offer — still figuring out what to sell
> (b) Pre-revenue — offer exists, no customers yet
> (c) Scaling — have revenue, trying to grow it
> (d) Established — growing consistently, optimizing"

*Routes to:* `/growth` project overlay as `funnel_stage`, `/finance` as `business_stage`, `/marketing` as `current_phase`.

---

**Q7 — Brand voice**

> "Show me 2 examples of writing you admire — from your own work, a competitor, a book, anything. Or describe your voice in 3 words and one sentence."

If they paste links, note them. If they describe it, capture the 3 words and the sentence.

*Routes to:* `/content` project overlay as `brand_voice_reference`, User Overlay for `/content` as `voice_profile`.

---

**Q8 — Compliance constraints**

> "Do you have any compliance constraints I should know about? Options: HIPAA (health data), financial services regulations, housing/real-estate advertising rules, or none."

If they select a regulated category, ask:
> "Is this a hard constraint (you're subject to it) or a soft one (you want to be cautious)?"

*Routes to:* `/ads` project overlay as `compliance_category` and `constraint_level`.

---

**Q9 — Current biggest bottleneck**

> "Right now, what's the biggest thing slowing you down — marketing, product, revenue, ops, or something else?"

*Routes to:* `/ops` project overlay as `current_priority`, informs which department should lead the first session.

---

**Q10 — Existing assets**

> "What do you already have? Check all that apply: landing page, email list, social following, paid ad account, product in production, paying customers."

*Routes to:* All project overlays as `existing_assets`. Informs CGO on what's available to optimize.

---

**Q11 — Revenue model**

> "How do you charge? (One-time, subscription, usage-based, service retainer, or not charging yet)"

If subscription, ask: "Monthly, annual, or both?"

*Routes to:* `/finance` project overlay as `revenue_model`, `/marketing` as `pricing_model`.

---

**Q12 — Working style**

> "Last one. How do you prefer to work with an AI executive? Three options:
> (a) Give me options and let me decide
> (b) Give me your recommendation and I'll say yes or no
> (c) Just decide and tell me what you chose"

*Routes to:* All user overlays as `decision_style`.

---

## After All 12 Questions

Say:

> "Here's what I captured. Let me know if anything needs correcting before I write the files."

Show a confirmation table:

| Field | Value |
|-------|-------|
| Role/Industry | {Q1 answer} |
| Project | {Q2 answer} |
| Customer | {Q3 answer} |
| Paid Ads | {Q4 answer} |
| Stack | {Q5 answer} |
| Funnel Stage | {Q6 answer} |
| Brand Voice | {Q7 answer} |
| Compliance | {Q8 answer} |
| Bottleneck | {Q9 answer} |
| Existing Assets | {Q10 answer} |
| Revenue Model | {Q11 answer} |
| Decision Style | {Q12 answer} |

After confirmation, write the files.

---

## Writing the Files

### Step 1: Create the directory

```bash
mkdir -p "{CWD}/.claude/departments"
```

### Step 2: Write project overlay files

Write one file per department. Each file uses this format:

```markdown
---
department: {dept}
project: {project name from Q2}
last_updated: {today's date}
---

# {Department} Project Context

## Project
{Q2 answer — project description}

## Customer / ICP
{Q3 answer — customer definition}

## {Department-specific fields from interview}
{Relevant Q answers for this department}

## Constraints
{Q8 if /ads; otherwise any relevant constraints from Q4-Q12}

## Current Priority
{Q9 answer if relevant to this department}

## Existing Assets
{Q10 answer}

## Revenue Model
{Q11 answer}

## Notes
(empty — self-evolution writes here)
```

**Department-specific field mapping:**

| File | Department-Specific Fields |
|------|---------------------------|
| `marketing.md` | `current_phase` (from Q6), `pricing_model` (Q11) |
| `ads.md` | `platforms`, `monthly_budget_tier` (Q4), `compliance_category`, `constraint_level` (Q8) |
| `content.md` | `target_audience` (Q3), `brand_voice_reference` (Q7) |
| `growth.md` | `funnel_stage` (Q6), `existing_assets` (Q10) |
| `engineering.md` | `stack` (Q5) |
| `ops.md` | `current_priority` (Q9) |
| `finance.md` | `business_stage` (Q6), `revenue_model` (Q11) |

### Step 3: Offer to write user overlays

After writing project overlays, ask:

> "Project overlays are written. Do you also want me to write user overlays? These save your voice and preferences to your home directory so they carry across all your projects."

If yes:

```bash
mkdir -p ~/.claude/departments/marketing
mkdir -p ~/.claude/departments/ads
mkdir -p ~/.claude/departments/content
mkdir -p ~/.claude/departments/growth
mkdir -p ~/.claude/departments/engineering
mkdir -p ~/.claude/departments/ops
mkdir -p ~/.claude/departments/finance
mkdir -p ~/.claude/departments/product
mkdir -p ~/.claude/departments/sales
mkdir -p ~/.claude/departments/design
mkdir -p ~/.claude/departments/support
mkdir -p ~/.claude/departments/legal
mkdir -p ~/.claude/departments/trading
mkdir -p ~/.claude/departments/security
```

Write `user-overlay.md` in each with:

```markdown
---
scope: user
department: {dept}
last_updated: {today's date}
---

# User Overlay — {Department}

## Role
{Q1 answer}

## Voice Profile
{Q7 answer — brand voice reference or description}

## Decision Style
{Q12 answer — options / recommendation / just decide}

## Notes
(empty — self-evolution writes here)
```

---

## Closing

After all files are written, say:

> "You're set up. Here's what I created:
>
> **Project overlays** (this project only):
> {CWD}/.claude/departments/{marketing,ads,content,growth,engineering,ops,finance,product,sales,design,support,legal,trading,security}.md
>
> **User overlays** (if you said yes):
> ~/.claude/departments/{dept}/user-overlay.md × 14
>
> You can now run any department command:
> /marketing  /ads  /content  /growth  /engineering  /ops  /finance
> /product  /sales  /design  /support  /legal  /trading  /security
>
> Run /department-status anytime to see what I've learned about each department."

---

## Error Handling

**If a question gets a non-answer ("I don't know", "skip", blank):**
Write `unknown` as the value and add a comment in the overlay: `# TODO: User skipped this — ask again next session`

**If the user is pre-product (has no stack, no customer, no revenue model):**
Still complete the interview. Write `not_defined_yet` for unanswered fields. The CGO and CFO overlays will note pre-offer stage and adjust their default frameworks accordingly.

**If the user is an agency or consultant (multiple clients):**
Note this in all overlays under a `context_type: agency` field. Departments will ask which client's context to apply at the start of each session rather than assuming a single product.
