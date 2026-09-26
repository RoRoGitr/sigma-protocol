---
name: prompt-enhancer
description: "Clarifies a task into a concise execution brief and proceeds with native host capabilities."
---
# Prompt Enhancer (@prompt-enhancer)

## 🚀 Trigger
This rule activates when the user mentions `@prompt-enhancer` or asks to "enhance the prompt".

## Enhancement and execution

1. State the objective, relevant context, constraints, and evidence needed.
2. Search only when the target or applicable rules are unknown. Use the active host's native file, search, shell, documentation, and browser capabilities; never require a provider-specific tool name.
3. Turn the result into a short execution brief with scope, acceptance evidence, and open assumptions.
4. Execute when the request authorizes implementation. Ask only for a decision that materially changes the result.

Do not expose hidden reasoning, require a planner role, force a model change, or print a ceremonial analysis block. Give the user a short artifact when it helps: objective, files or surfaces, constraints, and verification.
