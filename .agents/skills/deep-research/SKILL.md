---
name: deep-research
description: "Research current, unfamiliar, high-impact, or contested claims before they drive a decision. Select from the tools actually available in the current runtime; use primary sources for technical facts."
triggers:
  - step-1-ideation
  - step-2-architecture
  - step-8-technical-spec
  - 01-market-research
  - plan
  - sigma-planner
  - research
  - investigate
---

# Deep Research Skill

Comprehensive research orchestration for planning and implementation decisions.

Use this skill when a decision depends on information that may be current, unfamiliar, consequential, or disputed. Do not research routine, stable decisions merely because planning has begun. State why research is needed and what decision it will inform.

---

## MCP Tool Selection Matrix

### Tool selection

Inspect the tools available in the current runtime before choosing one. The names below are examples from one configured environment, not a required tool contract.

| Research Need | Primary Tool | Fallback |
|---------------|--------------|----------|
| **Web scraping** | `firecrawl_scrape` | `webfetch` |
| **Site crawling** | `firecrawl_crawl` | Manual links |
| **Semantic search** | `exa_web_search_exa` | `web_search` |
| **Code patterns** | `exa_get_code_context_exa` | GitHub search |
| **Deep research** | `exa_deep_researcher_start` | Multiple queries |
| **Documentation** | `Ref_ref_search_documentation` | Official docs |
| **URL reading** | `Ref_ref_read_url` | `webfetch` |
| **Library docs** | `context7_query-docs` | Ref MCP |
| **Conversational** | `perplexity_ask` | Web search |

---

## Firecrawl Integration

### When to Use Firecrawl

- **Competitor analysis** - scrape pricing pages, feature lists
- **Market research** - scrape industry reports, blog posts
- **Technical research** - scrape documentation, tutorials
- **Content extraction** - get clean content from complex pages

### Firecrawl Tools

```typescript
// Scrape a single page
firecrawl_scrape({
  url: "https://competitor.com/pricing",
  formats: ["markdown", "html"],
  onlyMainContent: true
})

// Crawl an entire site
firecrawl_crawl({
  url: "https://docs.library.com",
  maxDepth: 3,
  limit: 50,
  includePaths: ["/guides/", "/api/"],
  excludePaths: ["/blog/", "/news/"]
})

// Map a site structure
firecrawl_map({
  url: "https://competitor.com",
  limit: 100
})

// Search within a site
firecrawl_search({
  query: "authentication best practices",
  limit: 10
})
```

### Firecrawl Use Cases

| Use Case | Tool | Configuration |
|----------|------|---------------|
| Get pricing info | `scrape` | `onlyMainContent: true` |
| Crawl docs | `crawl` | `includePaths: ["/docs/"]` |
| Map competitor | `map` | `limit: 100` |
| Find specific content | `search` | Query + limit |

---

## EXA Integration

### When to Use EXA

- **Code examples** - find implementation patterns
- **Technical blogs** - find tutorials and guides
- **GitHub repos** - find similar projects
- **Current practices** - find recent best practices

### EXA Tools

```typescript
// Semantic web search
exa_web_search_exa({
  query: "React Server Components data fetching patterns 2026",
  numResults: 10,
  type: "auto" // neural or keyword
})

// Get code context
exa_get_code_context_exa({
  query: "Stripe webhook signature verification Next.js",
  numResults: 5
})

// Deep research (async)
exa_deep_researcher_start({
  instructions: "Research prop firm compliance implementations including daily loss limits, trailing drawdown, and position sizing",
  model: "exa-research-pro"
})

// Check deep research results
exa_deep_researcher_check({
  taskId: "task_abc123"
})

// Crawl specific URL
exa_crawling_exa({
  url: "https://stripe.com/docs/webhooks",
  subpages: true,
  subpageTarget: 10
})
```

---

## Research Process for Planning

### Phase 1: Context Gathering

Before a decision that needs research:

```markdown
1. IDENTIFY research needs:
   - What decisions need to be made?
   - What's unknown or unfamiliar?
   - What competitors/alternatives exist?

2. EXECUTE parallel research:
   - Market: firecrawl_search or exa_web_search_exa
   - Technical: exa_get_code_context_exa
   - Documentation: Ref_ref_search_documentation
   - Deep dive: exa_deep_researcher_start (if complex)

3. SYNTHESIZE findings:
   - Key insights
   - Options discovered
   - Recommendations
```

### Phase 2: Source Credibility

Score each source:

| Factor | Weight | Criteria |
|--------|--------|----------|
| Recency | 30% | Published within 12 months |
| Authority | 25% | Official docs, experts, peer-reviewed |
| Relevance | 25% | Directly addresses the query |
| Depth | 20% | Actionable detail, not fluff |

**Discard sources scoring below 60%.**

### Phase 3: Research Output

```markdown
## Research: [Topic]

**Date:** [TODAY]
**Tools Used:** [Firecrawl, EXA, Ref, Perplexity]
**Sources Evaluated:** [N]
**Sources Included:** [M]

### Executive Summary
[2-3 paragraph synthesis]

### Key Findings

#### Finding 1: [Title]
[Description with evidence]
*Source: [URL] via [Tool]*

#### Finding 2: [Title]
...

### Recommendations for Planning
1. [Recommendation based on research]
2. [Recommendation based on research]

### Source List

| # | Title | URL | Date | Credibility | Tool |
|---|-------|-----|------|-------------|------|
| 1 | ... | ... | ... | 85% | EXA |
| 2 | ... | ... | ... | 90% | Firecrawl |
```

---

## Planning Integration

### Planning handoff

When planning identifies a research-dependent decision:

```markdown
1. READ the planning request
2. IDENTIFY the precise claim, decision, and required evidence
3. EXECUTE the smallest research pass that can resolve it
4. PASS findings, sources, and uncertainty to the planning work
5. Continue planning with the evidence available
```

### Planner → Research Handoff

```yaml
planning_triggers_research:
  - architecture_decision: "Research current best practices for [topic]"
  - technology_choice: "Research [option A] vs [option B] 2026"
  - unfamiliar_feature: "Research implementation patterns for [feature]"
  - market_analysis: "Research competitors and alternatives for [market]"
```

---

## Common Research Patterns

### Pattern 1: Technology Evaluation

```typescript
// 1. Get current best practices
await exa_web_search_exa({
  query: "[Technology] best practices production 2026"
})

// 2. Get code examples
await exa_get_code_context_exa({
  query: "[Technology] implementation patterns examples"
})

// 3. Check official docs
await Ref_ref_search_documentation({
  query: "[Technology] official documentation getting started"
})
```

### Pattern 2: Competitor Analysis

```typescript
// 1. Map competitor sites
await firecrawl_map({ url: "https://competitor.com" })

// 2. Scrape key pages
await firecrawl_scrape({
  url: "https://competitor.com/pricing",
  formats: ["markdown"]
})

// 3. Search for comparisons
await exa_web_search_exa({
  query: "[Your Product] vs [Competitor] comparison 2026"
})
```

### Pattern 3: Deep Technical Research

```typescript
// 1. Start async deep research
const task = await exa_deep_researcher_start({
  instructions: "Research [complex topic] including [aspect 1], [aspect 2], and [aspect 3]"
})

// 2. While waiting, do quick searches
await exa_get_code_context_exa({ query: "[topic] code examples" })
await Ref_ref_search_documentation({ query: "[topic] documentation" })

// 3. Check deep research results
await exa_deep_researcher_check({ taskId: task.id })
```

---

## Quality Checklist

Before concluding research:

- [ ] Used the smallest set of sources and tools that can support the decision
- [ ] Source count is proportional to the decision; a primary source may be sufficient for a narrow factual claim
- [ ] Checked recency when the subject can change; recorded the publication or update date where available
- [ ] Code examples gathered (if technical)
- [ ] Official documentation checked
- [ ] Conflicting views noted
- [ ] Confidence level stated
- [ ] Recommendations actionable

---

## Error Handling

### If Firecrawl unavailable
```markdown
1. Use exa_crawling_exa for site crawling
2. Use webfetch for single pages
3. Note limitation in research output
```

### If EXA unavailable
```markdown
1. Use web_search for general queries
2. Use Ref_ref_search_documentation for docs
3. Note limitation in research output
```

### If no MCP tools available
```markdown
1. Notify user research will be limited
2. Use training knowledge with explicit caveats
3. Flag claims as "unverified - recommend manual research"
4. Suggest specific queries for user to run
```

---

## Integration with Sigma Protocol

| Step | Research Role |
|------|---------------|
| Step 1 (Ideation) | Market research, competitor analysis |
| Step 2 (Architecture) | Technology evaluation, pattern research |
| Step 3 (UX Design) | UI pattern research, accessibility |
| Step 8 (Technical Spec) | Implementation patterns, API research |
| Step 12 (Context Engine) | Codebase context, documentation |

---
