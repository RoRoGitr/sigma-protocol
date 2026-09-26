# Agent DNA Template

How to create custom agents for the Sigma Protocol harness. Agents are specialized AI workers with embedded methodology, constraints, and collaboration rules. This guide covers the full DNA structure, creation process, and common pitfalls.

---

## Table of Contents

1. [Frontmatter Schema](#frontmatter-schema)
2. [DNA Sections](#dna-sections)
3. [Agent Creation Checklist](#agent-creation-checklist)
4. [Model Selection Guide](#model-selection-guide)
5. [Anti-Patterns](#anti-patterns)
6. [Examples by Category](#examples-by-category)

---

## Frontmatter Schema

Every agent definition starts with YAML frontmatter. This is machine-parsed by the harness at runtime.

```yaml
---
# REQUIRED FIELDS
name: agent-name                    # Lowercase, hyphenated. Used for spawning: "sigma-{name}"
description: "What this agent does" # 1-2 sentences. Include trigger keywords for auto-routing.

# MODEL & TOOLS
model: claude-sonnet-4-6            # See Model Selection Guide below
tools:                              # Only the tools this agent needs (principle of least privilege)
  - Read                            # Read files
  - Write                           # Create/overwrite files
  - Edit                            # Modify existing files
  - Bash                            # Run shell commands
  - Glob                            # File pattern matching
  - Grep                            # Content search
  - LSP                             # Language server (type checking, go-to-definition)

# OPTIONAL FIELDS
color: "#5B8A72"                    # Hex color for UI identification
version: "1.0.0"                    # SemVer for tracking agent evolution
memory: project                     # Memory scope (see Memory Scopes below)
permissionMode: acceptEdits         # Permission level (see Permission Modes below)
skills:                             # Skills invoked per-project (see Skills section)
  - skill-name-1
  - skill-name-2
triggers:                           # Keywords that auto-route tasks to this agent
  - keyword-1
  - keyword-2
---
```

### Field Reference

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Agent identifier. Lowercase, hyphenated. |
| `description` | Yes | string | What the agent does + trigger keywords. |
| `model` | Yes | string | `claude-opus-4-6` or `claude-sonnet-4-6` |
| `tools` | Yes | string[] | Tools the agent can use. |
| `color` | No | string | Hex color code for UI display. |
| `version` | No | string | SemVer version string. |
| `memory` | No | string | `project`, `local`, or `user`. Default: none. |
| `permissionMode` | No | string | How the agent handles file modifications. |
| `skills` | No | string[] | Skills to invoke for specialized tasks. |
| `triggers` | No | string[] | Keywords that auto-route work to this agent. |

### Memory Scopes

`.claude/agent-memory/` is the **Claude-native runtime cache** — per-agent operational scratch the runtime reads/writes during execution. It is disposable and gitignored in Sigma. Durable, cross-session project knowledge (decisions, conventions, gotchas) belongs in the **methodology memory** at `.sigma/memory/project/` instead (see Step 12 → *Two memory layers*).

| Scope | Storage Location | Persistence | Use When |
|-------|-----------------|-------------|----------|
| `project` | `.claude/agent-memory/` | Gitignored runtime cache (promote durable items to `.sigma/memory/project/`) | Agent's operational scratch for project-specific patterns |
| `local` | `.claude/agent-memory-local/` | Gitignored, this machine only | Sensitive data (security findings, credentials context) |
| `user` | `~/.claude/agent-memory/` | Per-machine, cross-repo | Cross-project operational learnings (research sources, preferences) |
| *(none)* | N/A | N/A | Stateless agents (reviewers, auditors, fork workers) |

### Permission Modes

| Mode | Behavior | Use When |
|------|----------|----------|
| `default` | Asks before every file change | Read-only agents, reviewers |
| `plan` | Shows plan, asks for approval | Agents that need oversight |
| `acceptEdits` | Applies edits, user can review | Standard implementation agents |
| `dontAsk` | Applies without asking | Trusted automation agents |
| `bypassPermissions` | No permission prompts at all | Overnight/unattended agents |

### Tool Selection Guide

Assign only the tools an agent actually needs:

| Tool | Give To | Do NOT Give To |
|------|---------|----------------|
| `Read` | All agents | Never omit |
| `Write` | Implementation agents | Read-only reviewers |
| `Edit` | Implementation agents | Read-only reviewers |
| `Bash` | Agents that run tests, builds, or CLI commands | Pure analysis agents |
| `Glob` | Agents that search for files | Agents that receive explicit file lists |
| `Grep` | Agents that search file contents | Agents that receive explicit file lists |
| `LSP` | Agents that need type information | Non-code agents |
| `Task` | Coordinator agents that spawn sub-agents | Leaf worker agents |
| `Agent` | Coordinator agents that spawn sub-agents | Leaf worker agents |

**Coordinator tools:** Only agents that orchestrate other agents should have `Task` or `Agent`. If an agent has these, document exactly which sub-agents it can spawn.

```yaml
# Coordinator example — restricted Task tool
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - "Task(agent-a, agent-b, agent-c)"  # Explicit sub-agent allowlist
```

---

## DNA Sections

The body of the agent definition (after the frontmatter) contains the agent's DNA. DNA is embedded ideology — methodology that shapes every decision the agent makes, regardless of project or tech stack.

### Required Sections

#### 1. Persona (Opening)

A 2-3 sentence persona establishing expertise and perspective. This grounds the agent's decision-making.

```markdown
# Agent Name

You are a **[Title]** with [N]+ years [specific experience]. You [core philosophy statement].
```

**Rules:**
- State specific companies/contexts for credibility anchoring
- Include a core belief that guides decisions ("You believe the best architecture is the simplest one that solves the problem")
- Keep it to 2-3 sentences. The DNA sections carry the details.

#### 2. DNA -- Core Methodology

The agent's fundamental approach to work. These rules apply regardless of tech stack, language, or project.

```markdown
## DNA -- Core Methodology

### [Methodology Area 1]
- **Principle name.** Explanation of the principle and why it matters.
- **Another principle.** Concrete guidance, not abstract philosophy.

### [Methodology Area 2]
- ...
```

**Rules:**
- Each principle starts bold with a period. Explanation follows.
- Principles are prescriptive ("Do X because Y"), not descriptive ("X is important")
- 3-6 methodology areas, 3-7 principles each
- No implementation code in DNA. Patterns and constraints, not snippets.

#### 3. Writing Quality

Every agent must produce clear, direct output. Include this section in every agent.

```markdown
### Writing Quality
- No hedging ("might", "could perhaps") -- be direct and declarative
- No slop words ("dive in", "game-changing", "seamless", "robust", "leverage", "delve")
- Active voice, precision over politeness
- Error messages say what went wrong AND what to do about it
```

#### 4. Code Simplification (for implementation agents)

```markdown
### Code Simplification
- After every implementation, review for unnecessary complexity before reporting done
- Prefer readable, explicit code over compact clever solutions
- Remove dead code, unused imports, redundant abstractions on every pass
- If 3 similar lines are clearer than 1 abstraction, keep the 3 lines
- Simplify control flow: early returns over nested ifs, guard clauses over deep nesting
- One function = one job. If you need "and" to describe it, split it.
- No premature optimization -- measure first, optimize the hot path only
```

#### 5. Negative Boundaries

What the agent must NOT do. This prevents scope creep and role confusion.

```markdown
## Negative Boundaries

- This agent does NOT [action] -- that is **[correct-agent-name]**
- This agent does NOT [action] -- [reason]
```

**Rules:**
- Every boundary references which agent DOES handle that responsibility
- Include at least 3-5 boundaries
- Be specific: "Does NOT write backend API code" not "Does NOT do backend stuff"

#### 6. Collaboration

How this agent works with others. Defines the handoff chain.

```markdown
## Collaboration

- **Receives from**: [who sends work to this agent]
- **Hands off to**: [who this agent sends work to]
- **Reports to**: [who reviews this agent's output]
- **Escalates to**: [who handles blockers]
```

### Optional Sections

#### DNA (auto-enhanced)

Research-derived rules that supplement the core methodology. Added by the Self-Learning Agent System (SLAS) after pattern analysis.

```markdown
## DNA (auto-enhanced)

_Rules derived from [year] [domain] research._

- **Bold principle statement.** Supporting evidence and application guidance.
```

#### Tech Stack Skills

References to skills the agent invokes for project-specific work.

```markdown
## Tech Stack Skills (invoke per project)

- When [doing X]: invoke **$skill-name**
- When [doing Y]: invoke **$other-skill**
```

#### Anti-Patterns

Patterns this agent explicitly rejects.

```markdown
## Anti-Patterns You Reject

- [Anti-pattern] -- [what to do instead]
```

#### Task Sizing

Guidance for matching task complexity to model tier.

```markdown
## Task Sizing

- **Small** (sonnet): [scope description]
- **Medium** (opus): [scope description]
- **Large** (opus): [scope description]
```

#### Role-Specific Instructions

Detailed workflow, checklists, or templates unique to this agent's function.

```markdown
## Role-Specific Instructions

### [Workflow Name]
1. Step one
2. Step two
...
```

#### Report Format / Output Format

Structured template for the agent's deliverables.

```markdown
### Completion Report

| Field | Content |
|-------|---------|
| Status | COMPLETE / COMPLETE WITH CAVEATS |
| Files Changed | [list] |
| Tests Added | [list] |
| Remaining Concerns | [list] |
```

---

## Agent Creation Checklist

Follow this sequence when creating a new agent.

### Step 1: Define the Role

- [ ] Write a 1-sentence description of what this agent does
- [ ] Identify 3-5 trigger keywords that should route tasks to this agent
- [ ] Confirm no existing agent already covers this domain (check `docs/AGENT-CAPABILITY-MATRIX.md`)
- [ ] Determine if an existing agent can be enhanced instead of creating a new one

### Step 2: Choose the Model

- [ ] Select `claude-opus-4-6` for: orchestration, architecture, security, complex reasoning
- [ ] Select `claude-sonnet-4-6` for: focused implementation, routine coding, content generation

### Step 3: Assign Tools

- [ ] Start with the minimum: `[Read, Grep, Glob]`
- [ ] Add `Write`, `Edit` only if the agent creates or modifies files
- [ ] Add `Bash` only if the agent runs commands (tests, builds, CLI tools)
- [ ] Add `LSP` only if the agent needs type-checking or go-to-definition
- [ ] Add `Task`/`Agent` only if this is a coordinator (document the sub-agent allowlist)

### Step 4: Write the DNA

- [ ] Write the persona (2-3 sentences with specific expertise)
- [ ] Define core methodology (3-6 areas, 3-7 principles each)
- [ ] Include Writing Quality section
- [ ] Include Code Simplification section (if implementation agent)
- [ ] Define negative boundaries (3-5 minimum, reference the correct agent for each)
- [ ] Define collaboration chain (receives from, hands off to, reports to, escalates to)

### Step 5: Configure Memory and Permissions

- [ ] Choose memory scope: `project` (shared), `local` (sensitive), `user` (cross-project), or none (stateless)
- [ ] Choose permission mode: `default` (reviewers), `acceptEdits` (implementers), `bypassPermissions` (automation)

### Step 6: Add Skills

- [ ] List skills this agent should invoke for specialized tasks
- [ ] Document when each skill is triggered (in the Tech Stack Skills section)

### Step 7: Place the File

- [ ] Save to `.claude/agents/{department}/{agent-name}.md`
- [ ] Choose the correct department folder:

| Department | Agents That Belong Here |
|------------|------------------------|
| `engineering/` | Frontend, backend, mobile, DevOps, architect, infrastructure |
| `qa/` | QA engineer, devil's advocate, gap analyst, verification agents |
| `security/` | Security lead, web/API security, infra security, compliance, AI safety |
| `product/` | Product owner, venture studio partner, business analysts |
| `design/` | UX director, design systems architect, visual designers |
| `marketing/` | Content director, growth engineer, SEO specialists |
| `community/` | Community lead, Discord, Telegram, media generation, research |
| `trading/` | Quant strategist, market data engineer, risk analysts |

### Step 8: Validate

- [ ] Run the agent on a small test task to verify it stays within its boundaries
- [ ] Confirm it does NOT attempt work assigned to other agents
- [ ] Confirm it produces structured output (not free-text narratives)
- [ ] Confirm the collaboration chain is correct (no orphaned handoffs)

---

## Model Selection Guide

### claude-opus-4-6

Use for agents that require deep reasoning, multi-step planning, or cross-domain synthesis.

| Role Type | Examples |
|-----------|---------|
| Orchestrators | Lead architect, security lead, community lead |
| Quality gates | QA engineer, devil's advocate, gap analyst |
| Complex reasoning | Architecture decisions, threat modeling, trade-off analysis |
| Security review | Any agent that evaluates security posture |

**Context window:** Up to 1M tokens. Handles large codebases without degradation.

### claude-sonnet-4-6

Use for agents that execute focused tasks within well-defined scope.

| Role Type | Examples |
|-----------|---------|
| Implementation | Frontend engineer, backend engineer, mobile developer |
| Content generation | Product owner (PRDs), content director, media generation |
| Routine operations | DevOps, observability engineer, market data engineer |
| Focused analysis | Quant strategist (within defined methodology) |

**Context window:** Resets at 500K tokens. Best for file-scoped, bounded tasks.

### Decision Matrix

| Question | Opus | Sonnet |
|----------|------|--------|
| Does it spawn sub-agents? | Yes | Rarely |
| Does it make architecture decisions? | Yes | No |
| Does it evaluate security? | Yes | No |
| Is it the final quality gate? | Yes | No |
| Does it implement code within a defined spec? | No | Yes |
| Does it follow a fixed checklist/workflow? | Sometimes | Yes |
| Is the scope bounded to specific files? | No | Yes |

---

## Anti-Patterns

### 1. Implementation Code in DNA

DNA defines methodology and constraints, not code. If you put function implementations in the DNA, the agent will copy-paste them instead of reasoning about the right approach.

**Wrong:**
```markdown
### API Design
Always use this exact middleware pattern:
\`\`\`typescript
app.use((req, res, next) => {
  // validate, authenticate, authorize
})
\`\`\`
```

**Right:**
```markdown
### API Design
- Auth checks happen at the middleware level, before the request handler executes
- Authentication verifies identity (JWT, session). Authorization verifies permission (RBAC, ABAC)
- Both run as middleware. Never check auth inside business logic.
```

### 2. Agents That Are Too Broad

An agent that does "everything backend" will produce mediocre results across all domains. Narrow agents with deep expertise outperform broad generalists.

**Wrong:** "Full-Stack Engineer -- handles frontend, backend, database, deployment, and testing"

**Right:** Separate agents for frontend, backend, DevOps, and QA with clear boundaries between them.

### 3. Duplicated Functionality

Two agents that both handle input validation will produce conflicting approaches. Every capability should have exactly one owner.

**Check before creating:** Does any existing agent already cover this domain? Can an existing agent be enhanced with additional DNA instead?

### 4. Over-Tooling

Giving every agent all tools defeats the principle of least privilege. A devil's advocate with `Write` and `Edit` tools will be tempted to fix issues instead of reporting them -- destroying the actor-critic separation.

**Rule:** Start minimal. Add tools only when the agent cannot complete its core function without them.

### 5. Vague Negative Boundaries

"This agent does not do backend stuff" is useless. Name the specific agent that handles each excluded responsibility.

**Wrong:** "Does NOT handle infrastructure"

**Right:** "Does NOT configure CI/CD pipelines or deployment automation -- that is **devops**"

### 6. Missing Collaboration Chain

An agent with no collaboration section creates orphaned handoffs. Every agent must define who sends it work, who receives its output, and who reviews it.

### 7. Stateful Reviewers

Agents like devil's advocate and gap analyst should be stateless (no `memory` field). Memory introduces bias -- a reviewer that "remembers" previous reviews may become lenient over time. Fresh perspective on every run produces better adversarial review.

### 8. Coordinator Agents That Implement

Coordinators (agents with `Task`/`Agent` tools) should never write code. They plan, delegate, and review. If a coordinator is writing code, it is doing two jobs and doing both poorly.

---

## Examples by Category

### Minimal Implementation Agent (Leaf Worker)

```yaml
---
name: api-developer
description: "API Developer -- builds REST endpoints with input validation, auth middleware, and structured error responses."
model: claude-sonnet-4-6
tools: [Read, Write, Edit, Bash, Grep, Glob]
memory: project
permissionMode: acceptEdits
skills: [api-design-principles, verification]
---
```

### Read-Only Reviewer (Quality Gate)

```yaml
---
name: code-reviewer
description: "Code Reviewer -- adversarial review of implementation quality, security, and completeness. Read-only."
model: claude-opus-4-6
tools: [Read, Grep, Glob, Bash]
permissionMode: default
skills: [verification-before-completion, quality-gates]
---
```

### Coordinator (Team Lead)

```yaml
---
name: team-lead
description: "Team Lead -- orchestrates implementation agents, delegates tasks, reviews completion reports."
model: claude-opus-4-6
tools: [Read, Grep, Glob, Bash, "Task(api-developer, frontend-dev, qa-reviewer)"]
memory: project
permissionMode: default
skills: [executing-plans]
---
```

### Domain Specialist (Non-Code)

```yaml
---
name: product-analyst
description: "Product Analyst -- writes feature specs, acceptance criteria, and BDD scenarios. Does not write code."
model: claude-sonnet-4-6
tools: [Read, Write, Edit, Grep, Glob]
memory: project
permissionMode: acceptEdits
skills: [brainstorming, bdd-scenarios]
---
```

---

## File Placement

```
.claude/
  agents/
    {department}/
      {agent-name}.md       # Agent definition (this template)
  agent-memory/              # project-scoped memory (committed)
  agent-memory-local/        # local-scoped memory (gitignored)
  skills/
    {category}/
      {skill-name}/
        SKILL.md             # Skill definition (invoked by agents)
```

---

## Quick Reference: DNA Section Order

1. Frontmatter (YAML)
2. `# Agent Name` (H1 heading)
3. Persona paragraph
4. `## DNA -- Core Methodology`
5. `### [Methodology Areas]` (3-6 subsections)
6. `### Writing Quality` (mandatory)
7. `### Code Simplification` (if implementation agent)
8. `## DNA (auto-enhanced)` (if research-derived rules exist)
9. `## Tech Stack Skills` (if skills are assigned)
10. `## Negative Boundaries`
11. `## Anti-Patterns You Reject` (optional)
12. `## Role-Specific Instructions` (optional)
13. `## Collaboration`
