#!/usr/bin/env node
/**
 * validate-step-wiring.mjs — bench that Steps 0–15 invoke what they reference.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const STEPS_DIR = path.join(REPO_ROOT, 'steps');
const PARTIALS_DIR = path.join(STEPS_DIR, '_partials');
const SKILLS_DIR = path.join(REPO_ROOT, 'src', 'skills');
const COMMANDS_DIR = path.join(REPO_ROOT, 'commands');

const STRICT = process.argv.includes('--strict');
const JSON_MODE = process.argv.includes('--json');

const EXPECTED_STEPS = [
  'step-0-environment-setup',
  'step-1-ideation',
  'step-1.5-offer-architecture',
  'step-2-architecture',
  'step-3-ux-design',
  'step-4-flow-tree',
  'step-5-wireframe-prototypes',
  'step-6-design-system',
  'step-7-interface-states',
  'step-8-technical-spec',
  'step-9-landing-page',
  'step-10-feature-breakdown',
  'step-11-prd-generation',
  'step-11.5-task-handoff',
  'step-12-context-engine',
  'step-13-skillpack-generator',
  'step-14-agent-runtime-bootstrap',
  'step-15-observability-contract',
];

const REQUIRED_PARTIALS = {
  'step-0-environment-setup': ['boilerplate-catalog-preflight', 'curated-libraries-preflight', 'step-verify-handoff'],
  'step-1-ideation': ['boilerplate-catalog-preflight', 'step-verify-handoff'],
  'step-2-architecture': ['boilerplate-catalog-preflight', 'curated-libraries-preflight', 'step-verify-handoff'],
  'step-3-ux-design': ['curated-libraries-preflight', 'step-verify-handoff'],
  'step-4-flow-tree': ['dna-standards-preflight', 'curated-libraries-preflight', 'boilerplate-modules-preflight', 'step-verify-handoff'],
  'step-5-wireframe-prototypes': ['curated-libraries-preflight', 'step-verify-handoff'],
  'step-6-design-system': ['curated-libraries-preflight', 'step-verify-handoff'],
  'step-7-interface-states': ['curated-libraries-preflight', 'step-verify-handoff'],
  'step-8-technical-spec': ['curated-libraries-preflight', 'step-verify-handoff'],
  'step-9-landing-page': ['step9-template-catalog', 'step-verify-handoff'],
  'step-10-feature-breakdown': ['curated-libraries-preflight', 'boilerplate-modules-preflight', 'step-verify-handoff'],
  'step-11-prd-generation': ['curated-libraries-preflight', 'boilerplate-modules-preflight', 'step-verify-handoff'],
  'step-11.5-task-handoff': ['step-verify-handoff'],
  'step-12-context-engine': ['runtime-single-surface-policy', 'step12-canonical-body', 'step-verify-handoff'],
  'step-13-skillpack-generator': ['runtime-single-surface-policy', 'step-verify-handoff'],
  'step-14-agent-runtime-bootstrap': ['runtime-single-surface-policy', 'step-verify-handoff'],
  'step-15-observability-contract': ['step-verify-handoff'],
};

const PLATFORM_LINE_ALLOW = /do not|Do \*\*not\*\*|deprecated|Deprecated|optional operator|may exist|not required|not part|no mirror|e\.g\.|for example|visual design tool|Claude Design|Google Stitch|claude-design|bundle folder name|legacy|when configured|legacy adapter|Per-vendor|removed from the single-surface|do not run/i;

const issues = [];

function issue(severity, code, message, file = null) {
  issues.push({ severity, code, message, file });
}

function listSkillNames() {
  const names = new Set();
  if (!fs.existsSync(SKILLS_DIR)) return names;
  for (const entry of fs.readdirSync(SKILLS_DIR, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const p = path.join(SKILLS_DIR, entry.name);
    if (fs.existsSync(path.join(p, 'SKILL.md'))) names.add(entry.name);
    for (const sub of fs.readdirSync(p, { withFileTypes: true })) {
      if (sub.isDirectory() && fs.existsSync(path.join(p, sub.name, 'SKILL.md'))) {
        names.add(sub.name);
      }
    }
  }
  return names;
}

function skillExists(name) {
  if (listSkillNames().has(name)) return true;
  if (fs.existsSync(path.join(REPO_ROOT, '.agents', 'skills', name, 'SKILL.md'))) return true;
  if (fs.existsSync(path.join(REPO_ROOT, 'templates', 'skills', name, 'SKILL.md'))) return true;
  return false;
}

function extractSkillsInvoke(content) {
  const m = content.match(/<!-- SKILLS-INVOKE:start -->([\s\S]*?)<!-- SKILLS-INVOKE:end -->/);
  if (!m) return { skills: [], block: '' };
  const expandedBlock = expandIncludes(m[1]);
  const skills = [];
  for (const line of expandedBlock.split('\n')) {
    const hit = line.match(/^-\s+`([a-z0-9-]+)`/);
    if (hit) skills.push(hit[1]);
  }
  return { skills, block: m[0] };
}

function extractCuratedPartialSkills(content) {
  if (!content.includes('curated-libraries-preflight')) return new Set();
  const partialPath = path.join(PARTIALS_DIR, 'curated-libraries-preflight.md');
  if (!fs.existsSync(partialPath)) return new Set();
  const partial = fs.readFileSync(partialPath, 'utf8');
  const refs = new Set();
  for (const m of partial.matchAll(/→\s+`([a-z0-9-]+)`/g)) refs.add(m[1]);
  for (const m of partial.matchAll(/,\s*`([a-z0-9-]+)`/g)) refs.add(m[1]);
  return refs;
}

function extractPhaseInvokeSkills(content) {
  const refs = new Set();
  const patterns = [
    /\*\*Invoke skills?:\*\* `([^`\n]+)`/gi,
    /\*\*Invoke skill:\*\* `([a-z0-9-]+)`/gi,
    /\*\*Invoke `([a-z0-9-]+)`/gi,
    /(?:^|\s)invoke `([a-z0-9-]+)`/gi,
    /agents implementing it should invoke `([a-z0-9-]+)`/gi,
    /also invoke `([a-z0-9-]+)`/gi,
    /apply `([a-z0-9-]+)` \(invoke from src\/skills\//gi,
    /invoke `([a-z0-9-]+)` and `([a-z0-9-]+)`/gi,
  ];
  for (const re of patterns) {
    for (const m of content.matchAll(re)) {
      for (let i = 1; i < m.length; i++) {
        if (!m[i]) continue;
        for (const part of m[i].split(/`,\s*`/)) {
          const name = part.trim().replace(/^`|`$/g, '');
          if (/^[a-z][a-z0-9-]*$/.test(name)) refs.add(name);
        }
      }
    }
  }
  return refs;
}

function expandIncludes(content, seen = new Set()) {
  const re = /<!--\s*include:\s*(_partials\/[A-Za-z0-9._/-]+)\s*-->/g;
  return content.replace(re, (_, partial) => {
    const full = path.join(STEPS_DIR, partial);
    if (seen.has(full) || !fs.existsSync(full)) return '';
    seen.add(full);
    return expandIncludes(fs.readFileSync(full, 'utf8'), seen);
  });
}
function extractPartials(content) {
  const partials = [];
  const re = /<!--\s*include:\s*(_partials\/[A-Za-z0-9._/-]+)\s*-->/g;
  let m;
  while ((m = re.exec(content)) !== null) partials.push(m[1]);
  return partials;
}

function collectPartialRefs(content, seen = new Set()) {
  const refs = extractPartials(content);
  const all = [...refs];
  for (const ref of refs) {
    const full = path.join(STEPS_DIR, ref);
    if (seen.has(full) || !fs.existsSync(full)) continue;
    seen.add(full);
    all.push(...collectPartialRefs(fs.readFileSync(full, 'utf8'), seen));
  }
  return all;
}

function scanPlatformDrift(content, rel) {
  const badLineRes = [
    /Claude Code \/ Codex \/ Cursor \/ Droid/,
    /Factory Droid|Feeds Factory Droid/,
    /\.claude\/rules\/step12-methodology/,
    /CLAUDE\.md\.example.*Required|Required.*CLAUDE\.md\.example/,
    /mcp__exa__|mcp__firecrawl__/,
    /\/Volumes\/T7|T7 SSD/,
    /detect-workspace.*CLAUDE\.md/,
    /~\/\.claude\/skills\//,
    /skill `[a-z]/,
    /emit_codex_bundle|emit_droid_mission/,
    /Codex.*Claude Code|Claude Code.*Codex/,
    /\.cursor\/commands/,
  ];
  for (const line of content.split('\n')) {
    if (PLATFORM_LINE_ALLOW.test(line)) continue;
    for (const re of badLineRes) {
      if (re.test(line)) {
        issue('error', 'PLATFORM_DRIFT', `Platform-specific line in ${rel}: ${line.trim().slice(0, 120)}`, rel);
        break;
      }
    }
  }
}

const skillNames = listSkillNames();
const stepFiles = fs.readdirSync(STEPS_DIR)
  .filter((f) => f.startsWith('step-') && fs.statSync(path.join(STEPS_DIR, f)).isFile())
  .sort();

for (const expected of EXPECTED_STEPS) {
  if (!stepFiles.includes(expected)) {
    issue('error', 'MISSING_STEP', `Expected step file missing: steps/${expected}`);
  }
}

for (const stepFile of stepFiles) {
  const filePath = path.join(STEPS_DIR, stepFile);
  const content = fs.readFileSync(filePath, 'utf8');
  const expanded = expandIncludes(content);
  const rel = `steps/${stepFile}`;

  scanPlatformDrift(content, rel);
  scanPlatformDrift(expanded, `${rel} (expanded)`);

  if (!content.includes('<!-- SKILLS-INVOKE:start -->')) {
    issue('error', 'NO_SKILLS_INVOKE', `${rel} missing SKILLS-INVOKE block`, rel);
  } else if (!content.includes('skills-invoke-intro.md')) {
    issue('error', 'SKILLS_INTRO', `${rel} SKILLS-INVOKE must include skills-invoke-intro.md partial`, rel);
  }

  const { skills } = extractSkillsInvoke(content);
  for (const skill of skills) {
    if (!skillExists(skill)) {
      issue('error', 'MISSING_SKILL', `SKILLS-INVOKE skill \`${skill}\` not found (from ${rel})`, rel);
    }
  }

  const invokeRefs = new Set([...extractPhaseInvokeSkills(expanded), ...extractCuratedPartialSkills(expanded)]);
  for (const skill of invokeRefs) {
    if (!skills.includes(skill)) {
      issue('error', 'INVOKE_NOT_BOUND', `Phase invokes \`${skill}\` but it is missing from SKILLS-INVOKE in ${rel}`, rel);
    }
    if (!skillExists(skill)) {
      issue('error', 'MISSING_SKILL', `Phase invokes missing skill \`${skill}\` (from ${rel})`, rel);
    }
  }

  if (/\$holes|invoke `\$holes`|run `\$holes`/i.test(expanded) && !skills.includes('holes')) {
    issue('error', 'HOLES_NOT_BOUND', `${rel} requires \`holes\` in SKILLS-INVOKE (uses $holes gate)`, rel);
  }

  for (const partial of extractPartials(content)) {
    if (!fs.existsSync(path.join(STEPS_DIR, partial))) {
      issue('error', 'MISSING_PARTIAL', `Missing partial ${partial} referenced by ${rel}`, rel);
    }
  }

  const partialRefs = collectPartialRefs(content);
  const required = REQUIRED_PARTIALS[stepFile] || [];
  for (const partialName of required) {
    const hit = partialRefs.some((p) => p.includes(partialName)) || content.includes(partialName);
    if (!hit) {
      issue('error', 'REQUIRED_PARTIAL', `${rel} must reference partial ${partialName}`, rel);
    }
  }

  const hasVerifyHandoff =
    content.includes('step-verify-handoff.md') ||
    partialRefs.some((p) => p.includes('step-verify-handoff')) ||
    expanded.includes('@step-verify');

  if (!expanded.includes('<HARD-GATE>')) {
    issue('error', 'NO_HARD_GATE', `${rel} has no HARD-GATE marker (including partials)`, rel);
  }
  if (!expanded.includes('<verification>')) {
    issue('error', 'NO_VERIFICATION', `${rel} missing <verification> schema (including partials)`, rel);
  } else if (!hasVerifyHandoff) {
    issue('error', 'VERIFY_PARTIAL', `${rel} has <verification> but no step-verify-handoff partial`, rel);
  }

  const cmdPath = path.join(COMMANDS_DIR, `${stepFile}.md`);
  if (!fs.existsSync(cmdPath)) {
    issue('error', 'MISSING_COMMAND', `Missing rendered commands/${stepFile}.md — run sync-steps-to-platforms.sh`, rel);
  }
}

if (fs.existsSync(PARTIALS_DIR)) {
  for (const pf of fs.readdirSync(PARTIALS_DIR)) {
    const rel = `steps/_partials/${pf}`;
    scanPlatformDrift(fs.readFileSync(path.join(PARTIALS_DIR, pf), 'utf8'), rel);
  }
}

for (const aux of ['steps/README.md', 'steps/dev-loop']) {
  const auxPath = path.join(REPO_ROOT, aux);
  if (fs.existsSync(auxPath)) {
    scanPlatformDrift(fs.readFileSync(auxPath, 'utf8'), aux);
  }
}

// Legacy mirror dirs should not exist in clean OSS tree
for (const legacy of [
  'platforms',
  '.claude/commands',
  '.cursor/commands',
  '.factory/commands',
]) {
  if (fs.existsSync(path.join(REPO_ROOT, legacy))) {
    issue('warn', 'LEGACY_MIRROR', `Legacy mirror directory still present: ${legacy} (safe to delete)`);
  }
}

const errors = issues.filter((i) => i.severity === 'error');
const warns = issues.filter((i) => i.severity === 'warn');

if (JSON_MODE) {
  console.log(JSON.stringify({ ok: errors.length === 0, errors, warns, stepsChecked: stepFiles.length, skillsIndexed: skillNames.size }, null, 2));
} else {
  console.log(`validate-step-wiring: checked ${stepFiles.length} steps (expected ${EXPECTED_STEPS.length}), ${skillNames.size} skills`);
  for (const i of issues) {
    console.log(`[${i.severity.toUpperCase()}] ${i.code}: ${i.message}`);
  }
  if (errors.length === 0 && warns.length === 0) {
    console.log('validate-step-wiring: PASS');
  } else if (errors.length === 0) {
    console.log(`validate-step-wiring: PASS with ${warns.length} warning(s)`);
  } else {
    console.log(`validate-step-wiring: FAIL — ${errors.length} error(s), ${warns.length} warning(s)`);
  }
}

if (STRICT && (errors.length > 0 || warns.length > 0)) process.exit(1);
if (errors.length > 0) process.exit(1);
process.exit(0);
