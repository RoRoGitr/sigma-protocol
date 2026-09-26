"""
7-point health check for the Claude Brain knowledge base.

Checks 1-6 are structural (free, instant).
Check 7 is LLM-based (costs money, requires --deep flag).

Usage:
    uv run python lint.py                    # all structural checks (default)
    uv run python lint.py --structural-only  # same as default
    uv run python lint.py --deep             # include LLM contradiction check
    uv run python lint.py --fix              # auto-fix missing backlinks
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import INBOX_DIR, MEMORY_DIR, VAULT_PATH, now_iso, today_str
from utils import (
    count_inbound_links,
    extract_wikilinks,
    file_hash,
    get_article_word_count,
    invalidate_stem_index,
    list_session_files,
    list_wiki_articles,
    load_state,
    resolve_wiki_path,
    save_state,
    setup_logging,
    wiki_article_exists,
)

logger = setup_logging("lint")

# ── Check implementations ─────────────────────────────────────────────


def check_broken_wikilinks() -> list[dict]:
    """Check 1: [[links]] pointing to non-existent files."""
    issues = []
    for article in list_wiki_articles():
        if article.name.startswith("_"):
            continue
        content = article.read_text(encoding="utf-8")
        for link in extract_wikilinks(content):
            # Strip display text (e.g. [[path|display]] → path)
            target = link.split("|")[0].strip()
            # Skip session references — they're not wiki articles
            if target.startswith("sessions/"):
                continue
            if not wiki_article_exists(target):
                issues.append({
                    "check": "broken_wikilink",
                    "file": str(article.relative_to(VAULT_PATH)),
                    "link": target,
                    "severity": "error",
                })
    return issues


def check_orphan_pages() -> list[dict]:
    """Check 2: Articles with zero inbound links."""
    issues = []
    for article in list_wiki_articles():
        if article.name.startswith("_"):
            continue
        rel = str(article.relative_to(VAULT_PATH))
        # Skip index and top-level files — they're entry points by design
        if "/" not in rel:
            continue
        stem = article.stem
        inbound = count_inbound_links(stem)
        if inbound == 0:
            issues.append({
                "check": "orphan_page",
                "file": rel,
                "inbound_links": 0,
                "severity": "warning",
            })
    return issues


def check_orphan_sources(state: dict) -> list[dict]:
    """Check 3: Session files not yet compiled."""
    issues = []
    ingested = state.get("ingested", {})
    for session in list_session_files():
        if session.name not in ingested:
            issues.append({
                "check": "orphan_source",
                "file": str(session.relative_to(VAULT_PATH)),
                "severity": "warning",
                "detail": "Session not compiled into knowledge base",
            })
    return issues


def check_stale_articles(state: dict) -> list[dict]:
    """Check 4: Source session changed since compilation."""
    issues = []
    ingested = state.get("ingested", {})
    sessions_by_name = {s.name: s for s in list_session_files()}
    for session_name, record in ingested.items():
        session_path = sessions_by_name.get(session_name)
        if session_path is None:
            continue
        current_hash = file_hash(session_path)
        if current_hash != record.get("hash", ""):
            issues.append({
                "check": "stale_article",
                "file": f"sessions/{session_name}",
                "compiled_at": record.get("compiled_at", "unknown"),
                "severity": "warning",
                "detail": "Session changed since last compilation — rerun compile.py",
            })
    return issues


def check_missing_backlinks() -> list[tuple[str, str, str]]:
    """Check 5: A links to B but B doesn't link back to A.
    Returns list of (source_file, target_file, missing_link) tuples."""
    missing = []
    articles = [a for a in list_wiki_articles() if not a.name.startswith("_")]

    for article in articles:
        content = article.read_text(encoding="utf-8")
        source_stem = article.stem
        source_rel = str(article.relative_to(VAULT_PATH))

        for link in extract_wikilinks(content):
            target = link.split("|")[0].strip()
            # Skip session references
            if target.startswith("sessions/"):
                continue
            target_path = resolve_wiki_path(target)
            if target_path is None:
                continue
            target_content = target_path.read_text(encoding="utf-8")
            if f"[[{source_stem}]]" not in target_content:
                target_rel = str(target_path.relative_to(VAULT_PATH))
                missing.append((source_rel, target_rel, source_stem))
    return missing


def check_sparse_articles() -> list[dict]:
    """Check 6: Articles under 200 words (excluding frontmatter)."""
    issues = []
    for article in list_wiki_articles():
        if article.name.startswith("_"):
            continue
        word_count = get_article_word_count(article)
        if word_count < 200:
            issues.append({
                "check": "sparse_article",
                "file": str(article.relative_to(VAULT_PATH)),
                "word_count": word_count,
                "severity": "info",
                "detail": f"Only {word_count} words — may need expansion",
            })
    return issues


async def check_contradictions_llm() -> list[dict]:
    """Check 7: LLM-based contradiction detection (--deep only)."""
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query  # type: ignore

    articles = list_wiki_articles()
    if not articles:
        return []

    # Build compact article summaries for the LLM
    summaries = []
    for article in articles[:80]:  # cap to avoid blowing context
        if article.name.startswith("_"):
            continue
        rel = str(article.relative_to(VAULT_PATH))
        content = article.read_text(encoding="utf-8")
        summaries.append(f"### {rel}\n{content[:600]}")

    all_summaries = "\n\n".join(summaries)

    prompt = f"""You are auditing an Obsidian knowledge base for contradictions.

Below are article summaries from the vault. Identify pairs of articles that state directly contradictory facts, recommendations, or decisions.

## Articles
{all_summaries}

## Output Format
For each contradiction found, output exactly:

CONTRADICTION: <file-a> ↔ <file-b>
CLAIM_A: [exact quote or paraphrase from file-a]
CLAIM_B: [exact quote or paraphrase from file-b]
SEVERITY: critical|moderate|minor
RESOLUTION: [suggested fix]

If no contradictions found, output: NO_CONTRADICTIONS_FOUND

Be strict — only flag genuine factual conflicts, not differences in scope or context.
"""

    issues = []
    raw_output = ""

    try:
        async for message in query(
            prompt=prompt,
            options=ClaudeAgentOptions(
                cwd=str(VAULT_PATH),
                system_prompt={"type": "preset", "preset": "claude_code"},
                allowed_tools=[],
                permission_mode="acceptEdits",
                max_turns=2,
            ),
        ):
            if isinstance(message, ResultMessage):
                raw_output = str(message)
    except Exception as e:
        logger.error("LLM contradiction check failed: %s", e)
        return [{
            "check": "contradiction",
            "severity": "error",
            "detail": f"LLM check failed: {e}",
        }]

    if "NO_CONTRADICTIONS_FOUND" in raw_output:
        return []

    # Parse structured output
    for block in raw_output.split("CONTRADICTION:")[1:]:
        lines = block.strip().splitlines()
        pair = lines[0].strip() if lines else "unknown"
        issues.append({
            "check": "contradiction",
            "pair": pair,
            "detail": block.strip()[:400],
            "severity": "critical" if "critical" in block.lower() else "moderate",
        })

    return issues


def fix_missing_backlinks(missing: list[tuple[str, str, str]]) -> int:
    """Auto-fix: append backlink to target articles. Returns count fixed."""
    fixed = 0
    for _source_rel, target_rel, source_stem in missing:
        target_path = VAULT_PATH / target_rel
        if not target_path.exists():
            continue
        content = target_path.read_text(encoding="utf-8")
        # Append to Related Concepts section if present, else append at end
        backlink_line = f"- [[{source_stem}]] - backlink (auto-added by lint)"
        if "## Related Concepts" in content:
            content = content.replace(
                "## Related Concepts",
                f"## Related Concepts\n{backlink_line}",
                1,
            )
        else:
            content = content.rstrip() + f"\n\n## Related Concepts\n{backlink_line}\n"
        target_path.write_text(content, encoding="utf-8")
        fixed += 1
        logger.info("Added backlink [[%s]] to %s", source_stem, target_rel)
    invalidate_stem_index()
    return fixed


def compute_vault_score() -> dict:
    """Compute a 0-100 vault quality score: connectivity + integrity + freshness."""
    articles = [a for a in list_wiki_articles() if not a.name.startswith("_")]
    total = len(articles) if articles else 1  # avoid div-by-zero

    # Connectivity: % of articles with at least 1 inbound link (40 pts)
    linked = sum(1 for a in articles if count_inbound_links(a.stem) > 0)
    connectivity = (linked / total) * 40

    # Integrity: proportional wikilink resolution rate (30 pts)
    total_links = 0
    broken_links = 0
    for a in articles:
        content = a.read_text(encoding="utf-8")
        for link in extract_wikilinks(content):
            target = link.split("|")[0].strip()
            if target.startswith("sessions/"):
                continue
            total_links += 1
            if not wiki_article_exists(target):
                broken_links += 1
    if total_links > 0:
        integrity = (1 - broken_links / total_links) * 30
    else:
        integrity = 30.0

    # Freshness: % of articles updated within 30 days (30 pts)
    cutoff = datetime.now(timezone.utc) - timedelta(days=30)
    fresh = 0
    for a in articles:
        mtime = datetime.fromtimestamp(a.stat().st_mtime, tz=timezone.utc)
        if mtime >= cutoff:
            fresh += 1
    freshness = (fresh / total) * 30

    score = round(connectivity + integrity + freshness, 1)
    return {
        "score": score,
        "connectivity": round(connectivity, 1),
        "integrity": round(integrity, 1),
        "freshness": round(freshness, 1),
        "total_articles": total,
        "linked_articles": linked,
        "total_links": total_links,
        "broken_links": broken_links,
        "fresh_articles": fresh,
    }


SCORE_FILE = Path(__file__).resolve().parent / "vault-quality-score.json"


def save_vault_score(score_data: dict) -> None:
    """Save vault quality score with history (90 entries max)."""
    from config import now_iso

    history = []
    if SCORE_FILE.exists():
        try:
            existing = json.loads(SCORE_FILE.read_text(encoding="utf-8"))
            history = existing.get("history", [])
        except (json.JSONDecodeError, OSError):
            pass

    entry = {
        "timestamp": now_iso(),
        "score": score_data["score"],
        "connectivity": score_data["connectivity"],
        "integrity": score_data["integrity"],
        "freshness": score_data["freshness"],
    }
    history.append(entry)
    history = history[-90:]  # cap at 90 entries

    output = {
        "current": score_data,
        "history": history,
    }
    SCORE_FILE.write_text(json.dumps(output, indent=2), encoding="utf-8")


def write_report(sections: list[str], date: str) -> Path:
    """Save lint report to inbox."""
    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    report_path = INBOX_DIR / f"lint-{date}.md"
    report_path.write_text("\n\n".join(sections), encoding="utf-8")
    return report_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Health check for the Claude Brain knowledge base"
    )
    parser.add_argument(
        "--structural-only",
        action="store_true",
        help="Run structural checks only (default behavior)",
    )
    parser.add_argument(
        "--deep",
        action="store_true",
        help="Include LLM-based contradiction check (costs money)",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Auto-fix missing backlinks",
    )
    parser.add_argument(
        "--score",
        action="store_true",
        help="Compute and output vault quality score as JSON (0-100)",
    )
    args = parser.parse_args()

    if args.score:
        score_data = compute_vault_score()
        save_vault_score(score_data)
        print(json.dumps(score_data, indent=2))
        return

    state = load_state()
    date = today_str()
    all_issues: list[dict] = []
    report_sections: list[str] = []

    report_sections.append(
        f"# Claude Brain Lint Report\n**Date:** {date}\n**Vault:** {VAULT_PATH}"
    )

    # ── Check 1: Broken wikilinks ──────────────────────────────────────
    print("Check 1/7: Broken wikilinks...", end=" ", flush=True)
    broken = check_broken_wikilinks()
    all_issues.extend(broken)
    status = f"PASS (0 issues)" if not broken else f"FAIL ({len(broken)} broken links)"
    print(status)
    if broken:
        lines = [f"## Check 1: Broken Wikilinks — {len(broken)} issues\n"]
        for issue in broken:
            lines.append(f"- `{issue['file']}` → [[{issue['link']}]] does not exist")
        report_sections.append("\n".join(lines))

    # ── Check 2: Orphan pages ──────────────────────────────────────────
    print("Check 2/7: Orphan pages...", end=" ", flush=True)
    orphans = check_orphan_pages()
    all_issues.extend(orphans)
    status = f"PASS (0 issues)" if not orphans else f"WARN ({len(orphans)} orphans)"
    print(status)
    if orphans:
        lines = [f"## Check 2: Orphan Pages — {len(orphans)} issues\n"]
        for issue in orphans:
            lines.append(f"- `{issue['file']}` — no inbound links")
        report_sections.append("\n".join(lines))

    # ── Check 3: Orphan sources ────────────────────────────────────────
    print("Check 3/7: Orphan sources (uncompiled sessions)...", end=" ", flush=True)
    orphan_sources = check_orphan_sources(state)
    all_issues.extend(orphan_sources)
    status = f"PASS (0 issues)" if not orphan_sources else f"WARN ({len(orphan_sources)} uncompiled)"
    print(status)
    if orphan_sources:
        lines = [f"## Check 3: Orphan Sources — {len(orphan_sources)} issues\n"]
        for issue in orphan_sources:
            lines.append(f"- `{issue['file']}` — not yet compiled")
        report_sections.append("\n".join(lines))

    # ── Check 4: Stale articles ────────────────────────────────────────
    print("Check 4/7: Stale articles...", end=" ", flush=True)
    stale = check_stale_articles(state)
    all_issues.extend(stale)
    status = f"PASS (0 issues)" if not stale else f"WARN ({len(stale)} stale)"
    print(status)
    if stale:
        lines = [f"## Check 4: Stale Articles — {len(stale)} issues\n"]
        for issue in stale:
            lines.append(
                f"- `{issue['file']}` changed since compiled at {issue['compiled_at']}"
            )
        report_sections.append("\n".join(lines))

    # ── Check 5: Missing backlinks ─────────────────────────────────────
    print("Check 5/7: Missing backlinks...", end=" ", flush=True)
    missing_back = check_missing_backlinks()
    status = f"PASS (0 issues)" if not missing_back else f"WARN ({len(missing_back)} missing)"
    print(status)
    if missing_back:
        all_issues.extend([
            {
                "check": "missing_backlink",
                "source": src,
                "target": tgt,
                "missing_link": link,
                "severity": "warning",
            }
            for src, tgt, link in missing_back
        ])
        if args.fix:
            fixed = fix_missing_backlinks(missing_back)
            print(f"  Fixed {fixed} backlinks.")
        lines = [f"## Check 5: Missing Backlinks — {len(missing_back)} issues\n"]
        for src, tgt, link in missing_back:
            lines.append(f"- `{tgt}` is missing [[{link}]] (linked from `{src}`)")
        if args.fix:
            lines.append(f"\n_Auto-fix applied._")
        report_sections.append("\n".join(lines))

    # ── Check 6: Sparse articles ───────────────────────────────────────
    print("Check 6/7: Sparse articles (<200 words)...", end=" ", flush=True)
    sparse = check_sparse_articles()
    all_issues.extend(sparse)
    status = f"PASS (0 issues)" if not sparse else f"INFO ({len(sparse)} sparse)"
    print(status)
    if sparse:
        lines = [f"## Check 6: Sparse Articles — {len(sparse)} issues\n"]
        for issue in sparse:
            lines.append(f"- `{issue['file']}` — {issue['word_count']} words")
        report_sections.append("\n".join(lines))

    # ── Check 7: LLM contradictions (--deep only) ──────────────────────
    if args.deep:
        print("Check 7/7: LLM contradiction scan (this costs money)...", end=" ", flush=True)
        contradictions = asyncio.run(check_contradictions_llm())
        all_issues.extend(contradictions)
        status = f"PASS (0 found)" if not contradictions else f"FAIL ({len(contradictions)} contradictions)"
        print(status)
        if contradictions:
            lines = [f"## Check 7: Contradictions — {len(contradictions)} found\n"]
            for issue in contradictions:
                lines.append(f"### {issue.get('pair', 'unknown pair')}")
                lines.append(f"```\n{issue.get('detail', '')}\n```")
            report_sections.append("\n".join(lines))
    else:
        print("Check 7/7: LLM contradictions — SKIPPED (use --deep to enable)")

    # ── Summary ────────────────────────────────────────────────────────
    errors = [i for i in all_issues if i.get("severity") == "error"]
    warnings = [i for i in all_issues if i.get("severity") == "warning"]
    infos = [i for i in all_issues if i.get("severity") == "info"]

    summary_lines = [
        "## Summary",
        f"- Errors: {len(errors)}",
        f"- Warnings: {len(warnings)}",
        f"- Info: {len(infos)}",
        f"- Total issues: {len(all_issues)}",
        f"- Structural checks: 6/6 complete",
        f"- LLM check: {'complete' if args.deep else 'skipped (--deep)'}",
    ]
    report_sections.insert(1, "\n".join(summary_lines))

    report_path = write_report(report_sections, date)

    # Persist lint timestamp
    state["last_lint"] = now_iso()
    save_state(state)

    print(f"\nReport saved to: {report_path}")
    print(f"Errors: {len(errors)}  Warnings: {len(warnings)}  Info: {len(infos)}")

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
