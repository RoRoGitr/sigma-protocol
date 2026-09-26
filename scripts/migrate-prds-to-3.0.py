#!/usr/bin/env python3
"""
scripts/migrate-prds-to-3.0.py

PRD auto-upgrade migration script for Sigma Protocol 3.0.

Finds all existing PRDs under docs/prds/, injects required schema fields
(goal:, mission:) with sensible defaults, and reports any PRDs that cannot
be auto-upgraded.

Usage:
    python3 migrate-prds-to-3.0.py [--dry-run] [--apply] [--target docs/prds/]

    --dry-run  (default) Per-PRD report of what would change; no file writes.
    --apply    Rewrite files in place (with .bak backup per file).
    --target   Directory to scan (default: docs/prds/).

Per Dallion's Decision #9: backward-compat via auto-upgrade, not hard cut.
See docs/strategy/2026-05-23-cli-native-prd-upgrade.md for full rationale.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover — exercised in clean envs without pyyaml
    sys.stderr.write(
        "[migrate-prds-to-3.0] pyyaml not available — install with: "
        "pip install pyyaml  (or run via: uv run --with pyyaml python scripts/migrate-prds-to-3.0.py ...)\n"
    )
    sys.exit(2)

# ---------------------------------------------------------------------------
# Schema path (relative to this script's location)
# ---------------------------------------------------------------------------
_SCRIPT_DIR = Path(__file__).parent
SCHEMA_PATH = _SCRIPT_DIR.parent / "schemas" / "sigma-prd-canonical.schema.json"


# ---------------------------------------------------------------------------
# YAML frontmatter helpers (reused pattern from tag-destructive-skills.py.template)
# ---------------------------------------------------------------------------

def parse_frontmatter(content: str) -> dict[str, Any]:
    """Return parsed YAML frontmatter dict, or empty dict if none."""
    if not content.startswith("---"):
        return {}
    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}
    try:
        fm = yaml.safe_load(parts[1])
        return fm if isinstance(fm, dict) else {}
    except yaml.YAMLError:
        return {}


def split_content(content: str) -> tuple[str, str]:
    """Return (frontmatter_raw, body_after_closing_fence).
    frontmatter_raw includes the opening and closing --- markers and everything between.
    body is everything after the closing ---.
    """
    if not content.startswith("---"):
        return "", content
    parts = content.split("---", 2)
    if len(parts) < 3:
        return "", content
    # parts[0] = "" (before first ---), parts[1] = fm block, parts[2] = body
    frontmatter_raw = "---" + parts[1] + "---"
    body = parts[2]
    return frontmatter_raw, body


def has_frontmatter_field(content: str, field: str) -> bool:
    """True if the YAML frontmatter contains the given top-level key."""
    if not content.startswith("---"):
        return False
    parts = content.split("---", 2)
    if len(parts) < 3:
        return False
    return bool(re.search(rf"^\s*{re.escape(field)}\s*:", parts[1], re.M))


def inject_into_frontmatter(content: str, new_fields: dict[str, Any]) -> str:
    """Insert new_fields into the existing YAML frontmatter, just before the closing ---."""
    if not content.startswith("---"):
        extra = yaml.dump(new_fields, default_flow_style=False, allow_unicode=True)
        return f"---\n{extra}---\n\n{content}"
    parts = content.split("---", 2)
    if len(parts) < 3:
        return content  # malformed — skip
    fm_text = parts[1].rstrip("\n")
    extra = yaml.dump(new_fields, default_flow_style=False, allow_unicode=True)
    # Strip trailing newline from extra so we control spacing
    extra = extra.rstrip("\n")
    new_fm = f"{fm_text}\n{extra}\n"
    return f"---{new_fm}---{parts[2]}"


# ---------------------------------------------------------------------------
# Schema validation
# ---------------------------------------------------------------------------

def _load_schema() -> dict[str, Any]:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def validate_frontmatter(fm: dict[str, Any]) -> tuple[bool, str]:
    """
    Validate frontmatter dict against sigma-prd-canonical.schema.json.
    Returns (is_valid, reason_if_invalid).
    Pure Python implementation — no jsonschema dep required.
    """
    schema = _load_schema()
    required = schema.get("required", [])
    for field in required:
        if field not in fm:
            return False, f"Missing required field: {field}"

    # Validate prd_id pattern
    prd_id = fm.get("prd_id", "")
    if not isinstance(prd_id, str) or not re.match(r"^(F\d+\.\d+|PRD-[A-Z0-9][A-Z0-9-]*)$", prd_id):
        return False, f"prd_id '{prd_id}' does not match required pattern"

    # Validate goal block
    goal = fm.get("goal", {})
    if not isinstance(goal, dict):
        return False, "goal must be a dict"
    for req_field in ("objective", "stopping_condition", "files_to_read_first", "proof_commands"):
        if req_field not in goal:
            return False, f"goal.{req_field} is required"
    if not isinstance(goal.get("files_to_read_first"), list):
        return False, "goal.files_to_read_first must be a list"
    if not isinstance(goal.get("proof_commands"), list):
        return False, "goal.proof_commands must be a list"

    # Validate mission block
    mission = fm.get("mission", {})
    if not isinstance(mission, dict):
        return False, "mission must be a dict"
    for req_field in ("milestone", "expected_behavior", "verification_steps", "fulfills", "skill_name", "estimated_complexity"):
        if req_field not in mission:
            return False, f"mission.{req_field} is required"

    # verification_steps and fulfills must be non-empty lists matching VC-* pattern
    vc_pattern = re.compile(r"^VC-[A-Z0-9][A-Z0-9-]*$")
    for list_field in ("verification_steps", "fulfills"):
        val = mission.get(list_field, [])
        if not isinstance(val, list) or len(val) == 0:
            return False, f"mission.{list_field} must be a non-empty list"
        for item in val:
            if not vc_pattern.match(str(item)):
                return False, f"mission.{list_field} item '{item}' must match VC-* pattern"

    if mission.get("estimated_complexity") not in ("small", "medium", "large"):
        return False, "mission.estimated_complexity must be small|medium|large"

    return True, ""


# ---------------------------------------------------------------------------
# Tech stack detection (for proof_commands default)
# ---------------------------------------------------------------------------

def _detect_proof_commands(prd_path: Path) -> list[str]:
    """Heuristic: look for a Test/Verification section in the PRD body."""
    content = prd_path.read_text(encoding="utf-8")
    _, body = split_content(content)

    # Look for code blocks after test/verification headings
    test_heading = re.search(
        r"##\s+(Test|Verification|Testing).*?\n(.*?)(?=\n##|\Z)",
        body,
        re.I | re.S,
    )
    if test_heading:
        code_blocks = re.findall(r"```[^\n]*\n(.+?)```", test_heading.group(2), re.S)
        cmds = []
        for block in code_blocks:
            for line in block.strip().splitlines():
                line = line.strip()
                if line and not line.startswith("#"):
                    cmds.append(line)
                    if len(cmds) >= 3:
                        break
        if cmds:
            return cmds

    # Fallback: detect tech stack from repo root
    repo_root = prd_path.parent
    while repo_root.parent != repo_root:
        if (repo_root / "package.json").exists():
            return ["npm test"]
        if (repo_root / "pyproject.toml").exists() or (repo_root / "setup.py").exists():
            return ["pytest"]
        if (repo_root / "Cargo.toml").exists():
            return ["cargo test"]
        if (repo_root / "go.mod").exists():
            return ["go test ./..."]
        repo_root = repo_root.parent

    return ["pytest"]


# ---------------------------------------------------------------------------
# Skill name detection
# ---------------------------------------------------------------------------

_SKILL_LOOKUP = [
    (["react", "component", "tsx", "jsx", "frontend", "ui"], "frontend-engineer"),
    (["swift", "swiftui", "ios", "xcode"], "mobile-engineer"),
    (["react-native", "expo", "nativewind"], "mobile-engineer"),
    (["android", "kotlin"], "mobile-engineer"),
    (["database", "sql", "migration", "schema", "postgres", "mysql", "sqlite"], "database-architect"),
    (["devops", "kubernetes", "docker", "terraform", "infra", "deploy"], "devops-engineer"),
    (["security", "auth", "owasp", "vulnerability"], "security-engineer"),
]

def _detect_skill_name(content: str) -> str:
    body_lower = content.lower()
    for keywords, skill in _SKILL_LOOKUP:
        if any(kw in body_lower for kw in keywords):
            return skill
    return "backend-engineer"


# ---------------------------------------------------------------------------
# Objective extraction
# ---------------------------------------------------------------------------

def _extract_objective(fm: dict[str, Any], body: str) -> str:
    """Pull from existing summary field or first paragraph of description."""
    if "summary" in fm and isinstance(fm["summary"], str) and fm["summary"].strip():
        return fm["summary"].strip()[:400]

    # First non-empty paragraph in body (after the # heading)
    paragraphs = re.split(r"\n{2,}", body)
    for para in paragraphs:
        para = para.strip()
        if para and not para.startswith("#") and len(para) > 20:
            # Single sentence: take up to first period or entire paragraph capped at 300 chars
            sentence = re.split(r"\.\s", para)[0]
            return (sentence[:300] + ".") if not sentence.endswith(".") else sentence[:300]

    return f"Implement {fm.get('title', 'feature')} as specified."


# ---------------------------------------------------------------------------
# expected_behavior extraction
# ---------------------------------------------------------------------------

def _extract_expected_behavior(body: str) -> str:
    """Search for BDD Given/When/Then block in body."""
    bdd_match = re.search(
        r"((?:Given|When|Then)[^\n](?:.*?\n)*?(?:Given|When|Then)[^\n]+)",
        body,
        re.M | re.I,
    )
    if bdd_match:
        return bdd_match.group(0).strip()[:800]

    # Look for "BDD Scenarios" or similar heading
    heading_match = re.search(
        r"##\s+(?:BDD|Behavioral|Acceptance Criteria).*?\n(.*?)(?=\n##|\Z)",
        body,
        re.I | re.S,
    )
    if heading_match:
        text = heading_match.group(1).strip()[:800]
        if text:
            return text

    return "<TODO: derive from acceptance criteria>"


# ---------------------------------------------------------------------------
# Core upgrade logic
# ---------------------------------------------------------------------------

def _build_prd_id_slug(prd_id: str, title: str) -> str:
    """Generate slug from prd_id or title."""
    if prd_id:
        slug = prd_id.lower().replace("_", "-").replace(" ", "-")
        # Strip leading PRD- if present, normalize
        slug = re.sub(r"[^a-z0-9-]", "-", slug)
        slug = re.sub(r"-+", "-", slug).strip("-")
        # Ensure min length 2
        if len(slug) >= 2:
            return slug
    # Fall back to title
    slug = re.sub(r"[^a-z0-9-]", "-", title.lower())
    slug = re.sub(r"-+", "-", slug).strip("-")
    return slug[:80] if len(slug) >= 2 else "prd-unknown"


def _milestone_from_wave(wave: Any) -> str:
    if wave is None:
        return "M0: Pre-3.0 PRD"
    if isinstance(wave, int):
        return f"M{wave}: Wave {wave}"
    # String wave label
    return f"M0: {str(wave)}"


def _seed_acceptance_criterion_fields(ac: dict[str, Any]) -> dict[str, Any]:
    """
    Optionally seed new EARS-lint fields (earsForm, acceptanceCriterionId, testId)
    onto an existing acceptance criterion dict.

    - earsForm: left absent (classification is done by ears-lint at runtime).
    - testId: left absent (must be authored manually once a test exists).
    - acceptanceCriterionId: left absent (stable human IDs require author input).

    This function is a hook so callers can extend it with their own heuristics.
    Returns the criterion dict unchanged (zero-mutation today; structure preserved
    for Stage C when the judge may populate earsForm automatically).
    """
    return ac


def build_new_fields(fm: dict[str, Any], body: str, prd_path: Path) -> dict[str, Any]:
    """Build the new goal + mission blocks with sensible defaults."""
    prd_id = str(fm.get("prd_id", "PRD-UNKNOWN"))
    title = str(fm.get("title", "Untitled PRD"))
    full_content = prd_path.read_text(encoding="utf-8")

    new_fields: dict[str, Any] = {}

    # slug (required by schema but not in old PRDs)
    if "slug" not in fm:
        new_fields["slug"] = _build_prd_id_slug(prd_id, title)

    # goal block
    if "goal" not in fm:
        proof_cmds = _detect_proof_commands(prd_path)
        new_fields["goal"] = {
            "objective": _extract_objective(fm, body),
            "stopping_condition": (
                "All acceptance criteria pass; tests green; 8 pipeline gates pass on commit"
            ),
            "files_to_read_first": [],  # WARNING issued in report
            "proof_commands": proof_cmds,
            "max_turns": 20,
            "out_of_scope": [],
        }

    # mission block
    if "mission" not in fm:
        deps = fm.get("dependencies", []) or []
        wave = fm.get("wave")
        complexity = fm.get("complexity", fm.get("estimated_complexity", "medium"))
        if complexity not in ("small", "medium", "large"):
            complexity = "medium"
        expected_behavior = _extract_expected_behavior(body)
        skill_name = _detect_skill_name(full_content)
        slug_for_vc = re.sub(r"[^A-Z0-9]", "-", prd_id.upper())[:20].strip("-")
        vc_id = f"VC-{slug_for_vc}-001"

        new_fields["mission"] = {
            "milestone": _milestone_from_wave(wave),
            "preconditions": [str(d) for d in deps] if deps else [],
            "expected_behavior": expected_behavior,
            "verification_steps": [vc_id],  # WARNING: needs manual review
            "fulfills": [vc_id],            # WARNING: needs manual review
            "skill_name": skill_name,
            "estimated_complexity": complexity,
        }

    return new_fields


# ---------------------------------------------------------------------------
# Per-file upgrade
# ---------------------------------------------------------------------------

def upgrade_prd(
    prd_path: Path,
    dry_run: bool,
    apply: bool,
) -> dict[str, Any]:
    """
    Upgrade a single PRD file.
    Returns a result dict: {file, status, reason, schema_valid, warnings}
    """
    result: dict[str, Any] = {
        "file": str(prd_path),
        "prd_id": None,
        "status": "unknown",
        "reason": "",
        "schema_valid": None,
        "warnings": [],
    }

    content = prd_path.read_text(encoding="utf-8")
    fm = parse_frontmatter(content)

    if not fm:
        result["status"] = "needs_manual_review"
        result["reason"] = "No YAML frontmatter detected"
        return result

    result["prd_id"] = fm.get("prd_id")

    # Check if already compliant
    already_has_goal = "goal" in fm
    already_has_mission = "mission" in fm

    if already_has_goal and already_has_mission:
        # Still validate to confirm it truly passes
        valid, reason = validate_frontmatter(fm)
        if valid:
            result["status"] = "already_compliant"
            result["schema_valid"] = True
            return result
        else:
            result["status"] = "needs_manual_review"
            result["reason"] = f"Has goal+mission but fails schema: {reason}"
            result["schema_valid"] = False
            return result

    # Need upgrade
    _, body = split_content(content)
    new_fields = build_new_fields(fm, body, prd_path)

    # Warnings
    if new_fields.get("goal", {}).get("files_to_read_first") == []:
        result["warnings"].append("goal.files_to_read_first is empty — add manually for best /goal results")
    if "<TODO:" in new_fields.get("mission", {}).get("expected_behavior", ""):
        result["warnings"].append("mission.expected_behavior needs manual authoring — no BDD block found")
    result["warnings"].append("mission.verification_steps and fulfills use placeholder VC-ID — update with real assertion IDs")

    if dry_run:
        result["status"] = "would_upgrade"
        result["reason"] = f"Would inject: {', '.join(new_fields.keys())}"
        result["schema_valid"] = None
        return result

    # --- Apply mode ---
    # 1. Write .bak
    bak_path = Path(str(prd_path) + ".bak")
    bak_path.write_text(content, encoding="utf-8")

    # 2. Inject fields
    new_content = inject_into_frontmatter(content, new_fields)

    # 3. Validate new frontmatter
    new_fm = parse_frontmatter(new_content)
    valid, validation_reason = validate_frontmatter(new_fm)

    if not valid:
        # Rollback from .bak
        prd_path.write_text(bak_path.read_text(encoding="utf-8"), encoding="utf-8")
        bak_path.unlink(missing_ok=True)
        result["status"] = "needs_manual_review"
        result["reason"] = f"Schema validation failed after upgrade: {validation_reason}"
        result["schema_valid"] = False
        return result

    # 4. Write upgraded file
    prd_path.write_text(new_content, encoding="utf-8")
    bak_path.unlink(missing_ok=True)

    result["status"] = "upgraded"
    result["reason"] = f"Injected: {', '.join(new_fields.keys())}"
    result["schema_valid"] = True
    return result


# ---------------------------------------------------------------------------
# Main runner (importable for tests)
# ---------------------------------------------------------------------------

def run(
    target_dir: Path,
    dry_run: bool = True,
    apply: bool = False,
) -> list[dict[str, Any]]:
    """
    Scan target_dir (recursive) for .md files with YAML frontmatter.
    Returns list of result dicts — one per PRD found.
    """
    effective_dry_run = dry_run or not apply

    prd_files = sorted(target_dir.rglob("*.md"))
    results = []

    for prd_path in prd_files:
        # Skip non-PRD files (e.g. DA-REVIEW.md, GA-REVIEW.md)
        content = prd_path.read_text(encoding="utf-8")
        fm = parse_frontmatter(content)
        if not fm or "prd_id" not in fm:
            # Not a PRD — skip silently
            continue

        result = upgrade_prd(prd_path, dry_run=effective_dry_run, apply=apply)
        results.append(result)

    return results


def _print_report(results: list[dict[str, Any]], dry_run: bool) -> None:
    mode = "DRY-RUN" if dry_run else "APPLIED"
    print(f"\n=== PRD Migration to 3.0 ({mode}) ===\n")

    counts: dict[str, int] = {}
    needs_review: list[dict[str, Any]] = []

    for r in results:
        s = r["status"]
        counts[s] = counts.get(s, 0) + 1
        if s == "needs_manual_review":
            needs_review.append(r)
        icon = {
            "already_compliant": "✓",
            "upgraded": "↑",
            "would_upgrade": "~",
            "needs_manual_review": "!",
            "unknown": "?",
        }.get(s, "?")
        prd_id = r.get("prd_id") or Path(r["file"]).name
        print(f"  [{icon}] {prd_id:35s} {s:<22s} {r.get('reason', '')}")
        for w in r.get("warnings", []):
            print(f"         WARNING: {w}")

    print("\n--- Summary ---")
    for status, count in sorted(counts.items()):
        print(f"  {status:<22s}: {count}")
    print(f"  {'Total':<22s}: {len(results)}")

    if needs_review:
        print("\n--- Needs Manual Review ---")
        for r in needs_review:
            print(f"  {r['file']}")
            print(f"    Reason: {r.get('reason', 'unknown')}")

    if dry_run and counts.get("would_upgrade", 0) > 0:
        print(f"\nRun with --apply to upgrade {counts.get('would_upgrade', 0)} PRDs.")


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Migrate existing Sigma PRDs to 3.0 schema (goal + mission blocks)."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=True,
        help="Report what would change without writing files (default).",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        default=False,
        help="Rewrite files with .bak backup; schema-validate post-upgrade; rollback on failure.",
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path("docs/prds"),
        help="Directory to scan (default: docs/prds/).",
    )
    args = parser.parse_args()

    target = args.target
    if not target.is_absolute():
        # Resolve relative to CWD
        target = Path.cwd() / target

    if not target.exists():
        print(f"ERROR: target directory does not exist: {target}")
        sys.exit(1)

    dry_run = args.dry_run and not args.apply
    results = run(target_dir=target, dry_run=dry_run, apply=args.apply)
    _print_report(results, dry_run=dry_run)


if __name__ == "__main__":
    main()
