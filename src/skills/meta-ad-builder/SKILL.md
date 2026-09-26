---
name: meta-ad-builder
description: >-
  Publish finished creatives as live Meta (Facebook/Instagram) ads via the Meta
  Marketing API. Uploads an image or video, builds a multi-variant TEXT_LIQUIDITY
  creative, and creates a PAUSED ad in an existing ad set. Also pulls
  top-performing ads (ranked by ROAS) and competitor ads from the Ad Library to
  inform copy. Use when the user asks to deploy, publish, or launch a creative as
  a Meta or Facebook ad, push a video or image into an ad set, pull their top ads,
  or research competitor ads. Not for generating creative (use ad-creative-generation)
  and not for writing ad copy in isolation.
---

Turn a finished creative — typically the output of `ad-creative-generation` — into a live Meta ad. The skill covers three phases: **research** (optional) → **copy** → **deploy**. It interacts with the Meta Marketing API directly via the bundled Python scripts.

## When to use this skill

Trigger on phrases like:

- "deploy this video to Meta" / "publish this as a Facebook ad"
- "build/launch a Meta ad" / "push this creative into [ad set]"
- "create a Meta ad with this image and copy"
- "pull my top-performing ads" / "what are my best ads by ROAS"
- "research competitor ads" / "pull [brand]'s ads from the Ad Library"

Do not use this skill to *generate* creative — that is `ad-creative-generation`. This skill is the Meta Marketing API deployment step only.

## Prerequisites

Set these in `.env` (see `.env.example` in this skill's `scripts/` directory):

- `META_ACCESS_TOKEN` (required) — long-lived token with `ads_management` scope
- `META_AD_ACCOUNT_ID` (required) — with or without the `act_` prefix (e.g. `act_<YOUR_AD_ACCOUNT_ID>`)
- `META_PAGE_ID`, `META_IG_USER_ID`, `META_PIXEL_ID` — optional; used as defaults in `deploy-ad.py`
- `META_API_VERSION` — optional, defaults to `v23.0`

Run `bash scripts/check-meta-env.sh` to verify credentials before any deploy.

**Python dependencies:** `python3 -m pip install -r scripts/requirements.txt` (`requests`, `python-dotenv`).

**Target ad set:** The skill deploys ads into an *existing* ad set — it does not create campaigns or ad sets. Create the ad set in Ads Manager first.

**Creative on disk:** The creative must be a real file path on disk. Chat-pasted images cannot be passed to the API — ask the user for a path.

## Workflow

### Phase 1 — Research (optional)

Run when copy should model the account's proven winners or competitor ads.

```bash
# Rank the account's ads by ROAS and fetch the winning creative copy
python scripts/pull-top-ads.py --date-preset last_30d --min-spend 100 --limit 15

# Pull a competitor's ads from the Meta Ad Library
python scripts/pull-competitor-ads.py --pages "nike" --limit 50   # page username or numeric ID, not free-text brand search
```

Both write JSON under `OUTPUT_BASE` (or `./outputs/meta-ads/` — gitignored via the bundled `scripts/.gitignore`). Read the top-ad `copy` fields to identify winning hook/proof/CTA patterns before writing new copy.

### Phase 2 — Copy

Write a `copy.json` following **[prompting/copy-guide.md](prompting/copy-guide.md)**. The proven shape: 5 bodies, 5 titles, 3 descriptions. Meta mixes and matches them per impression via `TEXT_LIQUIDITY`. If Phase 1 ran, mirror the voice and patterns of the winners — new creative + proven copy DNA is the goal.

Save `copy.json` under `outputs/` so it is not committed (the `outputs/` directory must be in `.gitignore`).

### Phase 3 — Deploy

**Always dry-run first** — prints the full creative payload, makes no API calls:

```bash
python scripts/deploy-ad.py --dry-run \
  --adset-id <AD_SET_ID> --copy-file copy.json --link <DESTINATION_URL> \
  --image path/to/creative.png
```

Review the payload with the user, confirm the target ad set and destination URL, then deploy:

```bash
python scripts/deploy-ad.py \
  --adset-id <AD_SET_ID> --copy-file copy.json --link <DESTINATION_URL> \
  --video clip-a.mp4 --video clip-b.mp4 --cta SIGN_UP --pixel-id <PIXEL_ID>
```

- `--image` / `--video` are repeatable — each becomes its own ad in the ad set.
- Every ad is created **PAUSED**. Tell the user to review and un-pause in Meta Ads Manager. This skill never launches a spending ad automatically.
- Results (ad IDs) are written to `deployment_results.json` under `OUTPUT_BASE`.

## Decision tree

| User intent | Phases |
|---|---|
| "Deploy this creative to Meta" + copy provided | Phase 3 only |
| "Build a Meta ad, write the copy too" | Phase 2 → 3 |
| "Make ads modeled on my winners" | Phase 1 → 2 → 3 |
| "What are my best ads / competitor research" | Phase 1 only |

## Safety rules — money-adjacent, human-gated

This skill is the interface between AI-generated creative and live ad spend. Apply these rules without exception.

- **Ads deploy PAUSED.** Never add an `--active` override or un-pause ads without an explicit, direct user instruction. Always confirm the user knows the ads are paused after deployment.
- **Dry-run before every real deploy.** Show the full creative payload and get an explicit go-ahead before firing the live deploy.
- **Confirm ad set and destination URL** with the user before deploying — an ad in the wrong ad set spends against the wrong budget.
- **The live `deploy-ad.py` run is a confirmation action, not an assumption.** Treat it as a one-way door.
- **This skill creates ads only.** It does not create or edit campaigns, ad sets, budgets, or audiences. Those actions stay manual (in Ads Manager or via the cheatsheet in `reference/meta-api-cheatsheet.md`).

## Quirks and pitfalls

- **Video processing is async.** `deploy-ad.py` polls the uploaded video until Meta finishes processing before creating the ad — a video deploy can take several minutes. See `reference/deploy-patterns.md`.
- **Transient `OAuthException` (code 2).** Retried automatically with exponential backoff (5s → 10s → 20s, capped at 60s).
- **`act_` prefix** is added automatically by the script if missing from `META_AD_ACCOUNT_ID`.
- **Account-specific data stays out of git.** All output routes through `outputs/` (gitignored): ad IDs, pulled spend/revenue, competitor data, `copy.json`.
- **Special Ad Categories** (credit, employment, housing, social issues) change ad-set targeting rules — flag to the user; see `reference/meta-api-cheatsheet.md` §3.4.
- **Video `image_url` and `image_hash` are mutually exclusive.** The script handles this — do not pass both.
- **`standard_enhancements` is deprecated** and will cause error subcode `3858504` if included in a creative payload. The script strips it automatically.
- **API version:** default `v23.0`. Bump `META_API_VERSION` if Meta requires a newer version for a specific feature.

## Cost note

The Meta Marketing API is free to call. **Ad spend is real money** — but because every ad deploys PAUSED, nothing spends until the user un-pauses it in Ads Manager.

## File locations

| File | Purpose |
|---|---|
| `src/skills/meta-ad-builder/SKILL.md` | This file |
| `src/skills/meta-ad-builder/prompting/copy-guide.md` | 5-body / 5-title / 3-description copy frameworks |
| `src/skills/meta-ad-builder/reference/deploy-patterns.md` | Creative spec mechanics, video polling, retry, failure modes |
| `src/skills/meta-ad-builder/reference/meta-api-cheatsheet.md` | Full Meta Marketing API reference (campaigns, ad sets, ads, enums, gotchas, Ad Library) |
| `src/skills/meta-ad-builder/scripts/deploy-ad.py` | Deploy finished creatives as paused Meta ads |
| `src/skills/meta-ad-builder/scripts/pull-top-ads.py` | Rank account ads by ROAS; fetch winning copy |
| `src/skills/meta-ad-builder/scripts/pull-competitor-ads.py` | Pull competitor ads from the Meta Ad Library |
| `src/skills/meta-ad-builder/scripts/lib/meta_api.py` | Shared Meta API helpers (upload, poll, create ad, retry) |
| `src/skills/meta-ad-builder/scripts/check-meta-env.sh` | Verify credentials before any deploy |
| `src/skills/meta-ad-builder/scripts/requirements.txt` | Python dependencies (`requests`, `python-dotenv`) |

## Quality gates

- [ ] Credentials verified via `check-meta-env.sh` before any deploy.
- [ ] Target ad set confirmed with the user (ad set ID + budget owner).
- [ ] Destination URL confirmed with the user.
- [ ] `copy.json` reviewed against `prompting/copy-guide.md` — 5 bodies, 5 titles, 3 descriptions.
- [ ] Dry-run output reviewed and user approved before live deploy.
- [ ] Live deploy confirmed: all ads reported as PAUSED in the output.
- [ ] `deployment_results.json` reviewed — user instructed to un-pause manually in Ads Manager.
- [ ] Special Ad Category flag checked if the offer touches credit, employment, housing, or political issues.
