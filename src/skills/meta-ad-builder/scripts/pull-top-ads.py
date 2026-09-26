#!/usr/bin/env python3
"""
Pull ad-level insights from a Meta ad account, rank by ROAS (or spend), and
fetch the winning creative copy for the top N ads. Use the output to inform
new ad copy — feed it to the prompting/copy-guide.md workflow.

Usage:
  python pull-top-ads.py
  python pull-top-ads.py --date-preset last_30d --min-spend 100 --limit 15
  python pull-top-ads.py --sort spend

Required env (set in .env):  META_ACCESS_TOKEN, META_AD_ACCOUNT_ID
Output JSON is written under OUTPUT_BASE (or ./outputs/meta-ads/) — gitignored
because it contains account-specific spend and revenue figures.
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).parent / "lib"))
load_dotenv()

import requests  # noqa: E402
import meta_api  # noqa: E402

INSIGHT_FIELDS = [
    "ad_id", "ad_name", "campaign_name", "adset_name", "spend", "impressions",
    "clicks", "ctr", "cpc", "cpm", "actions", "action_values", "cost_per_action_type",
]


def get_ad_insights(ad_account, token, date_preset):
    url = f"{meta_api.BASE_URL}/{ad_account}/insights"
    params = {
        "access_token": token,
        "level": "ad",
        "fields": ",".join(INSIGHT_FIELDS),
        "date_preset": date_preset,
        "sort": "spend_descending",
        "limit": 100,
        "filtering": json.dumps([
            {"field": "spend", "operator": "GREATER_THAN", "value": "0"}
        ]),
    }
    all_insights = []
    while url:
        resp = requests.get(url, params=params, timeout=60)
        data = resp.json()
        if "error" in data:
            print(f"API Error: {json.dumps(data['error'], indent=2)}")
            return []
        all_insights.extend(data.get("data", []))
        url = data.get("paging", {}).get("next")
        params = None
    return all_insights


def get_ad_creative(ad_id, token):
    url = f"{meta_api.BASE_URL}/{ad_id}"
    params = {
        "access_token": token,
        "fields": "creative{id,name,title,body,object_story_spec,asset_feed_spec}",
    }
    resp = requests.get(url, params=params, timeout=60)
    data = resp.json()
    if "error" in data:
        print(f"  creative fetch error for {ad_id}: {data['error'].get('message')}")
        return None
    return data.get("creative", {})


# Meta reports the same purchase conversion under different action_type names
# depending on pixel / CAPI / app setup. Priority order — omni_purchase is the
# deduplicated roll-up, so take the first match to avoid double-counting.
PURCHASE_ACTIONS = (
    "omni_purchase",
    "offsite_conversion.fb_pixel_purchase",
    "onsite_web_purchase",
    "web_in_store_purchase",
    "purchase",
)


def extract_roas(insight):
    spend = float(insight.get("spend") or 0)
    if spend == 0:
        return 0.0
    values = {
        av.get("action_type"): float(av.get("value", 0))
        for av in insight.get("action_values") or []
    }
    for action in PURCHASE_ACTIONS:
        if action in values:
            return values[action] / spend
    return 0.0


def extract_copy(creative):
    if not creative:
        return {}
    feed = creative.get("asset_feed_spec") or {}
    story = creative.get("object_story_spec") or {}
    bodies = [b.get("text", "") for b in feed.get("bodies", [])]
    titles = [t.get("text", "") for t in feed.get("titles", [])]
    descs = [d.get("text", "") for d in feed.get("descriptions", [])]
    if not bodies:
        ld = story.get("link_data") or story.get("video_data") or {}
        bodies = [ld.get("message", creative.get("body", ""))]
        titles = [ld.get("name", creative.get("title", ""))]
    return {"bodies": bodies, "titles": titles, "descriptions": descs}


def main():
    parser = argparse.ArgumentParser(description="Pull top-performing Meta ads ranked by ROAS.")
    parser.add_argument("--date-preset", default="last_30d")
    parser.add_argument("--min-spend", type=float, default=0,
                        help="Minimum spend to include an ad (USD)")
    parser.add_argument("--limit", type=int, default=10,
                        help="Number of top ads to return")
    parser.add_argument("--sort", choices=["roas", "spend"], default="roas",
                        help="Ranking metric (default: roas)")
    args = parser.parse_args()

    token = meta_api.get_access_token()
    acct = meta_api.get_ad_account_id()

    print(f"Fetching insights for {acct} ({args.date_preset})...")
    insights = get_ad_insights(acct, token, args.date_preset)
    if not insights:
        print("No insights returned.")
        return

    for row in insights:
        row["_roas"] = extract_roas(row)

    filtered = [r for r in insights if float(r.get("spend") or 0) >= args.min_spend]
    sort_key = "_roas" if args.sort == "roas" else "spend"
    ranked = sorted(filtered, key=lambda r: float(r.get(sort_key) or 0), reverse=True)[:args.limit]

    print(f"\nTop {len(ranked)} ads by {args.sort}:")
    results = []
    for i, row in enumerate(ranked, 1):
        ad_id = row["ad_id"]
        spend = float(row.get("spend") or 0)
        roas = row["_roas"]
        print(f"  {i}. {row.get('ad_name', ad_id)} — spend=${spend:.2f} ROAS={roas:.2f}")
        creative = get_ad_creative(ad_id, token)
        copy = extract_copy(creative)
        results.append({
            "rank": i,
            "ad_id": ad_id,
            "ad_name": row.get("ad_name"),
            "campaign_name": row.get("campaign_name"),
            "adset_name": row.get("adset_name"),
            "spend": spend,
            "roas": roas,
            "impressions": row.get("impressions"),
            "ctr": row.get("ctr"),
            "copy": copy,
        })

    run_slug = f"top-ads-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    out_dir = meta_api.resolve_output_dir(run_slug)
    out_file = out_dir / "top_ads.json"
    out_file.write_text(json.dumps(results, indent=2))
    print(f"\nWritten to {out_file}")
    print("Use the 'copy' fields from the top ads to inform your new ad copy (copy-guide.md).")


if __name__ == "__main__":
    main()
