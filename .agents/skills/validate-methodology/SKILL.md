---
name: validate-methodology
metadata:
  canonical_source: "steps/validate-methodology"
description: "Validate compliance with the active Steps 0-15 methodology, including conditional Steps 1.5 and 11.5."
---

# @validate-methodology

Apply the current canonical contract in [the bundled contract](references/step.md).

## Scope

- Steps `0-15`
- Conditional Steps `1.5` and `11.5`
- Standalone backlog conversion commands after Steps 5 and 11
- Optional standalone orchestration after Step 11

The command is read-only. Report each artifact as complete, missing, skipped, or optional. Do not require archived outputs, vendor-specific mirrors, or a schema that the active command does not require.

## Usage

```bash
@validate-methodology
@validate-methodology --detailed
@validate-methodology --fix
```

With `--fix`, suggest the exact next command and what it creates. Do not mutate the project.

## Verification

Before reporting, read [the bundled contract](references/step.md) in this checkout and apply its artifact checklist and conditional rules. Maintainers regenerate the bundled contract from `steps/validate-methodology` using `scripts/sync-steps-to-platforms.sh`; installed users do not need the source checkout.
