---
name: manychat-api-operations
description: "Manage ManyChat subscribers, tags, custom fields, and flow triggers via the REST API -- complete endpoint reference and integration patterns"
triggers:
  - manychat-api
  - subscriber-management
  - manychat-sync
  - lead-sync
---

# ManyChat API Operations Skill

Complete reference for managing ManyChat programmatically. Covers subscriber lifecycle, tagging, custom fields, flow triggering, and cross-platform integration patterns.

## When to Invoke

- Managing ManyChat subscribers via API (create, find, tag, update)
- Syncing leads from external sources (Discord, landing pages, CRM)
- Triggering pre-built flows for specific subscribers
- Setting custom fields for dynamic content personalization
- Building integration scripts between ManyChat and other systems

---

## API Reference

**Base URL:** `https://api.manychat.com`
**Auth:** `Authorization: Bearer {page_id}:{token}`
**Content-Type:** `application/json` (for POST requests)

### Page Management

| Method | Endpoint | Rate | Description |
|--------|----------|------|-------------|
| GET | `/fb/page/getInfo` | 100/s | Get connected page info |
| GET | `/fb/page/getTags` | 100/s | List all tags |
| POST | `/fb/page/createTag` | 10/s | Create tag (`name`) |
| POST | `/fb/page/removeTag` | 10/s | Delete tag (`tag_id`) |
| POST | `/fb/page/removeTagByName` | 10/s | Delete tag (`tag_name`) |
| GET | `/fb/page/getCustomFields` | 100/s | List custom fields |
| POST | `/fb/page/createCustomField` | 10/s | Create field (`caption`, `type`) |
| GET | `/fb/page/getBotFields` | 100/s | List bot-level fields |
| POST | `/fb/page/createBotField` | 10/s | Create bot field (`name`, `type`) |
| POST | `/fb/page/setBotField` | 10/s | Set bot field value (`field_id`, `field_value`) |
| POST | `/fb/page/setBotFieldByName` | 10/s | Set bot field by name (`field_name`, `field_value`) |
| POST | `/fb/page/setBotFields` | 10/s | Set multiple bot fields (max 20) |
| GET | `/fb/page/getFlows` | 10/s | List all flows/automations |
| GET | `/fb/page/getGrowthTools` | 100/s | List growth tools |
| GET | `/fb/page/getOtnTopics` | 100/s | Get one-time notification topics |

### Subscriber Management

| Method | Endpoint | Rate | Description |
|--------|----------|------|-------------|
| GET | `/fb/subscriber/getInfo` | 10/s | Get subscriber details (`subscriber_id`) |
| GET | `/fb/subscriber/findByName` | 10/s | Search by name (`name`, max 100) |
| GET | `/fb/subscriber/findBySystemField` | 50/s | Find by email or phone (`email` or `phone`) |
| GET | `/fb/subscriber/findByCustomField` | 10/s | Find by custom field (`field_id`, `field_value`) |
| GET | `/fb/subscriber/getInfoByUserRef` | - | Get by user reference (`user_ref`) |
| POST | `/fb/subscriber/createSubscriber` | 10/s | Create new subscriber |
| POST | `/fb/subscriber/updateSubscriber` | 10/s | Update subscriber (`subscriber_id`) |
| POST | `/fb/subscriber/addTag` | 10/s | Add tag (`subscriber_id`, `tag_id`) |
| POST | `/fb/subscriber/addTagByName` | 10/s | Add tag by name (`subscriber_id`, `tag_name`) |
| POST | `/fb/subscriber/removeTag` | 10/s | Remove tag (`subscriber_id`, `tag_id`) |
| POST | `/fb/subscriber/removeTagByName` | 10/s | Remove tag by name (`subscriber_id`, `tag_name`) |
| POST | `/fb/subscriber/setCustomField` | 10/s | Set field (`subscriber_id`, `field_id`, `field_value`) |
| POST | `/fb/subscriber/setCustomFieldByName` | 10/s | Set field by name (`subscriber_id`, `field_name`, `field_value`) |
| POST | `/fb/subscriber/setCustomFields` | 10/s | Set multiple fields (max 20) |
| POST | `/fb/subscriber/verifyBySignedRequest` | 10/s | Verify via signed request |

### Sending

| Method | Endpoint | Rate | Description |
|--------|----------|------|-------------|
| POST | `/fb/sending/sendContent` | 25/s | Send content to subscriber (`subscriber_id`, `data`) |
| POST | `/fb/sending/sendContentByUserRef` | 25/s | Send by user ref (`user_ref`, `data`) |
| POST | `/fb/sending/sendFlow` | 20/s | Trigger flow (`subscriber_id`, `flow_ns`) |

---

## Python Client Pattern

Standard pattern for all ManyChat API scripts:

```python
"""ManyChat API client."""

from __future__ import annotations

import os
from typing import Any

import httpx
from dotenv import load_dotenv

load_dotenv()

API = "https://api.manychat.com"
TOKEN = os.getenv("MANYCHAT_API_KEY", "")


def _headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json",
    }


def _get(path: str, params: dict | None = None) -> dict[str, Any]:
    r = httpx.get(f"{API}{path}", headers=_headers(), params=params)
    r.raise_for_status()
    return r.json()


def _post(path: str, data: dict[str, Any]) -> dict[str, Any]:
    r = httpx.post(f"{API}{path}", headers=_headers(), json=data)
    r.raise_for_status()
    return r.json()
```

---

## Common Operations

### Find a Subscriber

```python
# By email
result = _get("/fb/subscriber/findBySystemField", {"email": "user@example.com"})
subscriber = result["data"]

# By phone
result = _get("/fb/subscriber/findBySystemField", {"phone": "+15551234567"})

# By name (returns up to 100 matches)
result = _get("/fb/subscriber/findByName", {"name": "Jane"})
subscribers = result["data"]

# By custom field
result = _get("/fb/subscriber/findByCustomField", {
    "field_id": 12345,
    "field_value": "yourbrand"
})
```

### Create a Subscriber

```python
result = _post("/fb/subscriber/createSubscriber", {
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+15551234567",
    "email": "john@example.com",
    "has_opt_in_sms": True,
    "has_opt_in_email": True,
    "consent_phrase": "Opted in via landing page",
})
subscriber_id = result["data"]["id"]
```

### Tag a Subscriber

```python
# By tag name (easier -- no need to look up tag ID)
_post("/fb/subscriber/addTagByName", {
    "subscriber_id": subscriber_id,
    "tag_name": "brand:academy",
})

# Remove tag
_post("/fb/subscriber/removeTagByName", {
    "subscriber_id": subscriber_id,
    "tag_name": "stage:cold",
})
```

### Set Custom Fields

```python
# Single field
_post("/fb/subscriber/setCustomFieldByName", {
    "subscriber_id": subscriber_id,
    "field_name": "subscriber_type",
    "field_value": "developer",
})

# Multiple fields (max 20 per call)
_post("/fb/subscriber/setCustomFields", {
    "subscriber_id": subscriber_id,
    "fields": [
        {"field_name": "company", "field_value": "Academy"},
        {"field_name": "source", "field_value": "discord"},
        {"field_name": "joined_at", "field_value": "2026-02-12T00:00:00+00:00"},
    ],
})
```

### Trigger a Flow

```python
# Get available flows first
flows = _get("/fb/page/getFlows")
# Find the flow namespace (flow_ns) from the response

# Trigger it for a subscriber
_post("/fb/sending/sendFlow", {
    "subscriber_id": subscriber_id,
    "flow_ns": "content20250212_abc123",  # From getFlows response
})
```

### Send Content Directly

```python
# Send a text message
_post("/fb/sending/sendContent", {
    "subscriber_id": subscriber_id,
    "data": {
        "version": "v2",
        "content": {
            "messages": [
                {
                    "type": "text",
                    "text": "Hey! Your Academy access is now active 🎉",
                }
            ],
        },
    },
    "message_tag": "CONFIRMED_EVENT_UPDATE",  # Required outside 24h window
})
```

---

## Integration Patterns

### Discord → ManyChat Lead Sync

When a new member joins the Discord server, create/tag them in ManyChat:

```python
async def sync_discord_member_to_manychat(
    email: str,
    discord_name: str,
    guild_name: str,
    interest_roles: list[str],
):
    """Sync a Discord member to ManyChat as a subscriber."""
    # Check if subscriber exists
    result = _get("/fb/subscriber/findBySystemField", {"email": email})

    if result.get("data"):
        subscriber_id = result["data"][0]["id"]
    else:
        # Create new subscriber
        result = _post("/fb/subscriber/createSubscriber", {
            "first_name": discord_name,
            "email": email,
            "has_opt_in_email": True,
            "consent_phrase": f"Joined {guild_name} Discord server",
        })
        subscriber_id = result["data"]["id"]

    # Tag with brand
    brand_tag = "brand:yourbrand" if guild_name == "yourbrand" else "brand:academy"
    _post("/fb/subscriber/addTagByName", {
        "subscriber_id": subscriber_id,
        "tag_name": brand_tag,
    })

    # Tag with source
    _post("/fb/subscriber/addTagByName", {
        "subscriber_id": subscriber_id,
        "tag_name": "source:discord",
    })

    # Set interest roles as custom fields
    for role in interest_roles:
        _post("/fb/subscriber/addTagByName", {
            "subscriber_id": subscriber_id,
            "tag_name": f"interest:{role.lower()}",
        })
```

### Landing Page → ManyChat

When someone submits a form on a landing page:

```python
def handle_landing_page_submission(
    email: str,
    name: str,
    lead_magnet: str,
    source_url: str,
):
    """Create subscriber and trigger lead magnet delivery flow."""
    result = _post("/fb/subscriber/createSubscriber", {
        "first_name": name.split()[0],
        "last_name": " ".join(name.split()[1:]) or "",
        "email": email,
        "has_opt_in_email": True,
        "consent_phrase": f"Downloaded {lead_magnet} from {source_url}",
    })
    subscriber_id = result["data"]["id"]

    # Tag and set context
    _post("/fb/subscriber/addTagByName", {
        "subscriber_id": subscriber_id,
        "tag_name": "source:landing-page",
    })
    _post("/fb/subscriber/setCustomFieldByName", {
        "subscriber_id": subscriber_id,
        "field_name": "lead_magnet",
        "field_value": lead_magnet,
    })

    # Trigger delivery flow
    _post("/fb/sending/sendFlow", {
        "subscriber_id": subscriber_id,
        "flow_ns": "lead_magnet_delivery_flow_ns",
    })
```

### Bulk Segment Operations

Tag all subscribers matching a condition:

```python
def bulk_tag_by_field(
    field_name: str,
    field_value: str,
    tag_name: str,
):
    """Find all subscribers with a field value and apply a tag."""
    # First, get the field ID
    fields = _get("/fb/page/getCustomFields")
    field_id = next(
        f["id"] for f in fields["data"]
        if f["name"] == field_name
    )

    # Find matching subscribers
    result = _get("/fb/subscriber/findByCustomField", {
        "field_id": field_id,
        "field_value": field_value,
    })

    tagged = 0
    for sub in result.get("data", []):
        _post("/fb/subscriber/addTagByName", {
            "subscriber_id": sub["id"],
            "tag_name": tag_name,
        })
        tagged += 1

    return tagged
```

---

## Custom Field Types

| Type | Format | Example |
|------|--------|---------|
| `text` | String | `"developer"` |
| `number` | Integer/float | `42` |
| `date` | `YYYY-MM-DD` | `"2026-02-12"` |
| `datetime` | ISO 8601 | `"2026-02-12T14:30:00+00:00"` |
| `boolean` | `true`/`false` | `true` |

---

## Recommended Custom Fields Setup

Create these fields for multi-brand management:

| Field Name | Type | Purpose |
|------------|------|---------|
| `source` | text | How they entered (discord, landing-page, instagram, tiktok) |
| `company` | text | Which brand they engaged with |
| `subscriber_type` | text | Segment (developer, trader, entrepreneur) |
| `lead_magnet` | text | Which lead magnet they downloaded |
| `discord_id` | text | Their Discord user ID (for cross-platform sync) |
| `discord_guild` | text | Which Discord server they're in |
| `funnel_stage` | text | Current stage (lead, engaged, customer, cold) |
| `last_engaged` | datetime | Last meaningful interaction |

---

## Rate Limit Strategy

Most endpoints are 10 req/sec. For bulk operations:

```python
import time

def bulk_operation(items: list, operation_fn, rate_limit: float = 0.12):
    """Execute bulk operations respecting rate limits."""
    results = []
    for item in items:
        result = operation_fn(item)
        results.append(result)
        time.sleep(rate_limit)  # ~8 req/sec to stay under 10/s limit
    return results
```

---

## Error Handling

```python
def safe_api_call(method: str, path: str, **kwargs) -> dict | None:
    """API call with error handling."""
    try:
        if method == "GET":
            return _get(path, **kwargs)
        return _post(path, **kwargs)
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 429:
            # Rate limited -- wait and retry
            time.sleep(1)
            return safe_api_call(method, path, **kwargs)
        elif e.response.status_code == 401:
            raise ValueError("Invalid MANYCHAT_API_KEY -- check your token")
        else:
            raise
```

---

## API Limitations Reminder

**Cannot do via API:**
- Create or edit flows/automations
- Modify flow steps, messages, or conditions
- Set up triggers (comment keywords, story replies)
- Configure growth tools
- Access analytics or reporting data

**Must use ManyChat UI for these tasks.** Design flow blueprints with the `manychat-funnel-strategy` skill, then build them manually in the visual editor.
