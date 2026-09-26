#!/bin/bash
# sync-from-community.sh — compare or pull bundled pipeline scripts against upstream.
# Upstream lives in cross-model-agents (the historical home of these gates).
# See SYNC-FROM-COMMUNITY.md for the full lineage and when-to-sync rules.

set -e

# Upstream path is fixed for now. If you relocate cross-model-agents, edit this
# constant or expose it as an env override. Keeping it hardcoded keeps the
# install one-shot and reproducible.
UPSTREAM_DIR="${PIPELINE_UPSTREAM_DIR:-}"  # maintainer-only: set to your upstream pipeline checkout

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_DIR="$SCRIPT_DIR"

MODE=""
BACKUP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --pull) MODE="pull"; shift ;;
    --backup) BACKUP=1; shift ;;
    -h|--help)
      cat <<'EOF'
Usage: sync-from-community.sh --check
       sync-from-community.sh --pull --backup

  --check         Print a drift table comparing local files to upstream. Read-only.
  --pull          Overwrite local bundled files with upstream copies.
  --backup        Required with --pull. Saves pre-pull state to .backup-<ts>/.
EOF
      exit 0
      ;;
    *)
      echo "ERROR: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "ERROR: pass --check or --pull (see --help)" >&2
  exit 2
fi

if [[ ! -d "$UPSTREAM_DIR" ]]; then
  echo "ERROR: upstream pipeline dir not found: $UPSTREAM_DIR" >&2
  echo "       Set PIPELINE_UPSTREAM_DIR or clone cross-model-agents first." >&2
  exit 3
fi

# Pick a sha256 binary. macOS ships shasum; Linux usually has sha256sum.
sha_cmd() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Collect the union of *.sh in both dirs, deduped and sorted.
list_files() {
  {
    find "$LOCAL_DIR" -maxdepth 1 -type f -name '*.sh' -exec basename {} \;
    find "$UPSTREAM_DIR" -maxdepth 1 -type f -name '*.sh' -exec basename {} \;
  } | sort -u
}

if [[ "$MODE" == "check" ]]; then
  printf "%-32s %s\n" "FILE" "STATUS"
  printf "%-32s %s\n" "----" "------"
  while read -r f; do
    local_path="$LOCAL_DIR/$f"
    up_path="$UPSTREAM_DIR/$f"
    if [[ -f "$local_path" && -f "$up_path" ]]; then
      ls_sha=$(sha_cmd "$local_path")
      up_sha=$(sha_cmd "$up_path")
      if [[ "$ls_sha" == "$up_sha" ]]; then
        printf "%-32s =  same\n" "$f"
      else
        printf "%-32s !  drifted\n" "$f"
      fi
    elif [[ -f "$up_path" ]]; then
      printf "%-32s +  upstream only (not bundled)\n" "$f"
    else
      printf "%-32s -  local only (no upstream)\n" "$f"
    fi
  done < <(list_files)
  exit 0
fi

if [[ "$MODE" == "pull" ]]; then
  if [[ "$BACKUP" -ne 1 ]]; then
    echo "ERROR: --pull requires --backup. Refusing to overwrite without a backup." >&2
    exit 4
  fi

  ts=$(date +%Y%m%d-%H%M%S)
  backup_dir="$LOCAL_DIR/.backup-$ts"
  mkdir -p "$backup_dir"
  # Copy every local *.sh into the backup, preserving mode + mtime.
  find "$LOCAL_DIR" -maxdepth 1 -type f -name '*.sh' -exec cp -p {} "$backup_dir/" \;
  echo "Backup written to: $backup_dir"

  # Overwrite local with upstream for any file present upstream.
  pulled=0
  while read -r f; do
    up_path="$UPSTREAM_DIR/$f"
    if [[ -f "$up_path" ]]; then
      cp -p "$up_path" "$LOCAL_DIR/$f"
      pulled=$((pulled + 1))
    fi
  done < <(find "$UPSTREAM_DIR" -maxdepth 1 -type f -name '*.sh' -exec basename {} \;)
  echo "Pulled $pulled file(s) from upstream."
  echo "Run --check to confirm drift is resolved."
  exit 0
fi
