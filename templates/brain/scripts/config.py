"""Path constants and configuration for the global AI Brain."""
from __future__ import annotations
import os
from pathlib import Path
from datetime import datetime, timezone

SCRIPTS_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPTS_DIR.parent

DEFAULT_VAULT_PATH = Path.home() / "Documents" / "AI Brain"
CONFIG_PATH = ROOT_DIR / ".brain-config.yaml"


def _parse_simple_yaml(text: str) -> dict:
    """Tiny fallback parser for the flat keys this package needs."""
    result: dict[str, object] = {}
    current_map: str | None = None
    for raw_line in text.splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        if raw_line.startswith((" ", "\t")) and current_map:
            if ":" not in raw_line:
                continue
            key, _, value = raw_line.strip().partition(":")
            result.setdefault(current_map, {})[key.strip()] = value.strip().strip("\"'")
            continue
        current_map = None
        if ":" not in raw_line:
            continue
        key, _, value = raw_line.partition(":")
        key = key.strip()
        value = value.strip()
        if not value:
            result[key] = {}
            current_map = key
        else:
            result[key] = value.strip("\"'")
    return result


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        return {}
    text = CONFIG_PATH.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        return yaml.safe_load(text) or {}
    except Exception:
        return _parse_simple_yaml(text)


_config = load_config()

_vault_from_env = os.environ.get("BRAIN_VAULT_PATH") or os.environ.get("BRAIN_VAULT_DIR")
_vault_from_config = _config.get("vault_path")
VAULT_PATH = Path(str(_vault_from_env or _vault_from_config or DEFAULT_VAULT_PATH)).expanduser()
PROJECT_MAP = _config.get("project_map", {}) if isinstance(_config.get("project_map", {}), dict) else {}
SPAWN_MIN_BATTERY = int(os.environ.get("BRAIN_SPAWN_MIN_BATTERY", _config.get("spawn_min_battery", 15) or 15))
AUTORESEARCH_COOLDOWN_HOURS = int(os.environ.get("BRAIN_AUTORESEARCH_COOLDOWN_HOURS", _config.get("autoresearch_cooldown_hours", 24) or 24))

SESSIONS_DIR = VAULT_PATH / "sessions"
MEMORY_DIR = VAULT_PATH / "memory"
PROJECTS_DIR = VAULT_PATH / "projects"
CONNECTIONS_DIR = VAULT_PATH / "connections"
QA_DIR = VAULT_PATH / "qa"
EVOLUTION_DIR = VAULT_PATH / "inbox" / "evolution"
INBOX_DIR = VAULT_PATH / "inbox"
RESEARCH_DIR = VAULT_PATH / "research"
AGENT_MEMORY_DIR = VAULT_PATH / "agents"
INDEX_FILE = MEMORY_DIR / "index.md"
BUILD_LOG = VAULT_PATH / "build-log.md"
STATE_FILE = SCRIPTS_DIR / "brain-state.json"
LAST_FLUSH_FILE = SCRIPTS_DIR / "last-flush.json"
FLUSH_LOG = SCRIPTS_DIR / "flush.log"

FLUSH_COOLDOWN_SECONDS = 60
COMPILE_COOLDOWN_SECONDS = 7200
COMPILE_AFTER_HOUR = 18
MAX_TURNS = 30
MAX_CONTEXT_CHARS = 15_000


def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat()


def today_str() -> str:
    return datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d")


def detect_project(cwd: str | None = None) -> str:
    """Detect project from CWD by reading .brain-config.yaml project map."""
    if cwd is None:
        cwd = os.getcwd()
    for pattern, slug in PROJECT_MAP.items():
        if pattern in cwd:
            return str(slug)
    # Fallback: use the directory name
    return Path(cwd).name.lower().replace(" ", "-")
