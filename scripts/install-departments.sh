#!/usr/bin/env bash
# install-departments.sh
#
# One-command installer for the Sigma Protocol C-suite department system.
# Wires up the UserPromptSubmit hook, records the Sigma Protocol root, and
# scaffolds the user-overlay tree so /marketing, /ads, /content, /growth,
# /engineering, /ops, /finance, /product, /sales, /design, /support,
# /legal, /trading, and /security work immediately in any Claude Code
# session.
#
# Idempotent: safe to run twice. If the hook is already registered, the
# overlay dirs exist, or the composer is already in ~/.claude/hooks/, the
# script reports "already installed" for that step and moves on.
#
# Portability: targets Apple's system bash 3.2. No associative arrays, no
# process substitution beyond what bash 3.2 supports, no GNU-only flags.
#
# Usage:
#   ./scripts/install-departments.sh              # interactive install
#   SSS_PROTOCOL_ROOT=/path ./scripts/install-departments.sh   # scripted
#   ./scripts/install-departments.sh --dry-run    # show what would happen
#   ./scripts/install-departments.sh --help

set -u
# IMPORTANT: no `set -e`. Each step reports its own outcome and we decide
# whether to continue. A failed jq shouldn't abort the whole install.

# ----- Configuration ---------------------------------------------------------

SCRIPT_PATH="$0"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

HOOKS_SRC_REPO="${REPO_ROOT}/templates/hooks/department-composer.sh"
HOOKS_SRC_INSTALLED="$HOME/.claude/hooks/department-composer.sh"

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_JSON="$CLAUDE_DIR/settings.json"
ROOT_MARKER="$CLAUDE_DIR/sigma-protocol-root"
OVERLAY_ROOT="$CLAUDE_DIR/departments"

# Canonical 13 (mirrors agent-skill-registry.json) + alias-canon surfaces.
DEPARTMENTS="engineering security legal marketing content finance ops sales product community trading design qa ads growth support gtm"

DRY_RUN=0
NON_INTERACTIVE=0

# ----- Output helpers --------------------------------------------------------

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; }
skip()  { printf '\033[1;36m[SKIP]\033[0m %s\n' "$*"; }

print_usage() {
  cat <<'USAGE'
Usage: install-departments.sh [options]

Wires up the Sigma Protocol department system for Claude Code.

Options:
  --dry-run            Show what would happen without changing anything.
  --non-interactive    Fail instead of prompting when a choice is required.
  -h, --help           Print this message.

Environment:
  SSS_PROTOCOL_ROOT    Absolute path to your Sigma Protocol checkout.
                       If set, skips discovery and root-prompt.

Idempotent. Running the installer a second time is safe and fast — each
step checks current state before modifying.
USAGE
}

# ----- Argument parsing ------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)         DRY_RUN=1 ;;
    --non-interactive) NON_INTERACTIVE=1 ;;
    -h|--help)         print_usage; exit 0 ;;
    *) warn "Unknown arg: $1 (use --help for usage)";;
  esac
  shift
done

# ----- Pre-flight ------------------------------------------------------------

info "Sigma Protocol — Department System Installer"
printf '     Repo:   %s\n' "$REPO_ROOT"
printf '     Claude: %s\n' "$CLAUDE_DIR"
if [ "$DRY_RUN" -eq 1 ]; then
  printf '     Mode:   DRY RUN (no changes will be written)\n'
fi
printf '\n'

if [ ! -d "$CLAUDE_DIR" ]; then
  fail "~/.claude/ does not exist. Install Claude Code first."
  exit 1
fi

mkdir -p "$HOOKS_DIR" 2>/dev/null || true

# ----- Step 1: Locate composer source ---------------------------------------

info "Step 1/6 — Locating the composer source"

COMPOSER_SOURCE=""
if [ -f "$HOOKS_SRC_INSTALLED" ]; then
  COMPOSER_SOURCE="$HOOKS_SRC_INSTALLED"
  ok "Composer already present at $HOOKS_SRC_INSTALLED"
elif [ -f "$HOOKS_SRC_REPO" ]; then
  COMPOSER_SOURCE="$HOOKS_SRC_REPO"
  ok "Composer template found at $HOOKS_SRC_REPO"
else
  fail "Cannot find department-composer.sh."
  fail "Expected one of:"
  fail "  - $HOOKS_SRC_INSTALLED (already installed)"
  fail "  - $HOOKS_SRC_REPO (shipped in the Sigma Protocol repo)"
  fail ""
  fail "If you just cloned the repo, pull latest or check the docs:"
  fail "  $REPO_ROOT/.agents/departments/README.md"
  exit 1
fi

# ----- Step 2: Copy composer to ~/.claude/hooks/ -----------------------------

info "Step 2/6 — Installing composer to $HOOKS_SRC_INSTALLED"

if [ -f "$HOOKS_SRC_INSTALLED" ] && [ "$COMPOSER_SOURCE" = "$HOOKS_SRC_INSTALLED" ]; then
  skip "Composer already at target — not overwriting."
elif [ "$DRY_RUN" -eq 1 ]; then
  skip "Would copy $COMPOSER_SOURCE -> $HOOKS_SRC_INSTALLED"
else
  if cp "$COMPOSER_SOURCE" "$HOOKS_SRC_INSTALLED" 2>/dev/null; then
    chmod +x "$HOOKS_SRC_INSTALLED" 2>/dev/null || true
    ok "Composer copied and made executable."
  else
    fail "Could not copy composer to $HOOKS_SRC_INSTALLED"
    exit 1
  fi
fi

# Whatever path we loaded from, the installed copy is the one we verify.
if [ -f "$HOOKS_SRC_INSTALLED" ] && [ ! -x "$HOOKS_SRC_INSTALLED" ] && [ "$DRY_RUN" -eq 0 ]; then
  chmod +x "$HOOKS_SRC_INSTALLED" 2>/dev/null || true
fi

# ----- Step 3: Discover SSS_PROTOCOL_ROOT -----------------------------------

info "Step 3/6 — Discovering Sigma Protocol root"

DISCOVERED_ROOT=""
DISCOVERY_METHOD=""

# (a) env var wins
if [ -n "${SSS_PROTOCOL_ROOT:-}" ]; then
  if [ -f "${SSS_PROTOCOL_ROOT}/.agents/departments/SCHEMA.md" ]; then
    DISCOVERED_ROOT="$SSS_PROTOCOL_ROOT"
    DISCOVERY_METHOD="\$SSS_PROTOCOL_ROOT env var"
  else
    warn "\$SSS_PROTOCOL_ROOT is set to '$SSS_PROTOCOL_ROOT' but .agents/departments/SCHEMA.md is missing there."
    warn "Ignoring and trying other discovery methods."
  fi
fi

# (b) walk up from CWD looking for .agents/departments/SCHEMA.md
if [ -z "$DISCOVERED_ROOT" ]; then
  _probe="$(pwd)"
  while [ -n "$_probe" ] && [ "$_probe" != "/" ]; do
    if [ -f "${_probe}/.agents/departments/SCHEMA.md" ]; then
      DISCOVERED_ROOT="$_probe"
      DISCOVERY_METHOD="walking up from \$PWD"
      break
    fi
    _probe="$(dirname "$_probe")"
  done
fi

# (c) assume script is running from inside the repo (scripts/install-...)
if [ -z "$DISCOVERED_ROOT" ]; then
  if [ -f "${REPO_ROOT}/.agents/departments/SCHEMA.md" ]; then
    DISCOVERED_ROOT="$REPO_ROOT"
    DISCOVERY_METHOD="script location (${REPO_ROOT})"
  fi
fi

# (d) interactive prompt
if [ -z "$DISCOVERED_ROOT" ]; then
  if [ "$NON_INTERACTIVE" -eq 1 ]; then
    fail "No Sigma Protocol root found and --non-interactive is set."
    fail "Set \$SSS_PROTOCOL_ROOT or run from inside the repo."
    exit 1
  fi
  if [ ! -t 0 ]; then
    fail "No Sigma Protocol root found and stdin is not a TTY (cannot prompt)."
    fail "Set \$SSS_PROTOCOL_ROOT and re-run."
    exit 1
  fi
  printf '\n'
  printf 'Could not discover your Sigma Protocol checkout automatically.\n'
  printf 'Enter the absolute path to it (the directory containing .agents/departments/SCHEMA.md):\n'
  printf '> '
  read -r _entered_root
  if [ -z "$_entered_root" ]; then
    fail "No path entered."
    exit 1
  fi
  # Expand a leading ~ manually (bash doesn't expand read input).
  case "$_entered_root" in
    "~"/*) _entered_root="$HOME/${_entered_root#~/}" ;;
    "~") _entered_root="$HOME" ;;
  esac
  if [ ! -f "${_entered_root}/.agents/departments/SCHEMA.md" ]; then
    fail "No SCHEMA.md found at ${_entered_root}/.agents/departments/SCHEMA.md"
    fail "That does not look like a Sigma Protocol checkout. Aborting."
    exit 1
  fi
  DISCOVERED_ROOT="$_entered_root"
  DISCOVERY_METHOD="user input"
fi

ok "Sigma Protocol root: $DISCOVERED_ROOT"
printf '     (via %s)\n' "$DISCOVERY_METHOD"

# Record root to ~/.claude/sigma-protocol-root. No shell-rc edits.
if [ "$DRY_RUN" -eq 1 ]; then
  skip "Would write root to $ROOT_MARKER"
else
  if [ -f "$ROOT_MARKER" ]; then
    _current_root="$(tr -d '\r\n' < "$ROOT_MARKER" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [ "$_current_root" = "$DISCOVERED_ROOT" ]; then
      skip "Root marker already set to this path."
    else
      printf '%s\n' "$DISCOVERED_ROOT" > "$ROOT_MARKER"
      ok "Root marker updated (was: $_current_root)."
    fi
  else
    printf '%s\n' "$DISCOVERED_ROOT" > "$ROOT_MARKER"
    ok "Root marker written to $ROOT_MARKER"
  fi
fi

# ----- Step 4: Register hook in ~/.claude/settings.json ---------------------

info "Step 4/6 — Registering UserPromptSubmit hook in settings.json"

if [ ! -f "$SETTINGS_JSON" ]; then
  fail "$SETTINGS_JSON does not exist."
  fail "Claude Code should create this on first launch. Open Claude Code once and re-run."
  exit 1
fi

# Quick idempotency check — grep is cheap.
if grep -q 'department-composer' "$SETTINGS_JSON" 2>/dev/null; then
  skip "Composer already registered in settings.json."
else
  if [ "$DRY_RUN" -eq 1 ]; then
    skip "Would register UserPromptSubmit hook in $SETTINGS_JSON"
  else
    # Back up first. Single timestamped backup per run.
    _BACKUP="${SETTINGS_JSON}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$SETTINGS_JSON" "$_BACKUP" 2>/dev/null && ok "Backed up settings.json to $_BACKUP"

    _HOOK_CMD="$HOOKS_SRC_INSTALLED"
    _REG_OK=0

    if command -v jq >/dev/null 2>&1; then
      # jq path — clean, schema-aware.
      _TMP="$(mktemp -t dept-settings.XXXXXX)" || _TMP=""
      if [ -n "$_TMP" ]; then
        if jq --arg cmd "$_HOOK_CMD" '
          .hooks = (.hooks // {}) |
          .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) |
          .hooks.UserPromptSubmit += [{"hooks":[{"type":"command","command":$cmd,"timeout":3}]}]
        ' "$SETTINGS_JSON" > "$_TMP" 2>/dev/null && [ -s "$_TMP" ]; then
          # Validate the result is still valid JSON.
          if jq -e . "$_TMP" >/dev/null 2>&1; then
            mv "$_TMP" "$SETTINGS_JSON" && _REG_OK=1
          else
            warn "jq produced invalid JSON. Leaving original settings.json untouched."
          fi
        else
          warn "jq transform failed. Falling back to python."
        fi
        [ -f "$_TMP" ] && rm -f "$_TMP"
      fi
    fi

    if [ "$_REG_OK" -ne 1 ] && command -v python3 >/dev/null 2>&1; then
      # Python fallback. Same transform, stdin/stdout piping.
      _TMP="$(mktemp -t dept-settings.XXXXXX)" || _TMP=""
      if [ -n "$_TMP" ]; then
        if SETTINGS_JSON="$SETTINGS_JSON" HOOK_CMD="$_HOOK_CMD" OUT_FILE="$_TMP" python3 - <<'PY' 2>/dev/null
import json, os, sys
path = os.environ["SETTINGS_JSON"]
cmd  = os.environ["HOOK_CMD"]
out  = os.environ["OUT_FILE"]
with open(path) as f:
    data = json.load(f)
hooks = data.setdefault("hooks", {})
ups   = hooks.setdefault("UserPromptSubmit", [])
ups.append({"hooks": [{"type": "command", "command": cmd, "timeout": 3}]})
with open(out, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
        then
          if [ -s "$_TMP" ]; then
            # Validate parsed round-trip succeeded.
            if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$_TMP" >/dev/null 2>&1; then
              mv "$_TMP" "$SETTINGS_JSON" && _REG_OK=1
            else
              warn "Python produced invalid JSON. Leaving original settings.json untouched."
            fi
          fi
        else
          warn "Python transform failed."
        fi
        [ -f "$_TMP" ] && rm -f "$_TMP"
      fi
    fi

    if [ "$_REG_OK" -eq 1 ]; then
      ok "Hook registered under hooks.UserPromptSubmit."
    else
      fail "Could not register hook automatically. Neither jq nor python3 produced a valid result."
      fail ""
      fail "Add this block manually to $SETTINGS_JSON under hooks.UserPromptSubmit:"
      fail ""
      fail "  {"
      fail "    \"hooks\": ["
      fail "      { \"type\": \"command\", \"command\": \"$_HOOK_CMD\", \"timeout\": 3 }"
      fail "    ]"
      fail "  }"
      exit 1
    fi
  fi
fi

# ----- Step 5: Scaffold user overlay tree -----------------------------------

info "Step 5/6 — Scaffolding user overlay tree at $OVERLAY_ROOT"

_CREATED=0
_EXISTING=0
for _dept in $DEPARTMENTS; do
  _target="$OVERLAY_ROOT/$_dept"
  if [ -d "$_target" ]; then
    _EXISTING=$((_EXISTING + 1))
  else
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '     Would create: %s\n' "$_target"
    else
      mkdir -p "$_target" 2>/dev/null && _CREATED=$((_CREATED + 1))
    fi
  fi
done

if [ "$DRY_RUN" -eq 1 ]; then
  skip "Dry run — no directories created."
else
  ok "Overlay tree ready: $_CREATED created, $_EXISTING already existed."
fi

# ----- Step 6: Verify with dry invocation -----------------------------------

info "Step 6/6 — Verifying composer works"

if [ "$DRY_RUN" -eq 1 ]; then
  skip "Dry run — skipping live test."
else
  _TEST_OUT="$(printf '%s' '{"prompt":"/marketing help"}' | "$HOOKS_SRC_INSTALLED" 2>/dev/null)"
  case "$_TEST_OUT" in
    *"Sigma Protocol Department Context: MARKETING"*)
      ok "Composer emitted MARKETING context. Install verified."
      ;;
    *)
      fail "Composer did not emit expected MARKETING context."
      fail "Dry invocation output (first 500 chars):"
      fail "---"
      printf '%s\n' "$_TEST_OUT" | head -c 500 >&2
      printf '\n---\n' >&2
      fail ""
      fail "Check the log for details:"
      fail "  tail -20 ~/.claude/logs/department-composer.log"
      exit 1
      ;;
  esac
fi

# ----- Report ---------------------------------------------------------------

printf '\n'
info "Install complete."
printf '\n'
printf '  Composer:   %s\n' "$HOOKS_SRC_INSTALLED"
printf '  Root file:  %s -> %s\n' "$ROOT_MARKER" "$DISCOVERED_ROOT"
printf '  Overlays:   %s/{marketing,ads,content,growth,engineering,ops,finance,product,sales,design,support,legal,trading,security}\n' "$OVERLAY_ROOT"
printf '  Registered: hooks.UserPromptSubmit in %s\n' "$SETTINGS_JSON"
printf '\n'
printf '  Next: open any Claude Code session and type\n'
printf '\n'
printf '    /marketing write me a launch email\n'
printf '\n'
printf '  Then run /onboard-departments to finish persona setup.\n'
printf '\n'

exit 0
