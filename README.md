# rust-pds-cloudflare

A GitHub **template** for deploying a Rust [AT Protocol](https://atproto.com) PDS
to **Cloudflare Workers**. The PDS logic comes from
[`stelyph-core`](https://github.com/Spirallex/rust-pds) (pulled as a pinned git
dependency); this repo is the thin, reusable deploy shell around it — Durable
Objects + R2 + a one-command build.

> Created something from this template? You get a fresh copy with no history.
> Run `./setup.sh`, set two secrets, and `./deploy.sh`.

## Quick start

```bash
# 1. Make your own repo from this template (or click "Use this template" on GitHub)
gh repo create <you>/my-pds --private --template Spirallex/rust-pds-cloudflare --clone
cd my-pds

# 2. Fill in per-deployment config (worker name, account_id, zone, signup host)
./setup.sh

# 3. Create the R2 blob bucket + set secrets
wrangler login
wrangler r2 bucket create <your-bucket>            # name is printed by setup.sh
wrangler secret put PDS_JWT_SECRET                 # HMAC secret for session JWTs / DPoP nonce seed
wrangler secret put PDS_KEY_PASSPHRASE             # argon2id passphrase wrapping signing keys at rest

# 4. Ship it
./deploy.sh          # build (release) + wrangler deploy
./deploy.sh --dry-run  # build only, verify the wasm compiles
```

## What `setup.sh` fills in

`wrangler.toml` ships with `__PLACEHOLDERS__`; `deploy.sh` refuses to run until
they're replaced. `setup.sh` prompts for (or reads from env):

| Value | Meaning |
|---|---|
| `WORKER_NAME` | the Cloudflare Worker script name |
| `CF_ACCOUNT_ID` | your Cloudflare account id |
| `R2_BUCKET` | R2 bucket for blobs (avatars/media/CAR chunks) |
| `PDS_ZONE_SUFFIX` | domain new handles end with (advertised as `availableUserDomains`) |
| `PDS_SIGNUP_HOST` | where the signup page + `createAccount` are served |

Non-interactive:
```bash
WORKER_NAME=my-pds CF_ACCOUNT_ID=abc123 PDS_ZONE_SUFFIX=pds.example.com ./setup.sh
```

## Prerequisites

- Rust + `wasm32-unknown-unknown` target (`deploy.sh` installs it if missing)
- [`wrangler`](https://developers.cloudflare.com/workers/wrangler/) (`npm i -g wrangler`) + `wrangler login`
- A Cloudflare account with Workers **Paid** (Durable Objects + R2)

## Keeping the worker source current

`src/` is copied from the monorepo and will drift. Refresh it and re-pin:
```bash
MONOREPO=/path/to/rust-pds ./sync.sh   # then bump the stelyph-core rev it prints, in Cargo.toml
```

## What this template does NOT manage

Routes, DNS, and the TLS certificate. `wrangler deploy` ships only the Worker
**script + bindings** (DOs, R2, vars, secrets). Point a route/DNS at the worker
with your own IaC (Pulumi/Terraform) or the Cloudflare dashboard.

## License

[PolyForm Noncommercial 1.0.0](LICENSE) — inherited from `stelyph-core`.
