---
name: community-analytics
description: "Cross-platform community health reports — engagement metrics, sentiment analysis, growth tracking, and channel activity summaries"
triggers:
  - community
  - analytics
  - engagement
  - health-report
---

# Community Analytics Skill

Generate cross-platform community health reports aggregating data from Discord, Telegram, and other community channels. Covers engagement metrics, sentiment analysis, growth tracking, and actionable recommendations.

## When to Invoke

- Generating weekly/monthly community health reports
- Analyzing engagement trends across platforms
- Comparing channel activity and identifying top content
- Planning community strategy based on data
- Identifying at-risk members or declining engagement

---

## Metrics Framework

### Core Metrics

| Metric | Formula | Healthy Range |
|--------|---------|---------------|
| **DAU/MAU Ratio** | Daily Active / Monthly Active × 100 | >20% |
| **Engagement Rate** | (Reactions + Replies) / Messages × 100 | >15% |
| **Growth Rate** | (New Members - Churned) / Total × 100 | >5% monthly |
| **Retention (7d)** | Members active 7d after join / New joins × 100 | >40% |
| **Response Time** | Avg time to first reply in support channels | <1 hour |
| **Content Reach** | Unique members who saw a post / Total members × 100 | >30% |

### Platform-Specific Metrics

#### Discord

| Metric | Source | Notes |
|--------|--------|-------|
| Online members | Presence API | Real-time gauge |
| Messages/channel/day | Message history | Activity distribution |
| Voice minutes | Voice state events | Engagement depth |
| Thread resolution rate | Forum/thread status | Support quality |
| Boost count | Server boost status | Community investment |

#### Telegram

| Metric | Source | Notes |
|--------|--------|-------|
| Active members | getChatMembersCount | 7-day active |
| Messages/day | Message history | Activity volume |
| Post views | Channel analytics | Content reach |
| Forward count | Message metrics | Content virality |
| Invite link clicks | Invite link API | Growth source tracking |

---

## Report Templates

### Weekly Health Report

```markdown
# Community Health Report

**Period**: [Start Date] — [End Date]
**Platforms**: Discord, Telegram
**Generated**: [Date]

---

## Executive Summary
[2-3 sentences: Is the community healthy? Growing? Any concerns?]

## Cross-Platform Overview

| Metric | Discord | Telegram | Total | Trend |
|--------|---------|----------|-------|-------|
| Total Members | [N] | [N] | [N] | [↑↓→] |
| Active Members (7d) | [N] | [N] | [N] | [↑↓→] |
| New Members | [N] | [N] | [N] | [↑↓→] |
| Messages Sent | [N] | [N] | [N] | [↑↓→] |
| Engagement Rate | [%] | [%] | [%] | [↑↓→] |

## Platform Deep Dives

### Discord
**Healthiest Channels** (by engagement):
1. #[channel] — [N] messages, [%] engagement
2. #[channel] — [N] messages, [%] engagement

**Quietest Channels** (may need attention):
1. #[channel] — [N] messages
2. #[channel] — [N] messages

**Top Contributors**: @[user], @[user], @[user]

### Telegram
**Post Performance** (top by views/engagement):
1. "[Post snippet]" — [N] views, [N] reactions
2. "[Post snippet]" — [N] views, [N] reactions

**Growth Sources**:
- Invite link "[name]": [N] joins
- Organic search: [N] joins

## Sentiment Overview
- Positive: ~[X]%
- Neutral: ~[X]%
- Negative: ~[X]%
- **Notable concerns**: [any recurring complaints or issues]

## Recommendations
1. **[Priority]**: [Specific, actionable recommendation]
2. **[Priority]**: [Specific, actionable recommendation]
3. **[Priority]**: [Specific, actionable recommendation]

## Next Week Focus
- [ ] [Action item]
- [ ] [Action item]
```

### Monthly Trend Report

```markdown
# Monthly Community Trends

**Period**: [Month Year]

## Growth Trajectory
| Week | Members | New | Churned | Net |
|------|---------|-----|---------|-----|
| Week 1 | [N] | [N] | [N] | [N] |
| Week 2 | [N] | [N] | [N] | [N] |
| Week 3 | [N] | [N] | [N] | [N] |
| Week 4 | [N] | [N] | [N] | [N] |

## Engagement Trends
[Week-over-week engagement comparison]

## Content Performance
**Best performing content this month**:
1. [Content] — [Metrics]
2. [Content] — [Metrics]

**Content types ranked by engagement**:
1. [Type] — [avg engagement]
2. [Type] — [avg engagement]

## Strategic Insights
[Data-driven observations about community health and direction]
```

---

## Sentiment Analysis

### Approach

Without dedicated NLP tools, estimate sentiment by analyzing:

1. **Reaction ratios**: Positive emoji vs negative emoji on posts
2. **Reply tone**: Supportive vs critical language in replies
3. **Member behavior**: New joins vs leaves, boost/subscribe changes
4. **Support volume**: Increasing support requests may indicate issues
5. **Topic clustering**: What are people talking about most?

### Red Flags

| Signal | What It Means | Action |
|--------|--------------|--------|
| DAU/MAU dropping | Members losing interest | Run engagement campaign |
| Support volume spiking | Product/service issues | Investigate root cause |
| Negative sentiment rising | Community dissatisfaction | Address concerns publicly |
| Growth stalling | Acquisition channels drying up | Review distribution strategy |
| Top contributors going quiet | Burnout or disengagement | Personal outreach |

---

## Data Collection

### Without APIs

If MCP servers aren't configured, collect data manually:
1. Ask Discord/Telegram agents to pull recent message counts
2. Use server/group member counts
3. Estimate engagement from visible reactions and replies
4. Note: Manual collection is less precise but still valuable

### With APIs

When Discord/Telegram MCPs are configured:
1. Query message history for the reporting period
2. Aggregate reactions, replies, and member activity
3. Calculate metrics programmatically
4. Generate reports with precise data

## Best Practices

- **Consistency**: Generate reports on the same schedule (weekly recommended)
- **Trends over absolutes**: A declining 10K community needs more attention than a growing 500-member one
- **Actionable insights**: Every metric should lead to a recommendation
- **Celebrate wins**: Highlight what's working, not just problems
- **Benchmark**: Compare against previous periods, not arbitrary standards
