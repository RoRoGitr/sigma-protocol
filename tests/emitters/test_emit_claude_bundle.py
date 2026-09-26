"""
Tests for scripts/emitters/emit_claude_bundle.py

TDD: these tests are written BEFORE the implementation.
All 5 must pass after emit_claude_bundle.py is implemented.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent.parent
EMITTER = REPO_ROOT / "scripts" / "emitters" / "emit_claude_bundle.py"
FIXTURES = REPO_ROOT / "schemas" / "fixtures"
DISPATCH_DIR = REPO_ROOT / ".sigma" / "dispatch" / "claude"
SCHEMA_PATH = REPO_ROOT / "schemas" / "sigma-prd-canonical.schema.json"

VALID_FIXTURE = FIXTURES / "F01.001-sample-valid.json"
MINIMAL_FIXTURE = FIXTURES / "F01.001-sample-minimal.json"

REQUIRED_XML_TAGS = ["<context>", "</context>", "<task>", "</task>",
                     "<requirements>", "</requirements>", "<proof>", "</proof>",
                     "<constraints>", "</constraints>", "<done-when>", "</done-when>"]

CHAR_LIMIT = 4000


def run_emitter(*args: str, capture_stderr: bool = True) -> subprocess.CompletedProcess:
    cmd = [sys.executable, str(EMITTER)] + list(args)
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(REPO_ROOT),
    )


class TestMinimalPrd:
    """test_minimal_prd: bundle generated, all 6 XML sections present."""

    def test_all_six_xml_tags_present(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"emitter failed:\n{result.stderr}"
        output_files = list(outdir.glob("*.goal.md"))
        assert len(output_files) == 1, f"Expected 1 output file, got: {output_files}"
        content = output_files[0].read_text()
        for tag in REQUIRED_XML_TAGS:
            assert tag in content, f"Missing XML tag: {tag}\n\nBundle:\n{content}"

    def test_output_filename_uses_prd_id(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        prd = json.loads(MINIMAL_FIXTURE.read_text())
        prd_id = prd["prd_id"]
        run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        expected = outdir / f"{prd_id}.goal.md"
        assert expected.exists(), f"Expected {expected} to exist"


class TestFullPrd:
    """test_full_prd: bundle generated, all fields populated, <=4000 chars."""

    def test_all_fields_populated(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"emitter failed:\n{result.stderr}"
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for tag in REQUIRED_XML_TAGS:
            assert tag in content, f"Missing tag: {tag}"

    def test_within_char_limit(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        assert len(content) <= CHAR_LIMIT, (
            f"Bundle is {len(content)} chars, exceeds {CHAR_LIMIT} limit.\n\n{content}"
        )

    def test_objective_present_in_task_section(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        prd = json.loads(VALID_FIXTURE.read_text())
        # The objective should appear somewhere in the bundle
        # (may be truncated if over budget but at least partially)
        assert prd["goal"]["objective"][:40] in content, "objective text missing from bundle"

    def test_stopping_condition_present(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        prd = json.loads(VALID_FIXTURE.read_text())
        assert prd["goal"]["stopping_condition"][:40] in content, (
            "stopping_condition text missing from done-when section"
        )


class TestInvalidPrdFails:
    """test_invalid_prd_fails: invalid PRD exits 2 with schema error message."""

    def test_missing_required_field_exits_2(self, tmp_path):
        # Remove required 'goal' block
        prd = json.loads(VALID_FIXTURE.read_text())
        del prd["goal"]
        bad_prd = tmp_path / "bad.json"
        bad_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2, (
            f"Expected exit 2 for invalid PRD, got {result.returncode}.\nstderr: {result.stderr}"
        )

    def test_invalid_prd_id_pattern_exits_2(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        prd["prd_id"] = "invalid prd id with spaces"
        bad_prd = tmp_path / "bad2.json"
        bad_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2, (
            f"Expected exit 2 for invalid prd_id, got {result.returncode}.\nstderr: {result.stderr}"
        )

    def test_error_message_on_stderr(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        del prd["mission"]
        bad_prd = tmp_path / "bad3.json"
        bad_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2
        assert len(result.stderr.strip()) > 0, "Expected error message on stderr"

    def test_not_json_exits_2(self, tmp_path):
        bad_prd = tmp_path / "bad4.json"
        bad_prd.write_text("this is not json {{{")
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2


class TestOversizedPrdTruncates:
    """test_oversized_prd_truncates: huge files_to_read_first produces <=4000 char bundle + warning."""

    def test_truncated_bundle_within_limit(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        # Add 200 huge file paths to blow the budget
        prd["goal"]["files_to_read_first"] = [
            f"src/really/long/path/to/some/file/number/{i}/that/is/very/verbose/indeed/filename.ts"
            for i in range(200)
        ]
        fat_prd = tmp_path / "fat.json"
        fat_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(fat_prd), "--output-dir", str(outdir))
        assert result.returncode == 0, f"emitter failed:\n{result.stderr}"
        output_files = list(outdir.glob("*.goal.md"))
        assert output_files, "No output file produced"
        content = output_files[0].read_text()
        assert len(content) <= CHAR_LIMIT, (
            f"Truncated bundle is still {len(content)} chars > {CHAR_LIMIT}"
        )

    def test_warning_emitted_to_stderr(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        prd["goal"]["files_to_read_first"] = [
            f"src/really/long/path/to/file/number/{i}/something.ts" for i in range(200)
        ]
        fat_prd = tmp_path / "fat2.json"
        fat_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(fat_prd), "--output-dir", str(outdir))
        assert result.returncode == 0
        assert "WARNING" in result.stderr or "truncat" in result.stderr.lower(), (
            f"Expected truncation warning in stderr, got:\n{result.stderr}"
        )

    def test_all_xml_tags_still_present_after_truncation(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        prd["goal"]["files_to_read_first"] = [
            f"src/verbose/path/{i}/file.ts" for i in range(200)
        ]
        fat_prd = tmp_path / "fat3.json"
        fat_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "claude"
        outdir.mkdir()
        run_emitter(str(fat_prd), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for tag in REQUIRED_XML_TAGS:
            assert tag in content, f"Missing tag after truncation: {tag}"


class TestIdempotent:
    """test_idempotent: run twice, byte-identical output."""

    def test_byte_identical_output(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        # First run
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        output_file = list(outdir.glob("*.goal.md"))[0]
        first_content = output_file.read_bytes()

        # Second run (overwrites)
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        second_content = output_file.read_bytes()

        assert first_content == second_content, (
            "Second run produced different output — emitter is not idempotent"
        )

    def test_validate_mode_does_not_write_file(self, tmp_path):
        outdir = tmp_path / "claude"
        outdir.mkdir()
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir), "--validate")
        assert result.returncode == 0, f"--validate mode failed:\n{result.stderr}"
        output_files = list(outdir.glob("*.goal.md"))
        assert len(output_files) == 0, "--validate should not write files"
        # Should print bundle + char count line
        assert "VALID" in result.stdout and "chars" in result.stdout, (
            f"Expected 'VALID ... chars ...' in stdout, got:\n{result.stdout}"
        )
