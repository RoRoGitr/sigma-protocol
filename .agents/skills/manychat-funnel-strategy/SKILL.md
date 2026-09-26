---
name: manychat-funnel-strategy
description: "Plan ManyChat DM funnels, write conversion copy, and produce step-by-step flow blueprints for Instagram, TikTok, and Messenger automations"
triggers:
  - manychat
  - dm-funnel
  - lead-flow
  - dm-automation
  - instagram-dm
  - tiktok-dm
---

# ManyChat Funnel Strategy Skill

Plan, architect, and write copy for ManyChat DM automations across Instagram, TikTok, and Messenger. Produces complete flow blueprints ready to build in ManyChat's visual editor.

## When to Invoke

- Planning a new DM funnel or lead flow
- Writing copy for ManyChat message sequences
- Designing comment-triggered automations (IG/TikTok)
- Architecting multi-step qualification flows
- Creating cross-brand funnel strategies

---

## Core Framework: The DM Funnel Stack

Every funnel follows this progression:

```
TRIGGER → HOOK → QUALIFY → VALUE → CONVERT → NURTURE
```

### 1. Trigger (How It Starts)

| Platform | Trigger Type | Example |
|----------|-------------|---------|
| Instagram | Comment keyword | User comments "GUIDE" on a Reel |
| Instagram | Story reply | User replies to a story with a keyword |
| Instagram | DM keyword | User DMs the page with "pricing" |
| Instagram | Link in bio click | User clicks growth tool link |
| TikTok | Comment keyword | User comments "LINK" on a TikTok |
| TikTok | DM keyword | User DMs the account |
| Messenger | Get Started button | User opens Messenger chat |
| Messenger | Ref link | User clicks a `m.me/` link with ref param |
| Any | API trigger | External system calls `sendFlow` |

### 2. Hook (First Message)

The first DM sets the tone. Rules:
- **Under 50 words** -- mobile screens are small
- **Use their name**: `{first_name}` personalization
- **Immediate value signal**: Tell them what they're getting
- **One clear CTA**: Button or quick reply, never both

**Good:**
> Hey {first_name}! 🔥 Here's the free trading checklist you asked for. Tap below to grab it.
> [Get the Checklist]

**Bad:**
> Hi there! Thank you so much for your interest in our amazing trading checklist! We've put together a comprehensive guide that covers everything from market analysis to risk management. Click below to download it, and don't forget to check out our other resources too!

### 3. Qualify (Segment the Lead)

Use Quick Replies to segment without friction:

```
"Quick question -- what best describes you?"

[🏗️ Building my first app]
[📈 Scaling an existing product]
[🏢 Running an agency]
```

- Each reply → set Custom Field `subscriber_type`
- Each reply → add Tag for segment
- Route to different flows based on answer

### 4. Value (Deliver Before You Ask)

Give something genuinely useful before asking for anything:
- PDF/checklist/template download link
- Quick tip or insight relevant to their segment
- Access to a free resource or community

### 5. Convert (The Ask)

Match the ask to the funnel stage:

| Funnel Stage | Ask | Example |
|-------------|-----|---------|
| Top | Email capture | "Drop your email and I'll send the full guide" |
| Middle | Webinar/event signup | "We're going live Thursday -- want the link?" |
| Bottom | Purchase/book call | "Ready to get started? Here's the link" |

### 6. Nurture (Post-Conversion)

After conversion, continue the relationship:
- Delay 24-48h → "Did you get a chance to check it out?"
- Weekly value messages (tagged as OTN or within 24h window)
- Re-engagement flow for cold subscribers (30-day tag check)

---

## Copy Frameworks for DM Messages

### The 3C Formula (Connect, Contextualize, CTA)

```
[Connect]: Acknowledge why they're here
[Contextualize]: Frame the value in their world
[CTA]: One clear next step
```

Example:
> Hey {first_name}! Saw you're interested in AI coding tools. 💻
> I put together a cheat sheet with the exact prompts I use to ship features 3x faster.
> [Send me the cheat sheet]

### The Curiosity Gap

Open a loop, close it with the CTA:

> Most developers waste 2 hours/day on boilerplate code.
> I built a system that eliminates it completely.
> Want to see how it works?
> [Yes, show me] [Not right now]

### The Social Proof Nudge

For conversion messages:

> 2,400+ developers are already using the SSS Protocol to ship faster.
> Want to join them?
> [Join the Academy]

---

## Platform-Specific Patterns

### Instagram DM Automation

**Comment-to-DM Flow (Highest Converting):**
1. Post a Reel/carousel with CTA: "Comment [KEYWORD] and I'll send it to your DMs"
2. ManyChat detects keyword → sends DM within seconds
3. First message: deliver promised value immediately
4. Follow-up: qualify and segment

**Rules:**
- Instagram limits: 1 message per trigger (then subscriber must reply to continue)
- Use Quick Replies to keep the conversation going (each reply = new 24h window)
- Story mentions and replies can also trigger flows
- Don't send more than 3 messages before a reply -- Meta flags spam

### TikTok DM Automation

**Comment Trigger Flow:**
1. Post TikTok with CTA: "Comment [KEYWORD] for the free guide"
2. ManyChat detects keyword → sends DM
3. TikTok DMs are newer -- keep flows simple (3-5 steps max)

**Rules:**
- TikTok automation is newer, fewer features than Instagram
- Focus on lead capture (email/phone) early in the flow
- TikTok audience skews younger -- adjust copy tone
- Shorter messages perform better on TikTok

### Messenger

**Most feature-rich platform:**
- Persistent menus, webviews, payment buttons
- Longer flows are acceptable (users expect Messenger bots)
- Can use carousels, galleries, and media-rich messages
- 24h + 1 rule: 1 follow-up message after 24h window, then need OTN

---

## Multi-Brand Funnel Architecture

When managing funnels across multiple companies:

```
PERSONAL BRAND (Authority Content)
  ├── Lead Magnet Flow → Email capture
  ├── Content Engagement → Tag interests
  └── Cross-Sell Flows:
       ├── Interest A → Route to Product A funnel
       └── Interest B → Route to Product B funnel

PRODUCT A (e.g. a SaaS platform)
  ├── Free Tool Flow → Calculator/checklist
  ├── Webinar Flow → Live sessions
  └── Conversion Flow → Signup

PRODUCT B (e.g. an education offer)
  ├── Free Resource Flow → Preview content
  ├── Community Flow → Discord invite
  └── Conversion Flow → Paid tier upsell (post-checkout)
```

### Cross-Brand Tagging Convention

Use a namespace prefix for multi-brand clarity:

| Tag | Purpose |
|-----|---------|
| `brand:personal` | Entered via personal brand content |
| `brand:product-a` | Entered via Product A content |
| `brand:product-b` | Entered via Product B content |
| `interest:topic-a` | Interested in topic A |
| `interest:topic-b` | Interested in topic B |
| `interest:ai` | Interested in AI/ML |
| `stage:lead` | New lead, not yet qualified |
| `stage:engaged` | Opened/clicked, showing interest |
| `stage:customer` | Converted |
| `stage:cold` | No engagement in 30+ days |

---

## Flow Blueprint Template

Use this template for every flow you design:

```markdown
## Flow: [Descriptive Name]

**Company**: [Personal / Product A / Product B]
**Platform**: [Instagram / TikTok / Messenger / Multi]
**Trigger**: [Exact trigger mechanism]
**Goal**: [Primary conversion metric]
**Expected Flow Length**: [Number of steps]

### Tags Created
- [tag_name]: [when applied]

### Custom Fields Used
- [field_name] (type): [what it stores]

### Steps

#### Step 1: [Name] (Message)
**Delay**: None (immediate)
**Copy**:
> [Exact message text with {first_name} personalization]

**Buttons/Quick Replies**:
- [Label 1] → Step 2a
- [Label 2] → Step 2b

**Actions**:
- Tag: [applied]
- Custom Field: [set]

#### Step 2a: [Name] (Condition)
**Condition**: [What's being checked]
- True → Step 3
- False → Step 4

...
```

---

## Metrics to Track

For each flow, define success metrics:

| Metric | Target | How to Measure |
|--------|--------|---------------|
| Open Rate | 80%+ | Messages opened / sent |
| Reply Rate | 30%+ | Subscribers who reply / opened |
| Click-Through Rate | 15%+ | Button clicks / messages sent |
| Conversion Rate | 5-10% | Conversions / subscribers entered |
| Drop-off Point | Identify | Step where most subscribers exit |

---

## Message Timing Best Practices

| Scenario | Delay | Rationale |
|----------|-------|-----------|
| After trigger | Immediate (0s) | Strike while iron is hot |
| Follow-up question | 2-5 minutes | Feels conversational, not automated |
| Value delivery after qualification | 1-3 minutes | Enough time to feel curated |
| Post-conversion check-in | 24 hours | Respect their time |
| Re-engagement | 3-7 days | Don't be clingy |
| Cold subscriber reactivation | 30 days | Last-chance before archiving |
