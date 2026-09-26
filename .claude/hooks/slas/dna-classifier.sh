#!/bin/bash
# DNA Classifier — Post-distill hook
# Reads session-distill output, classifies patterns as DNA-worthy vs one-off
# DNA proposals go to .claude/dna-proposals/ for human review
#
# Called by: session-end-summary.sh or manually after /session-distill
# Output: .claude/dna-proposals/YYYY-MM-DD-{type}.md

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROPOSALS_DIR="$PROJECT_DIR/.claude/dna-proposals"
PATTERNS_DIR="$PROJECT_DIR/docs/sessions/patterns"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$PROPOSALS_DIR"
mkdir -p "$PATTERNS_DIR"

# Read the latest session pattern file (if exists)
LATEST_PATTERN=$(ls -t "$PATTERNS_DIR"/*.md 2>/dev/null | head -1)
if [ -z "$LATEST_PATTERN" ]; then
  echo "No session patterns found in $PATTERNS_DIR"
  echo "Run /session-distill first to generate patterns."
  exit 0
fi

# Classification criteria for DNA-worthy patterns:
# 1. Appeared 3+ times across sessions (recurring)
# 2. Is methodology/ideology, not framework-specific
# 3. Would apply regardless of tech stack
# 4. Improves agent behavior, not just task output

# Output the classification prompt for the AI to process
cat << 'CLASSIFIER_PROMPT'
## DNA Classification Task

Read the latest session patterns and classify each as:

### DNA-WORTHY (embed in agent definitions)
Criteria: recurring (3+ sessions), methodology-level, tech-stack-agnostic
Action: Write proposal to `.claude/dna-proposals/`

### SKILL-WORTHY (create or update a skill)
Criteria: framework-specific, reusable across projects, technical knowledge
Action: Write proposal to `.claude/dna-proposals/` with type=skill

### ONE-OFF (discard)
Criteria: project-specific, one-time fix, already in git history
Action: No action needed

### Proposal Format
```markdown
---
type: dna | skill
target: [agent-name or skill-name]
priority: high | medium | low
evidence: [session IDs or dates where pattern appeared]
---

## Proposed Change

[What to add/modify]

## Why

[Why this is recurring and worth embedding]

## Where

[Exact file path and section to modify]
```
CLASSIFIER_PROMPT

echo ""
echo "Latest pattern file: $LATEST_PATTERN"
echo "Proposals dir: $PROPOSALS_DIR"
