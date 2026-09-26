#!/usr/bin/env python3
"""
Deploy finished creatives as Meta ads.

Each --image / --video becomes one ad in the target ad set, using a
multi-variant asset_feed_spec (TEXT_LIQUIDITY) so Meta rotates the supplied
body / title / description copy. Every ad is created PAUSED — review and
un-pause in Ads Manager.

Usage:
  python deploy-ad.py --adset-id <AD_SET_ID> --copy-file copy.json \\
      --link https://example.com --image creative.png

  python deploy-ad.py --adset-id <AD_SET_ID> --copy-file copy.json \\
      --link https://example.com --video a.mp4 --video b.mp4 --cta SIGN_UP

  python deploy-ad.py --dry-run --adset-id <AD_SET_ID> --copy-file copy.json \\
      --link https://example.com --image creative.png

copy-file JSON shape (titles/descriptions may be plain strings or {"text": ...}):
  { "bodies": ["..."], "titles": ["..."], "descriptions": ["..."] }

Required env (set in .env):  META_ACCESS_TOKEN, META_AD_ACCOUNT_ID
Optional env:  META_PAGE_ID, META_IG_USER_ID, META_PIXEL_ID, META_API_VERSION
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).parent / "lib"))
load_dotenv()

import meta_api  # noqa: E402

# Advantage+ creative enhancements enrollment map.
CREATIVE_FEATURES_SPEC_BASE = {
    "advantage_plus_creative": {"enroll_status": "OPT_IN"},
    "creative_stickers": {"enroll_status": "OPT_IN"},
    "enhance_cta": {
        "enroll_status": "OPT_IN",
        "customizations": {"text_extraction": {"enroll_status": "OPT_IN"}},
    },
    "generate_cta": {"enroll_status": "OPT_IN"},
    "inline_comment": {"enroll_status": "OPT_IN"},
    "product_extensions": {
        "enroll_status": "OPT_OUT",
        "customizations": {"pe_carousel": {"enroll_status": "OPT_OUT"}},
    },
    "reveal_details_over_time": {"enroll_status": "OPT_IN"},
    "show_destination_blurbs": {"enroll_status": "OPT_IN"},
    "show_summary": {"enroll_status": "OPT_IN"},
    "site_extensions": {"enroll_status": "OPT_OUT"},
    "text_optimizations": {
        "enroll_status": "OPT_IN",
        "customizations": {"text_extraction": {"enroll_status": "OPT_IN"}},
    },
    "text_translation": {"enroll_status": "OPT_IN"},
}

CREATIVE_FEATURES_SPEC_VIDEO = {
    **CREATIVE_FEATURES_SPEC_BASE,
    "video_auto_crop": {"enroll_status": "OPT_IN"},
    "video_filtering": {"enroll_status": "OPT_IN"},
    "video_uncrop": {"enroll_status": "OPT_IN"},
}


def load_copy(copy_path):
    """Read the copy JSON and normalize titles/descriptions to {"text": ...}."""
    with open(copy_path) as f:
        data = json.load(f)
    bodies = data.get("bodies") or []
    if not bodies:
        raise SystemExit(f"copy-file {copy_path} has no 'bodies'")

    def as_text_objs(items):
        return [it if isinstance(it, dict) else {"text": str(it)} for it in (items or [])]

    return {
        "bodies": [{"text": b} for b in bodies],
        "titles": as_text_objs(data.get("titles")),
        "descriptions": as_text_objs(data.get("descriptions")),
    }


def build_creative(copy, cta, page_id, ig_user_id, link, pixel_id,
                   image_hash=None, video_id=None, thumbnail_url=None):
    """Build a multi-variant TEXT_LIQUIDITY creative payload."""
    is_video = video_id is not None
    features = CREATIVE_FEATURES_SPEC_VIDEO if is_video else CREATIVE_FEATURES_SPEC_BASE

    asset_feed = {
        "optimization_type": "DEGREES_OF_FREEDOM",
        "bodies": copy["bodies"],
        "titles": copy["titles"],
        "descriptions": copy["descriptions"],
        "call_to_action_types": [cta],
    }
    if not is_video:
        asset_feed["link_urls"] = [{"website_url": link, "display_url": link}]

    if is_video:
        story_asset = {
            "video_id": video_id,
            "image_url": thumbnail_url,
            "call_to_action": {"type": cta, "value": {"link": link}},
        }
        story_spec = {"video_data": story_asset}
    else:
        story_asset = {
            "image_hash": image_hash,
            "link": link,
            "call_to_action": {"type": cta, "value": {"link": link}},
        }
        story_spec = {"link_data": story_asset}

    story_spec["page_id"] = page_id
    if ig_user_id:
        story_spec["instagram_user_id"] = ig_user_id

    creative = {
        "object_story_spec": story_spec,
        "asset_feed_spec": asset_feed,
        "degrees_of_freedom_spec": {
            "degrees_of_freedom_type": "USER_ENROLLED",
            "text_transformation_types": ["TEXT_LIQUIDITY"],
            "creative_features_spec": features,
        },
        "contextual_multi_ads": {"enroll_status": "OPT_OUT"},
    }

    tracking = []
    if pixel_id:
        tracking.append({"action.type": ["offsite_conversion"], "fb_pixel": [pixel_id]})

    return creative, tracking


def main():
    parser = argparse.ArgumentParser(description="Deploy creatives as PAUSED Meta ads.")
    parser.add_argument("--adset-id", required=True)
    parser.add_argument("--copy-file", required=True)
    parser.add_argument("--link", required=True, help="Destination URL for all ads")
    parser.add_argument("--image", action="append", default=[], metavar="PATH",
                        help="Image creative (repeatable — one ad per image)")
    parser.add_argument("--video", action="append", default=[], metavar="PATH",
                        help="Video creative (repeatable — one ad per video)")
    parser.add_argument("--cta", default="LEARN_MORE",
                        help="CTA type (default: LEARN_MORE)")
    parser.add_argument("--page-id", default=os.getenv("META_PAGE_ID"))
    parser.add_argument("--ig-user-id", default=os.getenv("META_IG_USER_ID"))
    parser.add_argument("--pixel-id", default=os.getenv("META_PIXEL_ID"))
    parser.add_argument("--dry-run", action="store_true",
                        help="Print the creative payload without making API calls")
    args = parser.parse_args()

    if not args.page_id:
        raise SystemExit("ERROR: --page-id or META_PAGE_ID required")
    if not args.image and not args.video:
        raise SystemExit("ERROR: provide at least one --image or --video")

    copy = load_copy(args.copy_file)
    results = []
    run_slug = f"deploy-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

    for img_path in args.image:
        print(f"\n[IMAGE] {img_path}")
        if args.dry_run:
            print(f"  DRY RUN — would upload image and create PAUSED ad in adset {args.adset_id}")
            creative, tracking = build_creative(
                copy, args.cta, args.page_id, args.ig_user_id, args.link,
                args.pixel_id, image_hash="<DRY_RUN_HASH>",
            )
            # Build the EXACT payload the live path sends so the dry-run is a true preview.
            if tracking:
                creative["tracking_specs"] = tracking
            print(json.dumps(
                {"adset_id": args.adset_id, "status": "PAUSED", "creative": creative},
                indent=2,
            ))
            continue

        img_hash = meta_api.upload_image(img_path)
        if not img_hash:
            print("  SKIPPED — upload failed.")
            continue

        creative, tracking = build_creative(
            copy, args.cta, args.page_id, args.ig_user_id, args.link,
            args.pixel_id, image_hash=img_hash,
        )
        if tracking:
            creative["tracking_specs"] = tracking

        ad_name = f"img-ad-{Path(img_path).stem}-{run_slug}"
        ad_id = meta_api.create_ad(args.adset_id, ad_name, creative)
        if ad_id:
            print(f"  Created PAUSED ad: {ad_id}")
            results.append({"type": "image", "path": img_path, "ad_id": ad_id, "status": "PAUSED"})
        else:
            print("  FAILED — see error above.")

    for vid_path in args.video:
        print(f"\n[VIDEO] {vid_path}")
        if args.dry_run:
            print(f"  DRY RUN — would upload video and create PAUSED ad in adset {args.adset_id}")
            creative, tracking = build_creative(
                copy, args.cta, args.page_id, args.ig_user_id, args.link,
                args.pixel_id, video_id="<DRY_RUN_VIDEO_ID>", thumbnail_url="<DRY_RUN_THUMB>",
            )
            # Build the EXACT payload the live path sends so the dry-run is a true preview.
            if tracking:
                creative["tracking_specs"] = tracking
            print(json.dumps(
                {"adset_id": args.adset_id, "status": "PAUSED", "creative": creative},
                indent=2,
            ))
            continue

        vid_id = meta_api.upload_video(vid_path)
        if not vid_id:
            print("  SKIPPED — video upload failed.")
            continue

        print(f"  Waiting for video {vid_id} to finish processing...")
        thumbnail_url = meta_api.wait_for_video(vid_id)
        if not thumbnail_url:
            print("  SKIPPED — video did not reach ready state.")
            continue

        creative, tracking = build_creative(
            copy, args.cta, args.page_id, args.ig_user_id, args.link,
            args.pixel_id, video_id=vid_id, thumbnail_url=thumbnail_url,
        )
        if tracking:
            creative["tracking_specs"] = tracking

        ad_name = f"vid-ad-{Path(vid_path).stem}-{run_slug}"
        ad_id = meta_api.create_ad(args.adset_id, ad_name, creative)
        if ad_id:
            print(f"  Created PAUSED ad: {ad_id}")
            results.append({"type": "video", "path": vid_path, "ad_id": ad_id, "status": "PAUSED"})
        else:
            print("  FAILED — see error above.")

    if results and not args.dry_run:
        out_dir = meta_api.resolve_output_dir(run_slug)
        results_file = out_dir / "deployment_results.json"
        results_file.write_text(json.dumps(results, indent=2))
        print(f"\nResults written to {results_file}")
        print(f"\nAll {len(results)} ad(s) created PAUSED. Review and un-pause in Meta Ads Manager.")


if __name__ == "__main__":
    main()
