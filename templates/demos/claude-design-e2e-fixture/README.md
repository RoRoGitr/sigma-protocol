# Claude Design E2E Fixture

Minimal fixture for exercising Sigma Protocol's Track A/B/Hybrid detection logic without running a live project. Used by `scripts/test-claude-design-detection.sh`.

## Fixture Contents

- **Flow 01 (auth):** Track A — has `claude-design/` bundle + `CLAUDE-DESIGN-PROMPT.md`
- **Flow 02 (dashboard):** Track B — has `screens/*.html`
- **Landing page:** Hybrid — has `claude-design/` bundle + `TEMPLATE-MAPPING.md`

## Test Scenarios

Run `scripts/test-claude-design-detection.sh` to exercise:

1. **Positive detection** — the fixture as-is. Validator should correctly identify each track.
2. **Negative mutation: missing bundle** — temporarily remove `docs/prds/flows/01-auth/claude-design/` and confirm validator flags incomplete Track A.
3. **Negative mutation: missing HTML** — temporarily remove `docs/prds/flows/02-dashboard/screens/*.html` and confirm validator flags incomplete Track B.
4. **Negative mutation: missing template map** — temporarily remove `docs/landing-page/TEMPLATE-MAPPING.md` and confirm validator flags incomplete Hybrid.

## Purpose

Gate 7 (Live End-to-End) is satisfied in SIMULATED mode by this fixture. Real live validation still requires a first real project to reach Step 5/9 — the fixture validates detection logic, not user-experience quality.
