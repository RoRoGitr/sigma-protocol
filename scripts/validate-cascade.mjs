#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const registryPath = path.join(repoRoot, '.claude', 'lib', 'agent-skill-registry.json');
const resolverPath = path.join(repoRoot, '.claude', 'lib', 'resolve-cascade.mjs');
const hookPath = path.join(repoRoot, '.claude', 'hooks', 'prompt-stack-augmenter.cjs');
const settingsPath = path.join(repoRoot, '.claude', 'settings.json');
const commandsRoot = path.join(repoRoot, 'commands');
const agentsRoot = path.join(repoRoot, '.claude', 'agents');
// Canonical skill surfaces (single-surface contract). `.claude/skills` is an
// operator-local install overlay — honored when present, never required.
const skillsRoots = [
  path.join(repoRoot, '.agents', 'skills'),
  path.join(repoRoot, 'src', 'skills'),
  path.join(repoRoot, '.claude', 'skills'),
].filter((dir) => existsSync(dir));

const failures = [];

function fail(message) {
  failures.push(message);
}

function readJson(file, label) {
  try {
    return JSON.parse(readFileSync(file, 'utf8'));
  } catch (error) {
    fail(`${label} is not valid JSON: ${error.message}`);
    return null;
  }
}

function walkAgents() {
  const out = new Map();
  const stack = existsSync(agentsRoot) ? [agentsRoot] : [];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const current = path.join(dir, entry.name);
      if (entry.isDirectory()) stack.push(current);
      if (entry.isFile() && entry.name.endsWith('.md')) {
        out.set(entry.name.replace(/\.md$/, ''), path.relative(repoRoot, current));
      }
    }
  }
  return out;
}

function walkSkillSlugs() {
  const out = new Set();
  const stack = [...skillsRoots];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const current = path.join(dir, entry.name);
      if (entry.isDirectory()) stack.push(current);
      if (entry.isFile() && entry.name === 'SKILL.md') {
        out.add(path.basename(path.dirname(current)));
      }
    }
  }
  return out;
}

const skillSlugIndex = new Set();

function skillExists(skill) {
  if (skillSlugIndex.size === 0) for (const slug of walkSkillSlugs()) skillSlugIndex.add(slug);
  if (skillSlugIndex.has(skill)) return true;
  return skillsRoots.some((root) => existsSync(path.join(root, skill, 'SKILL.md')));
}

function assertRegex(pattern, label) {
  try {
    new RegExp(pattern, 'i');
  } catch (error) {
    fail(`${label} has invalid regex: ${error.message}`);
  }
}

function extractStepSkills() {
  // Only slug-shaped bullet entries (`- \`skill-name\``) are skill references.
  // Prose inside the block (paths, placeholders, `$holes`) is not.
  const out = new Map();
  for (const file of readdirSync(commandsRoot).filter((name) => /^step-.*\.md$/.test(name))) {
    const text = readFileSync(path.join(commandsRoot, file), 'utf8');
    const match = text.match(/<!--\s*SKILLS-INVOKE:start\s*-->([\s\S]*?)<!--\s*SKILLS-INVOKE:end\s*-->/);
    if (!match) continue;
    const stepId = file.match(/^(step-[^-]+(?:\.[^-]+)?)/)?.[1] || file.replace(/\.md$/, '');
    const skills = [];
    for (const line of match[1].split('\n')) {
      const bullet = line.match(/^\s*-\s*`([a-z0-9][a-z0-9_-]*)`/);
      if (bullet) skills.push(bullet[1]);
    }
    out.set(stepId, skills);
  }
  return out;
}

function validateRegistry(registry, agents) {
  if (!registry || typeof registry !== 'object') return;
  if (!registry.departments || typeof registry.departments !== 'object') {
    fail('registry.departments is missing');
    return;
  }
  if (Object.keys(registry.departments).length !== 13) {
    fail(`registry.departments expected 13 departments, found ${Object.keys(registry.departments).length}`);
  }

  const referencedSkills = new Set();
  for (const [department, def] of Object.entries(registry.departments)) {
    const head = def.head || def.lead;
    if (!head) fail(`${department} has no head`);
    if (head && !agents.has(head)) fail(`${department} head @${head} does not resolve`);
    if (def.keywords) assertRegex(def.keywords, `${department}.keywords`);

    for (const skill of def.head_skills || []) referencedSkills.add(skill);

    for (const [agent, meta] of Object.entries(def.agents || {})) {
      if (!agents.has(agent)) fail(`${department} sub-agent @${agent} does not resolve`);
      if (!meta?.trigger_regex) fail(`${department}.${agent} is missing trigger_regex`);
      if (meta?.trigger_regex) assertRegex(meta.trigger_regex, `${department}.${agent}.trigger_regex`);
      for (const skill of meta.skills || []) referencedSkills.add(skill);
    }
  }

  if (!registry.skills || typeof registry.skills !== 'object') {
    fail('registry.skills is missing');
    return;
  }

  for (const [skill, meta] of Object.entries(registry.skills)) {
    referencedSkills.add(skill);
    if (!skillExists(skill)) fail(`top-level skill ${skill} does not resolve on any canonical skill surface`);
    if (!Array.isArray(meta.trigger_keywords) || meta.trigger_keywords.length === 0) {
      fail(`top-level skill ${skill} has no trigger_keywords`);
    }
    if (!meta.department) fail(`top-level skill ${skill} has no department`);
    if (!meta.quality_tier) fail(`top-level skill ${skill} has no quality_tier`);
    for (const agent of meta.owning_agents || []) {
      if (!agents.has(agent)) fail(`top-level skill ${skill} owning agent @${agent} does not resolve`);
    }
  }

  for (const skill of referencedSkills) {
    if (!skillExists(skill)) fail(`referenced skill ${skill} does not resolve on any canonical skill surface`);
  }
}

function validateStepTags(registry) {
  const stepSkills = extractStepSkills();
  if (stepSkills.size < 18) fail(`expected at least 18 step skill blocks, found ${stepSkills.size}`);

  for (const [stepId, skills] of stepSkills) {
    const stepDef = registry.steps?.[stepId];
    if (!stepDef) fail(`registry.steps missing ${stepId}`);

    // INV2: every skill bullet in a step block must resolve to a real skill.
    // Registry membership is NOT required — curated/preflight extras are
    // invoked directly via the Skill tool and stay outside cascade governance.
    for (const skill of skills) {
      if (!skillExists(skill)) fail(`${stepId} block references ${skill}, which does not resolve on any canonical skill surface`);
    }

    // INV3: every registry-governed skill for this step must appear in the
    // rendered block (generate-skill-bindings.mjs output is not stale).
    for (const skill of stepDef?.skills || []) {
      if (!skills.includes(skill)) fail(`registry.steps.${stepId} lists ${skill}, but the ${stepId} block does not include it`);
    }
  }

  // INV1: registry self-consistency for every step entry. Numbered steps tag
  // membership via sigma_steps; run-track steps via run_steps.
  for (const [stepId, stepDef] of Object.entries(registry.steps || {})) {
    const tagField = stepId.startsWith('run-') ? 'run_steps' : 'sigma_steps';
    for (const skill of stepDef?.skills || []) {
      if (!registry.skills?.[skill]) {
        fail(`registry.steps.${stepId} lists ${skill}, but registry.skills lacks it`);
        continue;
      }
      if (!registry.skills[skill][tagField]?.includes(stepId)) {
        fail(`${skill} is missing ${tagField} tag ${stepId} (listed in registry.steps.${stepId})`);
      }
    }
  }
  return stepSkills;
}

function validateAgentFrontmatter() {
  const stack = existsSync(agentsRoot) ? [agentsRoot] : [];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const current = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(current);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith('.md') || entry.name.toLowerCase() === 'readme.md') continue;
      const text = readFileSync(current, 'utf8');
      if (!text.startsWith('---')) continue;
      const end = text.indexOf('\n---', 3);
      if (end === -1) continue;
      const head = text.slice(0, end);
      const match = head.match(/\nskills:\s*\n((?:[ \t]*-[ \t]*.+\n?)+)/);
      if (!match) continue;
      const rel = path.relative(repoRoot, current);
      for (const line of match[1].split('\n')) {
        const item = line.match(/^[ \t]*-[ \t]*(.+?)[ \t]*$/);
        if (!item) continue;
        const slug = item[1].replace(/^["']|["']$/g, '').split('/').pop();
        if (!skillExists(slug)) fail(`agent ${rel} binds skill ${slug} which does not resolve on any canonical skill surface`);
      }
    }
  }
}

function validateSettings() {
  const settings = readJson(settingsPath, 'settings.json');
  const commands = JSON.stringify(settings?.hooks?.UserPromptSubmit || []);
  if (!commands.includes('.claude/hooks/prompt-stack-augmenter.cjs')) {
    fail('settings.json does not wire .claude/hooks/prompt-stack-augmenter.cjs into UserPromptSubmit');
  }
}

function runHook(prompt) {
  const input = JSON.stringify({
    hook_event_name: 'UserPromptSubmit',
    prompt,
    session_id: `validate-cascade-${Date.now()}`,
  });
  const result = spawnSync(process.execPath, [hookPath], {
    input,
    encoding: 'utf8',
    env: {
      ...process.env,
      CLAUDE_PROJECT_DIR: repoRoot,
      PROMPT_STACK_AUGMENTER_DISABLE_DEDUP: '1',
    },
  });
  if (result.status !== 0) {
    fail(`hook exited ${result.status} for prompt "${prompt}": ${result.stderr || result.stdout}`);
    return '';
  }
  if (!result.stdout.trim()) {
    fail(`hook emitted no output for prompt "${prompt}"`);
    return '';
  }
  try {
    const payload = JSON.parse(result.stdout);
    return payload.hookSpecificOutput?.additionalContext || '';
  } catch (error) {
    fail(`hook output is not valid JSON for prompt "${prompt}": ${error.message}`);
    return '';
  }
}

function assertIncludes(text, needles, label) {
  for (const needle of needles) {
    if (!text.includes(needle)) fail(`${label} missing ${needle}`);
  }
}

function validateHookSmoke() {
  const stepFive = runHook('run step 5 wireframes');
  assertIncludes(
    stepFive,
    ['invoke **design**', '@design-director', '@ux-director', '`frontend-design`', '`wireframe`', '`image-to-code`'],
    'step-5 cascade'
  );
  if (stepFive.includes('`missing`')) fail('step-5 cascade emits unresolved skill files (`missing`) — skill surface resolution is broken');

  const design = runHook('invoke the design department');
  assertIncludes(design, ['invoke **design**', '@design-director'], 'design cascade');

  const marketing = runHook('invoke marketing for an ad');
  assertIncludes(marketing, ['invoke **marketing**', '@cmo', '@paid-media-director', '`ads`'], 'marketing cascade');
}

function validateNoAbsoluteMachinePaths() {
  // Any absolute home path (this machine's or otherwise) hardcoded in runtime
  // files would break every other install — catch the pattern, not a name.
  const machinePathPattern = /(?:\/Users|\/home)\/[A-Za-z0-9._-]+\//;
  for (const file of [registryPath, resolverPath, hookPath, settingsPath]) {
    if (!existsSync(file)) {
      fail(`${path.relative(repoRoot, file)} is missing`);
      continue;
    }
    const text = readFileSync(file, 'utf8');
    if (machinePathPattern.test(text)) fail(`${path.relative(repoRoot, file)} contains a hardcoded machine home path`);
  }
}

const registry = readJson(registryPath, 'agent-skill-registry.json');
const agents = walkAgents();
const skills = walkSkillSlugs();

validateNoAbsoluteMachinePaths();
validateRegistry(registry, agents);
const stepSkills = registry ? validateStepTags(registry) : new Map();
validateAgentFrontmatter();
validateSettings();
validateHookSmoke();

if (failures.length) {
  console.error('validate-cascade failed');
  for (const item of failures) console.error(`- ${item}`);
  process.exit(1);
}

console.log('validate-cascade passed');
console.log(`- departments: ${Object.keys(registry.departments).length}`);
console.log(`- agents: ${agents.size}`);
console.log(`- skills in repo: ${skills.size}`);
console.log(`- registry skills: ${Object.keys(registry.skills).length}`);
console.log(`- step skill blocks: ${stepSkills.size}`);
console.log('- hook fire: step-5 design cascade, design department, marketing ad');
console.log('- repo-local files: .claude/lib/agent-skill-registry.json, .claude/lib/resolve-cascade.mjs, .claude/hooks/prompt-stack-augmenter.cjs');
