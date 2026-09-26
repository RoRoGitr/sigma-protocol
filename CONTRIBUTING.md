# Extending the Sigma Protocol

This guide explains how to customize and extend the Sigma Protocol for your own projects. The framework is designed to be adapted to your specific workflows, tech stacks, and team structures.

## Code of Conduct

All contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Extend

### Creating Custom Agents

1. Copy `AGENT-TEMPLATE.md` to `.claude/agents/your-agent-name.md`
2. Define the agent's role, skills, and tool restrictions
3. Add skill bindings in the frontmatter
4. Test the agent in a session before relying on it in production

See `docs/AGENT-CAPABILITY-MATRIX.md` for the full roster of built-in agents and their capabilities.

### Creating Custom Skills

1. Copy `SKILL-TEMPLATE.md` (repo root) to `src/skills/your-skill-name/SKILL.md` — `src/skills/` is the authored canonical surface; promote to the bundled `.agents/skills/` pool when it's ready for every runtime
2. Write the skill with proper YAML frontmatter (name, description, trigger phrases, allowed-tools)
3. Include real code examples from your codebase, not toy examples
4. Add a quality gates checklist for verification
5. Register it in `.claude/lib/agent-skill-registry.json` (department, trigger_keywords, quality_tier), then regenerate indexes with `node scripts/generate-sigma-indexes.mjs` and check with `node scripts/validate-cascade.mjs`

### Adding Custom Hooks

Hooks automate behaviors at specific lifecycle events (SessionStart, PreToolUse, PostToolUse, etc.).

1. Create your hook script in `.claude/hooks/` or `scripts/hooks/`
2. Register it in `.claude/settings.json` under the appropriate event
3. Test it in isolation before enabling

See `docs/HOOK-REFERENCE.md` for the full hook lifecycle and examples.

### Customizing Steps

Each step (0-15, plus 1.5 and 11.5) is a canonical command file in `steps/` (extensionless). The rendered slash-command files in `commands/` are generated from it — never edit `commands/` directly. To customize:

1. Read the step file in `steps/` to understand the default behavior
2. Edit the canonical `steps/` file, then run `bash scripts/sync-steps-to-platforms.sh` to re-render `commands/`
3. Add project-specific quality gates to the step's verification schema
4. Chain custom skills to steps via `.claude/lib/agent-skill-registry.json` (see `docs/CANONICAL-SOURCES.md`), then verify with `node scripts/validate-cascade.mjs` and `bash scripts/lint-step-parity.sh`

## File Structure

Place extensions in the appropriate directory:

| Directory | Purpose |
|-----------|---------|
| `src/skills/` | Authored canonical skills |
| `.agents/skills/` | Bundled skill pool (all runtimes) |
| `.claude/agents/` | Agent definitions (role, skills, model, tools) |
| `.claude/hooks/` | Lifecycle hooks (session, tool, commit events) |
| `.claude/rules/` | Rules and configuration for agent behavior |
| `schemas/` | JSON schemas for workflow validation |
| `templates/boilerplates/` | Project templates for scaffolding |

## Testing Your Extensions

Test tooling: `python3 -m venv .venv-test && .venv-test/bin/pip install -r requirements-dev.txt`, then `.venv-test/bin/python -m pytest tests/`. Shell suites run directly: `bash tests/test_<name>.sh`. Node validators need Node 20+ and `jq` on PATH.

Before relying on custom agents, skills, or hooks:

1. Test in at least one platform (Claude Code recommended)
2. Verify all quality gates pass
3. Check that outputs match expected format
4. Run the built-in verification skill: `verification-before-completion`

## Version Bumping

When tracking your own modifications:

- **PATCH** (0.0.X): Bug fixes, typo corrections
- **MINOR** (0.X.0): New skills, agents, or hooks
- **MAJOR** (X.0.0): Breaking changes to methodology or step structure

## Reporting Issues

If you find bugs or have feature requests for the core Sigma Protocol, open an issue with:

- Your platform (Claude Code, Codex, Cursor, etc.)
- The command or skill involved
- Steps to reproduce
- Expected vs actual behavior

## Architecture Decisions

When extending the protocol, consider:

1. Does this fit the Sigma methodology philosophy?
2. Does it work across supported platforms?
3. Is it consistent with existing patterns?
4. Does it follow the agent DNA structure (if creating agents)?
5. Does it follow the skill format (YAML frontmatter + markdown body)?

If unsure, open a discussion issue before investing significant effort.
