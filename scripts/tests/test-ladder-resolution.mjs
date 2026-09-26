#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');
const registryPath = path.join(repoRoot, '.claude', 'lib', 'agent-skill-registry.json');
const hookPath = path.join(repoRoot, '.claude', 'hooks', 'prompt-stack-augmenter.cjs');
const agentsRoot = path.join(repoRoot, '.claude', 'agents');
// Canonical skill surfaces; `.claude/skills` is an optional operator-local overlay.
const skillsRoots = [
  path.join(repoRoot, '.agents', 'skills'),
  path.join(repoRoot, 'src', 'skills'),
  path.join(repoRoot, '.claude', 'skills'),
].filter((dir) => existsSync(dir));
const skillRootPrefixes = ['.agents/skills/', 'src/skills/', '.claude/skills/'];

const ladderStepCases = [
  {
    id: 'step-0',
    prompt:
      'Student request: run step 0 environment setup. Set up operations, devops CI pipeline release, observability logs telemetry monitoring alerts, and QA verification regression coverage evidence.',
    agents: ['devops', 'observability-engineer', 'qa-engineer'],
  },
  {
    id: 'step-1',
    prompt:
      'Student request: run step 1 ideation. Shape the PRD bootstrapping, feature requirements, acceptance criteria, ideation, market validation, business model, and offer.',
    agents: ['product-owner', 'venture-studio-partner'],
  },
  {
    id: 'step-1.5',
    prompt:
      'Student request: run step 1.5 offer architecture. Run sales discovery and qualification, design the offer and pricing, handle the price objection, and negotiate the close.',
    agents: ['discovery-specialist', 'negotiation-specialist'],
  },
  {
    id: 'step-2',
    prompt:
      'Student request: run step 2 architecture. Decide the technical architecture, API, backend service, auth, database schema, migration, and worker boundaries.',
    agents: ['backend-engineer'],
  },
  {
    id: 'step-3',
    prompt:
      'Student request: run step 3 UX design. Map UX journey, flow, prototype, accessibility, interface state, responsive screen behavior, and layout.',
    agents: ['ux-director'],
  },
  {
    id: 'step-4',
    prompt:
      'Student request: run step 4 flow tree. Build the UX flow, screen inventory, responsive wireframes, prototype paths, and accessibility checkpoints.',
    agents: ['design-systems-architect', 'ux-director'],
  },
  {
    id: 'step-5',
    prompt:
      'Student request: run step 5 wireframe prototypes. Produce wireframes, prototype screens, component layout, responsive UI, design tokens, and visual assets.',
    agents: ['design-systems-architect', 'ux-director'],
  },
  {
    id: 'step-6',
    prompt:
      'Student request: run step 6 design system. Build design system tokens, theme, component library, Tailwind style guide, brand rules, and visual standards.',
    agents: ['design-systems-architect'],
  },
  {
    id: 'step-7',
    prompt:
      'Student request: run step 7 interface states. Define interface states, accessibility, responsive screens, design tokens, recovery states, and component behavior.',
    agents: ['design-systems-architect', 'ux-director'],
  },
  {
    id: 'step-8',
    prompt:
      'Student request: run step 8 technical spec. Write the technical spec, API design, backend services, endpoint contracts, database schema, and implementation blueprint.',
    agents: ['backend-engineer'],
  },
  {
    id: 'step-9',
    prompt:
      'Student request: run step 9 landing page. Create landing page strategy, copywriting, conversion funnel, CRO experiment, paid media ad creative, and campaign messaging.',
    agents: ['growth-engineer', 'paid-media-director'],
  },
  {
    id: 'step-10',
    prompt:
      'Student request: run step 10 feature breakdown. Break the feature into PRD requirements, sprint stories, acceptance criteria, and market-backed offer decisions.',
    agents: ['product-owner', 'venture-studio-partner'],
  },
  {
    id: 'step-11',
    prompt:
      'Student request: run step 11 PRD generation. Generate PRD requirements, BDD scenarios, acceptance criteria, sprint plan, and implementation-ready feature details.',
    agents: ['product-owner'],
  },
  {
    id: 'step-12',
    prompt:
      'Student request: run step 12 context engine. Build the runtime-native context engine, memory systems, prompt-engineering patterns, registry, hook, cascade, and agent context loading.',
    agents: ['harness-architect'],
  },
  {
    id: 'step-13',
    prompt:
      'Student request: run step 13 skillpack generator. Build the skillpack, skill registry, skill creator, skill writer, optimizer, hook, cascade, and Claude/Codex/Droid routing.',
    agents: ['harness-architect'],
  },
  {
    id: 'step-11.5',
    prompt: 'Student request: run step 11.5 task handoff. Build TASKS.json, execution claims, and the /next-task contract for the implementation backlog.',
    agents: [],
  },
  {
    id: 'step-14',
    prompt:
      'Student request: run step 14 agent runtime bootstrap. Build the agent runtime, harness, multi-agent orchestration, parallel spawning, skillpack, registry, hook, cascade, and Droid routing.',
    agents: ['compound-engineer', 'harness-architect'],
  },
  {
    id: 'step-15',
    prompt: 'Student request: run step 15 observability contract. Define per-feature instrumentation, logs, telemetry, metrics, and alerting acceptance criteria.',
    agents: [],
  },
];

const departmentPrompts = {
  engineering:
    'Invoke the engineering department. Need API backend auth webhook worker database schema migration, compound multi-agent orchestration parallel build system, devops CI CD pipeline deploy docker infra release secrets, dream ideation brainstorm strategy, frontend React Next UI CSS Tailwind screen layout responsive prototype wireframe, harness agent runtime skillpack registry hook cascade Claude Codex Droid, mobile iOS Android Expo Swift, observability logs telemetry alert monitoring, and x402 payment protocol machine payment.',
  security:
    'Invoke the security department. Need AI safety prompt injection LLM agent safety, compliance privacy GDPR SOC2 policy, infra container dependency supply chain secrets CI, mobile iOS Android secure storage, and web API XSS injection auth OWASP review.',
  legal:
    'Invoke the legal department. Need diplomatic relationship stakeholder politics timing, demand negotiate settle close, crisis board executive risk decision, due diligence forensics document review audit trail litigation hold, case law precedent cite research witness, and first draft agreement terms privacy policy NDA.',
  marketing:
    'Invoke the marketing department. Need CRO funnel conversion experiment retention pricing analytics, Manychat DM funnel automation subscriber flow, ads ad creative campaign paid media UGC, and direct-response copy.',
  content:
    'Invoke the content department. Need generate image AI image banner thumbnail video generation visual asset graphic hero, NotebookLM audio overview podcast video overview, transcribe transcript video research Instagram TikTok reel YouTube short-form media research.',
  finance:
    'Invoke the finance department. Need pricing, unit economics, cost, margin, runway, fundraising budget, valuation projection forecast, cash flow, raise, break even, profitability, and burn analysis.',
  ops:
    'Invoke the ops department. Need CI CD deploy infra pipeline secrets docker release, incident monitoring logs telemetry observability alert, QA test verification BDD regression coverage flaking, staging, and weekly review.',
  sales:
    'Invoke the sales department. Need sales discovery, outbound pipeline, proposal, close, negotiation, account follow up, prospect objections, retention churn onboarding customer success and NPS.',
  product:
    'Invoke the product department. Need PRD feature breakdown requirements sprint acceptance criteria, ideation market validation business model offer pricing mission, roadmap, and prioritization.',
  community:
    'Invoke the community department. Need customer success retention churn onboarding NPS support, Discord server channel moderation, Telegram bot forum topic group, engagement, broadcast, and cohort moderation.',
  trading:
    'Invoke the trading department. Need market data feed chart data pipeline OHLCV tick, strategy backtest base hit optimize Pine risk signal, broker, futures, and portfolio context.',
  design:
    'Invoke the design department. Need design system tokens theme component library Tailwind brand style guide wireframes, UX journey flow prototype accessibility interface state screen responsive layout, and visual direction.',
  qa:
    'Invoke the qa department. Need devil adversarial challenge risk critique, distill summary handoff knowledge lessons, reference standard benchmark QA pattern, loop repeat until clean evidence physical test acceptance, regression, and verification.',
};

function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

function walkFiles(root, predicate) {
  const out = new Map();
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const current = path.join(dir, entry.name);
      if (entry.isDirectory()) stack.push(current);
      if (entry.isFile() && predicate(entry.name)) {
        out.set(path.basename(entry.name, path.extname(entry.name)), path.relative(repoRoot, current));
      }
    }
  }
  return out;
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

function runHook(prompt) {
  const result = spawnSync(process.execPath, [hookPath], {
    input: JSON.stringify({
      hook_event_name: 'UserPromptSubmit',
      prompt,
      session_id: `ladder-resolution-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    }),
    encoding: 'utf8',
    env: {
      ...process.env,
      CLAUDE_PROJECT_DIR: repoRoot,
      PROMPT_STACK_AUGMENTER_DISABLE_DEDUP: '1',
    },
  });

  if (result.status !== 0) {
    throw new Error(`hook exited ${result.status}: ${result.stderr || result.stdout}`);
  }
  if (!result.stdout.trim()) {
    throw new Error('hook emitted no output');
  }
  const payload = JSON.parse(result.stdout);
  const context = payload.hookSpecificOutput?.additionalContext || '';
  if (!context.trim()) throw new Error('hook JSON contained empty additionalContext');
  return context;
}

function parseContext(context) {
  const department = context.match(/invoke \*\*([^*]+)\*\*/)?.[1] || null;
  const head = context.match(/with head @([A-Za-z0-9-]+)/)?.[1] || null;
  const headFile = context.match(/- Head file: `([^`]+)`/)?.[1] || null;
  const bench = [...context.matchAll(/@([A-Za-z0-9-]+)/g)].map((match) => match[1]);
  const benchFiles = {};
  for (const match of context.matchAll(/- @([A-Za-z0-9-]+) \(([^)]+)\)/g)) {
    benchFiles[match[1]] = match[2];
  }
  const skillFiles = {};
  for (const match of context.matchAll(/- `([^`]+)` (?:->|\u2192) `([^`]+)`/g)) {
    skillFiles[match[1]] = match[2];
  }
  return {
    department,
    head,
    headFile,
    agents: new Set(bench),
    benchFiles,
    skillFiles,
  };
}

function assertFile(relativePath, expectedRoots, label, failures) {
  const roots = Array.isArray(expectedRoots) ? expectedRoots : [expectedRoots];
  if (!relativePath) {
    failures.push(`${label} did not emit a file path`);
    return;
  }
  if (!roots.some((root) => relativePath.startsWith(root))) {
    failures.push(`${label} emitted path outside ${roots.join('|')}: ${relativePath}`);
    return;
  }
  if (!existsSync(path.join(repoRoot, relativePath))) {
    failures.push(`${label} emitted missing file: ${relativePath}`);
  }
}

function expectedSkillsFor(registry, department, agents, stepId = null) {
  const def = registry.departments[department];
  const skills = new Set(def.head_skills || []);
  for (const agent of agents) {
    for (const skill of def.agents?.[agent]?.skills || []) skills.add(skill);
  }
  if (stepId) {
    for (const skill of registry.steps?.[stepId]?.skills || []) skills.add(skill);
  }
  return [...skills];
}

function runCase({ kind, id, prompt, expectedDepartment, expectedHead, expectedAgents, expectedSkills }) {
  const failures = [];
  let context = '';
  let parsed = null;
  try {
    context = runHook(prompt);
    parsed = parseContext(context);
  } catch (error) {
    return {
      kind,
      id,
      ok: false,
      failures: [`hook failed: ${error.message}`],
      context,
    };
  }

  if (parsed.department !== expectedDepartment) {
    failures.push(`expected department ${expectedDepartment}, got ${parsed.department || '(none)'}`);
  }
  if (parsed.head !== expectedHead) {
    failures.push(`expected head @${expectedHead}, got @${parsed.head || '(none)'}`);
  }
  assertFile(parsed.headFile, '.claude/agents/', `${id} head @${expectedHead}`, failures);

  for (const agent of expectedAgents) {
    if (!parsed.agents.has(agent)) {
      failures.push(`expected context sub-agent @${agent} to fire`);
      continue;
    }
    assertFile(parsed.benchFiles[agent], '.claude/agents/', `${id} sub-agent @${agent}`, failures);
  }

  for (const skill of expectedSkills) {
    const file = parsed.skillFiles[skill];
    if (!file) {
      failures.push(`expected skill \`${skill}\` to load with a resolved file`);
      continue;
    }
    assertFile(file, skillRootPrefixes, `${id} skill \`${skill}\``, failures);
  }

  return {
    kind,
    id,
    ok: failures.length === 0,
    failures,
    context,
  };
}

const registry = readJson(registryPath);
const agentFiles = walkFiles(agentsRoot, (name) => name.endsWith('.md'));
const skillFiles = walkSkillSlugs();
const results = [];

for (const stepCase of ladderStepCases) {
  const step = registry.steps?.[stepCase.id];
  if (!step) {
    results.push({
      kind: 'step',
      id: stepCase.id,
      ok: false,
      failures: [`registry.steps.${stepCase.id} is missing`],
    });
    continue;
  }
  const department = step.department;
  const head = registry.departments?.[department]?.head;
  results.push(
    runCase({
      kind: 'step',
      id: stepCase.id,
      prompt: stepCase.prompt,
      expectedDepartment: department,
      expectedHead: head,
      expectedAgents: stepCase.agents,
      expectedSkills: expectedSkillsFor(registry, department, stepCase.agents, stepCase.id),
    })
  );
}

for (const [department, prompt] of Object.entries(departmentPrompts)) {
  const def = registry.departments?.[department];
  const agents = Object.keys(def?.agents || {});
  results.push(
    runCase({
      kind: 'department',
      id: department,
      prompt,
      expectedDepartment: department,
      expectedHead: def?.head,
      expectedAgents: agents,
      expectedSkills: expectedSkillsFor(registry, department, agents),
    })
  );
}

// Canon: Steps 0-15 plus conditional 1.5 and 11.5 → 18 numbered registry steps.
// Run Track steps (run-*) are legitimate registry keys validated by
// verify-run-track.mjs and validate-cascade.mjs, not this ladder.
const protectedStepKeys = Object.keys(registry.steps || {}).filter((key) => /^step-(?:1?[0-9](?:\.5)?)$/.test(key) && /^step-(?:0|1(?:\.5)?|[2-9]|1[0-5]|11\.5)$/.test(key));
const extraStepKeys = Object.keys(registry.steps || {}).filter(
  (key) => key !== 'step-verify.md' && !key.startsWith('run-') && !protectedStepKeys.includes(key)
);
if (protectedStepKeys.length !== 18) {
  results.push({
    kind: 'registry',
    id: 'steps',
    ok: false,
    failures: [`expected 18 ladder steps for 0-15 plus 1.5 and 11.5, found ${protectedStepKeys.length}: ${protectedStepKeys.join(', ')}`],
  });
}
if (extraStepKeys.length) {
  results.push({
    kind: 'registry',
    id: 'steps',
    ok: false,
    failures: [`unexpected registry.steps keys: ${extraStepKeys.join(', ')}`],
  });
}
if (Object.keys(departmentPrompts).length !== 13) {
  results.push({
    kind: 'registry',
    id: 'departments',
    ok: false,
    failures: [`test covers ${Object.keys(departmentPrompts).length} departments, expected 13`],
  });
}
// Every agent the registry references (heads + bench) must have an in-repo file;
// derived from the registry so the check never goes stale on roster growth.
const registryAgents = new Set();
for (const def of Object.values(registry.departments || {})) {
  if (def.head) registryAgents.add(def.head);
  for (const agent of Object.keys(def.agents || {})) registryAgents.add(agent);
}
const missingAgentFiles = [...registryAgents].filter((agent) => !agentFiles.has(agent));
if (missingAgentFiles.length) {
  results.push({
    kind: 'registry',
    id: 'agents',
    ok: false,
    failures: [`registry agents missing in-repo files: ${missingAgentFiles.join(', ')}`],
  });
}
if (skillFiles.size < Object.keys(registry.skills || {}).length) {
  results.push({
    kind: 'registry',
    id: 'skills',
    ok: false,
    failures: [`repo has ${skillFiles.size} skill files for ${Object.keys(registry.skills || {}).length} registry skills`],
  });
}

const passed = results.filter((result) => result.ok).length;
const total = results.length;
const failed = results.filter((result) => !result.ok);

console.log('ladder-resolution summary');
console.log(`- cases: ${passed}/${total} passed`);
console.log(`- steps: ${results.filter((result) => result.kind === 'step' && result.ok).length}/${ladderStepCases.length} passed`);
console.log(`- departments: ${results.filter((result) => result.kind === 'department' && result.ok).length}/${Object.keys(departmentPrompts).length} passed`);
console.log(`- agent files: ${agentFiles.size}`);
console.log(`- registry skills: ${Object.keys(registry.skills || {}).length}`);
console.log(`- in-repo skill files: ${skillFiles.size}`);

if (failed.length) {
  console.error('ladder-resolution failures');
  for (const result of failed) {
    console.error(`- ${result.kind}:${result.id}`);
    for (const failure of result.failures) console.error(`  - ${failure}`);
  }
  process.exit(1);
}

console.log('- physical hook: .claude/hooks/prompt-stack-augmenter.cjs');
console.log('- status: PASS');
