"""MEMORY.md lifecycle manager - moves stale entries from hot to warm storage.

Hot storage  = MEMORY.md (in-context, read every session)
Warm storage = vault memory/ files (read on demand via query.py)

Usage:
    uv run python scripts/evict.py              # preview what would be evicted
    uv run python scripts/evict.py --execute    # actually move entries
    uv run python scripts/evict.py --days 7     # custom age threshold (default: 14)
    uv run python scripts/evict.py --file path/to/MEMORY.md  # custom file path
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import MEMORY_DIR, VAULT_PATH, today_str
from utils import setup_logging

logger = setup_logging("evict")

# ── Constants ─────────────────────────────────────────────────────────

DEFAULT_MEMORY_PATH = Path.home() / ".claude" / "MEMORY.md"
DEFAULT_AGE_DAYS = 14

# Regex patterns for parsing MEMORY.md entries
# Matches lines like: - [Entry text](memory/file.md) — description
LINK_ENTRY_RE = re.compile(r"^(\s*-\s+)\[(.+?)\]\((.+?)\)\s*(?:—\s*(.+))?$")
# Matches date annotations like: (2026-04-07) or date: 2026-04-07
DATE_ANNOTATION_RE = re.compile(r"\((\d{4}-\d{2}-\d{2})\)")
# Matches section headers: ## Section Name
SECTION_RE = re.compile(r"^#{1,3}\s+(.+)$")


# ── Entry parsing ─────────────────────────────────────────────────────

def parse_date_from_line(line: str) -> date | None:
    """Extract date from a MEMORY.md line. Returns None if no date found."""
    match = DATE_ANNOTATION_RE.search(line)
    if match:
        try:
            return datetime.strptime(match.group(1), "%Y-%m-%d").date()
        except ValueError:
            return None
    return None


def parse_entries(memory_path: Path) -> list[dict]:
    """Parse MEMORY.md into structured entries.

    Each entry is a dict with:
        line_index: int
        raw: str
        section: str
        date: date | None
        is_entry: bool  (False for headers, blanks, etc.)
    """
    if not memory_path.exists():
        return []

    lines = memory_path.read_text(encoding="utf-8").splitlines(keepends=True)
    entries = []
    current_section = "Unknown"

    for i, line in enumerate(lines):
        stripped = line.rstrip("\n")

        # Track current section
        section_match = SECTION_RE.match(stripped)
        if section_match:
            current_section = section_match.group(1)
            entries.append({
                "line_index": i,
                "raw": line,
                "section": current_section,
                "date": None,
                "is_entry": False,
            })
            continue

        # Check if this is a dated entry line (bullet point with a date)
        is_entry = stripped.strip().startswith("-") and stripped.strip() != "-"
        entry_date = parse_date_from_line(stripped) if is_entry else None

        entries.append({
            "line_index": i,
            "raw": line,
            "section": current_section,
            "date": entry_date,
            "is_entry": is_entry,
        })

    return entries


def identify_eviction_candidates(
    entries: list[dict], age_days: int
) -> list[dict]:
    """Return entries older than age_days that should be evicted."""
    cutoff = date.today() - timedelta(days=age_days)
    candidates = []
    for entry in entries:
        if not entry["is_entry"]:
            continue
        if entry["date"] is not None and entry["date"] < cutoff:
            candidates.append(entry)
    return candidates


# ── Warm storage write ────────────────────────────────────────────────

def _slugify(text: str) -> str:
    """Convert text to a safe filename slug."""
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower().strip())
    return slug[:60].strip("-")


def write_to_warm_storage(entry: dict, section: str) -> Path:
    """Write an evicted entry to vault memory/ as a standalone article."""
    MEMORY_DIR.mkdir(parents=True, exist_ok=True)

    # Build a slug from the entry content
    content_text = entry["raw"].strip().lstrip("-").strip()
    # Strip markdown links for slug generation
    plain_text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", content_text)
    plain_text = re.sub(r"\*+", "", plain_text)
    slug = _slugify(plain_text[:60])

    if not slug:
        slug = f"entry-{entry['line_index']}"

    out_path = MEMORY_DIR / f"evicted-{slug}.md"

    # Don't overwrite an existing evicted file — append a suffix
    counter = 1
    while out_path.exists():
        out_path = MEMORY_DIR / f"evicted-{slug}-{counter}.md"
        counter += 1

    evicted_date = entry["date"].isoformat() if entry["date"] else today_str()
    section_slug = _slugify(section)

    article = (
        f"---\n"
        f"type: memory\n"
        f"date: {evicted_date}\n"
        f"status: archived\n"
        f"tags: [evicted, {section_slug}]\n"
        f"evicted_at: {today_str()}\n"
        f"---\n\n"
        f"# {plain_text[:80]}\n\n"
        f"**Section:** {section}\n"
        f"**Original date:** {evicted_date}\n\n"
        f"## Content\n\n"
        f"{content_text}\n"
    )
    out_path.write_text(article, encoding="utf-8")
    return out_path


# ── MEMORY.md rewrite ─────────────────────────────────────────────────

def remove_entries_from_memory(
    memory_path: Path, entries_to_remove: list[dict]
) -> int:
    """Remove evicted entries from MEMORY.md. Returns count removed."""
    if not entries_to_remove:
        return 0

    remove_indices = {e["line_index"] for e in entries_to_remove}
    all_lines = memory_path.read_text(encoding="utf-8").splitlines(keepends=True)

    kept_lines = []
    removed = 0
    for i, line in enumerate(all_lines):
        if i in remove_indices:
            removed += 1
            logger.info("Evicting line %d: %s", i, line.rstrip())
        else:
            kept_lines.append(line)

    # Clean up consecutive blank lines left by removal
    cleaned: list[str] = []
    prev_blank = False
    for line in kept_lines:
        is_blank = line.strip() == ""
        if is_blank and prev_blank:
            continue  # skip double blank lines
        cleaned.append(line)
        prev_blank = is_blank

    memory_path.write_text("".join(cleaned), encoding="utf-8")
    return removed


# ── Main ─────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Evict stale MEMORY.md entries to warm vault storage"
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Actually move entries (default is preview/dry-run)",
    )
    parser.add_argument(
        "--days",
        type=int,
        default=DEFAULT_AGE_DAYS,
        help=f"Age threshold in days (default: {DEFAULT_AGE_DAYS})",
    )
    parser.add_argument(
        "--file",
        type=str,
        default=str(DEFAULT_MEMORY_PATH),
        help=f"Path to MEMORY.md (default: {DEFAULT_MEMORY_PATH})",
    )
    args = parser.parse_args()

    memory_path = Path(args.file).expanduser()
    dry_run = not args.execute

    if not memory_path.exists():
        print(f"Error: MEMORY.md not found at {memory_path}")
        print(f"Pass --file to specify a different path.")
        sys.exit(1)

    print(f"{'[DRY RUN] ' if dry_run else ''}Scanning: {memory_path}")
    print(f"Age threshold: {args.days} days (entries before {date.today() - timedelta(days=args.days)})")
    print()

    # Parse entries
    entries = parse_entries(memory_path)
    total_entries = sum(1 for e in entries if e["is_entry"])
    candidates = identify_eviction_candidates(entries, args.days)

    print(f"Total entry lines: {total_entries}")
    print(f"Eviction candidates: {len(candidates)}")
    print()

    if not candidates:
        print("Nothing to evict — all entries are within the age threshold.")
        return

    # Show candidates
    print("Entries to evict:")
    for entry in candidates:
        age = (date.today() - entry["date"]).days if entry["date"] else "unknown"
        preview = entry["raw"].rstrip()[:80]
        print(f"  [{age}d old | {entry['section']}] {preview}")

    print()

    if dry_run:
        print(f"Run with --execute to move these {len(candidates)} entries to warm storage.")
        return

    # Execute eviction
    evicted_paths = []
    for entry in candidates:
        out_path = write_to_warm_storage(entry, entry["section"])
        evicted_paths.append(out_path)
        print(f"  Archived: {out_path.relative_to(VAULT_PATH)}")

    removed = remove_entries_from_memory(memory_path, candidates)

    print()
    print(f"Eviction complete.")
    print(f"  Removed: {removed} lines from MEMORY.md")
    print(f"  Archived: {len(evicted_paths)} entries to {MEMORY_DIR}")
    print()
    print(f"Run 'uv run python scripts/compile.py' to index the new archive files.")


if __name__ == "__main__":
    main()
