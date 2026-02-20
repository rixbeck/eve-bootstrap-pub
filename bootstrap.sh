#!/usr/bin/env bash
set -euo pipefail

# eve-bootstrap-pub bootstrapper
# Non-interactive entrypoint for bringing up a machine using the *private* eve-bootstrap repo.
#
# Usage:
#   export GH_TOKEN=github_pat_...
#   curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh | bash
#
# Notes:
# - This script is non-interactive; it will not prompt for secrets.
# - If secrets are missing, the private repo's install.sh may require an interactive TTY.

REPO_URL="https://github.com/rixbeck/eve-bootstrap.git"
CHECKOUT_DIR="${HOME}/.local/src/eve-bootstrap"

mkdir -p "${HOME}/.local/src"

if ! command -v git >/dev/null 2>&1; then
  echo "[bootstrap] Installing git..."
  sudo apt-get update -y
  sudo apt-get install -y git
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "[bootstrap] Installing gh (GitHub CLI)..."
  sudo apt-get update -y
  sudo apt-get install -y gh
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
  cat >&2 <<'EOM'
[bootstrap] Missing GH_TOKEN.

This bootstrapper needs GH_TOKEN to clone the private eve-bootstrap repo.
EOM
  exit 2
fi

# Non-interactive auth for gh
printf '%s' "$GH_TOKEN" | gh auth login --with-token >/dev/null

echo "[bootstrap] Cloning/updating private repo into $CHECKOUT_DIR"
if [[ -d "${CHECKOUT_DIR}/.git" ]]; then
  git -C "${CHECKOUT_DIR}" pull --ff-only
else
  git clone "${REPO_URL}" "${CHECKOUT_DIR}"
fi

echo "[bootstrap] Running private installer"
cd "${CHECKOUT_DIR}"
chmod +x ./install.sh || true
./install.sh
