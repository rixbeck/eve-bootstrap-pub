#!/usr/bin/env bash
set -euo pipefail

# eve-bootstrap-pub bootstrapper
# Public entrypoint for bringing up a machine using the *private* eve-bootstrap repo.
#
# GH auth is **non-interactive** (GH_TOKEN must be provided via env).
# The rest of the flow is delegated to the private repo's bootstrap.sh.
#
# Usage (piped; may not have TTY):
#   export GH_TOKEN=github_pat_...
#   curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh | bash
#
# Usage (interactive TTY recommended for secrets prompts):
#   export GH_TOKEN=github_pat_...
#   curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh -o /tmp/eve-bootstrap.sh
#   bash /tmp/eve-bootstrap.sh

REPO_URL="https://github.com/rixbeck/eve-bootstrap.git"
CHECKOUT_DIR="${HOME}/.local/src/eve-bootstrap"

mkdir -p "${HOME}/.local/src"

if ! command -v git >/dev/null 2>&1; then
  echo "[bootstrap] Installing git..."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "[bootstrap] Installing gh (GitHub CLI)..."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gh
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
  cat >&2 <<'EOM'
[bootstrap] Missing GH_TOKEN.

This bootstrapper needs GH_TOKEN to clone the private eve-bootstrap repo.
EOM
  exit 2
fi

# Explicitly authenticate gh with GH_TOKEN (clear any stale auth state)
echo "[bootstrap] Authenticating gh with GH_TOKEN"
rm -rf ~/.config/gh/hosts.yml ~/.config/gh/config.yml 2>/dev/null || true
echo "$GH_TOKEN" | gh auth login --with-token --hostname github.com

echo "[bootstrap] Verifying authentication"
if ! gh auth status >/dev/null 2>&1; then
  echo "[bootstrap] ERROR: gh auth failed despite GH_TOKEN being set" >&2
  exit 1
fi

echo "[bootstrap] Cloning/updating private repo into $CHECKOUT_DIR"
if [[ -d "${CHECKOUT_DIR}/.git" ]]; then
  # Use gh so private repo sync works with GH_TOKEN (no git credential prompts)
  (cd "${CHECKOUT_DIR}" && gh repo sync)
else
  # Use gh so private repo clone works without additional git credential prompts
  gh repo clone rixbeck/eve-bootstrap "$CHECKOUT_DIR"
fi

echo "[bootstrap] Delegating to private bootstrap.sh"
cd "${CHECKOUT_DIR}"
chmod +x ./bootstrap.sh || true
./bootstrap.sh
