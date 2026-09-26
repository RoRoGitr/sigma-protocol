---
name: market-state-awareness
description: CME futures market hours and expected daemon failure modes during closed/maintenance windows. Use BEFORE debugging "broker won't connect," "daemon dies on startup," or any auth/feed issue in a futures runtime. Use when planning scheduled jobs (avoid running live trading work during weekend window).
allowed-tools: Read, Bash, Grep
triggers: ["market hours", "market open", "market closed", "broker disconnected", "daemon won't start", "broker auth", "weekend maintenance", "globex", "RTH", "futures hours", "CME"]
---

# Market State Awareness — CME Futures Runtime

This skill is loaded before any session attempts to diagnose broker/daemon/feed issues in a futures runtime. **Always check market state first.** Most "auth broken" symptoms during weekends are actually "market closed."

## Equity-index futures (ES / NQ / YM / RTY / MES / MNQ)

Source: [CME Micro E-mini Equity Index Futures FAQ](https://www.cmegroup.com/articles/faqs/micro-e-mini-equity-index-futures-frequently-asked-questions.html), [E-mini Nasdaq-100 FAQ](https://www.cmegroup.com/education/articles-and-reports/e-mini-nasdaq-100-monday-and-wednesday-weekly-options-frequently-asked-questions.html).

| Window | Time (ET) | State |
|--------|-----------|-------|
| Sunday pre-open | 5:45 PM – 6:00 PM | Pre-open. Orders accepted, no matching. |
| Sunday open | 6:00 PM | Globex session begins for the week |
| Mon-Thu trading | 6:00 PM (prev day) → 4:15 PM | Continuous Globex session |
| **Daily 15-min halt** | **4:15 PM – 4:30 PM** | **Brief halt — equity-index specific** |
| Mon-Thu late session | 4:30 PM → 5:00 PM | Trading resumes |
| Daily maintenance (Mon-Thu) | 5:00 PM – 5:45 PM | Maintenance — broker may drop, tokens may expire |
| Mon-Thu pre-open | 5:45 PM – 6:00 PM | Pre-open before next session |
| Mon-Thu reopen | 6:00 PM | Next session begins |
| Friday late session | 4:30 PM → 5:00 PM | Final session of the week |
| Friday close | 5:00 PM | Closed for the weekend |
| Weekend closed | Fri 5:00 PM → Sun 5:45 PM | ~49 hours closed |
| RTH (cash equity reference) | 9:30 AM – 4:00 PM | NYSE/Nasdaq cash session — futures keep trading |

## Other CME products

| Product | Sessions | Daily halt |
|---------|----------|------------|
| Energy (CL, NG) | Sun 6:00 PM ET → Fri 5:00 PM ET | 5:00–6:00 PM ET |
| Metals (GC, SI, HG) | Sun 6:00 PM ET → Fri 5:00 PM ET | 5:00–6:00 PM ET |
| Forex spot | Sun ~5:00 PM ET → Fri ~5:00 PM ET (24/5) | None |
| Crypto | 24/7 | None |

Always confirm exact hours per product on the CME page — holiday schedules and product-specific exceptions exist.

## Diagnosis: market closed vs auth broken

Before tool-use to debug a daemon/broker problem, check the time against the tables above.

**Symptoms of "market closed" (NORMAL during Fri 5pm → Sun 6pm and daily 5–5:45pm halt):**
- Broker WebSocket dropped
- Broker auth token expired / refresh fails
- Market-data ticks stop arriving
- `BrokerConfigurationError` on daemon boot
- Any live-mode daemon boot refuses

**Symptoms of "auth actually broken" (during open hours):**
- Repeated re-auth attempts fail during a confirmed-open window
- OAuth callback never resolves to a token
- Encrypted token DB empty or corrupt
- Broker API returns 401/403 during open hours
- Token age > expected refresh window AND market is open

**Action when market is closed:**
- Do not start live-mode daemon. Use data-only mode for weekend research, dashboard testing, and monitoring.
- Schedule heavy non-trading work (Kronos retrain, full backfill, downsample) for the weekend window.

**Action when auth is actually broken (market open):**
- `<runtime-cli> auth list` — show stored logins and their account IDs
- `<runtime-cli> auth add` — full OAuth re-auth via browser flow
- `<runtime-cli> auth add-login --label <label>` — add credentials for an existing login
- Token refresh is automatic from the encrypted DB — there is no `sc auth refresh` subcommand.

## Holiday calendar

CME publishes holiday hours per product. Keep the local holiday cache in the target runtime repo.

Common cases:
- New Year's, MLK Day, Presidents Day, Good Friday, Memorial Day, Juneteenth, Independence Day, Labor Day, Thanksgiving (early close + next-day early close), Christmas (early close + closed).

Always cross-check the calendar before scheduling jobs near a holiday.

## Quality gates for any agent invoking this skill

1. Have you checked the current time against the equity-index table?
2. Are you sure this is a real auth problem and not a market-closed window?
3. Are you running live-mode daemon during weekend? If yes — switch to `--mode data-only`.
4. If scheduling a heavy job (fine-tune, backfill), are you placing it in the weekend window to avoid contending with live trading?
