#!/usr/bin/env node
/**
 * step-skill-gate.cjs — Stop hook. Hard-enforces the SKILLS-INVOKE contract.
 *
 * The problem: Sigma `/step-N` commands carry a `<!-- SKILLS-INVOKE -->` block
 * listing the skills the step MUST invoke (and a quality gate). That block is
 * soft markdown — nothing forces the model to actually call the Skill tool, so
 * runs silently skip the skills and the gate.
 *
 * This Stop hook closes that hole. When the active session is running a step
 * command, it:
 *   1. Reads the transcript, finds the most-recent step-command turn (detected
 *      by the SKILLS-INVOKE marker the command injects).
 *   2. Parses the REQUIRED skills from that block.
 *   3. Scans every Skill tool_use AFTER that turn for which were invoked.
 *   4. If any required skill was never invoked, BLOCKS the stop with a reason
 *      naming the skipped skills + the gate reminder, so the model must invoke
 *      them before it can finish. A real pending HARD-GATE pause is allowed:
 *      later-phase skills are not due while the model awaits the user's answer.
 *
 * Safety:
 *   - Fail-open: ANY error, missing field, or unreadable transcript → exit 0
 *     (allow stop). A gate must never brick a session.
 *   - Scoped: does nothing unless a step block is among recent turns.
 *   - Loop-safe: at most STEP_SKILL_GATE_MAX_NUDGES (default 2) blocks per
 *     (session, step); after that it releases and logs, so it can't trap a
 *     session when a skill is genuinely unavailable on this surface.
 *   - Override: STEP_SKILL_GATE_OFF=1 → exit silently.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

const ALLOW = () => process.exit(0); // fail-open / allow stop

try {
  if (process.env.STEP_SKILL_GATE_OFF === '1') ALLOW();

  const HOME = os.homedir();
  const MAX_NUDGES = parseInt(process.env.STEP_SKILL_GATE_MAX_NUDGES || '2', 10);
  const RECENT_WINDOW = 80; // only enforce if the step turn is within the last N entries
  // Cache/log dirs are overridable (STEP_SKILL_GATE_CACHE_DIR) so tests run hermetically.
  const CACHE_DIR = process.env.STEP_SKILL_GATE_CACHE_DIR || path.join(HOME, '.claude', '.cache', 'step-skill-gate');
  const LOG = process.env.STEP_SKILL_GATE_CACHE_DIR
    ? path.join(process.env.STEP_SKILL_GATE_CACHE_DIR, 'step-skill-gate.jsonl')
    : path.join(HOME, '.claude', 'logs', 'step-skill-gate.jsonl');

  // ---- read hook input (Stop event JSON on stdin) ----
  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf-8') || '{}'); } catch { input = {}; }
  const transcriptPath = input.transcript_path;
  const sessionId = input.session_id || 'unknown';
  if (!transcriptPath || !fs.existsSync(transcriptPath)) ALLOW();

  // ---- parse transcript JSONL ----
  // Bound the Stop-hook cost on huge transcripts: only the tail matters (RECENT_WINDOW=80).
  const lines = fs.readFileSync(transcriptPath, 'utf-8').split('\n').filter(Boolean).slice(-220);
  const entries = [];
  for (const ln of lines) { try { entries.push(JSON.parse(ln)); } catch { /* skip */ } }
  if (!entries.length) ALLOW();

  // Concatenate the text of an entry's message (string or block list).
  const msgText = (e) => {
    const m = e && e.message;
    if (!m) return '';
    const c = m.content;
    if (typeof c === 'string') return c;
    if (Array.isArray(c)) {
      return c.map((b) => (b && typeof b === 'object' && typeof b.text === 'string' ? b.text : '')).join('\n');
    }
    return '';
  };

  // Real-skill validator: keep only tokens that exist in the skill registry, so stray backtick
  // tokens (`null`, prose words) can't be treated as "required skills". Fail-safe: if the registry
  // can't be read, drop only obvious non-skill literals. (Registry path overridable for tests.)
  let _skillSet = null;
  const loadSkillSet = () => {
    if (_skillSet) return _skillSet;
    _skillSet = new Set();
    try {
      const regPath = process.env.STEP_SKILL_GATE_REGISTRY || path.join(HOME, '.claude', 'lib', 'agent-skill-registry.json');
      const reg = JSON.parse(fs.readFileSync(regPath, 'utf-8'));
      const skills = reg && reg.skills;
      if (Array.isArray(skills)) for (const s of skills) { const n = (s && (s.name || s.id || s.skill)) || (typeof s === 'string' ? s : null); if (n) _skillSet.add(String(n).toLowerCase()); }
      else if (skills && typeof skills === 'object') for (const k of Object.keys(skills)) _skillSet.add(k.toLowerCase());
    } catch { /* registry unreadable → fallback below */ }
    return _skillSet;
  };
  const DENY = new Set(['null', 'undefined', 'true', 'false', 'none', 'n/a']);
  const filterToRealSkills = (list) => {
    const set = loadSkillSet();
    return list.filter((s) => (DENY.has(s) ? false : set.size ? set.has(s) : s.length >= 3 && /[a-z]/.test(s)));
  };

  // ---- find the most-recent GENUINE step-command turn ----
  // A real /step expansion contains BOTH the SKILLS-INVOKE block AND the `# /step-N-...` command
  // header. Quoted fragments (agent task-notifications, pasted snippets, the plan file) carry the
  // marker WITHOUT the header — they must NOT trigger the gate (fixes the 2026-06-14 false-positive
  // that blocked a planning session for "step-15" demanding bogus skills `flows`/`null`).
  const MARK = 'SKILLS-INVOKE:start';
  const HEADER_RE = /^#\s*\/step-\d+(?:\.\d+)?[a-z0-9-]*/im; // require the real command slash (no false-fire on a discussed "# step-N")
  let stepIdx = -1;
  for (let i = entries.length - 1; i >= 0; i--) {
    const e = entries[i];
    if (!e || e.type !== 'user') continue;
    const t = msgText(e);
    if (t.includes(MARK) && HEADER_RE.test(t)) { stepIdx = i; break; }
  }
  if (stepIdx === -1) ALLOW();                              // no genuine step command active
  if (stepIdx < entries.length - RECENT_WINDOW) ALLOW();    // step turn is stale → don't nag

  // ---- extract required skills + a step label from that turn's block ----
  const block = msgText(entries[stepIdx]);
  const startTag = block.indexOf('SKILLS-INVOKE:start');
  const endTag = block.indexOf('SKILLS-INVOKE:end');
  const region = endTag > startTag ? block.slice(startTag, endTag) : block.slice(startTag);
  let required = [];
  for (const m of region.matchAll(/^\s*-\s*`([a-z0-9][a-z0-9._:-]{1,60})`/gim)) {
    required.push(m[1].toLowerCase());
  }
  required = filterToRealSkills(required); // drop non-skill tokens (`null`, prose); keep only registry skills
  // HITL requirement: the step declares <HARD-GATE> human checkpoints. The named
  // tool is a host hint; a final prose approval question is also a valid pause.
  const hitlRequired = block.includes('HARD-GATE') && block.includes('AskUserQuestion');
  if (!required.length && !hitlRequired) ALLOW(); // step present but nothing enforceable

  let stepLabel = 'step';
  const lab = block.match(/^#\s*\/?(step-\d+(?:\.\d+)?[a-z0-9-]*)/im) || block.match(/step-\d+(?:\.\d+)?[a-z-]*/i);
  if (lab) stepLabel = (lab[1] || lab[0]).toLowerCase();

  // ---- scan tool_use AFTER the step turn: skills invoked, HITL questions asked, output produced ----
  const invoked = new Set();
  let askCount = 0;   // Structured approval-question calls
  let lastStructuredQuestionIdx = -1;
  let outputCount = 0; // Write/Edit calls — proof the model actually produced step output
  for (let i = stepIdx; i < entries.length; i++) {
    const e = entries[i];
    const m = e && e.message;
    if (!m || !Array.isArray(m.content)) continue;
    for (const b of m.content) {
      if (!b || b.type !== 'tool_use') continue;
      if (b.name === 'AskUserQuestion') { askCount++; lastStructuredQuestionIdx = i; continue; }
      if (b.name === 'Write' || b.name === 'Edit' || b.name === 'NotebookEdit') { outputCount++; continue; }
      if (b.name === 'Read') {
        const readPath = String((b.input || {}).file_path || (b.input || {}).path || '').toLowerCase();
        for (const r of required) if (readPath.endsWith('/' + r + '/skill.md')) invoked.add(r);
        continue;
      }
      if (b.name !== 'Skill') continue;
      const inp = b.input || {};
      // The Skill tool's field is `skill`; scan all string values to be robust.
      const vals = [inp.skill, inp.command, inp.name, ...Object.values(inp).filter((v) => typeof v === 'string')];
      for (const v of vals) {
        if (typeof v !== 'string') continue;
        const low = v.toLowerCase();
        for (const r of required) if (low === r || low.endsWith(':' + r) || low === r.replace(/^.*:/, '')) invoked.add(r);
      }
    }
  }

  const missing = required.filter((r) => !invoked.has(r));

  // A Stop hook runs after an assistant turn. Only its final prose paragraph can
  // establish a pending gate. A question buried in an artifact, quote, or example
  // is not a request to the user and must not bypass the contract.
  const assistantEntries = entries.slice(stepIdx + 1).filter((e) => e && e.type === 'assistant');
  const finalAssistant = assistantEntries[assistantEntries.length - 1];
  const finalText = msgText(finalAssistant);
  // Remove fenced blocks before splitting paragraphs: blank lines are valid
  // inside a fence and must not reset its state.
  let fence = null;
  const proseText = finalText.split('\n').filter((line) => {
    const marker = line.match(/^\s{0,3}(`{3,}|~{3,})(.*)$/);
    if (marker) {
      if (!fence) fence = marker[1];
      else if (marker[1][0] === fence[0] && marker[1].length >= fence.length && !marker[2].trim()) fence = null;
      return false;
    }
    return !fence && !/^(?: {4}|\t)/.test(line);
  }).join('\n');
  const finalParagraphs = proseText.trim().split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean);
  let finalProseLine = '';
  for (let i = finalParagraphs.length - 1; i >= 0 && !finalProseLine; i--) {
    finalProseLine = finalParagraphs[i].split('\n').map((line) => line.trim()).filter((line) => {
      return line && !/^(?:>|[-*+]\s+|\d+[.)]\s+|options?\s*:|[`"“'])/i.test(line) &&
        !/^(?:example|sample|template|quote)\s*:/i.test(line);
    }).pop() || '';
  }
  finalProseLine = finalProseLine.replace(/(?:[*_`]+\s*)+$/, '');
  const proseGatePause = Boolean(
    /(?:approve|approval|confirm|choose|select|which\s+(?:option|direction|track)|ready\s+to|shall\s+i)\b[^?\n]{0,180}\?\s*$/i.test(finalProseLine) ||
    /\b(?:awaiting|waiting|paused)\b[^.\n]{0,120}\b(?:your\s+)?(?:approval|answer|confirmation)\b/i.test(finalProseLine)
  );

  // A structured question is pending only when no later user entry answered it
  // (or supplied new instructions). Tool-result event shapes vary by host, so
  // subsequent assistant output alone does not invalidate a pending question.
  const structuredGatePause = lastStructuredQuestionIdx !== -1 &&
    !entries.slice(lastStructuredQuestionIdx + 1).some((e) => e && e.type === 'user');
  const gatePause = proseGatePause || structuredGatePause;
  const completionClaim = new RegExp(
    '\\b(?:' + stepLabel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '|step\\s+\\d+(?:\\.\\d+)?)\\b[^\\n]{0,100}\\b(?:complete|completed|final)\\b|\\bready\\s+to\\s+(?:begin|start|move\\s+(?:to|into))\\s+(?:implementation|step\\s+\\d+)',
    'i'
  ).test(proseText);

  // Explicit unattended authorization must be a direct affirmative user
  // instruction before the command begins. Questions, negations, quoted/source
  // material, and a later revocation never count as fabricated approval.
  const isSourceOrQuestion = (t) => !t || /(?:\?|SKILLS-INVOKE|HARD-GATE|<!--|```)/i.test(t) ||
    /(?:^|\n)\s*(?:>|[-*+]\s+|[`"“'])/.test(t);
  const isUnattendedRevocation = (t) => !isSourceOrQuestion(t) &&
    /\b(?:do\s+not|don'?t|never|stop|pause|disable|end|revoke|cancel|must\s+not|cannot|can'?t)\b[^.\n]{0,120}\b(?:unattended|autonomous|without\s+stopping|without\s+asking)\b/i.test(t);
  const isUnattendedAuthorization = (t) => {
    if (isSourceOrQuestion(t) || isUnattendedRevocation(t)) return false;
    return /\b(?:proceed|continue|run|work|complete|finish|draft|update|make)\b[^.\n]{0,120}\b(?:unattended|without\s+stopping|without\s+asking|autonom(?:ous|ously))\b/i.test(t) ||
      /\b(?:unattended|autonom(?:ous|ously))\b[^.\n]{0,120}\b(?:proceed|continue|run|work|complete|finish|draft|update|make)\b/i.test(t) ||
      /\b(?:don'?t\s+ask\s+me|do\s+not\s+ask\s+me)\b[^.\n]{0,120}\b(?:proceed|continue|run|work|complete|finish|draft|update|make)\b/i.test(t) ||
      /\b(?:use|enable|enter|run\s+in|work\s+in)\s+autonomous\s+mode\b/i.test(t);
  };
  // "This run" means the immediately preceding user instruction, the current
  // command's explicit arguments, or a later user instruction in this command.
  // Do not inherit authorization from an unrelated earlier step in the transcript.
  let lastAuthorizationIdx = -1;
  const previous = entries[stepIdx - 1];
  if (previous && previous.type === 'user' && isUnattendedAuthorization(msgText(previous))) lastAuthorizationIdx = stepIdx - 1;
  const headerMatch = block.match(HEADER_RE);
  const headerLine = headerMatch && Number.isInteger(headerMatch.index)
    ? block.slice(headerMatch.index, block.indexOf('\n', headerMatch.index) === -1 ? block.length : block.indexOf('\n', headerMatch.index))
    : '';
  const headerStart = block.indexOf(headerLine);
  const commandArguments = (headerStart > 0 ? block.slice(0, headerStart) + '\n' : '') + headerLine;
  if (isUnattendedAuthorization(commandArguments) || /--(?:unattended|autonomous)\b/i.test(headerLine)) lastAuthorizationIdx = stepIdx;
  for (let i = stepIdx + 1; i < entries.length; i++) {
    const e = entries[i];
    if (e && e.type === 'user' && isUnattendedAuthorization(msgText(e))) lastAuthorizationIdx = i;
  }
  const hasUnattendedAuthorization = lastAuthorizationIdx !== -1 && !entries.slice(lastAuthorizationIdx + 1).some((e, offset) => {
    const i = lastAuthorizationIdx + 1 + offset;
    return i !== stepIdx && e && e.type === 'user' && isUnattendedRevocation(msgText(e));
  });

  // A valid pause wins: it prevents the hook from demanding later-phase skills
  // before the user has answered. Delegation waives only the question; missing
  // required skills remain enforced on an otherwise completed unattended run.
  if (gatePause && !completionClaim) ALLOW();
  const hitlViolation = hitlRequired && !hasUnattendedAuthorization && !gatePause && askCount === 0 && outputCount > 0;
  if (!missing.length && !hitlViolation) ALLOW(); // skills invoked + HITL respected → allow stop

  // ---- loop guard: cap nudges per (session, step) ----
  let state = {};
  const cacheFile = path.join(CACHE_DIR, `${sessionId}.json`);
  try { state = JSON.parse(fs.readFileSync(cacheFile, 'utf-8')); } catch { state = {}; }
  if (state.step !== stepLabel) state = { step: stepLabel, nudges: 0 };
  state.nudges = (state.nudges || 0) + 1;

  const writeLog = (action) => {
    try {
      fs.mkdirSync(path.dirname(LOG), { recursive: true });
      fs.appendFileSync(LOG, JSON.stringify({ sessionId, step: stepLabel, required, missing, hitlViolation, askCount, outputCount, gatePause, hasUnattendedAuthorization, action, nudges: state.nudges }) + '\n');
    } catch { /* ignore */ }
  };

  if (state.nudges > MAX_NUDGES) {
    writeLog('released'); // already nudged enough; never trap the session
    ALLOW();
  }

  try { fs.mkdirSync(CACHE_DIR, { recursive: true }); fs.writeFileSync(cacheFile, JSON.stringify(state)); } catch { /* ignore */ }
  writeLog('block');

  const parts = [];
  if (missing.length) {
    parts.push(`${missing.length} required skill(s) not invoked: ` +
      missing.map((s) => '`' + s + '`').join(', ') +
      ` — invoke each via the Skill tool now (do NOT rely on embedded summaries)`);
  }
  if (hitlViolation) {
    parts.push(`this step has human-in-the-loop <HARD-GATE> checkpoints but you generated output without a pending approval question or explicit unattended authorization — ask for approval with the host-supported question mechanism, or in a final prose response, then stop`);
  }
  const reason =
    `⛔ Step gate (${stepLabel}): ` + parts.join('; ') + '. ' +
    `Then satisfy the step's quality gate before finishing. ` +
    `If a skill is genuinely unavailable on this surface, state that explicitly and continue. (Override: STEP_SKILL_GATE_OFF=1)`;

  process.stdout.write(JSON.stringify({ decision: 'block', reason }));
  process.exit(0);
} catch (_e) {
  // Absolute fail-open.
  process.exit(0);
}
