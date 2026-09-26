---
name: reducing-entropy
description: "Reduce codebase complexity and disorder through targeted refactoring. Use when simplifying tangled code, removing dead paths, or clarifying abstractions. Triggers on \'reduce entropy\', \'simplify code\', \'reduce complexity\', \'code clarity\'."
triggers: ["token budget", "context limit", "minimize", "compress", "entropy", "optimization", "context window", "efficiency"]
priority: critical
tags: [context-optimization, token-efficiency, agent-performance, core]
department: core
---

# Reducing Entropy — Context Optimization & Token Efficiency

Systematic context reduction and token optimization techniques for AI agents. Enables 25-35% reduction in context window usage while maintaining task completion quality.

## Core Principles

### 1. Information Hierarchy
```
CRITICAL → HIGH → MEDIUM → LOW → NOISE
└─ Keep  → Keep → Compress → Summarize → Remove
```

### 2. Context Prioritization Rules
| Priority | Content Type | Action |
|----------|-------------|--------|
| **CRITICAL** | Current task requirements, API schemas | Keep verbatim |
| **HIGH** | Recent conversation context, error messages | Keep with light compression |
| **MEDIUM** | Related code patterns, examples | Compress to key patterns |
| **LOW** | General documentation, background info | Summarize to bullet points |
| **NOISE** | Redundant examples, verbose explanations | Remove entirely |

### 3. Token Budget Guidelines
- **Large Tasks (>10k tokens)**: Target 60% of available context
- **Medium Tasks (5-10k tokens)**: Target 70% of available context
- **Small Tasks (<5k tokens)**: Target 80% of available context
- **Emergency (near limit)**: Aggressive compression to 50%

## Optimization Techniques

### Code Context Reduction

**Before (Verbose):**
```python
# This function handles user authentication and validates credentials
# It takes a username and password as input parameters
# Returns True if authentication succeeds, False otherwise
def authenticate_user(username: str, password: str) -> bool:
    # First we need to hash the password for security
    hashed_password = hash_password(password)
    # Then we query the database to find the user
    user = database.get_user(username)
    # Finally we compare the hashed passwords
    return user and user.password_hash == hashed_password
```

**After (Compressed):**
```python
def authenticate_user(username: str, password: str) -> bool:
    """Auth user via password hash comparison"""
    hashed_password = hash_password(password)
    user = database.get_user(username)
    return user and user.password_hash == hashed_password
```
**Savings: 68% reduction**

### Documentation Compression

**Before (Verbose):**
```
The platform uses FastAPI for the backend API layer. FastAPI provides automatic
OpenAPI documentation generation, type hints for request/response validation,
and async/await support for high-performance operations. The platform integrates
with multiple data sources including Redis for caching and PostgreSQL for
persistent storage.
```

**After (Compressed):**
```
Stack: FastAPI (async, OpenAPI auto-docs) + Redis (cache) + PostgreSQL (storage)
```
**Savings: 80% reduction**

### Agent Communication Compression

**Before:**
```
I have completed the analysis of the authentication module. The module contains
three main components: the JWT token generator, the OAuth2 flow handler, and
the session manager. I found that the JWT token generator has a potential
security issue where tokens are not being rotated properly.
```

**After:**
```
Auth module analysis: 3 components (JWT, OAuth2, sessions). Finding: JWT tokens
not rotating properly — security risk.
```
**Savings: 65% reduction**

## When to Apply

| Trigger | Action |
|---------|--------|
| Context window >60% full | Apply MEDIUM-priority compression |
| Context window >80% full | Apply aggressive compression to all non-CRITICAL |
| Starting a new agent task | Pre-compress all injected context |
| Passing context between agents | Compress to structured summary format |
| Reading large files | Extract only relevant sections + signatures |

## Structured Summary Format

When compressing agent outputs or handoffs:

```markdown
## Summary: [Task Name]
**Status**: COMPLETE | IN_PROGRESS | BLOCKED
**Key Findings**: [2-3 bullet points]
**Files Changed**: [list]
**Decisions Made**: [list]
**Open Questions**: [list if any]
```

## Anti-Patterns

- Repeating the same information in different formats
- Including full file contents when only a function signature is needed
- Verbose error messages that restate the stack trace
- Re-explaining context the agent already has
- Including examples when the pattern is already clear

## When NOT to Use

- Not for greenfield projects with no existing codebase — applies to existing systems
- Not for feature development — focuses on reducing complexity, not adding capability
- Not for urgent hotfixes — entropy reduction is deliberate refactoring, not firefighting
- Not for documentation-only tasks — targets code and architecture entropy

## Related Skills

- `agent-development` — meta
- `agentation` — meta
- `creating-opencode-plugins` — meta
- `bdd-scenarios` — qa

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

EXA MCP, Read, Write, Edit
