"""Print a compact AI Brain health dashboard."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import (  # noqa: E402
    CONNECTIONS_DIR,
    FLUSH_LOG,
    INDEX_FILE,
    MEMORY_DIR,
    PROJECTS_DIR,
    QA_DIR,
    SCRIPTS_DIR,
    SESSIONS_DIR,
    STATE_FILE,
    VAULT_PATH,
)


def count_md(path: Path) -> int:
    if not path.exists():
        return 0
    return len([p for p in path.rglob("*.md") if not p.name.startswith("_")])


def load_state() -> dict:
    if not STATE_FILE.exists():
        return {}
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def tail(path: Path, lines: int = 5) -> list[str]:
    if not path.exists():
        return []
    try:
        return path.read_text(encoding="utf-8", errors="ignore").splitlines()[-lines:]
    except OSError:
        return []


def main() -> int:
    state = load_state()
    ingested = state.get("ingested", {})
    last_compile = "never"
    if isinstance(ingested, dict) and ingested:
        last_compile = max(str(item.get("compiled_at", "")) for item in ingested.values() if isinstance(item, dict)) or "unknown"

    index_lines = 0
    if INDEX_FILE.exists():
        index_lines = len(INDEX_FILE.read_text(encoding="utf-8", errors="ignore").splitlines())

    print("## Brain Status")
    print()
    print(f"Vault: {VAULT_PATH}")
    print()
    print("| Metric | Value |")
    print("|--------|-------|")
    print(f"| Memory articles | {count_md(MEMORY_DIR)} |")
    print(f"| Session journals | {count_md(SESSIONS_DIR)} |")
    print(f"| Project articles | {count_md(PROJECTS_DIR)} |")
    print(f"| Connections | {count_md(CONNECTIONS_DIR)} |")
    print(f"| Q&A articles | {count_md(QA_DIR)} |")
    print(f"| MEMORY index lines | {index_lines} |")
    print(f"| Last compile | {last_compile} |")
    print(f"| Total cost | ${float(state.get('total_cost', 0.0) or 0.0):.2f} |")
    print(f"| Queries run | {int(state.get('query_count', 0) or 0)} |")
    print(f"| Last lint | {state.get('last_lint', 'never')} |")
    print()
    print("### Recent Flush Activity")
    recent = tail(FLUSH_LOG)
    if recent:
        for line in recent:
            print(f"- {line}")
    else:
        print("- No flush activity recorded yet.")
    print()
    print(f"Scripts: {SCRIPTS_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
