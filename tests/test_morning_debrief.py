"""
Tests for scripts/morning-debrief.py

5 tests:
  test_empty_overnight_dir        — no runs found → "No overnight runs" message, exit 0
  test_full_overnight_with_questions — fixture dir with 2 Qs + 1 run.json → all sections present
  test_failed_prds_shown          — run.json with PRDs_failed → "## PRDs failed" section present
  test_no_questions               — run.json with deferred_question_count=0 → Q section omitted or "None pending"
  test_json_format                — --format=json → parseable JSON with required fields
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path

SCRIPT = Path(__file__).parent.parent / "scripts" / "morning-debrief.py"
FIXTURES = Path(__file__).parent / "fixtures" / "overnight"


def run_script(*args: str, target_dir: Path | None = None, cwd: Path | None = None):
    """Run morning-debrief.py and return (returncode, stdout, stderr)."""
    cmd = [sys.executable, str(SCRIPT)]
    if target_dir is not None:
        cmd += [f"--target-dir={target_dir}"]
    cmd += list(args)
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(cwd or Path(__file__).parent.parent),
    )
    return result.returncode, result.stdout, result.stderr


# ---------------------------------------------------------------------------
# test_empty_overnight_dir
# ---------------------------------------------------------------------------

def test_empty_overnight_dir(tmp_path):
    """Empty dir → exit 0, prints 'No overnight runs' message."""
    empty_dir = tmp_path / "overnight"
    empty_dir.mkdir()

    rc, out, err = run_script(target_dir=empty_dir)

    assert rc == 0, f"Expected exit 0, got {rc}. stderr: {err}"
    assert "No overnight runs" in out, f"Expected 'No overnight runs' in output:\n{out}"


# ---------------------------------------------------------------------------
# test_full_overnight_with_questions
# ---------------------------------------------------------------------------

def test_full_overnight_with_questions():
    """Fixture dir with 2 deferred Qs + run.json → all required sections present."""
    rc, out, err = run_script(target_dir=FIXTURES)

    assert rc == 0, f"Expected exit 0, got {rc}. stderr: {err}"

    required_sections = [
        "## Run summary",
        "## Deferred questions",
        "## PRDs completed",
        "## PRDs failed",
        "## Next actions",
    ]
    for section in required_sections:
        assert section in out, f"Missing section '{section}' in output:\n{out}"

    # Deferred question content
    assert "F01.003" in out, "Expected PRD id F01.003 in output"
    assert "F02.001" in out or "Droid mission" in out, "Expected PRD F02.001 reference"

    # Run summary fields
    assert "2026-05-23" in out, "Expected date in output"
    assert "claude" in out.lower(), "Expected CLI name in output"


# ---------------------------------------------------------------------------
# test_failed_prds_shown
# ---------------------------------------------------------------------------

def test_failed_prds_shown():
    """run.json with PRDs_failed populated → '## PRDs failed' section present."""
    rc, out, err = run_script(target_dir=FIXTURES)

    assert rc == 0, f"Expected exit 0, got {rc}. stderr: {err}"
    assert "## PRDs failed" in out, f"Expected '## PRDs failed' section:\n{out}"
    # Error tail should appear
    assert "F02.001" in out or "Droid mission emitter" in out, (
        f"Expected failed PRD detail in output:\n{out}"
    )


# ---------------------------------------------------------------------------
# test_no_questions
# ---------------------------------------------------------------------------

def test_no_questions(tmp_path):
    """run.json with deferred_question_count=0 → Q section omitted or 'None pending'."""
    overnight_dir = tmp_path / "overnight"
    overnight_dir.mkdir()

    run_json = {
        "started_at": "2026-05-23T01:00:00Z",
        "ended_at": "2026-05-23T03:00:00Z",
        "cli": "codex",
        "PRDs_completed": [
            {"id": "F01.001", "title": "Scaffold", "commit": "aaa1111", "duration_s": 200}
        ],
        "PRDs_failed": [],
        "deferred_question_count": 0,
        "exit_code": 0,
    }
    (overnight_dir / "run-001.json").write_text(json.dumps(run_json))

    rc, out, err = run_script(target_dir=overnight_dir)

    assert rc == 0, f"Expected exit 0, got {rc}. stderr: {err}"

    # Either the section is absent or it shows "None pending"
    if "## Deferred questions" in out:
        assert "None pending" in out or "none" in out.lower(), (
            f"Deferred Q section present but no 'None pending' text:\n{out}"
        )


# ---------------------------------------------------------------------------
# test_json_format
# ---------------------------------------------------------------------------

def test_json_format():
    """--format=json → parseable JSON with required top-level fields."""
    rc, out, err = run_script("--format=json", target_dir=FIXTURES)

    assert rc == 0, f"Expected exit 0, got {rc}. stderr: {err}"

    try:
        data = json.loads(out)
    except json.JSONDecodeError as exc:
        raise AssertionError(f"Output is not valid JSON: {exc}\nOutput:\n{out}") from exc

    required_keys = ["run_summary", "commits_shipped", "prds_completed", "prds_failed",
                     "deferred_questions", "next_actions"]
    for key in required_keys:
        assert key in data, f"Missing key '{key}' in JSON output. Keys: {list(data.keys())}"
