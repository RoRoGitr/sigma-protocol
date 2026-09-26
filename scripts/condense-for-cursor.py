#!/usr/bin/env python3
"""condense-for-cursor.py — turn a canonical SKILL.md into a Cursor .mdc rule.

Cursor rules are budget-sensitive: they load into context, so a rule must be
tight. This condenser:
  - parses the SKILL.md YAML frontmatter (name, description, triggers, department, globs)
  - emits valid Cursor MDC frontmatter (description, globs, alwaysApply)
  - keeps the instructional body but strips changelog/version cruft and caps length
  - appends a pointer to the full canonical skill so nothing is lost

Cursor rule semantics:
  - description present + alwaysApply:false  -> "agent-requested" rule (model pulls it in by description)
  - globs present                            -> auto-attaches when matching files are in context
  - alwaysApply:true                         -> always loaded (we never default to this)

Usage:
  python3 scripts/condense-for-cursor.py --input <SKILL.md> --output <out.mdc> [--max-lines N]
"""
import argparse
import re
import sys
from pathlib import Path

MAX_LINES_DEFAULT = 160


def parse_frontmatter(text: str):
    """Return (meta: dict, body: str). meta values are raw strings/lists (best-effort)."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    raw = text[3:end].strip("\n")
    body = text[end + 4 :]
    if body.startswith("\n"):
        body = body[1:]
    meta = {}
    key = None
    for line in raw.split("\n"):
        if re.match(r"^[A-Za-z0-9_-]+:", line):
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip()
            if val == "":
                meta[key] = []  # list follows
            else:
                meta[key] = val.strip().strip('"').strip("'")
        elif re.match(r"^\s*-\s+", line) and key is not None and isinstance(meta.get(key), list):
            meta[key].append(re.sub(r"^\s*-\s+", "", line).strip().strip('"').strip("'"))
    return meta, body


def condense_body(body: str, max_lines: int) -> str:
    lines = body.split("\n")
    out, skip_block = [], False
    for line in lines:
        low = line.strip().lower()
        # Drop changelog / version / "remember" motivational tails and their blocks.
        if low.startswith("## changelog") or low.startswith("### changelog"):
            skip_block = True
            continue
        if skip_block:
            if line.startswith("#") and "changelog" not in low:
                skip_block = False
            else:
                continue
        if low.startswith("version:") or low.startswith("source:") or low.startswith("last_updated:"):
            continue
        if re.match(r"^\s*[_*]+remember[:*]", low):
            continue
        out.append(line)
    # Trim trailing blank lines, then cap.
    while out and out[-1].strip() == "":
        out.pop()
    truncated = False
    if len(out) > max_lines:
        out = out[:max_lines]
        truncated = True
    text = "\n".join(out).rstrip()
    if truncated:
        text += "\n\n> Condensed for Cursor. Full skill: `.claude/skills/<slug>/SKILL.md`."
    return text


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--max-lines", type=int, default=MAX_LINES_DEFAULT)
    args = ap.parse_args()

    src = Path(args.input)
    if not src.is_file():
        print(f"condense-for-cursor: input not found: {src}", file=sys.stderr)
        return 2
    meta, body = parse_frontmatter(src.read_text(encoding="utf-8"))

    name = meta.get("name") or src.parent.name if src.name == "SKILL.md" else src.stem
    description = meta.get("description", "").replace("\n", " ").strip()
    if not description:
        description = f"Sigma skill: {name}."
    globs = meta.get("globs")
    triggers = meta.get("triggers")
    department = meta.get("department")

    # Build Cursor-valid frontmatter. alwaysApply is always false — rules are
    # agent-requested by description (or auto-attached by globs when provided).
    fm = ["---", f'description: "{description}"']
    if globs:
        if isinstance(globs, list):
            fm.append("globs: " + ",".join(globs))
        else:
            fm.append(f"globs: {globs}")
    fm.append("alwaysApply: false")
    # Preserve routing metadata as comments (Cursor ignores unknown keys, but keep it clean).
    if department:
        fm.append(f"# department: {department}")
    if triggers:
        tlist = triggers if isinstance(triggers, list) else [triggers]
        fm.append(f"# triggers: {', '.join(tlist)}")
    fm.append("---")

    condensed = condense_body(body, args.max_lines).replace("<slug>", str(name))
    out_text = "\n".join(fm) + "\n\n" + condensed + "\n"

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(out_text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
