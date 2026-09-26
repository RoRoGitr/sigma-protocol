#!/usr/bin/env bash
# scripts/sigma-dispatch.sh — execute a canonical PRD via the active CLI's native primitive.
# Used by the /sigma-dispatch slash command (commands/sigma-dispatch.md, slice 3a).
#
# Usage:
#   bash scripts/sigma-dispatch.sh <prd-id> [--dry-run] [--slice <id>]
#   bash scripts/sigma-dispatch.sh --all [--dry-run]
#   bash scripts/sigma-dispatch.sh --help

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root (script may be invoked from any CWD)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
print_help() {
  cat <<'EOF'
sigma-dispatch.sh — Execute a canonical PRD via the active CLI's native primitive.

Usage:
  bash scripts/sigma-dispatch.sh <prd-id> [--dry-run] [--slice <id>]
  bash scripts/sigma-dispatch.sh --all [--dry-run]
  bash scripts/sigma-dispatch.sh --help

Arguments:
  <prd-id>          PRD identifier (e.g. F01.001). Must match ^[A-Z][A-Z0-9-]+(\.[a-z0-9]+)*$
  --dry-run         Print what would fire; do not execute.
  --slice <id>      Dispatch a single named slice of a sliced PRD.
  --all             Batch-dispatch all unbuilt PRDs in dependency order (serial).
  --help, -h        Show this help.

CLI auto-detection:
  claude  — CLAUDECODE_ENTRYPOINT or CLAUDE_CODE_* env vars
  codex   — CODEX_EXEC=1 or CODEX_* env vars
  droid   — DROID_SESSION_ID or FACTORY_* env vars
  auggie  — not supported for dispatch (runs manually)
  unknown — error; set the appropriate env var for your CLI

Bundle paths (built by Phase 2 emitters):
  claude: .sigma/dispatch/claude/<prd-id>.goal.md
  codex:  .sigma/dispatch/codex/<prd-id>.goal.md
  droid:  .sigma/dispatch/droid/<prd-slug>/mission.md

Examples:
  bash scripts/sigma-dispatch.sh F01.001
  bash scripts/sigma-dispatch.sh F01.001 --dry-run
  bash scripts/sigma-dispatch.sh F01.001 --slice auth-login
  bash scripts/sigma-dispatch.sh --all --dry-run
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
PRD_ID=""
DRY_RUN=false
SLICE_ID=""
ALL_MODE=false

if [[ $# -eq 0 ]]; then
  print_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      print_help
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --slice)
      if [[ $# -lt 2 ]]; then
        echo "[sigma-dispatch] ERROR: --slice requires an argument." >&2
        exit 1
      fi
      SLICE_ID="$2"
      shift 2
      ;;
    --all)
      ALL_MODE=true
      shift
      ;;
    -*)
      echo "[sigma-dispatch] ERROR: Unknown flag: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1
      ;;
    *)
      if [[ -n "$PRD_ID" ]]; then
        echo "[sigma-dispatch] ERROR: Multiple PRD IDs provided: '$PRD_ID' and '$1'" >&2
        exit 1
      fi
      PRD_ID="$1"
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Security: validate PRD-ID format
# Reject anything not matching ^[A-Z][A-Z0-9-]+(\.[a-z0-9]+)*$
# This prevents shell injection via PRD-ID.
# ---------------------------------------------------------------------------
validate_prd_id() {
  local id="$1"
  if [[ -z "$id" ]]; then
    echo "[sigma-dispatch] ERROR: PRD ID is required." >&2
    echo "Usage: bash scripts/sigma-dispatch.sh <prd-id> [--dry-run]" >&2
    return 1
  fi
  # Pattern: uppercase letter, then uppercase letters/digits/hyphens,
  # optionally followed by dot-separated lowercase alphanumeric suffixes.
  if [[ ! "$id" =~ ^[A-Z][A-Z0-9-]+(\.[a-z0-9]+)*$ ]]; then
    echo "[sigma-dispatch] ERROR: Invalid PRD ID format: '$id'" >&2
    echo "  PRD IDs must match: ^[A-Z][A-Z0-9-]+(\\.[a-z0-9]+)*\$" >&2
    echo "  Examples: F01.001, PRD-AUTH, FEATURE-01.a" >&2
    echo "  Rejected to prevent shell injection." >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# CLI detection
# ---------------------------------------------------------------------------
detect_cli() {
  local cli
  cli="$(bash "$SCRIPT_DIR/detect-cli.sh" 2>/dev/null)"
  echo "$cli"
}

check_cli() {
  local cli="$1"
  case "$cli" in
    claude|codex|droid)
      return 0
      ;;
    auggie)
      echo "[sigma-dispatch] ERROR: Auggie dispatch not supported." >&2
      echo "  Auggie does not support autonomous /goal or --mission invocation." >&2
      echo "  Run the primitive manually using the dispatch bundle:" >&2
      echo "  cat .sigma/dispatch/auggie/<prd-id>.* (if emitted)" >&2
      return 1
      ;;
    unknown|*)
      echo "[sigma-dispatch] ERROR: Cannot detect active CLI." >&2
      echo "  Set one of these environment variables before running:" >&2
      echo "    Claude Code : CLAUDECODE_ENTRYPOINT=1" >&2
      echo "    Codex       : CODEX_EXEC=1" >&2
      echo "    Droid       : DROID_SESSION_ID=<session-id>" >&2
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# PRD resolution
# Searches docs/prds/**/<prd-id>*.md excluding flows/ subdirectory.
# ---------------------------------------------------------------------------
resolve_prd() {
  local prd_id="$1"
  local prd_file

  # Search recursively, skip flows/ (Step 5 prototypes)
  prd_file="$(find "$REPO_ROOT/docs/prds" -name "${prd_id}*.md" \
    -not -path "*/flows/*" \
    -not -path "*/completed/*" \
    2>/dev/null | head -1)"

  if [[ -z "$prd_file" ]]; then
    echo "[sigma-dispatch] ERROR: PRD '$prd_id' not found in docs/prds/." >&2

    # Fuzzy suggestion: list nearby PRDs by prefix
    local prefix="${prd_id%%.*}"
    local suggestions
    suggestions="$(find "$REPO_ROOT/docs/prds" -name "*.md" \
      -not -path "*/flows/*" \
      2>/dev/null \
      | xargs -I{} basename {} \
      | grep -i "^${prefix}" 2>/dev/null | head -5 || true)"

    if [[ -n "$suggestions" ]]; then
      echo "  Did you mean one of:" >&2
      while IFS= read -r s; do
        echo "    $s" >&2
      done <<< "$suggestions"
    else
      echo "  Run 'ls docs/prds/' to see available PRDs." >&2
    fi
    return 1
  fi

  echo "$prd_file"
}

# ---------------------------------------------------------------------------
# PRD slug derivation (for droid bundles)
# Takes the PRD ID and converts to a slug the emitter would have used.
# Convention from emit_droid_mission.py: lowercase, hyphens.
# ---------------------------------------------------------------------------
prd_to_slug() {
  local prd_id="$1"
  # Strip the leading category prefix (F01, PRD-, etc.) and lowercase
  echo "$prd_id" | tr '[:upper:]' '[:lower:]' | tr '.' '-'
}

# ---------------------------------------------------------------------------
# Bundle verification
# Returns the bundle path on success; error + hint on failure.
# ---------------------------------------------------------------------------
verify_bundle() {
  local cli="$1"
  local prd_id="$2"
  local bundle_path=""

  case "$cli" in
    claude)
      bundle_path="$REPO_ROOT/.sigma/dispatch/claude/${prd_id}.goal.md"
      if [[ ! -f "$bundle_path" ]]; then
        echo "[sigma-dispatch] ERROR: No Claude dispatch bundle for '${prd_id}'." >&2
        echo "  Expected: $bundle_path" >&2
        # Find the PRD file for the hint
        local prd_file
        prd_file="$(find "$REPO_ROOT/docs/prds" -name "${prd_id}*.md" -not -path "*/flows/*" 2>/dev/null | head -1 || echo "docs/prds/${prd_id}.md")"
        echo "  Generate it: python3 scripts/emitters/emit_claude_bundle.py $prd_file" >&2
        return 1
      fi
      # Guard: bundle must not escape .sigma/dispatch/
      local real_bundle real_dispatch
      real_bundle="$(cd "$(dirname "$bundle_path")" && pwd)/$(basename "$bundle_path")"
      real_dispatch="$(cd "$REPO_ROOT/.sigma/dispatch" && pwd)"
      if [[ "$real_bundle" != "$real_dispatch"* ]]; then
        echo "[sigma-dispatch] SECURITY: Bundle path escapes .sigma/dispatch/ — refusing." >&2
        return 1
      fi
      ;;
    codex)
      bundle_path="$REPO_ROOT/.sigma/dispatch/codex/${prd_id}.goal.md"
      if [[ ! -f "$bundle_path" ]]; then
        echo "[sigma-dispatch] ERROR: No Codex dispatch bundle for '${prd_id}'." >&2
        echo "  Expected: $bundle_path" >&2
        local prd_file
        prd_file="$(find "$REPO_ROOT/docs/prds" -name "${prd_id}*.md" -not -path "*/flows/*" 2>/dev/null | head -1 || echo "docs/prds/${prd_id}.md")"
        echo "  Generate it: python3 scripts/emitters/emit_codex_bundle.py $prd_file" >&2
        return 1
      fi
      local real_bundle real_dispatch
      real_bundle="$(cd "$(dirname "$bundle_path")" && pwd)/$(basename "$bundle_path")"
      real_dispatch="$(cd "$REPO_ROOT/.sigma/dispatch" && pwd)"
      if [[ "$real_bundle" != "$real_dispatch"* ]]; then
        echo "[sigma-dispatch] SECURITY: Bundle path escapes .sigma/dispatch/ — refusing." >&2
        return 1
      fi
      ;;
    droid)
      # Droid bundles are written to .sigma/dispatch/droid/<slug>/ where <slug>
      # comes from the PRD's slug field — NOT from the PRD-ID.  The prd_to_slug
      # heuristic (lowercase + dots→hyphens) is a fallback only.
      #
      # Resolution order:
      #   1. Scan features.json files for one whose feature IDs share the prd_id
      #      prefix — this finds the bundle regardless of what slug was used.
      #   2. Fall back to the prd_to_slug() heuristic path.

      local slug_dir=""

      # Step 1: scan all droid bundle dirs for a features.json that references
      # this prd_id (exact match or slice prefix "F99.001." / "F99.001.a").
      local droid_dispatch_dir="$REPO_ROOT/.sigma/dispatch/droid"
      if [[ -d "$droid_dispatch_dir" ]]; then
        while IFS= read -r -d '' features_file; do
          # Use Python to parse; -c is safe — no user input is interpolated.
          if python3 - "$features_file" "$prd_id" <<'PYEOF' 2>/dev/null
import json, sys
path, prd_id = sys.argv[1], sys.argv[2]
try:
    data = json.loads(open(path).read())
    for feat in data.get("features", []):
        fid = feat.get("id", "")
        if fid == prd_id or fid.startswith(prd_id + "."):
            sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(1)
PYEOF
          then
            slug_dir="$(dirname "$features_file")"
            break
          fi
        done < <(find "$droid_dispatch_dir" -name "features.json" -print0 2>/dev/null)
      fi

      # Step 2: fallback to the prd_to_slug heuristic
      if [[ -z "$slug_dir" ]]; then
        local heuristic_slug
        heuristic_slug="$(prd_to_slug "$prd_id")"
        slug_dir="$droid_dispatch_dir/${heuristic_slug}"
      fi

      bundle_path="${slug_dir}/mission.md"

      if [[ ! -f "$bundle_path" ]]; then
        echo "[sigma-dispatch] ERROR: No Droid dispatch bundle for '${prd_id}'." >&2
        echo "  Searched all dirs under $droid_dispatch_dir (by features.json match)" >&2
        local prd_file
        prd_file="$(find "$REPO_ROOT/docs/prds" -name "${prd_id}*.md" -not -path "*/flows/*" 2>/dev/null | head -1 || echo "docs/prds/${prd_id}.md")"
        echo "  Generate it: python3 scripts/emitters/emit_droid_mission.py $prd_file" >&2
        return 1
      fi
      local real_bundle real_dispatch
      real_bundle="$(cd "$(dirname "$bundle_path")" && pwd)/$(basename "$bundle_path")"
      real_dispatch="$(cd "$REPO_ROOT/.sigma/dispatch" && pwd)"
      if [[ "$real_bundle" != "$real_dispatch"* ]]; then
        echo "[sigma-dispatch] SECURITY: Bundle path escapes .sigma/dispatch/ — refusing." >&2
        return 1
      fi
      ;;
  esac

  echo "$bundle_path"
}

# ---------------------------------------------------------------------------
# Build CLI invocation command
# Bundle content is injected as DATA via heredoc/env var to avoid re-evaluation.
# ---------------------------------------------------------------------------
build_command() {
  local cli="$1"
  local bundle_path="$2"
  local perm_mode="${SIGMA_DISPATCH_PERM_MODE:-acceptEdits}"

  case "$cli" in
    claude)
      # Pass bundle content via env var to avoid shell re-evaluation of content.
      # The goal text is treated as data, not code.
      echo "SIGMA_GOAL_CONTENT=\$(cat $(printf '%q' "$bundle_path")) && claude -p \"\$SIGMA_GOAL_CONTENT\" --permission-mode $perm_mode"
      ;;
    codex)
      echo "SIGMA_GOAL_CONTENT=\$(cat $(printf '%q' "$bundle_path")) && codex exec --auto high \"\$SIGMA_GOAL_CONTENT\""
      ;;
    droid)
      echo "droid exec --mission -f $(printf '%q' "$bundle_path")"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Codex feature gate check
# ---------------------------------------------------------------------------
check_codex_features() {
  local config_file="$HOME/.codex/config.toml"
  if [[ -f "$config_file" ]] && grep -q 'features' "$config_file" 2>/dev/null; then
    if ! grep -q 'goals.*=.*true' "$config_file" 2>/dev/null; then
      echo "[sigma-dispatch] WARNING: Codex feature 'goals' may not be enabled." >&2
      echo "  If dispatch fails, run: codex features enable goals" >&2
      echo "  Or add 'goals = true' under [features] in ~/.codex/config.toml" >&2
    fi
  fi
  # Non-fatal: proceed even if we can't verify
}

# ---------------------------------------------------------------------------
# Dispatch a single PRD
# ---------------------------------------------------------------------------
dispatch_one() {
  local prd_id="$1"
  local cli="$2"

  # Validate ID
  validate_prd_id "$prd_id" || return 1

  # Resolve PRD file (existence check)
  local prd_file
  prd_file="$(resolve_prd "$prd_id")" || return 1

  # Verify bundle exists
  local bundle_path
  bundle_path="$(verify_bundle "$cli" "$prd_id")" || return 1

  # CLI-specific feature checks
  if [[ "$cli" == "codex" ]]; then
    check_codex_features
  fi

  # Build invocation
  local cmd
  cmd="$(build_command "$cli" "$bundle_path")"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would execute ($cli):"
    echo "  $cmd"
    echo "[DRY-RUN] Bundle path: $bundle_path"
    if [[ -n "$SLICE_ID" ]]; then
      echo "[DRY-RUN] Slice: $SLICE_ID (passed via SIGMA_SLICE env in real invocation)"
    fi
    return 0
  fi

  echo "[sigma-dispatch] Executing ($cli): $cmd"
  if [[ -n "$SLICE_ID" ]]; then
    SIGMA_SLICE="$SLICE_ID" eval "$cmd"
  else
    eval "$cmd"
  fi
}

# ---------------------------------------------------------------------------
# Topological sort for --all mode
# Reads .prd-status.json if present; falls back to alphabetical.
# ---------------------------------------------------------------------------
topo_sort_prds() {
  local status_file="$REPO_ROOT/docs/prds/.prd-status.json"
  local prd_files=()

  # Collect all implementation PRD files (skip flows/ and completed/)
  while IFS= read -r -d '' f; do
    prd_files+=("$f")
  done < <(find "$REPO_ROOT/docs/prds" -name "*.md" \
    -not -path "*/flows/*" \
    -not -path "*/completed/*" \
    -print0 2>/dev/null | sort -z)

  if [[ "${#prd_files[@]}" -eq 0 ]]; then
    echo "[sigma-dispatch] No PRDs found in docs/prds/ (excluding flows/ and completed/)." >&2
    return 1
  fi

  if [[ -f "$status_file" ]]; then
    # Parse JSON dependency order using Python (minimal, no extra deps)
    python3 - "$status_file" "${prd_files[@]}" <<'PYEOF'
import json
import sys

status_file = sys.argv[1]
prd_files = sys.argv[2:]

with open(status_file) as f:
    status_data = json.load(f)

# Build id -> entry map
entries = {}
for entry in status_data if isinstance(status_data, list) else status_data.values():
    if isinstance(entry, dict) and "prd_id" in entry:
        entries[entry["prd_id"]] = entry

# Topological sort by depends_on
ordered = []
visited = set()

def visit(prd_id):
    if prd_id in visited:
        return
    visited.add(prd_id)
    entry = entries.get(prd_id, {})
    for dep in entry.get("depends_on", []):
        visit(dep)
    # Skip done entries
    if entry.get("status") != "done":
        ordered.append(prd_id)

for entry in (status_data if isinstance(status_data, list) else status_data.values()):
    if isinstance(entry, dict) and "prd_id" in entry:
        visit(entry["prd_id"])

# Print ordered IDs
for prd_id in ordered:
    print(prd_id)
PYEOF
  else
    # No status file — print file basenames stripped of extension (alphabetical)
    for f in "${prd_files[@]}"; do
      basename "$f" .md
    done
  fi
}

# ---------------------------------------------------------------------------
# --all batch dispatch
# ---------------------------------------------------------------------------
dispatch_all() {
  local cli="$1"
  local ordered_ids=()

  # Get ordered PRD IDs
  while IFS= read -r id; do
    [[ -n "$id" ]] && ordered_ids+=("$id")
  done < <(topo_sort_prds 2>&1)

  if [[ "${#ordered_ids[@]}" -eq 0 ]]; then
    echo "[sigma-dispatch] No PRDs to dispatch." >&2
    return 0
  fi

  echo "[sigma-dispatch] --all mode: ${#ordered_ids[@]} PRDs queued (serial execution)"
  echo ""

  local summary_ok=()
  local summary_fail=()
  local summary_skip=()

  for prd_id in "${ordered_ids[@]}"; do
    # Skip IDs that don't match the pattern (e.g. wave-N filenames)
    if ! [[ "$prd_id" =~ ^[A-Z][A-Z0-9-]+(\.[a-z0-9]+)*$ ]]; then
      echo "[sigma-dispatch] SKIP: '$prd_id' does not match PRD ID pattern — skipping." >&2
      summary_skip+=("$prd_id")
      continue
    fi

    echo "--- Dispatching $prd_id ---"
    set +e
    dispatch_one "$prd_id" "$cli"
    local ec=$?
    set -e

    if [[ $ec -eq 0 ]]; then
      local sha=""
      sha="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "n/a")"
      summary_ok+=("$prd_id|done|$ec|$sha")
    else
      echo "[sigma-dispatch] FAILED: $prd_id (exit $ec) — continuing." >&2
      summary_fail+=("$prd_id|failed|$ec|n/a")
    fi
    echo ""
  done

  # Summary table
  echo "=============================="
  echo " Summary: --all dispatch"
  echo "=============================="
  printf "%-30s %-10s %-6s %-12s\n" "PRD-ID" "STATUS" "EXIT" "COMMIT-SHA"
  printf "%-30s %-10s %-6s %-12s\n" "------------------------------" "----------" "------" "------------"
  for entry in "${summary_ok[@]}" "${summary_fail[@]}" "${summary_skip[@]}"; do
    IFS='|' read -r id status ec sha <<< "$entry"
    printf "%-30s %-10s %-6s %-12s\n" "$id" "$status" "$ec" "$sha"
  done

  if [[ "${#summary_fail[@]}" -gt 0 ]]; then
    echo ""
    echo "[sigma-dispatch] ${#summary_fail[@]} PRD(s) failed. See above for details."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ "$ALL_MODE" == true ]]; then
  CLI="$(detect_cli)"
  check_cli "$CLI" || exit 1
  dispatch_all "$CLI"
  exit $?
fi

# Single PRD mode
if [[ -z "$PRD_ID" ]]; then
  echo "[sigma-dispatch] ERROR: PRD ID required." >&2
  echo "Usage: bash scripts/sigma-dispatch.sh <prd-id> [--dry-run]" >&2
  echo "Run with --help for full usage." >&2
  exit 1
fi

CLI="$(detect_cli)"
check_cli "$CLI" || exit 1

dispatch_one "$PRD_ID" "$CLI"
exit $?
