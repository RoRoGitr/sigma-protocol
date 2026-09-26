---
name: system-health
description: "System health check - verifies MCPs, file structure, PRDs, and command protocols"
---
# /system-health

**Comprehensive system health and integrity check**

## 🎯 Purpose

Verify that the SSS project system is "bulletproof" by checking:
1. MCP Configuration & Connectivity
2. File Structure & Organization
3. Documentation Completeness (Steps 0-12)
4. Command Protocol Compliance (MCP usage)
5. PRD Integrity
6. Manifest Accuracy

---

## 📋 Command Usage

```bash
/system-health
/system-health --fix  # Attempt auto-fixes where safe
```

---

## 🔍 Health Checks

### 1. MCP Status
- Check if `mcp_settings.json` (or `mcp.json`) exists and is valid JSON.
- Detect configured integrations and report each as configured, unavailable, or
  not applicable. Optional integrations such as `ref`, `exa`, `supabase`,
  `21st-devmagic`, `sequential-thinking`, and `firecrawl` do not block health.

### 2. File Structure
- Verify core directories exist:
  - `docs/specs`, `docs/architecture`, `docs/ux`, `docs/design`, `docs/states`, `docs/technical`, `docs/landing-page`, `docs/implementation`, `docs/prds`, `docs/wireframes`
  - host-specific command/rule folders only when that host is configured
- Check for deprecated/legacy folders:
  - `/PRD` (should be empty or gone)
  - `/.cursorrules` (should be small router)

### 3. Documentation Completeness
- Run logic similar to `/validate-methodology` but faster.
- Check for `docs/.manifest.json` and verify it matches disk content.
- Verify Step 5 (Wireframe Prototypes) outputs if used:
  - `docs/wireframes/`
  - `docs/wireframes/LANDING-PAGE-WIREFRAME.md`

### 4. Command Protocol
- Scan the current host's command surfaces when present.
- Check that declared tools are available or have a documented native/CLI fallback.
- Check for malformed tool identifiers such as double underscores `__`.

### 5. PRD Integrity
- Scan `docs/prds/`.
- Verify naming convention `F[0-9]+-.*.md`.
- Check for duplicate PRD IDs.
- Check if `legacy-*.md` files exist (moved from root).

### 6. Wireframe Integration (If Step 5 Used)
- Check for `docs/wireframes/` directory
- Verify prototype files exist
- Check for landing page wireframe

---

## Output Format

```
🏥 SYSTEM HEALTH REPORT
Generated: [DATE]

🔌 MCP Status:
✅ Ref (Configured)
✅ Exa (Configured)
✅ Supabase (Configured)
✅ 21st.dev (Configured)
⚠️ Context7 (Missing - Backup)

📁 File Structure:
✅ docs/* structure correct
✅ Root /PRD folder gone
✅ .cursorrules is modular router

📚 Documentation:
✅ Manifest in sync
✅ Step 0-12 docs present
ℹ️ Step 5 (Wireframes): Not used

🤖 Command Protocol:
PASS/MISS/SKIP command-tool receipts tied to the files actually scanned

📋 PRD Integrity:
✅ 8 PRDs found
✅ Naming conventions followed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OVERALL HEALTH: derive from the recorded PASS/MISS/SKIP checks; do not claim a
percentage or readiness without the corresponding receipt.
```
