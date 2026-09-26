#!/usr/bin/env node
/**
 * generate-skill-bindings.mjs — make the registry the single source of truth.
 *
 * Reads .claude/lib/agent-skill-registry.json and regenerates, in-place:
 *   1. The `<!-- SKILLS-INVOKE:start/end -->` block in each canonical
 *      `steps/step-*` file from `registry.steps[<id>].skills`.
 *   2. (with --agents) the `skills:` frontmatter list in each
 *      `.claude/agents/<dept>/<agent>.md` from the registry's head_skills and
 *      per-agent skills, MERGED with any skills the agent already declares so no
 *      curated binding is silently dropped.
 *
 * Default run touches steps only (safe + idempotent). Agent frontmatter is
 * opt-in via --agents because it is reconciled in the bindings pass.
 *
 * Flags: --agents  also rewrite agent skills: frontmatter
 *        --check   report drift, write nothing, exit 1 if any drift
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const registry = JSON.parse(fs.readFileSync(path.join(root, '.claude/lib/agent-skill-registry.json'), 'utf8'));

const args = new Set(process.argv.slice(2));
const CHECK = args.has('--check');
const DO_AGENTS = args.has('--agents');

const START = '<!-- SKILLS-INVOKE:start -->';
const END = '<!-- SKILLS-INVOKE:end -->';

function stepIdFromFilename(name) {
  const m = name.match(/^step-([0-9]+(?:\.[0-9]+)?)/);
  return m ? `step-${m[1]}` : null;
}

function renderBlock(skills, phases = {}) {
  const bullets = skills.length
    ? skills.map((s) => (phases[s] ? `- \`${s}\` — ${phases[s]}` : `- \`${s}\``)).join('\n')
    : '- _(no required skills for this step)_';
  return [
    START,
    '## Required skills — invoke the live skills (do NOT rely on embedded summaries)',
    '',
    "This step's output quality depends on these skills. **Invoke each via the Skill tool at the relevant phase** so you get the current, benchmarked version (the registry keeps these in sync across Claude Code / Codex / Cursor / Droid):",
    '',
    bullets,
    '',
    'If a skill is unavailable on this surface, state that and continue; never silently skip it.',
    END,
  ].join('\n');
}

let drift = 0;
let wrote = 0;

// ---- 1. step SKILLS-INVOKE blocks ----
const stepsDir = path.join(root, 'steps');
for (const name of fs.readdirSync(stepsDir)) {
  const file = path.join(stepsDir, name);
  if (!fs.statSync(file).isFile() || !name.startsWith('step-')) continue;
  const id = stepIdFromFilename(name);
  const def = id && registry.steps?.[id];
  if (!def) continue;
  const skills = Array.isArray(def.skills) ? def.skills : [];
  const text = fs.readFileSync(file, 'utf8');
  const s = text.indexOf(START);
  const e = text.indexOf(END);
  if (s === -1 || e === -1) continue;
  const current = text.slice(s, e + END.length);
  const next = renderBlock(skills, def.skill_phases || {});
  if (current === next) continue;
  drift++;
  if (CHECK) {
    console.log(`DRIFT step ${name} (registry ${skills.length} skills)`);
  } else {
    fs.writeFileSync(file, text.slice(0, s) + next + text.slice(e + END.length));
    wrote++;
    console.log(`OK   step ${name} (${skills.length} skills)`);
  }
}

// ---- 2. agent skills: frontmatter (opt-in) ----
function registrySkillsForAgent(agentName) {
  const out = new Set();
  for (const dept of Object.values(registry.departments || {})) {
    if (dept.head === agentName) (dept.head_skills || []).forEach((x) => out.add(x));
    const a = dept.agents?.[agentName];
    if (a?.skills) a.skills.forEach((x) => out.add(x));
  }
  return [...out];
}

function mergeFrontmatterSkills(text, skills) {
  if (!text.startsWith('---')) return null;
  const end = text.indexOf('\n---', 3);
  if (end === -1) return null;
  const head = text.slice(0, end);
  const body = text.slice(end);
  // existing skills: block (list form)
  const existing = new Set();
  const m = head.match(/\nskills:\s*\n((?:\s*-\s*.+\n?)*)/);
  if (m) for (const line of m[1].split('\n')) {
    const im = line.match(/^\s*-\s*(.+?)\s*$/);
    if (im) existing.add(im[1].replace(/^["']|["']$/g, ''));
  }
  const merged = [...new Set([...existing, ...skills])].sort();
  if (!merged.length) return null;
  const block = 'skills:\n' + merged.map((s) => `  - ${s}`).join('\n');
  let newHead;
  if (m) newHead = head.replace(/\nskills:\s*\n(?:\s*-\s*.+\n?)*/, '\n' + block + '\n');
  else newHead = head + '\n' + block;
  const next = newHead + body;
  return next === text ? null : next;
}

if (DO_AGENTS) {
  const agentsDir = path.join(root, '.claude/agents');
  const stack = fs.existsSync(agentsDir) ? [agentsDir] : [];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, entry.name);
      if (entry.isDirectory()) { stack.push(p); continue; }
      if (!entry.name.endsWith('.md') || entry.name.toLowerCase() === 'readme.md') continue;
      const agentName = entry.name.replace(/\.md$/, '');
      const skills = registrySkillsForAgent(agentName);
      if (!skills.length) continue;
      const text = fs.readFileSync(p, 'utf8');
      const next = mergeFrontmatterSkills(text, skills);
      if (!next) continue;
      drift++;
      if (CHECK) console.log(`DRIFT agent ${path.relative(root, p)}`);
      else { fs.writeFileSync(p, next); wrote++; console.log(`OK   agent ${path.relative(root, p)}`); }
    }
  }
}

if (CHECK) {
  console.log(drift ? `\n${drift} file(s) drift from registry` : '\nbindings in sync with registry');
  process.exit(drift ? 1 : 0);
}
console.log(`\nWrote ${wrote} file(s) from registry.`);
