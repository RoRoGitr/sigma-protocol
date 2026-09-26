#!/usr/bin/env node
/**
 * benchmark-step-variants.mjs
 *
 * A/B variant harness for Sigma Protocol step files.
 *
 * Given a step ID and two variant files, renders both prompts against a fixed
 * project brief and — when a claude CLI or ANTHROPIC_API_KEY is available —
 * executes each variant headless and scores outputs against a rubric:
 *
 *   Completeness (0-10):  does the output include all required sections?
 *   Specificity   (0-10): are claims concrete vs vague?
 *   Actionability (0-10): can an agent act on this without clarification?
 *   Format        (0-10): does it follow the structural conventions of the step?
 *
 * A second `claude -p` call acts as judge (model must differ from generator).
 * Results are written to docs/research/benchmarks/<date>-<step>.json.
 *
 * Usage:
 *   node scripts/benchmark-step-variants.mjs \
 *     --step step-11 \
 *     --variant-a steps/step-11-prd-generation \
 *     --variant-b /tmp/step11-old \
 *     --brief "a habit-tracking mobile app" \
 *     [--runs 1] \
 *     [--dry-run]
 *
 * Flags:
 *   --step <id>         Step identifier (used in output filename)
 *   --variant-a <path>  Path to variant A (new/current)
 *   --variant-b <path>  Path to variant B (baseline/old)
 *   --brief <text>      One-sentence project description for the prompt
 *   --runs <n>          Number of runs per variant (default: 1; set ≥3 for stable results)
 *   --dry-run           Skip LLM calls; emit scaffold JSON with null scores
 *   --judge-model <id>  Judge model (default: claude-haiku-4; must differ from generator)
 *   --gen-model <id>    Generator model (default: claude-sonnet-4-5)
 *   --output <path>     Override output path (default: docs/research/benchmarks/<date>-<step>.json)
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

// ─── Argument parsing ────────────────────────────────────────────────────────

const argv = process.argv.slice(2);
function flag(name) {
  const idx = argv.indexOf(name);
  if (idx === -1) return null;
  return argv[idx + 1] ?? null;
}
function hasFlag(name) { return argv.includes(name); }

const STEP_ID       = flag('--step');
const VARIANT_A     = flag('--variant-a');
const VARIANT_B     = flag('--variant-b');
const BRIEF         = flag('--brief') ?? 'a habit-tracking mobile app';
const RUNS          = parseInt(flag('--runs') ?? '1', 10);
const DRY_RUN       = hasFlag('--dry-run');
const JUDGE_MODEL   = flag('--judge-model')  ?? 'claude-haiku-4-5';
const GEN_MODEL     = flag('--gen-model')    ?? 'claude-sonnet-4-5';
const OUT_OVERRIDE  = flag('--output');

if (!STEP_ID || !VARIANT_A || !VARIANT_B) {
  console.error('Usage: node scripts/benchmark-step-variants.mjs --step <id> --variant-a <path> --variant-b <path> [options]');
  process.exit(1);
}

if (JUDGE_MODEL === GEN_MODEL) {
  console.error(`ERROR: judge-model and gen-model must differ (both set to "${GEN_MODEL}"). Self-grading is unreliable.`);
  process.exit(1);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function readFile(p) {
  const resolved = path.resolve(ROOT, p);
  if (!fs.existsSync(resolved)) throw new Error(`File not found: ${resolved}`);
  return fs.readFileSync(resolved, 'utf8');
}

function detectClaudeCLI() {
  // Prefer the binary directly over the shell function wrapper
  const candidates = [
    process.env.CLAUDE_BIN,
    `${process.env.HOME}/.local/bin/claude`,
    '/usr/local/bin/claude',
    '/opt/homebrew/bin/claude',
  ].filter(Boolean);

  for (const p of candidates) {
    if (fs.existsSync(p)) {
      // Cache for use by runClaude
      detectClaudeCLI._path = p;
      return true;
    }
  }
  // Fallback: check PATH
  const r = spawnSync('which', ['claude'], { encoding: 'utf8' });
  if (r.status === 0 && r.stdout.trim()) {
    detectClaudeCLI._path = r.stdout.trim();
    return true;
  }
  return false;
}

function detectApiKey() {
  return !!(process.env.ANTHROPIC_API_KEY);
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function outputPath() {
  if (OUT_OVERRIDE) return path.resolve(ROOT, OUT_OVERRIDE);
  const dir = path.join(ROOT, 'docs', 'research', 'benchmarks');
  fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, `${today()}-${STEP_ID}.json`);
}

// ─── Prompt construction ─────────────────────────────────────────────────────

function buildGeneratorPrompt(stepContent, brief) {
  return `You are running the Sigma Protocol step below against a new project.
Project brief: "${brief}"

Execute the step's Phase A and Phase B (planning phases only — do NOT author any implementation files).
Return a structured outline showing:
1. What inputs you detected / assumed
2. What decisions you would make
3. What sections / artifacts you would produce

Keep your response under 600 words. Focus on specificity and actionability.

---
${stepContent.slice(0, 8000)}
---
END OF STEP`;
}

function buildJudgePrompt(generatorOutput, brief, variantLabel) {
  return `You are an objective judge scoring an AI agent's response to a Sigma Protocol step.
Project brief: "${brief}"
Variant: ${variantLabel}

Agent output:
---
${generatorOutput.slice(0, 3000)}
---

Score the output on four dimensions, each 0-10:

1. COMPLETENESS (0-10): Does the response include all required planning phases and sections? 10 = all phases present; 0 = mostly missing.
2. SPECIFICITY (0-10): Are decisions concrete with real values, paths, and predicates? 10 = fully specific; 0 = only vague generalities.
3. ACTIONABILITY (0-10): Could an autonomous agent implement this without clarification? 10 = fully self-contained; 0 = requires many follow-up questions.
4. FORMAT_COMPLIANCE (0-10): Does the output follow the step's structural conventions (tables, numbered sections, EARS criteria where applicable)? 10 = perfect match; 0 = free prose only.

Respond with ONLY valid JSON in this exact shape:
{
  "completeness": <number>,
  "specificity": <number>,
  "actionability": <number>,
  "format_compliance": <number>,
  "total": <sum of all four>,
  "rationale": "<one sentence explaining the weakest dimension>"
}`;
}

// ─── LLM execution ───────────────────────────────────────────────────────────

function runClaude(prompt, model, label) {
  if (DRY_RUN) {
    console.log(`  [dry-run] would call: claude -p --model ${model} (${label})`);
    return null;
  }

  const hasCLI = detectClaudeCLI();
  const hasKey = detectApiKey();

  if (!hasCLI && !hasKey) {
    console.warn(`  [warn] claude CLI not found and ANTHROPIC_API_KEY not set — skipping LLM call for ${label}`);
    return null;
  }

  try {
    const tmpFile = path.join('/tmp', `sigma-bench-${crypto.randomBytes(4).toString('hex')}.txt`);
    fs.writeFileSync(tmpFile, prompt, 'utf8');

    let cmd, args;
    if (hasCLI) {
      // Use the binary path directly to bypass any shell function wrapper
      cmd = detectClaudeCLI._path || 'claude';
      args = ['-p', '--model', model];
    } else {
      // fallback: use curl against Anthropic API
      console.warn(`  [info] using ANTHROPIC_API_KEY REST fallback for ${label}`);
      return runAnthropicRest(prompt, model, label);
    }

    const result = spawnSync(cmd, args, {
      input: prompt,
      encoding: 'utf8',
      timeout: 120_000,
      maxBuffer: 1024 * 1024 * 4,
    });

    fs.unlinkSync(tmpFile);

    if (result.status !== 0) {
      console.warn(`  [warn] ${label}: claude exited ${result.status}: ${(result.stderr || '').slice(0, 200)}`);
      return null;
    }
    return result.stdout.trim();
  } catch (e) {
    console.warn(`  [warn] ${label}: exception: ${e.message}`);
    return null;
  }
}

function runAnthropicRest(prompt, model, label) {
  const payload = JSON.stringify({
    model,
    max_tokens: 1024,
    messages: [{ role: 'user', content: prompt }],
  });

  try {
    const result = spawnSync('curl', [
      '-s', '-X', 'POST',
      'https://api.anthropic.com/v1/messages',
      '-H', 'content-type: application/json',
      '-H', `x-api-key: ${process.env.ANTHROPIC_API_KEY}`,
      '-H', 'anthropic-version: 2023-06-01',
      '-d', payload,
    ], { encoding: 'utf8', timeout: 120_000 });

    if (result.status !== 0) {
      console.warn(`  [warn] REST ${label}: curl failed`);
      return null;
    }
    const parsed = JSON.parse(result.stdout);
    return parsed?.content?.[0]?.text ?? null;
  } catch (e) {
    console.warn(`  [warn] REST ${label}: ${e.message}`);
    return null;
  }
}

function parseScores(judgeOutput) {
  if (!judgeOutput) return null;
  try {
    const jsonMatch = judgeOutput.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return null;
    return JSON.parse(jsonMatch[0]);
  } catch {
    return null;
  }
}

// ─── Per-variant benchmark ────────────────────────────────────────────────────

async function benchmarkVariant(label, stepContent, brief, runs) {
  const runResults = [];
  for (let i = 0; i < runs; i++) {
    console.log(`  [${label}] run ${i + 1}/${runs}...`);
    const genPrompt = buildGeneratorPrompt(stepContent, brief);
    const genOutput = runClaude(genPrompt, GEN_MODEL, `${label}-gen-${i}`);

    let scores = null;
    if (genOutput) {
      const judgePrompt = buildJudgePrompt(genOutput, brief, label);
      const judgeOutput = runClaude(judgePrompt, JUDGE_MODEL, `${label}-judge-${i}`);
      scores = parseScores(judgeOutput);
    }

    runResults.push({
      run: i + 1,
      gen_output_chars: genOutput ? genOutput.length : null,
      scores,
    });
  }

  // Aggregate scores across runs
  const validRuns = runResults.filter(r => r.scores !== null);
  let aggregate = null;
  if (validRuns.length > 0) {
    const dims = ['completeness', 'specificity', 'actionability', 'format_compliance', 'total'];
    aggregate = {};
    for (const dim of dims) {
      const vals = validRuns.map(r => r.scores[dim]).filter(v => typeof v === 'number');
      aggregate[dim] = vals.length > 0 ? (vals.reduce((a, b) => a + b, 0) / vals.length).toFixed(2) : null;
    }
    aggregate.n_valid = validRuns.length;
  }

  return { label, runs: runResults, aggregate };
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\n=== Sigma Step Benchmark: ${STEP_ID} ===`);
  console.log(`Variant A: ${VARIANT_A}`);
  console.log(`Variant B: ${VARIANT_B}`);
  console.log(`Brief: "${BRIEF}"`);
  console.log(`Runs: ${RUNS}, Gen: ${GEN_MODEL}, Judge: ${JUDGE_MODEL}`);
  console.log(`Dry-run: ${DRY_RUN}\n`);

  const variantAContent = readFile(VARIANT_A);
  const variantBContent = readFile(VARIANT_B);

  const resultA = await benchmarkVariant('variant-A (new)', variantAContent, BRIEF, RUNS);
  const resultB = await benchmarkVariant('variant-B (old)', variantBContent, BRIEF, RUNS);

  const out = {
    meta: {
      step: STEP_ID,
      brief: BRIEF,
      date: today(),
      runs_per_variant: RUNS,
      gen_model: GEN_MODEL,
      judge_model: JUDGE_MODEL,
      dry_run: DRY_RUN,
      variant_a_path: VARIANT_A,
      variant_b_path: VARIANT_B,
      note: RUNS < 3
        ? `n=${RUNS} — results are indicative only. Rerun with --runs 3 for stable p50 estimates.`
        : `n=${RUNS}`,
    },
    rubric: {
      completeness:     'Does the response include all required planning phases and sections? (0-10)',
      specificity:      'Are decisions concrete with real values, paths, and predicates? (0-10)',
      actionability:    'Could an autonomous agent act without clarification? (0-10)',
      format_compliance:'Does the output follow the step\'s structural conventions? (0-10)',
      total:            'Sum of all four dimensions (0-40)',
    },
    results: { variant_a: resultA, variant_b: resultB },
    summary: null,
  };

  // Generate summary when both variants have aggregate scores
  if (resultA.aggregate && resultB.aggregate) {
    const aTotal = parseFloat(resultA.aggregate.total);
    const bTotal = parseFloat(resultB.aggregate.total);
    const winner = aTotal >= bTotal ? 'variant-A (new)' : 'variant-B (old)';
    const delta = Math.abs(aTotal - bTotal).toFixed(2);
    out.summary = {
      winner,
      delta_total: delta,
      interpretation: delta < 2
        ? 'No meaningful difference between variants (delta < 2 points).'
        : `${winner} leads by ${delta} total points.`,
      recommendation: aTotal >= bTotal
        ? 'Keep variant A (new). It matches or exceeds baseline.'
        : `Revert to variant B or investigate variant A regressions (delta: ${delta}).`,
    };
  } else {
    out.summary = {
      winner: null,
      delta_total: null,
      interpretation: DRY_RUN
        ? 'Dry-run mode — no LLM calls executed. Scaffold JSON produced.'
        : 'LLM calls failed or were skipped — scores not available.',
      recommendation: 'Rerun with a working claude CLI or ANTHROPIC_API_KEY set.',
    };
  }

  // Failed runs (no scores) must never clobber real results — suffix them.
  const allFailed = !out.summary || out.summary.winner === 'N/A' || out.summary.winner == null;
  const basePath = outputPath();
  const outPath = allFailed && fs.existsSync(basePath)
    ? basePath.replace(/\.json$/, `-failed-${Date.now()}.json`)
    : basePath;
  fs.writeFileSync(outPath, JSON.stringify(out, null, 2), 'utf8');
  console.log(`\nResults written to: ${outPath}`);

  if (out.summary) {
    console.log(`\nSummary:`);
    console.log(`  Winner:         ${out.summary.winner ?? 'N/A'}`);
    console.log(`  Delta (total):  ${out.summary.delta_total ?? 'N/A'}`);
    console.log(`  Interpretation: ${out.summary.interpretation}`);
    console.log(`  Recommendation: ${out.summary.recommendation}`);
  }
}

main().catch(e => { console.error(e); process.exit(1); });
