#!/usr/bin/env node
/**
 * scripts/verify/ears-lint.mjs
 *
 * EARS (Easy Approach to Requirements Syntax) linter for acceptance criteria.
 *
 * Reads acceptance criteria from:
 *   - .sigma/backlogs/{name}/prd.json  (JSON backlog format)
 *   - docs/prds/**\/*.md               (Markdown PRDs, ## Acceptance Criteria sections)
 *   - any path supplied via --src <path>
 *
 * EARS forms recognized (5 canonical + BDD exemption):
 *   ubiquitous      : "The <system> shall <action>"
 *   event-driven    : "When <event>, the <system> shall <action>"
 *   state-driven    : "While <state>, the <system> shall <action>"
 *   optional-feature: "Where <feature is included>, the <system> shall <action>"
 *   unwanted-behavior: "If <trigger>, then the <system> shall <action>"
 *   bdd             : "Given ... When ... Then ..." (exempt — advisory counts as covered)
 *   non-ears        : prefix NON-EARS: or earsForm:"non-ears" (explicitly exempt)
 *
 * Exit codes:
 *   0 — all criteria conform or are exempt (advisory mode default)
 *   1 — non-conforming non-exempt criteria found AND (--strict or EARS_LINT_ENFORCE=1)
 *
 * Emits: .sigma/indexes/ears-coverage.json
 *
 * Zero external dependencies — Node 20 stdlib only.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { resolve, join, extname, relative } from 'node:path';
import { argv, env, exit } from 'node:process';

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

const args = argv.slice(2);
const strict = args.includes('--strict') || env.EARS_LINT_ENFORCE === '1';
const srcArg = (() => {
  const i = args.indexOf('--src');
  return i !== -1 ? args[i + 1] : null;
})();

const REPO_ROOT = (() => {
  // Walk up from this script's location to find repo root (has schemas/ directory).
  // Decode percent-encoded characters from import.meta.url (e.g., spaces → %20).
  const rawDir = new URL('.', import.meta.url).pathname;
  const dir = decodeURIComponent(rawDir);
  // script is at scripts/verify/ears-lint.mjs → repo root is two levels up
  return resolve(dir, '..', '..');
})();

// ---------------------------------------------------------------------------
// EARS pattern matchers
// ---------------------------------------------------------------------------

/**
 * Returns the EARS form classification for a given text line, or null if unrecognized.
 * Order matters: check more-specific patterns first.
 */
function classifyEarsForm(text) {
  const t = text.trim();

  // NON-EARS prefix exemption
  if (/^NON-EARS:/i.test(t)) return 'non-ears';

  // BDD: Given/When/Then (any combination)
  if (/^(?:Given|When|Then)\s/i.test(t) || /\bGiven\b.*\bWhen\b.*\bThen\b/i.test(t)) return 'bdd';

  // EARS: unwanted-behavior — "If ... then the <system> shall"
  if (/^If\s.+,?\s+then\s+the\s+.+\s+shall\s/i.test(t)) return 'unwanted-behavior';

  // EARS: optional-feature — "Where ... the <system> shall"
  if (/^Where\s.+,?\s+the\s+.+\s+shall\s/i.test(t)) return 'optional-feature';

  // EARS: event-driven — "When ... the <system> shall"
  if (/^When\s.+,?\s+the\s+.+\s+shall\s/i.test(t)) return 'event-driven';

  // EARS: state-driven — "While ... the <system> shall"
  if (/^While\s.+,?\s+the\s+.+\s+shall\s/i.test(t)) return 'state-driven';

  // EARS: ubiquitous — "The <system> shall"
  if (/^The\s+.+\s+shall\s/i.test(t)) return 'ubiquitous';

  return null; // non-conforming
}

function isConformingOrExempt(form) {
  return form !== null; // null = non-conforming; any recognized form = conforming or exempt
}

// ---------------------------------------------------------------------------
// JSON backlog reader
// ---------------------------------------------------------------------------

/**
 * Parse a prd.json backlog file and extract acceptance criteria.
 * Returns Array<{acId, prd, earsForm, text, testId, conforms, kind}>
 */
function readBacklogJson(filePath) {
  let raw;
  try {
    raw = JSON.parse(readFileSync(filePath, 'utf8'));
  } catch (e) {
    process.stderr.write(`[ears-lint] WARNING: could not parse ${filePath}: ${e.message}\n`);
    return [];
  }

  const results = [];
  const stories = raw.stories ?? raw.features ?? raw.tasks ?? [];

  for (const story of stories) {
    const storyId = story.id ?? story.storyId ?? '?';
    const criteria = story.acceptanceCriteria ?? story.acceptance_criteria ?? [];
    for (const ac of criteria) {
      const text = ac.description ?? ac.text ?? '';
      const acId = ac.acceptanceCriterionId ?? ac.id ?? `${storyId}/${results.length}`;
      const explicitForm = ac.earsForm ?? null;
      const testId = ac.testId ?? null;

      // Explicit non-ears exemption via schema field
      let form = explicitForm;
      if (!form) {
        form = classifyEarsForm(text);
      } else if (form === 'non-ears') {
        // already exempt
      }

      const conforms = isConformingOrExempt(form);
      results.push({
        acId,
        prd: relative(REPO_ROOT, filePath),
        earsForm: form,
        text,
        testId,
        conforms,
        kind: 'json',
      });
    }
  }

  return results;
}

// ---------------------------------------------------------------------------
// Markdown PRD reader
// ---------------------------------------------------------------------------

/**
 * Extract acceptance criteria lines from ## Acceptance Criteria sections in a markdown PRD.
 * Returns Array<{acId, prd, earsForm, text, testId, conforms, kind}>
 */
function readMarkdownPrd(filePath) {
  let content;
  try {
    content = readFileSync(filePath, 'utf8');
  } catch (e) {
    process.stderr.write(`[ears-lint] WARNING: could not read ${filePath}: ${e.message}\n`);
    return [];
  }

  const lines = content.split('\n');
  const results = [];
  let inSection = false;
  let counter = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Detect section heading: ## Acceptance Criteria (any case, with optional plural/colon)
    if (/^#{1,4}\s+Acceptance Criteri/i.test(line)) {
      inSection = true;
      continue;
    }

    // Exit section on next heading of same or higher level
    if (inSection && /^#{1,4}\s/.test(line)) {
      inSection = false;
      continue;
    }

    if (!inSection) continue;

    // Criterion lines: list items or numbered items with non-trivial content
    const bulletMatch = line.match(/^[\s]*[-*+]\s+(.+)$/);
    const numberedMatch = line.match(/^[\s]*\d+[.)]\s+(.+)$/);
    const rawText = bulletMatch?.[1] ?? numberedMatch?.[1] ?? null;

    if (!rawText) continue;
    const text = rawText.trim();
    if (text.length < 5) continue; // skip trivially short entries

    counter += 1;
    const form = classifyEarsForm(text);
    const conforms = isConformingOrExempt(form);
    results.push({
      acId: `md-${counter}`,
      prd: relative(REPO_ROOT, filePath),
      earsForm: form,
      text,
      testId: null,
      conforms,
      kind: 'markdown',
    });
  }

  return results;
}

// ---------------------------------------------------------------------------
// File discovery
// ---------------------------------------------------------------------------

/**
 * Recursively find files matching extension under a directory.
 */
function findFiles(dir, ext) {
  const out = [];
  if (!existsSync(dir)) return out;
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    const stat = statSync(full);
    if (stat.isDirectory()) {
      out.push(...findFiles(full, ext));
    } else if (extname(full) === ext) {
      out.push(full);
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  let allCriteria = [];

  if (srcArg) {
    const srcPath = resolve(REPO_ROOT, srcArg);
    if (!existsSync(srcPath)) {
      process.stderr.write(`[ears-lint] ERROR: --src path does not exist: ${srcPath}\n`);
      exit(1);
    }
    const stat = statSync(srcPath);
    if (stat.isDirectory()) {
      // Scan for both JSON and MD
      for (const f of findFiles(srcPath, '.json')) {
        allCriteria.push(...readBacklogJson(f));
      }
      for (const f of findFiles(srcPath, '.md')) {
        allCriteria.push(...readMarkdownPrd(f));
      }
    } else {
      const ext = extname(srcPath);
      if (ext === '.json') {
        allCriteria.push(...readBacklogJson(srcPath));
      } else if (ext === '.md') {
        allCriteria.push(...readMarkdownPrd(srcPath));
      } else {
        process.stderr.write(`[ears-lint] ERROR: --src must be a .json or .md file, got: ${srcPath}\n`);
        exit(1);
      }
    }
  } else {
    // Default: scan .sigma/backlogs/*/prd.json and docs/prds/**/*.md
    const backlogsDir = join(REPO_ROOT, '.sigma', 'backlogs');
    if (existsSync(backlogsDir)) {
      for (const f of findFiles(backlogsDir, '.json')) {
        if (f.endsWith('prd.json')) {
          allCriteria.push(...readBacklogJson(f));
        }
      }
    }

    const prdsDir = join(REPO_ROOT, 'docs', 'prds');
    if (existsSync(prdsDir)) {
      for (const f of findFiles(prdsDir, '.md')) {
        allCriteria.push(...readMarkdownPrd(f));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Classify and count
  // ---------------------------------------------------------------------------

  let total = 0;
  let ears = 0;
  let bdd = 0;
  let nonEars = 0;
  let nonConforming = 0;
  let withTestId = 0;

  const nonConformingItems = [];

  for (const c of allCriteria) {
    total++;
    if (c.testId) withTestId++;

    if (c.earsForm === 'non-ears') {
      nonEars++;
    } else if (c.earsForm === 'bdd') {
      bdd++;
    } else if (c.earsForm !== null) {
      ears++;
    } else {
      nonConforming++;
      nonConformingItems.push(c);
    }
  }

  // ---------------------------------------------------------------------------
  // Orphan detection
  // ---------------------------------------------------------------------------

  const criteriaWithoutTestId = allCriteria
    .filter(c => !c.testId)
    .map(c => c.acId);

  // We have no test registry here; testsWithoutCriterion would require a test source.
  // Return empty — callers with a test registry can join on the coverage data.
  const testsWithoutCriterion = [];

  // ---------------------------------------------------------------------------
  // Coverage JSON output
  // ---------------------------------------------------------------------------

  const coverageDir = join(REPO_ROOT, '.sigma', 'indexes');
  mkdirSync(coverageDir, { recursive: true });
  const coveragePath = join(coverageDir, 'ears-coverage.json');

  const coverage = {
    generatedAt: new Date().toISOString(),
    source: srcArg ?? 'default (backlogs + docs/prds)',
    summary: {
      total,
      ears,
      bdd,
      nonEars,
      nonConforming,
      withTestId,
    },
    criteria: allCriteria,
    orphans: {
      criteriaWithoutTestId,
      testsWithoutCriterion,
    },
  };

  writeFileSync(coveragePath, JSON.stringify(coverage, null, 2), 'utf8');

  // ---------------------------------------------------------------------------
  // Console output
  // ---------------------------------------------------------------------------

  const pct = total > 0 ? Math.round(((ears + bdd + nonEars) / total) * 100) : 100;
  process.stdout.write(`[ears-lint] ${total} criteria scanned | ${ears} EARS | ${bdd} BDD | ${nonEars} NON-EARS exempt | ${nonConforming} non-conforming | ${pct}% covered\n`);
  process.stdout.write(`[ears-lint] coverage written → ${relative(REPO_ROOT, coveragePath)}\n`);

  if (nonConforming > 0) {
    process.stdout.write(`\n[ears-lint] Non-conforming criteria:\n`);
    for (const item of nonConformingItems) {
      process.stdout.write(`  [WARN] ${item.prd} :: ${item.acId}: ${item.text.slice(0, 120)}\n`);
    }
    if (strict) {
      process.stdout.write(`\n[ears-lint] FAIL: ${nonConforming} non-conforming criteria found (--strict / EARS_LINT_ENFORCE=1)\n`);
      process.stdout.write(`  Tip: prefix with "NON-EARS:" or set earsForm:"non-ears" to explicitly exempt.\n`);
      exit(1);
    } else {
      process.stdout.write(`\n[ears-lint] ADVISORY: ${nonConforming} non-conforming criteria found. Pass --strict or set EARS_LINT_ENFORCE=1 to enforce.\n`);
    }
  } else {
    process.stdout.write(`[ears-lint] OK: all criteria conform to EARS / BDD / NON-EARS exemption.\n`);
  }
}

main();
