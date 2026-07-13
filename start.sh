#!/usr/bin/env bash
set -euo pipefail

cd app

# Always derive a fresh effective session-signing key for this process.
# A persistent Render secret, when present, is used only as HMAC key material;
# a random 384-bit boot nonce guarantees rotation on every restart. The
# effective key is never printed or written to disk.
persistent_session_secret="${POLITIEK_SESSION_SECRET:-}"
boot_nonce="$(node -e "process.stdout.write(require('node:crypto').randomBytes(48).toString('base64url'))")"

if [ -n "$persistent_session_secret" ]; then
  POLITIEK_SESSION_SECRET="$(
    POLITIEK_SESSION_SECRET_BASE="$persistent_session_secret" \
    POLITIEK_SESSION_BOOT_NONCE="$boot_nonce" \
    node -e 'const crypto=require("node:crypto"); const base=process.env.POLITIEK_SESSION_SECRET_BASE||""; const nonce=process.env.POLITIEK_SESSION_BOOT_NONCE||""; process.stdout.write(crypto.createHmac("sha384",base).update(nonce).digest("base64url"));'
  )"
else
  POLITIEK_SESSION_SECRET="$boot_nonce"
fi

unset persistent_session_secret boot_nonce
export POLITIEK_SESSION_SECRET
export POLITIEK_SESSION_VERSION="${POLITIEK_SESSION_VERSION:-2026-07-13-v3}"
export POLITIEK_SESSION_HOURS="${POLITIEK_SESSION_HOURS:-8}"
export POLITIEK_FORCE_AUTH="1"
export POLITIEK_INTERNAL_VITE_PORT="${POLITIEK_INTERNAL_VITE_PORT:-5174}"

npm run online &
app_pid=$!

stop_app() {
  if kill -0 "$app_pid" 2>/dev/null; then
    kill -TERM "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null || true
  fi
}
trap stop_app TERM INT

if [ "${POLITIEK_RUNTIME_SELF_TEST:-1}" != "0" ]; then
  if ! node ../runtime-auth-self-test.mjs; then
    echo "Production-local authentication self-test failed; stopping service." >&2
    stop_app
    exit 1
  fi
fi

set +e
wait "$app_pid"
status=$?
set -e
trap - TERM INT
exit "$status"
