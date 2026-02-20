# eve-bootstrap-pub

Public entrypoint for bootstrapping an Ubuntu host using the **private** `eve-bootstrap` repo.

## Quick start (non-interactive)

Prerequisites:
- Ubuntu 24.04
- `sudo` access
- A GitHub token with access to the private repo

```bash
export GH_TOKEN=github_pat_...
curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh | bash
```

What it does:
- installs `git` and `gh` if missing
- authenticates to GitHub using `GH_TOKEN`
- clones/updates the private repo to `~/.local/src/eve-bootstrap`
- runs `~/.local/src/eve-bootstrap/install.sh`

## Notes

- This script is intentionally **non-interactive**.
- If the private installer needs to prompt (e.g. missing secrets), run it with a TTY.

