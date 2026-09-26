#!/usr/bin/env node

import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'sigma-skill-catalog-'));

function write(relativePath, content) {
  const file = path.join(fixture, relativePath);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);
}

function run(script, args = []) {
  return spawnSync(process.execPath, [path.join(fixture, 'scripts', script), ...args], {
    cwd: fixture,
    encoding: 'utf8',
  });
}

try {
  for (const script of ['generate-sigma-indexes.mjs', 'validate-skills.mjs']) {
    fs.mkdirSync(path.join(fixture, 'scripts'), { recursive: true });
    fs.copyFileSync(path.join(repoRoot, 'scripts', script), path.join(fixture, 'scripts', script));
  }
  write('scripts/skills-allowlist.json', '{"external_skills":[]}\n');
  write('src/skills/steps/nested/SKILL.md', '---\nname: nested\ndescription: Nested authored skill.\n---\n');
  write('src/skills/source-wins/SKILL.md', '---\nname: source-wins\ndescription: Authored source wins.\n---\n');
  write('src/skills/steps/nested/guide.md', '# Not a skill\n');
  write('.agents/skills/source-wins/SKILL.md', '---\nname: source-wins\ndescription: Bundled duplicate.\n---\n');
  write('.agents/skills/bundled-only/SKILL.md', '---\nname: bundled-only\ndescription: Bundled only skill.\n---\n');
  write('src/agents/dev/test-agent.md', '---\nskills:\n  - nested\n---\n');
  write('steps/test-step.md', '# test\n');
  write('steps/_partials/not-a-command.md', '# Shared fragment\n');
  write('commands/test-step.md', '# Rendered duplicate\n');
  write('commands/authored-command.md', '# Authored command\n');

  const generated = run('generate-sigma-indexes.mjs');
  assert.equal(generated.status, 0, generated.stderr);
  const skills = JSON.parse(fs.readFileSync(path.join(fixture, '.sigma/indexes/skills-index.json'), 'utf8'));
  assert.equal(skills.count, 3);
  assert.deepEqual(skills.items.map((item) => item.name), ['bundled-only', 'nested', 'source-wins']);
  assert.equal(skills.items.find((item) => item.name === 'nested').category, 'steps');
  assert.equal(skills.items.find((item) => item.name === 'source-wins').canonicalSourcePath, 'src/skills/source-wins/SKILL.md');
  const commands = JSON.parse(fs.readFileSync(path.join(fixture, '.sigma/indexes/commands-index.json'), 'utf8'));
  assert.equal(commands.count, 2);
  assert.ok(!commands.items.some((item) => item.canonicalSourcePath.includes('_partials')));
  assert.equal(commands.items.find((item) => item.name === 'test-step').canonicalSourcePath, 'steps/test-step.md');
  assert.equal(JSON.parse(fs.readFileSync(path.join(fixture, '.sigma/indexes/agents-index.json'), 'utf8')).count, 1);

  const valid = run('validate-skills.mjs');
  assert.equal(valid.status, 0, valid.stderr);
  write('fake-home/.claude/skills/nested/SKILL.md', fs.readFileSync(path.join(fixture, 'src/skills/steps/nested/SKILL.md'), 'utf8'));
  write('fake-home/.claude/skills/source-wins/SKILL.md', fs.readFileSync(path.join(fixture, 'src/skills/source-wins/SKILL.md'), 'utf8'));
  write('scripts/check-sync.mjs', `import os from 'node:os';\nos.homedir = () => ${JSON.stringify(path.join(fixture, 'fake-home'))};\nawait import('./validate-skills.mjs');\n`);
  const synced = run('check-sync.mjs', ['--sync', '--strict']);
  assert.equal(synced.status, 0, synced.stderr);
  write('fake-home/.claude/skills/nested/SKILL.md', 'different content');
  const drifted = run('check-sync.mjs', ['--sync', '--strict']);
  assert.equal(drifted.status, 1);
  assert.match(drifted.stdout + drifted.stderr, /nested.*DRIFT/);
  write('src/skills/legacy-flat.md', '---\nname: legacy-flat\ndescription: Legacy authored skill.\n---\n');
  assert.equal(run('generate-sigma-indexes.mjs').status, 0);
  const withLegacy = JSON.parse(fs.readFileSync(path.join(fixture, '.sigma/indexes/skills-index.json'), 'utf8'));
  assert.equal(withLegacy.count, 4);
  assert.equal(run('validate-skills.mjs').status, 0);
  const beforeCollision = fs.readFileSync(path.join(fixture, '.sigma/indexes/skills-index.json'), 'utf8');
  write('src/skills/ops/nested/SKILL.md', '---\nname: nested\ndescription: Collision.\n---\n');
  assert.equal(run('generate-sigma-indexes.mjs').status, 1);
  assert.equal(run('validate-skills.mjs').status, 1);
  assert.equal(fs.readFileSync(path.join(fixture, '.sigma/indexes/skills-index.json'), 'utf8'), beforeCollision);
  fs.rmSync(path.join(fixture, 'src/skills/ops'), { recursive: true });
  write('.agents/skills/bundled-only/SKILL.md', '---\nname: bundled-only\n---\n');
  const invalid = run('validate-skills.mjs');
  assert.equal(invalid.status, 1);
  assert.match(invalid.stderr, /bundled-only\/SKILL\.md.*missing or empty frontmatter description/);
  for (const emptyDescription of ['""', "''", '\nallowed-tools: Read', '|']) {
    write('.agents/skills/bundled-only/SKILL.md', `---\nname: bundled-only\ndescription: ${emptyDescription}\n---\n`);
    assert.equal(run('validate-skills.mjs').status, 1, `accepted empty description: ${emptyDescription}`);
  }
  write('.agents/skills/bundled-only/SKILL.md', '---\nname: bundled-only\ndescription: >-\n  Bundled skill with a folded description.\n---\n');
  assert.equal(run('validate-skills.mjs').status, 0);
  console.log('OK: skill catalog indexes recursive authored and bundled skills with source precedence; validator rejects invalid bundled metadata.');
} finally {
  fs.rmSync(fixture, { recursive: true, force: true });
}
