---
timestamp: 2026-05-23T04:37:00Z
workspace: sigma-protocol
prd_id: F02.001
recommended_default: "Fail fast with a clear error — do not emit partial bundles"
---

# Deferred Question

When a PRD references a skill file that does not exist on disk, should the emitter:
  (a) skip the missing skill silently and continue
  (b) fail fast with a clear error
  (c) emit the bundle with a warning annotation

This affects Claude, Codex, and Droid emitters equally.

**Recommended default:** Fail fast with a clear error — do not emit partial bundles
