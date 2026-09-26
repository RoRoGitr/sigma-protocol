---
name: threejs
description: "Three.js 3D web graphics — scenes, geometry, materials, lighting, shaders, animation. Use when building 3D web experiences. Triggers on \'three.js\', \'3d web\', \'webgl\', \'3d scene\', \'three js\'."
department: graphics
---

# Three.js

Comprehensive Three.js reference covering all aspects of 3D web graphics.

> **Version:** Patterns target Three.js r170+.

## Section Router

| Task | Load Section |
|------|-------------|
| Scene setup, cameras, renderer, Object3D | `sections/fundamentals.md` |
| Shapes, BufferGeometry, instancing | `sections/geometry.md` |
| PBR, ShaderMaterial, material properties | `sections/materials.md` |
| Texture types, UV mapping, environment maps | `sections/textures.md` |
| Light types, shadows, IBL | `sections/lighting.md` |
| GLTF, texture loading, async patterns | `sections/loaders.md` |
| Raycasting, controls, mouse/touch | `sections/interaction.md` |
| Keyframe, skeletal, morph targets | `sections/animation.md` |
| EffectComposer, bloom, DOF | `sections/postprocessing.md` |
| GLSL, custom shaders, uniforms | `sections/shaders.md` |

Load the relevant section(s) based on the task at hand.

## When NOT to Use

- Not for 2D canvas/SVG graphics — use algorithmic-art or web-artifacts-builder
- Not for native mobile 3D (SceneKit, ARKit) — web-based Three.js only
- Not for game engines (Unity, Unreal) — lightweight web 3D rendering
- Not for video production — real-time 3D rendering, not offline video

## Related Skills

- `composition-patterns` — engineering/frontend
- `frontend-design` — engineering/frontend
- `react-performance` — engineering/frontend
- `brand` — design

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Grep, Glob
