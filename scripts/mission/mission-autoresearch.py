#!/usr/bin/env python3
"""
mission-autoresearch.py — Per-mission Exa-powered research agent.

Invoked at the end of a brain-autoresearch workflow. Respects the compile-lock at
/tmp/claude-brain-compile.lock.d (mkdir-based atomic lock, macOS-portable).

Usage:
  mission-autoresearch.py                     # scan all active missions, run those > 24h stale
  mission-autoresearch.py --mission {slug}    # research one specific mission, ignore cadence
  mission-autoresearch.py --dry-run           # print what would be researched, no API calls
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SIGMAHQ_HOME = Path(os.environ.get("SIGMAHQ_HOME", os.environ.get("CLAUDE_CODE_COMMANDBOARD", str(Path.home() / ".commandboard")))).expanduser()
MISSIONS_DIR = SIGMAHQ_HOME / "missions"
COMPILE_LOCK = Path("/tmp/claude-brain-compile.lock.d")

MAX_KEYWORDS_PER_DAY = 3
MAX_RESULTS_PER_KEYWORD = 5
DEFAULT_RELEVANCE_THRESHOLD = 0.6
RETRY_DELAY_SECONDS = 5

# ---------------------------------------------------------------------------
# Logging — stderr, structured
# ---------------------------------------------------------------------------

logging.basicConfig(
    stream=sys.stderr,
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
log = logging.getLogger("mission-autoresearch")


# ---------------------------------------------------------------------------
# Compile-lock
# ---------------------------------------------------------------------------

def acquire_compile_lock() -> bool:
    """Attempt to acquire the compile-lock using mkdir (atomic, macOS-portable).

    Returns True if acquired, False if already held.
    """
    try:
        COMPILE_LOCK.mkdir(parents=False, exist_ok=False)
        return True
    except FileExistsError:
        return False


def release_compile_lock() -> None:
    """Release the compile-lock. Safe to call even if not held."""
    try:
        COMPILE_LOCK.rmdir()
    except (FileNotFoundError, OSError):
        pass


# ---------------------------------------------------------------------------
# Env / API key resolution
# ---------------------------------------------------------------------------

def _load_dotenv(path: Path) -> dict[str, str]:
    """Parse a .env file into a dict. Ignores comments and blank lines."""
    result: dict[str, str] = {}
    if not path.exists():
        return result
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, _, v = line.partition("=")
            result[k.strip()] = v.strip().strip('"').strip("'")
    return result


def get_exa_api_key() -> str | None:
    """Resolve EXA_API_KEY from environment or ~/.claude/.env."""
    key = os.environ.get("EXA_API_KEY")
    if key:
        return key
    env_file = Path.home() / ".claude" / ".env"
    env_vars = _load_dotenv(env_file)
    return env_vars.get("EXA_API_KEY")


def get_anthropic_api_key() -> str | None:
    """Resolve ANTHROPIC_API_KEY from environment or ~/.claude/.env."""
    key = os.environ.get("ANTHROPIC_API_KEY")
    if key:
        return key
    env_file = Path.home() / ".claude" / ".env"
    env_vars = _load_dotenv(env_file)
    return env_vars.get("ANTHROPIC_API_KEY")


# ---------------------------------------------------------------------------
# Mission I/O
# ---------------------------------------------------------------------------

def load_all_missions() -> dict[str, dict[str, Any]]:
    """Scan MISSIONS_DIR for mission.json files. Returns {slug: data}."""
    missions: dict[str, dict[str, Any]] = {}
    if not MISSIONS_DIR.exists():
        return missions
    for entry in MISSIONS_DIR.iterdir():
        if entry.name.startswith("_") or entry.name in {"active", "archive"}:
            continue
        if not entry.is_dir():
            continue
        mission_path = entry / "mission.json"
        if not mission_path.exists():
            continue
        try:
            with mission_path.open() as f:
                data = json.load(f)
            slug = data.get("id", entry.name)
            missions[slug] = data
        except (json.JSONDecodeError, OSError) as e:
            log.warning("Skipping malformed mission at %s: %s", entry, e)
    return missions


def save_mission(mission: dict[str, Any]) -> None:
    """Write mission.json back to disk with updated timestamp."""
    slug = mission["id"]
    mission["updated"] = datetime.now(timezone.utc).isoformat()
    path = MISSIONS_DIR / slug / "mission.json"
    with path.open("w") as f:
        json.dump(mission, f, indent=2)
        f.write("\n")


def append_jsonl(path: Path, entry: dict[str, Any]) -> None:
    """Append one JSON line to a .jsonl file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as f:
        f.write(json.dumps(entry) + "\n")


# ---------------------------------------------------------------------------
# Budget / spend tracking
# ---------------------------------------------------------------------------

def load_spend(slug: str) -> float:
    """Return total USD spent for a mission from spend-ledger.jsonl."""
    spend_path = MISSIONS_DIR / slug / "spend-ledger.jsonl"
    if not spend_path.exists():
        return 0.0
    total = 0.0
    with spend_path.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                total += entry.get("usd", 0.0)
            except json.JSONDecodeError:
                pass
    return total


def record_spend(slug: str, usd: float, description: str) -> None:
    """Append a spend entry to spend-ledger.jsonl."""
    spend_path = MISSIONS_DIR / slug / "spend-ledger.jsonl"
    append_jsonl(spend_path, {
        "ts": datetime.now(timezone.utc).isoformat(),
        "usd": usd,
        "description": description,
    })


# ---------------------------------------------------------------------------
# Cadence check
# ---------------------------------------------------------------------------

def is_stale(mission: dict[str, Any]) -> bool:
    """Return True if auto_research.last_run is null or > 24h ago."""
    ar = mission.get("auto_research", {})
    last_run = ar.get("last_run")
    if not last_run:
        return True
    try:
        last_dt = datetime.fromisoformat(last_run.replace("Z", "+00:00"))
        return datetime.now(timezone.utc) - last_dt > timedelta(hours=24)
    except (ValueError, TypeError):
        return True


# ---------------------------------------------------------------------------
# Exa search (REST API)
# ---------------------------------------------------------------------------

def exa_search(keyword: str, api_key: str, num_results: int = MAX_RESULTS_PER_KEYWORD) -> list[dict]:
    """Call Exa REST API and return list of {title, url, snippet} dicts.

    Retries once on network error with RETRY_DELAY_SECONDS backoff.
    Returns empty list on permanent failure.
    """
    try:
        import requests  # type: ignore[import-untyped]
    except ImportError:
        log.error("requests library not installed. Run: pip install requests")
        return []

    url = "https://api.exa.ai/search"
    headers = {
        "x-api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    payload = {
        "query": keyword,
        "numResults": num_results,
        "contents": {
            "text": {"maxCharacters": 500},
        },
    }

    for attempt in range(2):
        try:
            resp = requests.post(url, json=payload, headers=headers, timeout=30)
            if resp.status_code == 200:
                data = resp.json()
                results = []
                for item in data.get("results", []):
                    results.append({
                        "title": item.get("title", ""),
                        "url": item.get("url", ""),
                        "snippet": item.get("text", "")[:500],
                    })
                log.info("Exa: %d results for %r", len(results), keyword)
                return results
            else:
                log.warning("Exa returned HTTP %d for %r: %s", resp.status_code, keyword, resp.text[:200])
                return []
        except Exception as e:
            if attempt == 0:
                log.warning("Exa network error (will retry): %s", e)
                time.sleep(RETRY_DELAY_SECONDS)
            else:
                log.error("Exa network error (giving up): %s", e)
                return []
    return []


# ---------------------------------------------------------------------------
# Relevance scoring via Anthropic SDK (Haiku)
# ---------------------------------------------------------------------------

def score_relevance(
    mission_title: str,
    finding_title: str,
    finding_snippet: str,
    api_key: str,
) -> tuple[float, str]:
    """Score relevance of a finding for a mission using claude-haiku-4-5.

    Returns (score: 0.0-1.0, reason: str).
    Falls back to (0.0, 'scoring_unavailable') on any error.
    """
    try:
        import anthropic  # type: ignore[import-untyped]
    except ImportError:
        log.warning("anthropic SDK not installed. Run: pip install anthropic")
        return 0.0, "sdk_not_installed"

    client = anthropic.Anthropic(api_key=api_key)
    prompt = (
        f"Given mission goal: '{mission_title}'\n\n"
        f"Finding title: {finding_title!r}\n"
        f"Finding snippet: {finding_snippet!r}\n\n"
        "Is this finding relevant to the mission goal? "
        "Answer with a relevance score from 0.0 to 1.0 on the first line, "
        "then a single-line reason starting on the second line. "
        "Example:\n0.8\nDirectly addresses the integration requirements for this goal."
    )

    try:
        message = client.messages.create(
            model="claude-haiku-4-5",
            max_tokens=128,
            messages=[{"role": "user", "content": prompt}],
        )
        text = message.content[0].text.strip()
        lines = text.strip().splitlines()
        score = float(lines[0].strip())
        reason = lines[1].strip() if len(lines) > 1 else ""
        score = max(0.0, min(1.0, score))
        return score, reason
    except Exception as e:
        log.warning("Relevance scoring failed: %s", e)
        return 0.0, f"scoring_error: {e}"


# ---------------------------------------------------------------------------
# Per-mission research loop
# ---------------------------------------------------------------------------

def research_mission(
    slug: str,
    mission: dict[str, Any],
    exa_key: str | None,
    anthropic_key: str | None,
    dry_run: bool,
) -> None:
    """Run the research loop for one mission."""
    ar = mission.get("auto_research", {})
    keywords = ar.get("keywords", [])[:MAX_KEYWORDS_PER_DAY]
    relevance_threshold = ar.get("relevance_threshold", DEFAULT_RELEVANCE_THRESHOLD)
    title = mission.get("title", slug)
    budget_usd = mission.get("budget", {}).get("usd")
    now_ts = datetime.now(timezone.utc).isoformat()

    if not keywords:
        log.info("[%s] No keywords configured — skipping", slug)
        return

    # Budget check
    if budget_usd is not None:
        spent = load_spend(slug)
        if spent >= budget_usd:
            log.warning(
                "[%s] Budget exceeded ($%.4f spent / $%.2f budget) — skipping",
                slug, spent, budget_usd,
            )
            return

    if dry_run:
        print(f"[DRY RUN] {slug}: would search {len(keywords)} keywords: {keywords}")
        return

    if not exa_key:
        log.warning("[%s] EXA_API_KEY not found — skipping research, updating last_run=null", slug)
        ar["last_run"] = None
        mission["auto_research"] = ar
        save_mission(mission)
        return

    if not anthropic_key:
        log.warning("[%s] ANTHROPIC_API_KEY not found — skipping relevance scoring", slug)

    findings_above_threshold = 0
    total_checked = 0
    research_path = MISSIONS_DIR / slug / "research-findings.jsonl"

    for keyword in keywords:
        log.info("[%s] Searching: %r", slug, keyword)
        results = exa_search(keyword, exa_key)

        if not results:
            log.info("[%s] No results for %r", slug, keyword)
            continue

        for result in results:
            total_checked += 1
            relevance = DEFAULT_RELEVANCE_THRESHOLD  # default if no scoring
            reason = "no_scoring"

            if anthropic_key:
                relevance, reason = score_relevance(
                    title,
                    result.get("title", ""),
                    result.get("snippet", ""),
                    anthropic_key,
                )
                # ~$0.001 per call (Haiku)
                record_spend(slug, 0.001, f"relevance_score: {keyword[:40]}")

            if relevance >= relevance_threshold:
                findings_above_threshold += 1
                finding_entry = {
                    "ts": datetime.now(timezone.utc).isoformat(),
                    "keyword": keyword,
                    "title": result.get("title", ""),
                    "url": result.get("url", ""),
                    "snippet": result.get("snippet", ""),
                    "relevance": relevance,
                    "reason": reason,
                }
                append_jsonl(research_path, finding_entry)
                log.info("[%s] Finding saved: %.2f — %s", slug, relevance, result.get("title", ""))
            else:
                log.debug("[%s] Below threshold (%.2f < %.2f): %s", slug, relevance, relevance_threshold, result.get("title", ""))

    # Update last_run
    ar["last_run"] = now_ts
    mission["auto_research"] = ar
    save_mission(mission)

    # Append ledger summary
    ledger_path = MISSIONS_DIR / slug / "ledger.jsonl"
    append_jsonl(ledger_path, {
        "ts": now_ts,
        "event": "auto_research",
        "keywords": keywords,
        "findings_above_threshold": findings_above_threshold,
        "total_checked": total_checked,
    })

    log.info(
        "[%s] Research complete: %d/%d findings above threshold %.2f",
        slug, findings_above_threshold, total_checked, relevance_threshold,
    )


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Per-mission Exa research agent with Haiku relevance scoring",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--mission", metavar="SLUG",
        help="Research one specific mission (ignores cadence / 24h gate)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print what would be researched without making any API calls",
    )
    args = parser.parse_args()

    # Compile-lock: check before touching vault-adjacent paths
    if not args.dry_run:
        if not acquire_compile_lock():
            log.warning(
                "Compile lock held at %s — skipping autoresearch to avoid vault race. "
                "Will run on next cycle.",
                COMPILE_LOCK,
            )
            sys.exit(0)

    try:
        exa_key = get_exa_api_key()
        anthropic_key = get_anthropic_api_key()

        all_missions = load_all_missions()

        if not all_missions:
            log.info("No missions found at %s", MISSIONS_DIR)
            return

        if args.mission:
            # Single mission mode — ignore cadence
            if args.mission not in all_missions:
                log.error("Mission %r not found", args.mission)
                sys.exit(2)
            mission = all_missions[args.mission]
            ar = mission.get("auto_research", {})
            if not ar.get("enabled", False) and not args.dry_run:
                log.info("[%s] auto_research.enabled=false but --mission flag overrides", args.mission)
            research_mission(args.mission, mission, exa_key, anthropic_key, args.dry_run)
        else:
            # Scan all active missions with auto_research.enabled=true and stale
            researched = 0
            skipped = 0
            for slug, mission in sorted(all_missions.items()):
                status = mission.get("status", "")
                ar = mission.get("auto_research", {})

                if status not in {"active"}:
                    log.debug("[%s] status=%s — not active, skipping", slug, status)
                    skipped += 1
                    continue

                if not ar.get("enabled", False):
                    log.debug("[%s] auto_research.enabled=false — skipping", slug)
                    skipped += 1
                    continue

                if not is_stale(mission):
                    log.info("[%s] Last run < 24h ago — skipping", slug)
                    skipped += 1
                    continue

                research_mission(slug, mission, exa_key, anthropic_key, args.dry_run)
                researched += 1

            log.info("Autoresearch complete: %d researched, %d skipped", researched, skipped)

    finally:
        if not args.dry_run:
            release_compile_lock()


if __name__ == "__main__":
    main()
