---
description: "Web application E2E and integration testing — Playwright, Cypress, testing-library. Use when testing web applications. Triggers on \'e2e test\', \'integration test\', \'playwright\', \'cypress\', \'webapp test\'."
  Agent Browser CLI for lightweight testing. Playwright paths are exception-only and
  require explicit user opt-in.
name: webapp-testing
department: engineering
---

# Web Application Testing

## Policy Override (2026-02)

- Default frontend validation uses Russell Agent Browser CLI (`agent-browser`) and Vercel Agent CLI workflow when applicable.
- Do not use Playwright unless the user explicitly requests an exception.
- If examples below mention Playwright, treat them as optional fallback patterns only.

## Browser Tool Priority

| Tool | Best For | Install |
|------|----------|---------|
| **Agent Browser CLI** ⭐ | Quick verification, execution-backlog validation, context-efficient | `npm install -g agent-browser` |
| **Python Playwright (Exception Only)** | Complex automation, network interception, multi-tab | `pip install playwright && playwright install` |
| **Cursor Browser** | Cursor IDE users, interactive debugging | Built-in |

## Decision Tree: Choosing Your Approach

```
User task → Simple UI verification (element exists, click, fill)?
    ├─ Yes → Use Agent Browser CLI
    │         agent-browser open http://localhost:3000
    │         agent-browser snapshot -i   # Get interactive elements
    │         agent-browser click @e1     # Click by ref
    │
    └─ No (complex automation) → Need network interception, console logs, or multi-tab?
        ├─ Yes → User explicitly requested Playwright exception?
        │   ├─ Yes → Use Python Playwright scripts
        │   └─ No  → Stop and ask before using Playwright
        │         See examples below for server lifecycle management
        │
        └─ No → Is the server already running?
            ├─ Yes → Agent Browser CLI
            │
            └─ No → Use scripts/with_server.py + Agent Browser workflow (or ask before Playwright)
```

## Agent Browser CLI (Recommended for Simple Tests)

```bash
# Quick verification
agent-browser open http://localhost:3000/dashboard
agent-browser snapshot -i                           # List interactive elements
agent-browser click @e1                              # Click by ref ID
agent-browser fill @e2 "test@example.com"           # Fill input
agent-browser screenshot -o .claude/screenshots/test.png

# Session management for isolation
agent-browser session create my-test
agent-browser session use my-test
# ... run tests
agent-browser session destroy my-test
```

## Python Playwright (For Complex Automation)

**Helper Scripts Available**:
- `scripts/with_server.py` - Manages server lifecycle (supports multiple servers)

**Always run scripts with `--help` first** to see usage. DO NOT read the source until you try running the script first and find that a customized solution is absolutely necessary. These scripts can be very large and thus pollute your context window. They exist to be called directly as black-box scripts rather than ingested into your context window.

## Example: Using with_server.py

To start a server, run `--help` first, then use the helper:

**Single server:**
```bash
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_automation.py
```

**Multiple servers (e.g., backend + frontend):**
```bash
python scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python your_automation.py
```

To create an automation script, include only Playwright logic (servers are managed automatically):
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True) # Always launch chromium in headless mode
    page = browser.new_page()
    page.goto('http://localhost:5173') # Server already running and ready
    page.wait_for_load_state('networkidle') # CRITICAL: Wait for JS to execute
    # ... your automation logic
    browser.close()
```

## Reconnaissance-Then-Action Pattern

### Agent Browser CLI (Simple)
```bash
agent-browser open http://localhost:3000
agent-browser snapshot -i                    # See all interactive elements with refs
# Output: @e1: button "Submit", @e2: input "Email", etc.
agent-browser click @e1                      # Execute action using ref
```

### Playwright (Complex)
```python
page.screenshot(path='.claude/screenshots/inspect.png', full_page=True)
content = page.content()
page.locator('button').all()
```

## Common Pitfalls

❌ **Don't** inspect the DOM before waiting for `networkidle` on dynamic apps
✅ **Do** wait for `page.wait_for_load_state('networkidle')` before inspection (Playwright)
✅ **Do** use `agent-browser snapshot -i` after page has loaded (Agent Browser)

## Best Practices

- **Prefer Agent Browser CLI** for frontend verification - 93% less context than full Playwright
- **Use bundled scripts as black boxes** - To accomplish a task, consider whether one of the scripts available in `scripts/` can help. These scripts handle common, complex workflows reliably without cluttering the context window. Use `--help` to see usage, then invoke directly.
- Use `sync_playwright()` for synchronous scripts (Playwright only)
- Always close the browser when done (Playwright only - Agent Browser handles this)
- Use descriptive selectors: `text=`, `role=`, CSS selectors, or IDs
- Add appropriate waits: `page.wait_for_selector()` or `page.wait_for_timeout()`
- Save screenshots to `.claude/screenshots/` directory

## When NOT to Use

- Not for unit testing (Jest, vitest) — focuses on webapp E2E and integration testing
- Not for mobile app testing — use mobile-ui-testing skill
- Not for API testing — use backend testing patterns
- Not for performance load testing — use load-test audit skill

## Reference Files

- **examples/** - Examples showing common patterns:
  - `element_discovery.py` - Discovering buttons, links, and inputs on a page
  - `static_html_automation.py` - Using file:// URLs for local HTML
  - `console_logging.py` - Capturing console logs during automation

## When to Use Playwright vs Agent Browser

| Scenario | Recommended Tool |
|----------|-----------------|
| Quick element verification | Agent Browser CLI |
| Execution-backlog acceptance criteria | Agent Browser CLI |
| Network request interception | Playwright (explicit exception only) |
| Console log capture | Playwright (explicit exception only) |
| Multi-tab workflows | Playwright (explicit exception only) |
| Complex form automation | Playwright (explicit exception only) |
| Visual regression testing | Either |
| Screenshot capture | Either |

## Related Skills

- `brand` — design
- `canvas-design` — design
- `theme-factory` — design
- `ci-cd-patterns` — engineering/backend

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

EXA MCP, Bash, Read, Write, Edit, agent-browser CLI
