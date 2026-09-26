#!/usr/bin/env bash
# department-composer.sh
#
# UserPromptSubmit hook for Sigma Protocol C-suite department invocations.
#
# When a user's prompt starts with /marketing, /ads, /content, /growth,
# /engineering, /ops, or /finance, this hook composes three context layers
# and prints them to stdout so Claude ingests them as additional system
# context before executing the slash command.
#
# Layer 1: Department canon     (Sigma Protocol repo, stable)
# Layer 2: Project overlay      (per-repo .claude/departments/)
# Layer 3: User overlay         (Claude Brain, self-evolving)
#
# Contract: fail-safe. If composition breaks, exit 0 with no stdout so the
# slash command still runs — the user just loses the overlay injection.
# Every outcome (hit, miss, skip, error) lands in the log file.
#
# Portability: targets Apple's system bash 3.2. No associative arrays,
# no `${var,,}`, no `$EPOCHREALTIME`, no `printf -v ... '%(%s)T'`.

set -u
# IMPORTANT: no `set -e`. We must never crash the user's session.

# ----- Configuration ---------------------------------------------------------

# Invokable command surfaces. This list mirrors the canonical 13 departments in
# .claude/lib/agent-skill-registry.json. Alias slashes (/ads, /growth, /support,
# /gtm, /go-to-market, ...) resolve through config.department_aliases in that
# registry — see detect_department below. Alias-canon directories (an alias with
# its own .agents/departments/<alias>/department.md) compose their own canon.
DEPARTMENTS="engineering security legal marketing content finance ops sales product community trading design qa"

# SSS_PROTOCOL_ROOT resolution order (first match wins):
#   1. $SSS_PROTOCOL_ROOT env var (set by parent shell or launchd)
#   2. ~/.claude/sigma-protocol-root file (written by install-departments.sh)
#
# If none of those point to a directory containing .agents/departments/SCHEMA.md,
# Layer 1 is skipped (graceful degradation) and a WARN is logged. The hook
# still runs — the student just loses the canon layer until they reinstall.
_SPR_ROOT_FILE="$HOME/.claude/sigma-protocol-root"
if [ -n "${SSS_PROTOCOL_ROOT:-}" ]; then
  : # honor env var as-is
elif [ -r "$_SPR_ROOT_FILE" ]; then
  # Trim whitespace/newlines from the helper file's contents.
  SSS_PROTOCOL_ROOT="$(tr -d '\r\n' < "$_SPR_ROOT_FILE" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
else
  SSS_PROTOCOL_ROOT=""
fi
DEPT_CANON_DIR="${SSS_PROTOCOL_ROOT}/.agents/departments"

USER_OVERLAY_ROOT="${USER_OVERLAY_ROOT:-$HOME/.claude/departments}"

LOG_DIR="$HOME/.claude/logs"
LOG_FILE="$LOG_DIR/department-composer.log"

# Overlay safety: overlays marked with these substrings (case-insensitive)
# never make it into composed context — the layer is dropped and a warning is
# logged. Operators can extend the list (one term per line, lowercase) via
# ~/.claude/department-composer-banned.txt to keep private material out of
# any install that ships onward.
BANNED_TERMS="confidential-internal do-not-ship internal-only"
if [ -r "$HOME/.claude/department-composer-banned.txt" ]; then
  _EXTRA_BANNED="$(tr '\n' ' ' < "$HOME/.claude/department-composer-banned.txt" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  [ -n "${_EXTRA_BANNED// /}" ] && BANNED_TERMS="$BANNED_TERMS $_EXTRA_BANNED"
fi

# Composer budget. Exceeding this logs a WARN but never fails.
SOFT_BUDGET_MS=200

# ----- Helpers ---------------------------------------------------------------

log() {
  # log <level> <message>
  # Logging is best-effort. Never fail the hook if logging breaks.
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR" 2>/dev/null || return 0
  fi
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"
  printf '%s [%s] %s\n' "$ts" "$1" "$2" >> "$LOG_FILE" 2>/dev/null || true
}

now_ms() {
  # Millisecond epoch. On macOS bash 3.2 we don't have EPOCHREALTIME.
  # `gdate +%s%3N` works when coreutils is installed; otherwise we fall
  # back to seconds*1000 (200ms budget is coarse enough that this is OK).
  if [ -n "${EPOCHREALTIME:-}" ]; then
    local er="$EPOCHREALTIME"
    local secs="${er%.*}"
    local frac="${er#*.}"
    frac="${frac}000"
    frac="${frac:0:3}"
    printf '%s%s' "$secs" "$frac"
    return
  fi
  if command -v gdate >/dev/null 2>&1; then
    gdate +%s%3N 2>/dev/null && return
  fi
  # Fallback: seconds * 1000.
  local s
  s="$(date +%s 2>/dev/null || echo 0)"
  printf '%s' "$((s * 1000))"
}

lower() {
  # Pure-bash-plus-tr lowercase. `tr` is a mandatory POSIX utility.
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

resolve_alias() {
  # resolve_alias <token>
  # Looks the token up in config.department_aliases of the repo registry and
  # prints the target department (or nothing). Bash-3.2-safe flat-JSON scan;
  # fail-open — a missing or unreadable registry just means no alias support.
  local token="$1"
  local reg="${SSS_PROTOCOL_ROOT}/.claude/lib/agent-skill-registry.json"
  [ -r "$reg" ] || return 0
  sed -n '/"department_aliases"/,/}/p' "$reg" 2>/dev/null \
    | sed -n "s/.*\"${token}\"[[:space:]]*:[[:space:]]*\"\([a-z_-]*\)\".*/\1/p" \
    | head -1
}

detect_department() {
  # Inspects the prompt, extracts first whitespace-delimited token, strips
  # the leading slash and any trailing ":subcommand". Matches against the
  # canonical departments, then config.department_aliases. For an alias with
  # its own canon directory (alias-canon, e.g. /gtm or /ads), the alias name
  # is returned so its own department.md composes; otherwise the alias
  # resolves to its target department. Prints the matched name or empty.
  local prompt="$1"
  # Trim leading whitespace.
  # bash 3.2: no extglob-free pattern for this, so use a case+loop.
  while :; do
    case "$prompt" in
      [[:space:]]*) prompt="${prompt#?}" ;;
      *) break ;;
    esac
  done
  # First token up to whitespace.
  local first="${prompt%%[[:space:]]*}"
  case "$first" in
    /*) : ;;
    *) return 0 ;;
  esac
  local candidate="${first#/}"
  candidate="${candidate%%:*}"
  candidate="$(lower "$candidate")"
  local d
  for d in $DEPARTMENTS; do
    if [ "$candidate" = "$d" ]; then
      printf '%s' "$d"
      return 0
    fi
  done
  # Alias path: /gtm → gtm (alias-canon dir exists) or its registry target.
  local target
  target="$(resolve_alias "$candidate")"
  if [ -n "$target" ]; then
    if [ -f "${DEPT_CANON_DIR}/${candidate}/department.md" ]; then
      printf '%s' "$candidate"
    else
      printf '%s' "$target"
    fi
    return 0
  fi
  return 0
}

scan_banned() {
  # Returns 0 if content is clean, 1 if it contains any banned term.
  # Case-insensitive: lowercase content once, then substring match via
  # bash `case ... in` (fork-free).
  local content_lower
  content_lower="$(lower "$1")"
  local t
  for t in $BANNED_TERMS; do
    case "$content_lower" in
      *"$t"*) return 1 ;;
    esac
  done
  return 0
}

read_layer() {
  # read_layer <layer-number> <label> <path>
  # If the file exists and is non-empty and clean, prints it with a divider
  # and increments LAYERS_EMITTED. Missing/empty/banned → silently skip and log.
  local num="$1"
  local label="$2"
  local path="$3"
  if [ ! -f "$path" ]; then
    log INFO "layer ${num} (${label}) missing: ${path}"
    return 0
  fi
  if [ ! -s "$path" ]; then
    log INFO "layer ${num} (${label}) empty: ${path}"
    return 0
  fi
  local content
  content="$(cat "$path" 2>/dev/null)" || {
    log WARN "layer ${num} (${label}) unreadable: ${path}"
    return 0
  }
  if ! scan_banned "$content"; then
    log WARN "layer ${num} (${label}) contains banned terms, dropped: ${path}"
    return 0
  fi
  printf '\n## LAYER %s — %s\n' "$num" "$label"
  printf 'Source: %s\n\n' "$path"
  printf '%s\n' "$content"
  LAYERS_EMITTED=$((LAYERS_EMITTED + 1))
}

extract_prompt_from_json() {
  # Pure-bash extraction of a "prompt" or "user_prompt" string from a JSON
  # payload. Handles simple escapes (\", \\, \n, \t). Good enough for the
  # prompt field — we don't need full JSON parsing.
  local raw="$1"
  case "$raw" in
    *'"prompt"'*|*'"user_prompt"'*) : ;;
    *) printf '%s' "$raw"; return 0 ;;
  esac
  local key pat val
  for key in prompt user_prompt; do
    pat="\"$key\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]*(\\\\.[^\"\\\\]*)*)\""
    if [[ "$raw" =~ $pat ]]; then
      val="${BASH_REMATCH[1]}"
      val="${val//\\n/$'\n'}"
      val="${val//\\t/$'\t'}"
      val="${val//\\\"/\"}"
      val="${val//\\\\/\\}"
      printf '%s' "$val"
      return 0
    fi
  done
  printf '%s' "$raw"
}

upper() {
  printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

# ----- Main ------------------------------------------------------------------

START_MS="$(now_ms)"

# Claude Code passes the UserPromptSubmit payload as JSON on stdin. Accept
# either JSON or a raw prompt string. If stdin is a TTY, no input.
RAW_INPUT=""
if [ ! -t 0 ]; then
  RAW_INPUT="$(cat 2>/dev/null || true)"
fi

PROMPT="$(extract_prompt_from_json "$RAW_INPUT")"

DEPT="$(detect_department "$PROMPT")"

if [ -z "$DEPT" ]; then
  # Not a department invocation — silent exit, no stdout.
  exit 0
fi

# ----- Layer sourcing --------------------------------------------------------

# Validate canon root. If SCHEMA.md is missing, the configured root is wrong
# (student moved their checkout, deleted the repo, SSS_PROTOCOL_ROOT points
# to junk). Log once and skip Layer 1 — Layers 2 and 3 still work.
CANON_VALID=1
if [ ! -f "${DEPT_CANON_DIR}/SCHEMA.md" ]; then
  log WARN "canon invalid — SCHEMA.md not found at ${DEPT_CANON_DIR}/SCHEMA.md (SSS_PROTOCOL_ROOT=${SSS_PROTOCOL_ROOT}). Layer 1 skipped. Run scripts/install-departments.sh to fix."
  CANON_VALID=0
fi

if [ "$CANON_VALID" -eq 1 ]; then
  LAYER1_PATH="${DEPT_CANON_DIR}/${DEPT}/department.md"
else
  LAYER1_PATH="/dev/null"  # forces read_layer's file-exists check to fall through
fi

# Layer 2 — project overlay. Resolve from CWD.
CWD="$(pwd)"
LAYER2_PATH="${CWD}/.claude/departments/${DEPT}.md"

# Layer 3 — user overlay (Claude Brain, self-evolving).
LAYER3_PATH="${USER_OVERLAY_ROOT}/${DEPT}/user-overlay.md"

# ----- Compose ---------------------------------------------------------------

# Quick presence check so we can short-circuit the "no canon, no overlays"
# case without even opening a pipeline.
LAYERS_PRESENT=0
[ -s "$LAYER1_PATH" ] && LAYERS_PRESENT=$((LAYERS_PRESENT + 1))
[ -s "$LAYER2_PATH" ] && LAYERS_PRESENT=$((LAYERS_PRESENT + 1))
[ -s "$LAYER3_PATH" ] && LAYERS_PRESENT=$((LAYERS_PRESENT + 1))

DEPT_UPPER="$(upper "$DEPT")"

if [ "$LAYERS_PRESENT" -eq 0 ]; then
  log WARN "dept=${DEPT} all layers missing — canon path: ${LAYER1_PATH}"
  printf '# Sigma Protocol Department: %s\n' "$DEPT_UPPER"
  printf '(No canon file found at %s. Run `/step-13-skillpack-generator` or reinstall Sigma Protocol to restore.)\n' "$LAYER1_PATH"
  exit 0
fi

# LAYERS_EMITTED is incremented by read_layer when a layer survives all
# filters (present, non-empty, readable, clean). The difference between
# LAYERS_PRESENT and LAYERS_EMITTED is layers dropped by the banned scan.
LAYERS_EMITTED=0

NOW_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"
printf '# Sigma Protocol Department Context: %s\n' "$DEPT_UPPER"
printf 'Composed at: %s\n' "$NOW_TS"
printf 'CWD: %s\n' "$CWD"
printf -- '---\n'
read_layer 1 "Department Canon" "$LAYER1_PATH"
read_layer 2 "Project Overlay"  "$LAYER2_PATH"
read_layer 3 "User Overlay"     "$LAYER3_PATH"
printf -- '\n---\n'
printf 'End of department context. The /%s slash command now executes with the persona and skills defined above.\n' "$DEPT"

END_MS="$(now_ms)"
ELAPSED=$((END_MS - START_MS))
log INFO "dept=${DEPT} emitted=${LAYERS_EMITTED}/${LAYERS_PRESENT} elapsed_ms=${ELAPSED} cwd=${CWD}"

if [ "$ELAPSED" -gt "$SOFT_BUDGET_MS" ]; then
  log WARN "composer exceeded budget: ${ELAPSED}ms > ${SOFT_BUDGET_MS}ms (dept=${DEPT})"
fi

exit 0
