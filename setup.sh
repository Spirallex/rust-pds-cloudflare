#!/usr/bin/env bash
# Configure this template for a specific deployment: fills the __PLACEHOLDERS__ in
# wrangler.toml. Interactive, or set any value via env to skip its prompt:
#   WORKER_NAME=my-pds CF_ACCOUNT_ID=... PDS_ZONE_SUFFIX=pds.example.com ./setup.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! grep -q '__[A-Z0-9_]*__' wrangler.toml; then
  echo "wrangler.toml already configured (no placeholders left). Edit it by hand to change values." >&2
  exit 0
fi

ask() { # ask VAR "prompt" [default]
  local var="$1" msg="$2" def="${3:-}" cur val
  cur="${!var:-}"
  if [[ -n "$cur" ]]; then printf '%s' "$cur"; return; fi
  read -rp "$msg${def:+ [$def]}: " val </dev/tty 2>/dev/null || true
  printf '%s' "${val:-$def}"
}

WORKER_NAME="$(ask WORKER_NAME 'Worker name' 'my-pds')"
CF_ACCOUNT_ID="$(ask CF_ACCOUNT_ID 'Cloudflare account_id')"
R2_BUCKET="$(ask R2_BUCKET 'R2 bucket for blobs' "${WORKER_NAME}-blobs")"
PDS_ZONE_SUFFIX="$(ask PDS_ZONE_SUFFIX 'PDS zone suffix (handles end with this)' 'pds.example.com')"
PDS_SIGNUP_HOST="$(ask PDS_SIGNUP_HOST 'Signup host' "signup.${PDS_ZONE_SUFFIX}")"

[[ -n "$CF_ACCOUNT_ID" ]] || { echo "ERROR: CF_ACCOUNT_ID is required." >&2; exit 1; }

sed -i.bak \
  -e "s|__WORKER_NAME__|${WORKER_NAME}|g" \
  -e "s|__CF_ACCOUNT_ID__|${CF_ACCOUNT_ID}|g" \
  -e "s|__R2_BUCKET__|${R2_BUCKET}|g" \
  -e "s|__PDS_ZONE_SUFFIX__|${PDS_ZONE_SUFFIX}|g" \
  -e "s|__PDS_SIGNUP_HOST__|${PDS_SIGNUP_HOST}|g" \
  wrangler.toml
rm -f wrangler.toml.bak

echo
echo "wrangler.toml configured:"
echo "  name          = $WORKER_NAME"
echo "  account_id    = $CF_ACCOUNT_ID"
echo "  R2 bucket     = $R2_BUCKET"
echo "  zone suffix   = $PDS_ZONE_SUFFIX"
echo "  signup host   = $PDS_SIGNUP_HOST"
echo
echo "Next:"
echo "  wrangler r2 bucket create $R2_BUCKET"
echo "  wrangler secret put PDS_JWT_SECRET"
echo "  wrangler secret put PDS_KEY_PASSPHRASE"
echo "  ./deploy.sh"
