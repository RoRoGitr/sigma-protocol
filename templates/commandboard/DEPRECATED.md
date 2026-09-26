# DEPRECATED — SigmaHQ / CommandBoard template (frozen 2026-07-11)

**Linear replaced the SigmaHQ kanban as the Sigma Protocol task tracker on 2026-07-11.**

This directory is the install template for the retired SigmaHQ CommandBoard
(`~/.commandboard/` workspaces + `kanban-md`). It is kept for existing
installs and historical reference only.

- Do NOT install this template for new projects.
- Do NOT write task tracking here — steps 0-15 and the Run Track now mirror
  status to Linear when configured (detection: `LINEAR_API_KEY` in Keychain +
  `linear.project` in `runtime-baseline.json`; see
  `steps/_partials/linear-tracking.md`), otherwise to wave-labeled GitHub Issues.
- GitHub always owns the PR/branch/review/merge loop; when Linear is connected,
  its issues two-way-sync to GitHub once the operator enables per-repo issue
  sync (PR-linkback only today).
- File-based artifacts (`.prd-status.json`, `TASKS.md`) remain the offline
  fallback.
