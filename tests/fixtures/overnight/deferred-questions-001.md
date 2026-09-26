---
timestamp: 2026-05-23T02:14:00Z
workspace: sigma-protocol
prd_id: F01.003
recommended_default: "Use cursor-based pagination with page size 20"
---

# Deferred Question

Should the `/v1/prd-list` endpoint use offset-based or cursor-based pagination?

The PRD spec says "paginated list" but does not specify the pagination strategy.
Cursor-based is preferred for real-time data but adds client complexity.
Offset-based is simpler but can miss items during concurrent writes.

**Recommended default:** Use cursor-based pagination with page size 20
