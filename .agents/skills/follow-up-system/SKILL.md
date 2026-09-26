---
name: follow-up-system
department: sales
description: "Disciplined sales follow-up + retention cadence — 5 client types, rule-of-7, no-lead-untouched-48h, prepaid packages, and Hormozi retention-cohort renewal triggers. Use when a lead went quiet, a consult ended without a booking, you need a follow-up cadence, or you're designing renewal/retention timing. Triggers on 'follow up','follow-up','nurture','no-show','rule of 7','retention cadence','renewal trigger','lead went cold','5 client types'."
triggers:
  - follow-up
  - nurture
  - retention-cadence
  - renewal-trigger
  - no-show
  - lead-stage cadence
  - hot/nurture/cold
  - day 1/3/7
  - 12-touch
  - close the file
  - value-only follow-up
  - have you given up
  - reactivate dead lead
---

# Follow-Up System

## When to Use

- A consult, DM, or call ended **without** a booking and you need the next touch.
- A lead replied once then went silent (left-on-read, "I'll think about it", out-of-office).
- You're standing up a cadence so no inbound lead falls through the cracks.
- You're scheduling renewal / re-book touches against the customer lifecycle (day-90, month-6).
- You want to kill no-shows by moving money before the appointment.

This is the **proactive** layer. Discovery and closing happen on the call; follow-up addresses leads who do not close on first contact and keeps churn from eating the book.

## Practitioner notes (verify before quoting)

The percentages and video/blog attributions below are historical notes, not independently verified benchmarks. Sample schedules are alternatives, not cumulative mandatory touches. Select one for the buyer and channel; document consent, stop conditions and observed results. No package or deposit is charged by this skill without explicit authorization.

### Sources

**Sheila Bella** — follow-up is not optional, it is where the majority of revenue is recovered.
> "**40% of sales are made in follow-up.** Selling is proactive — you can't just take no." (YT)
> "**80% of converted leads need 5 follow-ups; 44% of reps quit after one.**" (blog)
> "No lead **untouched for 48 hours**; schedule the next contact while still on the call." (blog)
> "Follow-up done right reads as **caring, not pushy** — it previews the service quality." (blog)
> "Sell **packages, prepaid** — money before the appointment kills no-shows." (YT)

**Alex Hormozi** — churn is cohort-dependent, not flat; engineer the two retention milestones.
> "Don't ask 'how do I make churn go down' but 'how do I get someone to stay past day 90?'" (`-j8_YCWZ05Q` 04:29)

## Scripts & Patterns

### The 5 Client Types (Sheila) — each needs a distinct follow-up

| Type | Who they are | Follow-up move | First touch |
|------|--------------|----------------|-------------|
| **Glance** | Liked/viewed, never engaged | Re-warm with value content; no ask yet | Comment/story reply, soft |
| **Present** | In an active conversation now | Lead to the next step on the call; book the deposit | Same session — "here's your next step" |
| **Just-booked** | Said yes, deposit taken | Confirm + prep + over-deliver on the wait | Within 24h: confirmation + what-to-expect |
| **Dormant** | Past client, gone quiet | Re-activation offer / "we kept your spot" | Personalized re-book, reference last result |
| **Undecided** | Got a quote, didn't commit | Rule-of-7 cadence; surface the unasked question | Within 48h, then spaced touches |

### The Rule of 7 — touchpoint cadence (no lead untouched 48h)

Use the seven-touch sequence below as an example to test, not a requirement derived from unverified industry percentages. Schedule the **next** contact while still on the call — never hang up without the next touch on the calendar.

| Touch | Day | Channel | Purpose |
|-------|-----|---------|---------|
| 1 | 0 (on call) | live | Book deposit OR set next contact date |
| 2 | 2 | DM / email | "Here's your next step" — not "just checking in" |
| 3 | 4 | DM | Value: answer the unasked question (see Discovery skill) |
| 4 | 7 | DM / call | Social proof: a peer's before/after |
| 5 | 11 | DM | Reframe — cost of staying where she is |
| 6 | 16 | email | Different angle / new stakeholder benefit |
| 7 | 21 | DM | Respectful close — door stays open |

**Caring, not pushy.** Each touch previews service quality. Kill `"let me know"`, `"take your time"`, and unprompted discounting — they read as a price that was never real.

### Prepaid packages kill no-shows

Sell **packages, prepaid** — money lands before the appointment. "The minute you hang up, kids need things, notifications go off; she won't book later." Take the deposit on the call, not after.

### Retention follow-up from observed milestones

Use actual activation, renewal and inactivity events to schedule follow-up. Day 90 and month 6 are examples from practitioner material, not universal churn transitions. Use the `retention-engine` cohort definition and baseline. Customer preferences, opt-outs and buying horizon override any sample contact cadence.

### Repo cadence + deliverability (cross-channel touches)

Cold-sequence cadence from `outreach-cold.md` — adapt the spacing/breakup logic for warm follow-up:

| Day | Channel | Action |
|-----|---------|--------|
| 1 | Email | The Hook |
| 2 | LinkedIn | Connect + note |
| 3 | Email | The Value Add (no ask) |
| 5 | LinkedIn | Engage with their content |
| 7 | Email | The Social Proof |
| 14 | Email | Different Angle |
| 21 | Email | The Breakup |

**Sequence rules (verbatim from the repo template):**
- **Personalization minimum:** each touch carries ≥2 prospect-specific details.
- **Pause triggers:** stop the sequence the moment they reply — positive or negative.
- **Minimum spacing:** 48 hours between touches; tighten on engagement signals.
- **Opt-out:** respect unsubscribes immediately; remove from all sequences.

**Deliverability (cold/warm email):** start 10–20 emails/day per inbox, warm up to ~50/day over 2–3 weeks; use a separate sending subdomain; SPF + DKIM + DMARC configured; remove bounces immediately; test through mail-tester before a batch.

**Send timing:** C-suite/VP → Tue–Thu 7–8 AM or 5–6 PM; Directors/Managers → Tue–Thu 9–11 AM; founders → any weekday, odd hours. Avoid Monday AM and Friday PM.

## Anti-Patterns

- "Just checking in" — say `"here's your next step"` instead. Checking in is a non-ask that trains the lead to keep ignoring you.
- Quitting after one follow-up (44% do; the money is in touches 2–5).
- `"let me know"` / `"take your time"` as a close — these forfeit the lead.
- Unprompted discounting ("I can probably do a little discount") — signals the price was never real.
- Hanging up without the next contact scheduled.
- Booking without a prepaid deposit, then absorbing the no-show.
- Treating a practitioner's milestone dates as measured churn behavior for this project.
- Letting a lead go untouched past 48 hours.

## Quality Gates

- [ ] Every open lead has a **next touch scheduled** (no lead untouched > 48h).
- [ ] Cadence plans for **≥5 follow-ups** before declaring cold (rule of 7).
- [ ] Lead is classified into one of the **5 client types**; cadence matches the type.
- [ ] No `"let me know"` / `"take your time"` / unprompted discount in any touch.
- [ ] Every touch carries a concrete next step, not a "checking in".
- [ ] Bookings collect a **prepaid deposit** on the call.
- [ ] Retention touches map to actual activation and renewal events, with a stated cohort baseline.
- [ ] Renewal timing follows the customer's contract and preferences.

## Transcript-grounded upgrade
Practitioner playbook notes cite `sales-tactics.md` and `scripts-library.md` where an operator supplies them; these are not guaranteed installed resources. These are the named plays the agent bench runs; lines are verbatim — inject without polishing. Owners are bench keys: **ari-gold** (persistent field operator — speed, cadence, value touches, CRM hygiene), **voss** (tactical-empathy reopen + status labels), **ross** (predictable-revenue / no-show machinery), **harvey** (premium close-file authority).

### Lead-stage cadences (cadence follows buying horizon, not desperation)

Stage the lead by buying horizon and CRM source, then set contact frequency to match. Desperation cadence (daily pings on a 6-month buyer) burns the lead; the horizon sets the spacing (src: 36phQfbUKa8, n2gAJfcp7BA — `Hot/Nurture/Cold Stages`, owner ari-gold).

| Stage | Definition | Frequency | Move |
|-------|-----------|-----------|------|
| **Hot** | < 90 days from buying | **Weekly** contact | Personalized, decision-linked; push the next step |
| **Nurture** | > 90 days out | **Monthly** contact | Value-only touches; keep top-of-mind, no pressure |
| **Unresponsive** | No reply across the cadence | Drop to **newsletter** | Passive list; re-enters Hot/Nurture on any engagement signal |

**Fresh leads — Day 1/3/7** (new inbound + high-intent forms). Personalized video / email / text / call on **day 1**, repeat on **day 3** and **day 7**. Speed plus a human face beats anonymous drip fatigue — a face on day 1 prevents the lead going cold before the first human contact (src: 36phQfbUKa8, y2eS7ME8Oho — `Day 1/3/7 Lead Follow-Up`, owner ari-gold).

| Touch | Day | Channel | Move |
|-------|-----|---------|------|
| 1 | 1 | Personalized **video** (fallback email) | Named, references their form/intent — "I saw you came in on X" |
| 2 | 3 | **Text** or email | New angle or a relevant proof point, not "just checking in" |
| 3 | 7 | **Call** (+ voicemail) | Curiosity callback: "I've got a great idea for you I'm not sure if it's for you but give me a call back I want to run something past you" (src: ari-gold, CStw4HyLDR4) |

**12-touch unsold sequence** (real but unsold leads). Many sales land after the fifth contact — plan up to **12 touches** across **phone, text, video, gifts, retargeting, newsletter, and content** before retiring the lead (src: S8A46V9CJRs, CStw4HyLDR4 — `Twelve-Touch Unsold Follow-Up`, owner ari-gold). Rotate the channel each touch; never 12 identical emails. Persistence is the point — internally: "Once you give me a little nibble then I know you're real and you exist" (src: ari-gold, CStw4HyLDR4, 0ullQyCNWRA).

| # | Channel | # | Channel |
|---|---------|---|---------|
| 1 | Phone | 7 | Retargeting ad |
| 2 | Text | 8 | Content / case study |
| 3 | Video | 9 | Phone |
| 4 | Email (value) | 10 | Newsletter |
| 5 | Gift / handwritten | 11 | Text |
| 6 | Newsletter | 12 | Final value touch → then close-file prompt |

**No-show recovery ladder** (cross-ref `pre-call-show-rate-system` — that skill OWNS the booking-to-show machinery; this is the follow-up view). No-blame reschedule once, confirm priority + tighten reminders, then downgrade after repeated misses (src: a2a6KYS2sDw, Jw0XJx6EsdA, gHeOiQ1_V5o — `No-Show Recovery Ladder`, owner ross).

| Rung | Trigger | Move | Line | Owner |
|------|---------|------|------|-------|
| 1 | First no-show | No-blame reschedule; re-send invite; re-confirm notify-channel | "Just wanted to make sure this didn't get buried." (src: ari-gold, rXNCNcEBA3Y) | ari-gold |
| 2 | Reschedule booked | Confirm priority; add ~2h confirm; request live acceptance again | "How do you want to let us know if you can't make it?" (src: ross, a2a6KYS2sDw) | ross |
| 3 | Second no-show | Status-reset prompt forcing a reply bucket | "Maybe you're not ready to explore this" (src: voss, xl0t4J9wtg8) | ari-gold / voss |
| 4 | Repeated miss | Downgrade lead quality; stop protecting the calendar slot | "I'll update our records so we don't keep bugging you." (src: ross, a2a6KYS2sDw) | ross |

### Close-file prompt — when to formally close a dead deal

After a proposal or decision date goes silent, run the proposal cadence to its end and then ask for permission to close. The close-file ask is a pattern interrupt: the buyer who has been ghosting will often re-engage rather than let you close the door (src: 6kZhjbcoMYo, rXNCNcEBA3Y — `Proposal Follow-Up Cadence` + `Status-Reset Follow-Up`, owners voss / harvey / miner).

**Cadence to the close-file ask:**

| When | Touch |
|------|-------|
| +24 hours | Recap — what we agreed, the next step |
| Week 1 | "I'm guessing…" — label the silence: "I assume my email got lost in your inbox" (src: voss, rXNCNcEBA3Y) |
| Week 2 | "Still interested?" — status-reset: still interested / not now / went elsewhere / close file (src: miner, 8ttzQ5eougI, 6kZhjbcoMYo) |
| Final | **Close-file prompt:** "Do you have my permission to close the file?" (src: harvey, 6kZhjbcoMYo, rXNCNcEBA3Y) |

**Fire the close-file prompt when:** a proposal has been sent and the decision date is missed AND ≥2 prior follow-ups went unanswered. It is high-status, not needy — it returns a clear bucket (re-engage or genuinely dead) instead of an open loop rotting in the pipeline.

### Value-only follow-up — give before you ask

Long-cycle leads and renewals get touches that deliver, with **no demand attached**: new info, fresh proof, comps, market insight, a relevant article, a product update. Consistent giving keeps the seller top-of-mind without the pressure that trains a lead to ignore you (src: CStw4HyLDR4, 0ullQyCNWRA — `Value-Only Follow-Up`, owner ari-gold).

| Value touch | Example |
|-------------|---------|
| New info | A change in their market that affects the decision |
| Fresh proof | A peer's before/after that matches their situation |
| Comps | Benchmark / comparison data they can use internally |
| Market insight | A trend, regulation, or competitor move worth flagging |
| Relevant content | An article/clip that answers the unasked question |
| Product update | A new capability that maps to a pain they named |

**Rule:** every nurture-stage and renewal touch is value-only by default. The ask only returns when a buying signal appears (reply, click, re-engagement). A value touch with a hidden ask is not a value touch.

### "Have you given up?" reopen — only after they started something

Use **only** when a prospect already began something — started onboarding, requested a proposal, half-filled a form — and then went silent. The line triggers a reply; it does not fix the cause. After it lands, the agent MUST change the pattern that caused the ghosting (no new value, wrong channel, stalled next step) or the lead ghosts again (src: cQ1p1zIMEVQ, V-IVYaRJ9Ow, janQTa3ay5w — `Have-You-Given-Up Reopen`, owner voss).

- **Reopen line:** "Have you given up on X?" — name the specific thing they started (src: voss, cQ1p1zIMEVQ).
- **Old lost lead variant** (reactivate around the original goal): "did you guys give up on that or what what actually happened" (src: miner, janQTa3ay5w, n2gAJfcp7BA).
- **After the reply lands:** do NOT repeat the touch that got ignored. Bring a new value asset, switch channel, or make the next step smaller — then re-book.

**Do NOT use the reopen on a cold lead that never engaged** — there is nothing to "give up" on, and the line reads as a guilt trip. Cold-but-real leads belong in the 12-touch sequence, not the reopen.

### Anti-Patterns
- Running a desperation cadence (daily pings) on a >90-day nurture lead — match frequency to horizon, not anxiety.
- Sending 12 identical emails instead of rotating phone/text/video/gift/retargeting/newsletter/content.
- Firing "Have you given up?" on a lead that never engaged (no started thing → it's a guilt trip).
- Getting the ghost to reply with the reopen, then repeating the exact touch that caused the ghost.
- Letting a missed-decision-date proposal sit open forever instead of running the close-file prompt.
- Attaching a hidden ask to a "value" touch — it stops being value and trains the ignore.

### Quality Gates
- [ ] Every open lead is staged **Hot / Nurture / Unresponsive**; frequency matches (weekly / monthly / newsletter).
- [ ] Fresh inbound leads get the **Day 1/3/7** speed cadence with a human face on day 1.
- [ ] Unsold-but-real leads have a planned **12-touch** multi-channel sequence (not repeat-email).
- [ ] No-show recovery follows the **ladder** (reschedule → tighten → status-reset → downgrade), cross-ref `pre-call-show-rate-system`.
- [ ] Nurture + renewal touches are **value-only** until a buying signal returns.
- [ ] "Have you given up?" is used **only** on prospects who started something, and the ghosting-cause pattern is changed after the reply.
- [ ] A stalled proposal past its decision date runs to the **close-file prompt** rather than rotting open.
