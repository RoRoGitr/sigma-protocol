#!/bin/bash
# Claude Stop hook — parallel pipeline runner.
# Replaces three sequential hooks with parallel execution.
# Sequential worst-case was 15+10+10=35s. Parallel worst-case: max(15,10,10)=15s.
# This script is given timeout 20s (15s max + 5s buffer) in settings.json.

set +e  # don't exit on individual failures — collect all results

PARALLEL_PIDS=()

# 1. Session cleanup (was timeout 15s)
if [ -x "$HOME/.local/bin/session-cleanup.sh" ]; then
  "$HOME"/.local/bin/session-cleanup.sh claude-code-stop &
  PARALLEL_PIDS+=($!)
fi

# 2. Pipeline gate check (was timeout 10s)
if [ -x ""$HOME"/.local/bin/stop-gate.sh" ]; then
  "$HOME"/.local/bin/stop-gate.sh &
  PARALLEL_PIDS+=($!)
fi

# 3. Brain flush (was timeout 10s)
if [ -x "$HOME/.claude/scripts/stop-flush-hook.sh" ]; then
  "$HOME/.claude/scripts/stop-flush-hook.sh" &
  PARALLEL_PIDS+=($!)
fi

# Wait for all spawned jobs, collect exit codes
RESULT=0
for pid in "${PARALLEL_PIDS[@]}"; do
  if ! wait "$pid"; then
    RESULT=1
  fi
done

exit $RESULT
