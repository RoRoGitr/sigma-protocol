# Agent Registry Template

This template defines the agent-to-task mapping for swarm-first projects.
Step 12 injects this into CLAUDE.md during context engine generation.

---

## Agent Registry

### Core Agent Roles

| Agent Name | Domain | Primary Skills | When to Spawn |
|------------|--------|----------------|---------------|
| `lead-architect` | Planning & Architecture | `@senior-architect`, `@brainstorming` | Design decisions, system planning, PRD review |
| `qa-engineer` | Quality Assurance | `@senior-qa`, `@systematic-debugging` | Code review, bug investigation |
| `lead-architect` | Investigation | `@deep-research`, `@remembering-conversations` | Research, context gathering, docs lookup |
| `verification-loop` | Verification | `@quality-gates`, `@gap-analysis` | Verification loops, acceptance testing |
| `frontend-engineer` | UI/UX | `@frontend-design`, `@react-performance`, `@ux-designer` | React components, styling, UX |
| `backend-engineer` | API/Data | `@api-design-principles`, `@architecture-patterns` | APIs, server actions, database |
| `qa-engineer` | Testing | `@senior-qa`, `@quality-gates`, `@systematic-debugging` | Test writing, coverage |
| `content-director` | Documentation | `@skill-writer`, `@output-generation` | Docs, README, comments |
| `security-lead` | Security Lead | `@owasp-web-security`, `@owasp-api-security`, `@defense-in-depth`, `@security-code-review` | Threat modeling, security audit coordination, risk prioritization |
| `security-web-api` | Web/API Security | `@owasp-web-security`, `@owasp-api-security`, `@better-auth-best-practices` | Auth review, injection checks, XSS, BOLA |
| `security-infra` | Infra Security | `@dependency-security`, `@secrets-detection` | Container scanning, CI/CD hardening, supply chain |
| `security-compliance` | Compliance | `@saas-security-patterns`, `@security-code-review` | SOC 2, GDPR, HIPAA, PCI-DSS audits |
| `security-mobile` | Mobile Security | `@mobile-app-security`, `@owasp-web-security` | React Native security, certificate pinning, secure storage |
| `security-ai-safety` | AI Safety | `@owasp-llm-security`, `@dependency-security` | Prompt injection, LLM output validation, AI supply chain |

### Task Type Routing

| Task Pattern | Primary Agent | Fallback |
|--------------|---------------|----------|
| `**/*.test.*`, `**/*.spec.*` | `qa-engineer` | `qa-engineer` |
| `docs/prds/**` | `lead-architect` | `lead-architect` |
| `**/auth/**`, `**/middleware/**` | `security-web-api` | `security-lead` |
| `**/security/**`, `**/policies/**` | `security-lead` | `security-compliance` |
| `Dockerfile`, `*.yml` (CI/CD) | `security-infra` | `security-lead` |
| `**/ai/**`, `**/llm/**`, `**/prompts/**` | `security-ai-safety` | `security-lead` |
| `**/mobile/**`, `**/ios/**`, `**/android/**` | `security-mobile` | `security-lead` |

### Spawning Pattern

```markdown
<!-- Planning a new feature -->
Task tool: spawn lead-architect
Prompt: "Design the authentication system. Use @senior-architect skill. Output architecture doc."

<!-- Implementing frontend -->
Task tool: spawn frontend-engineer
Prompt: "Build LoginForm component. Use @frontend-design skill. Follow design system."

<!-- Running verification -->
Task tool: spawn verification-loop
Prompt: "Verify all acceptance criteria for PRD-001. Use @gap-analysis if issues found."

<!-- Research before implementation -->
Task tool: spawn lead-architect
Prompt: "Research Supabase RLS patterns for multi-tenant apps. Use @deep-research skill."

<!-- Security audit -->
Task tool: spawn security-lead
Prompt: "Run full security audit. Coordinate security-web-api for OWASP Top 10, security-infra for dependencies."

<!-- Compliance check -->
Task tool: spawn security-compliance
Prompt: "Run SOC 2 compliance check. Use @saas-security-patterns skill. Output compliance report."
```

### Agent Communication Protocol

Agents communicate through:
1. **Task tool results** - Direct response back to parent
2. **AGENTS.md updates** - Long-term learnings persist here
3. **File artifacts** - Code, docs, configs they produce

### Parallel vs Sequential

**Parallel (independent work):**
```markdown
Use Task tool multiple times in same message:
- frontend-engineer: Build Header component
- frontend-engineer: Build Footer component
- backend-engineer: Create auth endpoints
```

**Sequential (dependencies):**
```markdown
1. lead-architect: Design the feature architecture
2. [wait for result]
4. [wait for result]
5. qa-engineer: Verify implementation
```
