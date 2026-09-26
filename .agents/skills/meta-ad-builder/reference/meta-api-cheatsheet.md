# Meta Marketing API — cheat sheet

Everything needed to programmatically create and manage campaigns, ad sets, ads, and creative assets via the Graph API. Distilled from a production codebase across thousands of ad deploys.

**Base URL:** `https://graph.facebook.com/{API_VERSION}`

**Recommended versions:** `v24.0` (general), `v23.0` (ASC+ campaigns, DSA queries)

**Auth header:** `Authorization: Bearer {ACCESS_TOKEN}`

---

## 1. Authentication

### 1.1 Long-lived token

Short-lived tokens (~1 hour) must be exchanged for long-lived tokens (~60 days):

```
GET https://graph.facebook.com/v23.0/oauth/access_token
  ?grant_type=fb_exchange_token
  &client_id={META_APP_ID}
  &client_secret={META_APP_SECRET}
  &fb_exchange_token={SHORT_LIVED_TOKEN}
```

If the token is already long-lived, Meta returns error code `190` / subcode `463` — this is not a real error; the token is fine.

### 1.2 Token inspection

```
GET https://graph.facebook.com/debug_token
  ?input_token={TOKEN_TO_INSPECT}
  &access_token={APP_ID}|{APP_SECRET}
```

Returns `app_id`, `user_id`, `scopes`, `expires_at`, `type`.

### 1.3 Token refresh strategy

Meta tokens from Facebook Login for Business have no refresh tokens. The strategy:
- Exchange short-lived → long-lived on first connect
- Re-exchange within 7 days of `expires_at`
- After expiry, user must re-authenticate

---

## 2. Account management

### 2.1 Fetch ad accounts

```
GET /me/adaccounts?fields=account_id,name,currency,timezone_name,account_status&limit=100
```

### 2.2 Ad account ID format

All ad account endpoints require the `act_` prefix: `act_<YOUR_AD_ACCOUNT_ID>`.

Normalize: if the ID doesn't start with `act_`, prepend it.

---

## 3. Campaigns

### 3.1 Create a campaign

```json
POST /act_{ACCOUNT_ID}/campaigns
{
  "name": "My Campaign",
  "objective": "OUTCOME_SALES",
  "status": "PAUSED",
  "special_ad_categories": [],
  "daily_budget": 10000,
  "pacing_type": ["standard"],
  "bid_strategy": "LOWEST_COST_WITHOUT_CAP"
}
```

Budget values are in **cents** (10000 = $100.00).

### 3.2 Campaign objectives

`OUTCOME_SALES`, `OUTCOME_LEADS`, `OUTCOME_TRAFFIC`

### 3.3 Campaign types

**CBO (Campaign Budget Optimization / ADV+):** Include `daily_budget`, `pacing_type`, `bid_strategy` at campaign level.

**ABO (Ad Set Budget Optimization):** Omit those fields at campaign level; set budget at the ad set level instead.

**ASC+ (Advantage Shopping Campaign+):** Use `"smart_promotion_type": "AUTOMATED_SHOPPING_ADS"` and API version `v23.0` (deprecated in v24.0+). Omit `targeting_automation` and `is_adset_budget_sharing_enabled` entirely.

### 3.4 Special Ad Categories

Always required on campaign creation, even if empty:
```json
{ "special_ad_categories": [] }
```
Valid values: `HOUSING`, `EMPLOYMENT`, `CREDIT`, `ISSUES_ELECTIONS_POLITICS`

When country restrictions apply:
```json
{ "special_ad_categories": ["HOUSING"], "special_ad_category_country": ["US", "CA"] }
```
Omit `special_ad_category_country` entirely when it has no values — do not send an empty array.

---

## 4. Ad sets

### 4.1 Create an ad set

```json
POST /act_{ACCOUNT_ID}/adsets
{
  "name": "My Ad Set",
  "campaign_id": "120200...",
  "billing_event": "IMPRESSIONS",
  "optimization_goal": "OFFSITE_CONVERSIONS",
  "status": "ACTIVE",
  "bid_strategy": "LOWEST_COST_WITHOUT_CAP",
  "pacing_type": ["standard"],
  "daily_budget": 5000,
  "promoted_object": {
    "pixel_id": "<YOUR_PIXEL_ID>",
    "custom_event_type": "PURCHASE"
  },
  "targeting": { "geo_locations": { "countries": ["US"] } }
}
```

### 4.2 Targeting object (key fields)

```json
{
  "geo_locations": {
    "countries": ["US"],
    "location_types": ["home", "recent"]
  },
  "age_min": 25,
  "age_max": 55,
  "publisher_platforms": ["facebook", "instagram"],
  "facebook_positions": ["feed", "story", "facebook_reels"],
  "instagram_positions": ["stream", "story", "reels"],
  "targeting_automation": { "advantage_audience": 1 }
}
```

Always include `location_types: ["home", "recent"]` when using city/region/zip targeting.

### 4.3 DSA (EU compliance)

Required when targeting EU countries:
```json
{ "dsa_beneficiary": "Company Name", "dsa_payor": "Company Name" }
```

---

## 5. Ads

### 5.1 Create an ad (multi-variant text liquidity)

```json
POST /act_{ACCOUNT_ID}/ads
{
  "adset_id": "120200...",
  "name": "My Ad",
  "status": "PAUSED",
  "creative": {
    "object_story_spec": {
      "page_id": "<YOUR_PAGE_ID>",
      "video_data": {
        "video_id": "120200...",
        "image_url": "https://...",
        "call_to_action": { "type": "SIGN_UP", "value": { "link": "https://example.com" } }
      }
    },
    "asset_feed_spec": {
      "optimization_type": "DEGREES_OF_FREEDOM",
      "bodies": [{"text": "Body 1"}, {"text": "Body 2"}],
      "titles": [{"text": "Title 1"}, {"text": "Title 2"}],
      "descriptions": [{"text": "Description 1"}],
      "call_to_action_types": ["SIGN_UP"]
    },
    "degrees_of_freedom_spec": {
      "degrees_of_freedom_type": "USER_ENROLLED",
      "text_transformation_types": ["TEXT_LIQUIDITY"],
      "creative_features_spec": { ... }
    }
  }
}
```

All ads created by the skill use `"status": "PAUSED"`.

### 5.2 Fetching an ad's creative

```
GET /{AD_ID}?fields=creative{object_story_spec,asset_feed_spec,degrees_of_freedom_spec}
```

---

## 6. Creative assets

### 6.1 Upload image (base64)

```
POST /act_{ACCOUNT_ID}/adimages
bytes={BASE64_IMAGE_DATA}&name=my-image.jpg&access_token={TOKEN}
```

Response returns `images.{filename}.hash` — this is the `image_hash` for image ads. Max image size: 30 MB.

### 6.2 Upload video (URL-based)

```json
POST /act_{ACCOUNT_ID}/advideos
{ "file_url": "https://publicly-accessible-url.com/video.mp4", "name": "my-video.mp4" }
```

Video processing is async. Poll `GET /<video_id>?fields=status,thumbnails{uri,is_preferred}` until `video_status == "ready"`.

### 6.3 Video thumbnail gotchas

- `video_data` can have either `image_url` OR `image_hash`, never both — Meta rejects payloads with both present.
- In `asset_feed_spec.videos[]`, only `thumbnail_url` is supported (no `thumbnail_hash`).
- Temp/expiring URLs in `thumbnail_url` can cause error `1487713` — upload the image to `adimages` first and use its hash instead.

---

## 7. Ad insights

### 7.1 Pull ad-level insights

```
GET /act_{ACCOUNT_ID}/insights
  ?level=ad
  &fields=ad_id,ad_name,spend,impressions,clicks,actions,action_values
  &date_preset=last_30d
  &sort=spend_descending
  &filtering=[{"field":"spend","operator":"GREATER_THAN","value":"0"}]
```

### 7.2 Date presets

`maximum`, `today`, `yesterday`, `this_month`, `last_month`, `last_7d`, `last_14d`, `last_28d`, `last_30d`, `last_90d`

### 7.3 Extracting ROAS from actions/action_values

ROAS = `purchase_revenue / spend`. Extract purchase revenue from the `action_values` array where `action_type == "purchase"`.

---

## 8. Advantage+ creative enhancements (`creative_features_spec`)

Standard enrollment map used by `deploy-ad.py`:

```json
{
  "advantage_plus_creative": {"enroll_status": "OPT_IN"},
  "creative_stickers": {"enroll_status": "OPT_IN"},
  "enhance_cta": {"enroll_status": "OPT_IN", "customizations": {"text_extraction": {"enroll_status": "OPT_IN"}}},
  "generate_cta": {"enroll_status": "OPT_IN"},
  "inline_comment": {"enroll_status": "OPT_IN"},
  "product_extensions": {"enroll_status": "OPT_OUT", "customizations": {"pe_carousel": {"enroll_status": "OPT_OUT"}}},
  "reveal_details_over_time": {"enroll_status": "OPT_IN"},
  "show_destination_blurbs": {"enroll_status": "OPT_IN"},
  "show_summary": {"enroll_status": "OPT_IN"},
  "site_extensions": {"enroll_status": "OPT_OUT"},
  "text_optimizations": {"enroll_status": "OPT_IN", "customizations": {"text_extraction": {"enroll_status": "OPT_IN"}}},
  "text_translation": {"enroll_status": "OPT_IN"},
  "video_auto_crop": {"enroll_status": "OPT_IN"},
  "video_filtering": {"enroll_status": "OPT_IN"},
  "video_uncrop": {"enroll_status": "OPT_IN"}
}
```

**`standard_enhancements` is deprecated.** Meta returns it in creative specs but rejects it on create/copy (error `3858504`). Always strip it before sending payloads.

---

## 9. Error handling

### Transient errors (auto-retried)

Meta returns transient `OAuthException` (code `2`, `is_transient: true`) under load. Retry with exponential backoff (5s → 10s → 20s, cap 60s).

### Rate limiting (HTTP 429)

Honor the `Retry-After` header. If absent, wait 5s and retry once.

### HTTP 5xx

Retry up to 2 times with 2s backoff.

### Common error subcodes

| Subcode | Meaning |
|---|---|
| 1487713 | Video failed to process — video not ready when ad was created |
| 1885252 | Video not ready for use in an ad — `video_status` not yet `"ready"` |
| 3858504 | `standard_enhancements` included — strip it |
| 190/463 | Token already long-lived — not a real error |

---

## 10. Ad Library API (competitor research)

### 10.1 Endpoint

```
GET https://graph.facebook.com/{VERSION}/ads_archive
  ?ad_reached_countries=US
  &search_page_ids={PAGE_IDS}
  &ad_active_status=ACTIVE
  &sort_by=impressions_high_to_low
  &fields=id,page_name,ad_snapshot_url,ad_creative_bodies
  &limit=50
```

Provide either `search_page_ids` (comma-separated Page IDs, max 10) or `search_terms` — not both.

### 10.2 Gotchas

- No impressions/spend data for US commercial ads — only returned for political/issue ads and EU ads.
- Page IDs required — resolve names via `GET /{username}?fields=id` when only a vanity URL is known.
- Media not in API response — the API returns `ad_snapshot_url` only; downloading images/videos requires opening the snapshot URL separately.
- Requesting `ad_creative_bodies` with pagination can cause intermittent HTTP 500 — fetch creative fields per-ad if needed.

---

## 11. Enum reference (key values)

### CTA types

`LEARN_MORE`, `SHOP_NOW`, `SIGN_UP`, `SUBSCRIBE`, `APPLY_NOW`, `CONTACT_US`, `DOWNLOAD`, `GET_OFFER`, `GET_QUOTE`, `BUY_NOW`, `ORDER_NOW`, `WATCH_MORE`, `SEND_MESSAGE`, `CALL_NOW`, `GET_STARTED`, `NO_BUTTON`

### Bid strategies

`LOWEST_COST_WITHOUT_CAP`, `LOWEST_COST_WITH_BID_CAP`, `COST_CAP`

### Optimization goals

`OFFSITE_CONVERSIONS`, `LANDING_PAGE_VIEWS`, `LINK_CLICKS`, `IMPRESSIONS`, `REACH`, `LEAD_GENERATION`

### Publisher platforms

`facebook`, `instagram`, `messenger`, `audience_network`, `threads`

### Facebook positions

`feed`, `story`, `facebook_reels`, `right_hand_column`, `search`, `marketplace`, `video_feeds`, `instream_video`

### Instagram positions

`stream`, `story`, `reels`, `explore`, `explore_home`, `profile_feed`, `ig_search`, `profile_reels`

---

## 12. Gotchas and hard-won lessons

1. **Budget values are in cents.** $100.00 = `10000`.
2. **`special_ad_categories` is always required** on campaign creation, even if empty `[]`.
3. **`standard_enhancements` is deprecated** — strip it before sending any creative payload.
4. **Video `image_url` and `image_hash` are mutually exclusive.** Prefer `image_url`; delete `image_hash`.
5. **Video IDs in `asset_feed_spec.videos[]` must be integers**, not strings.
6. **Batch response `body` is a JSON string** — always `JSON.parse()` it.
7. **No `thumbnail_hash` field** in `asset_feed_spec.videos[]` — only `thumbnail_url` works.
8. **Duplicate assets in `images`/`videos` arrays are rejected** — merge `adlabels` onto one entry if the same asset serves multiple placements.
9. **Asset customization rules require at least 2** — Meta rejects the payload with fewer.
10. **Ad account IDs must include `act_` prefix** in all API URLs.
11. **Insights filter `campaign_id` is deprecated** — use `campaign.id` instead.
12. **HEVC video returns HTTP 413** on the `advideos` upload endpoint — re-encode to H.264 (`libx264`, CRF 23) before uploading.
13. **ASC+ campaigns are deprecated in v24.0+** — use `v23.0` and omit `targeting_automation` and `is_adset_budget_sharing_enabled`.
14. **`video_status == "ready"` required** — `processing_phase: complete` alone is not sufficient to create an ad against the video.
