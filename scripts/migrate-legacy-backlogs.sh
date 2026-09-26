#!/usr/bin/env bash
# migrate-legacy-backlogs.sh
# Copy legacy docs/ralph backlog artifacts into canonical .sigma/backlogs paths
# and rewrite machine-owned references to the canonical backlog root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT_ROOT="$DEFAULT_PROJECT_ROOT"
DRY_RUN=false

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--dry-run] [--project-root <path>]

Options:
  --dry-run            Show planned copies/rewrites without writing files
  --project-root PATH  Override the project root (defaults to the repo containing this script)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --project-root)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Missing value for --project-root" >&2
        exit 1
      fi
      PROJECT_ROOT="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
LEGACY_ROOT="$PROJECT_ROOT/docs/ralph"
CANONICAL_ROOT="$PROJECT_ROOT/.sigma/backlogs"
MACHINE_STATE_ROOT="$PROJECT_ROOT/.sigma"

copied=0
rewritten=0
unchanged=0
conflicts=0

rel_path() {
  local path="$1"
  echo "${path#$PROJECT_ROOT/}"
}

copy_file_if_needed() {
  local src="$1"
  local dest="$2"

  if [[ -f "$dest" ]]; then
    if cmp -s "$src" "$dest"; then
      echo "[=] $(rel_path "$dest")"
      ((unchanged+=1))
      return 0
    fi

    echo "[conflict] $(rel_path "$dest") already exists and differs from $(rel_path "$src")" >&2
    ((conflicts+=1))
    return 0
  fi

  if "$DRY_RUN"; then
    echo "[dry] copy $(rel_path "$src") -> $(rel_path "$dest")"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "[+] $(rel_path "$dest")"
  fi
  ((copied+=1))
}

rewrite_file_refs() {
  local file="$1"
  local tmp_file

  [[ -f "$file" ]] || return 0
  if ! grep -Eq 'docs/ralph|\.sigma/ralph' "$file"; then
    return 0
  fi

  tmp_file="$(mktemp)"
  sed \
    -e 's#docs/ralph/#.sigma/backlogs/#g' \
    -e 's#\.sigma/ralph/#.sigma/backlogs/#g' \
    "$file" > "$tmp_file"

  if cmp -s "$file" "$tmp_file"; then
    rm -f "$tmp_file"
    return 0
  fi

  if "$DRY_RUN"; then
    echo "[dry] rewrite $(rel_path "$file")"
    rm -f "$tmp_file"
  else
    mv "$tmp_file" "$file"
    echo "[~] $(rel_path "$file")"
  fi
  ((rewritten+=1))
}

echo "=== Legacy Backlog Migration ==="
echo "Project root: $PROJECT_ROOT"
echo "Legacy root:  ${LEGACY_ROOT#$PROJECT_ROOT/}"
echo "Target root:  ${CANONICAL_ROOT#$PROJECT_ROOT/}"
echo "Mode: dry-run=$DRY_RUN"
echo

if [[ ! -d "$LEGACY_ROOT" ]]; then
  echo "No legacy docs/ralph directory found. Nothing to migrate."
else
  while IFS= read -r src_file; do
    [[ -z "$src_file" ]] && continue
    rel_legacy="${src_file#$LEGACY_ROOT/}"
    dest_file="$CANONICAL_ROOT/$rel_legacy"
    copy_file_if_needed "$src_file" "$dest_file"

    if [[ -f "$dest_file" ]]; then
      rewrite_file_refs "$dest_file"
    fi
  done < <(find "$LEGACY_ROOT" -mindepth 2 -type f | sort)
fi

if [[ -d "$MACHINE_STATE_ROOT" ]]; then
  while IFS= read -r state_file; do
    [[ -z "$state_file" ]] && continue
    rewrite_file_refs "$state_file"
  done < <(find "$MACHINE_STATE_ROOT" -type f \( -name '*.json' -o -name '*.txt' -o -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.sigma' \) | sort)
fi

echo
echo "=== Summary ==="
echo "Copied: $copied"
echo "Rewritten: $rewritten"
echo "Unchanged: $unchanged"
echo "Conflicts: $conflicts"

if (( conflicts > 0 )); then
  exit 1
fi
