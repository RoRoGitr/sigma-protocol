"""
Memory flush agent - extracts knowledge from conversation context.
Spawned by hooks as a background process.
Usage: uv run python flush.py <context_file.md> <session_id>
"""
from __future__ import annotations

import os
os.environ["CLAUDE_INVOKED_BY"] = "memory_flush"

import asyncio
import json
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# Import from sibling modules
sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import (
    COMPILE_AFTER_HOUR,
    FLUSH_COOLDOWN_SECONDS,
    SPAWN_MIN_BATTERY,
    SCRIPTS_DIR,
    SESSIONS_DIR,
    VAULT_PATH,
    now_iso,
    today_str,
)
from utils import (
    detect_project,
    file_hash,
    load_flush_state,
    save_flush_state,
    setup_logging,
)

logger = setup_logging("flush")


# ── Extraction prompt ────────────────────────────────────────────────────────

EXTRACTION_PROMPT_TEMPLATE = """\
You are a knowledge extraction agent writing to an Obsidian vault.

Analyze the following conversation context and extract ONLY the knowledge worth preserving across sessions. This goes into a permanent session log — make every bullet count.

Anti-slop rules (violations invalidate the output):
- No hedging: never write "might", "could perhaps", "it seems", "appears to", "potentially"
- No filler: never write "dive in", "game-changing", "seamless", "robust", "leverage", "delve", "harness", "cutting-edge"
- Direct and declarative statements only
- One actionable bullet per line — no compound sentences masquerading as bullets
- Decisions MUST include rationale (what was decided AND why)
- Skip: routine tool calls, trivial back-and-forth, restating what the user already knows, obvious content
- Skip: implementation details unless they encode a non-obvious pattern or constraint
- If nothing worth saving exists in this context, respond with exactly: FLUSH_OK

Extract into this exact format (omit any section with no content):

**Context:** [1-2 sentences: what the user was working on and why]

**Decisions Made:**
- [decision]: [rationale]

**Lessons Learned:**
- [gotcha, pattern, or constraint discovered — phrased so a future agent understands what to do or avoid]

**Action Items:**
- [ ] [concrete follow-up with enough context to act on it]

Project: {project}
Session ID: {session_id}

--- CONVERSATION CONTEXT ---

{context}

--- END CONTEXT ---
"""


# ── Session file helpers ─────────────────────────────────────────────────────

def _session_file_path() -> Path:
    """Return today's session file path."""
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    return SESSIONS_DIR / f"{today_str()}.md"


def _session_header(project: str) -> str:
    """Generate the frontmatter + title for a new session file."""
    date = today_str()
    tags = ["session"]
    if project:
        tags.append(project)
    tags_str = ", ".join(tags)
    return (
        f"---\n"
        f"type: session\n"
        f"date: {date}\n"
        f"status: active\n"
        f"tags: [{tags_str}]\n"
        f"---\n\n"
        f"# Session — {date}\n\n"
        f"## Sessions\n"
    )


def _format_session_block(extracted: str, project: str, session_id: str) -> str:
    """Format the extracted content as an H3 session block to append."""
    now = datetime.now(timezone.utc).astimezone()
    time_str = now.strftime("%H:%M")
    project_label = project if project else "unknown"
    # Capitalize first letter of each word for the project label
    project_display = " ".join(w.capitalize() for w in project_label.replace("-", " ").split())

    block = f"\n### Session ({time_str}) — {project_display}\n"
    block += extracted.strip()
    block += "\n"
    return block


def _append_to_session_file(session_file: Path, block: str, project: str) -> None:
    """Create or append to today's session file."""
    if session_file.exists():
        current = session_file.read_text(encoding="utf-8")
        # Append the new block — no frontmatter duplication
        session_file.write_text(current.rstrip() + "\n" + block, encoding="utf-8")
        logger.info("Appended session block to %s", session_file)
    else:
        header = _session_header(project)
        session_file.write_text(header + block, encoding="utf-8")
        logger.info("Created new session file %s", session_file)


# ── Dedup check ──────────────────────────────────────────────────────────────

def _is_duplicate(session_id: str) -> bool:
    """Return True if this session was flushed within FLUSH_COOLDOWN_SECONDS."""
    state = load_flush_state()
    last_ts = state.get(session_id)
    if last_ts is None:
        return False
    elapsed = time.time() - last_ts
    if elapsed < FLUSH_COOLDOWN_SECONDS:
        logger.info(
            "Dedup: session %s flushed %.0fs ago (cooldown %ds) — skipping",
            session_id,
            elapsed,
            FLUSH_COOLDOWN_SECONDS,
        )
        return True
    return False


def _record_flush(session_id: str) -> None:
    """Record this session as flushed now."""
    state = load_flush_state()
    state[session_id] = time.time()
    # Prune entries older than 1 hour to keep the file lean
    cutoff = time.time() - 3600
    state = {k: v for k, v in state.items() if v > cutoff}
    save_flush_state(state)


# ── Compile trigger ──────────────────────────────────────────────────────────

def _maybe_spawn_compile(session_file: Path, hash_before: str | None) -> None:
    """After 6 PM, if the session file changed, spawn compile.py detached."""
    now = datetime.now(timezone.utc).astimezone()
    if now.hour < COMPILE_AFTER_HOUR:
        logger.info("Before %d:00 — skipping compile trigger", COMPILE_AFTER_HOUR)
        return

    if not session_file.exists():
        logger.warning("Session file missing — cannot trigger compile")
        return

    hash_after = file_hash(session_file)
    if hash_before is not None and hash_after == hash_before:
        logger.info("Session file unchanged — skipping compile trigger")
        return

    compile_script = SCRIPTS_DIR / "compile.py"
    if not compile_script.exists():
        logger.warning("compile.py not found at %s — skipping", compile_script)
        return

    guard = Path(os.environ.get("BRAIN_SPAWN_GUARD", str(Path.home() / ".local" / "bin" / "agent-spawn-guard")))
    if guard.exists() and os.access(guard, os.X_OK):
        guard_cmd = [
            str(guard),
            "--name",
            "brain-compile",
            "--min-battery",
            str(SPAWN_MIN_BATTERY),
            "--quiet",
        ]
        allowed = subprocess.run(
            guard_cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        ).returncode == 0
        if not allowed:
            logger.info("Spawn guard skipped compile.py")
            return

    if shutil.which("uv"):
        cmd = [
            "uv", "run",
            "--directory", str(SCRIPTS_DIR.parent),
            "python", str(compile_script),
        ]
    else:
        cmd = [sys.executable, str(compile_script)]
    try:
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        logger.info("Spawned compile.py as detached background process")
    except OSError as exc:
        logger.error("Failed to spawn compile.py: %s", exc)


# ── Agent SDK extraction ─────────────────────────────────────────────────────

async def _extract_knowledge(context: str, project: str, session_id: str) -> str:
    """Call Claude Agent SDK to extract knowledge from conversation context."""
    from claude_agent_sdk import (
        AssistantMessage,
        ClaudeAgentOptions,
        ResultMessage,
        TextBlock,
        query,
    )

    extraction_prompt = EXTRACTION_PROMPT_TEMPLATE.format(
        project=project or "unknown",
        session_id=session_id,
        context=context,
    )

    response = ""
    try:
        async for message in query(
            prompt=extraction_prompt,
            options=ClaudeAgentOptions(
                cwd=str(VAULT_PATH),
                allowed_tools=[],
                max_turns=2,
            ),
        ):
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        response += block.text
    except Exception as exc:
        logger.error("Agent SDK query failed: %s", exc)
        raise

    return response.strip()


# ── Main ─────────────────────────────────────────────────────────────────────

async def main() -> int:
    if len(sys.argv) < 3:
        logger.error("Usage: flush.py <context_file.md> <session_id>")
        print("Usage: flush.py <context_file.md> <session_id>", file=sys.stderr)
        return 1

    context_file = Path(sys.argv[1])
    session_id = sys.argv[2]

    logger.info("flush.py start — session_id=%s context_file=%s", session_id, context_file)

    # ── Dedup check ──────────────────────────────────────────────────────────
    if _is_duplicate(session_id):
        # Clean up temp file even on skip
        if context_file.exists():
            try:
                context_file.unlink()
            except OSError:
                pass
        return 0

    # ── Read context file ────────────────────────────────────────────────────
    if not context_file.exists():
        logger.error("Context file not found: %s", context_file)
        return 1

    try:
        context = context_file.read_text(encoding="utf-8").strip()
    except OSError as exc:
        logger.error("Failed to read context file %s: %s", context_file, exc)
        return 1

    if not context:
        logger.warning("Context file is empty — skipping flush")
        context_file.unlink(missing_ok=True)
        return 0

    # ── Detect project from context file path or CWD encoded in context ──────
    # Context files written by hooks typically include a CWD header line:
    # "CWD: /path/to/project"
    project = ""
    for line in context.splitlines()[:5]:
        if line.startswith("CWD:"):
            cwd_val = line[4:].strip()
            project = detect_project(cwd_val)
            break
    if not project:
        project = detect_project()

    logger.info("Detected project: %r", project)

    # ── Snapshot session file hash before write ───────────────────────────────
    session_file = _session_file_path()
    hash_before: str | None = file_hash(session_file) if session_file.exists() else None

    # ── Call Agent SDK ────────────────────────────────────────────────────────
    logger.info("Calling Agent SDK for extraction...")
    try:
        extracted = await _extract_knowledge(context, project, session_id)
    except Exception as exc:
        logger.error("Extraction failed: %s", exc)
        # Clean up temp file even on failure
        try:
            context_file.unlink(missing_ok=True)
        except OSError:
            pass
        return 1

    logger.info("Extraction complete (%d chars)", len(extracted))

    # ── Check sentinel response ──────────────────────────────────────────────
    if extracted == "FLUSH_OK" or not extracted:
        logger.info("Nothing worth saving — sentinel FLUSH_OK received")
        _record_flush(session_id)
        try:
            context_file.unlink(missing_ok=True)
        except OSError:
            pass
        return 0

    # ── Write to session file ─────────────────────────────────────────────────
    block = _format_session_block(extracted, project, session_id)
    try:
        _append_to_session_file(session_file, block, project)
    except OSError as exc:
        logger.error("Failed to write session file %s: %s", session_file, exc)
        try:
            context_file.unlink(missing_ok=True)
        except OSError:
            pass
        return 1

    # ── Record dedup state ────────────────────────────────────────────────────
    _record_flush(session_id)

    # ── Maybe spawn compile.py ────────────────────────────────────────────────
    _maybe_spawn_compile(session_file, hash_before)

    # ── Clean up temp context file ────────────────────────────────────────────
    try:
        context_file.unlink(missing_ok=True)
        logger.info("Cleaned up temp context file: %s", context_file)
    except OSError as exc:
        logger.warning("Failed to remove context file %s: %s", context_file, exc)

    logger.info(
        "flush.py complete — wrote to %s (session %s)",
        session_file,
        session_id,
    )
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
