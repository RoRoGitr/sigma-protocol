#!/usr/bin/env node
/** Verify Run Track step artifacts for M3 + S1 execution round. */
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];
const fail = (m) => failures.push(m);

const checks = [
  ['docs/run-track/marketing/M3-STACK-CHECKLIST.md', ['## What we\'re doing', '## Your tasks today', 'PostHog', 'UTM']],
  ['docs/run-track/sales/S1-ICP-ACCOUNTS.md', ['## What we\'re doing', 'Scorecard', 'Named accounts']],
];

// This verifier checks the OUTPUTS of an executed M3/S1 run-track round.
// Those artifacts are per-operator (gitignored — the framework ships shells
// only), so on a clean checkout there is nothing to verify yet.
if (checks.every(([rel]) => !existsSync(path.join(root, rel)))) {
  console.log('verify-run-track-steps SKIPPED — no executed run-track outputs in this checkout (clean install); run /run-marketing or /run-sales first.');
  process.exit(0);
}

for (const [rel, needles] of checks) {
  const abs = path.join(root, rel);
  if (!existsSync(abs)) fail(`missing ${rel}`);
  else {
    const text = readFileSync(abs, 'utf8');
    for (const n of needles) if (!text.includes(n)) fail(`${rel} missing section: ${n}`);
  }
}

for (const [dept, id] of [['marketing', 'M03.001'], ['sales', 'S01.001']]) {
  const data = JSON.parse(readFileSync(path.join(root, `.sigma/backlogs/${dept}/prd.json`), 'utf8'));
  const item = data.items?.find((i) => i.prd_id === id);
  if (!item) fail(`backlog missing ${id}`);
  else if ((item.daily_tasks || []).filter((t) => t.owner === 'founder').length > 3) fail(`${id} has >3 founder tasks`);
}

if (failures.length) {
  console.error('verify-run-track-steps FAILED');
  failures.forEach((f) => console.error(`- ${f}`));
  process.exit(1);
}
console.log('verify-run-track-steps PASSED (100%) — M3 + S1');
