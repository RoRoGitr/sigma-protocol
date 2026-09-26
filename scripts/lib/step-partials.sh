#!/usr/bin/env bash
# Shared recursive expansion for steps/_partials includes.

_step_partials_stack=()

_expand_step_partials_file() {
  local src="$1"
  local out="$2"
  local steps_dir="$3"
  local line partial active include_path

  for active in "${_step_partials_stack[@]-}"; do
    if [[ "$active" == "$src" ]]; then
      echo "ERROR: partial include cycle: ${_step_partials_stack[*]} -> $src" >&2
      return 1
    fi
  done
  _step_partials_stack+=("$src")

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*\<!--[[:space:]]*include:[[:space:]]*(_partials/[A-Za-z0-9._/-]+)[[:space:]]*--\>[[:space:]]*$ ]]; then
      include_path="${BASH_REMATCH[1]}"
      if [[ "/$include_path/" == *"/./"* || "/$include_path/" == *"/../"* || "$include_path" == *"//"* ]]; then
        echo "ERROR: invalid partial path $include_path (referenced by $src)" >&2
        return 1
      fi
      partial="$steps_dir/$include_path"
      if [[ ! -f "$partial" ]]; then
        echo "ERROR: missing partial $partial (referenced by $src)" >&2
        return 1
      fi
      _expand_step_partials_file "$partial" "$out" "$steps_dir" || return 1
    else
      printf '%s\n' "$line" >> "$out"
    fi
  done < "$src"

  unset '_step_partials_stack[${#_step_partials_stack[@]}-1]'
}

expand_step_partials() {
  local src="$1"
  local out="$2"
  local steps_dir="$3"

  : > "$out"
  _step_partials_stack=()
  _expand_step_partials_file "$src" "$out" "$steps_dir"
}
