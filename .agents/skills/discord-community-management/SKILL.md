---
name: discord-community-management
description: "Manage Discord communities — channel CRUD, role permissions, moderation, thread/forum management, audit logs, and engagement analytics"
triggers:
  - discord
  - community
  - server
  - moderation
  - channel
---

# Discord Community Management Skill

Manage live Discord servers through the Discord MCP or bot API. Covers channel management, role permissions, moderation workflows, thread/forum setup, and community analytics.

## When to Invoke

- Managing channels, categories, or server structure
- Configuring roles and permissions
- Posting announcements or content to channels
- Moderating members (timeout, kick, ban)
- Setting up forum channels or threads
- Generating community activity reports

---

## Channel Management

### Channel Types

| Type | Use Case | Key Settings |
|------|----------|-------------|
| Text | General discussion | Topic, slowmode, NSFW flag |
| Voice | Live conversation | Bitrate, user limit, region |
| Forum | Organized discussions | Tags, default reaction, guidelines |
| Stage | Events, presentations | Moderators, topic |
| Announcement | Cross-server updates | Follow capability |
| Category | Organization | Permission inheritance |

### Channel Organization Best Practices

```
📋 INFORMATION
  ├── #welcome
  ├── #rules
  ├── #announcements
  └── #faq

💬 COMMUNITY
  ├── #general
  ├── #introductions
  └── #off-topic

🔧 SUPPORT
  ├── #help-forum (Forum channel)
  └── #bug-reports

📢 CONTENT
  ├── #content-drops
  ├── #resources
  └── #showcase
```

## Role & Permission Management

### Permission Hierarchy

```
Server Owner (all permissions)
  └── Admin (manage server, roles, channels)
      └── Moderator (manage messages, timeout, kick)
          └── Member (send messages, react, connect)
              └── Visitor (view channels only)
```

### Key Permissions

| Permission | Admin | Mod | Member |
|-----------|-------|-----|--------|
| Manage Server | Yes | No | No |
| Manage Channels | Yes | No | No |
| Manage Roles | Yes | No | No |
| Kick Members | Yes | Yes | No |
| Ban Members | Yes | Yes | No |
| Timeout Members | Yes | Yes | No |
| Manage Messages | Yes | Yes | No |
| Send Messages | Yes | Yes | Yes |
| View Channels | Yes | Yes | Yes |

## Moderation Workflows

### Escalation Ladder

1. **Warning** — DM the user with a reminder of rules
2. **Timeout** — 1 hour → 24 hours → 7 days (escalating)
3. **Kick** — Remove from server (can rejoin)
4. **Ban** — Permanent removal (with optional message purge)

### Audit Log Monitoring

Key audit events to track:
- Member joins/leaves
- Role changes
- Channel modifications
- Message deletions (by mods)
- Ban/kick actions

## Thread & Forum Management

### Forum Channel Setup

```
Forum: #help-forum
├── Tags: [Bug, Feature Request, Question, Resolved]
├── Default Reaction: ✅
├── Guidelines: "Search before posting. Include reproduction steps."
├── Sort: Latest Activity
└── Auto-archive: 24 hours of inactivity
```

### Thread Best Practices

- Use threads for focused discussions in busy channels
- Auto-archive after 24h to reduce clutter
- Pin important threads
- Use thread-specific permissions for sensitive discussions

## Community Analytics

### Key Metrics

| Metric | What It Measures | Target |
|--------|-----------------|--------|
| DAU/MAU Ratio | Daily vs monthly active | >20% healthy |
| Messages/Day | Activity volume | Trending up |
| New Members/Week | Growth rate | Consistent |
| Retention (7-day) | New member stickiness | >40% |
| Response Time | Time to first reply in support | <1 hour |
| Thread Resolution | Help threads marked resolved | >70% |

### Activity Report Template

```markdown
## Community Health Report — [Date Range]

### Overview
- Total Members: [N] (+/- [change])
- Active Members (7d): [N]
- Messages Sent: [N]
- New Members: [N]

### Top Channels by Activity
1. #general — [N] messages
2. #help-forum — [N] threads
3. #content — [N] messages

### Engagement Highlights
- Most active day: [day]
- Peak activity hour: [hour]
- Top contributors: [members]

### Action Items
- [ ] [Recommended action based on data]
```

## Content Posting Guidelines

### Announcement Format

```markdown
📢 **[Announcement Title]**

[1-2 sentence summary]

**Key Details:**
• [Detail 1]
• [Detail 2]
• [Detail 3]

[CTA or link]
```

### Embed Best Practices

- Use brand colors consistently
- Include timestamps for time-sensitive content
- Add footer with source/attribution
- Keep descriptions under 4096 characters
- Use inline fields for compact data display
