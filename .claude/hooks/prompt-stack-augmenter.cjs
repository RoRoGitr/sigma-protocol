#!/usr/bin/env node
/**
 * Sigma Protocol UserPromptSubmit cascade hook.
 *
 * Repo-local and fail-open. It reads .claude/lib/agent-skill-registry.json from
 * this cloned repository, then injects the matched department head, context
 * bench, and step/skill files as additional context.
 */
'use strict';

const fs = require('fs');
const path = require('path');

if (process.env.SIGMA_CASCADE_ROUTING_OFF === '1') {
  process.exit(0);
}

const repoRoot = process.env.CLAUDE_PROJECT_DIR
  ? path.resolve(process.env.CLAUDE_PROJECT_DIR)
  : path.resolve(__dirname, '..', '..');
const registryPath = process.env.SIGMA_CASCADE_REGISTRY_FILE
  ? path.resolve(process.env.SIGMA_CASCADE_REGISTRY_FILE)
  : path.join(repoRoot, '.claude', 'lib', 'agent-skill-registry.json');
const agentsRoot = path.join(repoRoot, '.claude', 'agents');
// Canonical skill surfaces, in resolution order. `.claude/skills` is an
// operator-local install overlay — honored when present, never required.
const skillsRoots = [
  path.join(repoRoot, '.agents', 'skills'),
  path.join(repoRoot, 'src', 'skills'),
  path.join(repoRoot, '.claude', 'skills'),
];

function readInput() {
  try {
    return JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return {};
  }
}

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return null;
  }
}

function compile(pattern) {
  if (!pattern || typeof pattern !== 'string') return null;
  try {
    return new RegExp(pattern, 'i');
  } catch {
    return null;
  }
}

function unique(items) {
  return [...new Set(items.filter(Boolean))];
}

function rel(file) {
  return path.relative(repoRoot, file).split(path.sep).join('/');
}

function buildAgentMap() {
  const out = new Map();
  const stack = fs.existsSync(agentsRoot) ? [agentsRoot] : [];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const current = path.join(dir, entry.name);
      if (entry.isDirectory()) stack.push(current);
      if (entry.isFile() && entry.name.endsWith('.md')) {
        out.set(entry.name.replace(/\.md$/, ''), rel(current));
      }
    }
  }
  return out;
}

function skillFile(skill) {
  for (const root of skillsRoots) {
    const file = path.join(root, skill, 'SKILL.md');
    if (fs.existsSync(file)) return rel(file);
  }
  return null;
}

function normalizeStep(value) {
  if (!value) return null;
  const match = value.toString().toLowerCase().match(/\bstep[-\s]*([0-9]+(?:\.[0-9]+)?)\b/);
  return match ? `step-${match[1]}` : null;
}

function escapeRegexLiteral(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function resolveDepartmentKey(registry, value) {
  const raw = (value || '').toString().toLowerCase();
  if (registry.departments?.[raw]) return raw;
  return registry.config?.department_aliases?.[raw] || null;
}

function findInvokedDepartment(registry, prompt) {
  const departments = registry.departments || {};
  const aliases = registry.config?.department_aliases || {};
  const candidates = [
    ...Object.keys(departments).map((department) => [department, department]),
    ...Object.entries(aliases).map(([alias, department]) => [alias, department]),
  ];

  for (const [label, department] of candidates) {
    const escaped = escapeRegexLiteral(label);
    const explicit = new RegExp(
      [
        `^\\/${escaped}(?:\\b|:)`,
        `\\binvoke\\s+(?:the\\s+)?${escaped}\\s+(?:department|dept|team)\\b`,
        `\\binvoke\\s+(?:the\\s+)?${escaped}\\b`,
        `\\b${escaped}[-\\s]+(?:department|dept|team)\\b`,
        `\\b(?:department|dept|team)\\s+${escaped}\\b`,
      ].join('|'),
      'i'
    );
    if (explicit.test(prompt)) return department;
  }

  for (const [department, def] of Object.entries(departments)) {
    if (compile(def.keywords)?.test(prompt)) return department;
  }
  return null;
}

function tierFor(prompt) {
  if (/\b(just advise|advisor only|read only|answer only|do not spawn|don't spawn)\b/i.test(prompt)) {
    return 'advisor';
  }
  if (/\b(spawn|parallel|build|implement|design|wireframe|prototype|create|make|ship|scaffold)\b/i.test(prompt)) {
    return 'spawn';
  }
  return 'advisor';
}

function buildSkillTriggers(registry, prompt, alreadyNamed) {
  const cap = registry.config?.max_skills_injected_per_prompt || 16;
  const fired = [];
  for (const [skill, meta] of Object.entries(registry.skills || {})) {
    if (fired.length >= cap) break;
    if (alreadyNamed.has(skill)) continue;
    const keywords = Array.isArray(meta.trigger_keywords) ? meta.trigger_keywords : [];
    const escaped = keywords
      .filter((keyword) => typeof keyword === 'string' && keyword.trim())
      .map((keyword) => escapeRegexLiteral(keyword.trim()));
    if (!escaped.length) continue;
    const rx = new RegExp(`\\b(${escaped.join('|')})\\b`, 'i');
    if (rx.test(prompt)) fired.push({ skill, agents: meta.owning_agents || [] });
  }
  return fired;
}

function resolveCascade(registry, prompt) {
  const stepId = normalizeStep(prompt);
  const step = stepId ? registry.steps?.[stepId] : null;
  const department = step?.department || findInvokedDepartment(registry, prompt);
  const normalizedDepartment = resolveDepartmentKey(registry, department) || department;
  const def = normalizedDepartment ? registry.departments?.[normalizedDepartment] : null;
  if (!def?.head) return null;

  const agents = def.agents || {};
  const bench = [];
  for (const [agent, meta] of Object.entries(agents)) {
    if (compile(meta?.trigger_regex)?.test(prompt)) bench.push(agent);
  }

  const skills = [];
  skills.push(...(def.head_skills || []));
  for (const agent of bench) skills.push(...(agents[agent]?.skills || []));
  if (step?.skills) skills.push(...step.skills);

  const agentMap = buildAgentMap();
  const result = {
    department: normalizedDepartment,
    tier: tierFor(prompt),
    step: stepId,
    head: def.head,
    headFile: agentMap.get(def.head),
    headSkills: def.head_skills || [],
    bench,
    benchFiles: Object.fromEntries(bench.map((agent) => [agent, agentMap.get(agent)])),
    benchSkills: Object.fromEntries(bench.map((agent) => [agent, agents[agent]?.skills || []])),
    stepSkills: step?.skills || [],
    skills: unique(skills),
  };
  result.skillFiles = Object.fromEntries(result.skills.map((skill) => [skill, skillFile(skill)]));
  return result;
}

function formatCascade(cascade) {
  const step = cascade.step ? ` via ${cascade.step}` : '';
  const lines = [
    `**Department cascade** (tier: \`${cascade.tier}\`) → invoke **${cascade.department}**${step} with head @${cascade.head}.`,
  ];

  if (cascade.headFile) lines.push(`- Head file: \`${cascade.headFile}\``);
  lines.push(`- Head skills: ${cascade.headSkills.map((skill) => `\`${skill}\``).join(', ') || '(none)'}`);

  if (cascade.bench.length) {
    lines.push(`- Context-relevant bench: ${cascade.bench.map((agent) => `@${agent}`).join(', ')}`);
    for (const agent of cascade.bench) {
      const file = cascade.benchFiles[agent] ? ` (${cascade.benchFiles[agent]})` : '';
      const skills = (cascade.benchSkills[agent] || []).map((skill) => `\`${skill}\``).join(', ') || '(none)';
      lines.push(`  - @${agent}${file} → ${skills}`);
    }
  } else {
    lines.push('- Context-relevant bench: none matched; keep the head accountable.');
  }

  if (cascade.stepSkills.length) {
    lines.push(`- Step Required skills: ${cascade.stepSkills.map((skill) => `\`${skill}\``).join(', ')}`);
  }

  lines.push('- Resolved skill files:');
  for (const skill of cascade.skills) {
    lines.push(`  - \`${skill}\` → \`${cascade.skillFiles[skill] || 'missing'}\``);
  }
  lines.push(
    cascade.tier === 'spawn'
      ? '- Spawn tier: fan out the matched bench where the current surface supports agents.'
      : '- Advisor tier: load the head, bench, and skills into this turn without spawning.'
  );
  return lines;
}

function emit(additionalContext) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext,
    },
  }));
}

function main() {
  const input = readInput();
  if ((input.hook_event_name || '') !== 'UserPromptSubmit') return;
  const prompt = (input.prompt || '').toString();
  if (!prompt.trim()) return;

  const registry = readJson(registryPath);
  if (!registry?.departments || !registry?.skills) return;

  const cascade = resolveCascade(registry, prompt);
  const alreadyNamed = new Set(cascade?.skills || []);
  const skillTriggers = buildSkillTriggers(registry, prompt, alreadyNamed);

  if (!cascade && skillTriggers.length === 0) return;

  const lines = [];
  if (cascade) lines.push(...formatCascade(cascade));
  if (skillTriggers.length) {
    if (lines.length) lines.push('');
    lines.push('**Skill triggers** (registry) → invoke these skills this turn:');
    for (const fired of skillTriggers) {
      const owner = fired.agents.length ? ` — owner: ${fired.agents.map((agent) => `@${agent}`).join(', ')}` : '';
      lines.push(`- \`${fired.skill}\`${owner}`);
    }
  }
  lines.push('');
  lines.push('Treat these as standing skills for this turn; no global registry lookup is required.');
  emit(lines.join('\n'));
}

try {
  main();
} catch (error) {
  if (process.env.PROMPT_STACK_AUGMENTER_DEBUG === '1') {
    process.stderr.write(`prompt-stack-augmenter error: ${error?.message || error}\n`);
  }
}
