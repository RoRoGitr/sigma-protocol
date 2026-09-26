# Pre-commit Secret Scanning

This repo uses gitleaks to block staged secrets before they can be committed.

## Install gitleaks

```bash
brew install gitleaks
```

## Enable the hook

From the repo root:

```bash
git config core.hooksPath scripts/hooks
chmod +x scripts/hooks/pre-commit scripts/hooks/pre-commit-secrets.sh
```

The repo-local `scripts/hooks/pre-commit` wrapper runs `scripts/hooks/pre-commit-secrets.sh` first. If a global pipeline hook exists at `~/.githooks/pre-commit`, the wrapper runs it after the secrets scan.

## Manual check

```bash
bash scripts/hooks/pre-commit-secrets.sh
```

The hook fails closed if `gitleaks` is missing or if staged secrets are detected.
