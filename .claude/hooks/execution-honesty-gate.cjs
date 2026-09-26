#!/usr/bin/env node
/**
 * execution-honesty-gate.cjs — Stop hook. Enforces "evidence over assertion".
 *
 * The execution doctrine: never claim done/passing/fixed without the command
 * and its real output in the same turn. This gate catches the most common
 * violation — the model edits code, then claims tests/build/lint PASS without
 * having run anything this turn.
 *
 * Fires only when ALL of these hold (deliberately conservative):
 *   1. The final assistant turn makes a verifiable completion claim
 *      (tests pass / build green / lint clean / "fixed" / "verified").
 *   2. The model produced output this turn (Write/Edit) — it did real work.
 *   3. ZERO command executions (Bash/Shell) happened since the last user turn —
 *      so the claim has no run behind it.
 *
 * Then it BLOCKS once with a nudge to run the command and paste its output.
 *
 * Safety: fail-open on any error; loop-safe (one nudge per session turn);
 * override SIGMA_HONESTY_GATE_OFF=1.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const ALLOW = () => process.exit(0);

try {
  if (process.env.SIGMA_HONESTY_GATE_OFF === '1') ALLOW();

  const HOME = process.env.HOME || require('os').homedir();
  const CACHE_DIR = process.env.SIGMA_HONESTY_GATE_CACHE_DIR || path.join(HOME, '.claude', '.cache', 'execution-honesty-gate');

  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf-8') || '{}'); } catch { input = {}; }
  const transcriptPath = input.transcript_path;
  const sessionId = input.session_id || 'unknown';
  if (!transcriptPath || !fs.existsSync(transcriptPath)) ALLOW();

  const lines = fs.readFileSync(transcriptPath, 'utf-8').split('\n').filter(Boolean).slice(-120);
  const entries = [];
  for (const ln of lines) { try { entries.push(JSON.parse(ln)); } catch { /* skip */ } }
  if (!entries.length) ALLOW();

  const msgText = (e) => {
    const m = e && e.message;
    if (!m) return '';
    const c = m.content;
    if (typeof c === 'string') return c;
    if (Array.isArray(c)) return c.map((b) => (b && typeof b === 'object' && typeof b.text === 'string' ? b.text : '')).join('\n');
    return '';
  };

  // last user turn
  let lastUser = -1;
  for (let i = entries.length - 1; i >= 0; i--) {
    if (entries[i] && entries[i].type === 'user') { lastUser = i; break; }
  }
  if (lastUser === -1) ALLOW();

  // assistant text + tool use since last user turn
  let claimText = '';
  let ranCommand = false;
  let producedOutput = false;
  for (let i = lastUser + 1; i < entries.length; i++) {
    const e = entries[i];
    if (!e || e.type !== 'assistant') continue;
    claimText += '\n' + msgText(e);
    const m = e.message;
    if (m && Array.isArray(m.content)) {
      for (const b of m.content) {
        if (!b || b.type !== 'tool_use') continue;
        if (b.name === 'Bash' || b.name === 'Shell') ranCommand = true;
        if (b.name === 'Write' || b.name === 'Edit' || b.name === 'NotebookEdit') producedOutput = true;
      }
    }
  }
  if (ranCommand) ALLOW();      // evidence exists this turn
  if (!producedOutput) ALLOW(); // no work claimed → nothing to verify

  // verifiable completion-claim patterns
  const CLAIM = /\b(all tests? (?:are )?pass(?:ing|ed)?|tests? (?:now )?pass|test suite (?:is )?green|build (?:is )?(?:green|passing|succeed)|builds? (?:cleanly|fine)|lint(?:ing)? (?:is )?clean|no lint errors|type ?check (?:is )?clean|verified (?:that )?(?:it|the|tests)|confirmed (?:it )?works|i (?:have )?(?:fixed|resolved) the (?:bug|test|failure|error))\b/i;
  if (!CLAIM.test(claimText)) ALLOW();

  // loop guard: one nudge per (session, turn-position)
  const key = `${sessionId}-${lastUser}`;
  const cacheFile = path.join(CACHE_DIR, `${sessionId}.json`);
  let state = {};
  try { state = JSON.parse(fs.readFileSync(cacheFile, 'utf-8')); } catch { state = {}; }
  if (state.key === key) ALLOW(); // already nudged for this exact turn
  try { fs.mkdirSync(CACHE_DIR, { recursive: true }); fs.writeFileSync(cacheFile, JSON.stringify({ key })); } catch { /* ignore */ }

  const reason =
    '⛔ Execution-honesty gate: you claimed tests/build/lint pass (or a fix works) and edited code this turn, ' +
    'but ran NO command this turn to prove it. Per the execution doctrine, evidence beats assertion: ' +
    'run the actual test/build/lint command now and show its real output, then report PASS/MISS with that proof. ' +
    'If the command genuinely cannot run on this surface, say so explicitly. (Override: SIGMA_HONESTY_GATE_OFF=1)';

  process.stdout.write(JSON.stringify({ decision: 'block', reason }));
  process.exit(0);
} catch (_e) {
  process.exit(0); // absolute fail-open
}
