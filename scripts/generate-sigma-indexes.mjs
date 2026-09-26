#!/usr/bin/env node

import fsp from 'node:fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

// --- Self-contained shims ---------------------------------------------------
// This script previously depended on the external `fs-extra` package and on
// `../cli/lib/catalog.js`. Neither ships with the template's install surface,
// so the script crashed on import and produced no indexes. The shims below
// reproduce exactly the small slice of behavior used here, with zero external
// dependencies, so the generator runs standalone and now includes src/skills
// and src/agents. If `cli/lib/catalog.js` is restored later, swap these back.
const fs = {
  async pathExists(p) {
    try {
      await fsp.access(p);
      return true;
    } catch {
      return false;
    }
  },
  readdir: (p, opts) => fsp.readdir(p, opts),
  ensureDir: (p) => fsp.mkdir(p, { recursive: true }),
  async writeJson(p, data, opts = {}) {
    const spaces = opts.spaces ?? 0;
    await fsp.writeFile(p, JSON.stringify(data, null, spaces) + '\n');
  },
};

// Department-aware taxonomy. `sales` is a first-class department alongside the
// existing categories; `marketing` keeps the legacy marketing skills (incl.
// retention-engine and hormozi-frameworks).
const SIGMA_CATEGORIES = [
  'steps',
  'orchestration',
  'deploy',
  'ops',
  'audit',
  'platform',
  'sales',
  'marketing',
  'deprecated',
  'dev',
];

const SALES_SKILLS = new Set([
  'objection-handling',
  'high-ticket-closing',
  'pricing-psychology',
  'sales-identity',
  'content-to-client',
  'dm-funnel',
  'follow-up-system',
  'discovery',
  'lead-qualification',
  'outreach-sequencing',
  'icp-definition',
]);

function categorizeCodexSkillName(name) {
  if (SALES_SKILLS.has(name)) return 'sales';
  if (/^[0-9][0-9]-/.test(name)) return 'marketing';
  if (
    name === 'retention-engine' ||
    name === 'hormozi-frameworks' ||
    /^(brand-voice|direct-response-copy|launch-strategy|marketing-|social-content|video-hooks|ai-image-prompt|ai-video-prompt|notebooklm-format|community-analytics)/.test(name)
  ) {
    return 'marketing';
  }
  return 'dev';
}

function categorizeAgentName() {
  return 'dev';
}

function categorizeCommandName(_name, root) {
  if (SIGMA_CATEGORIES.includes(root)) return root;
  return 'dev';
}
// ---------------------------------------------------------------------------

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const indexesDir = path.join(projectRoot, '.sigma', 'indexes');

const COMMAND_ROOTS = [
  'steps',
  'ops',
  'audit',
  'dev',
  'deploy',
  'marketing',
];

function statusFromName(name) {
  return /^(sigma-|cleanup-repo$|step-5a|step-5b|step-11a|step-11b|ralph-)/.test(name)
    ? 'deprecated'
    : 'active';
}

function ensurePosix(filePath) {
  return filePath.split(path.sep).join('/');
}

async function collectFiles(rootPath, predicate) {
  if (!(await fs.pathExists(rootPath))) return [];

  const out = [];
  async function walk(current) {
    const entries = await fs.readdir(current, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.name.startsWith('.')) continue;
      const fullPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        await walk(fullPath);
        continue;
      }
      if (predicate(fullPath, entry.name)) out.push(fullPath);
    }
  }

  await walk(rootPath);
  return out.sort();
}

function buildCommandGeneratedPaths(category, relativePath, name) {
  const suffix = relativePath.replace(/^(steps|ops|audit|dev|deploy|marketing)\//, '').replace(/\.md$/, '');
  const docPath = `${suffix}.md`;
  return [
    `commands/${docPath}`,
    `.codex/skills/${category}/${name}/SKILL.md`,
  ];
}

function buildSkillGeneratedPaths(_category, name) {
  return [
    `.agents/skills/${name}/SKILL.md`,
    `.codex/skills/${name}/SKILL.md`,
  ];
}

function buildAgentGeneratedPaths(name) {
  return ['AGENTS.md'];
}

async function existingGeneratedPaths(paths) {
  const resolved = await Promise.all(
    paths.map(async (relativePath) => {
      const exists = await fs.pathExists(path.join(projectRoot, relativePath));
      return exists ? relativePath : null;
    })
  );
  return resolved.filter(Boolean);
}

async function buildCommandIndex() {
  const items = [];

  for (const root of COMMAND_ROOTS) {
    const rootPath = path.join(projectRoot, root);
    const files = await collectFiles(rootPath, (filePath, entryName) => {
      if (entryName === 'README.md' || entryName === 'README') return false;
      if (root === 'steps' && path.dirname(filePath) !== rootPath) return false;
      return true;
    });

    for (const filePath of files) {
      const relativePath = ensurePosix(path.relative(projectRoot, filePath));
      const rawName = path.basename(filePath);
      const name = rawName.replace(/\.md$/, '');
      const category = categorizeCommandName(name, root);
      items.push({
        id: relativePath.replace(/\.md$/, ''),
        name,
        category,
        status: statusFromName(name),
        canonicalSourcePath: relativePath,
        generatedPaths: await existingGeneratedPaths(buildCommandGeneratedPaths(category, relativePath, name)),
      });
    }
  }

  const names = new Set(items.map((item) => item.name));
  const commandsRoot = path.join(projectRoot, 'commands');
  const authoredCommands = await collectFiles(commandsRoot, (filePath, name) =>
    path.dirname(filePath) === commandsRoot && name.endsWith('.md') && name !== 'README.md');
  for (const filePath of authoredCommands) {
    const name = path.basename(filePath, '.md');
    if (names.has(name)) continue;
    const relativePath = ensurePosix(path.relative(projectRoot, filePath));
    items.push({ id: relativePath.replace(/\.md$/, ''), name, category: categorizeCommandName(name, 'commands'),
      status: statusFromName(name), canonicalSourcePath: relativePath, generatedPaths: [] });
    names.add(name);
  }
  return items.sort((a, b) => a.id.localeCompare(b.id));
}

async function buildSkillIndex() {
  const sourceRoot = path.join(projectRoot, 'src', 'skills');
  const bundledRoot = path.join(projectRoot, '.agents', 'skills');
  const sourceFiles = await collectFiles(sourceRoot, (filePath, entryName) => entryName === 'SKILL.md'
    || (path.dirname(filePath) === sourceRoot && entryName.endsWith('.md') && entryName !== 'README.md'));
  const bundledFiles = await collectFiles(bundledRoot, (_filePath, entryName) => entryName === 'SKILL.md');
  const itemsByName = new Map();

  for (const files of [sourceFiles, bundledFiles]) {
    const seen = new Map();
    for (const filePath of files) {
      const name = path.basename(filePath) === 'SKILL.md' ? path.basename(path.dirname(filePath)) : path.basename(filePath, '.md');
      if (seen.has(name)) throw new Error(`Duplicate skill identity '${name}': ${seen.get(name)} and ${filePath}`);
      seen.set(name, filePath);
    }
  }

  for (const filePath of sourceFiles) {
    const relativePath = ensurePosix(path.relative(projectRoot, filePath));
    const name = path.basename(filePath) === 'SKILL.md'
      ? path.basename(path.dirname(filePath))
      : path.basename(filePath, '.md');
    const relativeToSource = ensurePosix(path.relative(sourceRoot, filePath));
    const pathParts = relativeToSource.split('/');
    const sourceCategory = path.basename(filePath) === 'SKILL.md' && pathParts.length >= 3
      ? pathParts[0]
      : null;
    const category = sourceCategory && SIGMA_CATEGORIES.includes(sourceCategory)
      ? sourceCategory
      : categorizeCodexSkillName(name);
    itemsByName.set(name, {
      id: `skills/${name}`,
      name,
      category,
      status: statusFromName(name),
      canonicalSourcePath: relativePath,
      generatedPaths: await existingGeneratedPaths(buildSkillGeneratedPaths(category, name)),
    });
  }

  for (const filePath of bundledFiles) {
    const name = path.basename(path.dirname(filePath));
    if (itemsByName.has(name)) continue;
    const relativePath = ensurePosix(path.relative(projectRoot, filePath));
    itemsByName.set(name, {
      id: `skills/${name}`,
      name,
      category: categorizeCodexSkillName(name),
      status: statusFromName(name),
      canonicalSourcePath: relativePath,
      generatedPaths: [],
    });
  }

  return [...itemsByName.values()].sort((a, b) => a.id.localeCompare(b.id));
}

async function buildAgentIndex() {
  const sourceRoot = path.join(projectRoot, 'src', 'agents');
  const files = await collectFiles(sourceRoot, (_filePath, entryName) => entryName.endsWith('.md'));
  const items = [];
  for (const filePath of files) {
    const relativePath = ensurePosix(path.relative(projectRoot, filePath));
    const name = path.basename(filePath, '.md');
    const relativeToSource = ensurePosix(path.relative(sourceRoot, filePath));
    const pathParts = relativeToSource.split('/');
    const sourceCategory = pathParts.length >= 2 ? pathParts[0] : null;
    items.push({
      id: `agents/${name}`,
      name,
      category: sourceCategory && SIGMA_CATEGORIES.includes(sourceCategory)
        ? sourceCategory
        : categorizeAgentName(name),
      status: 'active',
      canonicalSourcePath: relativePath,
      generatedPaths: await existingGeneratedPaths(buildAgentGeneratedPaths(name)),
    });
  }

  return items.sort((a, b) => a.id.localeCompare(b.id));
}

async function writeIndex(fileName, items) {
  await fs.ensureDir(indexesDir);
  const payload = {
    version: 1,
    generatedAt: new Date().toISOString(),
    taxonomy: SIGMA_CATEGORIES,
    count: items.length,
    items,
  };
  await fs.writeJson(path.join(indexesDir, fileName), payload, { spaces: 2 });
}

// --- Runtime catalog: .claude/skills/INDEX.json -----------------------------
// The runtime skill-discovery catalog consumed by onboarding/init flows. It
// indexes the ACTUAL generated Claude skills (not the canonical map above) so
// agents can discover available behaviors at runtime.
function parseFrontmatter(text) {
  if (!text.startsWith('---')) return {};
  const end = text.indexOf('\n---', 3);
  if (end === -1) return {};
  const block = text.slice(3, end).split('\n');
  const fm = {};
  let key = null;
  let listVals = null;
  for (const line of block) {
    const listItem = line.match(/^\s*-\s+(.*)$/);
    if (listItem && key && listVals) {
      listVals.push(listItem[1].replace(/^["']|["']$/g, '').trim());
      continue;
    }
    const kv = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!kv) continue;
    if (listVals && key) {
      fm[key] = listVals;
      listVals = null;
    }
    key = kv[1];
    let val = kv[2].trim();
    if (val === '') {
      listVals = [];
      fm[key] = listVals;
    } else if (val.startsWith('[') && val.endsWith(']')) {
      fm[key] = val.slice(1, -1).split(',').map((s) => s.replace(/^["']|["']$/g, '').trim()).filter(Boolean);
      listVals = null;
    } else {
      fm[key] = val.replace(/^["']|["']$/g, '');
      listVals = null;
    }
  }
  if (listVals && key) fm[key] = listVals;
  return fm;
}

async function buildClaudeSkillsCatalog() {
  const skillsRoot = path.join(projectRoot, '.claude', 'skills');
  const files = await collectFiles(skillsRoot, (_p, name) => name === 'SKILL.md');
  const skills = [];
  const byDept = {};
  for (const filePath of files) {
    const rel = ensurePosix(path.relative(projectRoot, filePath));
    const parts = ensurePosix(path.relative(skillsRoot, filePath)).split('/');
    const text = await fsp.readFile(filePath, 'utf8');
    const fm = parseFrontmatter(text);
    const name = fm.name || (parts.length >= 2 ? parts[parts.length - 2] : 'unknown');
    const department = fm.department || (parts.length >= 3 ? parts[0] : 'core');
    const triggers = Array.isArray(fm.triggers) ? fm.triggers : [];
    byDept[department] = (byDept[department] || 0) + 1;
    skills.push({
      name,
      department,
      path: rel,
      description: fm.description || '',
      triggers,
    });
  }
  skills.sort((a, b) => a.name.localeCompare(b.name));
  return {
    version: '1.0.0',
    generated: new Date().toISOString().slice(0, 10),
    stats: { total: skills.length, by_department: byDept },
    skills,
  };
}

async function main() {
  const commands = await buildCommandIndex();
  const skills = await buildSkillIndex();
  const agents = await buildAgentIndex();
  const catalog = await buildClaudeSkillsCatalog();
  await writeIndex('commands-index.json', commands);
  await writeIndex('skills-index.json', skills);
  await writeIndex('agents-index.json', agents);
  await fs.ensureDir(path.join(projectRoot, '.claude', 'skills'));
  await fs.writeJson(path.join(projectRoot, '.claude', 'skills', 'INDEX.json'), catalog, { spaces: 2 });
  console.log('Generated .sigma/indexes/{commands,skills,agents}-index.json + .claude/skills/INDEX.json');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
