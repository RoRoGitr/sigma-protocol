#!/usr/bin/env python3
"""
emit_codex_bundle.py — Canonical PRD → Codex /goal bundle emitter.

Phase 2b of the Sigma Protocol 3.0 CLI-Native PRD Upgrade.

Transforms a canonical PRD (matching schemas/sigma-prd-canonical.schema.json)
into a Codex-flavored bundle at .sigma/dispatch/codex/<prd-id>.goal.md

Bundle format follows GPT-5-Codex preamble cadence (per OpenAI docs):
  - Role framing FIRST ("You are a senior engineer...")
  - NO XML tags — markdown headings only
  - Numbered steps for files, implementation plan, and proof of progress
  - Explicit "Done when" stopping condition (never truncated)
  - apply_patch format mention in working-style block
  - "Bias to action; persist end-to-end"

4000-char output budget enforced. Truncation order (most dispensable first):
  1. Working-style block (drop to 2-line stub)
  2. Out-of-scope bullet items (remove from the end, one at a time)
  3. Implementation plan items beyond the first 3
  4. Files-to-read items beyond the top 5
  5. Proof-of-progress commands beyond the top 3
  NEVER truncate: role-frame opener, Objective, Done-when sections.

Usage:
    python3 emit_codex_bundle.py <prd-path-or-glob> [--output-dir .sigma/dispatch/codex] [--validate]

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

# Repo name used in the role-frame opener (derived from cwd basename at emit time)
_REPO_NAME = REPO_ROOT.name


# ─────────────────────────────────────────────────────────────────────────────
# Schema validation (pure stdlib — mirrors emit_claude_bundle.py)
# ─────────────────────────────────────────────────────────────────────────────

def _validate_prd(prd: dict[str, Any]) -> list[str]:
    """
    Validate a PRD dict against the canonical schema.
    Returns a list of error strings (empty = valid).

    Implements required fields and patterns from sigma-prd-canonical.schema.json
    without the jsonschema library.
    """
    errors: list[str] = []

    # Required top-level fields
    required = ["prd_id", "title", "slug", "goal", "mission"]
    for field in required:
        if field not in prd:
            errors.append(f"Missing required field: '{field}'")

    if errors:
        return errors

    # prd_id pattern
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

    # slug
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
            "fulfills", "skill_name", "estimated_complexity",
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

def _assemble_bundle(prd: dict[str, Any], state: dict[str, Any]) -> str:
    """
    Assemble the Codex /goal bundle from a valid PRD.

    state controls what optional content is included during truncation:
      files_limit    — max files_to_read_first items (None = unlimited)
      proof_limit    — max proof_commands items (None = unlimited)
      plan_limit     — max implementation plan items (None = unlimited)
      oos_limit      — max out_of_scope items (None = unlimited, 0 = omit section)
      style_short    — if True, use 2-line working style stub instead of full block
    """
    goal = prd["goal"]
    mission = prd.get("mission", {})
    slices = prd.get("slices", [])

    files_limit: int | None = state.get("files_limit")
    proof_limit: int | None = state.get("proof_limit")
    plan_limit: int | None = state.get("plan_limit")
    oos_limit: int | None = state.get("oos_limit")
    style_short: bool = state.get("style_short", False)

    # ── Role-frame opener (FIRST — Codex requires this) ────────────────────
    prd_id = prd["prd_id"]
    title = prd["title"]
    role_line = (
        f"You are a senior engineer working on {_REPO_NAME}. "
        "You implement features end-to-end with bias to action, "
        "persist until done, and follow `apply_patch` format for diffs."
    )

    # ── # Objective ────────────────────────────────────────────────────────
    objective_body = goal["objective"]

    # ── # Files to read FIRST ─────────────────────────────────────────────
    files = goal.get("files_to_read_first", [])
    if files_limit is not None:
        files = files[:files_limit]
    if files:
        files_lines = "\n".join(f"{i}. {f}" for i, f in enumerate(files, 1))
    else:
        files_lines = "(no specific files required — start from the objective)"

    # ── # Implementation plan ─────────────────────────────────────────────
    if slices:
        plan_items = [f"{s['id']}: {s['title']}" for s in slices]
    else:
        # Fall back to expected_behavior as a single plan bullet
        expected = mission.get("expected_behavior", "")
        if expected:
            plan_items = [expected[:200] + ("..." if len(expected) > 200 else "")]
        else:
            plan_items = [objective_body]
    if plan_limit is not None:
        plan_items = plan_items[:plan_limit]
    plan_lines = "\n".join(f"{i}. {item}" for i, item in enumerate(plan_items, 1))

    # ── # Out of scope ─────────────────────────────────────────────────────
    out_of_scope = goal.get("out_of_scope", [])
    if oos_limit is not None:
        out_of_scope = out_of_scope[:oos_limit]

    oos_section = ""
    if out_of_scope:
        oos_lines = "\n".join(f"- {item}" for item in out_of_scope)
        oos_section = f"\n# Out of scope\n{oos_lines}"

    # ── # Done when ────────────────────────────────────────────────────────
    max_turns = goal.get("max_turns", 20)
    done_when_body = (
        f"{goal['stopping_condition']} "
        f"Or stop after {max_turns} turns."
    )

    # ── # Proof of progress ────────────────────────────────────────────────
    proof_cmds = goal.get("proof_commands", [])
    if proof_limit is not None:
        proof_cmds = proof_cmds[:proof_limit]
    if proof_cmds:
        proof_lines = "\n".join(f"{i}. `{cmd}`" for i, cmd in enumerate(proof_cmds, 1))
    else:
        proof_lines = "(run the tests defined in the stopping condition)"

    # ── # Working style ────────────────────────────────────────────────────
    if style_short:
        style_body = (
            "- Acknowledge briefly (1 sentence) before each tool batch\n"
            "- Use `apply_patch` for code diffs; persist end-to-end this turn"
        )
    else:
        style_body = (
            "- Acknowledge briefly (1 sentence) before each tool batch\n"
            "- Use `apply_patch` for code diffs\n"
            "- Persist end-to-end this turn; do not stop mid-task\n"
            "- Tone: concise + friendly coding teammate (not corporate)"
        )

    # ── Assemble ───────────────────────────────────────────────────────────
    parts = [
        role_line,
        "",
        "# Objective",
        objective_body,
        "",
        "# Files to read FIRST (before writing any code)",
        files_lines,
        "",
        "# Implementation plan",
        plan_lines,
    ]

    if oos_section:
        parts.append(oos_section)

    parts += [
        "",
        "# Done when",
        done_when_body,
        "",
        "# Proof of progress",
        proof_lines,
        "",
        "# Working style",
        style_body,
    ]

    return "\n".join(parts)


def _enforce_char_limit(prd: dict[str, Any], limit: int = CHAR_LIMIT) -> tuple[str, bool]:
    """
    Assemble the bundle and truncate intelligently if it exceeds limit.

    Truncation order (least important first — Objective and Done-when NEVER truncated):
      1. Style block → 2-line stub
      2. Out-of-scope items (remove from the end, one at a time)
      3. Implementation plan items (keep top 3 minimum)
      4. Files-to-read items (keep top 5 maximum; then trim to top 3, then 1)
      5. Proof-of-progress items (keep top 3)

    Returns (bundle_text, was_truncated).
    """
    goal = prd["goal"]
    slices = prd.get("slices", [])

    state: dict[str, Any] = {
        "files_limit": None,
        "proof_limit": None,
        "plan_limit": None,
        "oos_limit": None,
        "style_short": False,
    }

    bundle = _assemble_bundle(prd, state)
    if len(bundle) <= limit:
        return bundle, False

    # Pass 1: shorten working-style block
    state["style_short"] = True
    bundle = _assemble_bundle(prd, state)
    if len(bundle) <= limit:
        return bundle, True

    # Pass 2: trim out_of_scope one at a time
    oos = goal.get("out_of_scope", [])
    remaining_oos = len(oos)
    while len(bundle) > limit and remaining_oos > 0:
        remaining_oos -= 1
        state["oos_limit"] = remaining_oos
        bundle = _assemble_bundle(prd, state)
    if len(bundle) <= limit:
        return bundle, True

    # Pass 3: trim implementation plan to 3 items min
    plan_count = len(slices) if slices else 1
    while len(bundle) > limit and plan_count > 3:
        plan_count -= 1
        state["plan_limit"] = plan_count
        bundle = _assemble_bundle(prd, state)
    if len(bundle) <= limit:
        return bundle, True

    # Pass 4: cap files_to_read_first at 5, then 3, then 1
    files = goal.get("files_to_read_first", [])
    for cap in (5, 3, 1):
        if len(files) > cap:
            state["files_limit"] = cap
            bundle = _assemble_bundle(prd, state)
            if len(bundle) <= limit:
                return bundle, True

    # Pass 5: cap proof_commands at 3
    proof = goal.get("proof_commands", [])
    if len(proof) > 3:
        state["proof_limit"] = 3
        bundle = _assemble_bundle(prd, state)
        if len(bundle) <= limit:
            return bundle, True

    # Final fallback: hard truncate everything except role frame + Objective + Done-when
    # Build a minimal bundle with just the non-negotiable parts
    role_line = (
        f"You are a senior engineer working on {_REPO_NAME}. "
        "You implement features end-to-end with bias to action, "
        "persist until done, and follow `apply_patch` format for diffs."
    )
    minimal = (
        f"{role_line}\n\n"
        f"# Objective\n{goal['objective']}\n\n"
        f"# Done when\n{goal['stopping_condition']} Or stop after {goal.get('max_turns', 20)} turns.\n\n"
        "# Working style\n"
        "- Use `apply_patch` for code diffs; persist end-to-end this turn"
    )
    if len(minimal) <= limit:
        return minimal, True

    # Absolute last resort: hard truncate at limit
    bundle = minimal[: limit - 4] + "\n..."
    return bundle, True


# ─────────────────────────────────────────────────────────────────────────────
# Main entry points
# ─────────────────────────────────────────────────────────────────────────────

def emit_file(prd_path: Path, output_dir: Path, validate_only: bool = False) -> int:
    """
    Process one PRD file. Returns an exit code (0 = success, 2 = validation error).
    """
    try:
        raw = prd_path.read_text(encoding="utf-8")
        prd = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f"ERROR: {prd_path}: invalid JSON: {exc}", file=sys.stderr)
        return 2

    errors = _validate_prd(prd)
    if errors:
        print(f"ERROR: {prd_path}: schema validation failed:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 2

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

    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{prd_id}.goal.md"
    output_path.write_text(bundle, encoding="utf-8")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Emit a Codex /goal bundle from a canonical Sigma PRD."
    )
    parser.add_argument(
        "prd_paths",
        nargs="+",
        help="Path(s) to canonical PRD JSON files. Glob patterns supported.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(REPO_ROOT / ".sigma" / "dispatch" / "codex"),
        help="Output directory for .goal.md bundles (default: .sigma/dispatch/codex)",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate + print bundle without writing the file.",
    )
    args = parser.parse_args(argv)

    output_dir = Path(args.output_dir)
    exit_code = 0

    resolved_paths: list[Path] = []
    for pattern in args.prd_paths:
        matches = glob.glob(pattern, recursive=True)
        if matches:
            resolved_paths.extend(Path(m) for m in matches)
        else:
            resolved_paths.append(Path(pattern))

    for prd_path in resolved_paths:
        code = emit_file(prd_path, output_dir, validate_only=args.validate)
        if code != 0:
            exit_code = code

    return exit_code


def generate(prd_dict: dict[str, Any]) -> str:
    """Generate a Codex /goal bundle string from an in-memory PRD dict.

    Validates the PRD, assembles the bundle with intelligent truncation,
    and returns the bundle text. Raises ValueError on schema validation failure.

    Args:
        prd_dict: A PRD dict conforming to sigma-prd-canonical.schema.json.

    Returns:
        Bundle string (markdown, no XML tags, ≤4000 chars).

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
