#!/usr/bin/env node
// security-gate.mjs — diff-scoped, deterministic security acceptance gate.
//
// Operates on CHANGED files only (not the whole repo). Runs three deterministic
// checks and emits advisory findings by default. Hard-blocks only under --enforce
// (or SECURITY_GATE_ENFORCE=1) for verified secrets or new High/Critical CVEs.
//
// Checks:
//   1. SECRET SCAN  — built-in regex for common secret shapes; gitleaks if on PATH.
//      HIGH-confidence match = block (enforce mode). LOW = advisory.
//   2. DEPENDENCY AUDIT — npm audit / osv-scanner / pip-audit on changed manifests.
//      tool-missing = LOGGED canary + check recorded as `skipped`, never `passed`.
//   3. NEW-ROUTE-WITHOUT-AUTH — grep changed server files for route handlers lacking
//      an adjacent auth reference. Heuristic; always advisory.
//
// Baseline: .sigma/security/baseline.json stores accepted fingerprints.
//   --update-baseline  writes current findings as the new baseline.
//
// CLI:
//   node scripts/verify/security-gate.mjs [options]
//
//   --staged              use `git diff --staged --name-only` (pre-commit)
//   --base <ref>          use `git diff <ref> --name-only`
//   --files <f1,f2,...>   explicit file list (bypasses git; for tests/CI)
//   --json                machine output { findings, newFindings, blocked, advisory }
//   --enforce             new verified-secret / new-High/Critical-CVE → exit 1
//   --update-baseline     write current findings to baseline and exit 0
//   --baseline <path>     override baseline path (default: .sigma/security/baseline.json)
//
// Env:
//   SECURITY_GATE_ENFORCE=1   same effect as --enforce
//   SIGMA_REPO_ROOT=<path>    override repo root (for hermetic tests)
//
// Fail-open guarantee:
//   Any internal exception → logged to stderr + exit 0 (never trap a commit on a gate bug).
//   Tool-missing → logged canary + check recorded as `skipped`, not `passed`.

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = process.env.SIGMA_REPO_ROOT
  || path.resolve(__dirname, '..', '..');

// ── Argument parsing ────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2);

let staged = false;
let baseRef = null;
let explicitFiles = null;  // string[] when --files provided
let jsonMode = false;
let enforce = process.env.SECURITY_GATE_ENFORCE === '1';
let updateBaseline = false;
let baselinePath = path.join(REPO_ROOT, '.sigma', 'security', 'baseline.json');

for (let i = 0; i < rawArgs.length; i++) {
  const a = rawArgs[i];
  if (a === '--staged') {
    staged = true;
  } else if (a === '--base') {
    const next = rawArgs[i + 1];
    if (!next || next.startsWith('--')) {
      console.error('security-gate: --base requires a ref argument');
      process.exit(1);
    }
    baseRef = next;
    i++;
  } else if (a === '--files') {
    const next = rawArgs[i + 1];
    if (!next || next.startsWith('--')) {
      console.error('security-gate: --files requires a comma-separated file list');
      process.exit(1);
    }
    explicitFiles = next.split(',').map(f => f.trim()).filter(Boolean);
    i++;
  } else if (a === '--json') {
    jsonMode = true;
  } else if (a === '--enforce') {
    enforce = true;
  } else if (a === '--update-baseline') {
    updateBaseline = true;
  } else if (a === '--baseline') {
    const next = rawArgs[i + 1];
    if (!next || next.startsWith('--')) {
      console.error('security-gate: --baseline requires a path argument');
      process.exit(1);
    }
    baselinePath = path.resolve(next);
    i++;
  } else {
    console.error(`security-gate: unknown argument '${a}'`);
    process.exit(1);
  }
}

// ── Types ────────────────────────────────────────────────────────────────────
//
// Finding: { type, severity, file, line, confidence, fingerprint, detail }
//   type:        'secret' | 'dependency' | 'unauth-route' | 'skipped-check'
//   severity:    'HIGH' | 'MEDIUM' | 'LOW' | 'INFO'
//   confidence:  'HIGH' | 'LOW'
//   fingerprint: sha256 of (type+file+detail) — used for baseline suppression
//   detail:      human-readable description

// ── Secret patterns ───────────────────────────────────────────────────────────
//
// HIGH-confidence (verified secret shape) → block under enforce.
// LOW-confidence (generic key=value shape) → advisory only.

const HIGH_CONFIDENCE_PATTERNS = [
  // AWS access key
  { re: /AKIA[0-9A-Z]{16}/, label: 'AWS access key (AKIA prefix)' },
  // OpenAI secret key
  { re: /sk-[A-Za-z0-9]{20,}/, label: 'OpenAI/generic sk- secret key' },
  // GitHub tokens (classic + fine-grained)
  { re: /gh[oprst]_[A-Za-z0-9]{30,}/, label: 'GitHub token (ghp/gho/ghr/ghs/grt prefix)' },
  // PEM private key
  { re: /-----BEGIN .{0,40}PRIVATE KEY-----/, label: 'PEM private key block' },
];

const LOW_CONFIDENCE_PATTERNS = [
  // Generic api_key / secret / token = "value" (≥20 chars)
  { re: /(api[_-]?key|secret|token)\s*[=:]\s*["'][A-Za-z0-9_\-]{20,}["']/i, label: 'Generic key/secret/token assignment' },
];

// ── Path filter ───────────────────────────────────────────────────────────────
//
// Docs-only changes should not fail on secret/auth checks — the patterns are
// meaningless in prose. We skip secret + unauth-route checks for these extensions.

const DOCS_EXTENSIONS = new Set(['.md', '.mdx', '.txt', '.rst', '.adoc', '.pdf']);
const MANIFEST_NAMES = new Set(['package.json', 'package-lock.json', 'requirements.txt', 'pyproject.toml']);

// Server file patterns — files that may define route handlers
const SERVER_EXTENSIONS = new Set(['.js', '.mjs', '.cjs', '.ts', '.mts', '.py', '.rb', '.go']);

function isDocsFile(filePath) {
  return DOCS_EXTENSIONS.has(path.extname(filePath).toLowerCase());
}

function isManifest(filePath) {
  return MANIFEST_NAMES.has(path.basename(filePath));
}

function isServerFile(filePath) {
  return SERVER_EXTENSIONS.has(path.extname(filePath).toLowerCase());
}

// ── Fingerprint ───────────────────────────────────────────────────────────────

function fingerprint(type, file, detail) {
  const raw = `${type}|${file}|${detail}`;
  return crypto.createHash('sha256').update(raw).digest('hex').slice(0, 16);
}

// ── Baseline I/O ──────────────────────────────────────────────────────────────

function loadBaseline(p) {
  if (!fs.existsSync(p)) return new Set();
  try {
    const obj = JSON.parse(fs.readFileSync(p, 'utf8'));
    if (Array.isArray(obj.accepted)) {
      return new Set(obj.accepted);
    }
    return new Set();
  } catch {
    return new Set();
  }
}

function writeBaseline(p, findings) {
  const dir = path.dirname(p);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  const accepted = findings.map(f => f.fingerprint);
  fs.writeFileSync(p, JSON.stringify({ accepted, updated_at: new Date().toISOString() }, null, 2) + '\n', 'utf8');
}

// ── Tool detection ────────────────────────────────────────────────────────────
//
// Uses /usr/bin/which (hardcoded allowlist path, no shell string) — same
// pattern as fusion.mjs tool-on-PATH detection.

function isOnPath(tool) {
  try {
    execFileSync('/usr/bin/which', [tool], { stdio: ['ignore', 'pipe', 'ignore'] });
    return true;
  } catch {
    return false;
  }
}

// ── Changed-file resolution ───────────────────────────────────────────────────
//
// execFileSync with argv array — never a shell string. injection-safe.

function resolveChangedFiles() {
  if (explicitFiles !== null) {
    return explicitFiles;
  }

  let args;
  if (staged) {
    args = ['diff', '--staged', '--name-only', '--diff-filter=ACMR'];
  } else if (baseRef) {
    args = ['diff', baseRef, '--name-only', '--diff-filter=ACMR'];
  } else {
    // Default: unstaged working-tree changes vs HEAD
    args = ['diff', 'HEAD', '--name-only', '--diff-filter=ACMR'];
  }

  try {
    const out = execFileSync('git', args, {
      cwd: REPO_ROOT,
      stdio: ['ignore', 'pipe', 'pipe'],
    }).toString('utf8');
    return out.split('\n').map(l => l.trim()).filter(Boolean);
  } catch {
    // If git fails (e.g. no commits yet), return empty — gate exits cleanly
    return [];
  }
}

// ── Check 1: Secret scan ──────────────────────────────────────────────────────

function scanFileForSecrets(relPath, findings) {
  const absPath = path.join(REPO_ROOT, relPath);
  if (!fs.existsSync(absPath)) return;

  let content;
  try {
    content = fs.readFileSync(absPath, 'utf8');
  } catch {
    return;
  }

  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    for (const { re, label } of HIGH_CONFIDENCE_PATTERNS) {
      if (re.test(line)) {
        const detail = `${label} — line ${lineNum}`;
        findings.push({
          type: 'secret',
          severity: 'HIGH',
          file: relPath,
          line: lineNum,
          confidence: 'HIGH',
          fingerprint: fingerprint('secret', relPath, detail),
          detail,
        });
        break;  // one high-confidence hit per line is enough
      }
    }

    for (const { re, label } of LOW_CONFIDENCE_PATTERNS) {
      if (re.test(line)) {
        const detail = `${label} — line ${lineNum}`;
        findings.push({
          type: 'secret',
          severity: 'MEDIUM',
          file: relPath,
          line: lineNum,
          confidence: 'LOW',
          fingerprint: fingerprint('secret', relPath, detail),
          detail,
        });
        break;
      }
    }
  }
}

function runSecretCheck(changedFiles, findings, canaries) {
  // Filter: skip pure-docs files for secret scanning
  const targetFiles = changedFiles.filter(f => !isDocsFile(f));

  if (targetFiles.length === 0) return;

  // gitleaks: run only in --staged mode (protect --staged is fast and scoped).
  // We do NOT run `gitleaks detect --source <REPO_ROOT>` because that scans the
  // entire working tree recursively — it will hang on large repos. The built-in
  // regex scan covers the changed-file set authoritatively for all modes.
  if (isOnPath('gitleaks') && staged) {
    try {
      execFileSync('gitleaks', ['protect', '--staged', '--exit-code', '1'], {
        cwd: REPO_ROOT,
        stdio: ['ignore', 'pipe', 'pipe'],
        timeout: 30_000,
      });
      // exit 0 = gitleaks found nothing staged
    } catch {
      // exit non-zero = gitleaks found something staged; built-in scan adds detail
    }
  } else if (!isOnPath('gitleaks')) {
    canaries.push('gitleaks not on PATH — using built-in regex secret scan (reduced coverage)');
  }
  // When gitleaks IS on PATH but not in --staged mode, the built-in scan below
  // covers the diff. No canary needed — coverage is adequate.

  // Built-in regex scan always runs (authoritative for per-file/line detail)
  for (const f of targetFiles) {
    scanFileForSecrets(f, findings);
  }
}

// ── Check 2: Dependency audit ─────────────────────────────────────────────────

function runDependencyAudit(changedFiles, findings, canaries, skipped) {
  const changedManifests = changedFiles.filter(isManifest);
  if (changedManifests.length === 0) return;

  const hasNodeManifests = changedManifests.some(
    f => f === 'package.json' || f === 'package-lock.json'
  );
  const hasPythonManifests = changedManifests.some(
    f => f === 'requirements.txt' || f === 'pyproject.toml'
  );

  // Node manifests — prefer npm audit, then osv-scanner
  if (hasNodeManifests) {
    if (isOnPath('npm')) {
      try {
        const out = execFileSync('npm', ['audit', '--json', '--audit-level=high'], {
          cwd: REPO_ROOT,
          stdio: ['ignore', 'pipe', 'pipe'],
          timeout: 60_000,
        }).toString('utf8');

        try {
          const report = JSON.parse(out);
          const vulns = report.vulnerabilities || {};
          for (const [name, v] of Object.entries(vulns)) {
            const sev = (v.severity || '').toUpperCase();
            if (sev === 'HIGH' || sev === 'CRITICAL') {
              const detail = `npm vulnerability: ${name} severity=${v.severity} via=${(v.via || []).map(x => (typeof x === 'string' ? x : x.name)).join(', ')}`;
              findings.push({
                type: 'dependency',
                severity: sev,
                file: 'package.json',
                line: null,
                confidence: 'HIGH',
                fingerprint: fingerprint('dependency', 'package.json', detail),
                detail,
              });
            }
          }
        } catch {
          // npm audit output may be non-JSON on older versions — log canary
          canaries.push('npm audit output could not be parsed as JSON — dependency check incomplete');
        }
      } catch (e) {
        // npm audit exits non-zero when vulnerabilities found — output still has findings
        const stdout = e.stdout ? e.stdout.toString('utf8') : '';
        if (stdout) {
          try {
            const report = JSON.parse(stdout);
            const vulns = report.vulnerabilities || {};
            for (const [name, v] of Object.entries(vulns)) {
              const sev = (v.severity || '').toUpperCase();
              if (sev === 'HIGH' || sev === 'CRITICAL') {
                const detail = `npm vulnerability: ${name} severity=${v.severity} via=${(v.via || []).map(x => (typeof x === 'string' ? x : x.name)).join(', ')}`;
                findings.push({
                  type: 'dependency',
                  severity: sev,
                  file: 'package.json',
                  line: null,
                  confidence: 'HIGH',
                  fingerprint: fingerprint('dependency', 'package.json', detail),
                  detail,
                });
              }
            }
          } catch {
            canaries.push('npm audit output could not be parsed as JSON — dependency check incomplete');
          }
        }
      }
    } else if (isOnPath('osv-scanner')) {
      try {
        execFileSync('osv-scanner', ['--json', path.join(REPO_ROOT, 'package.json')], {
          cwd: REPO_ROOT,
          stdio: ['ignore', 'pipe', 'pipe'],
          timeout: 60_000,
        });
      } catch (e) {
        const stdout = e.stdout ? e.stdout.toString('utf8') : '';
        canaries.push(`osv-scanner ran on package.json (exit ${e.status}) — manual review of output required: ${stdout.slice(0, 200)}`);
      }
    } else {
      canaries.push('npm and osv-scanner not on PATH — Node dependency audit skipped');
      skipped.push('dependency-audit-node');
    }
  }

  // Python manifests — pip-audit
  if (hasPythonManifests) {
    if (isOnPath('pip-audit')) {
      try {
        execFileSync('pip-audit', ['--format', 'json', '--output', '/dev/stdout'], {
          cwd: REPO_ROOT,
          stdio: ['ignore', 'pipe', 'pipe'],
          timeout: 60_000,
        });
      } catch (e) {
        const stdout = e.stdout ? e.stdout.toString('utf8') : '';
        if (stdout) {
          try {
            const report = JSON.parse(stdout);
            const deps = report.dependencies || [];
            for (const dep of deps) {
              for (const vuln of (dep.vulns || [])) {
                const detail = `pip-audit: ${dep.name}@${dep.version} — ${vuln.id} (${vuln.description || 'no description'})`;
                findings.push({
                  type: 'dependency',
                  severity: 'HIGH',
                  file: 'requirements.txt',
                  line: null,
                  confidence: 'HIGH',
                  fingerprint: fingerprint('dependency', 'requirements.txt', detail),
                  detail,
                });
              }
            }
          } catch {
            canaries.push('pip-audit output could not be parsed — dependency check incomplete');
          }
        }
      }
    } else {
      canaries.push('pip-audit not on PATH — Python dependency audit skipped');
      skipped.push('dependency-audit-python');
    }
  }
}

// ── Check 3: New route without auth ──────────────────────────────────────────
//
// Heuristic: in changed server files, look for route/handler definitions that
// lack an adjacent auth reference within ±5 lines.

const ROUTE_PATTERNS = [
  /app\.(get|post|put|delete|patch|head|options)\s*\(/i,
  /router\.(get|post|put|delete|patch|head|options)\s*\(/i,
  /@app\.route\s*\(/,
  /export\s+(default\s+)?async\s+function\s+(GET|POST|PUT|DELETE|PATCH)\s*\(/,
  // Next.js route handler exports
  /export\s+(const|async\s+function)\s+(GET|POST|PUT|DELETE|PATCH)\s*[=(]/,
];

const AUTH_PATTERNS = [
  /withAuth/i,
  /requireAuth/i,
  /getServerSession/i,
  /verifyJWT/i,
  /authenticate/i,
  /isAuthenticated/i,
  /checkAuth/i,
  /ensureAuth/i,
  /jwtVerify/i,
  /bearerAuth/i,
  /apiKeyAuth/i,
  /sessionAuth/i,
  /authMiddleware/i,
  /protect\b/,
  /guard\b/i,
  /useAuth\b/i,
];

function scanFileForUnauthRoutes(relPath, findings) {
  const absPath = path.join(REPO_ROOT, relPath);
  if (!fs.existsSync(absPath)) return;

  let content;
  try {
    content = fs.readFileSync(absPath, 'utf8');
  } catch {
    return;
  }

  const lines = content.split('\n');
  const WINDOW = 5;  // lines to look ahead/behind for auth reference

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const hasRoute = ROUTE_PATTERNS.some(re => re.test(line));
    if (!hasRoute) continue;

    // Check surrounding window for auth reference
    const start = Math.max(0, i - WINDOW);
    const end = Math.min(lines.length - 1, i + WINDOW);
    const window = lines.slice(start, end + 1).join('\n');
    const hasAuth = AUTH_PATTERNS.some(re => re.test(window));

    if (!hasAuth) {
      const lineNum = i + 1;
      const detail = `Route handler at line ${lineNum} has no adjacent auth reference within ±${WINDOW} lines`;
      findings.push({
        type: 'unauth-route',
        severity: 'MEDIUM',
        file: relPath,
        line: lineNum,
        confidence: 'LOW',
        fingerprint: fingerprint('unauth-route', relPath, detail),
        detail,
      });
    }
  }
}

function runRouteAuthCheck(changedFiles, findings) {
  // Only check server-side files, skip docs
  const targetFiles = changedFiles.filter(f => isServerFile(f) && !isDocsFile(f));
  for (const f of targetFiles) {
    scanFileForUnauthRoutes(f, findings);
  }
}

// ── Main logic ────────────────────────────────────────────────────────────────

function main() {
  // Load baseline fingerprints
  const baselineSet = loadBaseline(baselinePath);

  // Resolve changed files
  let changedFiles;
  try {
    changedFiles = resolveChangedFiles();
  } catch (e) {
    console.error(`security-gate: failed to resolve changed files — ${e.message}`);
    // Fail-open
    if (jsonMode) {
      process.stdout.write(JSON.stringify({
        findings: [],
        newFindings: [],
        blocked: false,
        advisory: [],
        canaries: [`resolveChangedFiles failed: ${e.message}`],
        skipped: [],
        error: e.message,
      }, null, 2) + '\n');
    }
    process.exit(0);
  }

  // Detect docs-only diff — skip secret/auth checks but still do dep audit
  const nonDocsFiles = changedFiles.filter(f => !isDocsFile(f));
  const docsOnly = changedFiles.length > 0 && nonDocsFiles.length === 0;

  const allFindings = [];
  const canaries = [];
  const skipped = [];

  // Check 1: Secret scan (skip for docs-only diffs)
  if (!docsOnly) {
    try {
      runSecretCheck(changedFiles, allFindings, canaries);
    } catch (e) {
      canaries.push(`secret-scan internal error: ${e.message}`);
    }
  } else {
    canaries.push('docs-only diff — secret scan and route-auth check skipped');
  }

  // Check 2: Dependency audit (always run — manifest changes are never docs-only)
  try {
    runDependencyAudit(changedFiles, allFindings, canaries, skipped);
  } catch (e) {
    canaries.push(`dependency-audit internal error: ${e.message}`);
  }

  // Check 3: Unauth route check (skip for docs-only diffs)
  if (!docsOnly) {
    try {
      runRouteAuthCheck(changedFiles, allFindings);
    } catch (e) {
      canaries.push(`route-auth-check internal error: ${e.message}`);
    }
  }

  // Separate into new (not in baseline) vs suppressed
  const newFindings = allFindings.filter(f => !baselineSet.has(f.fingerprint));
  const suppressedFindings = allFindings.filter(f => baselineSet.has(f.fingerprint));

  // --update-baseline: write all current findings as accepted, exit 0
  if (updateBaseline) {
    writeBaseline(baselinePath, allFindings);
    if (!jsonMode) {
      console.log(`security-gate: baseline updated at ${baselinePath}`);
      console.log(`  accepted ${allFindings.length} finding fingerprint(s)`);
    } else {
      process.stdout.write(JSON.stringify({
        findings: allFindings,
        newFindings: [],
        blocked: false,
        advisory: allFindings,
        canaries,
        skipped,
        baselineUpdated: true,
      }, null, 2) + '\n');
    }
    process.exit(0);
  }

  // Classify new findings into block vs advisory
  const blockingFindings = [];
  const advisoryFindings = [];

  for (const f of newFindings) {
    const isBlockable = (
      (f.type === 'secret' && f.confidence === 'HIGH') ||
      (f.type === 'dependency' && (f.severity === 'HIGH' || f.severity === 'CRITICAL'))
    );
    if (isBlockable) {
      blockingFindings.push(f);
    } else {
      advisoryFindings.push(f);
    }
  }

  const blocked = enforce && blockingFindings.length > 0;

  // Emit telemetry breadcrumb (optional — never throws)
  try {
    const telemetryDir = path.join(REPO_ROOT, '.sigma', 'telemetry', 'sessions');
    if (fs.existsSync(path.dirname(telemetryDir))) {
      if (!fs.existsSync(telemetryDir)) fs.mkdirSync(telemetryDir, { recursive: true });
      const record = {
        event: 'gate_fired',
        gate: 'security_acceptance',
        ts: new Date().toISOString(),
        status: blocked ? 'failed' : (newFindings.length > 0 ? 'advisory' : 'passed'),
        new_findings: newFindings.length,
        blocked,
        enforce,
      };
      const sessionId = process.env.SIGMA_SESSION_ID || 'security-gate-standalone';
      fs.appendFileSync(
        path.join(telemetryDir, `${sessionId}.jsonl`),
        JSON.stringify(record) + '\n',
        'utf8'
      );
    }
  } catch {
    // Telemetry must never break a gate
  }

  // ── Output ─────────────────────────────────────────────────────────────────

  if (jsonMode) {
    process.stdout.write(JSON.stringify({
      findings: allFindings,
      newFindings,
      blocked,
      advisory: advisoryFindings,
      blocking: blockingFindings,
      suppressed: suppressedFindings.length,
      canaries,
      skipped,
      changedFiles,
      docsOnly,
      enforce,
    }, null, 2) + '\n');
  } else {
    if (canaries.length > 0) {
      for (const c of canaries) {
        console.log(`[security-gate] CANARY: ${c}`);
      }
    }
    if (skipped.length > 0) {
      for (const s of skipped) {
        console.log(`[security-gate] SKIPPED: ${s}`);
      }
    }

    if (changedFiles.length === 0) {
      console.log('[security-gate] no changed files — nothing to scan');
    } else if (docsOnly) {
      console.log(`[security-gate] docs-only diff (${changedFiles.length} file(s)) — secret/auth checks skipped`);
    } else {
      console.log(`[security-gate] scanning ${changedFiles.length} changed file(s)…`);
    }

    if (suppressedFindings.length > 0) {
      console.log(`[security-gate] ${suppressedFindings.length} finding(s) suppressed by baseline`);
    }

    if (newFindings.length === 0) {
      console.log('[security-gate] OK — no new findings');
    } else {
      const label = blocked ? 'BLOCK' : 'ADVISORY';
      console.log(`[security-gate] ${label}: ${newFindings.length} new finding(s):`);
      for (const f of newFindings) {
        const loc = f.line ? `:${f.line}` : '';
        const blockFlag = (enforce && (f.type === 'secret' && f.confidence === 'HIGH') ||
                           (f.type === 'dependency' && (f.severity === 'HIGH' || f.severity === 'CRITICAL')))
          ? ' [BLOCKING]' : ' [advisory]';
        console.log(`  [${f.type}] ${f.severity}/${f.confidence} ${f.file}${loc}${blockFlag}`);
        console.log(`    ${f.detail}`);
        console.log(`    fingerprint: ${f.fingerprint}`);
      }
      if (!enforce && blockingFindings.length > 0) {
        console.log(`[security-gate] ${blockingFindings.length} finding(s) would block under --enforce`);
      }
      console.log('[security-gate] run with --update-baseline to suppress known findings');
    }

    if (blocked) {
      console.error('[security-gate] BLOCKED: verified secret or High/Critical CVE found (--enforce mode)');
    }
  }

  process.exit(blocked ? 1 : 0);
}

// ── Fail-open wrapper ─────────────────────────────────────────────────────────
//
// Any uncaught exception → log + exit 0 (never trap a commit on a gate bug).

try {
  main();
} catch (err) {
  console.error(`[security-gate] internal error — ${err.message}`);
  if (jsonMode) {
    process.stdout.write(JSON.stringify({
      findings: [],
      newFindings: [],
      blocked: false,
      advisory: [],
      canaries: [`internal error: ${err.message}`],
      skipped: [],
      error: err.message,
    }, null, 2) + '\n');
  }
  process.exit(0);
}
