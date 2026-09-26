"""Shared utilities for My AI Brain."""
from __future__ import annotations

import hashlib
import json
import logging
import os
import re
import sys
from pathlib import Path

from config import (
    CONNECTIONS_DIR,
    FLUSH_LOG,
    INDEX_FILE,
    LAST_FLUSH_FILE,
    MEMORY_DIR,
    PROJECTS_DIR,
    QA_DIR,
    SESSIONS_DIR,
    STATE_FILE,
    VAULT_PATH,
    detect_project,
    now_iso,
    today_str,
)


# ── Recursion guard ──────────────────────────────────────────────────

def check_recursion_guard() -> bool:
    """Return True if we should exit (invoked by memory flush)."""
    return bool(os.environ.get("CLAUDE_INVOKED_BY"))


# ── File hashing ─────────────────────────────────────────────────────

def file_hash(path: Path) -> str:
    """SHA-256 hash of a file (first 16 hex chars)."""
    return hashlib.sha256(path.read_bytes()).hexdigest()[:16]


# ── State management ─────────────────────────────────────────────────

def load_state() -> dict:
    """Load persistent state from brain-state.json."""
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return {"ingested": {}, "query_count": 0, "last_lint": None, "total_cost": 0.0}


def save_state(state: dict) -> None:
    """Save state to brain-state.json."""
    STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")


def load_flush_state() -> dict:
    """Load flush dedup state."""
    if LAST_FLUSH_FILE.exists():
        try:
            return json.loads(LAST_FLUSH_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def save_flush_state(state: dict) -> None:
    """Save flush dedup state."""
    LAST_FLUSH_FILE.write_text(json.dumps(state), encoding="utf-8")


# ── Wikilink helpers ─────────────────────────────────────────────────

def extract_wikilinks(content: str) -> list[str]:
    """Extract all [[wikilinks]] from markdown content."""
    return re.findall(r"\[\[([^\]]+)\]\]", content)


# ── Stem index for wikilink resolution ──────────────────────────────
_stem_index: dict[str, Path] | None = None


def _build_stem_index() -> dict[str, Path]:
    """Build a {stem: path, relative_path_without_ext: path} index for wiki articles."""
    global _stem_index
    if _stem_index is not None:
        return _stem_index
    index: dict[str, Path] = {}
    for article in list_wiki_articles():
        if article.name.startswith("_"):
            continue
        # Index by stem (e.g. "agent-dna" → path)
        index[article.stem] = article
        # Index by relative path without .md (e.g. "projects/sigma-capital/concepts/agent-dna" → path)
        rel = str(article.relative_to(VAULT_PATH))
        if rel.endswith(".md"):
            rel = rel[:-3]
        index[rel] = article
    _stem_index = index
    return index


def wiki_article_exists(link: str) -> bool:
    """Check if a wikilinked article exists on disk (supports stem-based resolution)."""
    index = _build_stem_index()
    return link in index


def resolve_wiki_path(link: str) -> Path | None:
    """Resolve a wikilink string to its actual file path, or None if not found."""
    index = _build_stem_index()
    return index.get(link)


def invalidate_stem_index() -> None:
    """Clear the stem index cache (call after creating/modifying articles)."""
    global _stem_index
    _stem_index = None


# ── Wiki content helpers ─────────────────────────────────────────────

def read_wiki_index() -> str:
    """Read the knowledge base index file."""
    if INDEX_FILE.exists():
        return INDEX_FILE.read_text(encoding="utf-8")
    return "# Memory Index\n\n(empty - no articles compiled yet)"


def list_wiki_articles() -> list[Path]:
    """List all wiki article files across all knowledge directories."""
    articles = []
    for subdir in [MEMORY_DIR, PROJECTS_DIR, CONNECTIONS_DIR, QA_DIR]:
        if subdir.exists():
            articles.extend(sorted(subdir.rglob("*.md")))
    return articles


def list_session_files() -> list[Path]:
    """List all session log files."""
    if not SESSIONS_DIR.exists():
        return []
    return sorted(f for f in SESSIONS_DIR.glob("*.md") if f.name != "_index.md")


def read_all_wiki_content() -> str:
    """Read index + all wiki articles into a single string for context."""
    parts = [f"## INDEX\n\n{read_wiki_index()}"]
    for md_file in list_wiki_articles():
        if md_file.name.startswith("_"):
            continue
        rel = md_file.relative_to(VAULT_PATH)
        content = md_file.read_text(encoding="utf-8")
        parts.append(f"## {rel}\n\n{content}")
    return "\n\n---\n\n".join(parts)


# ── Transcript parsing ───────────────────────────────────────────────

def extract_tail_from_transcript(
    transcript_path: Path, max_turns: int = 30, max_chars: int = 15_000
) -> tuple[str, int]:
    """Read JSONL transcript and extract last N conversation turns as markdown."""
    turns: list[str] = []

    with open(transcript_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg = entry.get("message", {})
            if isinstance(msg, dict):
                role = msg.get("role", "")
                content = msg.get("content", "")
            else:
                role = entry.get("role", "")
                content = entry.get("content", "")

            if role not in ("user", "assistant"):
                continue

            if isinstance(content, list):
                text_parts = []
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        text_parts.append(block.get("text", ""))
                    elif isinstance(block, str):
                        text_parts.append(block)
                content = "\n".join(text_parts)

            if isinstance(content, str) and content.strip():
                label = "User" if role == "user" else "Assistant"
                turns.append(f"**{label}:** {content.strip()}\n")

    recent = turns[-max_turns:]
    context = "\n".join(recent)

    if len(context) > max_chars:
        context = context[-max_chars:]
        boundary = context.find("\n**")
        if boundary > 0:
            context = context[boundary + 1:]

    return context, len(recent)


# ── Frontmatter generation ───────────────────────────────────────────

def frontmatter(
    note_type: str,
    tags: list[str],
    status: str = "active",
    date: str | None = None,
    extra: dict | None = None,
) -> str:
    """Generate Obsidian YAML frontmatter."""
    lines = ["---"]
    lines.append(f"type: {note_type}")
    lines.append(f"date: {date or today_str()}")
    lines.append(f"status: {status}")
    lines.append(f"tags: [{', '.join(tags)}]")
    if extra:
        for k, v in extra.items():
            lines.append(f"{k}: {v}")
    lines.append("---")
    return "\n".join(lines)


# ── Logging setup ────────────────────────────────────────────────────

def setup_logging(name: str = "brain") -> logging.Logger:
    """Set up file-based logging for background processes."""
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.FileHandler(str(FLUSH_LOG))
        handler.setFormatter(
            logging.Formatter(
                "%(asctime)s %(levelname)s [%(name)s] %(message)s",
                datefmt="%Y-%m-%d %H:%M:%S",
            )
        )
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    return logger


# ── Index helpers ────────────────────────────────────────────────────

def count_inbound_links(target: str) -> int:
    """Count how many wiki articles link to a given target (includes index files)."""
    count = 0
    for article in list_wiki_articles():
        content = article.read_text(encoding="utf-8")
        if f"[[{target}]]" in content:
            count += 1
    return count


def get_article_word_count(path: Path) -> int:
    """Count words in an article, excluding YAML frontmatter."""
    content = path.read_text(encoding="utf-8")
    if content.startswith("---"):
        end = content.find("---", 3)
        if end != -1:
            content = content[end + 3:]
    return len(content.split())
