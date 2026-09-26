"""
emit_droid_mission.py — Canonical PRD → Factory Droid mission bundle emitter.

Phase 2c of the Sigma Protocol 3.0 CLI-Native PRD Upgrade.

Transforms a canonical PRD (sigma-prd-canonical.schema.json) into a 4-file
Factory Droid mission bundle at:

  .sigma/dispatch/droid/<prd-slug>/
    mission.md                   # Mission goal + scope + success criteria
    features.json                # Factory features.json-schema conformant
    validation-contract.md       # BDD-like behavioral assertions
    .factory/services.yaml       # Stub with hardcoded port placeholder

Usage:
  python3 emit_droid_mission.py <prd-path-or-glob> [--output-dir .sigma/dispatch/droid] [--validate]

Exits:
  0 — success
  1 — unexpected error
  2 — schema validation failure (invalid PRD input)
"""
from __future__ import annotations

import argparse
import glob
import json
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Schema validation
# ---------------------------------------------------------------------------

# Inline Factory features.json required-field contract (from reverse-engineered
# orchestrator prompt at https://gist.github.com/V1ki/356b121038722ebf32b5aac85482c113)
FEATURES_REQUIRED_FIELDS: dict[str, type] = {
    "id": str,
    "description": str,
    "skillName": str,
    "milestone": str,
    "preconditions": list,
    "expectedBehavior": str,
    "verificationSteps": list,
    "fulfills": list,
    "status": str,
}
FEATURES_STATUS_ENUM = {"pending", "in_progress", "done", "failed"}

CANONICAL_SCHEMA_PATH = Path(__file__).parent.parent.parent / "schemas" / "sigma-prd-canonical.schema.json"


def _validate_prd_against_schema(prd: dict, prd_path: Path) -> None:
    """
    Validate PRD against canonical schema.
    Raises SystemExit(2) with an error message on failure.

    Uses jsonschema if available; falls back to manual required-field check.
    """
    try:
        import jsonschema

        schema = json.loads(CANONICAL_SCHEMA_PATH.read_text())
        try:
            jsonschema.validate(instance=prd, schema=schema)
        except jsonschema.ValidationError as exc:
            print(
                f"Schema validation error in {prd_path}:\n  {exc.message}",
                file=sys.stderr,
            )
            sys.exit(2)
    except ImportError:
        # Fallback: manual required-field check
        _validate_prd_manual(prd, prd_path)


def _validate_prd_manual(prd: dict, prd_path: Path) -> None:
    """Minimal required-field validation without jsonschema."""
    top_required = ["prd_id", "title", "slug", "goal", "mission"]
    missing_top = [k for k in top_required if k not in prd]
    if missing_top:
        print(
            f"Schema validation error in {prd_path}: missing required fields: {missing_top}",
            file=sys.stderr,
        )
        sys.exit(2)

    goal_required = ["objective", "stopping_condition", "files_to_read_first", "proof_commands"]
    missing_goal = [k for k in goal_required if k not in prd.get("goal", {})]
    if missing_goal:
        print(
            f"Schema validation error in {prd_path}: goal block missing required fields: {missing_goal}",
            file=sys.stderr,
        )
        sys.exit(2)

    mission_required = [
        "milestone", "expected_behavior", "verification_steps",
        "fulfills", "skill_name", "estimated_complexity",
    ]
    missing_mission = [k for k in mission_required if k not in prd.get("mission", {})]
    if missing_mission:
        print(
            f"Schema validation error in {prd_path}: mission block missing required fields: {missing_mission}",
            file=sys.stderr,
        )
        sys.exit(2)


def _validate_feature(feature: dict) -> list[str]:
    """Return list of validation errors for a single feature dict."""
    errors: list[str] = []
    for field, expected_type in FEATURES_REQUIRED_FIELDS.items():
        if field not in feature:
            errors.append(f"missing required field: {field!r}")
        elif not isinstance(feature[field], expected_type):
            errors.append(
                f"field {field!r} must be {expected_type.__name__}, "
                f"got {type(feature[field]).__name__}"
            )
    if "status" in feature and feature["status"] not in FEATURES_STATUS_ENUM:
        errors.append(
            f"status {feature['status']!r} not in {sorted(FEATURES_STATUS_ENUM)}"
        )
    if "preconditions" in feature and isinstance(feature["preconditions"], list):
        if not all(isinstance(p, str) for p in feature["preconditions"]):
            errors.append("preconditions items must all be strings")
    if "verificationSteps" in feature and isinstance(feature["verificationSteps"], list):
        if not all(isinstance(s, str) for s in feature["verificationSteps"]):
            errors.append("verificationSteps items must all be strings")
    if "fulfills" in feature and isinstance(feature["fulfills"], list):
        if not all(isinstance(s, str) for s in feature["fulfills"]):
            errors.append("fulfills items must all be strings")
    return errors


# ---------------------------------------------------------------------------
# mission.md generator
# ---------------------------------------------------------------------------

def _render_mission_md(prd: dict) -> str:
    title = prd["title"]
    goal = prd["goal"]
    mission = prd.get("mission", {})

    objective = goal.get("objective", "")
    stopping_condition = goal.get("stopping_condition", "")
    files_to_read = goal.get("files_to_read_first", [])
    proof_commands = goal.get("proof_commands", [])
    out_of_scope = goal.get("out_of_scope", [])
    expected_behavior = mission.get("expected_behavior", "")

    # Scope: in-scope from expected_behavior, out-of-scope from goal.out_of_scope
    in_scope_line = expected_behavior if expected_behavior else "See expected_behavior in PRD."
    out_of_scope_lines = "\n".join(f"- {item}" for item in out_of_scope) if out_of_scope else "- (none specified)"

    files_lines = "\n".join(f"- {f}" for f in files_to_read) if files_to_read else "- (none specified)"
    proof_lines = "\n".join(f"- {cmd}" for cmd in proof_commands) if proof_commands else "- (none specified)"

    return (
        f"# Mission: {title}\n"
        f"\n"
        f"## Goal\n"
        f"{objective}\n"
        f"\n"
        f"## Scope\n"
        f"- In scope: {in_scope_line}\n"
        f"- Out of scope:\n"
        f"{out_of_scope_lines}\n"
        f"\n"
        f"## Success criteria\n"
        f"{stopping_condition}\n"
        f"\n"
        f"## Required reading (load BEFORE planning)\n"
        f"{files_lines}\n"
        f"\n"
        f"## Proof of progress\n"
        f"{proof_lines}\n"
    )


# ---------------------------------------------------------------------------
# features.json generator
# ---------------------------------------------------------------------------

def _build_feature(
    feature_id: str,
    description: str,
    prd: dict,
) -> dict:
    mission = prd.get("mission", {})
    return {
        "id": feature_id,
        "description": description,
        "skillName": mission.get("skill_name", ""),
        "milestone": mission.get("milestone", ""),
        "preconditions": list(mission.get("preconditions", [])),
        "expectedBehavior": mission.get("expected_behavior", ""),
        "verificationSteps": list(mission.get("verification_steps", [])),
        "fulfills": list(mission.get("fulfills", [])),
        "status": "pending",
    }


def _render_features_json(prd: dict) -> str:
    prd_id = prd["prd_id"]
    title = prd["title"]
    goal = prd["goal"]
    slices = prd.get("slices", [])

    if slices:
        # One feature per slice
        features = []
        for s in slices:
            slice_id = s["id"]
            slice_desc = f"{s['title']}: {goal.get('objective', '')}"
            features.append(_build_feature(slice_id, slice_desc, prd))
    else:
        # Single feature for the whole PRD
        description = f"{title}: {goal.get('objective', '')}"
        features = [_build_feature(prd_id, description, prd)]

    result = {"features": features}
    return json.dumps(result, indent=2, ensure_ascii=False) + "\n"


# ---------------------------------------------------------------------------
# validation-contract.md generator
# ---------------------------------------------------------------------------

def _split_bdd_clauses(expected_behavior: str) -> list[str]:
    """
    Split a multi-clause BDD expectedBehavior string into individual clauses.

    The fixture format uses ". Given " (period-space-Given) as the separator
    between clauses. Each returned clause is a self-contained "Given...when...then"
    sentence. Single-clause strings are returned as a one-element list.
    """
    import re as _re
    text = expected_behavior.strip()
    # Split on ". Given " (case-insensitive). Re-attach "Given " to each
    # continuation clause because splitting strips the separator.
    parts = _re.split(r"\.\s+(?=given\s)", text, flags=_re.IGNORECASE)
    clauses: list[str] = []
    for i, part in enumerate(parts):
        part = part.strip().rstrip(".")
        if not part:
            continue
        # All continuation clauses (i > 0) lost their leading "Given " due to
        # lookahead split — they still have it because we used a lookahead.
        clauses.append(part)
    return clauses if clauses else [text]


def _bdd_from_clause(clause: str, preconditions: list[str]) -> tuple[str, str, str]:
    """
    Extract or derive Given/When/Then from a single BDD clause string.

    Returns (given_content, when_content, then_content) where the content
    does NOT include the keyword prefix ("Given "/"When "/"Then ") — the
    caller is responsible for rendering the GIVEN/WHEN/THEN headers.

    If the clause already starts with "given ", parse inline when/then markers.
    Otherwise, heuristically construct the triple.
    """
    text = clause.strip()
    lower = text.lower()

    if lower.startswith("given "):
        # Inline BDD — parse by scanning for "when " and "then " markers
        # in a single-sentence clause. These appear as ", when " and ", then ".
        given_part = ""
        when_part = ""
        then_part = ""

        # Try splitting inline on ", when " and ", then " (comma-space-keyword)
        import re as _re
        # Pattern: capture text up to ", when " and ", then "
        m_when = _re.search(r",?\s+when\s+", text, _re.IGNORECASE)
        m_then = _re.search(r",?\s+then\s+", text, _re.IGNORECASE)

        if m_when and m_then and m_when.start() < m_then.start():
            given_part = text[:m_when.start()].strip()
            when_part = text[m_when.end():m_then.start()].strip()
            then_part = text[m_then.end():].strip()
        elif m_then and not m_when:
            given_part = text[:m_then.start()].strip()
            when_part = "the described action is performed"
            then_part = text[m_then.end():].strip()
        else:
            # No inline when/then found — entire clause is the given
            given_part = text
            when_part = "the described action is performed"
            then_part = "the expected behavior occurs as described"

        # Strip the leading "Given " keyword from given_part — caller adds GIVEN
        given_content = _re.sub(r"^given\s+", "", given_part, count=1, flags=_re.IGNORECASE).strip()
        return given_content, when_part, then_part

    # Heuristic derivation for non-BDD text
    if preconditions:
        given = "; ".join(preconditions)
    else:
        given = "the system is in the expected initial state"
    when = "the described action is performed"
    then = text if text else "the expected behavior occurs as described"
    return given, when, then


def _render_validation_contract_md(prd: dict) -> str:
    title = prd["title"]
    prd_id = prd["prd_id"]
    mission = prd.get("mission", {})
    expected_behavior = mission.get("expected_behavior", "")
    verification_steps = mission.get("verification_steps", [])
    fulfills = mission.get("fulfills", [])
    preconditions = mission.get("preconditions", [])

    # Deduplicate VC IDs while preserving order
    all_vc_ids = list(dict.fromkeys(verification_steps + fulfills))

    # Split expectedBehavior into atomic clauses — one per VC ID ideally
    clauses = _split_bdd_clauses(expected_behavior)

    lines: list[str] = [
        f"# Validation Contract: {title}",
        "",
        "## Assertions",
        "",
    ]

    if not all_vc_ids:
        # Fallback: at least one assertion from expected_behavior
        given, when, then = _bdd_from_clause(clauses[0], preconditions)
        lines += [
            f"### VC-{prd_id}-001 — Primary Behavior",
            f"GIVEN {given}",
            f"WHEN {when}",
            f"THEN {then}",
            "",
        ]
        return "\n".join(lines)

    for idx, vc_id in enumerate(all_vc_ids, start=1):
        label = vc_id.replace("VC-", "").replace("-", " ").title()

        if idx - 1 < len(clauses):
            # Zip: this VC ID gets its own atomic clause
            clause = clauses[idx - 1]
            given, when, then = _bdd_from_clause(clause, preconditions)
        else:
            # More VC IDs than clauses — emit a placeholder
            given = f"(TODO: split expectedBehavior into {len(all_vc_ids)}+ atomic assertions — clause {idx} not present)"
            when = "the described action is performed"
            then = "the expected behavior occurs as described"
            import sys as _sys
            print(
                f"WARNING: VC ID #{idx} ({vc_id}) has no matching clause in expectedBehavior "
                f"({len(clauses)} clause(s) for {len(all_vc_ids)} VC IDs).",
                file=_sys.stderr,
            )

        lines += [
            f"### {vc_id} — {label}",
            f"GIVEN {given}",
            f"WHEN {when}",
            f"THEN {then}",
            "",
        ]

    # If there are more clauses than VC IDs, append extras under VC-XTRA
    extra_clauses = clauses[len(all_vc_ids):]
    if extra_clauses:
        import sys as _sys
        print(
            f"WARNING: {len(extra_clauses)} extra clause(s) in expectedBehavior have no matching VC IDs.",
            file=_sys.stderr,
        )
        for i, clause in enumerate(extra_clauses, start=1):
            given, when, then = _bdd_from_clause(clause, preconditions)
            lines += [
                f"### VC-{prd_id}-XTRA-{i:03d} — Extra Assertion {i}",
                f"GIVEN {given}",
                f"WHEN {when}",
                f"THEN {then}",
                "",
            ]

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# .factory/services.yaml generator
# ---------------------------------------------------------------------------

def _render_services_yaml(prd: dict) -> str:
    prd_id = prd["prd_id"]
    return (
        f"# Services required by mission {prd_id}\n"
        f"# Auto-generated stub — fill in actual services + commands + healthchecks before running mission.\n"
        f"services: []\n"
        f"# Example skeleton:\n"
        f"# services:\n"
        f"#   - name: api\n"
        f"#     port: 3000  # HARDCODE — must be literal in start/stop/healthcheck\n"
        f"#     start: \"PORT=3000 npm start\"\n"
        f"#     stop: \"lsof -ti:3000 | xargs kill\"\n"
        f"#     healthcheck: \"curl -fsS http://localhost:3000/health\"\n"
    )


# ---------------------------------------------------------------------------
# Core emitter
# ---------------------------------------------------------------------------

def emit_bundle(prd: dict, output_dir: Path, validate_only: bool = False) -> dict[str, str]:
    """
    Build the 4-file bundle for a single PRD.

    Returns a dict mapping relative path → content string.
    Does NOT write files when validate_only=True.
    """
    slug = prd["slug"]

    mission_md = _render_mission_md(prd)
    features_json_str = _render_features_json(prd)
    validation_contract_md = _render_validation_contract_md(prd)
    services_yaml = _render_services_yaml(prd)

    bundle: dict[str, str] = {
        "mission.md": mission_md,
        "features.json": features_json_str,
        "validation-contract.md": validation_contract_md,
        ".factory/services.yaml": services_yaml,
    }

    # Validate features.json structure
    features_data = json.loads(features_json_str)
    for feature in features_data["features"]:
        errors = _validate_feature(feature)
        if errors:
            print(
                f"features.json validation errors for PRD {prd['prd_id']}:\n  "
                + "\n  ".join(errors),
                file=sys.stderr,
            )
            sys.exit(1)

    if validate_only:
        print(f"VALID — Would write bundle for PRD {prd['prd_id']} ({slug}) to {output_dir / slug}/")
        print(f"  features.json: {len(features_data['features'])} feature(s)")
        for i, feature in enumerate(features_data["features"]):
            print(f"    [{i}] id={feature['id']!r} status={feature['status']!r}")
        return bundle

    # Write files
    bundle_dir = output_dir / slug
    for rel_path, content in bundle.items():
        dest = bundle_dir / rel_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(content, encoding="utf-8")

    return bundle


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Emit Factory Droid mission bundles from canonical PRD JSON files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "prd_paths",
        nargs="+",
        metavar="PRD_PATH",
        help="Path(s) or glob(s) to canonical PRD JSON files.",
    )
    parser.add_argument(
        "--output-dir",
        default=".sigma/dispatch/droid",
        help="Root output directory (default: .sigma/dispatch/droid).",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate without writing files. Prints what would be written.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    output_dir = Path(args.output_dir)

    # Expand globs
    prd_files: list[Path] = []
    for pattern in args.prd_paths:
        matched = glob.glob(pattern, recursive=True)
        if matched:
            prd_files.extend(Path(p) for p in matched)
        else:
            # Treat as a literal path
            prd_files.append(Path(pattern))

    if not prd_files:
        print("No PRD files found matching the given paths/globs.", file=sys.stderr)
        return 1

    for prd_path in prd_files:
        if not prd_path.exists():
            print(f"File not found: {prd_path}", file=sys.stderr)
            return 1

        try:
            prd = json.loads(prd_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"JSON parse error in {prd_path}: {exc}", file=sys.stderr)
            return 1

        _validate_prd_against_schema(prd, prd_path)

        emit_bundle(prd, output_dir, validate_only=args.validate)

    return 0


def generate(prd_dict: dict) -> str:
    """Generate the Droid mission.md string from an in-memory PRD dict.

    Validates required fields and returns the mission.md content.
    Raises ValueError on schema validation failure.

    For the dispatch_prompts dict, the 'droid' key holds mission.md content
    because that is the primary entrypoint for Factory Droid missions.
    The full 4-file bundle (features.json, validation-contract.md,
    .factory/services.yaml) is only written when dispatching to disk.

    Args:
        prd_dict: A PRD dict conforming to sigma-prd-canonical.schema.json.

    Returns:
        mission.md content as a string.

    Raises:
        ValueError: If the PRD is missing required fields.
    """
    top_required = ["prd_id", "title", "slug", "goal", "mission"]
    missing = [k for k in top_required if k not in prd_dict]
    if missing:
        raise ValueError(f"PRD missing required fields: {missing}")
    return _render_mission_md(prd_dict)


if __name__ == "__main__":
    sys.exit(main())
