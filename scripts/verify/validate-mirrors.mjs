#!/usr/bin/env node
// validate-mirrors.mjs — skill mirror corruption check + cross-mirror drift detector.
//
// Checks:
//   1. CORRUPTION: any mirrored SKILL.md containing tool-runtime dump signatures
//      (ResultMessage(, ToolUseBlock(, TextBlock(, raw [{'type':) → hard-fail exit 1.
//      This catches the bug where a tool-call dump was written into a skill file.
//
//   2. DRIFT: for each canonical src/skills/<name>/SKILL.md, compare the mirrored
//      copies in .claude/skills, .codex/skills, .factory/skills, .agents/skills.
//      Reports DRIFT (sha256 differs) and VERSION drift (frontmatter version: disagrees).
//      Under --strict, DRIFT exits 1.
//
// RULE: check "every canonical skill is faithfully mirrored" (superset-safe).
// Do NOT flag extra skills that exist in mirrors but not in src/ — the global pool
// is a superset of src/ by design.
//
// Absent mirror surfaces (e.g. .codex/skills doesn't exist) are skipped gracefully.
//
// CLI:
//   node scripts/verify/validate-mirrors.mjs                   # non-strict, report only
//   node scripts/verify/validate-mirrors.mjs --strict          # drift → exit 1
//   node scripts/verify/validate-mirrors.mjs --json            # machine output
//   node scripts/verify/validate-mirrors.mjs --root <dir>      # override repo root (for tests)
//
// Env: none needed; use --root for hermetic tests.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ── Arg parsing ──────────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2);
let STRICT = false;
let JSON_MODE = false;
let REPO_ROOT = path.resolve(__dirname, '..', '..');

for (let i = 0; i < rawArgs.length; i++) {
  const a = rawArgs[i];
  if (a === '--strict') {
    STRICT = true;
  } else if (a === '--json') {
    JSON_MODE = true;
  } else if (a === '--root') {
    const next = rawArgs[i + 1];
    if (!next || next.startsWith('--')) {
      console.error('validate-mirrors: --root requires a path argument');
      process.exit(1);
    }
    REPO_ROOT = path.resolve(next);
    i++;
  } else {
    console.error(`validate-mirrors: unknown argument '${a}'`);
    process.exit(1);
  }
}

// ── Mirror surfaces to check against canonical src/skills ────────────────────

const MIRROR_SURFACES = [
  '.claude/skills',
  '.codex/skills',
  '.factory/skills',
  '.agents/skills',
];

// ── Tool-runtime dump signatures (corruption indicators) ─────────────────────
// These patterns appear when a tool-call response was accidentally written into
// a skill file. Any SKILL.md containing these is corrupted.

const CORRUPTION_SIGNATURES = [
  'ResultMessage(',
  'ToolUseBlock(',
  'TextBlock(',
  "[{'type':",
];

// ── Helpers ──────────────────────────────────────────────────────────────────

function sha256(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

function readFile(p) {
  try {
    return fs.readFileSync(p, 'utf8');
  } catch {
    return null;
  }
}

function extractVersion(content) {
  if (!content) return null;
  // Match YAML frontmatter version: field
  const m = content.match(/^---\r?\n[\s\S]*?^version:\s*["']?([^\n"']+?)["']?\s*$/m);
  return m ? m[1].trim() : null;
}

function listSkillDirs(skillsDir) {
  if (!fs.existsSync(skillsDir)) return [];
  const entries = fs.readdirSync(skillsDir, { withFileTypes: true });
  return entries
    .filter(e => e.isDirectory())
    .map(e => e.name)
    .sort();
}

function walkForSkillMds(dir) {
  // Recursively find all SKILL.md files under a surface directory
  if (!fs.existsSync(dir)) return [];
  const results = [];
  function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) {
        walk(p);
      } else if (e.name === 'SKILL.md') {
        results.push(p);
      }
    }
  }
  walk(dir);
  return results;
}

// ── Accumulators ─────────────────────────────────────────────────────────────

const corruptionFindings = [];  // { file, signatures }
const driftFindings = [];       // { skill, surface, type, srcVersion, mirrorVersion }
const missingFindings = [];     // { skill, surface }

// ── Step 1: Corruption scan across ALL mirror surfaces ───────────────────────

for (const surface of MIRROR_SURFACES) {
  const surfaceDir = path.join(REPO_ROOT, surface);
  if (!fs.existsSync(surfaceDir)) continue;

  const skillMds = walkForSkillMds(surfaceDir);
  for (const filePath of skillMds) {
    const content = readFile(filePath);
    if (!content) continue;

    const found = CORRUPTION_SIGNATURES.filter(sig => content.includes(sig));
    if (found.length > 0) {
      corruptionFindings.push({
        file: path.relative(REPO_ROOT, filePath),
        signatures: found,
      });
    }
  }
}

// ── Step 2: Cross-mirror drift for canonical src/ skills ─────────────────────

const SRC_SKILLS_DIR = path.join(REPO_ROOT, 'src', 'skills');
const canonicalSkills = listSkillDirs(SRC_SKILLS_DIR);

for (const skillName of canonicalSkills) {
  const canonicalPath = path.join(SRC_SKILLS_DIR, skillName, 'SKILL.md');
  const canonicalContent = readFile(canonicalPath);
  if (!canonicalContent) continue;  // no SKILL.md — validate-skills.mjs catches this

  const canonicalHash = sha256(canonicalContent);
  const canonicalVersion = extractVersion(canonicalContent);

  for (const surface of MIRROR_SURFACES) {
    const surfaceDir = path.join(REPO_ROOT, surface);
    if (!fs.existsSync(surfaceDir)) continue;  // surface absent — skip gracefully

    // Mirror may live at <surface>/<skillName>/SKILL.md directly
    const mirrorPath = path.join(surfaceDir, skillName, 'SKILL.md');
    if (!fs.existsSync(mirrorPath)) {
      missingFindings.push({
        skill: skillName,
        surface,
        canonicalVersion,
      });
      continue;
    }

    const mirrorContent = readFile(mirrorPath);
    if (!mirrorContent) continue;

    const mirrorHash = sha256(mirrorContent);
    const mirrorVersion = extractVersion(mirrorContent);

    if (mirrorHash !== canonicalHash) {
      driftFindings.push({
        skill: skillName,
        surface,
        type: 'CONTENT_DRIFT',
        canonicalVersion,
        mirrorVersion,
        detail: 'SHA256 mismatch — mirror SKILL.md differs from canonical src/skills/',
      });
    } else if (canonicalVersion !== mirrorVersion) {
      // Same content but different version field — shouldn't happen if sha matches, but check anyway
      driftFindings.push({
        skill: skillName,
        surface,
        type: 'VERSION_DRIFT',
        canonicalVersion,
        mirrorVersion,
        detail: 'Content matches but frontmatter version: differs',
      });
    }
  }
}

// ── Build result ──────────────────────────────────────────────────────────────

const ok = corruptionFindings.length === 0 &&
  (STRICT ? driftFindings.length === 0 : true);

const result = {
  ok,
  canonical_skills_checked: canonicalSkills.length,
  mirror_surfaces_checked: MIRROR_SURFACES.filter(s => fs.existsSync(path.join(REPO_ROOT, s))).length,
  corruption: {
    count: corruptionFindings.length,
    findings: corruptionFindings,
  },
  drift: {
    count: driftFindings.length,
    findings: driftFindings,
  },
  missing: {
    count: missingFindings.length,
    findings: missingFindings,
    note: 'Missing = canonical skill has no corresponding mirror in that surface. Not a hard fail (superset rule). Re-mirror to resolve.',
  },
};

// ── Output ────────────────────────────────────────────────────────────────────

if (JSON_MODE) {
  process.stdout.write(JSON.stringify(result, null, 2) + '\n');
} else {
  if (corruptionFindings.length > 0) {
    console.error(`FAIL: ${corruptionFindings.length} CORRUPTION finding(s):`);
    for (const f of corruptionFindings) {
      console.error(`  CORRUPT: ${f.file} — signatures: ${f.signatures.join(', ')}`);
    }
    console.error('');
  }

  if (driftFindings.length > 0) {
    const label = STRICT ? 'FAIL' : 'WARN';
    console.log(`${label}: ${driftFindings.length} DRIFT finding(s):`);
    for (const f of driftFindings) {
      console.log(`  ${f.type}: ${f.skill} in ${f.surface} (src version=${f.canonicalVersion ?? 'none'}, mirror version=${f.mirrorVersion ?? 'none'})`);
      console.log(`    ${f.detail}`);
    }
    console.log('');
  }

  if (missingFindings.length > 0) {
    console.log(`INFO: ${missingFindings.length} canonical skill(s) have no mirror in some surface(s):`);
    for (const f of missingFindings) {
      console.log(`  MISSING: ${f.skill} in ${f.surface}`);
    }
    console.log('');
  }

  if (ok) {
    if (corruptionFindings.length === 0 && driftFindings.length === 0 && missingFindings.length === 0) {
      console.log(`OK: ${canonicalSkills.length} canonical skills — no corruption, no drift.`);
    } else if (corruptionFindings.length === 0) {
      console.log(`OK (non-strict): no corruption. ${driftFindings.length} drift finding(s) + ${missingFindings.length} missing mirror(s) — run with --strict to fail on drift.`);
    }
  } else {
    console.error(`FAIL: validate-mirrors found ${corruptionFindings.length} corruption + ${driftFindings.length} drift finding(s).`);
  }
}

process.exit(ok ? 0 : 1);
