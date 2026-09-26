# Sigma Protocol C-Suite Departments

**What this is:** executive personas you can summon with a slash command. Each one is a domain expert with stable methodology (Layer 1), project-specific context (Layer 2), and your personal history (Layer 3) composed into a single briefing before Claude responds.

---

## How It Works (1-Minute Version)

You type `/marketing write a launch email`. Before Claude sees your prompt, a hook injects three layers of context — so Claude isn't just Claude, it's your CMO who knows your product, knows what's worked before, and speaks in your voice.

```
┌───────────────────────────────────────────────────────────────────────┐
│  You: /marketing write a launch email                                 │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
               ┌─────────────▼──────────────┐
               │  UserPromptSubmit hook     │
               │  department-composer.sh    │
               └─────────────┬──────────────┘
                             │
      ┌──────────────────────┼──────────────────────┐
      │                      │                      │
      ▼                      ▼                      ▼
┌───────────┐        ┌───────────────┐        ┌──────────────┐
│ LAYER 1   │        │ LAYER 2       │        │ LAYER 3      │
│ Canon     │        │ Project       │        │ User Overlay │
│ (stable)  │        │ Overlay       │        │ (evolves)    │
│           │        │ (per repo)    │        │              │
│ CMO voice │        │ Current offer │        │ What worked  │
│ Framework │        │ ICP + KPIs    │        │ What failed  │
│ Skills    │        │ Ad accounts   │        │ Voice prefs  │
└─────┬─────┘        └───────┬───────┘        └──────┬───────┘
      │                      │                       │
      └──────────────────────┼───────────────────────┘
                             │
                             ▼
             ┌───────────────────────────────┐
             │  Concatenated context injected│
             │  into Claude's system prompt  │
             └───────────────┬───────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Claude answers│
                    │  as your CMO   │
                    └────────────────┘
```

---

## The 13 Departments

| Slash | Who it is | When to use |
|-------|-----------|-------------|
| `/engineering` | CTO | Architecture, tech stack, build-vs-buy, technical hiring |
| `/security` | CISO | Threat modeling, audits, OWASP, secrets, compliance posture |
| `/legal` | General Counsel | Contracts, IP, terms, compliance responses |
| `/marketing` | CMO | Brand, positioning, GTM, lifecycle emails, landing copy |
| `/content` | Content Director | Editorial calendar, video/short-form, SEO, repurposing |
| `/finance` | CFO | Budgeting, unit economics, fundraising, cash flow |
| `/ops` | COO | SOPs, internal systems, vendor management, hiring ops |
| `/sales` | CSO | Outbound, pipeline, discovery, high-ticket close, proposals |
| `/product` | CPO | PRDs, roadmap, prioritization, user research |
| `/community` | Community Lead | Discord/Telegram, social, media, community health |
| `/trading` | Chief Trading Officer | Strategy backtests, risk, broker ops, market data |
| `/design` | Design Director | UX flows, visual identity, design systems, accessibility |
| `/qa` | QA Engineer | Verification, test strategy, gap analysis, ship decisions |

Aliases: `/ads` and `/growth` route through `/marketing`; `/support` routes to `/community`.

Every department invokes an Opus model. These are strategic personas with budget authority in the conversation — you don't want them running on a cheaper model.

---

## Install

From the root of your Sigma Protocol checkout, run:

```bash
./scripts/install-departments.sh
```

That's it. The installer is idempotent — re-running it is safe.

### What the installer does

- **Copies** `templates/hooks/department-composer.sh` into `~/.claude/hooks/department-composer.sh` and marks it executable.
- **Records** the path to your Sigma Protocol checkout in `~/.claude/sigma-protocol-root` so the composer can find the canon layer (no shell-rc edits).
- **Registers** the `UserPromptSubmit` hook in `~/.claude/settings.json`, preserving every other hook already configured. Uses `jq` if available, falls back to Python 3. Creates a timestamped backup before writing.
- **Scaffolds** `~/.claude/departments/{marketing,ads,content,growth,engineering,ops,finance}/` so the user-overlay layer has a home. Does not overwrite any existing `user-overlay.md`.
- **Verifies** the install by piping a dry prompt through the composer and checking the output. Exits non-zero if the smoke test fails.

### After install

1. Open any Claude Code session.
2. Type `/marketing` (or any of the 13 departments) followed by your request.
3. Optionally drop a project overlay at `{your-project}/.claude/departments/marketing.md` — see `SCHEMA.md` § 3.2 for the template. No overlay is fine; the canon alone is still a senior CMO.
4. Run `/onboard-departments` once to customize personas to your business.

### Manual install (advanced / CI)

If you need to script your own install (CI, container image bake, custom configuration management), bypass the shell script and do the four things it does:

1. Copy `templates/hooks/department-composer.sh` into `~/.claude/hooks/` and `chmod +x`.
2. Write the absolute path to your Sigma Protocol checkout into `~/.claude/sigma-protocol-root`, or set the `SSS_PROTOCOL_ROOT` environment variable at Claude Code launch.
3. Append this entry to `hooks.UserPromptSubmit` in `~/.claude/settings.json`:

   ```json
   {
     "hooks": [
       {
         "type": "command",
         "command": "~/.claude/hooks/department-composer.sh",
         "timeout": 3
       }
     ]
   }
   ```

4. Create the 7 overlay directories under `~/.claude/departments/`.

Verify with:

```bash
echo '{"prompt":"/marketing help"}' | ~/.claude/hooks/department-composer.sh
```

The first line of stdout should be `# Sigma Protocol Department Context: MARKETING`.

---

## Files on Disk

```
~/.claude/
├── hooks/
│   └── department-composer.sh          ← the hook (fires on every prompt)
├── logs/
│   └── department-composer.log         ← every invocation logs here
├── sigma-protocol-root                  ← written by installer, points to the canon
└── .tier                                ← your tier file (single line)

{SSS-Protocol-repo}/
├── scripts/
│   └── install-departments.sh           ← the installer (run once)
├── templates/
│   └── hooks/
│       └── department-composer.sh       ← composer source (copied by installer)
└── .agents/departments/
    ├── SCHEMA.md                        ← contract for all 3 layers
    ├── README.md                        ← this file
    ├── marketing/department.md          ← Layer 1 canon
    ├── ads/department.md
    ├── content/department.md
    ├── growth/department.md
    ├── engineering/department.md
    ├── ops/department.md
    └── finance/department.md

{your-project}/.claude/departments/
├── marketing.md                         ← Layer 2 overlay (optional)
├── ads.md
└── ...                                  ← one per department you customize

~/.claude/departments/
├── marketing/user-overlay.md            ← Layer 3, written by flush.py
├── ads/user-overlay.md
└── ...
```

---

## Troubleshooting

### I invoked `/marketing` but nothing happened

Check the log:

```bash
tail -20 ~/.claude/logs/department-composer.log
```

Four likely lines:

- `blocked tier=free` — you're on free plan. Upgrade to Pro to access departments.
- `canon invalid — SCHEMA.md not found at ...` — the installer can't see the Sigma Protocol checkout. Re-run `./scripts/install-departments.sh` from the repo, or `cat ~/.claude/sigma-protocol-root` to confirm the path still exists. The composer still works without canon; you just lose Layer 1.
- `all layers missing — canon path: ...` — canon, project overlay, and user overlay are all empty. Re-run the installer and check `~/.claude/departments/` was scaffolded.
- No recent entry at all — the hook isn't registered. Re-run `./scripts/install-departments.sh` (idempotent) to register.

### I see `layer N contains banned terms, dropped`

The composer strips any layer that mentions founder-internal brand tokens (see the `BANNED_TERMS` constant in `department-composer.sh`). These are internal references that shouldn't leak into student installs.

Check which layer tripped it, open that file, and remove the reference. Layer 2 (project overlay) is the most common culprit — someone pasted from an internal doc.

### The composer is slow

Soft budget is 200ms. Typical run is 180-300ms on macOS with cold disk, typically closer to ~250ms (mostly bash fork/exec). Anything above 500ms suggests a huge Layer 2 or 3 file — check size:

```bash
wc -l ~/.claude/departments/*/user-overlay.md
```

Layer 3 should cap at 5000 tokens per file. If flush.py is not pruning, that's a bug — report it.

### I want to add an 8th department

Don't. Seven is the spec. Expanding requires updating SCHEMA.md (major version bump), the composer's `DEPARTMENTS` list, the classifier in flush.py, and every persona agent reference. Talk to lead-architect first.

### How do I save a learning to my overlay?

Three ways:

1. **Explicit:** say "save this to my marketing overlay" in-session — Claude appends a timestamped entry.
2. **Automatic:** flush.py (runs on Stop hook) classifies session events and appends to the right overlay.
3. **Manual:** edit `~/.claude/departments/marketing/user-overlay.md` directly. Follow SCHEMA.md § 3.3 — newest entries at the top of each section, ISO 8601 timestamps.

---

## Related Reading

- **SCHEMA.md** — the contract. Read this if you're writing a canon, modifying flush.py, or adding a consumer.
- **Sigma Protocol CLAUDE.md** — methodology overview, steps 0-14.
- **`commands/run-m-*` and `.agents/skills/`** — workflow commands and skills `/marketing` can invoke. The department layer wraps these; it doesn't replace them.
