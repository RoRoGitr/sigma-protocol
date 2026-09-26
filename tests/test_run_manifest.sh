#!/usr/bin/env bash
# Hermetic tests for scripts/verify/run-manifest.mjs
#
# All I/O is redirected via SIGMA_MANIFEST_DIR + SIGMA_JUDGE_DIR into a temp
# dir. No dependency on the real .sigma/ state.
#
# Tests:
#   (a) --step with existing step file  → manifest has step name + non-null sha
#   (b) --artifact                      → manifest has artifact sha
#   (c) --gate with fixture judge JSON  → manifest captures panel/synthesizer ids
#   (d) missing step file + no gate     → fields null, exit 0 (fail-open)
#   (e) --json shape                    → step/artifact/judge/code/env keys all present
#   (f) git commit captured or null     → no crash, field is string|null

set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/verify/run-manifest.mjs"
W="$(mktemp -d)"
PASS=0; FAIL=0
trap 'rm -rf "$W"' EXIT

ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

# ── Helpers ──────────────────────────────────────────────────────────────────

# Read a dotted key path from a JSON file.
# jpath FILE KEY  (e.g. jpath manifest.json step.sha256)
jpath() {
  local file="$1" key="$2"
  node -e '
    const fs = require("fs");
    const obj = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const parts = process.argv[2].split(".");
    let cur = obj;
    for (const p of parts) {
      if (cur == null) { process.stdout.write("null"); process.exit(0); }
      cur = cur[p];
    }
    if (cur === null || cur === undefined) process.stdout.write("null");
    else process.stdout.write(String(cur));
  ' "$file" "$key"
}

# Return the first manifest JSON file written into a given SIGMA_MANIFEST_DIR.
first_manifest() {
  local dir="$1"
  local f
  f="$(ls "$dir"/*.json 2>/dev/null | head -1)"
  echo "$f"
}

# ── (a) --step with an existing step file ────────────────────────────────────
echo "== (a) existing step file → non-null step sha =="
{
  MD="$W/a/manifests"; JD="$W/a/judge"
  mkdir -p "$MD" "$JD"
  export SIGMA_MANIFEST_DIR="$MD"
  export SIGMA_JUDGE_DIR="$JD"
  export SIGMA_SESSION_ID="test-run-a"

  # step-1-ideation exists in the real repo steps/ dir
  node "$SCRIPT" --step step-1-ideation >/dev/null 2>&1
  rc=$?
  mf="$(first_manifest "$MD")"
  if [ "$rc" -ne 0 ]; then
    bad "(a) exit code $rc (expected 0)"
  elif [ -z "$mf" ]; then
    bad "(a) no manifest file written"
  else
    name="$(jpath "$mf" step.name)"
    sha="$(jpath "$mf" step.sha256)"
    if [ "$name" = "step-1-ideation" ] && [ "$sha" != "null" ] && [ -n "$sha" ]; then
      ok "(a) step name=step-1-ideation sha=${sha:0:12}…"
    else
      bad "(a) name='$name' sha='$sha'"
    fi
  fi
}

# ── (b) --artifact ───────────────────────────────────────────────────────────
echo "== (b) --artifact → artifact sha captured =="
{
  MD="$W/b/manifests"; JD="$W/b/judge"
  mkdir -p "$MD" "$JD"
  ART="$W/b/sample.md"
  printf "# Hello\nThis is a test artifact.\n" > "$ART"
  export SIGMA_MANIFEST_DIR="$MD"
  export SIGMA_JUDGE_DIR="$JD"
  export SIGMA_SESSION_ID="test-run-b"

  node "$SCRIPT" --step step-2-architecture --artifact "$ART" >/dev/null 2>&1
  rc=$?
  mf="$(first_manifest "$MD")"
  if [ "$rc" -ne 0 ]; then
    bad "(b) exit code $rc"
  elif [ -z "$mf" ]; then
    bad "(b) no manifest file written"
  else
    sha="$(jpath "$mf" artifact.sha256)"
    rel="$(jpath "$mf" artifact.relative)"
    if [ "$sha" != "null" ] && [ -n "$sha" ]; then
      ok "(b) artifact sha=${sha:0:12}… rel=$rel"
    else
      bad "(b) artifact.sha256='$sha'"
    fi
  fi
}

# ── (c) --gate with fixture judge JSON ───────────────────────────────────────
echo "== (c) --gate reads panel/synthesizer from judge fixture =="
{
  MD="$W/c/manifests"; JD="$W/c/judge"
  mkdir -p "$MD" "$JD"
  export SIGMA_MANIFEST_DIR="$MD"
  export SIGMA_JUDGE_DIR="$JD"
  export SIGMA_SESSION_ID="test-run-c"

  # Write a fixture judge JSON matching the real .sigma/judge/<gate>.json shape
  cat > "$JD/mygate.json" <<'EOF'
{
  "gate": "mygate",
  "status": "PASS",
  "advisory": false,
  "blocking": true,
  "crossFamily": true,
  "families": ["anthropic", "openai"],
  "calibrated": true,
  "injection_attempt_detected": false,
  "advisory_reason": "",
  "panel": [
    {"id": "claude", "family": "anthropic"},
    {"id": "codex",  "family": "openai"}
  ],
  "synthesizer": {"id": "claude", "family": "anthropic"},
  "criteria": [],
  "artifact": "docs/test.md"
}
EOF

  node "$SCRIPT" --step step-8-technical-spec --gate mygate >/dev/null 2>&1
  rc=$?
  mf="$(first_manifest "$MD")"
  if [ "$rc" -ne 0 ]; then
    bad "(c) exit code $rc"
  elif [ -z "$mf" ]; then
    bad "(c) no manifest file written"
  else
    gate_field="$(jpath "$mf" judge.gate)"
    synth_id="$(jpath "$mf" judge.synthesizer.id)"
    # panel is an array; check the manifest JSON contains the panel member ids
    panel_ok=false
    if node -e '
      const fs = require("fs");
      const m = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      const p = m.judge && m.judge.panel;
      if (!Array.isArray(p) || p.length < 2) process.exit(1);
      const ids = p.map(v => v.id);
      if (ids.includes("claude") && ids.includes("codex")) process.exit(0);
      process.exit(1);
    ' "$mf" 2>/dev/null; then
      panel_ok=true
    fi

    if [ "$gate_field" = "mygate" ] && [ "$synth_id" = "claude" ] && [ "$panel_ok" = "true" ]; then
      ok "(c) judge.gate=mygate synthesizer.id=claude panel=[claude,codex]"
    else
      bad "(c) gate='$gate_field' synth='$synth_id' panel_ok=$panel_ok"
    fi
  fi
}

# ── (d) missing inputs → fields null, exit 0 (fail-open) ────────────────────
echo "== (d) missing step file + no gate → null fields, exit 0 =="
{
  MD="$W/d/manifests"; JD="$W/d/judge"
  mkdir -p "$MD" "$JD"
  export SIGMA_MANIFEST_DIR="$MD"
  export SIGMA_JUDGE_DIR="$JD"
  export SIGMA_SESSION_ID="test-run-d"

  # step name that does not exist in steps/
  node "$SCRIPT" --step step-does-not-exist >/dev/null 2>&1
  rc=$?
  mf="$(first_manifest "$MD")"
  if [ "$rc" -ne 0 ]; then
    bad "(d) exit code $rc (expected 0 — fail-open)"
  elif [ -z "$mf" ]; then
    bad "(d) no manifest file written"
  else
    sha="$(jpath "$mf" step.sha256)"
    judge_field="$(jpath "$mf" judge)"
    if [ "$sha" = "null" ] && [ "$judge_field" = "null" ]; then
      ok "(d) step.sha256=null judge=null exit=0 (fail-open)"
    else
      bad "(d) step.sha256='$sha' judge='$judge_field' (expected null)"
    fi
  fi
}

# ── (e) --json shape valid ───────────────────────────────────────────────────
echo "== (e) --json emits object with all top-level keys =="
{
  MD="$W/e/manifests"; JD="$W/e/judge"
  mkdir -p "$MD" "$JD"
  ART="$W/e/art.txt"; echo "content" > "$ART"
  export SIGMA_MANIFEST_DIR="$MD"
  export SIGMA_JUDGE_DIR="$JD"
  export SIGMA_SESSION_ID="test-run-e"

  json_out="$(node "$SCRIPT" --step step-1-ideation --artifact "$ART" --json 2>/dev/null)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    bad "(e) exit code $rc"
  else
    keys_ok=false
    if echo "$json_out" | node -e '
      const chunks = [];
      process.stdin.on("data", d => chunks.push(d));
      process.stdin.on("end", () => {
        const m = JSON.parse(chunks.join(""));
        const required = ["run_id","step","artifact","judge","code","env"];
        const missing = required.filter(k => !(k in m));
        if (missing.length > 0) { console.error("missing: "+missing.join(",")); process.exit(1); }
        process.exit(0);
      });
    ' 2>/dev/null; then
      keys_ok=true
    fi

    if [ "$keys_ok" = "true" ]; then
      ok "(e) --json has run_id/step/artifact/judge/code/env keys"
    else
      bad "(e) missing top-level keys in: $(echo "$json_out" | head -3)"
    fi
  fi
}

# ── (f) git commit captured or null — no crash ───────────────────────────────
echo "== (f) git commit is string or null, never crashes =="
{
  MD="$W/f/manifests"; JD="$W/f/judge"
  mkdir -p "$MD" "$JD"
  export SIGMA_MANIFEST_DIR="$MD"
  export SIGMA_JUDGE_DIR="$JD"
  export SIGMA_SESSION_ID="test-run-f"

  node "$SCRIPT" --step step-1-ideation --json >/dev/null 2>&1
  rc=$?
  mf="$(first_manifest "$MD")"
  if [ "$rc" -ne 0 ]; then
    bad "(f) exit code $rc (expected 0)"
  elif [ -z "$mf" ]; then
    bad "(f) no manifest file written"
  else
    commit="$(jpath "$mf" code.git_commit)"
    # acceptable: a 40-char hex string OR the literal "null"
    if echo "$commit" | grep -qE '^[0-9a-f]{40}$'; then
      ok "(f) git_commit captured: ${commit:0:10}…"
    elif [ "$commit" = "null" ]; then
      ok "(f) git_commit=null (not a git repo — fail-open)"
    else
      bad "(f) unexpected git_commit value: '$commit'"
    fi
  fi
}

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All tests passed." || exit 1
