"""
Index-guided knowledge retrieval for the Claude Brain vault.

No RAG, no vector DB. The agent reads the index, picks relevant articles, opens
them on demand with the Read tool, then synthesizes an answer with [[wikilink]]
citations.

Resilience:
- Only the INDEX is sent in the prompt (not the whole vault) — sending the full
  vault produced a multi-MB prompt that hung the SDK on large brains.
- The SDK call is bounded by a HARD timeout; if it times out / errors / is offline,
  a deterministic grep fallback returns the top matching articles so a query ALWAYS
  returns something. `--grep-only` forces the SDK-free path.

Usage:
    uv run python query.py "What auth patterns do I use?"
    uv run python query.py "What gotchas exist for this framework?"            # auto-files to qa/
    uv run python query.py "What gotchas exist for this framework?" --no-file-back
    uv run python query.py "What gotchas exist for this framework?" --no-cache
    uv run python query.py "What gotchas exist for this framework?" --grep-only  # SDK-free, instant
"""
from __future__ import annotations

import argparse
import asyncio
import os
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import BUILD_LOG, MEMORY_DIR, QA_DIR, VAULT_PATH, now_iso, today_str
from utils import (
    load_state,
    read_wiki_index,
    save_state,
    setup_logging,
)

logger = setup_logging("query")

# Internal marker for "the SDK path failed -> use the grep fallback". A sentinel (not a
# user-facing string) avoids mistaking a real answer that happens to start with it.
_FAIL_SENTINEL = "__BRAIN_QUERY_FAILED__"


def _slug(question: str) -> str:
    """Convert question to a safe filename slug."""
    slug = re.sub(r"[^a-z0-9]+", "-", question.lower().strip())
    return slug[:60].strip("-")


def _check_qa_cache(question: str, max_age_days: int = 7) -> str | None:
    """Check if a recent Q&A answer exists in the cache. Returns content or None."""
    slug = _slug(question)
    qa_file = QA_DIR / f"{slug}.md"
    if qa_file.exists():
        mtime = datetime.fromtimestamp(qa_file.stat().st_mtime, tz=timezone.utc)
        cutoff = datetime.now(timezone.utc) - timedelta(days=max_age_days)
        if mtime >= cutoff:
            return qa_file.read_text(encoding="utf-8")
    return None


_STOPWORDS = {
    "the", "a", "an", "of", "to", "in", "on", "for", "and", "or", "is", "are", "was",
    "what", "how", "do", "does", "did", "i", "my", "me", "you", "your", "with", "that",
    "this", "it", "at", "by", "be", "as", "from", "about", "can", "will", "when",
    "where", "which", "who", "use", "used", "have", "has",
}


def _keywords(question: str) -> list[str]:
    words = re.findall(r"[a-z0-9][a-z0-9_-]{2,}", question.lower())
    kws = [w for w in words if w not in _STOPWORDS]
    return kws or words


def grep_fallback(question: str, max_files: int = 8, max_lines: int = 4, scan_cap: int = 4000) -> str:
    """Deterministic, no-SDK retrieval: grep the vault for the question's keywords and
    return the top-matching articles + excerpts. Used when the Agent SDK is unavailable
    (rate-limited / offline) so a query STILL returns real docs."""
    kws = _keywords(question)
    if not kws:
        return "Grep fallback: no searchable keywords in question."
    search_dirs = [VAULT_PATH / d for d in
                   ("memory", "connections", "qa", "projects", "research", "sessions", "external")]
    scored: list[tuple[int, Path, list[str]]] = []
    scanned = 0
    for d in search_dirs:
        if not d.is_dir():
            continue
        for p in d.rglob("*.md"):  # unsorted: scan_cap below bounds traversal cost
            if "_consolidated" in p.parts or "_snapshots" in p.parts:
                continue
            if scanned >= scan_cap:
                break
            scanned += 1
            try:
                with open(p, encoding="utf-8", errors="replace") as _fh:
                    text = _fh.read(262144)  # first 256KB/file — bounds per-file read cost
            except OSError:
                continue
            low = text.lower()
            score = sum(low.count(k) for k in kws)
            if score <= 0:
                continue
            lines = [ln.strip() for ln in text.splitlines()
                     if any(k in ln.lower() for k in kws) and ln.strip()][:max_lines]
            scored.append((score, p, lines))
    if not scored:
        return f"Grep fallback: no vault articles match [{', '.join(kws)}]."
    scored.sort(key=lambda t: t[0], reverse=True)
    out = [f"## Grep fallback (SDK unavailable) — top matches for: {question}",
           f"_keywords: {', '.join(kws)} · scanned {scanned} files_", ""]
    for score, p, lines in scored[:max_files]:
        try:
            rel = p.relative_to(VAULT_PATH).with_suffix("").as_posix()
        except ValueError:
            rel = p.stem
        out.append(f"### [[{rel}]]  ({score} hits)")
        for ln in lines:
            out.append(f"> {ln[:300]}")
        out.append("")
    return "\n".join(out)


async def run_query(question: str, file_back: bool) -> str:
    """Run the query against the vault. Returns the synthesized answer (or a sentinel
    prefix on failure, which the caller turns into a grep fallback)."""
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, TextBlock, query  # type: ignore

    # Send only the INDEX — the agent opens articles on demand via Read/Glob/Grep (cwd is
    # the vault root). Dumping the whole vault produced a huge prompt that hung the SDK.
    wiki_content = read_wiki_index()
    _max_ctx = int(os.environ.get("BRAIN_QUERY_MAX_CONTENT", "400000"))
    if len(wiki_content) > _max_ctx:
        wiki_content = wiki_content[:_max_ctx] + "\n\n[... index truncated — use Glob/Grep on the vault ...]"

    timestamp = now_iso()
    date = today_str()
    qa_slug = _slug(question)
    qa_file = QA_DIR / f"{qa_slug}.md"
    memory_dir_str = str(MEMORY_DIR)
    build_log_str = str(BUILD_LOG)

    file_back_instructions = ""
    if file_back:
        file_back_instructions = f"""
## Persist to Q&A (--file-back is ON)

After synthesizing the answer, do the following:

1. **Create a Q&A article** at `{qa_file}`:
```markdown
---
title: "{question}"
tags: [qa, query]
created: {date}
updated: {date}
sources: []
---
# {question}

[Your synthesized answer here, with [[wikilinks]] to source articles]

## Sources
[List the articles you read]
```

2. **Update the index** at `{memory_dir_str}/index.md`:
   - Add an entry under a `## Q&A` section (create if missing):
     `- [[qa/{qa_slug}]] — {question}`

3. **Append to build log** at `{build_log_str}`:
   `## [{timestamp}] query | {question}`

Write all three files before finishing.
"""

    prompt = f"""You are a knowledge retrieval agent for an Obsidian vault.

## Vault INDEX
(Open any article in full with the Read tool — your cwd is the vault root; index entries are relative paths.)
{wiki_content}

---

## Question
{question}

## Instructions

1. **Read the INDEX above** — it lists the vault's articles.
2. **Identify 3-10 relevant articles** from the index based on the question.
3. **Open those articles in full with the Read tool** (cwd is the vault root; use the index's relative paths). Use Glob/Grep for anything the index misses.
4. **Synthesize a direct, declarative answer** using [[wikilink]] citations to the exact articles you used.
5. **Format your answer** as:
   - A direct answer paragraph (no hedging, no filler)
   - Key points as bullet list if multiple items
   - [[wikilinks]] inline for every claim sourced from an article
   - A "Sources" section listing which articles you relied on

### Quality rules:
- No hedging ("might", "could", "it seems")
- No filler — every sentence carries information
- If the vault has no relevant information, say so directly: "The vault has no articles covering this topic."
- Cite every claim — if you state a fact, link to its article
{file_back_instructions}
"""

    allowed_tools = ["Read", "Glob", "Grep"]
    if file_back:
        allowed_tools += ["Write", "Edit"]

    _sdk_timeout = int(os.environ.get("BRAIN_QUERY_SDK_TIMEOUT", "60"))

    async def _consume() -> str:
        ans = ""
        async for message in query(
            prompt=prompt,
            options=ClaudeAgentOptions(
                cwd=str(VAULT_PATH),
                system_prompt={"type": "preset", "preset": "claude_code"},
                allowed_tools=allowed_tools,
                permission_mode="acceptEdits",
                max_turns=15,
            ),
        ):
            if isinstance(message, ResultMessage):
                if hasattr(message, "content") and message.content:
                    for block in message.content:
                        if isinstance(block, TextBlock):
                            ans = block.text
                            break
                if not ans:
                    ans = str(message)
        return ans

    # HARD timeout via asyncio.wait (NOT wait_for — wait_for blocks awaiting the task's
    # cancellation, so a stuck/uncancellable SDK iterator wedges it). asyncio.wait returns
    # at the deadline regardless, so we always regain control and fall back.
    task = asyncio.ensure_future(_consume())
    done, _pending = await asyncio.wait({task}, timeout=_sdk_timeout)
    if task not in done:
        logger.error("Query SDK timed out after %ds (hard)", _sdk_timeout)
        task.cancel()
        await asyncio.wait({task}, timeout=5)  # bounded: let the cancel close the generator
        # A cleanly cancelled task raises CancelledError from .exception() (a BaseException,
        # not caught by `except Exception`), so only read it when it actually finished.
        if task.done() and not task.cancelled():
            try:
                task.exception()
            except Exception:
                pass
        return f"{_FAIL_SENTINEL} SDK timeout"
    try:
        return task.result()
    except Exception as e:
        logger.error("Query failed: %s", e)
        return f"{_FAIL_SENTINEL} {e}"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Query the Claude Brain knowledge base"
    )
    parser.add_argument("question", type=str, help="The question to ask")
    parser.add_argument(
        "--file-back",
        action="store_true",
        help="(deprecated — filing is now the default) Persist the answer to qa/",
    )
    parser.add_argument(
        "--no-file-back",
        action="store_true",
        help="Skip persisting the answer to qa/ (default: answers are always filed)",
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Skip cache check — always run a fresh query",
    )
    parser.add_argument(
        "--grep-only",
        action="store_true",
        help="Skip the SDK entirely — deterministic grep retrieval (always works, can't hang)",
    )
    args = parser.parse_args()

    question = args.question.strip()
    if not question:
        print("Error: question cannot be empty")
        sys.exit(1)

    # Guaranteed SDK-free path — instant, can't hang. Reliable when the SDK is down.
    if args.grep_only:
        print(grep_fallback(question))
        return

    state = load_state()

    # Check qa/ cache first (skip if --no-cache)
    if not args.no_cache:
        cached = _check_qa_cache(question)
        if cached:
            print(f"Cache hit: qa/{_slug(question)}.md (< 7 days old)\n")
            content = cached
            if content.startswith("---"):
                end = content.find("---", 3)
                if end != -1:
                    content = content[end + 3:].strip()
            print(content)
            return

    file_back = not args.no_file_back
    print(f"Querying: {question}")
    if file_back:
        print("(saved to qa/ only if the model answers; grep fallback is not filed)")
    print()

    # Redirect fd 2 -> /dev/null ONLY around asyncio.run (then restore) to swallow the
    # benign asyncio "Exception ignored in BaseSubprocessTransport.__del__" GC noise emitted
    # during loop teardown when an uncancellable SDK subprocess is abandoned — without hiding
    # later (fallback/state-save) stderr.
    _saved_err = None
    try:
        _saved_err = os.dup(2)
        _dn = os.open(os.devnull, os.O_WRONLY)
        os.dup2(_dn, 2)
        os.close(_dn)
    except Exception:
        _saved_err = None
    try:
        answer = asyncio.run(run_query(question, file_back))
    except Exception as e:
        answer = f"{_FAIL_SENTINEL} {e}"
    finally:
        if _saved_err is not None:
            try:
                os.dup2(_saved_err, 2)
                os.close(_saved_err)
            except Exception:
                pass

    # SDK unavailable (timeout / offline / import error) -> deterministic grep fallback.
    used_fallback = (not answer.strip()) or answer.startswith(_FAIL_SENTINEL)
    if used_fallback:
        print("[SDK unavailable — deterministic grep fallback]\n")
        print(grep_fallback(question))
    else:
        print(answer)

    # Track query count in state
    state["query_count"] = state.get("query_count", 0) + 1
    state["last_query"] = {
        "question": question,
        "asked_at": now_iso(),
        "file_back": file_back,
    }
    save_state(state)

    if file_back and not used_fallback:
        qa_slug = _slug(question)
        qa_file = QA_DIR / f"{qa_slug}.md"
        if qa_file.exists():
            print(f"\nSaved to: {qa_file}")
        else:
            print("\nNote: --file-back was requested but qa file was not confirmed on disk.")

    # FINAL act: an abandoned SDK subprocess transport may emit one more benign "__del__"
    # GC line at interpreter shutdown (after all real work + stderr above). Point fd 2 at
    # /dev/null as the very last thing so exit-time GC noise is dropped.
    try:
        sys.stdout.flush()
        _dn2 = os.open(os.devnull, os.O_WRONLY)
        os.dup2(_dn2, 2)
        os.close(_dn2)
    except Exception:
        pass


if __name__ == "__main__":
    main()
