#!/usr/bin/env bash
set -euo pipefail

# eve-bootstrap-pub bootstrapper
# Public entrypoint for bringing up a machine using internal SSOT (tailnet) sources.
#
# Contract (required env):
#   - TAILSCALE_AUTHKEY  (unattended join)
#   - GIT_EVE_BASEURL    (internal git base, e.g. http://gogs.ts.neologik.hu/rix)
#
# Usage (piped; may not have TTY):
#   export TAILSCALE_AUTHKEY=tskey-auth-...
#   export GIT_EVE_BASEURL=http://gogs.ts.neologik.hu/rix
#   curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh | bash
#
# Usage (interactive TTY recommended for any later prompts):
#   curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh -o /tmp/eve-bootstrap.sh
#   bash /tmp/eve-bootstrap.sh

CHECKOUT_DIR="${EVE_BOOTSTRAP_DIR:-${HOME}/.local/src/eve-bootstrap}"
REPO_NAME="${EVE_BOOTSTRAP_REPO:-eve-bootstrap}"

need_env() {
  local k="$1"
  if [[ -z "${!k:-}" ]]; then
    echo "[bootstrap] Missing required env: $k" >&2
    exit 2
  fi
}

need_env TAILSCALE_AUTHKEY
need_env GIT_EVE_BASEURL

# Derived source (read-only clone)
REPO_URL="${GIT_EVE_BASEURL}/${REPO_NAME}.git"

mkdir -p "$(dirname "$CHECKOUT_DIR")"

if ! command -v sudo >/dev/null 2>&1; then
  echo "[bootstrap] ERROR: sudo is required" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "[bootstrap] Installing git..."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "[bootstrap] Installing curl..."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl
fi

# Tailscale (unattended) must be available before pulling internal SSOT sources.
if ! command -v tailscale >/dev/null 2>&1; then
  echo "[bootstrap] Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "[bootstrap] Bringing up Tailscale (unattended)"
# Note: do not pass empty --hostname flag.
if [[ -n "${EVE_TAILSCALE_HOSTNAME:-}" ]]; then
  sudo tailscale up --authkey "${TAILSCALE_AUTHKEY}" --hostname "${EVE_TAILSCALE_HOSTNAME}" --ssh --accept-dns=true
else
  sudo tailscale up --authkey "${TAILSCALE_AUTHKEY}" --ssh --accept-dns=true
fi

echo "[bootstrap] Cloning/updating eve-bootstrap from internal SSOT: $REPO_URL"
if [[ -d "${CHECKOUT_DIR}/.git" ]]; then
  # Conservative update: hard-reset to remote branch.
  (
    cd "${CHECKOUT_DIR}"
    git fetch --all --prune
    branch="$(git rev-parse --abbrev-ref HEAD)"
    git reset --hard "origin/${branch}"
  )
else
  git clone "$REPO_URL" "$CHECKOUT_DIR"
fi

echo "[bootstrap] Delegating to bootstrap.sh in $CHECKOUT_DIR"
cd "${CHECKOUT_DIR}"
chmod +x ./bootstrap.sh || true
./bootstrap.sh
