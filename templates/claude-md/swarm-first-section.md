# Swarm-First CLAUDE.md Template Section

This template section should be injected into every project's CLAUDE.md by Step 12.

---

## 🐝 Swarm-First Philosophy

**CRITICAL RULE: Never work solo. Always delegate to sub-agents.**

Every task, no matter how simple, should leverage the agent swarm:

### Mandatory Delegation Rules

1. **Always spawn sub-agents** — Use the Task tool to delegate work
2. **Match agents to domains** — Use the right agent for the job (see Agent Registry below)
3. **Invoke skills explicitly** — Sub-agents MUST use `/skill-name` for domain expertise
4. **Parallelize when possible** — Spawn multiple agents for independent work

### Agent Invocation Pattern

```bash
# WRONG - Working solo
[Read files, make edits directly]

# CORRECT - Delegate to swarm
[Spawn lead-architect for design]
[Spawn qa-engineer for QA]
[Spawn verification-loop for verification]
```

### When to Use Each Agent Type

| Task Type | Primary Agent | Supporting Agents |
|-----------|---------------|-------------------|
| Planning/Architecture | lead-architect | -- |
| Code Implementation | backend-engineer | frontend-engineer |
| Bug Fixes | backend-engineer | qa-engineer |
| Research | lead-architect | -- |
| Code Review | qa-engineer | -- |
| Verification | verification-loop | -- |
| Testing | qa-engineer | qa-engineer |
| Documentation | content-director | lead-architect |
| Security Audit | security-lead | security-web-api, security-infra |
| Auth/API Security | security-web-api | security-lead |
| Infra/Supply Chain | security-infra | security-lead |
| Compliance | security-compliance | security-lead |
| Mobile Security | security-mobile | security-lead |
| AI/LLM Safety | security-ai-safety | security-lead |

### Spawning Sub-Agents

```
Use Task tool with:
- subagent_type: "general-purpose" (or specialized type)
- run_in_background: true (for parallel work)
```

---

## 📚 Agent Registry

### Core Agents

| Agent | Domain | Skills to Use | When to Spawn |
|-------|--------|---------------|---------------|
| `lead-architect` | Architecture | @senior-architect, @brainstorming | Planning, design decisions |
| `qa-engineer` | Quality | @senior-qa, @systematic-debugging | Code review, bug fixes |
| `lead-architect` | Investigation | @deep-research, @remembering-conversations | Research, context gathering |
| `verification-loop` | Verification | @quality-gates, @systematic-debugging | Verification loops |
| `frontend-engineer` | UI/UX | @frontend-design, @react-performance, @ux-designer | React, components |
| `backend-engineer` | API/Data | @api-design-principles, @architecture-patterns | APIs, databases |
| `qa-engineer` | Testing | @senior-qa, @quality-gates | Test writing, coverage |
| `content-director` | Documentation | @skill-writer, @output-generation | Docs, README updates |
| `security-lead` | Security Lead | @owasp-web-security, @defense-in-depth, @security-code-review | Security audits, threat modeling |
| `security-web-api` | Web/API Sec | @owasp-web-security, @owasp-api-security, @better-auth-best-practices | Auth review, OWASP Top 10 |
| `security-infra` | Infra Sec | @dependency-security, @secrets-detection | Supply chain, CI/CD, containers |
| `security-compliance` | Compliance | @saas-security-patterns, @security-code-review | SOC 2, GDPR, HIPAA |
| `security-mobile` | Mobile Sec | @mobile-app-security | React Native, iOS, Android |
| `security-ai-safety` | AI Safety | @owasp-llm-security | Prompt injection, LLM security |

### Agent Spawn Examples

```markdown
<!-- Planning a new feature -->
Task: spawn lead-architect
Prompt: "Design the authentication system. Use @senior-architect skill. Output architecture doc."

<!-- Implementing frontend -->
Task: spawn frontend-engineer
Prompt: "Build LoginForm component. Use @frontend-design skill. Follow design system."

<!-- Running verification -->
Task: spawn verification-loop
Prompt: "Verify all acceptance criteria for S001. Use @systematic-debugging if issues found."
```

---

## 🗂️ Skills Registry ({{SKILL_COUNT}} Skills by Category)

### Quick Lookup: Find the right skill instantly

<!-- Step 13 auto-generates this section based on actual skills in .claude/skills/ -->

{{SKILLS_BY_CATEGORY}}

---

## Skill Invocation Rules

1. **Always prefix with `/`** — Use `/skill-name` not just `skill-name`
2. **Match skill to task** — Check the "Use When" column
3. **Chain skills** — Complex tasks may need multiple skills in sequence
4. **Sub-agents inherit** — When spawning, tell the sub-agent which skills to use

### Example Skill Chains

```markdown
<!-- New feature implementation -->
1. /brainstorming — Explore approaches
2. /senior-architect — Design solution
3. /frontend-design — Build UI
4. /senior-qa — Write tests
5. /systematic-debugging — Fix issues

<!-- Bug fix workflow -->
1. /systematic-debugging — Diagnose root cause
2. /senior-qa — Verify fix
3. /quality-gates — Ensure no regressions
```
