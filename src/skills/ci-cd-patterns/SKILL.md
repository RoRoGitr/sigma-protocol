---
name: ci-cd-patterns
description: "GitHub Actions CI/CD patterns for TypeScript, Python, Go, and Docker workloads. Covers OIDC keyless cloud auth, reusable workflows, composite actions, SHA-pinned action versions, least-privilege permissions, caching (actions/cache@v5), matrix builds, concurrency controls, environment-gated production deploys, Docker GHA layer cache, monorepo path-aware CI, Dependabot for actions, and supply-chain hardening. Triggers on: github actions, CI/CD, workflow, pipeline, deploy, OIDC, reusable workflow, composite action, actions cache, SHA pin, Dependabot, matrix build, concurrency, canary deploy, blue-green deploy."
department: engineering
triggers:
  - github actions
  - CI/CD
  - workflow
  - pipeline
  - deploy
  - OIDC
  - reusable workflow
  - composite action
  - actions cache
  - SHA pin
  - Dependabot
  - matrix build
  - concurrency
  - canary deploy
  - blue-green deploy
  - continuous integration
  - continuous deployment
---

# CI/CD Patterns

GitHub Actions production patterns — OIDC keyless auth, reusable workflows, composite actions, caching, security hardening, and supply-chain hygiene.

> Version anchor: `actions/checkout@v6.0.3` · `actions/setup-node@v6.4.0` · `actions/cache@v5.0.5` · `docker/build-push-action@v5` · `actions/configure-aws-credentials@v4`. Verified 2026-06-04.

---

## When to Use

- Setting up or auditing a GitHub Actions pipeline
- Implementing OIDC keyless cloud authentication
- Extracting shared steps into reusable workflows or composite actions
- Adding caching, concurrency controls, or matrix builds
- Hardening a workflow against supply-chain attacks
- Wiring environment-gated production deploys

## When NOT to Use

- iOS/macOS Xcode CI — use the `asc-xcode-build` skill
- Terraform/Pulumi provisioning — infrastructure concerns, not pipeline config
- Monitoring and alerting — use `observability`

---

## Action Version Reference (June 2026)

Always pin to full 40-char SHA, not a mutable tag. Automate updates via Dependabot.

| Action | Latest tag | Use |
|--------|-----------|-----|
| `actions/checkout` | v6.0.3 | Source checkout |
| `actions/setup-node` | v6.4.0 | Node 24, auto npm cache from `packageManager` |
| `actions/setup-python` | v5 | Python setup |
| `actions/cache` | v5.0.5 | Node 24, cache service v2 (runner ≥ 2.327.1) |
| `docker/setup-buildx-action` | v3 | Buildx |
| `docker/build-push-action` | v5 | Build + push with GHA cache |
| `docker/login-action` | v3 | Registry auth |
| `aws-actions/configure-aws-credentials` | v4 | OIDC federation to AWS |

Pin example:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
```

---

## Security: Least-Privilege Permissions

Set `permissions: {}` at workflow level; grant only what each job needs.

```yaml
permissions: {}   # deny-all default

jobs:
  build:
    permissions:
      contents: read

  security-scan:
    permissions:
      contents: read
      security-events: write   # required to upload SARIF

  deploy-prod:
    permissions:
      contents: read
      id-token: write          # required for OIDC
```

Common grants:

| Need | Grant |
|------|-------|
| Checkout source | `contents: read` |
| OIDC cloud auth | `id-token: write` |
| Upload SARIF | `security-events: write` |
| Create PR | `pull-requests: write`, `contents: write` |
| Publish package | `packages: write` |

---

## OIDC Keyless Cloud Auth (no stored secrets)

Replace long-lived `CLOUD_API_KEY` secrets with OIDC federation. Credentials are short-lived and scoped to the job.

### AWS

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    environment: production
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
      - uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502  # v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-deploy
          aws-region: us-east-1
      - run: aws ecs update-service ...
```

Trust policy (IAM role) — scope to `environment:production`:

```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub":
        "repo:YOUR_ORG/YOUR_REPO:environment:production",
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    }
  }
}
```

**June 18 2026 note:** repos created or renamed after June 18 2026 get numeric IDs in the OIDC `sub` claim (e.g., `repo:octocat-123456/my-repo-456789:environment:production`). Opt in early via Settings → Actions → OIDC token customization and update trust policies before the cutover.

### GCP

```yaml
- uses: google-github-actions/auth@6fc4af4b145ae7821d527454aa9bd537d1f2dc5f  # v2
  with:
    workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github/providers/github
    service_account: deploy@my-project.iam.gserviceaccount.com
```

### Azure

```yaml
- uses: azure/login@a457da9ea143d694b1b9c7c869abb1ea73f5f3c9  # v2
  with:
    client-id: ${{ vars.AZURE_CLIENT_ID }}
    tenant-id: ${{ vars.AZURE_TENANT_ID }}
    subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

---

## Reusable Workflows

Define common build/test/deploy logic once; call from multiple repos. Supports typed inputs, secret passing, and job-output propagation.

### Callee (`.github/workflows/reusable-node-ci.yml`)

```yaml
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: "20"
        required: false
      working-directory:
        type: string
        default: "."
        required: false
    secrets:
      NPM_TOKEN:
        required: false
    outputs:
      build-artifact:
        description: "Artifact name uploaded by this workflow"
        value: ${{ jobs.build.outputs.artifact-name }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    outputs:
      artifact-name: ${{ steps.upload.outputs.artifact-id }}
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v6.4.0
        with:
          node-version: ${{ inputs.node-version }}
          cache: npm
      - run: npm ci
      - run: npm run build
      - id: upload
        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
        with:
          name: build-${{ github.sha }}
          path: dist/
```

### Caller

```yaml
jobs:
  ci:
    uses: ./.github/workflows/reusable-node-ci.yml
    with:
      node-version: "22"
      working-directory: apps/api
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      # OR: secrets: inherit  (passes all caller secrets)
```

Nesting limits: up to 10 levels on github.com, 4 levels on GHES.

---

## Composite Actions

Run in the calling job's environment — no new runner spin-up. Ideal for 5–10 shared setup steps.

### `action.yml` (in `.github/actions/setup-node-pnpm/`)

```yaml
name: Setup Node + pnpm
description: Install Node, pnpm, and restore caches

inputs:
  node-version:
    description: "Node version"
    default: "20"
  pnpm-version:
    description: "pnpm version"
    default: "9"

runs:
  using: composite
  steps:
    - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v6.4.0
      with:
        node-version: ${{ inputs.node-version }}
    - uses: pnpm/action-setup@b906affcce14559ad1aafd4ab0e942779e9f58b1  # v4
      with:
        version: ${{ inputs.pnpm-version }}
    - uses: actions/cache@d4323d4dc3a886b8d64a1ba37b423fa4000e6ab8  # v5.0.5
      with:
        path: ~/.pnpm-store
        key: pnpm-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}
        restore-keys: pnpm-${{ runner.os }}-
    - run: pnpm install --frozen-lockfile
      shell: bash
```

### Caller

```yaml
- uses: ./.github/actions/setup-node-pnpm
  with:
    node-version: "22"
```

Composite vs reusable workflow decision:

| Need | Use |
|------|-----|
| Share setup steps, same runner | Composite action |
| Parallel jobs, environment approvals, matrix support | Reusable workflow |
| Cross-repo sharing | Reusable workflow (shared-workflows repo) |

---

## Caching (actions/cache@v5)

Requires GitHub Actions runner ≥ 2.327.1. Cache service v2 with Node 24.

### Split restore/save (fine-grained control)

```yaml
- id: cache-restore
  uses: actions/cache/restore@d4323d4dc3a886b8d64a1ba37b423fa4000e6ab8  # v5.0.5
  with:
    path: ~/.npm
    key: npm-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: npm-${{ runner.os }}-

- run: npm ci

- uses: actions/cache/save@d4323d4dc3a886b8d64a1ba37b423fa4000e6ab8  # v5.0.5
  if: steps.cache-restore.outputs.cache-hit != 'true'
  with:
    path: ~/.npm
    key: ${{ steps.cache-restore.outputs.cache-primary-key }}
```

### pnpm

```yaml
- uses: actions/cache@d4323d4dc3a886b8d64a1ba37b423fa4000e6ab8  # v5.0.5
  with:
    path: ~/.pnpm-store
    key: pnpm-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: pnpm-${{ runner.os }}-
```

### Turborepo

```yaml
- uses: actions/cache@d4323d4dc3a886b8d64a1ba37b423fa4000e6ab8  # v5.0.5
  with:
    path: .turbo
    key: turbo-${{ runner.os }}-${{ github.sha }}
    restore-keys: turbo-${{ runner.os }}-
```

Cache limits: 10 GB per repo; 7-day LRU eviction.

---

## Concurrency Controls

Cancel in-progress runs for PRs, but never for `main`:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

For deployment workflows, scope to the environment to prevent parallel deploys:

```yaml
concurrency:
  group: deploy-${{ github.ref }}-production
  cancel-in-progress: false   # never cancel an in-flight deploy
```

---

## Monorepo Path-Aware CI (Matrix Fan-Out)

```yaml
jobs:
  detect:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.changes.outputs.matrix }}
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
      - id: changes
        uses: tj-actions/changed-files@d3d59640e01b7f5afc14f4e9c2a1cce24f79d11  # v46 SHA-pinned
        with:
          json: true
          dir_names: true
          dir_names_max_depth: 2
          files_yaml: |
            apps/api:
              - apps/api/**
            apps/web:
              - apps/web/**
            packages/shared:
              - packages/shared/**

  build:
    needs: detect
    if: needs.detect.outputs.matrix != '[]'
    strategy:
      fail-fast: false            # catch ALL failures, not just the first
      matrix:
        app: ${{ fromJson(needs.detect.outputs.matrix) }}
    uses: ./.github/workflows/reusable-node-ci.yml
    with:
      working-directory: ${{ matrix.app }}
```

---

## Environment-Gated Production Deploys

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
      - run: ./scripts/deploy.sh staging

  deploy-prod:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production        # required reviewers enforced here
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
      - uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502  # v4
        with:
          role-to-assume: ${{ vars.AWS_DEPLOY_ROLE }}
          aws-region: us-east-1
      - run: ./scripts/deploy.sh production
```

Trust policy scoped to `environment:production` means creds only issue AFTER environment approval — the approval gate is infrastructure-enforced, not bypassable in workflow code.

---

## Docker Build + Push (GHA Layer Cache)

```yaml
jobs:
  docker:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
        with:
          persist-credentials: false   # prevent credential leak in artifact-producing jobs

      - uses: docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f  # v3

      - uses: docker/login-action@c94ce9fb468520275223c153574b00df6fe4bcc9  # v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@ca052bb54ab0790a636c9b5f226502c73d547a25  # v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          provenance: true             # SLSA attestation
```

---

## Dependabot for Actions

Automate SHA + version bumps for Actions and Docker base images:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
      day: monday
    groups:
      actions-minor-patch:
        update-types:
          - minor
          - patch

  - package-ecosystem: docker
    directory: /
    schedule:
      interval: weekly
```

---

## Supply Chain Quick Reference

| Concern | Mitigation |
|---------|-----------|
| Mutable action tags (tj-actions compromise) | Pin all third-party actions to full 40-char SHA |
| New action version, unknown trust | 7-day cooldown: `pinact --min-age 7` or Renovate `minimumReleaseAge` — detects 80–90% of attacks |
| Untrusted code in `pull_request_target` | Never checkout PR code in `pull_request_target` without pinned, read-only steps; restrict write permissions |
| Long-lived cloud credentials | Replace with OIDC federation; no stored API keys for cloud providers |
| Org-level enforcement | GitHub Actions policy → Allowed Actions → SHA-only mode (enforced Aug 2025) |
| Runtime network exfiltration | Add `step-security/harden-runner@<SHA>` with `egress-policy: audit` to baseline, then `block` |
| npm/PyPI publish credentials | Trusted Publishing: OIDC from GitHub to registry; add `id-token: write` + `--provenance` |

Harden-Runner example:

```yaml
- uses: step-security/harden-runner@91182cccc01eb5e619899d80e4e971d6181294a7  # v2.10.1
  with:
    egress-policy: audit   # start with audit, then convert to block after baseline
    allowed-endpoints: >
      api.github.com:443
      registry.npmjs.org:443
```

---

## Full CI Template

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions: {}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
        with:
          persist-credentials: false

      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v6.4.0
        with:
          node-version: "20"
          cache: npm

      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test -- --coverage

  security:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
        with:
          fetch-depth: 0
          persist-credentials: false

      - uses: gitleaks/gitleaks-action@ff98106e4c7b2bc287b24eaf42907196329070c7  # v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Semgrep deprecated its GitHub Action — run the CLI directly.
      - name: Semgrep
        run: |
          pip install semgrep
          semgrep ci --config p/typescript --config p/security-audit
```

---

## Anti-Patterns

- Tag-based action pinning (`@v4`, `@main`) — tags are mutable; use full SHA
- Storing cloud credentials as GitHub secrets — replace with OIDC federation
- `permissions: write-all` or no `permissions:` block — grants unnecessary scopes
- `pull_request_target` + checkout of PR code — enables untrusted code to access secrets
- No `concurrency` block — parallel workflows overwrite each other's deployments
- `actions/cache@v3` or older — use v5 (Node 24, cache service v2)
- `returntocorp/semgrep-action@v1` — rebranded; use `semgrep/semgrep-action@v2`
- Skipping `fail-fast: false` in matrix — hides failures in other matrix cells

---

## Quality Gates

- [ ] All third-party actions pinned to full 40-char SHA
- [ ] `permissions: {}` at workflow level; per-job grants explicit and minimal
- [ ] OIDC federation configured for cloud deploys — no long-lived cloud credentials in secrets
- [ ] OIDC trust policy scoped to `environment:production` for production deploys
- [ ] `concurrency.cancel-in-progress` set (false for main, true for PRs)
- [ ] `actions/cache@v5` used (not v3 or v4)
- [ ] `fail-fast: false` on matrix builds
- [ ] `persist-credentials: false` on checkout for artifact-producing jobs
- [ ] Dependabot configured for `github-actions` package ecosystem
- [ ] June 2026 OIDC immutable `sub` cutover reviewed — numeric IDs for repos created/renamed after June 18 2026
