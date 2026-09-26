# Changelog

All notable changes to Sigma Protocol V2 are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org/).

## [2.0.0] — 2026-07-02

Sigma Protocol V2 — a clean single-surface release. This repository supersedes the original `sigma-protocol` repo with fresh history; the methodology content carries forward, the legacy does not.

### The single-surface contract
- Canonical sources only: `steps/` (canonical step files) → `commands/` (rendered slash commands), `src/skills/` + `src/agents/` (authored), `.agents/skills/` (bundled pool), `schemas/`, `docs/`.
- Per-vendor mirror trees (`.codex/`, `.cursor/`, `.factory/`, `.claude/commands/`, `.claude/skills/`) are operator-local, generated on install, and gitignored — they never ship.
- `CLAUDE.md` is a tracked thin pointer to `AGENTS.md`, the single instruction surface for every runtime. Machine-specific overrides go in `CLAUDE.local.md` (gitignored).

### Methodology
- Steps `0–15` plus conditional `1.5` (Offer Architecture) and `11.5` (Task Handoff) — the only numbered workflow steps.
- Standalone workflow commands ship as real slash commands: `/prd-json`, `/prd-orchestrate`, `/continue`, `/status`, `/platform-sync`.
- Run Track: 8 operating departments (`/run-marketing` … `/run-legal`) with 64 numbered steps.
- C-suite department system: 13 canonical departments plus 4 alias-canons (`/ads`, `/growth`, `/support`, `/gtm`); the department composer resolves aliases from the registry and composes alias-canon personas.

### Integrity
- `validate-cascade.mjs` validates the registry directly (registry self-consistency, block resolvability, registry→block coverage) across canonical skill surfaces.
- Runtime cascade (`prompt-stack-augmenter.cjs` / `resolve-cascade.mjs`) resolves skills against canonical surfaces — a fresh clone resolves 100% of registry skills.
- Test suite green on a clean checkout: python, shell, and node validators are self-sufficient (no operator-local fixtures).
