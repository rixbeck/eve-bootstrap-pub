# eve-bootstrap-pub

Public entrypoint for bootstrapping an Ubuntu host using the **private** `eve-bootstrap` repo.

## Quick start

Prerequisites:
- Ubuntu 24.04
- `sudo` access
- A GitHub token with access to the private repo (**required**): `GH_TOKEN`

### Option A — piped (may not have TTY)

```bash
export GH_TOKEN=github_pat_...
curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh | bash
```

### Option A2 — file-based token (matches ~/.config/eve-bootstrap/.env convention)

```bash
mkdir -p ~/.config/eve-bootstrap
printf '%s\n' 'GH_TOKEN=github_pat_...' > ~/.config/eve-bootstrap/.env
chmod 600 ~/.config/eve-bootstrap/.env
curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh | bash
```

### Option B — interactive TTY (recommended)

Use this when the private installer may need to prompt (git-crypt key / secrets wizard).

```bash
export GH_TOKEN=github_pat_...
curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh -o /tmp/eve-bootstrap.sh
bash /tmp/eve-bootstrap.sh
```

What it does:
- installs `git` and `gh` if missing
- authenticates to GitHub using `GH_TOKEN`
- clones/updates the private repo to `~/.local/src/eve-bootstrap`
- runs `~/.local/src/eve-bootstrap/bootstrap.sh`

## Notes

- GH auth is intentionally **non-interactive**.
  - Preferred: `GH_TOKEN` set via environment.
  - Fallback: `~/.config/eve-bootstrap/.env` containing `GH_TOKEN=...`.
- Whether the rest of the flow is interactive depends on how you run the script:
  - piped (`curl ... | bash`) often has no TTY
  - file + `bash` gives you a TTY

