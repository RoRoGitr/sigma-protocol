#!/usr/bin/env python3
"""Generate thin step-* pointer stubs under .agents/skills/ and .codex/skills/."""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STEPS_DIR = ROOT / "steps"
TARGET_DIRS = (
    ROOT / ".agents" / "skills",
    ROOT / ".codex" / "skills",
)

FORBIDDEN = {
    "step-5a-prototype-prep",
    "step-5b-prd-to-json",
    "step-11a-prd-to-json",
    "step-11b-prd-swarm",
    "step-1-5-offer-architecture",
    "step-0.5-mission",
    "step-verify",
}


def parse_description(step_path: Path) -> str:
    text = step_path.read_text(encoding="utf-8")
    m = re.search(r'^description:\s*"(.+?)"\s*$', text, re.MULTILINE)
    if m:
        return m.group(1)
    m = re.search(r"^description:\s*(.+?)\s*$", text, re.MULTILINE)
    return m.group(1).strip() if m else f"Sigma workflow step: {step_path.name}"


def pointer_body(name: str, description: str) -> str:
    canonical = f"steps/{name}"
    safe_desc = description.replace("\\", "\\\\").replace('"', '\\"')
    return f"""---
name: {name}
description: "{safe_desc}"
canonical_source: "{canonical}"
---

# /{name} — Pointer

The canonical definition lives at `{canonical}` (extensionless).

**To invoke:** run `/{name}` — rendered at `commands/{name}.md` via `./scripts/sync-steps-to-platforms.sh`.

**To update behavior:** edit `{canonical}` then run `./scripts/sync-steps-to-platforms.sh --prune`. Do not edit this pointer body.
"""


def purge_forbidden(base: Path) -> None:
    for legacy in sorted(FORBIDDEN):
        legacy_dir = base / legacy
        if legacy_dir.exists():
            shutil.rmtree(legacy_dir)
            print(f"[-] {legacy_dir.relative_to(ROOT)}")


def main() -> int:
    if not STEPS_DIR.is_dir():
        print(f"ERROR: missing {STEPS_DIR}", file=sys.stderr)
        return 1

    expected: set[str] = set()
    written = 0

    for target in TARGET_DIRS:
        target.mkdir(parents=True, exist_ok=True)
        purge_forbidden(target)

    for step_path in sorted(STEPS_DIR.glob("step-*")):
        if not step_path.is_file():
            continue
        name = step_path.name
        if name in FORBIDDEN:
            continue
        expected.add(name)
        desc = parse_description(step_path)
        body = pointer_body(name, desc)
        for target in TARGET_DIRS:
            out_dir = target / name
            out_dir.mkdir(parents=True, exist_ok=True)
            out_file = out_dir / "SKILL.md"
            out_file.write_text(body, encoding="utf-8")
            print(f"[+] {out_file.relative_to(ROOT)}")
            written += 1

    print(f"\nWrote {written} pointer stub(s) across {len(TARGET_DIRS)} target(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
