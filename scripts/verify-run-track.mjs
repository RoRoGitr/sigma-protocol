#!/usr/bin/env node
/**
 * Run Track acceptance gate — exit 0 only when scaffolding is 100% complete.
 * Usage: node scripts/verify-run-track.mjs [--wave=1|2|3|4] [--deep]
 */
import { copyFileSync, existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const failures = [];

const waveArg = process.argv.find((a) => a.startsWith('--wave='));
const wave = waveArg ? Number(waveArg.split('=')[1]) : 4;
const deep = process.argv.includes('--deep') || wave === 4;
if (![1, 2, 3, 4].includes(wave)) {
  console.error('Invalid --wave; use 1, 2, 3, or 4');
  process.exit(1);
}

function fail(msg) {
  failures.push(msg);
}

function mustExist(rel) {
  const abs = path.join(root, rel);
  if (!existsSync(abs)) fail(`missing: ${rel}`);
  return abs;
}

function skillResolved(slug) {
  return (
    existsSync(path.join(root, '.agents/skills', slug, 'SKILL.md')) ||
    existsSync(path.join(root, 'src/skills', slug, 'SKILL.md'))
  );
}

function gitTracked(relGlob) {
  const r = spawnSync('git', ['ls-files', relGlob], { cwd: root, encoding: 'utf8' });
  return (r.stdout || '').trim().split('\n').filter(Boolean);
}

const manifestPath = path.join(root, 'scripts/run-track-manifest.json');
let slugs = new Set();
if (!existsSync(manifestPath)) {
  fail('missing: scripts/run-track-manifest.json (run generate-run-track-steps.py)');
} else {
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  const waves = manifest.waves || {};
  for (let w = 1; w <= wave; w++) {
    const wdef = waves[String(w)];
    if (!wdef) {
      fail(`manifest waves missing wave ${w}`);
      continue;
    }
    for (const o of wdef.orchestrators || []) slugs.add(o);
    for (const s of manifest.steps || []) {
      if ((wdef.depts || []).includes(s.department)) slugs.add(s.slug);
    }
  }

  for (const slug of slugs) {
    mustExist(`steps/${slug}`);
    mustExist(`commands/${slug}.md`);
    mustExist(`.agents/skills/${slug}/SKILL.md`);
  }

  const atomByWave = {
    1: ['gtm-stack-setup', 'crm-pipeline-setup'],
    2: ['content-production-queue', 'funnel-instrumentation-setup', 'ab-test-spec'],
    3: ['weekly-review'],
    4: ['entity-formation-setup'],
  };
  const atoms = new Set(['gtm-stack-setup', 'crm-pipeline-setup']);
  for (let w = 2; w <= wave; w++) {
    for (const a of atomByWave[w] || []) atoms.add(a);
  }
  for (const skill of atoms) {
    if (!skillResolved(skill)) fail(`atom skill missing: ${skill}`);
  }

  const registry = JSON.parse(
    readFileSync(path.join(root, '.claude/lib/agent-skill-registry.json'), 'utf8'),
  );
  for (const slug of slugs) {
    const step = registry.steps?.[slug];
    if (!step) fail(`registry.steps missing ${slug}`);
    const cmd = step?.command?.replace(/^\.\//, '');
    if (cmd && !existsSync(path.join(root, cmd))) fail(`registry command missing on disk: ${cmd}`);
  }
  const orchestrators = new Set();
  for (let w = 1; w <= wave; w++) {
    for (const o of waves[String(w)]?.orchestrators || []) orchestrators.add(o);
  }
  for (const o of orchestrators) {
    if (!registry.skills?.[o]) fail(`registry.skills missing orchestrator ${o}`);
  }

  if (deep) {
    const skillAudit = spawnSync(
      'python3',
      [
        '-c',
        `import sys; sys.path.insert(0,'scripts'); from run_track_manifest import all_step_rows; 
rows=list(all_step_rows()); missing=[]
for row in rows:
  for s in row[4].split(','):
    s=s.strip()
    from pathlib import Path
    ok=Path('.agents/skills',s,'SKILL.md').exists() or Path('src/skills',s,'SKILL.md').exists()
    if not ok: missing.append(f"{row[0]}:{s}")
print('\\n'.join(missing))`,
      ],
      { cwd: root, encoding: 'utf8' },
    );
    for (const line of (skillAudit.stdout || '').trim().split('\n').filter(Boolean)) {
      fail(`skill binding unresolved: ${line}`);
    }

    const schema = JSON.parse(readFileSync(path.join(root, 'schemas/sigma-run-prd.schema.json'), 'utf8'));
    const depts = schema.properties?.department?.enum || [];
    for (const d of ['marketing', 'sales', 'content', 'growth', 'community', 'ops', 'finance', 'legal']) {
      if (!depts.includes(d)) fail(`schema department enum missing ${d}`);
    }

    const rt = JSON.parse(readFileSync(path.join(root, '.sigma/run-track.json'), 'utf8'));
    for (const key of [
      'content_after_step',
      'growth_after_step',
      'community_after_step',
      'ops_after_step',
      'finance_after_step',
      'legal_after_step',
    ]) {
      if (wave >= 2 && ['content_after_step', 'growth_after_step'].includes(key) && !rt.trigger?.[key]) {
        fail(`.sigma/run-track.json missing trigger.${key}`);
      }
      if (wave >= 3 && ['community_after_step', 'ops_after_step'].includes(key) && !rt.trigger?.[key]) {
        fail(`.sigma/run-track.json missing trigger.${key}`);
      }
      if (wave >= 4 && ['finance_after_step', 'legal_after_step'].includes(key) && !rt.trigger?.[key]) {
        fail(`.sigma/run-track.json missing trigger.${key}`);
      }
    }

    const m9 = readFileSync(path.join(root, 'steps/run-m-9-optimize-cadence'), 'utf8');
    if (!m9.includes('G3') && !m9.includes('run-growth')) {
      fail('M9 step missing G-track CRO boundary (W2-7)');
    }

    const trackedSteps = gitTracked('steps/run-*').length;
    const trackedCmds = gitTracked('commands/run-*.md').length;
    const expectedFiles = slugs.size;
    if (trackedSteps < expectedFiles) {
      fail(`git index: ${trackedSteps}/${expectedFiles} steps/run-* tracked (stage + commit waves 2–4)`);
    }
    if (trackedCmds < expectedFiles) {
      fail(`git index: ${trackedCmds}/${expectedFiles} commands/run-*.md tracked (stage + commit waves 2–4)`);
    }

    for (const rel of [
      'docs/run-track/RESEARCH-CONTENT-TEAM-ONBOARDING.md',
      'docs/run-track/RESEARCH-GROWTH-OPS-ONBOARDING.md',
      'docs/run-track/RESEARCH-COMMUNITY-MANAGER-ONBOARDING.md',
      'docs/run-track/RESEARCH-STARTUP-COO-OPS.md',
      'docs/run-track/RESEARCH-STARTUP-CFO-FINANCE-OPS.md',
      'docs/run-track/RESEARCH-STARTUP-GC-LEGAL-OPS.md',
    ]) {
      if (wave >= 2 && existsSync(path.join(root, rel))) {
        const text = readFileSync(path.join(root, rel), 'utf8');
        if (!text.includes('## Executive summary')) fail(`${rel} missing Executive summary`);
        if (!text.includes('Run step') && !text.includes('Run Track')) {
          fail(`${rel} missing Run step mapping section`);
        }
      }
    }
  }
}

const coreDocs = [
  'docs/run-track/README.md',
  'docs/run-track/RUN-TRACK-ROADMAP.md',
  'docs/run-track/RUN-TRACK-ACCEPTANCE.md',
  'docs/run-track/CLEAN-INSTALL.md',
  'docs/run-track/HOW-TO-USE.md',
  'docs/run-track/TOOL-STACK-MATRIX.md',
  'docs/run-track/SKILL-GAP-ANALYSIS.md',
  'docs/run-track/BUSINESS-MODEL-MODULES.md',
  'docs/run-track/BUSINESS-MODEL.example.json',
  'templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md',
  'schemas/sigma-run-prd.schema.json',
  '.sigma/run-track.json',
  'scripts/run_track_manifest.py',
  'scripts/run-track-manifest.json',
  'scripts/run-track-continue.py',
  'docs/run-track/RESEARCH-ENTITY-FORMATION.md',
];
for (const rel of coreDocs) mustExist(rel);

const researchByWave = {
  1: [
    'docs/run-track/RESEARCH-MARKETING-AGENCY-ONBOARDING.md',
    'docs/run-track/RESEARCH-SALES-TEAM-ONBOARDING.md',
  ],
  2: [
    'docs/run-track/RESEARCH-CONTENT-TEAM-ONBOARDING.md',
    'docs/run-track/RESEARCH-GROWTH-OPS-ONBOARDING.md',
  ],
  3: [
    'docs/run-track/RESEARCH-COMMUNITY-MANAGER-ONBOARDING.md',
    'docs/run-track/RESEARCH-STARTUP-COO-OPS.md',
  ],
  4: [
    'docs/run-track/RESEARCH-STARTUP-CFO-FINANCE-OPS.md',
    'docs/run-track/RESEARCH-STARTUP-GC-LEGAL-OPS.md',
    'docs/AFTER-STEP-15.md',
  ],
};
for (let w = 1; w <= wave; w++) {
  for (const rel of researchByWave[w] || []) mustExist(rel);
}

const deptsByWave = {
  1: ['marketing', 'sales'],
  2: ['content', 'growth'],
  3: ['community', 'ops'],
  4: ['finance', 'legal'],
};
const allDepts = [];
for (let w = 1; w <= wave; w++) allDepts.push(...deptsByWave[w]);

for (const dept of allDepts) {
  mustExist(`docs/run-track/${dept}/README.md`);
  const examplePath = `.sigma/backlogs/${dept}/prd.json.example`;
  mustExist(examplePath);
  const backlogPath = path.join(root, `.sigma/backlogs/${dept}/prd.json`);
  if (!existsSync(backlogPath)) {
    copyFileSync(path.join(root, examplePath), backlogPath);
  }
  try {
    const data = JSON.parse(readFileSync(backlogPath, 'utf8'));
    if (!Array.isArray(data.items)) fail(`${dept} backlog missing items array`);
  } catch (e) {
    fail(`${dept} backlog invalid JSON: ${e.message}`);
  }
}

for (const dept of allDepts) {
  const sync = spawnSync('python3', ['scripts/sigmahq-sync-run-track.py', '--dept', dept, '--dry-run'], {
    cwd: root,
    encoding: 'utf8',
  });
  if (sync.status !== 0) fail(`sigmahq-sync-run-track ${dept} dry-run failed: ${sync.stderr || sync.stdout}`);
}

const allSync = spawnSync('python3', ['scripts/sigmahq-sync-run-track.py', '--dept', 'all', '--dry-run'], {
  cwd: root,
  encoding: 'utf8',
});
if (allSync.status !== 0) fail(`sigmahq-sync-run-track --dept all failed: ${allSync.stderr || allSync.stdout}`);

if (deep) {
  const gen = spawnSync('python3', ['scripts/generate-run-track-steps.py'], { cwd: root, encoding: 'utf8' });
  if (gen.status !== 0) fail(`generate-run-track-steps.py failed: ${gen.stderr || gen.stdout}`);
  const drift = spawnSync('git', ['diff', '--name-only', 'steps/', 'commands/', '.agents/skills/run-'], {
    cwd: root,
    encoding: 'utf8',
  });
  const changed = (drift.stdout || '').trim().split('\n').filter(Boolean);
  if (changed.length) fail(`generator not idempotent vs git index: ${changed.length} files drift (${changed.slice(0, 3).join(', ')}…)`);
}

if (failures.length) {
  console.error(`verify-run-track FAILED (wave=${wave}${deep ? ', deep' : ''})`);
  for (const f of failures) console.error(`- ${f}`);
  process.exit(1);
}

const expectedSteps = { 1: 18, 2: 34, 3: 48, 4: 64 };
const expectedOrch = { 1: 2, 2: 4, 3: 6, 4: 8 };
console.log(`verify-run-track PASSED (100%) wave=${wave}${deep ? ' deep' : ''}`);
console.log(`- expected steps through wave ${wave}: ${expectedSteps[wave]}`);
console.log(`- expected orchestrators through wave ${wave}: ${expectedOrch[wave]}`);
console.log(`- slugs checked: ${slugs.size}`);
