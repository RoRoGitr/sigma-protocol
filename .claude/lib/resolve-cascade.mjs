#!/usr/bin/env node
/**
 * Sigma-local cascade resolver.
 *
 * This is the repo-scoped ladder resolver for Sigma Protocol. It reads
 * .claude/lib/agent-skill-registry.json from this repository, resolves a
 * department or Sigma step prompt, and prints the department head, matched bench,
 * and skill files using repo-relative paths.
 *
 * Usage:
 *   node .claude/lib/resolve-cascade.mjs "run step 5 wireframes" --json
 *   node .claude/lib/resolve-cascade.mjs design "invoke design department"
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
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
  const text = value.toString().toLowerCase();
  const direct = text.match(/\bstep[-\s]*([0-9]+(?:\.[0-9]+)?)\b/);
  return direct ? `step-${direct[1]}` : null;
}

function resolveDepartmentKey(registry, value) {
  const raw = (value || '').toString().toLowerCase();
  const departments = registry.departments || {};
  if (departments[raw]) return raw;
  const aliases = registry.config?.department_aliases || {};
  return aliases[raw] || null;
}

function findInvokedDepartment(registry, prompt) {
  const text = prompt.trim();
  const departments = registry.departments || {};
  const aliases = registry.config?.department_aliases || {};
  const candidates = [
    ...Object.keys(departments).map((department) => [department, department]),
    ...Object.entries(aliases).map(([alias, department]) => [alias, department]),
  ];

  for (const [label, department] of candidates) {
    const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
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
    if (explicit.test(text)) return department;
  }

  // Scored inference (2026-06-10, ported from the global unified-intent-router):
  // dept keywords score 2 per distinct hit (capped at 3 hits); each bench
  // agent whose trigger_regex matches adds 1. Best department wins only at
  // score >= 3, so a single generic keyword can't hijack the routing and
  // JSON ordering never decides ties.
  if (text.length < 18) return null;
  let best = null;
  let bestScore = 0;
  for (const [department, def] of Object.entries(departments)) {
    let score = 0;
    const rx = compile(def.keywords);
    if (rx) {
      let hits = [];
      try {
        hits = [...new Set((text.match(new RegExp(rx.source, 'gi')) || []).map((s) => s.toLowerCase()))];
      } catch { /* keep hits empty */ }
      score += 2 * Math.min(hits.length, 3);
    }
    for (const meta of Object.values(def.agents || {})) {
      const arx = compile(meta?.trigger_regex);
      if (arx?.test(text)) score += 1;
    }
    if (score > bestScore) {
      bestScore = score;
      best = department;
    }
  }
  return bestScore >= 3 ? best : null;
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

export function resolveCascade(prompt, options = {}) {
  const registry = options.registry || readJson(registryPath);
  if (!registry?.departments) return null;

  const explicitDepartment = resolveDepartmentKey(registry, options.department);
  const stepId = normalizeStep(prompt) || normalizeStep(options.step);
  const step = stepId ? registry.steps?.[stepId] : null;
  const department = explicitDepartment || step?.department || findInvokedDepartment(registry, prompt);
  const def = department ? registry.departments?.[department] : null;
  if (!department || !def?.head) return null;

  const agents = def.agents || {};
  const bench = [];
  for (const [agent, meta] of Object.entries(agents)) {
    const rx = compile(meta?.trigger_regex);
    if (rx?.test(prompt)) bench.push(agent);
  }

  const skills = [];
  skills.push(...(def.head_skills || []));
  for (const agent of bench) skills.push(...(agents[agent]?.skills || []));
  if (step?.skills) skills.push(...step.skills);

  const agentMap = buildAgentMap();
  const result = {
    department,
    tier: options.tier || tierFor(prompt),
    step: stepId,
    head: def.head,
    head_file: agentMap.get(def.head) || null,
    head_skills: def.head_skills || [],
    bench,
    bench_files: Object.fromEntries(bench.map((agent) => [agent, agentMap.get(agent) || null])),
    bench_skills: Object.fromEntries(bench.map((agent) => [agent, agents[agent]?.skills || []])),
    step_skills: step?.skills || [],
    skills: unique(skills),
  };
  result.skill_files = Object.fromEntries(result.skills.map((skill) => [skill, skillFile(skill)]));
  return result;
}

export function formatCascade(result) {
  if (!result) return '';
  const lines = [];
  const step = result.step ? ` via ${result.step}` : '';
  lines.push(`**Department cascade** (tier: \`${result.tier}\`) → invoke **${result.department}**${step} with head @${result.head}.`);
  if (result.head_file) lines.push(`- Head file: \`${result.head_file}\``);
  lines.push(`- Head skills: ${result.head_skills.map((skill) => `\`${skill}\``).join(', ') || '(none)'}`);
  if (result.bench.length) {
    lines.push(`- Context-relevant bench: ${result.bench.map((agent) => `@${agent}`).join(', ')}`);
    for (const agent of result.bench) {
      const file = result.bench_files[agent] ? ` (${result.bench_files[agent]})` : '';
      const skills = (result.bench_skills[agent] || []).map((skill) => `\`${skill}\``).join(', ') || '(none)';
      lines.push(`  - @${agent}${file} → ${skills}`);
    }
  } else {
    lines.push('- Context-relevant bench: none matched; keep the head accountable.');
  }
  if (result.step_skills.length) {
    lines.push(`- Step Required skills: ${result.step_skills.map((skill) => `\`${skill}\``).join(', ')}`);
  }
  lines.push('- Resolved skill files:');
  for (const skill of result.skills) {
    const file = result.skill_files[skill] || 'missing';
    lines.push(`  - \`${skill}\` → \`${file}\``);
  }
  lines.push(
    result.tier === 'spawn'
      ? '- Spawn tier: fan out the matched bench where the current surface supports agents.'
      : '- Advisor tier: load the head, bench, and skills into this turn without spawning.'
  );
  return lines.join('\n');
}

function main() {
  const args = process.argv.slice(2);
  const json = args.includes('--json');
  const tierIndex = args.indexOf('--tier');
  const tier = tierIndex >= 0 ? args[tierIndex + 1] : undefined;
  const positional = args.filter((arg, index) => {
    if (arg.startsWith('--')) return false;
    if (tierIndex >= 0 && index === tierIndex + 1) return false;
    return true;
  });

  const first = positional[0] || '';
  const second = positional[1] || '';
  const department = second ? first : undefined;
  const prompt = second || first;
  const result = resolveCascade(prompt, { department, tier });
  if (!result) process.exit(0);
  process.stdout.write(json ? `${JSON.stringify(result, null, 2)}\n` : `${formatCascade(result)}\n`);
}

if (fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
