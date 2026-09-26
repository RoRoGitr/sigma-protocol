---
name: skill-registry
description: "Master registry of all skills categorized by task type. Use when generating CLAUDE.md, AGENTS.md, or selecting skills for task execution. Select skills by the actual task, intended outcome and applicability; keywords are discovery hints only."
triggers:
  - step-12-context-engine
  - step-13-skillpack-generator
  - orchestrate
  - prd-orchestrate
---

# Skill Registry

Master catalog of skills organized by task type for relevance-based selection.

---

## How to Use This Registry

When selecting skills for a task:
1. Identify the requested outcome, affected surfaces and required workflow. Use keywords only to discover candidates; a word or file extension alone is not an activation rule.
2. Read candidate descriptions and invoke only skills whose actual purpose applies to this task. Honor explicitly requested skills and mandatory project ceremonies; do not load every skill in a matching category.
3. For swarm execution, assign each agent the skills relevant to its actual task. The swarm-size and ceremony policies below remain unchanged.

---

## Skills by Category

### PLANNING & IDEATION
**Keywords:** plan, ideate, brainstorm, design, architect, requirements, PRD, strategy

| Skill | When to Use |
|-------|-------------|
| `deep-research` | **ALWAYS FIRST** - Before any planning, research context |
| `brainstorming` | After research, before ANY creative work |
| `executing-plans` | When you have a written plan to execute |
| `marketing-psychology` | When designing offers, pricing, or conversion flows |

**Applicability rule:** For actual planning or ideation, apply the required research-before-brainstorming workflow. A quoted keyword or a routine task mentioning a plan does not by itself start that workflow.

---

### FRONTEND & UI
**Keywords:** component, UI, page, layout, design system, wireframe, landing page, styling

| Skill | When to Use |
|-------|-------------|
| `frontend-design` | Building any UI component or page |
| `react-performance` | Any React/Next.js implementation |
| `marketing-copywriting` | Landing pages, marketing pages |

**Applicability rule:** For work that designs or changes a frontend interface, invoke `frontend-design`; a path or file extension alone does not establish design work.

---

### BACKEND & API
**Keywords:** API, endpoint, database, server action, authentication, integration

| Skill | When to Use |
|-------|-------------|
| `verification-before-completion` | Before claiming ANY backend work complete |

**Applicability rule:** Before claiming backend work complete, invoke `verification-before-completion` and use checks applicable to the changed behavior.

---

### TESTING & QA
**Keywords:** test, QA, verify, validate, check, audit, regression

| Skill | When to Use |
|-------|-------------|
| `verification-before-completion` | Before ANY completion claim |
| `tdd-skill-creation` | When creating new skills or commands |
| `react-performance` | Performance testing |
| `seo-audit` | SEO verification |

**Applicability rule:** For verification work or a completion claim, invoke `verification-before-completion`; a mention of a test in unrelated prose does not activate a QA workflow.

---

### DOCUMENTATION & WRITING
**Keywords:** docs, README, changelog, PR, commit, proposal, contract

| Skill | When to Use |
|-------|-------------|
| `writing-clearly` | ANY prose for humans |
| `marketing-copywriting` | Marketing documentation |

**Applicability rule:** For human-facing prose where writing guidance applies, use `writing-clearly`; a Markdown extension alone does not activate it.

---

### MARKETING & GROWTH
**Keywords:** marketing, launch, SEO, copy, ads, email, social, pricing

| Skill | When to Use |
|-------|-------------|
| `marketing-copywriting` | Any marketing copy |
| `marketing-psychology` | Conversion optimization, pricing |
| `seo-audit` | SEO work |
| `launch-strategy` | Product/feature launches |

**Applicability rule:** For actual marketing work, select the skill for the requested deliverable, such as copy, conversion analysis, SEO or launch planning.

---

### AGENT HARNESS & INFRASTRUCTURE
**Keywords:** harness, tool system, hook pipeline, agent architecture, CLI agent, permission system

| Skill | When to Use |
|-------|-------------|
| `harness-engineering` | Building CLI agent harnesses, tool systems, hook pipelines |
| `context-engineering-advanced` | Session-level context management, compaction, memory extraction |
| `agent-spawning-patterns` | Multi-agent systems, coordinator/worker, team memory |
| `dream-consolidation` | Background memory consolidation, overnight learning |
| `permission-engineering` | Permission layers, bash security, tool access control |
| `feature-flag-architecture` | Feature flags (compile-time, runtime, per-user gating) |

**Applicability rule:** For harness architecture use `harness-engineering`; for session context management use `context-engineering-advanced`; for agent coordination design use `agent-spawning-patterns`. Select by the problem being worked on, not a keyword mention.

---

### PAYMENTS & AGENT ECONOMY
**Keywords:** x402, agent wallet, crypto payment, USDC, machine payment, agent economy

| Skill | When to Use |
|-------|-------------|
| `x402-integration` | Machine-to-machine USDC payments, agent wallets, spending limits |

**Applicability rule:** For implementing or reviewing x402 payments, agent wallets or their spending controls, use `x402-integration`.

---

### COMPANION & GAMIFICATION
**Keywords:** companion, gacha, pet system, rarity, collectible, buddy

| Skill | When to Use |
|-------|-------------|
| `companion-system` | Gacha companion design, species, rarity, cosmetics, marketplace |

**Applicability rule:** For designing or implementing a companion or gacha system, use `companion-system`.

---

### ORCHESTRATION & SWARMS
**Keywords:** orchestrate, swarm, parallel, agents, distribute

| Skill | When to Use |
|-------|-------------|
| `subagent-driven-development` | Same-session parallel execution |
| `dispatching-parallel-agents` | Multiple independent problems |
| `executing-plans` | Batch execution with checkpoints |

**Applicability rule:** For an authorized parallel-execution task with independently actionable subtasks, use `dispatching-parallel-agents`. Follow the existing swarm ceremony and sizing policy below.

---

## Swarm Assignment Rules

When distributing tasks to swarm agents, use the matrix as a candidate list and assign only skills relevant to each actual task; preserve the required research/review ceremony:

```yaml
agent_skill_assignment:
  planning_agents:
    - deep-research        # ALWAYS FIRST
    - brainstorming
    - executing-plans

  frontend_agents:
    - frontend-design
    - react-performance
    - marketing-copywriting  # if landing page

  backend_agents:
    - verification-before-completion
    - x402-integration         # if payment-related

  harness_architects:
    - harness-engineering
    - context-engineering-advanced
    - agent-spawning-patterns
    - permission-engineering
    - feature-flag-architecture

  dream_engineers:
    - dream-consolidation
    - context-engineering-advanced
    - agent-spawning-patterns

  x402_engineers:
    - x402-integration
    - auth-patterns
    - api-design-principles

  companion_designers:
    - companion-system
    - frontend-design
    - ux-psychology

  qa_agents:
    - verification-before-completion
    - tdd-skill-creation

  documentation_agents:
    - writing-clearly

  marketing_agents:
    - deep-research        # for competitor analysis
    - marketing-copywriting
    - marketing-psychology
    - seo-audit
    - launch-strategy
```

---

## CLAUDE.md / AGENTS.md Template Section

**Include this in generated CLAUDE.md files:**

```markdown
## Automatic Skill Invocation

Before executing a task, identify the actual requested outcome and select applicable skills. Keywords and file extensions are discovery hints, not sufficient activation conditions. Honor explicitly requested skills and the mandatory project ceremonies; load only relevant skills.

| Actual Task | Applicable Skill |
|-------------|------------------|
| Planning or ideation | deep-research, then brainstorming under the planning ceremony |
| Designing or changing a frontend interface | frontend-design |
| Verifying work or making a completion claim | verification-before-completion |
| Writing human-facing prose | writing-clearly when its guidance applies |
| Marketing deliverable | The specific applicable marketing skill, not the whole category |
| Authorized parallel execution of independent tasks | dispatching-parallel-agents under the swarm policy below |

## Swarm Execution (Default Mode)

**Never work solo. Always use swarms for PRD execution.**

Minimum swarm size by task complexity:
- Simple PRD (1-3 features): 5 agents
- Medium PRD (4-7 features): 10 agents
- Complex PRD (8+ features): 15-20 agents

Each agent receives:
1. Specific task assignment
2. Relevant skills from registry
3. Verification requirements
```

---

## Integration Points

### Step 12 (Context Engine)
Generate CLAUDE.md with:
- Swarm-first philosophy
- Task-relevance skill selection table
- Agent skill assignment matrix

### Step 13 (Skillpack Generator)
Fill skill placeholders with:
- Project-specific skill list
- Categorized skill registry
- Discovery keywords plus explicit task applicability

### Sigma Planner Agent
When planning tasks:
1. Read this registry
2. Categorize each task
3. Assign skills to agents
4. Distribute to swarm

---
