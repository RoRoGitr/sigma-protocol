---
name: game-art-pipeline
description: "Use for conditional game art direction, asset planning, source rights, and acceptance-evidence preparation."
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Game Art Pipeline

Open sibling gateway `../game-development/references/catalog.json`; select `characters` or `environments` and load the generated workflow reference. In an author checkout prefer `domains/game-development/catalog.json`. Without it, report detailed art-pack missing and do not invent a house pipeline.

For a selected 3D asset, plan in order: reference views and source rights → component/clothing/prop/material breakdown → geometry and silhouette → multiview review → UV and textures → rig/deformation where it moves → animation and contact checks → engine acceptance evidence. Output a versioned asset brief with provenance, dependencies, reviewer, acceptance checklist, and revision trigger.

For 2D, substitute the applicable sprite/illustration/animation states and export evidence. For non-visual work, mark this workflow not-applicable with a reason. Do not set an engine, format, budget, art freeze, tool, or numeric target by default. Never claim render, rig, export, import, or performance results without external proof.

Sources: [Khronos glTF](https://www.khronos.org/gltf/) describes an interchange standard; it does not validate an import. Preserve catalog source IDs for character/environment practices.
