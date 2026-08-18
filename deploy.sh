#!/usr/bin/env bash
# One-command build + deploy to Cloudflare.
#   ./deploy.sh            # build (release) + wrangler deploy
#   ./deploy.sh --dry-run  # build only (verify the wasm compiles)
set -euo pipefail
cd "$(dirname "$0")"

if grep -q '__[A-Z0-9_]*__' wrangler.toml; then
  echo "ERROR: wrangler.toml still has __PLACEHOLDERS__ — run ./setup.sh first." >&2
  exit 1
fi

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

echo "==> checking toolchain"
rustup target list --installed | grep -q wasm32-unknown-unknown \
  || { echo "installing wasm32 target"; rustup target add wasm32-unknown-unknown; }
command -v worker-build >/dev/null 2>&1 \
  || { echo "installing worker-build"; cargo install -q worker-build --version '^0.8'; }

if [[ "$DRY_RUN" == "1" ]]; then
  echo "==> building (dry run, no deploy)"; worker-build --release
  echo "==> OK: wasm built. Skipping deploy (--dry-run)."; exit 0
fi

command -v wrangler >/dev/null 2>&1 \
  || { echo "ERROR: wrangler not found. 'npm i -g wrangler' or use 'npx wrangler'." >&2; exit 1; }
echo "==> deploying"; wrangler deploy
echo "==> done. If you haven't yet: wrangler secret put PDS_JWT_SECRET / PDS_KEY_PASSPHRASE"
