---
name: architecture-template
description: Generate ARCHITECTURE.md documents following the standard template. Use when creating or updating system architecture documentation.
---

# Architecture Template Skill

> Generate ARCHITECTURE.md documents following the standard template.

## Trigger
Use when creating or updating system architecture documentation.

## Template

```markdown
# System Architecture

## 1. System Overview

### High-Level Diagram
[ASCII or Mermaid diagram]

### Key Components
| Component | Purpose | Technology |
|-----------|---------|------------|
| [Name] | [What it does] | [Stack] |

## 2. Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Frontend | [Tech] | [Why] |
| Backend | [Tech] | [Why] |
| Database | [Tech] | [Why] |
| Auth | [Tech] | [Why] |
| Hosting | [Tech] | [Why] |

## 3. Data Architecture
[ERD or table definitions]
[Data flow description]

## 4. API Design
[REST/GraphQL/tRPC + rationale]
| Method | Endpoint | Purpose |
|--------|----------|---------|

## 5. Security Architecture
- Authentication: [method]
- Authorization: [method]
- Data Protection: [approach]

## 6. Infrastructure
- Deployment: [approach]
- Scaling: [strategy]
- DR: [backup, failover, RTO/RPO]

## 7. Architecture Decision Records (ADRs)
### ADR-001: [Decision Title]
- **Status:** Accepted
- **Context:** [Why]
- **Decision:** [What]
- **Consequences:** [Trade-offs]

## 8. Open Questions
- [ ] [Unresolved question]
```
