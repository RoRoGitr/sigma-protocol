#!/usr/bin/env python3
"""
scripts/emitters/emit_kanban_prompt.py

Template-derived dispatch prompts for plain kanban tasks (no PRD frontmatter).
Used by hq_state.py via compute_dispatch_prompts() (D2 wires this).

3 CLI flavors: claude (XML), codex (role-framed), droid (mission-md-lite).
Pure stdlib. No subprocess. No file IO per call. ≤2000 chars per prompt.

Plan: ~/.claude/plans/hashed-sparking-seahorse.md (D3 row)
"""
from __future__ import annotations
import html
from typing import Any

_LIMIT = 2000

_CLAUDE_T = """\
<context>
Working on kanban task in workspace: {workspace}
Task ID: {id}  |  Status: {status}  |  Priority: {priority}
</context>

<task>
{title}
</task>

<details>
{description}
</details>

<done-when>
This task is moved to status "done" in the kanban board.
Acceptance criteria: implementation complete, tests pass if applicable, no regressions.
</done-when>

<constraints>
- Stay within the workspace's existing patterns
- Update kanban status when done
- Max ~30 turns of work — escalate if scope grows
</constraints>"""

_CODEX_T = """\
You are a senior engineer working on a kanban task in workspace `{workspace}`. \
Bias to action, persist end-to-end, use `apply_patch` for diffs.

# Objective
{title}

# Context
- Task ID: {id}  |  Status: {status}  |  Priority: {priority}
- Skill: {skill}

# Details
{description}

# Done when
1. Implementation complete + tests pass (if applicable)
2. No regressions in adjacent code
3. Kanban status moved to "done"
4. Or stop after 30 turns

# Working style
- Concise + friendly coding teammate tone
- Use `apply_patch` for code diffs
- 1-sentence acknowledge before each tool batch"""

_DROID_T = """\
# Mission: {title}

## Goal
Complete the kanban task `{id}` in workspace `{workspace}`.

## Scope
- In scope: {description}
- Out of scope: anything not directly required by the acceptance criteria

## Success criteria
Task moved to status "done" with all acceptance criteria met. \
Implementation complete, tests pass, no regressions.

## Required reading (load BEFORE planning)
- Workspace kanban board for `{workspace}`
- Any files mentioned in the task description above

## Proof of progress
- Implementation diff
- Test output (if applicable)
- Updated kanban status"""


def _get(task: dict[str, Any], *keys: str, default: str = "") -> str:
    for k in keys:
        v = task.get(k)
        if v and str(v).strip():
            return str(v).strip()
    return default


def _cut(text: str) -> str:
    return text if len(text) <= _LIMIT else text[: _LIMIT - 3] + "..."


def emit_kanban_prompts(task: dict[str, Any], workspace: str = "") -> dict[str, str]:
    """Return {'claude': str, 'codex': str, 'droid': str} for a kanban task."""
    title = _get(task, "title", default="Untitled kanban task")
    desc = _get(task, "description", "body")
    tid = _get(task, "id", default="(no ID)")
    priority = _get(task, "priority", default="medium")
    status = _get(task, "status", default="todo")
    skill = _get(task, "skill", default="general")
    ws = workspace or "(unknown)"

    ctx = dict(id=tid, status=status, priority=priority, workspace=ws, skill=skill)
    return {
        "claude": _cut(_CLAUDE_T.format(
            title=html.escape(title),
            description=html.escape(desc) if desc else
                "No additional details — see workspace kanban board for context.",
            **ctx,
        )),
        "codex": _cut(_CODEX_T.format(
            title=title,
            description=desc or "(See workspace kanban board for full context.)",
            **ctx,
        )),
        "droid": _cut(_DROID_T.format(
            title=title,
            description=desc or title,
            **ctx,
        )),
    }


if __name__ == "__main__":
    import argparse, json, sys

    ap = argparse.ArgumentParser(description="Emit dispatch prompts for a kanban task.")
    ap.add_argument("--task", required=True, help='JSON task dict, e.g. \'{"title":"foo"}\'')
    ap.add_argument("--workspace", default="", help="Workspace name")
    ap.add_argument("--cli", choices=["claude", "codex", "droid", "all"], default="all")
    args = ap.parse_args()

    try:
        task_dict: dict[str, Any] = json.loads(args.task)
    except json.JSONDecodeError as exc:
        print(f"Error: --task must be valid JSON — {exc}", file=sys.stderr)
        sys.exit(1)

    result = emit_kanban_prompts(task_dict, workspace=args.workspace)
    print(json.dumps(result, indent=2) if args.cli == "all" else result[args.cli])
