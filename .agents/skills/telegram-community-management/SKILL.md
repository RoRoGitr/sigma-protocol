---
name: telegram-community-management
description: "Manage Telegram communities — group/channel operations, admin tools, pin messages, media upload, and engagement analytics"
triggers:
  - telegram
  - community
  - group
  - channel
---

# Telegram Community Management Skill

Manage Telegram groups and channels through the Telegram MCP or bot API. Covers message management, admin operations, content scheduling, and community analytics.

## When to Invoke

- Managing Telegram group/channel settings
- Posting or scheduling content
- Moderating members (ban, restrict, promote)
- Uploading media to groups/channels
- Generating community activity reports

---

## Group vs Channel

| Feature | Group | Channel |
|---------|-------|---------|
| Members can post | Yes | No (admins only) |
| Discussion | Direct | Via linked group |
| Max members | 200,000 | Unlimited subscribers |
| Message editing | Original author | Admin only |
| Best for | Community discussion | Broadcasting content |

## Admin Operations

### Member Management

| Action | Bot API Method | Permission Required |
|--------|---------------|-------------------|
| Ban user | `banChatMember` | can_restrict_members |
| Unban user | `unbanChatMember` | can_restrict_members |
| Restrict user | `restrictChatMember` | can_restrict_members |
| Promote to admin | `promoteChatMember` | can_promote_members |
| Get member info | `getChatMember` | — |

### Restriction Permissions

```typescript
// Restrict a user (read-only mode)
await bot.api.restrictChatMember(chatId, userId, {
  permissions: {
    can_send_messages: false,
    can_send_photos: false,
    can_send_videos: false,
    can_send_other_messages: false,
  },
  until_date: Math.floor(Date.now() / 1000) + 86400, // 24 hours
});
```

## Message Management

### Pinning

```typescript
// Pin a message
await bot.api.pinChatMessage(chatId, messageId, {
  disable_notification: false, // notify members
});

// Unpin
await bot.api.unpinChatMessage(chatId, messageId);
```

### Message Templates

#### Announcement

```
📢 *Announcement Title*

Brief summary of the news.

*Key Details:*
• Detail one
• Detail two
• Detail three

[Link or CTA](https://example.com)
```

#### Community Update

```
🏠 *Weekly Community Update*

📊 *Stats:*
• Active members: X
• Messages this week: X
• New members: X

🎯 *This Week:*
• [Event/milestone 1]
• [Event/milestone 2]

💡 *Coming Up:*
• [Upcoming event]
```

## Content Scheduling

Telegram doesn't have native scheduled messages via bot API. Implement scheduling with:

1. **Cron jobs**: Use node-cron to trigger sends at specific times
2. **Queue system**: Bull/BullMQ with delayed jobs
3. **Database**: Store scheduled messages with timestamps, process in a worker

```typescript
import cron from 'node-cron';

// Post daily at 9 AM UTC
cron.schedule('0 9 * * *', async () => {
  await bot.api.sendMessage(channelId, 'Good morning! 🌅');
});
```

## Media Upload

### File Size Limits

| Type | Max Size | Notes |
|------|----------|-------|
| Photo | 10 MB (compressed) | Best as JPEG, max 20 MB uncompressed |
| Video | 50 MB | Supports streaming |
| Document | 50 MB | Any file type |
| Audio | 50 MB | MP3, M4A, etc. |
| Voice | 1 MB | OGG with OPUS codec |
| Sticker | 512 KB | WebP, 512x512 px |

### Media Group (Album)

```typescript
await bot.api.sendMediaGroup(chatId, [
  { type: 'photo', media: new InputFile('/path/to/img1.jpg'), caption: 'Photo 1' },
  { type: 'photo', media: new InputFile('/path/to/img2.jpg') },
]);
```

## Community Analytics

### Key Metrics

| Metric | What It Measures | Target |
|--------|-----------------|--------|
| Daily Active Users | Unique senders/day | Trending up |
| Messages/Day | Group activity | Stable or growing |
| New Members/Week | Growth rate | Consistent |
| Member Retention (7d) | Stickiness | >30% |
| Admin Response Time | Time to moderate | <30 min |

### Activity Report Template

```markdown
## Telegram Community Report — [Date Range]

### Overview
- Total Members: [N] (+/- [change])
- Active Members (7d): [N]
- Messages Sent: [N]
- New Members: [N]

### Top Discussions
1. [Topic] — [N] messages
2. [Topic] — [N] messages

### Content Performance
- Most engaged post: [description] ([N] reactions)
- Most shared: [description] ([N] forwards)

### Action Items
- [ ] [Recommended action]
```

## Invite Link Management

```typescript
// Create invite link with tracking
const link = await bot.api.createChatInviteLink(chatId, {
  name: 'Twitter Campaign',
  expire_date: Math.floor(Date.now() / 1000) + 604800, // 7 days
  member_limit: 100,
});

// Revoke link
await bot.api.revokeChatInviteLink(chatId, link.invite_link);
```

## Moderation Best Practices

### Escalation Ladder

1. **Warning**: Reply to message with rule reminder
2. **Restrict**: Read-only for 1h → 24h → 7d
3. **Ban**: Permanent removal (with optional message delete)

### Anti-Spam Setup

- Enable slow mode: 1 message per 10-30 seconds for new members
- Use `@SpamBot` integration for automated spam detection
- Restrict new members from sending links for first 24 hours
- Set up CAPTCHA verification for new joins
