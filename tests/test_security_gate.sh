#!/usr/bin/env bash
# test_security_gate.sh — hermetic test suite for scripts/verify/security-gate.mjs
#
# Six test cases, all hermetic — operate in a temp git repo via --files override
# and SIGMA_REPO_ROOT env so the real repo's diff is never used.
#
#   (a) planted fake secret → flagged (advisory by default, blocking under --enforce)
#   (b) clean diff → pass (exit 0, zero findings)
#   (c) baseline suppresses a known finding
#   (d) tool-missing path → skipped recorded + logged, NOT silent pass
#   (e) docs-only diff → secret/auth checks skipped, no failure
#   (f) --json shape valid (required keys present, types correct)
#
# Fake secrets are built from parts at runtime — no literal secret lands in this
# file so gitleaks will not flag the test itself.
#
# Usage: bash tests/test_security_gate.sh
# Exit:  0 = all passed, 1 = one or more failed

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$REPO_ROOT/scripts/verify/security-gate.mjs"

PASS=0
FAIL=0

# ── Assertion helpers ─────────────────────────────────────────────────────────

pass() {
  echo "  PASS: $1"
  PASS=$(( PASS + 1 ))
}

fail() {
  echo "  FAIL: $1" >&2
  FAIL=$(( FAIL + 1 ))
}

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label (exit $actual)"
  else
    fail "$label — expected exit $expected, got $actual"
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    pass "$label (contains '$needle')"
  else
    fail "$label — output does not contain '$needle'"$'\n'"  Output was:"$'\n'"$haystack"
  fi
}

assert_not_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    fail "$label — output should NOT contain '$needle'"$'\n'"  Output was:"$'\n'"$haystack"
  else
    pass "$label (does not contain '$needle')"
  fi
}

# ── Node guard ────────────────────────────────────────────────────────────────

if ! command -v node &>/dev/null; then
  echo "FAIL: node not on PATH — install Node.js 20+" >&2
  exit 1
fi

echo ""
echo "security-gate test suite"
echo "========================"

# ── Temp workspace ────────────────────────────────────────────────────────────
#
# All tests share a single temp dir as the SIGMA_REPO_ROOT. Tests use --files
# to feed an explicit changed-file list, bypassing git entirely. The gate reads
# actual file contents from SIGMA_REPO_ROOT, so we write fixture files there.

TMPDIR_ROOT="$(mktemp -d /tmp/sg-test-XXXXXX)"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

# Make it look like a minimal repo so git-fallback paths don't blow up
git init -q "$TMPDIR_ROOT" 2>/dev/null || true

FAKE_ROOT="$TMPDIR_ROOT"

# ── Helper: build a fake secret string at runtime from parts ─────────────────
#
# We never write a literal high-confidence secret into this source file.
# The patterns in the gate are:
#   AWS:    AKIA[0-9A-Z]{16}
#   sk-:    sk-[A-Za-z0-9]{20,}
#   GitHub: gh[oprst]_[A-Za-z0-9]{30,}
#   PEM:    -----BEGIN .* PRIVATE KEY-----
#
# We build them from parts so this file stays gitleaks-safe.

make_aws_key() {
  # AKIA + 16 uppercase alphanum chars
  printf 'AKIA%s' 'ABCDEFGHIJ123456'
}

make_sk_key() {
  # sk- + 25 alphanum chars
  printf 'sk-%s' 'ABCDEFGHIJKLMNOPQRSTUVWXY'
}

make_gh_token() {
  # ghp_ + 36 alphanum chars
  printf 'ghp_%s' 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef1234'
}

# ── Test (a): planted secret → flagged ───────────────────────────────────────

echo ""
echo "Test (a): planted fake secret is flagged as a finding"

SECRET_FILE="$FAKE_ROOT/config.js"
AWS_KEY="$(make_aws_key)"
cat > "$SECRET_FILE" <<EOF
// config
const accessKey = "$AWS_KEY";
module.exports = { accessKey };
EOF

set +e
TA_OUT="$(SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "config.js" \
  2>&1)"
TA_EXIT=$?
set -e

# Default mode (no --enforce): advisory, exit 0
assert_exit "(a) advisory mode exits 0" 0 "$TA_EXIT"
assert_contains "(a) output mentions secret finding" "secret" "$TA_OUT"
assert_contains "(a) output mentions config.js" "config.js" "$TA_OUT"

# Enforce mode: should exit 1 because HIGH-confidence secret
set +e
TA_ENF_OUT="$(SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "config.js" \
  --enforce \
  2>&1)"
TA_ENF_EXIT=$?
set -e

assert_exit "(a) enforce mode exits 1 on verified secret" 1 "$TA_ENF_EXIT"
assert_contains "(a) enforce output mentions BLOCK" "BLOCK" "$TA_ENF_OUT"

# ── Test (b): clean diff → pass ───────────────────────────────────────────────

echo ""
echo "Test (b): clean diff (no secrets, no manifests, no routes) → exit 0, zero findings"

CLEAN_FILE="$FAKE_ROOT/src/utils.js"
mkdir -p "$FAKE_ROOT/src"
cat > "$CLEAN_FILE" <<'EOF'
// Pure utility — no secrets, no routes
function add(a, b) { return a + b; }
module.exports = { add };
EOF

set +e
TB_JSON="$(SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "src/utils.js" \
  --json \
  2>&1)"
TB_EXIT=$?
set -e

assert_exit "(b) clean diff exits 0" 0 "$TB_EXIT"

# Verify zero newFindings in JSON output
TB_NEW="$(node -e "
  const j = JSON.parse(process.argv[1]);
  process.stdout.write(String(j.newFindings.length));
" "$TB_JSON" 2>/dev/null || echo 'parse_error')"

if [ "$TB_NEW" = "0" ]; then
  pass "(b) clean diff has zero newFindings"
else
  fail "(b) clean diff should have zero newFindings — got: $TB_NEW"
fi

# ── Test (c): baseline suppresses known finding ───────────────────────────────

echo ""
echo "Test (c): baseline suppresses a known finding"

SECRET_FILE2="$FAKE_ROOT/legacy.js"
SK_KEY="$(make_sk_key)"
cat > "$SECRET_FILE2" <<EOF
// legacy secret (accepted)
const apiKey = "$SK_KEY";
EOF

BASELINE_DIR="$FAKE_ROOT/.sigma/security"
mkdir -p "$BASELINE_DIR"
BASELINE_FILE="$BASELINE_DIR/baseline.json"

# First run: collect the fingerprint
set +e
TC_FIRST_JSON="$(SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "legacy.js" \
  --json \
  --baseline "$BASELINE_FILE" \
  2>&1)"
TC_FIRST_EXIT=$?
set -e

# Update baseline from this run
SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "legacy.js" \
  --baseline "$BASELINE_FILE" \
  --update-baseline \
  >/dev/null 2>&1

if [ -f "$BASELINE_FILE" ]; then
  pass "(c) baseline file written"
else
  fail "(c) baseline file not created at $BASELINE_FILE"
fi

# Second run: same file + enforce — should exit 0 because finding is baselined
set +e
TC_OUT="$(SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "legacy.js" \
  --json \
  --baseline "$BASELINE_FILE" \
  --enforce \
  2>&1)"
TC_EXIT=$?
set -e

assert_exit "(c) baselined finding exits 0 even under --enforce" 0 "$TC_EXIT"

TC_NEW="$(node -e "
  const j = JSON.parse(process.argv[1]);
  process.stdout.write(String(j.newFindings.length));
" "$TC_OUT" 2>/dev/null || echo 'parse_error')"

if [ "$TC_NEW" = "0" ]; then
  pass "(c) baselined finding produces zero newFindings"
else
  fail "(c) baselined finding should produce zero newFindings — got: $TC_NEW"
fi

TC_SUPPRESSED="$(node -e "
  const j = JSON.parse(process.argv[1]);
  process.stdout.write(String(j.suppressed));
" "$TC_OUT" 2>/dev/null || echo 'parse_error')"

if [ "$TC_SUPPRESSED" != "0" ] && [ "$TC_SUPPRESSED" != "parse_error" ]; then
  pass "(c) suppressed count > 0 ($TC_SUPPRESSED)"
else
  fail "(c) suppressed count should be > 0 — got: $TC_SUPPRESSED"
fi

# ── Test (d): tool-missing → skipped recorded, not silent pass ───────────────
#
# We write a manifest so the dep-audit check triggers. To test the "tool-missing"
# canary path we restrict PATH so audit tools (npm, osv-scanner, pip-audit,
# gitleaks) are absent, but node itself remains resolvable.

echo ""
echo "Test (d): tool-missing path → skipped recorded + canary logged, not silent pass"

MANIFEST_FILE="$FAKE_ROOT/package.json"
cat > "$MANIFEST_FILE" <<'EOF'
{ "name": "test", "version": "1.0.0", "dependencies": {} }
EOF

# Build a restricted PATH: only the directory containing the node binary.
# This lets `node "$GATE"` execute while making npm/osv-scanner/pip-audit/gitleaks
# invisible to the gate's /usr/bin/which probe.
NODE_BIN_DIR="$(dirname "$(command -v node)")"
RESTRICTED_PATH="$NODE_BIN_DIR"

set +e
TD_OUT="$(SIGMA_REPO_ROOT="$FAKE_ROOT" PATH="$RESTRICTED_PATH" node "$GATE" \
  --files "package.json" \
  --json \
  2>&1)"
TD_EXIT=$?
set -e

# Gate must not error out (fail-open: exit 0)
assert_exit "(d) tool-missing exits 0 (fail-open)" 0 "$TD_EXIT"

# The JSON output must either record a skipped check or a canary — not silently pass
TD_HAS_SIGNAL="$(node -e "
  const j = JSON.parse(process.argv[1]);
  const hasSkipped = Array.isArray(j.skipped) && j.skipped.length > 0;
  const hasCanary  = Array.isArray(j.canaries) && j.canaries.length > 0;
  process.stdout.write(hasSkipped || hasCanary ? 'yes' : 'no');
" "$TD_OUT" 2>/dev/null || echo 'parse_error')"

if [ "$TD_HAS_SIGNAL" = "yes" ]; then
  pass "(d) skipped[] or canaries[] populated when tool missing"
else
  fail "(d) tool-missing must record skipped or canary — got: $TD_HAS_SIGNAL"
fi

# Verify blocked=false in JSON (tool-missing must never hard-block)
TD_BLOCKED="$(node -e "
  const j = JSON.parse(process.argv[1]);
  process.stdout.write(String(j.blocked));
" "$TD_OUT" 2>/dev/null || echo 'parse_error')"

if [ "$TD_BLOCKED" = "false" ]; then
  pass "(d) blocked=false when tool missing"
else
  fail "(d) blocked should be false when tool missing — got: $TD_BLOCKED"
fi

# ── Test (e): docs-only diff → no secret/auth failure ────────────────────────

echo ""
echo "Test (e): docs-only diff → secret/auth checks skipped, gate passes"

GH_TOKEN="$(make_gh_token)"
README_FILE="$FAKE_ROOT/docs/README.md"
mkdir -p "$FAKE_ROOT/docs"
# Even though we embed a token-shaped string in a .md file, the gate
# should skip secret scanning for docs-only diffs and exit 0
cat > "$README_FILE" <<EOF
# Docs

Example token for illustration: $GH_TOKEN

This is documentation only.
EOF

set +e
TE_JSON="$(SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "docs/README.md" \
  --json \
  --enforce \
  2>&1)"
TE_EXIT=$?
set -e

assert_exit "(e) docs-only diff exits 0 even under --enforce" 0 "$TE_EXIT"

TE_DOCS_ONLY="$(node -e "
  const j = JSON.parse(process.argv[1]);
  process.stdout.write(String(j.docsOnly));
" "$TE_JSON" 2>/dev/null || echo 'parse_error')"

if [ "$TE_DOCS_ONLY" = "true" ]; then
  pass "(e) docsOnly=true for .md-only diff"
else
  fail "(e) docsOnly should be true for .md-only diff — got: $TE_DOCS_ONLY"
fi

TE_BLOCKED="$(node -e "
  const j = JSON.parse(process.argv[1]);
  process.stdout.write(String(j.blocked));
" "$TE_JSON" 2>/dev/null || echo 'parse_error')"

if [ "$TE_BLOCKED" = "false" ]; then
  pass "(e) blocked=false for docs-only diff"
else
  fail "(e) blocked should be false for docs-only diff — got: $TE_BLOCKED"
fi

# ── Test (f): --json shape is valid ──────────────────────────────────────────

echo ""
echo "Test (f): --json output has required shape (findings, newFindings, blocked, advisory)"

AWS_KEY2="$(make_aws_key)"
SHAPE_FILE="$FAKE_ROOT/shape_test.js"
cat > "$SHAPE_FILE" <<EOF
const key = "$AWS_KEY2";
EOF

set +e
TF_JSON="$(SIGMA_REPO_ROOT="$FAKE_ROOT" node "$GATE" \
  --files "shape_test.js" \
  --json \
  2>&1)"
TF_EXIT=$?
set -e

# Validate required keys and types
TF_PARSE="$(node -e "
  const j = JSON.parse(process.argv[1]);
  const required = ['findings', 'newFindings', 'blocked', 'advisory', 'canaries', 'skipped'];
  const missing = required.filter(k => !(k in j));
  if (missing.length) { console.error('missing keys: ' + missing.join(', ')); process.exit(1); }
  if (!Array.isArray(j.findings))    { console.error('findings not array'); process.exit(1); }
  if (!Array.isArray(j.newFindings)) { console.error('newFindings not array'); process.exit(1); }
  if (!Array.isArray(j.advisory))    { console.error('advisory not array'); process.exit(1); }
  if (!Array.isArray(j.canaries))    { console.error('canaries not array'); process.exit(1); }
  if (!Array.isArray(j.skipped))     { console.error('skipped not array'); process.exit(1); }
  if (typeof j.blocked !== 'boolean') { console.error('blocked not boolean'); process.exit(1); }
  // Validate each finding has required fields
  for (const f of j.findings) {
    const fReq = ['type','severity','file','confidence','fingerprint','detail'];
    const fMiss = fReq.filter(k => !(k in f));
    if (fMiss.length) { console.error('finding missing fields: ' + fMiss.join(', ')); process.exit(1); }
  }
  console.log('shape ok — findings=' + j.findings.length + ' newFindings=' + j.newFindings.length + ' blocked=' + j.blocked);
" "$TF_JSON" 2>&1)"
TF_PARSE_EXIT=$?

if [ "$TF_PARSE_EXIT" -eq 0 ]; then
  pass "(f) --json shape valid ($TF_PARSE)"
else
  fail "(f) --json shape invalid: $TF_PARSE"
fi

# Verify no literal real secret appears in the test source file itself
# (this is a meta-check — ensures our runtime-built strings don't leak into source)
LITERAL_CHECK="$(grep -c 'AKIA[0-9A-Z]\{16\}' "$0" || true)"
if [ "$LITERAL_CHECK" -eq 0 ]; then
  pass "(f) no literal AWS key pattern in test source"
else
  fail "(f) literal AWS key pattern found in test source — gitleaks-unsafe"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "========================"
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
