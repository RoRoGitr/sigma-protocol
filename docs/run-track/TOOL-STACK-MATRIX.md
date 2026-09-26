# Tool Stack Matrix — Run Track

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Purpose:** Vendor-neutral tiers per business function. Skills **route** to these tools; MCPs/CLIs **execute**.

---

## Matrix

| Function | Tier 1 (free / bootstrap) | Tier 2 (founder default) | Tier 3 (scale) | Sigma skill | Sigma MCP / CLI |
|----------|---------------------------|--------------------------|----------------|-------------|-----------------|
| **Analytics / product** | PostHog free, GA4 | PostHog + Sentry | Amplitude, Mixpanel | `observability`, `gtm-stack-setup` | `user-sentry` |
| **Error tracking** | Sentry free | Sentry team | Sentry enterprise | `sentry` | `user-sentry` |
| **Social scheduling** | Manual + native apps | **the social scheduler** | Buffer, Hootsuite | `gtm-stack-setup` | your scheduler's MCP |
| **Video / image gen** | Manual | **Higgsfield CLI**, Kie.ai | Arcads, Runway | `ad-creative-generation`, `ad-image-prompting`, `media-generation` | `user-higgsfield` |
| **Email / lifecycle** | Resend free | ConvertKit, **GHL**, Resend prod | Customer.io, Braze | `06-email-sequences`, `visual-email-sequences` (global) | — |
| **CRM / pipeline** | Notion table | **GHL**, HubSpot free | Salesforce | `crm-pipeline-setup` | — |
| **Outbound email** | Gmail manual | Instantly, Smartlead | Outreach.io | `outreach-sequencing` | Gmail MCP (Claude) |
| **DM / comment funnels** | Manual DMs | **ManyChat** | — | `manychat-funnel-strategy`, `dm-funnel` | ManyChat API skill |
| **Paid ads** | — | Meta + Google Ads | + LinkedIn | `08-ads-strategy`, `meta-ad-builder` | Chrome/ad managers via `/ads` |
| **SEO** | Manual | Ahrefs/Semrush trial | Enterprise SEO | `16-seo-content` | Exa, Firecrawl |
| **Voice / AI calls** | — | **VAPI**, LiveKit | Twilio + VAPI | `voice-outbound-patterns` (v2) | — |
| **Transcripts / research** | — | Supadata | — | `22-video-research` | `user-supadata` |
| **Community** | Discord/TG free | Discord + Telegram bots | — | `17-community-update`, `discord-community-management` | Discord/TG skills |

---

## Cross-department reuse

| Tool | Marketing | Sales | Content | Growth |
|------|-----------|-------|---------|--------|
| **the social scheduler** | Schedule posts, multi-profile | Founder brand outbound | Publish calendar | — |
| **PostHog** | Funnel, UTM | — | Content CTR | Activation events |
| **GHL** | Email + landing | CRM + pipeline | — | Lifecycle |
| **ManyChat** | Comment→DM ads | S6 inbound | Keyword funnels | — |
| **Higgsfield CLI** | Ad creative | — | Short-form video | — |

---

## M3 / S2 setup order (recommended)

1. PostHog (or GA4) — verify `$pageview` and one custom event  
2. Meta Pixel + CAPI (if paid social)  
3. Email provider (Resend/ConvertKit/GHL)  
4. CRM pipeline (GHL/HubSpot) — **after** S2 stage definitions written  
5. the social scheduler accounts connected  
6. ManyChat (if DM funnel in BUSINESS-MODEL module)  
7. Sentry (if app shipped)  

---

## Credential gate (founder-only)

Run Track never stores secrets in git. Project overlay documents **account IDs and roles only**:

```markdown
## Active Channels & Accounts
- PostHog: project ID xxx (Admin: founder)
- the social scheduler: profile "Brand" — account_id from accounts_list
```

Founder provides OAuth/API keys in local env or MCP auth flows.

---

## v2 additions

- VAPI + LiveKit outbound for SDR voice  
- Twilio SMS for follow-up  
- Go High Level deep automation (workflows as reference, not in skills)
