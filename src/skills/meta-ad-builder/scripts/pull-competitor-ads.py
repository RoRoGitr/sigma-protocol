#!/usr/bin/env python3
"""
Pull competitor ads from the Meta Ad Library for research and copy inspiration.

Usage:
  python pull-competitor-ads.py --pages "nike" --limit 50
  python pull-competitor-ads.py --pages "nike,adidas" --country US --days 60

--pages takes page USERNAMES (the handle in facebook.com/<username>) or numeric
page IDs — NOT free-text brand search. An input that isn't an exact page username
or ID resolves to nothing and is skipped with a warning.

Required env:  META_ACCESS_TOKEN
Output JSON is written under OUTPUT_BASE (or ./outputs/meta-ads/) — gitignored.

NOTE: The Ad Library API returns ad_snapshot_url and copy text but NOT
impression/spend data for US commercial ads (only political/issue ads return
those metrics). Use for creative copy and format research, not performance data.
"""

import argparse
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path

import requests
from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).parent / "lib"))
load_dotenv()

import meta_api  # noqa: E402

AD_ARCHIVE_URL = f"https://graph.facebook.com/{meta_api.API_VERSION}/ads_archive"


def resolve_page_id(page_name, token):
    """Resolve a page vanity name to its numeric page ID."""
    url = f"https://graph.facebook.com/{meta_api.API_VERSION}/{page_name}"
    resp = requests.get(url, params={"fields": "id", "access_token": token}, timeout=30)
    data = resp.json()
    return data.get("id")


def pull_ads(page_ids, token, country, days, limit, media_type):
    end = datetime.utcnow()
    start = end - timedelta(days=days)
    params = {
        "access_token": token,
        "ad_reached_countries": country,
        "search_page_ids": ",".join(page_ids),
        "ad_delivery_date_min": start.strftime("%Y-%m-%d"),
        "ad_delivery_date_max": end.strftime("%Y-%m-%d"),
        "ad_active_status": "ALL",
        "sort_by": "impressions_high_to_low",
        "media_type": media_type,
        "fields": "id,page_name,ad_creative_bodies,publisher_platforms,ad_snapshot_url,ad_delivery_start_time",
        "limit": min(limit, 100),
    }
    all_ads = []
    url = AD_ARCHIVE_URL
    while url and len(all_ads) < limit:
        resp = requests.get(url, params=params, timeout=60)
        data = resp.json()
        if "error" in data:
            print(f"Ad Library error: {json.dumps(data['error'], indent=2)}")
            break
        all_ads.extend(data.get("data", []))
        url = data.get("paging", {}).get("next")
        params = None
    return all_ads[:limit]


def main():
    parser = argparse.ArgumentParser(description="Pull competitor ads from the Meta Ad Library.")
    parser.add_argument("--pages", required=True,
                        help="Comma-separated page usernames (facebook.com/<handle>) or numeric "
                             "page IDs, max 10 — not free-text brand search")
    parser.add_argument("--country", default="US")
    parser.add_argument("--days", type=int, default=30,
                        help="Look-back window in days")
    parser.add_argument("--limit", type=int, default=50)
    parser.add_argument("--media-type", default="all",
                        choices=["all", "video", "image"])
    args = parser.parse_args()

    token = meta_api.get_access_token()
    page_names = [p.strip() for p in args.pages.split(",")]

    print("Resolving page IDs...")
    page_ids = []
    for name in page_names:
        if name.isdigit():
            page_ids.append(name)
        else:
            pid = resolve_page_id(name, token)
            if pid:
                print(f"  {name} → {pid}")
                page_ids.append(pid)
            else:
                print(f"  WARNING: could not resolve page ID for '{name}'")

    if not page_ids:
        print("No valid page IDs — aborting.")
        return

    print(f"\nFetching up to {args.limit} ads for page IDs: {', '.join(page_ids)}...")
    ads = pull_ads(page_ids, token, args.country, args.days, args.limit, args.media_type)
    print(f"Retrieved {len(ads)} ads.")

    run_slug = f"competitor-ads-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    out_dir = meta_api.resolve_output_dir(run_slug)
    out_file = out_dir / "competitor_ads.json"
    out_file.write_text(json.dumps(ads, indent=2))
    print(f"\nWritten to {out_file}")
    print("Review 'ad_creative_bodies' and 'ad_snapshot_url' to analyze competitor creative formats.")


if __name__ == "__main__":
    main()
