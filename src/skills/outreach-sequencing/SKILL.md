---
name: outreach-sequencing
department: sales
description: "Cold/warm outreach sequencing — the 5-email cold sequence, integrated LinkedIn cadence, breakup rules, banned words/openers, deliverability + send-timing tables, and Hormozi's 1-1-1 rule (one product/avatar/channel until $1M). Use when writing a cold sequence, building an outreach cadence, generating connection requests, or auditing outreach for spam triggers. Triggers on 'cold email','outreach sequence','email cadence','LinkedIn outreach','breakup email','cold sequence','1-1-1 rule','deliverability'."
triggers:
  - outreach-sequence
  - cold-email
  - linkedin-cadence
  - breakup-email
  - deliverability
  - trigger-led list
  - account-first outbound
  - permission opener
  - problem menu
  - no-oriented ask
  - contextual call
  - suppression check
  - proof-source lock
  - meeting tie-down
---

# Outreach Sequencing

## When to Use

- Writing a cold or warm outbound email sequence to a prospect.
- Building a multi-channel cadence (email + LinkedIn) with the right spacing.
- Generating connection requests / LinkedIn messages / breakup emails.
- Auditing existing outreach for banned words, weak openers, or deliverability problems.
- Deciding which avatar/channel to run before the funnel converts (1-1-1 gate).

This is **outbound mechanics** — what to send, in what order, through which channels. Follow-up cadence after a reply lives in `follow-up-system`; the qualification gate before outreach lives in `lead-qualification`.

## Core DNA (operators behind this)

**Alex Hormozi** — the 1-1-1 rule gates whether you should be running this sequence at all.
> "Sell one product or service to one avatar on one channel until you make $1 million. That's it." (`jfW6gL6hKhk` 08:36)

Every pre-$1M diversification is a tax on speed. If outreach is fanning across multiple avatars or channels before the funnel converts, that's misaligned avatar = low-close signal = disqualification criterion. One product, one avatar, one channel until the sequence converts.

## Frameworks

### The 5-email cold sequence (repo `outreach-cold.md`)

| Day | Channel | Email | Goal |
|-----|---------|-------|------|
| 1 | Email | **The Hook** | Personalized observation + clear value prop; soft 15-min ask |
| 3 | Email | **The Value Add** | Pure value, no ask — position as a helpful resource |
| 7 | Email | **The Social Proof** | Relevant case study / metric from a similar company |
| 14 | Email | **The Different Angle** | Reframe: new pain point, stakeholder, or trigger |
| 21 | Email | **The Breakup** | Respectful close; leaves the door open; often the highest reply rate |

**Framework selection (decision tree, repo):**
```
Hot company trigger event?      → Framework 3 (Trigger Event)
Mutual connection / community?  → Framework 4 (Mutual Connection)
Strong personal anchor?         → Framework 1 (Observation → Connection → Ask)
Relevant case study w/ metrics? → Framework 2 (Problem → Proof → Ask)
otherwise → Framework 1 with an industry-level observation
```

### LinkedIn cadence (omnichannel, repo)

| Day | Action |
|-----|--------|
| 0 | Connection request + custom note (< 300 chars, personalized) |
| 1 | Email 1 (The Hook) |
| 3 | Email 2 (The Value Add) |
| 5 | Engage with their content — like + substantive comment (no pitch) |
| 7 | Email 3 (The Social Proof) |
| 10 | LinkedIn message referencing the emails (different value prop) |
| 14 | Email 4 (The Different Angle) |
| 18 | Share content they'd find valuable (tag only if genuinely relevant) |
| 21 | Email 5 (The Breakup) |

### Breakup rules (verbatim from the repo)

- NEVER guilt-trip ("I've sent 4 emails and haven't heard back").
- NEVER threaten ("This is my last email").
- Keep under 75 words. Tone: understanding, professional, confident.
- Leave them feeling positive — some of the highest reply rates come from breakups.
- Good: "Sounds like the timing isn't right — totally understand. If [problem] becomes a priority, I'd love to help."
- Bad: "I've reached out several times without a response. I'll assume you're not interested."

### Banned words + opener rules (repo `sales-outreach/`)

**Subject lines:** 4–7 words max · no spam triggers (free, guarantee, act now, limited time, urgent) · no exclamation marks · no ALL CAPS · lowercase is fine · 2 A/B options per email.

**First-line bans (NEVER open with):**
- "I hope this finds you well" (or any variant)
- "My name is…"
- "I'm reaching out because…"

The first line MUST reference something specific (trigger, post, product, company).

**Body banned jargon:** synergy · value extraction clichés · circle back · touch base · low-hanging fruit · deep dive · bandwidth · ecosystem. Emails 1–4 under 100 words; Email 5 under 75. One CTA per email, framed as a question. No emojis, no bold/italic (plain text outperforms HTML for cold).

### Deliverability table (repo)

| Practice | Recommendation |
|----------|---------------|
| Send volume | 10–20/day per inbox, warm up to ~50/day |
| Email warmup | Warm new addresses 2–3 weeks before cold outreach |
| Domain | Separate sending subdomain (e.g. mail.company.com) to protect primary reputation |
| Authentication | SPF + DKIM + DMARC configured |
| Unsubscribe | Include opt-out (CAN-SPAM) |
| Bounces | Remove immediately |
| Spam testing | Test through mail-tester.com before sending |

### Send-timing table (repo)

| Audience | Best days | Best times | Avoid |
|----------|-----------|-----------|-------|
| C-suite / VP | Tue, Wed, Thu | 7–8 AM or 5–6 PM | Mon AM, Fri PM |
| Directors / Managers | Tue, Wed, Thu | 9–11 AM | Mon AM, Fri PM |
| Technical / IC | Tue, Wed | 10 AM–12 PM | Mon, Fri |
| Founders / Startup | Any weekday, Sat AM | 7–9 AM or 8–10 PM | Sun |

### Follow-up rules after the sequence (repo)

| Scenario | Action |
|----------|--------|
| No response to all 5 | Wait 30 days, re-approach with a new angle / trigger |
| Out-of-office | Re-send Email 1 the day after they return |
| "Not interested" | Respond graciously, ask for a referral, remove from sequence |
| "Not now" | Ask when's better, set a reminder, send a value-add meanwhile |
| Positive reply | Respond within 1 hour, propose 2–3 specific times |

## Anti-Patterns

- Running outreach across multiple avatars/channels before the funnel converts (violates 1-1-1).
- Opening with "I hope this finds you well" / "My name is…" / "I'm reaching out because…".
- Spam-trigger subject lines (free, guarantee, urgent) or exclamation marks.
- Jargon in the body (synergy, value extraction clichés, circle back, bandwidth).
- Guilt-trip or threat in the breakup email.
- More than one CTA per email.
- Cold-sending from the primary domain without a warmed subdomain + SPF/DKIM/DMARC.
- HTML emails with tracking pixels for the first cold touch (plain text outperforms).

## Quality Gates

- [ ] **1-1-1 checked** — one product, one avatar, one channel until the funnel converts.
- [ ] Subject lines 4–7 words, no spam triggers, no exclamation marks, 2 A/B options each.
- [ ] No banned opener; first line references something specific to the prospect.
- [ ] No banned jargon in the body; emails 1–4 < 100 words, email 5 < 75.
- [ ] One CTA per email, framed as a question.
- [ ] Breakup email is respectful — no guilt-trip, no threat, < 75 words.
- [ ] LinkedIn cadence integrated (Day 0/5/10/18) alongside the 5-email sequence.
- [ ] Deliverability covered: warmed inbox, separate subdomain, SPF/DKIM/DMARC, bounce removal.
- [ ] Send timing matched to the contact's role.


## Transcript-grounded upgrade
**Trigger-led, account-first outbound** — do not blast a contact list. Build from **observable triggers**
(hiring, funding, tech change, ad spend in the niche) → pick the **account** → map the buying committee →
then sequence the people. Ad-library/job-board signals prove a company has demand + money (src: a2a6KYS2sDw, tdYvRKVr0pk).

**The opener is permission + a problem menu, never a pitch:**
- *Permission opener:* honest, short, gives an out — "Can I be straight with why I'm reaching out?"
- *Problem menu:* name 2–3 problems peers in their niche have; let them self-select. Buyers grant
  attention when the opener is relevant and brief (src: a2a6KYS2sDw).
- *No-oriented ask:* "Would it be ridiculous to grab 12 minutes?" — a "no" is safe, so it earns the reply.

**Multi-channel ordering:** email/LinkedIn touch first, then the **contextual call** that references it
("I sent a note about X") — the call lands warm, not cold. Hand the structure to `b2b-cold-call-screenplay`.

**Infrastructure gates (block the send if any fail):** suppression check (already in pipeline / opted-out /
customer), **deliverability gate** (warmed inbox, separate sending subdomain, SPF/DKIM/DMARC, bounce removal —
route to `ai-sdr-readiness-gate`), proof-source lock (every claim cites a real case/number), and a **meeting
tie-down** (specific slot + instant calendar invite). Bad deliverability scales spam, not pipeline (src: G0AsZQlSCUw, UxBCtg8rmt0, Z9xzPDRrQHw).

**Owners:** braun (cold copy), ross (system/cadence), voss (no-oriented framing), general (governance).
**Every customer-facing send routes through the approval queue (new-contact gate).**
