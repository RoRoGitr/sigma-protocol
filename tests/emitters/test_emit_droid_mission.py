"""
Tests for scripts/emitters/emit_droid_mission.py

TDD: these tests are written BEFORE the implementation.
All 5 must pass after emit_droid_mission.py is implemented.
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
EMITTER = REPO_ROOT / "scripts" / "emitters" / "emit_droid_mission.py"
FIXTURES = REPO_ROOT / "schemas" / "fixtures"

VALID_FIXTURE = FIXTURES / "F01.001-sample-valid.json"
MINIMAL_FIXTURE = FIXTURES / "F01.001-sample-minimal.json"

# Factory features.json required fields (from reverse-engineered orchestrator prompt)
FEATURES_REQUIRED_FIELDS = [
    "id",
    "description",
    "skillName",
    "milestone",
    "preconditions",
    "expectedBehavior",
    "verificationSteps",
    "fulfills",
    "status",
]

FEATURES_STATUS_ENUM = {"pending", "in_progress", "done", "failed"}

# Required H2 sections in mission.md
MISSION_H2_SECTIONS = ["## Goal", "## Scope", "## Success criteria", "## Required reading"]

# Expected 4-file bundle inside .sigma/dispatch/droid/<slug>/
EXPECTED_FILES = {"mission.md", "features.json", "validation-contract.md"}
EXPECTED_FACTORY_DIR = ".factory"
EXPECTED_SERVICES_YAML = ".factory/services.yaml"


def run_emitter(*args: str) -> subprocess.CompletedProcess:
    cmd = [sys.executable, str(EMITTER)] + list(args)
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(REPO_ROOT),
    )


def get_bundle_dir(output_dir: Path, slug: str) -> Path:
    return output_dir / slug


class TestMinimalPrd:
    """test_minimal_prd: 4 output files generated, all required sections present."""

    def test_generates_four_output_files(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"Emitter failed:\n{result.stderr}"

        # slug for F01.001-sample-minimal.json is "password-reset"
        bundle = get_bundle_dir(outdir, "password-reset")
        assert bundle.exists(), f"Bundle dir not created: {bundle}"

        for fname in EXPECTED_FILES:
            assert (bundle / fname).exists(), f"Missing file: {fname}"

        factory_dir = bundle / EXPECTED_FACTORY_DIR
        assert factory_dir.exists(), f".factory/ dir missing"
        assert (bundle / EXPECTED_SERVICES_YAML).exists(), "Missing .factory/services.yaml"

    def test_mission_md_has_required_h2_sections(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0

        bundle = get_bundle_dir(outdir, "password-reset")
        mission_text = (bundle / "mission.md").read_text()

        for section in MISSION_H2_SECTIONS:
            assert section in mission_text, f"mission.md missing section: {section!r}"

    def test_features_json_single_feature_with_required_fields(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0

        bundle = get_bundle_dir(outdir, "password-reset")
        features_data = json.loads((bundle / "features.json").read_text())

        assert "features" in features_data, "features.json missing 'features' key"
        features = features_data["features"]
        assert len(features) == 1, f"Expected 1 feature, got {len(features)}"

        feature = features[0]
        missing = [k for k in FEATURES_REQUIRED_FIELDS if k not in feature]
        assert not missing, f"features.json feature missing required fields: {missing}"

    def test_validation_contract_has_assertions(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0

        bundle = get_bundle_dir(outdir, "password-reset")
        vc_text = (bundle / "validation-contract.md").read_text()

        assert "# Validation Contract:" in vc_text, "Missing validation contract header"
        assert "## Assertions" in vc_text, "Missing ## Assertions section"
        # Should have at least one assertion block
        assert "VC-" in vc_text, "No VC-* assertion IDs found"
        assert "GIVEN" in vc_text or "Given" in vc_text, "No GIVEN clause found"

    def test_services_yaml_stub_present(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0

        bundle = get_bundle_dir(outdir, "password-reset")
        services_text = (bundle / ".factory" / "services.yaml").read_text()

        assert "services:" in services_text, ".factory/services.yaml missing 'services:' key"


class TestFullPrdWithSlices:
    """test_full_prd_with_slices: features.json has one feature per slice."""

    def test_features_json_has_one_feature_per_slice(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"Emitter failed:\n{result.stderr}"

        # VALID_FIXTURE has 4 slices (F01.001.a, .b, .c, .d)
        bundle = get_bundle_dir(outdir, "user-authentication")
        features_data = json.loads((bundle / "features.json").read_text())

        features = features_data["features"]
        assert len(features) == 4, f"Expected 4 features (one per slice), got {len(features)}"

    def test_slice_ids_used_in_features(self, tmp_path):
        outdir = tmp_path / "droid"
        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))

        bundle = get_bundle_dir(outdir, "user-authentication")
        features_data = json.loads((bundle / "features.json").read_text())
        feature_ids = [f["id"] for f in features_data["features"]]

        assert "F01.001.a" in feature_ids, "Slice F01.001.a not found in feature IDs"
        assert "F01.001.d" in feature_ids, "Slice F01.001.d not found in feature IDs"

    def test_mission_md_generated_for_sliced_prd(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0

        bundle = get_bundle_dir(outdir, "user-authentication")
        mission_text = (bundle / "mission.md").read_text()

        # Mission should contain the PRD title
        assert "User authentication with email + password" in mission_text


class TestInvalidPrdFails:
    """test_invalid_prd_fails: exit 2 with schema error message."""

    def test_missing_required_field_exits_2(self, tmp_path):
        # Craft an invalid PRD (missing 'mission' block)
        invalid_prd = {
            "prd_id": "F99.001",
            "title": "Bad PRD",
            "slug": "bad-prd",
            "goal": {
                "objective": "This PRD is intentionally invalid.",
                "stopping_condition": "Never.",
                "files_to_read_first": [],
                "proof_commands": [],
            },
            # 'mission' block is MISSING — should fail schema validation
        }
        bad_file = tmp_path / "bad.json"
        bad_file.write_text(json.dumps(invalid_prd))

        outdir = tmp_path / "droid"
        result = run_emitter(str(bad_file), "--output-dir", str(outdir))
        assert result.returncode == 2, (
            f"Expected exit 2 for invalid PRD, got {result.returncode}.\n"
            f"stderr: {result.stderr}\nstdout: {result.stdout}"
        )

    def test_schema_error_message_in_stderr(self, tmp_path):
        invalid_prd = {
            "prd_id": "F99.001",
            "title": "Bad PRD",
            "slug": "bad-prd",
            "goal": {
                "objective": "x" * 10,
                "stopping_condition": "x" * 10,
                "files_to_read_first": [],
                "proof_commands": [],
            },
        }
        bad_file = tmp_path / "bad.json"
        bad_file.write_text(json.dumps(invalid_prd))

        outdir = tmp_path / "droid"
        result = run_emitter(str(bad_file), "--output-dir", str(outdir))
        assert result.returncode == 2
        combined = result.stderr + result.stdout
        assert "schema" in combined.lower() or "validation" in combined.lower() or "missing" in combined.lower(), (
            f"Expected schema error info in output, got:\n{combined}"
        )


class TestFeaturesJsonValidates:
    """test_features_json_validates: features.json structure matches Factory's required field list."""

    def test_all_required_fields_present_and_typed(self, tmp_path):
        outdir = tmp_path / "droid"
        run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))

        bundle = get_bundle_dir(outdir, "password-reset")
        features_data = json.loads((bundle / "features.json").read_text())
        feature = features_data["features"][0]

        assert isinstance(feature["id"], str), "id must be str"
        assert isinstance(feature["description"], str), "description must be str"
        assert isinstance(feature["skillName"], str), "skillName must be str"
        assert isinstance(feature["milestone"], str), "milestone must be str"
        assert isinstance(feature["preconditions"], list), "preconditions must be list"
        assert all(isinstance(p, str) for p in feature["preconditions"]), "preconditions items must be str"
        assert isinstance(feature["expectedBehavior"], str), "expectedBehavior must be str"
        assert isinstance(feature["verificationSteps"], list), "verificationSteps must be list"
        assert all(isinstance(s, str) for s in feature["verificationSteps"]), "verificationSteps items must be str"
        assert isinstance(feature["fulfills"], list), "fulfills must be list"
        assert all(isinstance(s, str) for s in feature["fulfills"]), "fulfills items must be str"
        assert feature["status"] in FEATURES_STATUS_ENUM, f"status must be one of {FEATURES_STATUS_ENUM}"

    def test_validate_mode_does_not_write_files(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir), "--validate")
        assert result.returncode == 0, f"--validate mode failed:\n{result.stderr}"
        # No files written in validate mode
        assert not outdir.exists() or not any(outdir.rglob("*")), (
            "--validate should not write files, but output dir has content"
        )

    def test_validate_mode_prints_feature_structure(self, tmp_path):
        outdir = tmp_path / "droid"
        result = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir), "--validate")
        assert result.returncode == 0
        # Should print what would be written
        assert "features" in result.stdout.lower() or "VALID" in result.stdout, (
            f"--validate should print validation result, got:\n{result.stdout}"
        )


class TestIdempotent:
    """test_idempotent: running twice produces byte-identical output."""

    def test_all_four_files_byte_identical_on_second_run(self, tmp_path):
        outdir = tmp_path / "droid"

        # First run
        result1 = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result1.returncode == 0, f"First run failed:\n{result1.stderr}"

        bundle = get_bundle_dir(outdir, "password-reset")

        # Capture first-run contents
        first_run = {}
        for fname in EXPECTED_FILES:
            first_run[fname] = (bundle / fname).read_bytes()
        first_run[EXPECTED_SERVICES_YAML] = (bundle / EXPECTED_SERVICES_YAML).read_bytes()

        # Second run (same output dir — overwrites)
        result2 = run_emitter(str(MINIMAL_FIXTURE), "--output-dir", str(outdir))
        assert result2.returncode == 0, f"Second run failed:\n{result2.stderr}"

        # Compare
        for fname in EXPECTED_FILES:
            second_content = (bundle / fname).read_bytes()
            assert first_run[fname] == second_content, (
                f"File {fname!r} is NOT byte-identical between runs"
            )
        second_services = (bundle / EXPECTED_SERVICES_YAML).read_bytes()
        assert first_run[EXPECTED_SERVICES_YAML] == second_services, (
            ".factory/services.yaml is NOT byte-identical between runs"
        )

    def test_valid_fixture_idempotent(self, tmp_path):
        outdir = tmp_path / "droid"

        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        bundle = get_bundle_dir(outdir, "user-authentication")
        first_features = (bundle / "features.json").read_bytes()

        run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        second_features = (bundle / "features.json").read_bytes()

        assert first_features == second_features, "features.json not byte-identical on second run"


class TestValidationContractDistinctAssertions:
    """Regression tests for P0-D1: each VC ID must produce distinct assertion content."""

    def test_each_vc_id_has_distinct_content(self, tmp_path):
        """Every VC block body must carry unique assertion content — no two blocks
        may share the same GIVEN/WHEN/THEN lines (heading lines differ by ID but
        the assertion body must also differ)."""
        outdir = tmp_path / "droid"
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"Emitter failed:\n{result.stderr}"

        bundle = get_bundle_dir(outdir, "user-authentication")
        vc_text = (bundle / "validation-contract.md").read_text()

        # Split into per-VC blocks — each block starts with "### VC-"
        import re
        raw_blocks = re.split(r"(?=^### VC-)", vc_text, flags=re.MULTILINE)
        vc_blocks = [b.strip() for b in raw_blocks if b.strip().startswith("### VC-")]

        assert len(vc_blocks) >= 2, (
            f"Need at least 2 VC blocks to check distinctness, got {len(vc_blocks)}"
        )

        # Extract the body of each block (everything after the heading line)
        # so we compare assertion content, not VC IDs which are inherently different
        def block_body(block: str) -> str:
            lines = block.splitlines()
            # Skip the "### VC-AUTH-..." heading line
            body_lines = [l for l in lines[1:] if l.strip()]
            return "\n".join(body_lines)

        bodies = [block_body(b) for b in vc_blocks]

        # No two VC block bodies may be identical
        for i in range(len(bodies)):
            for j in range(i + 1, len(bodies)):
                assert bodies[i] != bodies[j], (
                    f"VC block {i+1} and block {j+1} have identical assertion bodies — "
                    f"each VC ID must carry a distinct atomic assertion.\n"
                    f"Block {i+1} body:\n{bodies[i][:200]}\n"
                    f"Block {j+1} body:\n{bodies[j][:200]}"
                )

    def test_no_given_given_double_prepend(self, tmp_path):
        """The emitter must not produce 'GIVEN Given ...' double-prepend on any line."""
        outdir = tmp_path / "droid"
        result = run_emitter(str(VALID_FIXTURE), "--output-dir", str(outdir))
        assert result.returncode == 0, f"Emitter failed:\n{result.stderr}"

        bundle = get_bundle_dir(outdir, "user-authentication")
        vc_text = (bundle / "validation-contract.md").read_text()

        offending = [
            line for line in vc_text.splitlines()
            if line.startswith("GIVEN Given ") or line.startswith("GIVEN given ")
        ]
        assert not offending, (
            f"Found {len(offending)} line(s) with 'GIVEN Given' double-prepend:\n"
            + "\n".join(offending)
        )
