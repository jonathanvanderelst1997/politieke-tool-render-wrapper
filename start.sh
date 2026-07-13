#!/usr/bin/env bash
set -euo pipefail

cd app

# Keep the login password and the session-signing secret strictly separate.
# When Render has no persistent POLITIEK_SESSION_SECRET configured, generate an
# ephemeral 384-bit secret for this process. A restart then invalidates every
# earlier session automatically without ever writing the secret to GitHub.
if [ -z "${POLITIEK_SESSION_SECRET:-}" ]; then
  POLITIEK_SESSION_SECRET="$(node -e "process.stdout.write(require('node:crypto').randomBytes(48).toString('base64url'))")"
  export POLITIEK_SESSION_SECRET
fi

export POLITIEK_SESSION_VERSION="${POLITIEK_SESSION_VERSION:-2026-07-13-v2}"
export POLITIEK_SESSION_HOURS="${POLITIEK_SESSION_HOURS:-8}"
export POLITIEK_FORCE_AUTH="1"
export POLITIEK_INTERNAL_VITE_PORT="${POLITIEK_INTERNAL_VITE_PORT:-5174}"

exec npm run online
