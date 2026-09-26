#### Boilerplate module manifest (when `.sigma/boilerplate.json` exists)

1. **Read** `.sigma/modules.manifest.json` if present.
2. **Cross-check** Step 4 screen inventory / Step 10 features against enabled modules (`modules.*.enabled === true`).
3. **Record** inherited routes and module file paths in the step output — do not re-scaffold modules the boilerplate already ships.
4. **Module ID vocabulary** must match `templates/boilerplates/_shared/module-catalog.json` (see `docs/references/integration-packs-catalog.md`).

If manifest is missing but `boilerplate.json` exists → note as gap; do not invent module IDs.
