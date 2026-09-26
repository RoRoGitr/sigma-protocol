"""
Tests for scripts/emitters/emit_codex_bundle.py

TDD: these tests are written BEFORE the implementation.
All 6 must pass after emit_codex_bundle.py is implemented.

Key Codex differences enforced here:
  - Role-frame opener ("You are a...") NOT XML tags
  - NO <context>, <task>, <requirements> etc. XML tags
  - Numbered lists for files + plan + proof
  - apply_patch mention in working-style block
  - <=4000 char output limit
  - Objective + Done-when NEVER truncated
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent.parent
EMITTER = REPO_ROOT / "scripts" / "emitters" / "emit_codex_bundle.py"
FIXTURES = REPO_ROOT / "schemas" / "fixtures"

VALID_FIXTURE = FIXTURES / "F01.001-sample-valid.json"
MINIMAL_FIXTURE = FIXTURES / "F01.001-sample-minimal.json"

CHAR_LIMIT = 4000

# XML tags that must NOT appear in Codex bundles (Claude-specific pattern)
FORBIDDEN_XML_TAGS = [
    "<context>", "</context>",
    "<task>", "</task>",
    "<requirements>", "</requirements>",
    "<constraints>", "</constraints>",
    "<done-when>", "</done-when>",
]

# Markdown sections that MUST appear (Codex uses headings, not XML)
REQUIRED_HEADINGS = [
    "# Objective",
    "# Files to read FIRST",
    "# Implementation plan",
    "# Done when",
    "# Proof of progress",
    "# Working style",
]


def run_emitter(*args: str) -> subprocess.CompletedProcess:
    cmd = [sys.executable, str(EMITTER)] + list(args)
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(REPO_ROOT),
    )


class TestMinimalPrd:
    """test_minimal_prd: bundle has role-frame opener, no XML tags, <=4000 chars."""

    def test_role_frame_opener(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"emitter failed:\n{result.stderr}"
        output_files = list(outdir.glob("*.goal.md"))
        assert len(output_files) == 1, f"Expected 1 output file, got: {output_files}"
        content = output_files[0].read_text()
        # Must start with "You are a senior engineer"
        assert content.startswith("You are a senior engineer"), (
            f"Bundle must start with role-frame opener. Got:\n{content[:200]}"
        )

    def test_no_xml_tags_in_output(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for tag in FORBIDDEN_XML_TAGS:
            assert tag not in content, (
                f"Forbidden XML tag '{tag}' found in Codex bundle.\n\nBundle:\n{content}"
            )

    def test_within_char_limit(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        assert len(content) <= CHAR_LIMIT, (
            f"Bundle is {len(content)} chars, exceeds {CHAR_LIMIT} limit."
        )

    def test_output_filename_uses_prd_id(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        prd = json.loads(MINIMAL_FIXTURE.read_text())
        prd_id = prd["prd_id"]
        run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        expected = outdir / f"{prd_id}.goal.md"
        assert expected.exists(), f"Expected {expected} to exist"


class TestFullPrd:
    """test_full_prd: all sections present, numbered lists for files + plan + proof."""

    def test_all_required_headings_present(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"emitter failed:\n{result.stderr}"
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for heading in REQUIRED_HEADINGS:
            assert heading in content, (
                f"Required heading missing: '{heading}'\n\nBundle:\n{content}"
            )

    def test_files_to_read_are_numbered(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        prd = json.loads(VALID_FIXTURE.read_text())
        files = prd["goal"]["files_to_read_first"]
        if files:
            # At least one file should appear as "1. <filename>"
            assert "1. " in content, (
                f"Files should be numbered (e.g. '1. src/auth/index.ts')\n\nBundle:\n{content}"
            )

    def test_implementation_plan_uses_numbered_list(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        # Valid PRD has slices — they should appear numbered
        prd = json.loads(VALID_FIXTURE.read_text())
        if prd.get("slices"):
            assert "1. " in content, (
                "Implementation plan items should be numbered\n\nBundle:\n{content}"
            )

    def test_proof_commands_numbered(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        prd = json.loads(VALID_FIXTURE.read_text())
        proof_cmds = prd["goal"].get("proof_commands", [])
        if proof_cmds:
            # Proof commands should appear as numbered list
            assert "1. " in content, (
                "Proof commands should be numbered\n\nBundle:\n{content}"
            )

    def test_apply_patch_mentioned(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        assert "apply_patch" in content, (
            "Codex bundle must mention 'apply_patch' in working-style block\n\nBundle:\n{content}"
        )

    def test_within_char_limit(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        assert len(content) <= CHAR_LIMIT, (
            f"Bundle is {len(content)} chars, exceeds {CHAR_LIMIT} limit."
        )

    def test_no_xml_tags(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for tag in FORBIDDEN_XML_TAGS:
            assert tag not in content, (
                f"Forbidden XML tag '{tag}' found in Codex bundle.\n\nBundle:\n{content}"
            )


class TestInvalidPrdFails:
    """test_invalid_prd_fails: invalid PRD exits 2."""

    def test_missing_goal_exits_2(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        del prd["goal"]
        bad_prd = tmp_path / "bad.json"
        bad_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2, (
            f"Expected exit 2 for invalid PRD, got {result.returncode}.\nstderr: {result.stderr}"
        )

    def test_invalid_prd_id_exits_2(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        prd["prd_id"] = "NOT VALID"
        bad_prd = tmp_path / "bad2.json"
        bad_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2

    def test_not_json_exits_2(self, tmp_path):
        bad_prd = tmp_path / "bad3.json"
        bad_prd.write_text("this is not json {{{")
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2

    def test_error_message_on_stderr(self, tmp_path):
        prd = json.loads(VALID_FIXTURE.read_text())
        del prd["mission"]
        bad_prd = tmp_path / "bad4.json"
        bad_prd.write_text(json.dumps(prd))
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(bad_prd), "--output-dir", str(outdir))
        assert result.returncode == 2
        assert len(result.stderr.strip()) > 0, "Expected error message on stderr"


class TestOversizedTruncates:
    """test_oversized_truncates: <=4000 chars + WARN, Objective + Done-when preserved."""

    def _make_fat_prd(self, tmp_path: Path, suffix: str = "") -> Path:
        prd = json.loads(VALID_FIXTURE.read_text())
        # Blow out working-style section would be internal — blow files_to_read_first
        prd["goal"]["files_to_read_first"] = [
            f"src/really/long/path/to/some/file/number/{i}/that/is/verbose/indeed.ts"
            for i in range(200)
        ]
        fat_prd = tmp_path / f"fat{suffix}.json"
        fat_prd.write_text(json.dumps(prd))
        return fat_prd

    def test_truncated_bundle_within_limit(self, tmp_path):
        fat_prd = self._make_fat_prd(tmp_path, "1")
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(fat_prd), "--output-dir", str(outdir))
        assert result.returncode == 0, f"emitter failed:\n{result.stderr}"
        output_files = list(outdir.glob("*.goal.md"))
        assert output_files, "No output file produced"
        content = output_files[0].read_text()
        assert len(content) <= CHAR_LIMIT, (
            f"Truncated bundle is still {len(content)} chars > {CHAR_LIMIT}"
        )

    def test_warning_emitted_to_stderr_on_truncation(self, tmp_path):
        fat_prd = self._make_fat_prd(tmp_path, "2")
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(fat_prd), "--output-dir", str(outdir))
        assert result.returncode == 0
        assert "WARNING" in result.stderr or "truncat" in result.stderr.lower(), (
            f"Expected truncation warning in stderr, got:\n{result.stderr}"
        )

    def test_objective_preserved_after_truncation(self, tmp_path):
        fat_prd = self._make_fat_prd(tmp_path, "3")
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(fat_prd), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        prd = json.loads(VALID_FIXTURE.read_text())
        # Objective must never be truncated — check first 40 chars appear
        assert prd["goal"]["objective"][:40] in content, (
            "Objective must be preserved even after truncation"
        )

    def test_done_when_preserved_after_truncation(self, tmp_path):
        fat_prd = self._make_fat_prd(tmp_path, "4")
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(fat_prd), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        prd = json.loads(VALID_FIXTURE.read_text())
        # stopping_condition must never be truncated
        assert prd["goal"]["stopping_condition"][:40] in content, (
            "Done-when (stopping_condition) must be preserved even after truncation"
        )

    def test_no_xml_tags_after_truncation(self, tmp_path):
        fat_prd = self._make_fat_prd(tmp_path, "5")
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(fat_prd), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for tag in FORBIDDEN_XML_TAGS:
            assert tag not in content, (
                f"Forbidden XML tag '{tag}' found after truncation.\n\nBundle:\n{content}"
            )


class TestIdempotent:
    """test_idempotent: byte-identical output on re-runs."""

    def test_byte_identical_output(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        output_file = list(outdir.glob("*.goal.md"))[0]
        first_content = output_file.read_bytes()

        # Second run overwrites
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        second_content = output_file.read_bytes()

        assert first_content == second_content, (
            "Second run produced different output — emitter is not idempotent"
        )

    def test_validate_mode_does_not_write_file(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir), "--validate")
        assert result.returncode == 0, f"--validate mode failed:\n{result.stderr}"
        output_files = list(outdir.glob("*.goal.md"))
        assert len(output_files) == 0, "--validate should not write files"
        assert "VALID" in result.stdout and "chars" in result.stdout, (
            f"Expected 'VALID ... chars ...' in stdout, got:\n{result.stdout}"
        )


class TestNoXmlTags:
    """test_no_xml_tags: grep output for <...> XML tag patterns returns nothing (Codex hates them)."""

    def test_no_xml_opening_tags_in_valid_output(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for tag in FORBIDDEN_XML_TAGS:
            assert tag not in content, (
                f"XML tag '{tag}' must not appear in Codex bundle (Claude-only pattern).\n"
                f"Bundle:\n{content}"
            )

    def test_no_xml_tags_in_minimal_output(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        content = list(outdir.glob("*.goal.md"))[0].read_text()
        for tag in FORBIDDEN_XML_TAGS:
            assert tag not in content, (
                f"XML tag '{tag}' must not appear in Codex bundle.\nBundle:\n{content}"
            )

    def test_validate_mode_output_no_xml_tags(self, tmp_path):
        outdir = tmp_path / "codex"
        outdir.mkdir()
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir), "--validate")
        assert result.returncode == 0
        # --validate prints the bundle to stdout; check that too
        for tag in FORBIDDEN_XML_TAGS:
            assert tag not in result.stdout, (
                f"XML tag '{tag}' found in --validate stdout output."
            )
