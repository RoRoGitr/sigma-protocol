"""
Tests for hq_state.compute_dispatch_prompts() — D1 + D2 contract.

D1 (original) tests:
  - test_placeholder_format: returns dict with 3 required keys
  - test_missing_title_handles_gracefully: no title → sensible default
  - test_prd_doc_arg_accepted: prd_doc kwarg accepted without error
  - test_keys_match_schema: returned keys match dispatch_prompts.schema.json exactly

D2 (new) tests:
  - test_prd_shaped_task_uses_emitters: PRD-shaped task → emitter output matches direct calls
  - test_plain_task_uses_kanban_emitter: plain task → output matches emit_kanban_prompts()
  - test_exception_returns_fallback: mocked emitter raise → fallback string appears
  - test_perf_under_2s_for_3000_tasks: 3000 mixed tasks → total time < 2s
"""

import importlib
import json
import os
import sys
import time
from pathlib import Path
from unittest.mock import patch

import pytest

# Resolve lib path relative to this file so the test works regardless of cwd.
REPO_ROOT = Path(__file__).parent.parent
LIB_DIR = REPO_ROOT / "templates" / "commandboard" / "lib"
EMITTERS_DIR = REPO_ROOT / "scripts" / "emitters"
SCHEMA_PATH = LIB_DIR / "dispatch_prompts.schema.json"
FIXTURES_DIR = REPO_ROOT / "schemas" / "fixtures"

sys.path.insert(0, str(LIB_DIR))
sys.path.insert(0, str(EMITTERS_DIR))

# Lazy imports after paths are set.
import hq_state  # noqa: E402
import emit_kanban_prompt  # noqa: E402
import emit_claude_bundle  # noqa: E402
import emit_codex_bundle  # noqa: E402
import emit_droid_mission  # noqa: E402


SCHEMA_REQUIRED_KEYS = {"claude", "codex", "droid"}

# A valid minimal PRD dict for D2 tests (matches F01.001-sample-valid.json shape).
_SAMPLE_PRD = {
    "prd_id": "F01.001",
    "title": "User authentication with email + password",
    "slug": "user-authentication",
    "goal": {
        "objective": "Ship POST /auth/login + POST /auth/register endpoints with JWT issuance.",
        "stopping_condition": "All tests in tests/auth/*.test.ts pass and curl POST /auth/login returns 200.",
        "files_to_read_first": ["src/auth/index.ts"],
        "proof_commands": ["npm test -- src/auth"],
    },
    "mission": {
        "milestone": "M1: Auth foundation",
        "expected_behavior": (
            "Given a user submits valid credentials, when they hit POST /auth/login, "
            "then the response is 200 with {token, user}."
        ),
        "verification_steps": ["VC-AUTH-001"],
        "fulfills": ["VC-AUTH-001"],
        "skill_name": "backend-engineer",
        "estimated_complexity": "medium",
    },
}


def test_placeholder_format():
    """Returns a dict with exactly 3 string-valued keys."""
    task = {"id": 1, "title": "Ship the auth middleware"}
    result = hq_state.compute_dispatch_prompts(task)
    assert isinstance(result, dict), "compute_dispatch_prompts must return a dict"
    assert set(result.keys()) == SCHEMA_REQUIRED_KEYS, f"Expected keys {SCHEMA_REQUIRED_KEYS}, got {set(result.keys())}"
    for key in SCHEMA_REQUIRED_KEYS:
        assert isinstance(result[key], str), f"Value for '{key}' must be a str"
        assert len(result[key]) > 0, f"Value for '{key}' must be non-empty"
    # Sanity-check that the task title appears in each prompt.
    for key in SCHEMA_REQUIRED_KEYS:
        assert "Ship the auth middleware" in result[key], (
            f"Task title missing from '{key}' prompt: {result[key]!r}"
        )


def test_missing_title_handles_gracefully():
    """Task dict with no 'title' key returns prompts with a sensible default string."""
    task = {"id": 42}
    result = hq_state.compute_dispatch_prompts(task)
    assert isinstance(result, dict)
    assert set(result.keys()) == SCHEMA_REQUIRED_KEYS
    for key in SCHEMA_REQUIRED_KEYS:
        assert isinstance(result[key], str)
        assert len(result[key]) > 0, f"Prompt for '{key}' must not be empty even with no title"


def test_prd_doc_arg_accepted():
    """Passing prd_doc does not raise — D1 ignores it but D2 will use it."""
    task = {"id": 7, "title": "Wire emitters into sync"}
    # Must not raise with prd_doc=None (default)
    result_default = hq_state.compute_dispatch_prompts(task)
    assert isinstance(result_default, dict)

    # Must not raise with an explicit string prd_doc
    result_str = hq_state.compute_dispatch_prompts(task, prd_doc="# PRD content here")
    assert isinstance(result_str, dict)

    # Must not raise with a dict prd_doc (future-proofing for D2's parsed-frontmatter dict)
    result_dict = hq_state.compute_dispatch_prompts(task, prd_doc={"goal": "Deploy auth"})
    assert isinstance(result_dict, dict)


def test_keys_match_schema():
    """Returned keys are exactly the 'required' keys declared in dispatch_prompts.schema.json."""
    assert SCHEMA_PATH.exists(), (
        f"Schema file missing: {SCHEMA_PATH}. Create it before running tests."
    )
    with SCHEMA_PATH.open() as f:
        schema = json.load(f)

    schema_required = set(schema.get("required", []))
    assert schema_required == SCHEMA_REQUIRED_KEYS, (
        f"Schema 'required' {schema_required} differs from expected {SCHEMA_REQUIRED_KEYS}"
    )

    task = {"id": 99, "title": "Validate schema alignment"}
    result = hq_state.compute_dispatch_prompts(task)
    assert set(result.keys()) == schema_required, (
        f"compute_dispatch_prompts returned keys {set(result.keys())} "
        f"but schema requires {schema_required}"
    )


# ── D2 tests ──────────────────────────────────────────────────────────────────


def test_prd_shaped_task_uses_emitters():
    """PRD-shaped task (prd_id + goal + mission) produces output matching direct emitter calls."""
    result = hq_state.compute_dispatch_prompts(_SAMPLE_PRD, workspace="products/sigma-protocol")

    assert set(result.keys()) == SCHEMA_REQUIRED_KEYS

    # Each value must be a non-empty string.
    for key in SCHEMA_REQUIRED_KEYS:
        assert isinstance(result[key], str), f"'{key}' must be str"
        assert len(result[key]) > 0, f"'{key}' must be non-empty"

    # Byte-for-byte match against direct emitter calls.
    expected_claude = emit_claude_bundle.generate(_SAMPLE_PRD)
    expected_codex = emit_codex_bundle.generate(_SAMPLE_PRD)
    expected_droid = emit_droid_mission.generate(_SAMPLE_PRD)

    assert result["claude"] == expected_claude, (
        f"claude prompt mismatch.\nGot:      {result['claude'][:120]!r}\n"
        f"Expected: {expected_claude[:120]!r}"
    )
    assert result["codex"] == expected_codex, (
        f"codex prompt mismatch.\nGot:      {result['codex'][:120]!r}\n"
        f"Expected: {expected_codex[:120]!r}"
    )
    assert result["droid"] == expected_droid, (
        f"droid prompt mismatch.\nGot:      {result['droid'][:120]!r}\n"
        f"Expected: {expected_droid[:120]!r}"
    )

    # PRD bundle has structural markers: XML for claude, markdown # for codex + droid.
    assert "<context>" in result["claude"], "claude bundle missing <context> tag"
    assert "# Objective" in result["codex"], "codex bundle missing '# Objective' heading"
    assert "# Mission:" in result["droid"], "droid bundle missing '# Mission:' heading"


def test_plain_task_uses_kanban_emitter():
    """Plain kanban task (no prd_id/goal/mission) produces output matching emit_kanban_prompts()."""
    task = {
        "id": "KB-42",
        "title": "Refactor auth middleware",
        "description": "Split the monolithic auth handler into composable middleware.",
        "status": "todo",
        "priority": "high",
    }
    workspace = "products/sigma-protocol"

    result = hq_state.compute_dispatch_prompts(task, workspace=workspace)
    assert set(result.keys()) == SCHEMA_REQUIRED_KEYS

    expected = emit_kanban_prompt.emit_kanban_prompts(task, workspace)

    for key in SCHEMA_REQUIRED_KEYS:
        assert result[key] == expected[key], (
            f"'{key}' mismatch.\nGot:      {result[key][:120]!r}\n"
            f"Expected: {expected[key][:120]!r}"
        )

    # Kanban template has recognisable structural elements.
    assert "<task>" in result["claude"], "claude kanban missing <task> tag"
    assert "# Objective" in result["codex"], "codex kanban missing '# Objective' heading"
    assert "# Mission:" in result["droid"], "droid kanban missing '# Mission:' heading"


def test_exception_returns_fallback():
    """When an emitter raises, the fallback string appears and the other keys are unaffected."""
    # Use a PRD-shaped task so the PRD branch is exercised.
    task = dict(_SAMPLE_PRD)

    # Patch emit_claude_bundle.generate to raise inside hq_state's deferred import.
    # We patch the module-level function after it's been imported into the emitters path.
    with patch.object(emit_claude_bundle, "generate", side_effect=RuntimeError("boom")):
        # Also patch the importlib.import_module inside _emit_prd_prompts to return
        # the already-imported (patched) module so the raise propagates correctly.
        original_import = importlib.import_module

        def fake_import(name, *args, **kwargs):
            if name == "emit_claude_bundle":
                return emit_claude_bundle
            if name == "emit_codex_bundle":
                return emit_codex_bundle
            if name == "emit_droid_mission":
                return emit_droid_mission
            return original_import(name, *args, **kwargs)

        with patch("importlib.import_module", side_effect=fake_import):
            result = hq_state.compute_dispatch_prompts(task)

    assert "Error generating claude prompt" in result["claude"], (
        f"Expected fallback in 'claude', got: {result['claude']!r}"
    )
    # The other two CLIs must still produce real content.
    assert "<task>" not in result["claude"] or "Error" in result["claude"]
    assert "# Objective" in result["codex"], "codex should still work when claude fails"
    assert "# Mission:" in result["droid"], "droid should still work when claude fails"


def test_resolver_finds_standalone_install(tmp_path, monkeypatch):
    """Resolver finds emitters in a pure-standalone install layout (no sigma-protocol repo).

    Simulates D5's standalone install: ~/.sigmahq/scripts/emitters/ + ~/.sigmahq/lib/hq_state.py
    with NO co-installed sigma-protocol repo. Verifies _resolve_emitters_dir() returns the
    standalone emitters path, and compute_dispatch_prompts() produces real (not fallback) output.
    """
    # Build a sandbox HOME with the standalone install layout.
    fake_home = tmp_path / "home"
    sigmahq = fake_home / ".sigmahq"
    standalone_emitters = sigmahq / "scripts" / "emitters"
    standalone_emitters.mkdir(parents=True)
    standalone_lib = sigmahq / "lib"
    standalone_lib.mkdir()

    # Copy the real emitter modules into the standalone location.
    for emitter_name in (
        "emit_kanban_prompt.py",
        "emit_claude_bundle.py",
        "emit_codex_bundle.py",
        "emit_droid_mission.py",
    ):
        src = EMITTERS_DIR / emitter_name
        assert src.exists(), f"Source emitter missing: {src}"
        (standalone_emitters / emitter_name).write_bytes(src.read_bytes())

    # Point HOME to the sandbox and clear SIGMAHQ_HOME + the cached repo-relative
    # path resolution. We have to suppress the repo-relative branch by monkeypatching
    # __file__ on the hq_state module to a path inside the sandbox.
    monkeypatch.setenv("HOME", str(fake_home))
    monkeypatch.delenv("SIGMAHQ_HOME", raising=False)

    # Force the resolver to behave as if hq_state is installed standalone:
    # move __file__ into the standalone lib/ so the repo-relative search misses.
    sandbox_hq_state = standalone_lib / "hq_state.py"
    sandbox_hq_state.write_bytes(Path(hq_state.__file__).read_bytes())

    # Patch hq_state's __file__ so the repo-relative search (1st in list) misses.
    monkeypatch.setattr(hq_state, "__file__", str(sandbox_hq_state))

    # Patch Path.home() to return the sandbox HOME so the standalone-install branch matches.
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: fake_home))

    # Re-resolve — should find the standalone emitters via sibling-relative or ~/.sigmahq/ path.
    resolved = hq_state._resolve_emitters_dir()
    assert resolved is not None, (
        "Standalone resolver returned None — emitters not found in sandbox install layout. "
        f"Expected one of: {standalone_emitters} or sibling path."
    )
    assert resolved.is_dir(), f"Resolved path is not a dir: {resolved}"
    assert (resolved / "emit_kanban_prompt.py").exists(), (
        f"Resolved path missing emit_kanban_prompt.py: {resolved}"
    )

    # The resolved path must be within the sandbox (not the real repo).
    assert str(fake_home) in str(resolved), (
        f"Resolver leaked outside sandbox HOME. Expected path under {fake_home}, got {resolved}"
    )

    # Now exercise compute_dispatch_prompts end-to-end — must return REAL output (no fallback).
    # Clear emitters from sys.path so the test forces the resolver to re-add the standalone path.
    saved_path = list(sys.path)
    try:
        sys.path[:] = [p for p in sys.path if "emitters" not in p]
        # Also evict the cached emitter modules so importlib.import_module re-resolves them
        # from the standalone path.
        for mod_name in (
            "emit_kanban_prompt",
            "emit_claude_bundle",
            "emit_codex_bundle",
            "emit_droid_mission",
        ):
            sys.modules.pop(mod_name, None)

        task = {"title": "standalone parity test", "id": "001"}
        result = hq_state.compute_dispatch_prompts(task, workspace="test")

        assert set(result.keys()) == SCHEMA_REQUIRED_KEYS
        for key in SCHEMA_REQUIRED_KEYS:
            assert "Error generating" not in result[key], (
                f"Standalone resolver still triggers fallback for '{key}': {result[key][:160]!r}"
            )
            assert "emitters directory not found" not in result[key], (
                f"Standalone resolver returned 'not found' for '{key}': {result[key][:160]!r}"
            )
            assert "standalone parity test" in result[key], (
                f"Standalone prompt missing task title for '{key}': {result[key][:160]!r}"
            )
    finally:
        sys.path[:] = saved_path


def test_perf_under_2s_for_3000_tasks():
    """3000 mixed tasks (10% PRD-shaped, 90% plain kanban) complete under 2 seconds total."""
    # Build a mix of 300 PRD-shaped + 2700 plain kanban tasks.
    prd_task = dict(_SAMPLE_PRD)  # PRD-shaped
    plain_task = {
        "id": "KB-PERF",
        "title": "Performance test task",
        "description": "A plain kanban task for perf measurement.",
        "status": "todo",
        "priority": "medium",
    }
    tasks = [prd_task] * 300 + [plain_task] * 2700

    start = time.perf_counter()
    for task in tasks:
        hq_state.compute_dispatch_prompts(task, workspace="perf-workspace")
    elapsed = time.perf_counter() - start

    assert elapsed < 2.0, (
        f"compute_dispatch_prompts for 3000 tasks took {elapsed:.3f}s (budget: 2.0s). "
        "Consider adding ThreadPoolExecutor for the PRD branch."
    )
