#!/usr/bin/env node
// validate-skills.mjs — skill-routing integrity gate for the harness-as-company skill system.
//
// Sigma `src/` is the single source of truth; it mirrors byte-for-byte into the global
// `~/.claude/skills` pool, and downstream agent runtimes inherit that pool via their config
// bridge. This validator keeps that invariant from rotting.
//
// Checks (default — CI-safe, no machine-local state):
//   1. Every recursive `src/skills/**/SKILL.md` and `.agents/skills/**/SKILL.md`
//      has valid frontmatter; `name:` must match its containing directory.
//   2. Every `skills:` ref in `src/agents/**` resolves to a src skill OR an allowlisted
//      external/global skill (scripts/skills-allowlist.json). Dept-pathed refs
//      (`engineering/backend/foo`) resolve on their basename.
//   Hard-fails (exit 1) on any dangling ref or name mismatch.
//
//   --sync   : additionally diff each src skill against the global pool (~/.claude/skills)
//              and report MISSING (in src, absent from global) / DRIFT (SKILL.md differs).
//              Skipped automatically when the global pool isn't present (e.g. in CI).
//   --strict : promote sync MISSING/DRIFT warnings to hard failures.
//
// Usage:  node scripts/validate-skills.mjs [--sync] [--strict]

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const SKILLS_DIR = path.join(root, 'src', 'skills');
const BUNDLED_SKILLS_DIR = path.join(root, '.agents', 'skills');
const AGENTS_DIR = path.join(root, 'src', 'agents');
const ALLOWLIST = path.join(__dirname, 'skills-allowlist.json');

const args = new Set(process.argv.slice(2));
const SYNC = args.has('--sync');
const STRICT = args.has('--strict');

const errors = [];
const warnings = [];

function frontmatter(md) {
  const txt = fs.readFileSync(md, 'utf8');
  const m = txt.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  return m ? m[1] : null;
}

function frontmatterName(md) {
  const fm = frontmatter(md);
  if (fm === null) return null;
  const nm = fm.match(/^name:\s*["']?([^"'\n]+?)["']?\s*$/m);
  return nm ? nm[1].trim() : null;
}

function listSkillFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  return walkMd(dir)
    .filter((file) => path.basename(file) === 'SKILL.md'
      || (dir === SKILLS_DIR && path.dirname(file) === dir && path.basename(file) !== 'README.md'))
    .sort();
}

function agentSkillRefs(agentMd) {
  const fm = frontmatter(agentMd);
  if (fm === null) return [];
  const out = [];
  let inSkills = false;
  for (const line of fm.split('\n')) {
    if (/^skills:\s*$/.test(line)) { inSkills = true; continue; }
    if (!inSkills) continue;
    const item = line.match(/^\s*-\s*(.+?)\s*$/);
    if (item) { out.push(item[1].replace(/["']/g, '').trim()); continue; }
    if (/^\S/.test(line)) break; // next top-level frontmatter key ends the list
  }
  return out;
}

function walkMd(dir) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walkMd(p));
    else if (e.name.endsWith('.md')) out.push(p);
  }
  return out;
}

function skillHash(md) {
  if (!fs.existsSync(md)) return null;
  return crypto.createHash('sha256').update(fs.readFileSync(md)).digest('hex');
}

// --- allowlist (external/global skills that src agents may reference) ---
let allowSet = new Set();
if (fs.existsSync(ALLOWLIST)) {
  try {
    const j = JSON.parse(fs.readFileSync(ALLOWLIST, 'utf8'));
    allowSet = new Set(j.external_skills || []);
  } catch (e) {
    errors.push(`skills-allowlist.json is not valid JSON: ${e.message}`);
  }
}

// --- check 1: skill metadata in authored and bundled pools ---
const sourceSkillFiles = listSkillFiles(SKILLS_DIR);
const bundledSkillFiles = listSkillFiles(BUNDLED_SKILLS_DIR);
const skillName = (md) => path.basename(md) === 'SKILL.md' ? path.basename(path.dirname(md)) : path.basename(md, '.md');
const skillDirs = sourceSkillFiles.map(skillName);
const skillSet = new Set(skillDirs);
function validateSkillMetadata(md, pool) {
  const d = skillName(md);
  const name = frontmatterName(md);
  if (name === null) errors.push(`${pool} skill '${path.relative(root, md)}': missing or unparseable frontmatter name:`);
  else if (name !== d) errors.push(`${pool} skill '${path.relative(root, md)}': frontmatter name '${name}' != directory '${d}'`);
  const fm = frontmatter(md);
  const description = fm?.match(/^description:[ \t]*(.*)$/m);
  const value = description?.[1].trim();
  let hasDescription = Boolean(value && value !== '""' && value !== "''" && !value.startsWith('#'));
  if (value && /^[|>][-+]?/.test(value)) {
    const rest = fm.slice(description.index + description[0].length).split('\n').slice(1);
    const content = [];
    for (const line of rest) {
      if (/^\S/.test(line)) break;
      content.push(line.trim());
    }
    hasDescription = content.some((line) => line && !line.startsWith('#'));
  }
  if (fm !== null && !hasDescription) {
    errors.push(`${pool} skill '${path.relative(root, md)}': missing or empty frontmatter description:`);
  }
}
for (const md of sourceSkillFiles) validateSkillMetadata(md, 'src');
for (const md of bundledSkillFiles) validateSkillMetadata(md, 'bundled');
for (const files of [sourceSkillFiles, bundledSkillFiles]) {
  const seen = new Map();
  for (const md of files) {
    const name = skillName(md);
    if (seen.has(name)) errors.push(`Duplicate skill identity '${name}': ${seen.get(name)} and ${md}`);
    seen.set(name, md);
  }
}

// --- check 2: agent skills-refs resolve ---
let agentCount = 0;
let refCount = 0;
for (const agent of walkMd(AGENTS_DIR)) {
  agentCount++;
  for (const ref of agentSkillRefs(agent)) {
    refCount++;
    const base = ref.split('/').pop();
    const resolved = skillSet.has(ref) || skillSet.has(base) || allowSet.has(ref) || allowSet.has(base);
    if (!resolved) {
      errors.push(`${path.relative(root, agent)}: skills ref '${ref}' does not resolve (not in src/skills/ or skills-allowlist.json)`);
    }
  }
}

// --- check 3 (optional): cross-surface sync vs global pool ---
if (SYNC) {
  const globalSkills = path.join(os.homedir(), '.claude', 'skills');
  if (!fs.existsSync(globalSkills)) {
    warnings.push(`--sync: global pool ${globalSkills} not present — skipped (expected in CI)`);
  } else {
    for (const md of sourceSkillFiles) {
      const d = skillName(md);
      const g = path.join(globalSkills, d);
      if (!fs.existsSync(g)) { warnings.push(`sync: '${d}' in src but MISSING from global pool`); continue; }
      if (skillHash(md) !== skillHash(path.join(g, 'SKILL.md'))) {
        warnings.push(`sync: '${d}' DRIFT — src and global SKILL.md differ (re-mirror)`);
      }
    }
    warnings.push(`--sync: downstream runtimes that bridge to the global pool inherit it 1:1, so the global pool is the consumer source of truth.`);
  }
}

// --- report ---
if (warnings.length) {
  console.log('Warnings:');
  for (const w of warnings) console.log('  ⚠ ' + w);
  console.log('');
}
if (errors.length) {
  console.error(`FAIL: ${errors.length} skill-routing error(s):`);
  for (const e of errors) console.error('  ✗ ' + e);
  process.exit(1);
}
const driftFail = STRICT && warnings.some((w) => w.includes('DRIFT') || w.includes('MISSING from global'));
if (driftFail) {
  console.error('FAIL: --strict set and cross-surface drift present (see warnings).');
  process.exit(1);
}
console.log(`OK: ${sourceSkillFiles.length} authored skills and ${bundledSkillFiles.length} bundled skills (frontmatter valid), ${refCount} agent skill-refs across ${agentCount} agents all resolve.`);
