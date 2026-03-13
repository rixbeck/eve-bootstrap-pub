# eve-bootstrap-pub

Public entrypoint for bootstrapping an Ubuntu host using **internal SSOT** sources over the tailnet.

## Quick start

Prerequisites:
- Ubuntu 24.04
- `sudo` access
- **Tailscale unattended join key** (required): `TAILSCALE_AUTHKEY`
- Internal git base URL (required): `GIT_EVE_BASEURL`
  - example: `http://gogs.ts.neologik.hu/rix`

### Option A — piped (may not have TTY)

```bash
export TAILSCALE_AUTHKEY=tskey-auth-...
export GIT_EVE_BASEURL=http://gogs.ts.neologik.hu/rix
curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh | bash
```

### Option B — interactive TTY (recommended)

```bash
export TAILSCALE_AUTHKEY=tskey-auth-...
export GIT_EVE_BASEURL=http://gogs.ts.neologik.hu/rix
curl -fsSL https://raw.githubusercontent.com/rixbeck/eve-bootstrap-pub/main/bootstrap.sh -o /tmp/eve-bootstrap.sh
bash /tmp/eve-bootstrap.sh
```

What it does:
- installs `git` + `curl` if missing
- installs Tailscale if missing
- runs `tailscale up` **unattended** using `TAILSCALE_AUTHKEY` (early, required)
- clones/updates `eve-bootstrap` from: `${GIT_EVE_BASEURL}/eve-bootstrap.git`
- runs `bootstrap.sh` from that checkout

## Notes

- This bootstrapper **does not use GitHub auth** and does **not** require `GH_TOKEN`.
- Whether later steps are interactive depends on how you run the script:
  - piped (`curl ... | bash`) often has no TTY
  - file + `bash` gives you a TTY
