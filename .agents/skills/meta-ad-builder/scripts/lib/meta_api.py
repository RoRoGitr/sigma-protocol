"""
Shared Meta Marketing API helpers for the meta-ad-builder skill.

Handles image/video upload, video-processing polling, and ad creation with
transient-error retry/backoff.

Credentials come from environment (load a .env first with python-dotenv):
  META_ACCESS_TOKEN   (required) — long-lived user/system token, ads_management scope
  META_AD_ACCOUNT_ID  (required) — with or without the act_ prefix
  META_API_VERSION    (optional) — Graph API version, default v23.0
"""

import base64
import json
import os
import time
from pathlib import Path

import requests

API_VERSION = os.getenv("META_API_VERSION", "v23.0")
BASE_URL = f"https://graph.facebook.com/{API_VERSION}"


def get_access_token():
    token = os.getenv("META_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("META_ACCESS_TOKEN not set — see check-meta-env.sh")
    return token


def get_ad_account_id():
    acct = os.getenv("META_AD_ACCOUNT_ID")
    if not acct:
        raise RuntimeError("META_AD_ACCOUNT_ID not set — see check-meta-env.sh")
    return acct if acct.startswith("act_") else f"act_{acct}"


def resolve_output_dir(run_slug):
    """Resolve a per-run output directory.

    Honors OUTPUT_BASE if set; otherwise writes under ./outputs/meta-ads/.
    Both are gitignored so account-specific ad IDs and performance data never
    land in version control.
    """
    base = os.getenv("OUTPUT_BASE")
    root = Path(base) if base else Path("outputs/meta-ads")
    run_dir = root / run_slug
    run_dir.mkdir(parents=True, exist_ok=True)
    return run_dir


def upload_image(path, name=None):
    """Upload an image to /adimages (base64). Returns the image hash."""
    path = Path(path)
    if not path.exists():
        print(f"  ERROR: image not found: {path}")
        return None
    with open(path, "rb") as f:
        img_b64 = base64.b64encode(f.read()).decode("utf-8")
    token = get_access_token()
    acct = get_ad_account_id()
    url = f"{BASE_URL}/{acct}/adimages"
    resp = requests.post(
        url,
        data={"bytes": img_b64, "name": name or path.name, "access_token": token},
        timeout=120,
    )
    data = resp.json()
    images = data.get("images", {})
    entry = images.get(name or path.name) or next(iter(images.values()), None)
    if not entry or "hash" not in entry:
        print(f"  ERROR uploading image: {json.dumps(data, indent=2)}")
        return None
    return entry["hash"]


def upload_video(path):
    """Upload a video to /advideos (multipart). Returns the video ID."""
    path = Path(path)
    if not path.exists():
        print(f"  ERROR: video not found: {path}")
        return None
    token = get_access_token()
    acct = get_ad_account_id()
    url = f"{BASE_URL}/{acct}/advideos"
    with open(path, "rb") as f:
        resp = requests.post(
            url,
            data={"access_token": token, "name": path.name},
            files={"source": (path.name, f, "video/mp4")},
            timeout=600,
        )
    data = resp.json()
    vid_id = data.get("id")
    if not vid_id:
        print(f"  ERROR uploading video: {json.dumps(data, indent=2)}")
        return None
    return vid_id


def wait_for_video(video_id, poll_interval=10, max_wait=600):
    """Poll until the video is ready for use in ads. Returns the preferred thumbnail URL."""
    token = get_access_token()
    url = f"{BASE_URL}/{video_id}"
    params = {
        "access_token": token,
        "fields": "status,thumbnails{uri,is_preferred}",
    }
    deadline = time.time() + max_wait
    while time.time() < deadline:
        resp = requests.get(url, params=params, timeout=30)
        data = resp.json()
        status = data.get("status", {})
        video_status = status.get("video_status", "")
        processing_phase = status.get("processing_phase", {}).get("status", "")
        if video_status == "ready":
            thumbs = data.get("thumbnails", {}).get("data", [])
            preferred = next((t["uri"] for t in thumbs if t.get("is_preferred")), None)
            if not preferred and thumbs:
                preferred = thumbs[0]["uri"]
            return preferred
        if video_status == "error":
            print(f"  ERROR: video {video_id} failed processing: {data}")
            return None
        print(f"  Waiting for video {video_id} — phase={processing_phase} status={video_status}")
        time.sleep(poll_interval)
    print(f"  TIMEOUT: video {video_id} not ready after {max_wait}s")
    return None


def create_ad(adset_id, name, creative, status="PAUSED"):
    """Create an ad in the given ad set. Retries transient errors with backoff.

    Every ad is created PAUSED. Pass status='PAUSED' explicitly — never change
    this default without an explicit user instruction.
    """
    token = get_access_token()
    acct = get_ad_account_id()
    url = f"{BASE_URL}/{acct}/ads"
    payload = {
        "adset_id": adset_id,
        "name": name,
        "status": status,
        "creative": json.dumps(creative),
        "access_token": token,
    }
    backoff = [5, 10, 20, 60]
    for attempt, wait in enumerate([0] + backoff):
        if wait:
            print(f"  Retrying ad creation (attempt {attempt + 1}) in {wait}s...")
            time.sleep(wait)
        resp = requests.post(url, data=payload, timeout=60)
        # Retry transient HTTP-level failures (rate limit / server errors) per the cheatsheet.
        if resp.status_code == 429 or resp.status_code >= 500:
            if attempt < len(backoff):
                print(f"  HTTP {resp.status_code} from Graph API, will retry.")
                continue
            print(f"  ERROR creating ad: HTTP {resp.status_code} after retries: {resp.text[:300]}")
            return None
        try:
            data = resp.json()
        except ValueError:
            print(f"  ERROR creating ad: non-JSON response (HTTP {resp.status_code}): {resp.text[:300]}")
            return None
        if "error" in data:
            err = data["error"]
            if err.get("is_transient") and attempt < len(backoff):
                print(f"  Transient error (code {err.get('code')}), will retry.")
                continue
            print(f"  ERROR creating ad: {json.dumps(err, indent=2)}")
            return None
        return data.get("id")
    return None
