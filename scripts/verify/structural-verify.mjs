#!/usr/bin/env node
// structural-verify.mjs — flow-tree structural integrity gate.
//
// Validates a flow-tree JSON document against `schemas/flow-tree.schema.json`
// using two layers of checking:
//
//   Layer A  — hand-rolled subset schema check
//              Required keys, enum membership, id pattern conformance, date format.
//              Zero external dependencies: hand-rolled per validate-skills.mjs style.
//
//   Layer B  — referential completeness
//              screens[].moduleId ∈ modules[].id
//              modules[].screens[] ∈ screens[].id
//              flows[].screens[] ∈ screens[].id
//              modules[].dependsOn[] ∈ module ids (no self-ref)
//              Cycle detection in module dependency graph (DFS)
//              Unique screen / module / flow ids
//              meta.totalScreens == screens.length (when present)
//              Every screen has a non-empty moduleId
//
//   Advisory — PRD-owner and markdown parity checks (absent artifact = warn only).
//              Promoted to errors under --strict.
//
// Usage:
//   node scripts/verify/structural-verify.mjs [--file <path>] [--json] [--strict] [--allow-missing]
//
//   --file <path>   : path to flow-tree JSON (default: product/flows/flow-tree.json)
//   --json          : machine output { ok, errors: [], warnings: [] }
//   --strict        : promote advisory warnings to hard errors
//   --allow-missing : missing input file → exit 0 with advisory (gate-safe)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

// ── Argument parsing ────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2);

let filePath = path.join(REPO_ROOT, 'product', 'flows', 'flow-tree.json');
let jsonMode = false;
let strict = false;
let allowMissing = false;

for (let i = 0; i < rawArgs.length; i++) {
  const a = rawArgs[i];
  if (a === '--file') {
    const next = rawArgs[i + 1];
    if (!next || next.startsWith('--')) {
      console.error('structural-verify: --file requires a path argument');
      process.exit(1);
    }
    filePath = path.resolve(next);
    i++;
  } else if (a === '--json') {
    jsonMode = true;
  } else if (a === '--strict') {
    strict = true;
  } else if (a === '--allow-missing') {
    allowMissing = true;
  } else {
    console.error(`structural-verify: unknown argument '${a}'`);
    process.exit(1);
  }
}

// ── Error / warning accumulators ────────────────────────────────────────────

const errors = [];
const warnings = [];

// Counts populated after Layer B runs; used by report() which may be called
// from early-exit paths before the id Sets are initialized.
let _mCount = 0;
let _sCount = 0;
let _fCount = 0;

function err(msg) { errors.push(msg); }
function warn(msg) { warnings.push(msg); }
function advisory(msg) {
  if (strict) {
    err(msg);
  } else {
    warn(`[advisory] ${msg}`);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

// Matches schema pattern ^[a-z][a-zA-Z0-9]*$ (camelCase module id)
const MODULE_ID_PATTERN = /^[a-z][a-zA-Z0-9]*$/;

// Matches schema pattern ^[a-z][a-z0-9-]*$ (kebab-case screen id)
const SCREEN_ID_PATTERN = /^[a-z][a-z0-9-]*$/;

// Matches ISO date format YYYY-MM-DD
const DATE_PATTERN = /^\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])$/;

const PLATFORM_ENUM = ['web', 'mobile', 'both'];
const PRIORITY_ENUM = ['P0', 'P1', 'P2', 'P3'];
const COMPLEXITY_ENUM = ['Simple', 'Medium', 'Complex'];

function isString(v) { return typeof v === 'string'; }
function isBoolean(v) { return typeof v === 'boolean'; }
function isStringArray(v) { return Array.isArray(v) && v.every(isString); }

// ── File loading ─────────────────────────────────────────────────────────────

if (!fs.existsSync(filePath)) {
  if (allowMissing) {
    advisory(`flow-tree file not found at '${filePath}' — skipped (--allow-missing)`);
    report();
    process.exit(0);
  }
  console.error(`structural-verify: file not found: ${filePath}`);
  process.exit(1);
}

let doc;
try {
  const raw = fs.readFileSync(filePath, 'utf8');
  doc = JSON.parse(raw);
} catch (e) {
  err(`JSON parse error: ${e.message}`);
  report();
  process.exit(1);
}

// ── Layer A: hand-rolled subset schema check ─────────────────────────────────

// Top-level required keys: $schema, meta, modules, screens
for (const key of ['$schema', 'meta', 'modules', 'screens']) {
  if (!(key in doc)) {
    err(`missing required top-level key: '${key}'`);
  }
}

// meta object
if (doc.meta && typeof doc.meta === 'object') {
  const meta = doc.meta;
  for (const key of ['appName', 'platform', 'generatedAt']) {
    if (!(key in meta)) {
      err(`meta: missing required key '${key}'`);
    }
  }
  if ('appName' in meta && !isString(meta.appName)) {
    err(`meta.appName must be a string`);
  }
  if ('platform' in meta) {
    if (!PLATFORM_ENUM.includes(meta.platform)) {
      err(`meta.platform '${meta.platform}' is not one of [${PLATFORM_ENUM.join(', ')}]`);
    }
  }
  if ('generatedAt' in meta) {
    if (!isString(meta.generatedAt) || !DATE_PATTERN.test(meta.generatedAt)) {
      err(`meta.generatedAt '${meta.generatedAt}' is not a valid YYYY-MM-DD date`);
    }
  }
  if ('totalScreens' in meta) {
    if (!Number.isInteger(meta.totalScreens) || meta.totalScreens < 1) {
      err(`meta.totalScreens must be an integer >= 1`);
    }
  }
  if ('uiProfile' in meta && meta.uiProfile !== null && typeof meta.uiProfile === 'object') {
    if (!('id' in meta.uiProfile)) {
      err(`meta.uiProfile: missing required key 'id'`);
    }
    if ('id' in meta.uiProfile && !isString(meta.uiProfile.id)) {
      err(`meta.uiProfile.id must be a string`);
    }
  }
} else if ('meta' in doc) {
  err(`meta must be an object`);
}

// modules array
if ('modules' in doc) {
  if (!Array.isArray(doc.modules)) {
    err(`modules must be an array`);
  } else {
    doc.modules.forEach((mod, i) => {
      const loc = `modules[${i}]`;
      if (typeof mod !== 'object' || mod === null) {
        err(`${loc} must be an object`);
        return;
      }
      for (const key of ['id', 'name', 'platform', 'required']) {
        if (!(key in mod)) {
          err(`${loc}: missing required key '${key}'`);
        }
      }
      if ('id' in mod) {
        if (!isString(mod.id)) {
          err(`${loc}.id must be a string`);
        } else if (!MODULE_ID_PATTERN.test(mod.id)) {
          err(`${loc}.id '${mod.id}' does not match pattern ^[a-z][a-zA-Z0-9]*$ (camelCase)`);
        }
      }
      if ('name' in mod && !isString(mod.name)) {
        err(`${loc}.name must be a string`);
      }
      if ('platform' in mod && !PLATFORM_ENUM.includes(mod.platform)) {
        err(`${loc}.platform '${mod.platform}' is not one of [${PLATFORM_ENUM.join(', ')}]`);
      }
      if ('required' in mod && !isBoolean(mod.required)) {
        err(`${loc}.required must be a boolean`);
      }
      if ('screens' in mod && !isStringArray(mod.screens)) {
        err(`${loc}.screens must be an array of strings`);
      }
      if ('dependsOn' in mod && !isStringArray(mod.dependsOn)) {
        err(`${loc}.dependsOn must be an array of strings`);
      }
      if ('routes' in mod && !isStringArray(mod.routes)) {
        err(`${loc}.routes must be an array of strings`);
      }
      if ('envVars' in mod && !isStringArray(mod.envVars)) {
        err(`${loc}.envVars must be an array of strings`);
      }
    });
  }
}

// screens array
if ('screens' in doc) {
  if (!Array.isArray(doc.screens)) {
    err(`screens must be an array`);
  } else {
    doc.screens.forEach((scr, i) => {
      const loc = `screens[${i}]`;
      if (typeof scr !== 'object' || scr === null) {
        err(`${loc} must be an object`);
        return;
      }
      for (const key of ['id', 'title', 'moduleId', 'priority']) {
        if (!(key in scr)) {
          err(`${loc}: missing required key '${key}'`);
        }
      }
      if ('id' in scr) {
        if (!isString(scr.id)) {
          err(`${loc}.id must be a string`);
        } else if (!SCREEN_ID_PATTERN.test(scr.id)) {
          err(`${loc}.id '${scr.id}' does not match pattern ^[a-z][a-z0-9-]*$ (kebab-case)`);
        }
      }
      if ('title' in scr && !isString(scr.title)) {
        err(`${loc}.title must be a string`);
      }
      if ('moduleId' in scr) {
        if (!isString(scr.moduleId) || scr.moduleId.trim() === '') {
          err(`${loc}.moduleId must be a non-empty string`);
        }
      }
      if ('priority' in scr && !PRIORITY_ENUM.includes(scr.priority)) {
        err(`${loc}.priority '${scr.priority}' is not one of [${PRIORITY_ENUM.join(', ')}]`);
      }
      if ('platform' in scr && !PLATFORM_ENUM.includes(scr.platform)) {
        err(`${loc}.platform '${scr.platform}' is not one of [${PLATFORM_ENUM.join(', ')}]`);
      }
      if ('complexity' in scr && !COMPLEXITY_ENUM.includes(scr.complexity)) {
        err(`${loc}.complexity '${scr.complexity}' is not one of [${COMPLEXITY_ENUM.join(', ')}]`);
      }
      if ('animationComplexity' in scr && !COMPLEXITY_ENUM.includes(scr.animationComplexity)) {
        err(`${loc}.animationComplexity '${scr.animationComplexity}' is not one of [${COMPLEXITY_ENUM.join(', ')}]`);
      }
    });
  }
}

// flows array (optional)
if ('flows' in doc) {
  if (!Array.isArray(doc.flows)) {
    err(`flows must be an array`);
  } else {
    doc.flows.forEach((flow, i) => {
      const loc = `flows[${i}]`;
      if (typeof flow !== 'object' || flow === null) {
        err(`${loc} must be an object`);
        return;
      }
      for (const key of ['id', 'name', 'screens']) {
        if (!(key in flow)) {
          err(`${loc}: missing required key '${key}'`);
        }
      }
      if ('id' in flow && !isString(flow.id)) {
        err(`${loc}.id must be a string`);
      }
      if ('name' in flow && !isString(flow.name)) {
        err(`${loc}.name must be a string`);
      }
      if ('screens' in flow && !isStringArray(flow.screens)) {
        err(`${loc}.screens must be an array of strings`);
      }
    });
  }
}

// ── Layer B: referential completeness (O(n) id Sets) ─────────────────────────

const modules = Array.isArray(doc.modules) ? doc.modules : [];
const screens = Array.isArray(doc.screens) ? doc.screens : [];
const flows = Array.isArray(doc.flows) ? doc.flows : [];

// Build id sets (O(n)) — duplicate detection runs during construction
const moduleIds = new Set();
const screenIds = new Set();
const flowIds = new Set();

for (const mod of modules) {
  if (!isString(mod.id)) continue;
  if (moduleIds.has(mod.id)) {
    err(`duplicate module id: '${mod.id}'`);
  } else {
    moduleIds.add(mod.id);
  }
}

for (const scr of screens) {
  if (!isString(scr.id)) continue;
  if (screenIds.has(scr.id)) {
    err(`duplicate screen id: '${scr.id}'`);
  } else {
    screenIds.add(scr.id);
  }
}

for (const flow of flows) {
  if (!isString(flow.id)) continue;
  if (flowIds.has(flow.id)) {
    err(`duplicate flow id: '${flow.id}'`);
  } else {
    flowIds.add(flow.id);
  }
}

// Expose counts to report() which may be called from early-exit paths
_mCount = moduleIds.size;
_sCount = screenIds.size;
_fCount = flowIds.size;

// screens[].moduleId ∈ modules[].id  AND  every screen has non-empty owner
for (const scr of screens) {
  if (!isString(scr.moduleId) || scr.moduleId.trim() === '') {
    // Already caught in Layer A — skip here to avoid double-error
    continue;
  }
  if (!moduleIds.has(scr.moduleId)) {
    err(`screen '${scr.id}' references moduleId '${scr.moduleId}' which does not exist in modules[]`);
  }
}

// modules[].screens[] ∈ screens[].id
for (const mod of modules) {
  if (!isString(mod.id)) continue;
  const modScreens = Array.isArray(mod.screens) ? mod.screens : [];
  for (const sid of modScreens) {
    if (!screenIds.has(sid)) {
      err(`module '${mod.id}': screens[] references '${sid}' which does not exist in screens[]`);
    }
  }
}

// flows[].screens[] ∈ screens[].id
for (const flow of flows) {
  if (!isString(flow.id)) continue;
  const flowScreens = Array.isArray(flow.screens) ? flow.screens : [];
  for (const sid of flowScreens) {
    if (!screenIds.has(sid)) {
      err(`flow '${flow.id}': screens[] references '${sid}' which does not exist in screens[]`);
    }
  }
}

// modules[].dependsOn[] ∈ module ids  +  no self-reference
for (const mod of modules) {
  if (!isString(mod.id)) continue;
  const deps = Array.isArray(mod.dependsOn) ? mod.dependsOn : [];
  for (const dep of deps) {
    if (dep === mod.id) {
      err(`module '${mod.id}': dependsOn[] contains self-reference`);
    } else if (!moduleIds.has(dep)) {
      err(`module '${mod.id}': dependsOn[] references '${dep}' which does not exist in modules[]`);
    }
  }
}

// Cycle detection in module dependency graph (DFS with three-colour marking)
// 0 = unvisited, 1 = in stack, 2 = done
{
  // Build adjacency list
  const adj = new Map();
  for (const mod of modules) {
    if (!isString(mod.id)) continue;
    adj.set(mod.id, Array.isArray(mod.dependsOn) ? mod.dependsOn.filter(d => moduleIds.has(d)) : []);
  }

  const colour = new Map();
  for (const id of moduleIds) colour.set(id, 0);

  function dfs(node, stack) {
    colour.set(node, 1);
    stack.push(node);
    for (const dep of (adj.get(node) || [])) {
      const c = colour.get(dep);
      if (c === 1) {
        // Found a cycle — reconstruct the loop
        const cycleStart = stack.indexOf(dep);
        const cycle = stack.slice(cycleStart).concat(dep);
        err(`dependency cycle detected in modules: ${cycle.join(' -> ')}`);
        return;
      }
      if (c === 0) {
        dfs(dep, stack);
      }
    }
    stack.pop();
    colour.set(node, 2);
  }

  for (const id of moduleIds) {
    if (colour.get(id) === 0) {
      dfs(id, []);
    }
  }
}

// meta.totalScreens == screens.length
if (doc.meta && 'totalScreens' in doc.meta && typeof doc.meta.totalScreens === 'number') {
  if (doc.meta.totalScreens !== screens.length) {
    err(`meta.totalScreens (${doc.meta.totalScreens}) does not match actual screens.length (${screens.length})`);
  }
}

// ── Advisory: PRD-owner and markdown parity ──────────────────────────────────

// Check prdSource — if present, verify the referenced file exists
if (doc.meta && isString(doc.meta.prdSource)) {
  const prdPath = path.resolve(path.dirname(filePath), doc.meta.prdSource);
  if (!fs.existsSync(prdPath)) {
    advisory(`meta.prdSource '${doc.meta.prdSource}' does not exist at '${prdPath}'`);
  }
}

// Check that each screen has prdFeatures defined (advisory — not required by schema)
for (const scr of screens) {
  if (!isString(scr.id)) continue;
  if (!Array.isArray(scr.prdFeatures) || scr.prdFeatures.length === 0) {
    advisory(`screen '${scr.id}' has no prdFeatures[] — cannot trace to a PRD feature`);
  }
}

// ── Output ────────────────────────────────────────────────────────────────────

// report() is defined after accumulators but before file-loading so it can be
// called from early-exit paths (e.g. --allow-missing). References to id Sets
// are guarded because those Sets are only initialized after a successful parse.
function report() {
  const ok = errors.length === 0;

  if (jsonMode) {
    process.stdout.write(JSON.stringify({ ok, errors, warnings }, null, 2) + '\n');
    return;
  }

  if (warnings.length) {
    console.log('Warnings:');
    for (const w of warnings) console.log('  ! ' + w);
    console.log('');
  }

  if (!ok) {
    console.error(`FAIL: ${errors.length} error(s):`);
    for (const e of errors) console.error('  x ' + e);
    return;
  }

  console.log(`OK: ${_mCount} module(s), ${_sCount} screen(s), ${_fCount} flow(s) — all referential checks passed.`);
}

report();
process.exit(errors.length > 0 ? 1 : 0);
