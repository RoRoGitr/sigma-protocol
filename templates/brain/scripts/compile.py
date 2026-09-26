"""
Compile session logs into structured knowledge articles.

Usage:
    uv run python compile.py              # compile new/changed only
    uv run python compile.py --all        # force recompile everything
    uv run python compile.py --file sessions/2024-01-15.md
    uv run python compile.py --dry-run
"""
from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import (
    CONNECTIONS_DIR,
    MEMORY_DIR,
    PROJECTS_DIR,
    QA_DIR,
    SCRIPTS_DIR,
    SESSIONS_DIR,
    VAULT_PATH,
    now_iso,
)
from utils import (
    file_hash,
    list_session_files,
    list_wiki_articles,
    load_state,
    read_wiki_index,
    save_state,
    setup_logging,
)

logger = setup_logging("compile")


async def compile_session(session_path: Path, state: dict) -> float:
    """Compile a single session file into knowledge articles. Returns API cost."""
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query  # type: ignore

    session_content = session_path.read_text(encoding="utf-8")
    wiki_index = read_wiki_index()

    # Read compilation learnings for context (Saraev resources.md pattern)
    learnings_file = VAULT_PATH / "research" / "compilation-learnings.md"
    learnings_context = ""
    if learnings_file.exists():
        try:
            learnings_context = learnings_file.read_text(encoding="utf-8")
        except OSError:
            pass

    # Read existing articles for context (cap at 50 to stay within limits)
    existing_context = ""
    existing: dict[str, str] = {}
    for article_path in list_wiki_articles():
        if article_path.name.startswith("_"):
            continue
        rel = article_path.relative_to(VAULT_PATH)
        content = article_path.read_text(encoding="utf-8")
        existing[str(rel)] = content

    if existing:
        parts = []
        for rel_path, content in list(existing.items())[:50]:
            parts.append(f"### {rel_path}\n```markdown\n{content[:500]}\n```")
        existing_context = "\n\n".join(parts)

    timestamp = now_iso()
    projects_dir_str = str(PROJECTS_DIR)
    connections_dir_str = str(CONNECTIONS_DIR)
    qa_dir_str = str(QA_DIR)
    memory_dir_str = str(MEMORY_DIR)
    vault_path_str = str(VAULT_PATH)

    article_format = """\
---
title: "Topic Name"
tags: [domain, topic]
sources: ["sessions/SESSION_FILE"]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
# Topic Name
[2-4 sentence explanation]
## Key Points
- [bullet points]
## Details
[deeper explanation]
## Related Concepts
- [[path/to/related]] - how it connects
## Sources
- [[sessions/SESSION_FILE]] - what was learned"""

    prompt = f"""You are a knowledge compiler for an Obsidian vault. Read the session log below and extract knowledge into structured articles.

## Current Wiki Index
{wiki_index}

## Existing Articles (summaries)
{existing_context if existing_context else "(No existing articles yet)"}

## Session Log to Compile
**File:** {session_path.name}

{session_content}

## Compilation Learnings
{learnings_context if learnings_context else "(No previous learnings yet)"}

## Your Task

Extract knowledge from this session log into vault articles. Follow these rules:

1. **Project-scoped concepts** → Write to `projects/{{project}}/concepts/{{topic}}.md`
   - Identify the project from the session tags or context
   - One file per atomic concept (pattern, decision, gotcha, architecture choice)
2. **Cross-project connections** → Write to `connections/{{topic}}.md`
   - Only when 2+ projects share a pattern or insight
3. **Update existing articles** if this session adds info to an existing concept
   - Add the session as a source, add new key points
4. **Update memory/index.md** → Add new entries to the index
5. **Append to build-log.md** → Add: `## [{timestamp}] compile | {session_path.name}`

### Article format (MANDATORY):
```markdown
{article_format}
```

### Quality rules:
- Every article MUST have YAML frontmatter with title, tags, sources, created, updated
- Use [[wikilinks]] for all internal references
- No hedging, no filler — direct and declarative
- Prefer updating existing articles over creating near-duplicates
- A single session may touch 3-10 knowledge articles

### File paths:
- Project concepts: {projects_dir_str}/{{project}}/concepts/
- Connections: {connections_dir_str}/
- Q&A: {qa_dir_str}/
- Index: {memory_dir_str}/index.md
- Build log: {vault_path_str}/build-log.md
"""

    cost = 0.0
    try:
        async for message in query(
            prompt=prompt,
            options=ClaudeAgentOptions(
                cwd=str(VAULT_PATH),
                system_prompt={"type": "preset", "preset": "claude_code"},
                allowed_tools=["Read", "Write", "Edit", "Glob", "Grep"],
                permission_mode="acceptEdits",
                max_turns=30,
            ),
        ):
            if isinstance(message, ResultMessage):
                cost = message.total_cost_usd or 0.0
    except Exception as e:
        logger.error("Compilation error for %s: %s", session_path.name, e)
        return 0.0

    # Update state
    state.setdefault("ingested", {})[session_path.name] = {
        "hash": file_hash(session_path),
        "compiled_at": now_iso(),
        "cost_usd": cost,
    }
    state["total_cost"] = state.get("total_cost", 0.0) + cost
    save_state(state)
    logger.info("Compiled %s — cost $%.4f", session_path.name, cost)

    # Append to compilation learnings (Saraev resources.md pattern)
    try:
        entry = (
            f"\n\n## [{now_iso()}] compile | {session_path.name}\n"
            f"- Cost: ${cost:.4f}\n"
            f"- Session size: {len(session_content)} chars\n"
            f"- Existing articles at compile time: {len(existing)}\n"
        )
        if learnings_file.exists():
            with open(learnings_file, "a", encoding="utf-8") as f:
                f.write(entry)
        else:
            learnings_file.parent.mkdir(parents=True, exist_ok=True)
            learnings_file.write_text(
                "---\ntitle: Compilation Learnings\ntags: [meta, autoresearch, compile]\n"
                f"created: {now_iso()[:10]}\nupdated: {now_iso()[:10]}\n---\n\n"
                "# Compilation Learnings\n" + entry,
                encoding="utf-8",
            )
    except OSError as e:
        logger.warning("Failed to update compilation learnings: %s", e)

    return cost


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compile session logs into knowledge articles"
    )
    parser.add_argument("--all", action="store_true", help="Force recompile all sessions")
    parser.add_argument("--file", type=str, help="Compile a specific session file")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be compiled")
    parser.add_argument("--evict", action="store_true", help="Run evict.py after compilation to move stale MEMORY.md entries to vault")
    args = parser.parse_args()

    state = load_state()

    if args.file:
        target = Path(args.file)
        if not target.is_absolute():
            target = SESSIONS_DIR / target.name
        if not target.exists():
            target = VAULT_PATH / args.file
        if not target.exists():
            print(f"Error: {args.file} not found")
            sys.exit(1)
        to_compile = [target]
    else:
        all_sessions = list_session_files()
        if args.all:
            to_compile = all_sessions
        else:
            to_compile = []
            for sp in all_sessions:
                prev = state.get("ingested", {}).get(sp.name, {})
                if not prev or prev.get("hash") != file_hash(sp):
                    to_compile.append(sp)

    if not to_compile:
        print("Nothing to compile — all session logs are up to date.")
        return

    prefix = "[DRY RUN] " if args.dry_run else ""
    print(f"{prefix}Files to compile ({len(to_compile)}):")
    for f in to_compile:
        print(f"  - {f.name}")

    if args.dry_run:
        return

    total_cost = 0.0
    for i, sp in enumerate(to_compile, 1):
        print(f"\n[{i}/{len(to_compile)}] Compiling {sp.name}...")
        cost = asyncio.run(compile_session(sp, state))
        total_cost += cost
        print(f"  Cost: ${cost:.4f}")

    articles = list_wiki_articles()
    print(f"\nCompilation complete. Total cost: ${total_cost:.2f}")
    print(f"Knowledge base: {len(articles)} articles")

    if args.evict:
        import subprocess
        print("\nRunning MEMORY.md eviction...")
        subprocess.run(
            ["uv", "run", "--directory", str(SCRIPTS_DIR), "python", str(SCRIPTS_DIR / "evict.py"), "--execute"],
            cwd=str(SCRIPTS_DIR),
        )


if __name__ == "__main__":
    main()
