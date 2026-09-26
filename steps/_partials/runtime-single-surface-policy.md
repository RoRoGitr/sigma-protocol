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
