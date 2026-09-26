#!/usr/bin/env bash
# sync-steps-to-platforms.sh
# Render canonical step files from steps/ into commands/ (single OSS surface).
# Partials in steps/_partials/ are inlined at render time.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STEPS_DIR="$PROJECT_ROOT/steps"
PARTIALS_DIR="$STEPS_DIR/_partials"
COMMANDS_TARGET="$PROJECT_ROOT/commands"
source "$SCRIPT_DIR/lib/step-partials.sh"

DRY_RUN=false
PRUNE=false

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--dry-run] [--prune]

Options:
  --dry-run   Show planned changes without writing files
  --prune     Remove stale command files that no longer exist in steps/
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --prune) PRUNE=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

is_step_mirror_name() {
  local name="$1"
  if [[ "$name" == "step-verify" ]]; then
    return 1
  fi
  [[ "$name" == step-* || "$name" == run-* || "$name" == "dev-loop" || "$name" == "validate-methodology" ]]
}

is_forbidden_legacy_step_name() {
  local name="$1"
  [[ "$name" == "step-5a-prototype-prep" || "$name" == "step-5b-prd-to-json" || "$name" == "step-11a-prd-to-json" || "$name" == "step-11b-prd-swarm" ]]
}

if [[ ! -d "$STEPS_DIR" ]]; then
  echo "ERROR: steps directory not found: $STEPS_DIR" >&2
  exit 1
fi

echo "=== Sigma Step Render ==="
echo "Source: $STEPS_DIR"
echo "Target: ${COMMANDS_TARGET#$PROJECT_ROOT/}"
echo "Mode: dry-run=$DRY_RUN prune=$PRUNE"
echo

mkdir -p "$COMMANDS_TARGET"

synced=0
skipped=0
RENDER_TMP="$(mktemp)"
trap 'rm -f "$RENDER_TMP"' EXIT

while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  base="$(basename "$src")"
  [[ "$base" == "README.md" || "$base" == "README" ]] && continue

  name="${base%.md}"
  if is_forbidden_legacy_step_name "$name"; then
    echo "[skip] forbidden legacy step source excluded: $name"
    ((skipped+=1))
    continue
  fi

  if ! expand_step_partials "$src" "$RENDER_TMP" "$STEPS_DIR"; then
    echo "ERROR: failed to render ${src#$PROJECT_ROOT/}" >&2
    exit 1
  fi

  dest="$COMMANDS_TARGET/$name.md"
  adapter="$PROJECT_ROOT/.agents/skills/$name/SKILL.md"
  if [[ -f "$adapter" ]] && grep -Fq "canonical_source: \"steps/$name\"" "$adapter"; then
    reference="$PROJECT_ROOT/.agents/skills/$name/references/step.md"
    if [[ ! -f "$reference" ]] || ! cmp -s "$RENDER_TMP" "$reference"; then
      if "$DRY_RUN"; then
        echo "[dry] bundle ${reference#$PROJECT_ROOT/}"
      else
        mkdir -p "$(dirname "$reference")"
        cp "$RENDER_TMP" "$reference"
        echo "[+] ${reference#$PROJECT_ROOT/}"
      fi
    fi
  fi
  if [[ -f "$dest" ]] && cmp -s "$RENDER_TMP" "$dest"; then
    echo "[=] ${dest#$PROJECT_ROOT/}"
    continue
  fi

  if "$DRY_RUN"; then
    echo "[dry] sync ${src#$PROJECT_ROOT/} -> ${dest#$PROJECT_ROOT/}"
  else
    cp "$RENDER_TMP" "$dest"
    echo "[+] ${dest#$PROJECT_ROOT/}"
  fi
  ((synced+=1))
done < <(find "$STEPS_DIR" -maxdepth 1 -type f | sort)

pruned=0
if "$PRUNE"; then
  echo
  echo "--- Prune stale commands ---"
  while IFS= read -r dest; do
    [[ -z "$dest" ]] && continue
    name="$(basename "$dest" .md)"
    if ! is_step_mirror_name "$name"; then
      continue
    fi
    if is_forbidden_legacy_step_name "$name"; then
      if "$DRY_RUN"; then
        echo "[dry] prune forbidden legacy ${dest#$PROJECT_ROOT/}"
      else
        rm -f "$dest"
        echo "[-] ${dest#$PROJECT_ROOT/}"
      fi
      ((pruned+=1))
      continue
    fi
    if [[ -f "$STEPS_DIR/$name" || -f "$STEPS_DIR/$name.md" ]]; then
      continue
    fi
    if "$DRY_RUN"; then
      echo "[dry] prune ${dest#$PROJECT_ROOT/}"
    else
      rm -f "$dest"
      echo "[-] ${dest#$PROJECT_ROOT/}"
    fi
    ((pruned+=1))
  done < <(find "$COMMANDS_TARGET" -maxdepth 1 -type f -name '*.md' | sort)
fi

echo
echo "=== Summary ==="
echo "Synced: $synced"
echo "Pruned: $pruned"
echo "Skipped: $skipped"
