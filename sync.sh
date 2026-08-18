#!/usr/bin/env bash
# Refresh the worker source from the public rust-pds monorepo.
# NOTE: this overwrites src/ AND wrangler.toml — if you've already run setup.sh,
# re-run it after syncing (or sync into a fresh checkout). Cargo.toml is never
# touched; just bump the stelyph-core `rev` to the hash printed below.
#   MONOREPO=/path/to/rust-pds ./sync.sh     # defaults to ../rust-pds
set -euo pipefail
cd "$(dirname "$0")"
MONOREPO="${MONOREPO:-../rust-pds}"
WORKER="$MONOREPO/rust-worker"
[[ -d "$WORKER/src" ]] || { echo "ERROR: $WORKER/src not found. Set MONOREPO=/path/to/rust-pds." >&2; exit 1; }
rm -f src/*.rs; cp "$WORKER"/src/*.rs src/; cp "$WORKER/Cargo.lock" Cargo.lock
echo "synced src/ from $WORKER"
REV="$(git -C "$MONOREPO" rev-parse HEAD)"
echo "monorepo rev: $REV"
echo "ACTION: bump the stelyph-core 'rev' in Cargo.toml to: $REV"
echo "NOTE: wrangler.toml was NOT synced (it holds your per-deployment config)."
