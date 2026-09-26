#!/usr/bin/env bash
# Install the global AI Brain package for Claude Code and other local CLIs.

set -euo pipefail

FORCE=false
DRY_RUN=false
YES=false
NO_CRON=false
SKIP_CRON_LOAD="${BRAIN_INSTALL_SKIP_CRON_LOAD:-false}"
BRAIN_NAME="AI Brain"
VAULT_PATH_ARG=""

usage() {
  cat <<'EOF'
Usage: install-brain.sh [options]

Options:
  --vault-path PATH     Use this Obsidian vault or plain folder.
  --brain-name NAME     Folder name for fallback vault creation. Default: AI Brain.
  --yes                 Non-interactive mode. Use detected/default paths.
  --force               Refresh installed package files.
  --dry-run             Show planned work without writing files.
  --no-cron             Do not install the daily cron files.
  --skip-cron-load      Write cron files but do not load/enable them.
  -h, --help            Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault-path) VAULT_PATH_ARG="${2:-}"; shift 2 ;;
    --brain-name) BRAIN_NAME="${2:-AI Brain}"; shift 2 ;;
    --yes|-y) YES=true; shift ;;
    --force|-f) FORCE=true; shift ;;
    --dry-run|-n) DRY_RUN=true; shift ;;
    --no-cron) NO_CRON=true; shift ;;
    --skip-cron-load) SKIP_CRON_LOAD=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(dirname "$SCRIPT_DIR")"
BRAIN_SOURCE="$SOURCE_ROOT/templates/brain"

CLAUDE_HOME="$HOME/.claude"
CLAUDE_BRAIN_HOME="$CLAUDE_HOME/brain"
CLAUDE_SKILLS="$CLAUDE_HOME/skills"
LOCAL_BIN="$HOME/.local/bin"
BACKUP_DIR="$CLAUDE_HOME/backups/brain-install-$(date +%Y%m%d-%H%M%S)"
TRACE_FILE="${BRAIN_INSTALL_TRACE_FILE:-}"

info() { printf '==> %s\n' "$1"; }
warn() { printf 'WARN: %s\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

trace_write() {
  [[ -z "$TRACE_FILE" ]] && return 0
  mkdir -p "$(dirname "$TRACE_FILE")"
  printf '%s\n' "$1" >> "$TRACE_FILE"
}

expand_path() {
  python3 - "$1" "$HOME" <<'PY'
import os
import sys
from pathlib import Path

raw = sys.argv[1]
home = sys.argv[2]
if raw.startswith("~/"):
    raw = home + raw[1:]
print(str(Path(os.path.expandvars(raw)).expanduser()))
PY
}

read_config_value() {
  local config="$1"
  local key="$2"
  [[ -f "$config" ]] || return 0
  python3 - "$config" "$key" <<'PY' 2>/dev/null || true
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
value = ""
try:
    import yaml  # type: ignore
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    value = str(data.get(key) or "")
except Exception:
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith(key + ":"):
            value = line.split(":", 1)[1].strip().strip("\"'")
            break
print(value)
PY
}

backup_file() {
  local target="$1"
  [[ -f "$target" ]] || return 0
  [[ "$DRY_RUN" == true ]] && return 0
  mkdir -p "$BACKUP_DIR/$(dirname "${target#$HOME/}")"
  cp "$target" "$BACKUP_DIR/${target#$HOME/}"
}

install_file() {
  local source="$1"
  local target="$2"
  [[ -f "$source" ]] || fail "Missing source file: $source"

  if [[ -f "$target" ]] && cmp -s "$source" "$target" && [[ "$FORCE" == false ]]; then
    case "$target" in
      *.sh|*/bin/brain-*|*/hooks/*.sh)
        [[ "$DRY_RUN" == true ]] || chmod +x "$target"
        ;;
    esac
    return 0
  fi

  info "Install ${target#$HOME/}"
  trace_write "$target"
  [[ "$DRY_RUN" == true ]] && return 0
  mkdir -p "$(dirname "$target")"
  backup_file "$target"
  cp "$source" "$target"
  case "$target" in
    *.sh|*/bin/brain-*|*/hooks/*.sh) chmod +x "$target" ;;
  esac
}

install_package() {
  info "Installing brain package under ~/.claude/brain"
  while IFS= read -r source_file; do
    rel="${source_file#$BRAIN_SOURCE/}"
    install_file "$source_file" "$CLAUDE_BRAIN_HOME/$rel"
  done < <(find "$BRAIN_SOURCE" -type f ! -path '*/.git/*' | sort)
}

install_global_skills() {
  info "Installing brain skills into ~/.claude/skills"
  while IFS= read -r skill_dir; do
    name="$(basename "$skill_dir")"
    install_file "$skill_dir/SKILL.md" "$CLAUDE_SKILLS/$name/SKILL.md"
  done < <(find "$BRAIN_SOURCE/skills" -maxdepth 1 -mindepth 1 -type d -name 'brain-*' | sort)
}

install_wrappers() {
  info "Installing terminal wrappers into ~/.local/bin"
  while IFS= read -r wrapper; do
    install_file "$wrapper" "$LOCAL_BIN/$(basename "$wrapper")"
  done < <(find "$BRAIN_SOURCE/bin" -maxdepth 1 -type f | sort)
}

discover_obsidian_vaults() {
  python3 - "$HOME" <<'PY'
from __future__ import annotations

import os
import sys
from pathlib import Path

home = Path(sys.argv[1])
candidates: list[Path] = []

roots = [home / "Documents", home]
for root in roots:
    if not root.exists():
        continue
    try:
        root_depth = len(root.parts)
        for current, dirs, _files in os.walk(root):
            path = Path(current)
            depth = len(path.parts) - root_depth
            dirs[:] = [d for d in dirs if not d.startswith(".") and d not in {"node_modules", "Library", "Applications"}]
            if ".obsidian" in dirs:
                vault = path
                if vault != home and vault not in candidates:
                    candidates.append(vault)
                if len(candidates) >= 5:
                    dirs[:] = []
                    break
            if depth >= 3:
                dirs[:] = []
    except (PermissionError, OSError):
        continue

if (home / ".obsidian").is_dir():
    print(f"HOME_MARKER\t{home}")

for candidate in candidates[:5]:
    print(candidate)
PY
}

choose_vault_path() {
  local existing_config="$CLAUDE_BRAIN_HOME/.brain-config.yaml"
  local configured=""
  local vault_kind="folder"

  if [[ -n "$VAULT_PATH_ARG" ]]; then
    printf '%s\t%s\n' "$(expand_path "$VAULT_PATH_ARG")" "explicit"
    return 0
  fi

  if [[ -n "${BRAIN_VAULT_PATH:-}" || -n "${BRAIN_VAULT_DIR:-}" ]]; then
    printf '%s\t%s\n' "$(expand_path "${BRAIN_VAULT_PATH:-$BRAIN_VAULT_DIR}")" "env"
    return 0
  fi

  configured="$(read_config_value "$existing_config" vault_path)"
  if [[ -n "$configured" ]]; then
    printf '%s\t%s\n' "$(expand_path "$configured")" "config"
    return 0
  fi

  local candidates
  candidates="$(discover_obsidian_vaults || true)"
  local first_candidate
  first_candidate="$(printf '%s\n' "$candidates" | grep -v '^HOME_MARKER' | sed -n '1p')"

  if [[ -n "$first_candidate" ]]; then
    vault_kind="obsidian"
    if [[ "$YES" == false && -t 0 ]]; then
      printf 'Detected Obsidian vault: %s\n' "$first_candidate"
      printf 'Use this vault for the AI Brain? [Y/n] '
      read -r answer
      case "${answer:-Y}" in
        y|Y|yes|YES) printf '%s\t%s\n' "$first_candidate" "$vault_kind"; return 0 ;;
      esac
    elif [[ "$YES" == true ]]; then
      printf '%s\t%s\n' "$first_candidate" "$vault_kind"
      return 0
    fi
  fi

  if printf '%s\n' "$candidates" | grep -q '^HOME_MARKER' && [[ "$YES" == false && -t 0 ]]; then
    warn "Found ~/.obsidian. Home can be an Obsidian vault, but using home as a vault is usually noisy."
    printf 'Use HOME as the vault anyway? [y/N] '
    read -r answer
    case "${answer:-N}" in
      y|Y|yes|YES) printf '%s\t%s\n' "$HOME" "obsidian"; return 0 ;;
    esac
  fi

  printf '%s\t%s\n' "$HOME/Documents/$BRAIN_NAME" "folder"
}

write_brain_config() {
  local vault_path="$1"
  local vault_kind="$2"
  local config_path="$CLAUDE_BRAIN_HOME/.brain-config.yaml"

  info "Writing brain config"
  trace_write "$config_path"
  [[ "$DRY_RUN" == true ]] && return 0
  mkdir -p "$CLAUDE_BRAIN_HOME"
  backup_file "$config_path"
  cat > "$config_path" <<EOF
vault_path: $vault_path
brain_name: $BRAIN_NAME
vault_kind: $vault_kind
autoresearch_cooldown_hours: 24
spawn_min_battery: 15
project_map: {}
EOF
}

initialize_vault() {
  local vault_path="$1"
  local vault_kind="$2"
  info "Initializing brain vault at $vault_path"
  trace_write "$vault_path"
  [[ "$DRY_RUN" == true ]] && return 0
  mkdir -p "$vault_path"
  python3 "$CLAUDE_BRAIN_HOME/scripts/init_vault.py" --vault-path "$vault_path" --scan-paths "$HOME/projects,$HOME/code,$HOME/Documents" >/dev/null
  write_brain_config "$vault_path" "$vault_kind"
}

patch_settings() {
  local settings="$CLAUDE_HOME/settings.json"
  local rtk_present="$1"

  info "Wiring Claude Code hooks in ~/.claude/settings.json"
  trace_write "$settings"
  [[ "$DRY_RUN" == true ]] && return 0
  mkdir -p "$CLAUDE_HOME"
  [[ -f "$settings" ]] || printf '{}\n' > "$settings"
  backup_file "$settings"

  python3 - "$settings" "$rtk_present" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
rtk_present = sys.argv[2] == "true"

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    data = {}

hooks = data.setdefault("hooks", {})

def has_command(event: str, command: str) -> bool:
    for entry in hooks.get(event, []):
        for hook in entry.get("hooks", []):
            if hook.get("command") == command:
                return True
    return False

def add_hook(event: str, matcher: str, command: str, timeout: int) -> None:
    if has_command(event, command):
        return
    entry = None
    for candidate in hooks.setdefault(event, []):
        if candidate.get("matcher", "") == matcher:
            entry = candidate
            break
    if entry is None:
        entry = {"matcher": matcher, "hooks": []}
        hooks[event].append(entry)
    entry.setdefault("hooks", []).append({
        "type": "command",
        "command": command,
        "timeout": timeout,
    })

add_hook("SessionStart", "", 'bash "$HOME/.claude/brain/hooks/session-start.sh" || true', 10)
add_hook("PreCompact", "", 'bash "$HOME/.claude/brain/hooks/pre-compact.sh" || true', 10)
add_hook("Stop", "", 'bash "$HOME/.claude/brain/hooks/stop.sh" || true', 10)
add_hook("SessionEnd", "", 'bash "$HOME/.claude/brain/hooks/stop.sh" || true', 10)

if rtk_present:
    add_hook("PreToolUse", "Bash", 'command -v rtk >/dev/null 2>&1 && rtk hook claude || true', 5)

path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

install_cron() {
  local os_name
  os_name="$(uname -s | tr '[:upper:]' '[:lower:]')"

  [[ "$NO_CRON" == true ]] && return 0
  info "Installing daily autoresearch cron"

  if [[ "$os_name" == "darwin" ]]; then
    local source="$BRAIN_SOURCE/cron/launchd/ai.sigma.brain-autoresearch.plist"
    local target="$HOME/Library/LaunchAgents/ai.sigma.brain-autoresearch.plist"
    trace_write "$target"
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$(dirname "$target")"
      backup_file "$target"
      sed "s#__HOME__#$HOME#g" "$source" > "$target"
      if [[ "$SKIP_CRON_LOAD" != true ]] && command -v launchctl >/dev/null 2>&1; then
        launchctl unload "$target" >/dev/null 2>&1 || true
        launchctl load "$target" >/dev/null 2>&1 || warn "Cron file written, but launchctl load failed. Load manually with: launchctl load $target"
      fi
    fi
  elif [[ "$os_name" == "linux" ]]; then
    local service_source="$BRAIN_SOURCE/cron/systemd/ai-brain-autoresearch.service"
    local timer_source="$BRAIN_SOURCE/cron/systemd/ai-brain-autoresearch.timer"
    local systemd_dir="$HOME/.config/systemd/user"
    trace_write "$systemd_dir/ai-brain-autoresearch.service"
    trace_write "$systemd_dir/ai-brain-autoresearch.timer"
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$systemd_dir"
      install_file "$service_source" "$systemd_dir/ai-brain-autoresearch.service"
      install_file "$timer_source" "$systemd_dir/ai-brain-autoresearch.timer"
      if [[ "$SKIP_CRON_LOAD" != true ]] && command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        systemctl --user enable --now ai-brain-autoresearch.timer >/dev/null 2>&1 || warn "Cron files written, but systemd enable failed. Enable manually with: systemctl --user enable --now ai-brain-autoresearch.timer"
      fi
    fi
  else
    warn "Unsupported cron platform for $os_name. Cron templates are installed under ~/.claude/brain/cron."
  fi
}

ensure_path_notice() {
  case ":$PATH:" in
    *":$LOCAL_BIN:"*) return ;;
  esac
  warn "~/.local/bin is not in PATH. Add this to your shell profile:"
  printf '  export PATH="$HOME/.local/bin:$PATH"\n'
}

ensure_python_deps() {
  # brain-evolve needs pyyaml (+ python-dotenv per templates/brain/pyproject.toml).
  # Best-effort install; a miss degrades brain-evolve only, never the install.
  if python3 -c 'import yaml' >/dev/null 2>&1; then
    return
  fi
  info "Installing brain Python deps (pyyaml, python-dotenv)..."
  if python3 -m pip install --user --quiet pyyaml python-dotenv >/dev/null 2>&1; then
    info "Brain Python deps installed."
  else
    warn "Could not pip-install pyyaml/python-dotenv. brain-evolve will not run until you do:"
    printf '  python3 -m pip install --user pyyaml python-dotenv\n'
  fi
}

main() {
  [[ -d "$BRAIN_SOURCE" ]] || fail "Brain template not found at $BRAIN_SOURCE"

  local chosen vault_path vault_kind
  chosen="$(choose_vault_path)"
  vault_path="$(printf '%s' "$chosen" | awk -F '\t' '{print $1}')"
  vault_kind="$(printf '%s' "$chosen" | awk -F '\t' '{print $2}')"

  info "Source: $BRAIN_SOURCE"
  info "Target package: $CLAUDE_BRAIN_HOME"
  info "Vault: $vault_path ($vault_kind)"

  install_package
  install_global_skills
  install_wrappers
  write_brain_config "$vault_path" "$vault_kind"
  initialize_vault "$vault_path" "$vault_kind"

  if command -v rtk >/dev/null 2>&1; then
    info "RTK found: $(rtk --version 2>/dev/null || echo installed)"
    patch_settings true
  else
    warn "RTK not found. RTK compresses CLI output and saves tokens."
    warn "Install manually: brew install rtk && rtk init --global"
    patch_settings false
  fi

  install_cron
  ensure_path_notice
  ensure_python_deps

  info "Brain install complete"
  printf '  Vault: %s\n' "$vault_path"
  printf '  Commands: brain-status, brain-query, brain-compile, brain-evolve\n'
}

main "$@"
