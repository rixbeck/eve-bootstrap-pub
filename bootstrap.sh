#!/usr/bin/env bash
set -euo pipefail

# eve-bootstrap-pub bootstrapper
# Public entrypoint for bringing up a machine using the *private* eve-bootstrap repo.
#
# GH auth is **non-interactive**.
# - Preferred: provide GH_TOKEN via environment.
# - Fallback: store GH_TOKEN in ~/.config/eve-bootstrap/.env (key=value) and the script will load it.
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

# gh is optional; we prefer plain git + GH_TOKEN header auth for non-interactive runs.

# Optional fallback: load GH_TOKEN from ~/.config/eve-bootstrap/.env
# (This keeps VM bringup zero-config except the two critical secrets.)
EVE_BOOTSTRAP_ENV_FILE="${EVE_BOOTSTRAP_ENV_FILE:-$HOME/.config/eve-bootstrap/.env}"
if [[ -z "${GH_TOKEN:-}" && -f "$EVE_BOOTSTRAP_ENV_FILE" ]]; then
  echo "[bootstrap] Loading secrets from $EVE_BOOTSTRAP_ENV_FILE" >&2
  # shellcheck disable=SC1090
  set -a
  . "$EVE_BOOTSTRAP_ENV_FILE"
  set +a
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
  cat >&2 <<'EOM'
[bootstrap] Missing GH_TOKEN.

Provide it either as:
  - env var: GH_TOKEN=... (recommended for one-shot runs)
  - file: ~/.config/eve-bootstrap/.env containing GH_TOKEN=...
EOM
  exit 2
fi

echo "[bootstrap] Preparing GitHub auth header (GH_TOKEN)"
auth_b64="$(printf 'x-access-token:%s' "$GH_TOKEN" | base64 | tr -d '\n')"

if [[ -d "${CHECKOUT_DIR}/.git" ]]; then
  echo "[bootstrap] Updating private repo in ${CHECKOUT_DIR}"
  git -C "${CHECKOUT_DIR}" \
    -c http.https://github.com/.extraheader="AUTHORIZATION: basic ${auth_b64}" \
    -c filter.git-crypt.smudge= \
    -c filter.git-crypt.clean= \
    -c filter.git-crypt.required=false \
    pull --ff-only
else
  echo "[bootstrap] Cloning private repo into ${CHECKOUT_DIR}"
  git -c http.https://github.com/.extraheader="AUTHORIZATION: basic ${auth_b64}" \
    clone "${REPO_URL}" "${CHECKOUT_DIR}"
fi

echo "[bootstrap] Delegating to private bootstrap.sh"
cd "${CHECKOUT_DIR}"
chmod +x ./bootstrap.sh || true
./bootstrap.sh
