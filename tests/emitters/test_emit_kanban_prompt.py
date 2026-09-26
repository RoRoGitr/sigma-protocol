"""
tests/emitters/test_emit_kanban_prompt.py

6 pytest tests for emit_kanban_prompt.py (D3, Sigma Protocol 3.0.3).

TDD: written BEFORE the implementation (RED → GREEN).
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

# Import the module under test
from scripts.emitters.emit_kanban_prompt import emit_kanban_prompts

SCHEMA_PATH = (
    Path(__file__).parent.parent.parent
    / "templates"
    / "commandboard"
    / "lib"
    / "dispatch_prompts.schema.json"
)

# ─────────────────────────────────────────────────────────────────────────────
# Fixtures
# ─────────────────────────────────────────────────────────────────────────────

MINIMAL_TASK: dict = {"title": "Fix the login bug"}

FULL_TASK: dict = {
    "id": "042",
    "title": "Refactor auth middleware",
    "description": "Extract JWT validation into its own module. Add unit tests.",
    "priority": "high",
    "status": "todo",
    "skill": "backend-engineer",
    "assignee": "backend-engineer",
}


# ─────────────────────────────────────────────────────────────────────────────
# Test 1: dict has exactly claude / codex / droid keys
# ─────────────────────────────────────────────────────────────────────────────

def test_three_keys_returned() -> None:
    result = emit_kanban_prompts(MINIMAL_TASK, workspace="products/sigma-protocol")
    assert set(result.keys()) == {"claude", "codex", "droid"}, (
        f"Expected exactly 3 keys (claude, codex, droid), got: {set(result.keys())}"
    )


# ─────────────────────────────────────────────────────────────────────────────
# Test 2: task with only title produces valid (non-empty) prompts
# ─────────────────────────────────────────────────────────────────────────────

def test_minimal_task() -> None:
    result = emit_kanban_prompts({"title": "Write changelog"}, workspace="ws/a")
    for cli in ("claude", "codex", "droid"):
        assert isinstance(result[cli], str), f"{cli} must be a string"
        assert len(result[cli]) > 0, f"{cli} must be non-empty"
        assert "Write changelog" in result[cli], (
            f"{cli} prompt must contain the task title"
        )


# ─────────────────────────────────────────────────────────────────────────────
# Test 3: full task — all fields appear in prompts
# ─────────────────────────────────────────────────────────────────────────────

def test_full_task() -> None:
    result = emit_kanban_prompts(FULL_TASK, workspace="products/sigma-protocol")
    for cli in ("claude", "codex", "droid"):
        prompt = result[cli]
        assert "042" in prompt, f"{cli}: task id '042' must appear"
        assert "Refactor auth middleware" in prompt, f"{cli}: title must appear"
        assert "products/sigma-protocol" in prompt, f"{cli}: workspace must appear"
    # description should appear in at least claude + codex
    assert "JWT validation" in result["claude"], "claude: description must appear"
    assert "JWT validation" in result["codex"], "codex: description must appear"


# ─────────────────────────────────────────────────────────────────────────────
# Test 4: HTML escaping in claude XML, NOT in codex/droid
# ─────────────────────────────────────────────────────────────────────────────

def test_html_escape_claude_xml() -> None:
    task = {"title": "Fix <button> & <input>", "id": "001"}
    result = emit_kanban_prompts(task, workspace="ws/b")

    # Claude (XML) — must escape
    assert "&lt;button&gt;" in result["claude"], (
        "claude: '<button>' must be HTML-escaped to '&lt;button&gt;'"
    )
    assert "&amp;" in result["claude"], (
        "claude: '&' must be HTML-escaped to '&amp;'"
    )

    # Codex and Droid (markdown) — must NOT escape
    assert "<button>" in result["codex"], (
        "codex: '<button>' must NOT be escaped (markdown, not XML)"
    )
    assert "<button>" in result["droid"], (
        "droid: '<button>' must NOT be escaped (markdown, not XML)"
    )


# ─────────────────────────────────────────────────────────────────────────────
# Test 5: each prompt is ≤ 2000 chars
# ─────────────────────────────────────────────────────────────────────────────

def test_each_prompt_under_2000_chars() -> None:
    # Use a task with long description to stress the limit
    long_desc = "A" * 800
    task = {
        "id": "999",
        "title": "A" * 200,
        "description": long_desc,
        "priority": "low",
        "status": "todo",
        "skill": "general",
    }
    result = emit_kanban_prompts(task, workspace="stress/test")
    for cli in ("claude", "codex", "droid"):
        length = len(result[cli])
        assert length <= 2000, (
            f"{cli} prompt is {length} chars — exceeds 2000-char limit"
        )


# ─────────────────────────────────────────────────────────────────────────────
# Test 6: return dict matches dispatch_prompts.schema.json
# ─────────────────────────────────────────────────────────────────────────────

def test_keys_match_d1_schema() -> None:
    assert SCHEMA_PATH.exists(), (
        f"Schema not found at {SCHEMA_PATH} — D1 must ship before D3 tests run"
    )
    schema = json.loads(SCHEMA_PATH.read_text())

    result = emit_kanban_prompts(FULL_TASK, workspace="products/sigma-protocol")

    # Schema requires these exact keys with no additionals
    required = set(schema.get("required", []))
    assert required == {"claude", "codex", "droid"}, (
        f"Schema required keys changed: {required}"
    )
    # No extra keys
    assert set(result.keys()) == required, (
        f"Result keys {set(result.keys())} don't match schema required {required}"
    )
    # All values are strings (per schema type: "string")
    for key in required:
        prop_type = schema["properties"][key]["type"]
        assert prop_type == "string", f"Schema: {key} must be type string"
        assert isinstance(result[key], str), f"Result: {key} must be a str"
