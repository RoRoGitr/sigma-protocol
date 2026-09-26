#!/usr/bin/env python3
"""
emit_claude_bundle.py — Canonical PRD → Claude /goal bundle emitter.

Phase 2a of the Sigma Protocol 3.0 CLI-Native PRD Upgrade.

Transforms a canonical PRD (matching schemas/sigma-prd-canonical.schema.json)
into a Claude-flavored bundle at .sigma/dispatch/claude/<prd-id>.goal.md

Bundle format uses XML tags per Anthropic best practices:
  <context>, <task>, <requirements>, <proof>, <constraints>, <done-when>

4000-char output budget enforced. Truncation order (most dispensable first):
  1. out_of_scope items (constraints section)
  2. files_to_read_first items (requirements section)
  3. context section (shortened)
  4. proof commands (trimmed)

Usage:
    python3 emit_claude_bundle.py <prd-path-or-glob> [--output-dir .sigma/dispatch/claude] [--validate]

Exit codes:
    0  — success
    2  — PRD validation failed
    1  — unexpected error
"""
from __future__ import annotations

import argparse
import glob
import json
import re
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).parent.parent.parent
SCHEMA_PATH = REPO_ROOT / "schemas" / "sigma-prd-canonical.schema.json"
CHAR_LIMIT = 4000

# ─────────────────────────────────────────────────────────────────────────────
# Schema validation (pure stdlib — jsonschema has arch issues on this machine)
# ─────────────────────────────────────────────────────────────────────────────

def _validate_prd(prd: dict[str, Any]) -> list[str]:
    """
    Validate a PRD dict against the canonical schema.
    Returns a list of error strings (empty = valid).

    Implements the required fields and patterns from sigma-prd-canonical.schema.json
    without the jsonschema library (which has a native extension arch issue).
    """
    errors: list[str] = []

    # Required top-level fields
    required = ["prd_id", "title", "slug", "goal", "mission"]
    for field in required:
        if field not in prd:
            errors.append(f"Missing required field: '{field}'")

    if errors:
        # No point continuing if required fields are absent
        return errors

    # prd_id pattern: ^(F\d+\.\d+|PRD-[A-Z0-9][A-Z0-9-]*)$
    prd_id = prd["prd_id"]
    if not isinstance(prd_id, str):
        errors.append("'prd_id' must be a string")
    else:
        pattern = r"^(F\d+\.\d+|PRD-[A-Z0-9][A-Z0-9-]*)$"
        if not re.match(pattern, prd_id):
            errors.append(
                f"'prd_id' value '{prd_id}' does not match pattern {pattern}"
            )
        if not (3 <= len(prd_id) <= 64):
            errors.append(f"'prd_id' length must be 3–64, got {len(prd_id)}")

    # title
    title = prd.get("title", "")
    if not isinstance(title, str) or not (3 <= len(title) <= 200):
        errors.append("'title' must be a string of length 3–200")

    # slug pattern: ^[a-z0-9][a-z0-9-]*[a-z0-9]$
    slug = prd.get("slug", "")
    if not isinstance(slug, str):
        errors.append("'slug' must be a string")
    else:
        slug_pattern = r"^[a-z0-9][a-z0-9-]*[a-z0-9]$"
        if not re.match(slug_pattern, slug):
            errors.append(
                f"'slug' value '{slug}' does not match pattern {slug_pattern}"
            )

    # goal block
    goal = prd.get("goal", {})
    if not isinstance(goal, dict):
        errors.append("'goal' must be an object")
    else:
        goal_required = ["objective", "stopping_condition", "files_to_read_first", "proof_commands"]
        for field in goal_required:
            if field not in goal:
                errors.append(f"Missing required field in 'goal': '{field}'")
        if "objective" in goal:
            obj = goal["objective"]
            if not isinstance(obj, str) or not (10 <= len(obj) <= 400):
                errors.append("'goal.objective' must be a string of length 10–400")
        if "stopping_condition" in goal:
            sc = goal["stopping_condition"]
            if not isinstance(sc, str) or not (10 <= len(sc) <= 400):
                errors.append("'goal.stopping_condition' must be a string of length 10–400")
        if "files_to_read_first" in goal and not isinstance(goal["files_to_read_first"], list):
            errors.append("'goal.files_to_read_first' must be an array")
        if "proof_commands" in goal and not isinstance(goal["proof_commands"], list):
            errors.append("'goal.proof_commands' must be an array")
        if "max_turns" in goal:
            mt = goal["max_turns"]
            if not isinstance(mt, int) or not (1 <= mt <= 200):
                errors.append("'goal.max_turns' must be an integer 1–200")
        if "out_of_scope" in goal and not isinstance(goal["out_of_scope"], list):
            errors.append("'goal.out_of_scope' must be an array")

    # mission block
    mission = prd.get("mission", {})
    if not isinstance(mission, dict):
        errors.append("'mission' must be an object")
    else:
        mission_required = [
            "milestone", "expected_behavior", "verification_steps",
            "fulfills", "skill_name", "estimated_complexity"
        ]
        for field in mission_required:
            if field not in mission:
                errors.append(f"Missing required field in 'mission': '{field}'")
        if "expected_behavior" in mission:
            eb = mission["expected_behavior"]
            if not isinstance(eb, str) or len(eb) < 10:
                errors.append("'mission.expected_behavior' must be a string of length >= 10")
        if "verification_steps" in mission:
            vs = mission["verification_steps"]
            if not isinstance(vs, list) or len(vs) < 1:
                errors.append("'mission.verification_steps' must be a non-empty array")
            else:
                vc_pattern = r"^VC-[A-Z0-9][A-Z0-9-]*$"
                for v in vs:
                    if not re.match(vc_pattern, str(v)):
                        errors.append(f"'verification_steps' item '{v}' must match {vc_pattern}")
        if "fulfills" in mission:
            ff = mission["fulfills"]
            if not isinstance(ff, list) or len(ff) < 1:
                errors.append("'mission.fulfills' must be a non-empty array")
        if "skill_name" in mission:
            sn = mission["skill_name"]
            sn_pattern = r"^[a-z0-9][a-z0-9-]*$"
            if not isinstance(sn, str) or not re.match(sn_pattern, sn):
                errors.append(f"'mission.skill_name' must match {sn_pattern}")
        if "estimated_complexity" in mission:
            ec = mission["estimated_complexity"]
            if ec not in ("small", "medium", "large"):
                errors.append("'mission.estimated_complexity' must be 'small', 'medium', or 'large'")

    return errors


# ─────────────────────────────────────────────────────────────────────────────
# Bundle assembly
# ─────────────────────────────────────────────────────────────────────────────

def _assemble_bundle(prd: dict[str, Any], truncation_state: dict[str, Any] | None = None) -> str:
    """
    Assemble the Claude /goal bundle from a valid PRD.

    truncation_state is an internal dict tracking which optional items have been
    dropped. Callers pass None on the first call; recursive calls from
    _enforce_char_limit pass the state to guide further truncation.
    """
    goal = prd["goal"]
    mission = prd.get("mission", {})
    slices = prd.get("slices", [])

    if truncation_state is None:
        truncation_state = {
            "files_trimmed": 0,    # number of files_to_read_first items dropped
            "oos_trimmed": 0,      # number of out_of_scope items dropped
            "proof_trimmed": 0,    # number of proof_commands dropped
            "context_short": False, # whether context has been shortened
        }

    # ── <context> ─────────────────────────────────────────────────────────
    preconditions = mission.get("preconditions", [])
    if truncation_state.get("context_short"):
        context_lines = [f"PRD {prd['prd_id']}: {prd['title']}."]
    else:
        context_parts = [f"PRD {prd['prd_id']}: {prd['title']}."]
        milestone = mission.get("milestone", "")
        if milestone:
            context_parts.append(f"Milestone: {milestone}.")
        if preconditions:
            context_parts.append("Preconditions: " + "; ".join(preconditions) + ".")
        context_lines = context_parts

    context_body = " ".join(context_lines)

    # ── <task> ─────────────────────────────────────────────────────────────
    task_body = goal["objective"]

    # ── <requirements> ────────────────────────────────────────────────────
    req_lines: list[str] = []

    # BDD expected_behavior
    expected = mission.get("expected_behavior", "")
    if expected:
        req_lines.append(f"- {expected}")

    # Slices as numbered bullets
    for i, s in enumerate(slices, 1):
        req_lines.append(f"{i}. [{s['id']}] {s['title']}: {s['proof']}")

    # files_to_read_first — respect truncation
    files = goal.get("files_to_read_first", [])
    files_trimmed = truncation_state.get("files_trimmed", 0)
    visible_files = files[:max(0, len(files) - files_trimmed)] if files_trimmed < len(files) else []
    if visible_files:
        req_lines.append("Must read first: " + ", ".join(visible_files))
    elif files and files_trimmed > 0 and len(files) > files_trimmed:
        # Still some left but fewer
        req_lines.append("Must read first: " + ", ".join(visible_files))

    requirements_body = "\n".join(req_lines) if req_lines else "(see objective)"

    # ── <proof> ───────────────────────────────────────────────────────────
    proof_cmds = goal.get("proof_commands", [])
    proof_trimmed = truncation_state.get("proof_trimmed", 0)
    visible_proof = proof_cmds[:max(0, len(proof_cmds) - proof_trimmed)]
    proof_body = "\n".join(visible_proof) if visible_proof else "(run tests)"

    # ── <constraints> ─────────────────────────────────────────────────────
    out_of_scope = goal.get("out_of_scope", [])
    max_turns = goal.get("max_turns", 20)
    oos_trimmed = truncation_state.get("oos_trimmed", 0)
    visible_oos = out_of_scope[:max(0, len(out_of_scope) - oos_trimmed)]

    constraints_lines = []
    if visible_oos:
        constraints_lines.append("- Out of scope: " + "; ".join(visible_oos))
    constraints_lines.append(f"- Max turns: {max_turns} (stop after {max_turns} turns if not done)")
    constraints_body = "\n".join(constraints_lines)

    # ── <done-when> ───────────────────────────────────────────────────────
    done_when_body = goal["stopping_condition"]

    # ── assemble ──────────────────────────────────────────────────────────
    bundle = (
        f"<context>\n{context_body}\n</context>\n\n"
        f"<task>\n{task_body}\n</task>\n\n"
        f"<requirements>\n{requirements_body}\n</requirements>\n\n"
        f"<proof>\n{proof_body}\n</proof>\n\n"
        f"<constraints>\n{constraints_body}\n</constraints>\n\n"
        f"<done-when>\n{done_when_body}\n</done-when>"
    )

    return bundle


def _enforce_char_limit(prd: dict[str, Any], limit: int = CHAR_LIMIT) -> tuple[str, bool]:
    """
    Assemble the bundle and truncate intelligently if it exceeds limit.

    Truncation order (least important first):
      1. out_of_scope items (remove one at a time from the end)
      2. files_to_read_first items (remove one at a time from the end)
      3. proof_commands (remove one at a time from the end)
      4. context shortened to one-liner

    Returns (bundle_text, was_truncated).
    """
    goal = prd["goal"]
    state: dict[str, Any] = {
        "files_trimmed": 0,
        "oos_trimmed": 0,
        "proof_trimmed": 0,
        "context_short": False,
    }

    bundle = _assemble_bundle(prd, state)
    if len(bundle) <= limit:
        return bundle, False

    # Pass 1: trim out_of_scope one item at a time
    oos = goal.get("out_of_scope", [])
    while len(bundle) > limit and state["oos_trimmed"] < len(oos):
        state["oos_trimmed"] += 1
        bundle = _assemble_bundle(prd, state)

    if len(bundle) <= limit:
        return bundle, True

    # Pass 2: trim files_to_read_first one item at a time
    files = goal.get("files_to_read_first", [])
    while len(bundle) > limit and state["files_trimmed"] < len(files):
        state["files_trimmed"] += 1
        bundle = _assemble_bundle(prd, state)

    if len(bundle) <= limit:
        return bundle, True

    # Pass 3: shorten context to one-liner
    if not state["context_short"]:
        state["context_short"] = True
        bundle = _assemble_bundle(prd, state)

    if len(bundle) <= limit:
        return bundle, True

    # Pass 4: trim proof_commands one at a time
    proof = goal.get("proof_commands", [])
    while len(bundle) > limit and state["proof_trimmed"] < max(0, len(proof) - 1):
        state["proof_trimmed"] += 1
        bundle = _assemble_bundle(prd, state)

    # Final: hard truncate at limit - 5 + ellipsis as absolute last resort
    if len(bundle) > limit:
        bundle = bundle[: limit - 4] + "\n..."

    return bundle, True


# ─────────────────────────────────────────────────────────────────────────────
# Main entry points
# ─────────────────────────────────────────────────────────────────────────────

def emit_file(prd_path: Path, output_dir: Path, validate_only: bool = False) -> int:
    """
    Process one PRD file. Returns an exit code (0 = success, 2 = validation error).
    """
    # Parse JSON
    try:
        raw = prd_path.read_text(encoding="utf-8")
        prd = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f"ERROR: {prd_path}: invalid JSON: {exc}", file=sys.stderr)
        return 2

    # Validate
    errors = _validate_prd(prd)
    if errors:
        print(f"ERROR: {prd_path}: schema validation failed:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 2

    # Assemble bundle with truncation
    bundle, was_truncated = _enforce_char_limit(prd, CHAR_LIMIT)

    if was_truncated:
        print(
            f"WARNING: {prd_path}: bundle exceeded {CHAR_LIMIT} chars — truncated intelligently "
            f"(final: {len(bundle)} chars)",
            file=sys.stderr,
        )

    prd_id = prd["prd_id"]

    if validate_only:
        print(bundle)
        print(f"\nVALID ({len(bundle)} chars / {CHAR_LIMIT} limit)")
        return 0

    # Write output
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{prd_id}.goal.md"
    output_path.write_text(bundle, encoding="utf-8")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Emit a Claude /goal bundle from a canonical Sigma PRD."
    )
    parser.add_argument(
        "prd_paths",
        nargs="+",
        help="Path(s) to canonical PRD JSON files. Glob patterns supported.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(REPO_ROOT / ".sigma" / "dispatch" / "claude"),
        help="Output directory for .goal.md bundles (default: .sigma/dispatch/claude)",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate + print bundle without writing the file.",
    )
    args = parser.parse_args(argv)

    output_dir = Path(args.output_dir)
    exit_code = 0

    # Expand globs
    resolved_paths: list[Path] = []
    for pattern in args.prd_paths:
        matches = glob.glob(pattern, recursive=True)
        if matches:
            resolved_paths.extend(Path(m) for m in matches)
        else:
            # Treat as literal path (may not exist — emit_file handles errors)
            resolved_paths.append(Path(pattern))

    for prd_path in resolved_paths:
        code = emit_file(prd_path, output_dir, validate_only=args.validate)
        if code != 0:
            exit_code = code

    return exit_code


def generate(prd_dict: dict[str, Any]) -> str:
    """Generate a Claude /goal bundle string from an in-memory PRD dict.

    Validates the PRD, assembles the bundle with intelligent truncation,
    and returns the bundle text. Raises ValueError on schema validation failure.

    Args:
        prd_dict: A PRD dict conforming to sigma-prd-canonical.schema.json.

    Returns:
        Bundle string (XML-tagged, ≤4000 chars).

    Raises:
        ValueError: If the PRD fails schema validation.
    """
    errors = _validate_prd(prd_dict)
    if errors:
        raise ValueError(f"PRD schema validation failed: {'; '.join(errors)}")
    bundle, _ = _enforce_char_limit(prd_dict, CHAR_LIMIT)
    return bundle


if __name__ == "__main__":
    sys.exit(main())
