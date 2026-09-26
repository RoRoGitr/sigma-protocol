---
name: game-quality-planning
description: "Use for conditional game test strategy, accessibility scope, quality risks, and evidence requirements."
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Game Quality Planning

Open sibling gateway `../game-development/references/catalog.json`, select `quality`, and load its generated reference. In the author repo use `domains/game-development/catalog.json`. If missing, keep standard Sigma quality work and state the detailed pack is unavailable.

Order: identify material uncertainty/risk → select design, accessibility, technical, or player evidence → define smallest valid method and failure signal → name required proof and reviewer → decide revision/invalidation dependencies. Output a risk-to-evidence matrix that stays linked to the active step's gates.

Do not mandate outside testers, device matrix, playable build, or compliance claim. Accessibility guidance scopes review; it is not proof of compliance. A plan is `PREPARED`; only attached results can be tested.

Sources: [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/); [Xbox Accessibility Guidelines](https://learn.microsoft.com/en-us/gaming/accessibility/).
