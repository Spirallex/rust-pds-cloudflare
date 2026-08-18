# rust-pds-cloudflare

A GitHub **template** for running your own [AT Protocol](https://atproto.com) PDS
(Personal Data Server) on **Cloudflare Workers**, in Rust. Click **"Use this
template"**, run two scripts, and you have a live PDS — accounts and repos on
Workers + Durable Objects, blobs in R2.

The PDS engine is [`stelyph-core`](https://github.com/Spirallex/rust-pds) (pulled
as a pinned git dependency). This repo is the thin, reusable deploy shell around
it.

---

## What you'll end up with

- Your own PDS reachable at `https://<worker>.<subdomain>.workers.dev` (and, optionally, your own domain)
- Account creation + repo hosting, federating with the AT Protocol network
- Media blobs stored in Cloudflare R2

## Step 0 — Create your repo from this template

**In the browser:** click the green **"Use this template" → Create a new repository**.

**Or with the GitHub CLI:**
```bash
gh repo create <you>/my-pds --private --template Spirallex/rust-pds-cloudflare --clone
cd my-pds
```
You get a fresh repo with its own history — none of the template's commits.

## Step 1 — Prerequisites

| Need | How |
|---|---|
| **Cloudflare account, Workers _Paid_ plan** | Durable Objects **and** R2 require the paid plan (~$5/mo). |
| **Rust toolchain** | [rustup.rs](https://rustup.rs) — `deploy.sh` auto-adds the `wasm32` target + `worker-build`. |
| **wrangler** (Cloudflare CLI) | `npm i -g wrangler` then `wrangler login`. |

Find your **account id** with `wrangler whoami` (or the Cloudflare dashboard → Workers & Pages, right sidebar).

## Step 2 — Configure your deployment

```bash
./setup.sh
```
It prompts for (or reads from env) the values that go into `wrangler.toml`:

| Value | What it is |
|---|---|
| `WORKER_NAME` | your Cloudflare Worker script name |
| `CF_ACCOUNT_ID` | your Cloudflare account id |
| `R2_BUCKET` | R2 bucket for blobs (avatars/media) |
| `PDS_ZONE_SUFFIX` | the domain new handles end with, e.g. `pds.example.com` |
| `PDS_SIGNUP_HOST` | where the signup page + `createAccount` are served |

Non-interactive:
```bash
WORKER_NAME=my-pds CF_ACCOUNT_ID=abc123 PDS_ZONE_SUFFIX=pds.example.com ./setup.sh
```
`deploy.sh` refuses to run while any placeholder is still present, so you can't
accidentally ship an unconfigured worker.

## Step 3 — Provision Cloudflare resources

```bash
# R2 bucket for blobs (name is printed by setup.sh)
wrangler r2 bucket create <your-bucket>

# Secrets — never stored in the repo. Generate strong values:
openssl rand -hex 32 | wrangler secret put PDS_JWT_SECRET     # session-JWT / DPoP-nonce secret
wrangler secret put PDS_KEY_PASSPHRASE                        # argon2id passphrase wrapping signing keys
```
> ⚠️ Keep both secrets safe and stable. Rotating `PDS_JWT_SECRET` invalidates all
> sessions; losing `PDS_KEY_PASSPHRASE` means signing keys can't be unwrapped.

## Step 4 — Deploy

```bash
./deploy.sh              # build (release wasm) + wrangler deploy
./deploy.sh --dry-run    # build only, verify the wasm compiles
```
Note the `*.workers.dev` URL wrangler prints, then smoke-test it:
```bash
curl https://<worker>.<subdomain>.workers.dev/xrpc/com.atproto.server.describeServer
```
A JSON response with `availableUserDomains` means the PDS is live.

## Step 5 — Serve on your own domain (for real use)

This template deploys the Worker **script + bindings** only — it does **not**
manage routes, DNS, or TLS, so it never fights an infra-as-code setup. To put the
PDS on your domain, pick one:

- **Single hostname (simplest):** add a custom-domain route to `wrangler.toml` and redeploy —
  ```toml
  routes = [{ pattern = "pds.example.com", custom_domain = true }]
  ```
  Cloudflare auto-creates the DNS record and certificate for that one name.
- **Wildcard handles (`*.pds.example.com`):** custom-domain routes don't support
  wildcards. You need a proxied wildcard DNS record **plus** an Advanced
  Certificate / Total TLS covering `*.pds.example.com` (Universal SSL only covers
  one label). See [Cloudflare: Workers Routes](https://developers.cloudflare.com/workers/configuration/routing/routes/).
- **Dashboard:** Workers & Pages → your worker → Settings → Domains & Routes.

## Keeping the PDS engine up to date

`src/` is copied from the monorepo and will drift. To refresh and re-pin:
```bash
MONOREPO=/path/to/rust-pds ./sync.sh   # then bump the stelyph-core `rev` it prints, in Cargo.toml
```
(If you don't have the monorepo checked out, just bump the `rev` in `Cargo.toml`
to a newer commit of [Spirallex/rust-pds](https://github.com/Spirallex/rust-pds).)

## Troubleshooting

| Symptom | Fix |
|---|---|
| `wrangler.toml still has __PLACEHOLDERS__` | Run `./setup.sh`. |
| `bucket ... does not exist` on deploy | `wrangler r2 bucket create <bucket>`. |
| Durable Objects / R2 rejected | You're on the free plan — DO + R2 need Workers **Paid**. |
| wasm-bindgen schema-version error | `worker-build` version drift; `cargo install worker-build --version ^0.8`. |
| Build can't find `stelyph-core` | Network/git issue reaching the public monorepo; retry, or check the `rev` exists. |

## License

[PolyForm Noncommercial 1.0.0](LICENSE) — inherited from `stelyph-core`.
