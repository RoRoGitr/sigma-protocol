#!/usr/bin/env bash
# autoresearch.sh - daily self-improvement loop for the AI Brain.
#
# Pattern: compile session notes -> score the vault -> close research gaps ->
# propose/apply reversible skill updates -> log the trend.
#
# Usage:
#   scripts/autoresearch.sh
#   scripts/autoresearch.sh --dry-run
#
# Optional feature flags:
#   BRAIN_GAPCLOSE=1                  Process open inbox/RESEARCH-*.md items.
#   BRAIN_GAPCLOSE_RESEARCH_CMD=cmd   Command that receives question, terms, snippet.
#   BRAIN_EVOLVE_AUTO_APPLY=0         Generate proposals but do not apply them.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"
CONFIG_FILE="$ROOT_DIR/.brain-config.yaml"
VAULT_PATH="${BRAIN_VAULT_PATH:-${BRAIN_VAULT_DIR:-$HOME/Documents/AI Brain}}"
SCORE_FILE="$SCRIPTS_DIR/vault-quality-score.json"
LOG_FILE="$SCRIPTS_DIR/autoresearch.log"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

resolve_vault_path() {
  if [[ -f "$CONFIG_FILE" ]]; then
    local configured
    configured="$(python3 - "$CONFIG_FILE" "$HOME" <<'PY' 2>/dev/null || true
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
home = sys.argv[2]
value = ""
try:
    import yaml  # type: ignore
    data = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    value = str(data.get("vault_path") or "")
except Exception:
    for line in config_path.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith("vault_path:"):
            value = line.split(":", 1)[1].strip().strip("\"'")
            break
if value.startswith("~/"):
    value = home + value[1:]
print(value)
PY
)"
    [[ -n "$configured" ]] && VAULT_PATH="$configured"
  fi
}

run_python() {
  local script="$1"
  shift
  if command -v uv >/dev/null 2>&1; then
    uv run --directory "$ROOT_DIR" python "$script" "$@"
  else
    python3 "$script" "$@"
  fi
}

json_quote() {
  python3 - "$1" <<'PY'
import json
import sys
print(json.dumps(sys.argv[1]))
PY
}

slugify() {
  python3 - "$1" <<'PY'
import re
import sys
slug = re.sub(r"[^a-z0-9]+", "-", sys.argv[1].lower()).strip("-")
print((slug or "research-gap")[:60].strip("-") or "research-gap")
PY
}

gapclose_enabled() {
  [[ "${BRAIN_GAPCLOSE:-}" == "1" ]]
}

gapclose_list_open() {
  local cap="$1"
  python3 - "$VAULT_PATH" "$cap" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

vault = Path(sys.argv[1])
cap = int(sys.argv[2])
inbox = vault / "inbox"

def clean(value: str) -> str:
    return re.sub(r"[\t\r\n]+", " ", value or "").strip()

def decode(value: str) -> str:
    raw = value.strip()
    if not raw:
        return ""
    try:
        return str(json.loads(raw))
    except json.JSONDecodeError:
        return raw.strip("\"'")

def item_blocks(lines: list[str]) -> list[list[str]]:
    blocks: list[list[str]] = []
    current: list[str] = []
    for line in lines:
        if line.startswith("- "):
            if current:
                blocks.append(current)
            current = [line]
        elif current:
            current.append(line)
    if current:
        blocks.append(current)
    return blocks

def parse_block(block: list[str]) -> dict[str, object]:
    fields: dict[str, object] = {"suggested_terms": []}
    in_terms = False
    terms: list[str] = []
    for line in block:
        key_match = re.match(r"\s*(?:-\s*)?([A-Za-z_]+):\s*(.*)$", line)
        if key_match:
            key, raw = key_match.group(1), key_match.group(2)
            in_terms = key == "suggested_terms"
            if key == "suggested_terms":
                continue
            fields[key] = decode(raw)
            continue
        term_match = re.match(r"\s+-\s*(.+?)\s*$", line)
        if in_terms and term_match:
            terms.append(decode(term_match.group(1)))
    fields["suggested_terms"] = terms
    return fields

if not inbox.exists():
    raise SystemExit(0)

emitted = 0
for path in sorted(inbox.glob("RESEARCH-*.md")):
    blocks = item_blocks(path.read_text(encoding="utf-8").splitlines())
    for block in blocks:
        item = parse_block(block)
        if str(item.get("status", "")).lower() != "open":
            continue
        question = str(item.get("question", "")).strip()
        if not question:
            continue
        terms = ", ".join(str(term) for term in item.get("suggested_terms", []))
        print("\t".join(clean(part) for part in [
            str(path),
            question,
            str(item.get("context_snippet", "")),
            terms,
            str(item.get("session", "")),
            str(item.get("created", "")),
        ]))
        emitted += 1
        if emitted >= cap:
            raise SystemExit(0)
PY
}

gapclose_mark_closed() {
  local inbox_file="$1"
  local question="$2"
  local research_path="$3"
  local closed_at
  closed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  python3 - "$inbox_file" "$question" "$research_path" "$closed_at" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
target_question = sys.argv[2]
research_path = sys.argv[3]
closed_at = sys.argv[4]

def decode(value: str) -> str:
    raw = value.strip()
    try:
        return str(json.loads(raw))
    except json.JSONDecodeError:
        return raw.strip("\"'")

def normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip()).casefold().strip("\"'")

def split_doc(lines: list[str]) -> tuple[list[str], list[list[str]]]:
    prefix: list[str] = []
    blocks: list[list[str]] = []
    current: list[str] = []
    for line in lines:
        if line.startswith("- "):
            if current:
                blocks.append(current)
            current = [line]
        elif current:
            current.append(line)
        elif not blocks:
            prefix.append(line)
    if current:
        blocks.append(current)
    return prefix, blocks

def block_field(block: list[str], key: str) -> str:
    for line in block:
        match = re.match(rf"\s*(?:-\s*)?{re.escape(key)}:\s*(.*)$", line)
        if match:
            return decode(match.group(1))
    return ""

text = path.read_text(encoding="utf-8")
prefix, blocks = split_doc(text.splitlines())
changed = False
target = normalize(target_question)
new_blocks: list[list[str]] = []

for block in blocks:
    status = block_field(block, "status").lower()
    question = normalize(block_field(block, "question"))
    if status == "open" and question == target and not changed:
        status_index = next((i for i, line in enumerate(block) if re.match(r"\s*(?:-\s*)?status:\s*open\s*$", line)), None)
        if status_index is not None:
            block[status_index] = re.sub(r"open\s*$", "closed", block[status_index])
            if not block_field(block, "closed"):
                block.insert(status_index + 1, f"  closed: {json.dumps(closed_at)}")
            if not block_field(block, "research"):
                block.insert(status_index + 2, f"  research: {json.dumps(research_path)}")
            changed = True
    new_blocks.append(block)

if changed:
    output_lines: list[str] = []
    output_lines.extend(prefix)
    for block in new_blocks:
        output_lines.extend(block)
    path.write_text("\n".join(output_lines).rstrip() + "\n", encoding="utf-8")
PY
}

spawn_guard_allows() {
  local name="$1"
  local guard="${BRAIN_SPAWN_GUARD:-$HOME/.local/bin/agent-spawn-guard}"
  local min_battery="${BRAIN_SPAWN_MIN_BATTERY:-15}"
  if [[ ! -x "$guard" ]]; then
    return 0
  fi
  "$guard" --name "$name" --min-battery "$min_battery" --quiet
}

gapclose_run_item() {
  local inbox_file="$1"
  local question="$2"
  local snippet="$3"
  local terms="$4"
  local session="$5"
  local created="$6"

  if ! spawn_guard_allows "brain-gapclose"; then
    log "Spawn guard skipped brain-gapclose"
    return 1
  fi

  mkdir -p "$VAULT_PATH/research"
  local slug research_path tmp_path findings_path
  slug="$(slugify "$question")"
  research_path="$VAULT_PATH/research/$(date -u +%Y-%m-%d)-$slug.md"
  local n=2
  while [[ -e "$research_path" ]]; do
    research_path="$VAULT_PATH/research/$(date -u +%Y-%m-%d)-$slug-$n.md"
    n=$((n + 1))
  done
  tmp_path="${research_path}.tmp"
  findings_path="${research_path}.findings.tmp"

  if [[ -n "${BRAIN_GAPCLOSE_RESEARCH_CMD:-}" ]]; then
    if ! "$BRAIN_GAPCLOSE_RESEARCH_CMD" "$question" "$terms" "$snippet" > "$findings_path" 2>&1; then
      log "WARN: gap-close research command failed for: $question"
      rm -f "$findings_path" "$tmp_path"
      return 1
    fi
  elif command -v claude >/dev/null 2>&1; then
    local prompt
    prompt="Run one bounded research pass for this AI Brain gap. Return concise findings with sources when available. Do not write files. Do not spawn follow-up agents."
    if ! timeout "${BRAIN_GAPCLOSE_TIMEOUT_SECONDS:-600}" claude -p --bare --append-system-prompt "$prompt" \
      "Question: $question
Context: $snippet
Suggested terms: $terms" > "$findings_path" 2>&1; then
      log "WARN: Claude gap-close research failed for: $question"
      rm -f "$findings_path" "$tmp_path"
      return 1
    fi
  else
    log "WARN: no research command or claude CLI available for gap-close"
    return 1
  fi

  {
    echo "---"
    echo "type: research"
    echo "source: brain-gapclose"
    echo "status: complete"
    echo "question: $(json_quote "$question")"
    echo "session: $(json_quote "$session")"
    echo "created_from_gap: $(json_quote "$created")"
    echo "inbox: $(json_quote "$inbox_file")"
    echo "---"
    echo
    echo "# Gap-Close Research: $question"
    echo
    echo "## Context"
    echo "$snippet"
    echo
    echo "## Suggested Terms"
    echo "$terms"
    echo
    echo "## Findings"
    cat "$findings_path"
  } > "$tmp_path"

  mv "$tmp_path" "$research_path"
  rm -f "$findings_path"
  gapclose_mark_closed "$inbox_file" "$question" "$research_path"
  log "gap-close wrote $research_path"
}

gapclose_router() {
  gapclose_enabled || return 0
  local cap="${BRAIN_GAPCLOSE_CAP:-5}"
  if [[ ! "$cap" =~ ^[0-9]+$ || "$cap" -lt 1 ]]; then
    cap=5
  fi

  local processed=0
  local inbox_file question snippet terms session created
  while IFS=$'\t' read -r inbox_file question snippet terms session created; do
    [[ -n "${inbox_file:-}" ]] || continue
    [[ "$processed" -ge "$cap" ]] && break
    if gapclose_run_item "$inbox_file" "$question" "$snippet" "$terms" "$session" "$created"; then
      processed=$((processed + 1))
    fi
  done < <(gapclose_list_open "$cap")

  log "gap-close processed $processed item(s)"
}

resolve_vault_path
mkdir -p "$VAULT_PATH/research" "$VAULT_PATH/inbox"
LEARNINGS_FILE="$VAULT_PATH/research/compilation-learnings.md"
BUILD_LOG="$VAULT_PATH/build-log.md"

log "=== autoresearch cycle start ==="

prev_score="none"
if [[ -f "$SCORE_FILE" ]]; then
  prev_score="$(python3 - "$SCORE_FILE" <<'PY' 2>/dev/null || echo "none"
import json
import sys
data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
print(data.get("current", data).get("score", "none"))
PY
)"
fi
log "Previous score: $prev_score"

if $DRY_RUN; then
  log "[DRY RUN] Would run gap-close if enabled, compile, score, evolve, and log trend."
  log "  vault: $VAULT_PATH"
  log "  compile: $SCRIPTS_DIR/compile.py"
  log "  score:   $SCRIPTS_DIR/lint.py --score"
  log "  evolve:  $SCRIPTS_DIR/evolve.py --apply"
  exit 0
fi

gapclose_router

log "Compiling new sessions..."
if ! spawn_guard_allows "brain-compile"; then
  compile_output="(skipped by spawn guard)"
else
  compile_output="$(run_python "$SCRIPTS_DIR/compile.py" 2>&1 || true)"
fi
log "Compile output: $(echo "$compile_output" | tail -3 | tr '\n' ' ')"

log "Scoring vault..."
score_json="$(run_python "$SCRIPTS_DIR/lint.py" --score 2>&1)" || {
  log "ERROR: lint.py --score failed: $score_json"
  exit 1
}
log "Score JSON: $score_json"

if [[ "${BRAIN_EVOLVE_AUTO_APPLY:-1}" == "1" ]]; then
  log "Detecting and applying reversible evolution proposals..."
  evolve_output="$(run_python "$SCRIPTS_DIR/evolve.py" --apply 2>&1 | tail -8 || true)"
else
  log "Detecting evolution proposals without apply..."
  evolve_output="$(run_python "$SCRIPTS_DIR/evolve.py" 2>&1 | tail -8 || true)"
fi
log "Evolution: $evolve_output"

new_score="$(printf '%s' "$score_json" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("score", "error"))' 2>/dev/null || echo "error")"
if [[ "$new_score" == "error" ]]; then
  log "ERROR: Could not parse score from lint output"
  exit 1
fi

trend="$(python3 - "$prev_score" "$new_score" <<'PY'
import sys
try:
    prev = None if sys.argv[1] == "none" else float(sys.argv[1])
    new = float(sys.argv[2])
except ValueError:
    print("unknown")
    raise SystemExit(0)
if prev is None:
    print("baseline (first run)")
else:
    delta = round(new - prev, 1)
    if delta > 0:
        print(f"improved (+{delta})")
    elif delta < 0:
        print(f"degraded ({delta})")
    else:
        print("unchanged (0.0)")
PY
)"
log "New score: $new_score | Trend: $trend"

{
  echo
  echo "## [$(date -u +%Y-%m-%dT%H:%M:%SZ)] autoresearch | automated"
  echo "- Previous score: $prev_score"
  echo "- New score: $new_score"
  echo "- Trend: $trend"
  echo "- Compile output summary: $(echo "$compile_output" | tail -3 | tr '\n' ' ')"
} >> "$LEARNINGS_FILE"

echo "## [$(date -u +%Y-%m-%dT%H:%M:%SZ)] autoresearch | score: $new_score ($trend)" >> "$BUILD_LOG"

log "=== autoresearch cycle complete: $new_score ($trend) ==="
