#!/usr/bin/env python3
"""
mission-stack.py — Mission DAG validator, active leaf resolver, halt cascade logic.

CLI:
  mission-stack.py --validate {slug}
  mission-stack.py --resolve-active {workspace}
  mission-stack.py --halt {slug} --reason "..."
  mission-stack.py --list-tree {workspace}
  mission-stack.py --node-states {workspace} --json

Data lives at: ${SIGMAHQ_HOME:-~/.commandboard}/missions/*/mission.json
Active symlinks: ${SIGMAHQ_HOME:-~/.commandboard}/missions/active/{workspace-slug}
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from collections import deque
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SIGMAHQ_HOME = Path(os.environ.get("SIGMAHQ_HOME", os.environ.get("CLAUDE_CODE_COMMANDBOARD", str(Path.home() / ".commandboard")))).expanduser()
MISSIONS_DIR = SIGMAHQ_HOME / "missions"
ACTIVE_DIR = MISSIONS_DIR / "active"

TERMINAL_STATUSES = {"completed", "abandoned"}
RUNNABLE_STATUSES = {"active", "runnable", "paused"}

LAST_RESULT_VALUES = {"pass", "fail", "unknown", None}

# ---------------------------------------------------------------------------
# Logging — stderr only, structured prefix
# ---------------------------------------------------------------------------

logging.basicConfig(
    stream=sys.stderr,
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
log = logging.getLogger("mission-stack")


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def load_mission(slug: str) -> dict[str, Any]:
    """Load and parse a single mission.json by slug.

    Raises SystemExit(2) on missing file or malformed JSON.
    """
    mission_path = MISSIONS_DIR / slug / "mission.json"
    if not mission_path.exists():
        print(f"ERROR: mission.json not found: {mission_path}", file=sys.stderr)
        sys.exit(2)
    try:
        with mission_path.open() as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"ERROR: malformed mission.json at {mission_path}: {e}", file=sys.stderr)
        sys.exit(2)
    if "id" not in data or "status" not in data:
        print(f"ERROR: mission.json missing required fields (id, status): {mission_path}", file=sys.stderr)
        sys.exit(2)
    return data


def load_all_missions() -> dict[str, dict[str, Any]]:
    """Scan MISSIONS_DIR for all mission.json files. Returns {slug: mission_data}.

    Logs and skips any malformed entries (does not exit).
    """
    missions: dict[str, dict[str, Any]] = {}
    if not MISSIONS_DIR.exists():
        return missions
    for entry in MISSIONS_DIR.iterdir():
        if entry.name.startswith("_") or entry.name == "active" or entry.name == "archive":
            continue
        if not entry.is_dir():
            continue
        mission_path = entry / "mission.json"
        if not mission_path.exists():
            continue
        try:
            with mission_path.open() as f:
                data = json.load(f)
            slug = data.get("id", entry.name)
            missions[slug] = data
        except (json.JSONDecodeError, OSError) as e:
            log.warning("Skipping malformed mission at %s: %s", entry, e)
    return missions


def missions_for_workspace(workspace: str, missions: dict[str, dict]) -> dict[str, dict]:
    """Filter missions belonging to the given workspace."""
    return {slug: m for slug, m in missions.items() if m.get("workspace") == workspace}


# ---------------------------------------------------------------------------
# DAG helpers (with doctests)
# ---------------------------------------------------------------------------

def build_adjacency(missions: dict[str, dict]) -> dict[str, list[str]]:
    """Build {slug: [child_slugs]} from missions dict.

    >>> m = {
    ...   'a': {'id': 'a', 'children': ['b', 'c'], 'parent_id': None, 'status': 'active', 'workspace': 'w'},
    ...   'b': {'id': 'b', 'children': [], 'parent_id': 'a', 'status': 'runnable', 'workspace': 'w'},
    ...   'c': {'id': 'c', 'children': [], 'parent_id': 'a', 'status': 'runnable', 'workspace': 'w'},
    ... }
    >>> adj = build_adjacency(m)
    >>> sorted(adj['a'])
    ['b', 'c']
    >>> adj['b']
    []
    """
    return {slug: list(m.get("children", [])) for slug, m in missions.items()}


def detect_cycle(missions: dict[str, dict]) -> list[str] | None:
    """Return a cycle path [a, b, c, a] if a cycle exists, else None.

    Uses DFS with white/grey/black colouring.

    >>> # Acyclic
    >>> m = {'a': {'children': ['b']}, 'b': {'children': ['c']}, 'c': {'children': []}}
    >>> detect_cycle(m) is None
    True

    >>> # Cycle: a -> b -> a
    >>> m2 = {'a': {'children': ['b']}, 'b': {'children': ['a']}}
    >>> cycle = detect_cycle(m2)
    >>> cycle is not None
    True
    >>> len(cycle) >= 2
    True

    >>> # Self-loop
    >>> m3 = {'x': {'children': ['x']}}
    >>> detect_cycle(m3) is not None
    True
    """
    WHITE, GREY, BLACK = 0, 1, 2
    color: dict[str, int] = {slug: WHITE for slug in missions}
    parent: dict[str, str | None] = {slug: None for slug in missions}

    def dfs(node: str) -> list[str] | None:
        color[node] = GREY
        for child in missions.get(node, {}).get("children", []):
            if child not in color:
                # Child references a mission not in our set — skip
                continue
            if color[child] == GREY:
                # Found cycle — reconstruct path
                path = [child, node]
                cur = node
                while parent[cur] is not None and parent[cur] != child:
                    cur = parent[cur]  # type: ignore[assignment]
                    path.append(cur)
                path.append(child)
                path.reverse()
                return path
            if color[child] == WHITE:
                parent[child] = node
                result = dfs(child)
                if result:
                    return result
        color[node] = BLACK
        return None

    for slug in missions:
        if color[slug] == WHITE:
            result = dfs(slug)
            if result:
                return result
    return None


def check_reciprocal_edges(missions: dict[str, dict]) -> list[str]:
    """Verify that parent_id and children[] are reciprocal.

    Returns list of violation descriptions. Empty = valid.

    >>> m = {
    ...   'a': {'id': 'a', 'children': ['b'], 'parent_id': None},
    ...   'b': {'id': 'b', 'children': [], 'parent_id': 'a'},
    ... }
    >>> check_reciprocal_edges(m)
    []

    >>> # b.parent_id = 'a' but 'a' doesn't list 'b' in children
    >>> m2 = {
    ...   'a': {'id': 'a', 'children': [], 'parent_id': None},
    ...   'b': {'id': 'b', 'children': [], 'parent_id': 'a'},
    ... }
    >>> len(check_reciprocal_edges(m2)) > 0
    True
    """
    violations = []
    for slug, m in missions.items():
        parent_id = m.get("parent_id")
        if parent_id:
            parent = missions.get(parent_id)
            if parent is None:
                violations.append(f"{slug}.parent_id={parent_id!r} references unknown mission")
            elif slug not in parent.get("children", []):
                violations.append(
                    f"{slug}.parent_id={parent_id!r} but {parent_id}.children does not include {slug!r}"
                )
        for child_id in m.get("children", []):
            child = missions.get(child_id)
            if child is None:
                violations.append(f"{slug}.children includes {child_id!r} which does not exist")
            elif child.get("parent_id") != slug:
                violations.append(
                    f"{slug}.children includes {child_id!r} but {child_id}.parent_id={child.get('parent_id')!r}"
                )
    return violations


def active_descendant_count(slug: str, missions: dict[str, dict]) -> int:
    """Count descendants with status in {active, runnable, paused} recursively.

    >>> m = {
    ...   'root': {'children': ['c1', 'c2'], 'status': 'active'},
    ...   'c1':   {'children': ['c3'],       'status': 'runnable'},
    ...   'c2':   {'children': [],           'status': 'completed'},
    ...   'c3':   {'children': [],           'status': 'active'},
    ... }
    >>> active_descendant_count('root', m)
    2
    >>> active_descendant_count('c2', m)
    0
    """
    count = 0
    queue = deque(missions.get(slug, {}).get("children", []))
    visited: set[str] = set()
    while queue:
        child_id = queue.popleft()
        if child_id in visited:
            continue
        visited.add(child_id)
        child = missions.get(child_id)
        if child is None:
            continue
        if child.get("status") in RUNNABLE_STATUSES:
            count += 1
        queue.extend(child.get("children", []))
    return count


def find_active_leaf(workspace: str, missions: dict[str, dict]) -> str | None:
    """Return the slug with status='active' for this workspace, or None.

    >>> m = {
    ...   'a': {'workspace': 'w', 'status': 'active'},
    ...   'b': {'workspace': 'w', 'status': 'runnable'},
    ...   'c': {'workspace': 'other', 'status': 'active'},
    ... }
    >>> find_active_leaf('w', m)
    'a'
    >>> find_active_leaf('other', m)
    'c'
    >>> find_active_leaf('missing', m) is None
    True
    """
    for slug, m in missions.items():
        if m.get("workspace") == workspace and m.get("status") == "active":
            return slug
    return None


# ---------------------------------------------------------------------------
# Symlink helpers
# ---------------------------------------------------------------------------

def workspace_to_slug(workspace: str) -> str:
    """Convert workspace path to symlink name.

    >>> workspace_to_slug('products/my-product')
    'products-my-product'
    >>> workspace_to_slug('tools/my-tool')
    'tools-my-tool'
    """
    return workspace.replace("/", "-")


def update_active_symlink(workspace: str, target_slug: str | None) -> None:
    """Update (or remove) the active/{workspace-slug} symlink."""
    ACTIVE_DIR.mkdir(parents=True, exist_ok=True)
    link_path = ACTIVE_DIR / workspace_to_slug(workspace)
    if link_path.exists() or link_path.is_symlink():
        link_path.unlink()
    if target_slug is not None:
        target_dir = MISSIONS_DIR / target_slug
        link_path.symlink_to(target_dir)
        log.info("Active symlink: %s -> %s", link_path, target_dir)
    else:
        log.info("Active symlink removed for workspace: %s", workspace)


# ---------------------------------------------------------------------------
# Persist mission data
# ---------------------------------------------------------------------------

def save_mission(mission: dict[str, Any]) -> None:
    """Write mission.json back to disk, updating the `updated` timestamp."""
    slug = mission["id"]
    mission["updated"] = datetime.now(timezone.utc).isoformat()
    mission_path = MISSIONS_DIR / slug / "mission.json"
    mission_path.parent.mkdir(parents=True, exist_ok=True)
    with mission_path.open("w") as f:
        json.dump(mission, f, indent=2)
        f.write("\n")


def append_ledger(slug: str, entry: dict[str, Any]) -> None:
    """Append a single JSON entry to ledger.jsonl."""
    ledger_path = MISSIONS_DIR / slug / "ledger.jsonl"
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    with ledger_path.open("a") as f:
        f.write(json.dumps(entry) + "\n")


# ---------------------------------------------------------------------------
# --validate
# ---------------------------------------------------------------------------

def cmd_validate(slug: str) -> int:
    """Validate a single mission's DAG invariants.

    Returns 0 if valid, 1 if invalid.
    """
    all_missions = load_all_missions()
    if slug not in all_missions:
        print(f"ERROR: mission {slug!r} not found", file=sys.stderr)
        return 2

    # Build workspace subset that includes the slug and all related
    workspace = all_missions[slug].get("workspace", "")
    ws_missions = missions_for_workspace(workspace, all_missions)

    findings: list[str] = []

    # 1. Cycle check
    cycle = detect_cycle(ws_missions)
    if cycle:
        findings.append(f"CYCLE DETECTED: {' -> '.join(cycle)}")

    # 2. Reciprocal edges
    violations = check_reciprocal_edges(ws_missions)
    findings.extend(violations)

    # 3. At most one active per workspace
    active_slugs = [s for s, m in ws_missions.items() if m.get("status") == "active"]
    if len(active_slugs) > 1:
        findings.append(f"MULTIPLE ACTIVE NODES: {active_slugs}")

    # 4. last_result tri-state check
    for s, m in ws_missions.items():
        for check in m.get("machine_checks", []):
            lr = check.get("last_result")
            if lr not in LAST_RESULT_VALUES:
                findings.append(
                    f"{s}.machine_checks[{check.get('id')}].last_result={lr!r} invalid — must be pass|fail|unknown|null"
                )

    if findings:
        for f in findings:
            print(f"INVALID: {f}", file=sys.stderr)
        return 1

    print(f"VALID: {slug}", file=sys.stderr)
    return 0


# ---------------------------------------------------------------------------
# --resolve-active
# ---------------------------------------------------------------------------

def cmd_resolve_active(workspace: str) -> int:
    """Print the active leaf slug for a workspace. Empty output if none."""
    all_missions = load_all_missions()
    slug = find_active_leaf(workspace, all_missions)
    if slug:
        print(slug)
    return 0


# ---------------------------------------------------------------------------
# --halt
# ---------------------------------------------------------------------------

def cmd_halt(slug: str, reason: str, new_status: str = "abandoned") -> int:
    """Cascade halt a mission and all active descendants.

    Prints JSON: {halted: [...], new_active_leaf: slug_or_null}
    """
    all_missions = load_all_missions()

    if slug not in all_missions:
        print(f"ERROR: mission {slug!r} not found", file=sys.stderr)
        return 2

    root = all_missions[slug]
    workspace = root.get("workspace", "")
    now_ts = datetime.now(timezone.utc).isoformat()

    halted: list[str] = []

    # Collect all descendants to halt (BFS, only those in non-terminal states)
    to_halt: list[str] = []
    queue: deque[str] = deque([slug])
    while queue:
        current_slug = queue.popleft()
        current = all_missions.get(current_slug)
        if current is None:
            continue
        status = current.get("status", "")
        if status not in TERMINAL_STATUSES:
            to_halt.append(current_slug)
        # Always recurse into children to find non-terminal descendants
        for child_id in current.get("children", []):
            if child_id in all_missions:
                child_status = all_missions[child_id].get("status", "")
                if child_status not in TERMINAL_STATUSES:
                    queue.append(child_id)

    # Apply halt to each
    for target_slug in to_halt:
        mission = all_missions[target_slug]
        cascade_from = slug if target_slug != slug else None
        mission["status"] = new_status
        if new_status == "completed":
            mission["completed_at"] = now_ts
        save_mission(mission)
        append_ledger(target_slug, {
            "ts": now_ts,
            "event": "halted",
            "reason": reason,
            "cascade_from": cascade_from,
            "new_status": new_status,
        })
        halted.append(target_slug)
        log.info("Halted %s -> %s (cascade_from=%s)", target_slug, new_status, cascade_from)

    # Determine new active leaf
    new_active_leaf: str | None = None
    parent_id = root.get("parent_id")

    if parent_id and parent_id in all_missions:
        parent = all_missions[parent_id]
        # Find runnable siblings of slug (sorted by ID, lowest first)
        siblings = sorted(
            c for c in parent.get("children", [])
            if c != slug and all_missions.get(c, {}).get("status") == "runnable"
        )
        if siblings:
            # Activate first runnable sibling
            new_active_leaf = siblings[0]
            sibling_mission = all_missions[new_active_leaf]
            sibling_mission["status"] = "active"
            save_mission(sibling_mission)
            append_ledger(new_active_leaf, {
                "ts": now_ts,
                "event": "activated",
                "reason": f"sibling {slug} halted",
                "cascade_from": None,
                "new_status": "active",
            })
            log.info("Activated sibling %s as new active leaf", new_active_leaf)
        else:
            # Check if parent still has active_descendant_count == 0
            # Reload parent since we may have just halted some children
            parent_adc = active_descendant_count(parent_id, all_missions)
            if parent_adc == 0:
                new_active_leaf = parent_id
                parent["status"] = "active"
                save_mission(parent)
                append_ledger(parent_id, {
                    "ts": now_ts,
                    "event": "activated",
                    "reason": f"all children of {parent_id} halted, parent resumes",
                    "cascade_from": None,
                    "new_status": "active",
                })
                log.info("Parent %s becomes active leaf", parent_id)
    # else: no parent — top-level mission halted, no new leaf

    update_active_symlink(workspace, new_active_leaf)

    result = {"halted": halted, "new_active_leaf": new_active_leaf}
    print(json.dumps(result, indent=2))
    return 0


# ---------------------------------------------------------------------------
# --list-tree
# ---------------------------------------------------------------------------

def cmd_list_tree(workspace: str) -> int:
    """Pretty-print the mission tree for a workspace."""
    all_missions = load_all_missions()
    ws_missions = missions_for_workspace(workspace, all_missions)

    if not ws_missions:
        print(f"(no missions for workspace: {workspace})")
        return 0

    # Find roots (no parent_id or parent not in this workspace)
    roots = sorted(
        slug for slug, m in ws_missions.items()
        if not m.get("parent_id") or m.get("parent_id") not in ws_missions
    )

    def print_node(slug: str, depth: int = 0) -> None:
        m = ws_missions.get(slug)
        if m is None:
            return
        status = m.get("status", "?")
        title = m.get("title", slug)
        prefix = "  " * depth + ("└─ " if depth > 0 else "")
        marker = "*" if status == "active" else " "
        print(f"{prefix}[{marker}{status:<10}] {slug}  {title}")
        for child_id in sorted(m.get("children", [])):
            if child_id in ws_missions:
                print_node(child_id, depth + 1)

    print(f"Mission tree: {workspace}")
    print("=" * 60)
    for root in roots:
        print_node(root)

    return 0


# ---------------------------------------------------------------------------
# --node-states
# ---------------------------------------------------------------------------

def cmd_node_states(workspace: str, as_json: bool) -> int:
    """Output per-node {slug, status, active_descendant_count} for a workspace."""
    all_missions = load_all_missions()
    ws_missions = missions_for_workspace(workspace, all_missions)

    nodes = []
    for slug, m in sorted(ws_missions.items()):
        nodes.append({
            "slug": slug,
            "title": m.get("title", ""),
            "status": m.get("status"),
            "parent_id": m.get("parent_id"),
            "children": m.get("children", []),
            "active_descendant_count": active_descendant_count(slug, ws_missions),
        })

    if as_json:
        print(json.dumps(nodes, indent=2))
    else:
        for n in nodes:
            print(f"{n['slug']:<40} {n['status']:<12} adc={n['active_descendant_count']}")

    return 0


# ---------------------------------------------------------------------------
# CLI entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Mission DAG validator + active leaf resolver + halt cascade",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--validate", metavar="SLUG", help="Validate DAG acyclic + invariants")
    parser.add_argument("--resolve-active", metavar="WORKSPACE", help="Print active leaf slug")
    parser.add_argument("--halt", metavar="SLUG", help="Apply halt cascade to slug")
    parser.add_argument("--reason", default="unspecified", help="Reason for halt (used with --halt)")
    parser.add_argument(
        "--status",
        choices=["completed", "abandoned"],
        default="abandoned",
        help="Terminal status for halted missions (default: abandoned)",
    )
    parser.add_argument("--list-tree", metavar="WORKSPACE", help="Pretty-print mission tree")
    parser.add_argument("--node-states", metavar="WORKSPACE", help="Output per-node states")
    parser.add_argument("--json", action="store_true", help="Output as JSON (used with --node-states)")
    parser.add_argument("--doctest", action="store_true", help="Run inline doctests and exit")

    args = parser.parse_args()

    if args.doctest:
        import doctest
        results = doctest.testmod(verbose=True)
        sys.exit(0 if results.failed == 0 else 1)

    if args.validate:
        sys.exit(cmd_validate(args.validate))

    if args.resolve_active:
        sys.exit(cmd_resolve_active(args.resolve_active))

    if args.halt:
        sys.exit(cmd_halt(args.halt, args.reason, args.status))

    if args.list_tree:
        sys.exit(cmd_list_tree(args.list_tree))

    if args.node_states:
        sys.exit(cmd_node_states(args.node_states, args.json))

    parser.print_help()
    sys.exit(1)


if __name__ == "__main__":
    main()
