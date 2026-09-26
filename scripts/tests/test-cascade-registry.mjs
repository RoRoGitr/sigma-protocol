#!/usr/bin/env node
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');
const registryPath = path.join(repoRoot, '.claude', 'lib', 'agent-skill-registry.json');
const hookPath = path.join(repoRoot, '.claude', 'hooks', 'prompt-stack-augmenter.cjs');
const settingsPath = path.join(repoRoot, '.claude', 'settings.json');
const commandsRoot = path.join(repoRoot, 'commands');
const agentsRoot = path.join(repoRoot, '.claude', 'agents');
// Canonical skill surfaces; `.claude/skills` is an optional operator-local overlay.
const skillsRoots = [
  path.join(repoRoot, '.agents', 'skills'),
  path.join(repoRoot, 'src', 'skills'),
  path.join(repoRoot, '.claude', 'skills'),
].filter((dir) => existsSync(dir));

function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

function walkSkillSlugs(roots = skillsRoots) {
  const out = new Set();
  const stack = [...roots];
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

function walkAgentSlugs(root = agentsRoot) {
  const out = new Set();
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const current = path.join(dir, entry.name);
      if (entry.isDirectory()) stack.push(current);
      if (entry.isFile() && entry.name.endsWith('.md')) {
        out.add(entry.name.replace(/\.md$/, ''));
      }
    }
  }
  return out;
}

function extractStepSkills() {
  const out = new Map();
  for (const file of readdirSync(commandsRoot).filter((name) => /^step-.*\.md$/.test(name))) {
    const text = readFileSync(path.join(commandsRoot, file), 'utf8');
    const match = text.match(/<!--\s*SKILLS-INVOKE:start\s*-->([\s\S]*?)<!--\s*SKILLS-INVOKE:end\s*-->/);
    if (!match) continue;
    const stepId = file.match(/^(step-[^-]+(?:\.[^-]+)?)/)?.[1] || file.replace(/\.md$/, '');
    // Only slug-shaped bullets are skill refs; block prose (paths, `$holes`) is not.
    const skills = [];
    for (const line of match[1].split('\n')) {
      const bullet = line.match(/^\s*-\s*`([a-z0-9][a-z0-9_-]*)`/);
      if (bullet) skills.push(bullet[1]);
    }
    out.set(stepId, skills);
  }
  return out;
}

function runHook(prompt) {
  const input = JSON.stringify({
    hook_event_name: 'UserPromptSubmit',
    prompt,
    session_id: `cascade-test-${Date.now()}`,
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

  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.ok(result.stdout.trim(), `hook emitted no output for "${prompt}"`);
  const payload = JSON.parse(result.stdout);
  return payload.hookSpecificOutput?.additionalContext || '';
}

describe('Sigma cascade registry', () => {
  it('resolves every department, agent, regex, and skill locally', () => {
    assert.ok(existsSync(registryPath), 'repo-local cascade registry is missing');
    const registry = readJson(registryPath);
    const agents = walkAgentSlugs();
    const skills = walkSkillSlugs();

    assert.equal(Object.keys(registry.departments || {}).length, 13);

    const referencedSkills = new Set();
    for (const [department, def] of Object.entries(registry.departments)) {
      assert.ok(def.head, `${department} has no head`);
      assert.ok(agents.has(def.head), `${department} head @${def.head} does not resolve in repo`);
      assert.doesNotThrow(() => new RegExp(def.keywords, 'i'), `${department}.keywords must compile`);

      for (const skill of def.head_skills || []) referencedSkills.add(skill);

      for (const [agent, meta] of Object.entries(def.agents || {})) {
        assert.ok(agents.has(agent), `${department} sub-agent @${agent} does not resolve in repo`);
        assert.ok(meta.trigger_regex, `${department}.${agent} missing trigger_regex`);
        assert.doesNotThrow(() => new RegExp(meta.trigger_regex, 'i'), `${department}.${agent}.trigger_regex must compile`);
        for (const skill of meta.skills || []) referencedSkills.add(skill);
      }
    }

    for (const [skill, meta] of Object.entries(registry.skills || {})) {
      referencedSkills.add(skill);
      assert.ok(Array.isArray(meta.trigger_keywords) && meta.trigger_keywords.length > 0, `${skill} has no trigger_keywords`);
      assert.ok(meta.department, `${skill} has no department`);
      assert.ok(meta.quality_tier, `${skill} has no quality_tier`);
      for (const agent of meta.owning_agents || []) {
        assert.ok(agents.has(agent), `${skill} owner @${agent} does not resolve in repo`);
      }
    }

    for (const skill of referencedSkills) {
      assert.ok(skills.has(skill), `skill ${skill} does not resolve to an in-repo SKILL.md on a canonical surface`);
    }
  });

  it('keeps step blocks and registry.steps consistent', () => {
    const registry = readJson(registryPath);
    const skills = walkSkillSlugs();
    const stepSkills = extractStepSkills();
    assert.ok(stepSkills.size >= 18, 'expected at least the Sigma step command skill blocks');

    for (const [stepId, blockSkills] of stepSkills) {
      // Every block bullet resolves on disk (registry membership not required —
      // curated/preflight extras are invoked directly via the Skill tool).
      for (const skill of blockSkills) {
        assert.ok(skills.has(skill), `${stepId} block references ${skill}, which does not resolve on any canonical surface`);
      }
      // Every registry-governed skill for the step appears in the rendered block.
      for (const skill of registry.steps?.[stepId]?.skills || []) {
        assert.ok(blockSkills.includes(skill), `registry.steps.${stepId} lists ${skill}, but the block omits it`);
      }
    }

    // Registry self-consistency: numbered steps tag via sigma_steps, run-track via run_steps.
    for (const [stepId, stepDef] of Object.entries(registry.steps || {})) {
      const tagField = stepId.startsWith('run-') ? 'run_steps' : 'sigma_steps';
      for (const skill of stepDef?.skills || []) {
        assert.ok(registry.skills?.[skill], `registry.steps.${stepId} lists ${skill}, but registry.skills lacks it`);
        assert.ok(
          registry.skills[skill][tagField]?.includes(stepId),
          `${skill} is missing ${tagField} tag ${stepId}`
        );
      }
    }
  });

  it('wires the UserPromptSubmit hook in settings', () => {
    const settings = readJson(settingsPath);
    const hooks = settings.hooks?.UserPromptSubmit || [];
    const commands = JSON.stringify(hooks);
    assert.ok(commands.includes('.claude/hooks/prompt-stack-augmenter.cjs'));
  });

  it('physically resolves sample prompts through the hook', () => {
    const stepFive = runHook('run step 5 wireframes');
    assert.match(stepFive, /@design-director/);
    assert.match(stepFive, /@ux-director/);
    assert.match(stepFive, /`frontend-design`/);
    assert.match(stepFive, /`wireframe`/);
    assert.match(stepFive, /`image-to-code`/);

    const design = runHook('invoke the design department');
    assert.match(design, /invoke \*\*design\*\*/);
    assert.match(design, /@design-director/);

    const marketing = runHook('invoke marketing for an ad');
    assert.match(marketing, /invoke \*\*marketing\*\*/);
    assert.match(marketing, /@cmo/);
    assert.match(marketing, /@paid-media-director/);
    assert.match(marketing, /`ads`/);
  });
});
