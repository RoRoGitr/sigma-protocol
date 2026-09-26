# Research decisions — checked 2026-09-19

Use publications available by the review date. A retrieved page is evidence for its specific claims, not proof that every framework is current. Preserve foundational methods unless evidence warrants a change. No source found is not proof of no change.

| Source | Supported decision |
|---|---|
| [OpenAI: GPT-6 Astra model guidance](https://developers.openai.com/api/docs/guides/latest-model) | Clarify authorized persistence, scope, delegation and proportionate verification. Model settings belong to the adapter; Astra tool calls require Responses and sampling knobs are unsupported. |
| [OpenAI: Rethinking skills and prompts, September 11](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra) | Keep skill descriptions precise and short; load supporting material on demand; remove unnecessary mandatory reading and conflicting stop instructions. |
| [Anthropic: Fable 5.1 overview](https://platform.claude.com/docs/en/models/fable-5-1/overview) | Official ID `claude-fable-5-1`, released September 1. Local routing also uses this family. Fable 5.2 remains unverified after exact-name official-domain searches and release-note inspection. |
| [Anthropic: Prompting Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1) | Keep authorized work moving, show concise progress, batch independent calls, use targeted edits and proportionate tests. Preserve constraints and unfinished work through compaction. API integrations must preserve returned thinking/history; this is not a command to expose private reasoning. |
| [Claude Code memory](https://code.claude.com/docs/en/memory) | Use a thin CLAUDE.md import to consume the shared AGENTS.md. Do not assume Markdown links perform native imports. |
| [Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md) | Account for the instruction chain and effective project-doc budget; verify root and nested project context. |
| [Agent Skills specification](https://agentskills.io/specification) | Portable core requires name and description, with optional license, compatibility, metadata and experimental allowed-tools. Claude model/context/hooks fields are host extensions. Keep support files bundled. |
| [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) | Runtime-specific frontmatter and tools must not be described as a universal agent format. |

API capability guidance is distinct from what a Claude Code or Codex host exposes. No account-wide model settings are changed by this audit.

## Framework corrections verified during integration

- [DTCG format](https://www.designtokens.org/tr/2025.10/format/) and [color](https://www.designtokens.org/tr/2025.10/color/): corrected Step 6 and the token skill's exchange examples and specification status.
- [DOJ Title II](https://www.ada.gov/resources/2024-03-08-web-rule/): replaced obsolete deadline and universal-law wording in Step 7.
- [DORA metrics](https://dora.dev/guides/dora-metrics/): the current fifth delivery metric is deployment rework rate. Reliability is tracked separately.
- [Google DESIGN.md](https://github.com/google-labs-code/design.md): linter exists; retained the workflow with actual version/result evidence and limited accessibility claims.
- [JTBD](https://www.christenseninstitute.org/theory/jobs-to-be-done/) and [ODI](https://strategyn.com/jobs-to-be-done-template/): distinguish qualitative discovery from quantitatively ranked unmet needs.

The initial framework reviewer confused a SNAP testimonial with the method acronym and offered an uncertain Vitest chronology. Integration corrected those report claims; they were not used to change the methods or install versions.

- [Claude skill permissions and packaging](https://code.claude.com/docs/en/skills): native allowed-tools can preapprove tool access; it does not replace task or release authorization. Step adapters retain valid metadata and bundle their full instructions.
- [FTC endorsement guidance](https://www.ftc.gov/business-guidance/resources/ftcs-endorsement-guides-what-people-are-asking): revised the existing incentive/testimonial tactic to require truthful opinions, usage consent and applicable material-connection disclosure.
