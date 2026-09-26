#!/usr/bin/env bash
# Sigma Protocol installer — one command from a cloned checkout.
# Usage:  git clone https://github.com/Dallionking/sigma-protocol-public sigma-protocol-v2 && cd sigma-protocol-v2
#         bash scripts/install.sh            # core install (Claude Code + departments)
#         bash scripts/install.sh --all      # core + SigmaHQ board (optional)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33mWARN:\033[0m %s\n' "$1"; }
fail()  { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

# --- Prereqs -----------------------------------------------------------------
info "Checking prerequisites (git, node >= 20, python3, jq)..."
command -v git    >/dev/null 2>&1 || fail "git is required."
command -v node   >/dev/null 2>&1 || fail "node (>= 20) is required — https://nodejs.org"
command -v python3 >/dev/null 2>&1 || fail "python3 is required."
command -v jq     >/dev/null 2>&1 || warn "jq not found — installers fall back to python3 where possible, but installing jq is recommended."

# --- Render + validate canonical surfaces -------------------------------------
info "Rendering steps -> commands/ and validating wiring..."
bash "$REPO_ROOT/scripts/sync-steps-to-platforms.sh" >/dev/null
node "$REPO_ROOT/scripts/verify/validate-step-wiring.mjs" || fail "Step wiring validation failed — the checkout is inconsistent."

# --- Core installs -------------------------------------------------------------
info "Installing Claude Code surfaces (skills, agents, gates)..."
bash "$REPO_ROOT/scripts/install-claude-code.sh" || fail "install-claude-code.sh failed."

info "Installing the department system (composer + overlays)..."
bash "$REPO_ROOT/scripts/install-departments.sh" || fail "install-departments.sh failed."

# --- Optional: SigmaHQ ----------------------------------------------------------
if [ "${1:-}" = "--all" ]; then
  info "Installing SigmaHQ (kanban + mission board)..."
  bash "$REPO_ROOT/scripts/install-sigmahq.sh" || warn "SigmaHQ install did not complete — it is optional; see docs/SIGMAHQ.md."
fi

info "Done. Verify with: node scripts/validate-cascade.mjs"
info "Then open your agent CLI and run: /step-1-ideation  (see GETTING-STARTED.md)"
