"""
tests/test_migrate_prds.py

TDD tests for scripts/migrate-prds-to-3.0.py
All 5 required tests — written FIRST (RED phase).
"""
from __future__ import annotations

import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

import pytest

# Allow importing the migration script as a module
SCRIPTS_DIR = Path(__file__).parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import importlib.util

_MIGRATE_SCRIPT = SCRIPTS_DIR / "migrate-prds-to-3.0.py"
_spec = importlib.util.spec_from_file_location("migrate_prds", _MIGRATE_SCRIPT)
migrate = importlib.util.module_from_spec(_spec)  # type: ignore[arg-type]
_spec.loader.exec_module(migrate)  # type: ignore[union-attr]

SCHEMA_PATH = Path(__file__).parent.parent / "schemas" / "sigma-prd-canonical.schema.json"

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

LEGACY_PRD = """\
---
prd_id: PRD-TEST-LEGACY
title: Legacy Test PRD
version: 1.0.0
status: draft
wave: 1
dependencies:
  - PRD-OTHER
complexity: medium
---

# PRD: Legacy Test PRD

## Overview

This is the legacy PRD body. It must survive upgrade byte-identical.

## Test Section

Run `pytest` to verify.
"""

COMPLIANT_PRD = """\
---
prd_id: PRD-TEST-COMPLIANT
title: Already Compliant PRD
slug: already-compliant-prd
version: 1.0.0
status: draft
wave: 1
dependencies: []
goal:
  objective: Implement the already-compliant feature end to end.
  stopping_condition: All acceptance criteria pass; tests green; 8 pipeline gates pass on commit
  files_to_read_first: []
  proof_commands:
    - pytest
  max_turns: 20
  out_of_scope: []
mission:
  milestone: "M0: Pre-3.0 PRD"
  preconditions: []
  expected_behavior: Given valid input When processed Then output matches spec
  verification_steps:
    - VC-COMPLIANT-001
  fulfills:
    - VC-COMPLIANT-001
  skill_name: backend-engineer
  estimated_complexity: medium
---

# PRD: Already Compliant PRD

## Overview

Body content that must survive unchanged.
"""


def dir_checksums(directory: Path) -> dict[str, str]:
    """MD5 checksum of every file in directory (recursive)."""
    result = {}
    for f in sorted(directory.rglob("*")):
        if f.is_file():
            result[str(f.relative_to(directory))] = hashlib.md5(
                f.read_bytes()
            ).hexdigest()
    return result


# ---------------------------------------------------------------------------
# Test 1: --dry-run doesn't write anything
# ---------------------------------------------------------------------------

def test_dry_run_doesnt_write():
    """--dry-run must leave all files byte-identical."""
    with tempfile.TemporaryDirectory() as tmp:
        target = Path(tmp)
        prd_file = target / "PRD-TEST-LEGACY.md"
        prd_file.write_text(LEGACY_PRD, encoding="utf-8")

        before = dir_checksums(target)
        migrate.run(target_dir=target, dry_run=True, apply=False)
        after = dir_checksums(target)

        assert before == after, "dry-run must not modify any files"


# ---------------------------------------------------------------------------
# Test 2: Already-compliant PRD passes through unchanged
# ---------------------------------------------------------------------------

def test_already_compliant_unchanged():
    """PRD with goal+mission already present → status=already_compliant, no diff."""
    with tempfile.TemporaryDirectory() as tmp:
        target = Path(tmp)
        prd_file = target / "PRD-COMPLIANT.md"
        prd_file.write_text(COMPLIANT_PRD, encoding="utf-8")
        original_content = COMPLIANT_PRD

        results = migrate.run(target_dir=target, dry_run=False, apply=True)

        assert len(results) == 1
        result = results[0]
        assert result["status"] == "already_compliant"
        # File content must be byte-identical
        assert prd_file.read_text(encoding="utf-8") == original_content


# ---------------------------------------------------------------------------
# Test 3: Legacy PRD gets goal+mission injected with sensible defaults
# ---------------------------------------------------------------------------

def test_legacy_prd_upgraded():
    """PRD lacking goal+mission gets them injected with sensible defaults."""
    with tempfile.TemporaryDirectory() as tmp:
        target = Path(tmp)
        prd_file = target / "PRD-LEGACY.md"
        prd_file.write_text(LEGACY_PRD, encoding="utf-8")

        results = migrate.run(target_dir=target, dry_run=False, apply=True)

        assert len(results) == 1
        result = results[0]
        assert result["status"] == "upgraded", f"Expected upgraded, got {result['status']}: {result.get('reason')}"

        # Body must still contain the original PRD body text
        new_content = prd_file.read_text(encoding="utf-8")
        assert "## Overview" in new_content
        assert "## Test Section" in new_content
        assert "This is the legacy PRD body." in new_content

        # Frontmatter must now contain goal and mission
        fm = migrate.parse_frontmatter(new_content)
        assert "goal" in fm, "goal block must be present after upgrade"
        assert "mission" in fm, "mission block must be present after upgrade"

        # goal fields
        assert "objective" in fm["goal"]
        assert "stopping_condition" in fm["goal"]
        assert isinstance(fm["goal"]["files_to_read_first"], list)
        assert isinstance(fm["goal"]["proof_commands"], list)

        # mission fields — use wave for milestone
        assert fm["mission"]["milestone"] == "M1: Wave 1"
        # Use dependencies for preconditions
        assert fm["mission"]["preconditions"] == ["PRD-OTHER"]
        # complexity mapped
        assert fm["mission"]["estimated_complexity"] == "medium"

        # Post-upgrade validation passes schema
        assert result.get("schema_valid") is True


# ---------------------------------------------------------------------------
# Test 4: Rollback on schema failure
# ---------------------------------------------------------------------------

def test_rollback_on_schema_failure():
    """
    If post-upgrade schema validation fails, the file is rolled back from .bak
    and marked needs_manual_review.
    """
    # Create a PRD that will produce an invalid schema result by
    # monkeypatching the validator to always fail for this PRD id.
    with tempfile.TemporaryDirectory() as tmp:
        target = Path(tmp)
        prd_file = target / "PRD-BAD.md"
        prd_file.write_text(LEGACY_PRD.replace("PRD-TEST-LEGACY", "PRD-BAD"), encoding="utf-8")
        original_content = prd_file.read_text(encoding="utf-8")

        # Monkeypatch: force validate_frontmatter to return False for PRD-BAD
        original_validate = migrate.validate_frontmatter
        def failing_validate(fm: dict) -> tuple[bool, str]:
            if fm.get("prd_id") == "PRD-BAD":
                return False, "Simulated schema failure for test"
            return original_validate(fm)

        migrate.validate_frontmatter = failing_validate
        try:
            results = migrate.run(target_dir=target, dry_run=False, apply=True)
        finally:
            migrate.validate_frontmatter = original_validate

        assert len(results) == 1
        result = results[0]
        assert result["status"] == "needs_manual_review"

        # File must be restored to original content
        current_content = prd_file.read_text(encoding="utf-8")
        assert current_content == original_content, "File must be rolled back to original on schema failure"

        # .bak file should not exist (cleaned up after rollback)
        bak_file = Path(str(prd_file) + ".bak")
        assert not bak_file.exists(), ".bak must be cleaned up after rollback"


# ---------------------------------------------------------------------------
# Test 5: Idempotent — running --apply twice produces identical result
# ---------------------------------------------------------------------------

def test_idempotent():
    """Running --apply twice produces identical files (no double-injection)."""
    with tempfile.TemporaryDirectory() as tmp:
        target = Path(tmp)
        prd_file = target / "PRD-LEGACY.md"
        prd_file.write_text(LEGACY_PRD, encoding="utf-8")

        # First run
        results1 = migrate.run(target_dir=target, dry_run=False, apply=True)
        content_after_first = prd_file.read_text(encoding="utf-8")
        checksum1 = hashlib.md5(content_after_first.encode()).hexdigest()

        # Second run
        results2 = migrate.run(target_dir=target, dry_run=False, apply=True)
        content_after_second = prd_file.read_text(encoding="utf-8")
        checksum2 = hashlib.md5(content_after_second.encode()).hexdigest()

        assert checksum1 == checksum2, "Second run must not modify already-upgraded file"
        assert results2[0]["status"] == "already_compliant", "Second run must report already_compliant"
