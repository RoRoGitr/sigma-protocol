---
name: x-twitter-research
description: "Research X/Twitter content — fetch tweets/threads via API, analyze engagement, monitor trends, and extract insights"
triggers:
  - x
  - twitter
  - tweet
  - thread
---

# X/Twitter Research Skill

Fetch, analyze, and extract insights from X/Twitter content. Supports tweet/thread retrieval, user timeline analysis, trend monitoring, and content opportunity identification.

## When to Invoke

- Fetching a specific tweet or thread for analysis
- Researching a topic or hashtag on X/Twitter
- Analyzing competitor content strategies on X
- Monitoring trends relevant to a project
- Extracting content ideas from viral tweets

---

## X API v2 Integration

### Authentication

```bash
# Bearer Token (read-only, most common)
export X_BEARER_TOKEN="your-bearer-token"

# Verify access
curl -X GET "https://api.twitter.com/2/tweets/search/recent?query=from:elonmusk" \
  -H "Authorization: Bearer $X_BEARER_TOKEN"
```

### Getting a Bearer Token

1. Go to https://developer.x.com/en/portal/dashboard
2. Create a project and app
3. Generate a Bearer Token (requires at least Basic tier, $100/month for search)
4. Free tier: limited to tweet posting only

### Key Endpoints

| Endpoint | What It Does | Tier Required |
|----------|-------------|---------------|
| `GET /2/tweets/:id` | Fetch single tweet | Free |
| `GET /2/tweets/search/recent` | Search recent tweets (7 days) | Basic |
| `GET /2/tweets/search/all` | Full archive search | Pro |
| `GET /2/users/:id/tweets` | User timeline | Basic |
| `GET /2/tweets/:id/quote_tweets` | Quote tweets | Basic |

## Tweet Fetching

### Single Tweet with Expansions

```bash
curl -X GET "https://api.twitter.com/2/tweets/TWEET_ID?\
tweet.fields=created_at,public_metrics,conversation_id,context_annotations&\
expansions=author_id,referenced_tweets.id&\
user.fields=username,name,verified" \
  -H "Authorization: Bearer $X_BEARER_TOKEN"
```

### Thread Reconstruction

Threads are linked by `conversation_id`:

```bash
# Get the conversation
curl -X GET "https://api.twitter.com/2/tweets/search/recent?\
query=conversation_id:TWEET_ID from:AUTHOR_USERNAME&\
tweet.fields=created_at,in_reply_to_user_id&\
max_results=100" \
  -H "Authorization: Bearer $X_BEARER_TOKEN"
```

Sort results by `created_at` to reconstruct thread order.

## Fallback: Web Scraping

When X API access is unavailable:

1. **WebFetch**: Fetch tweet URL directly (may be blocked)
2. **WebSearch**: Search for tweet content via web search engines
3. **Nitter instances**: Some public Nitter mirrors still operational
4. **Archive.org**: Check Wayback Machine for cached tweets

Note: Scraping is less reliable and may violate ToS. API access is strongly preferred.

## Analysis Framework

### Tweet Analysis Template

```markdown
# Tweet Analysis: [Topic/URL]

**Author**: @[username] ([name])
**Posted**: [date/time]
**Engagement**: [likes] likes, [retweets] RTs, [replies] replies, [views] views

---

## Content
[Full tweet text]

## Thread Context
[If part of a thread, include full thread]

## Analysis
- **Topic**: [what the tweet is about]
- **Sentiment**: [positive/negative/neutral]
- **Key Claim**: [main argument or statement]
- **Audience Reaction**: [summary of reply sentiment]

## Engagement Analysis
- **Engagement Rate**: [likes+RTs+replies / views × 100]%
- **Reply-to-Like Ratio**: [high ratio = controversial, low = consensus]
- **Quote-to-RT Ratio**: [high ratio = people adding commentary]

## Content Opportunities
- [How you could build on this topic]
- [Counter-argument or complementary angle]
- [Related content idea]
```

### Topic Research Template

```markdown
# X/Twitter Research: [Topic]

**Query**: [search terms used]
**Date Range**: [from] to [to]
**Total Results**: [N]

---

## Top Tweets by Engagement
1. @[user]: "[tweet snippet]" — [metrics]
2. @[user]: "[tweet snippet]" — [metrics]
3. @[user]: "[tweet snippet]" — [metrics]

## Key Themes
1. **[Theme]**: [description with examples]
2. **[Theme]**: [description with examples]

## Notable Voices
- @[user]: [why they're relevant, their angle]
- @[user]: [why they're relevant, their angle]

## Sentiment Overview
- Positive: ~[X]%
- Neutral: ~[X]%
- Negative: ~[X]%

## Content Opportunities
- [Underserved angle or gap]
- [Trending sub-topic]
- [Controversial take with engagement potential]

## Hashtags & Keywords
- Primary: [hashtags]
- Related: [keywords]
```

## Rate Limits

### X API v2 Rate Limits

| Endpoint | Free | Basic | Pro |
|----------|------|-------|-----|
| Tweet lookup | 15/15min | 15/15min | 300/15min |
| Recent search | — | 60/15min | 300/15min |
| User timeline | — | 15/15min | 900/15min |
| Monthly tweet cap | 500 reads | 10,000 reads | 1M reads |

Always implement exponential backoff and track remaining quota.

## Output Format

### File Location

```
docs/research/transcripts/YYYY-MM-DD-x-[slug].md
docs/research/analysis/YYYY-MM-DD-[topic].md
```

## Best Practices

### Research Quality
- Always include engagement metrics for context
- Note the date — X conversations are highly time-sensitive
- Capture the full thread, not just the head tweet
- Check for community notes/corrections on viral tweets

### Ethical Considerations
- Respect privacy — don't research private accounts
- Note deleted tweets may indicate retracted statements
- Be aware of bot activity in engagement metrics
- Don't amplify harmful content in summaries
