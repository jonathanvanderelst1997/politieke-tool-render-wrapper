#!/usr/bin/env bash
set -euo pipefail

if [ -z "${GH_DEPLOY_KEY_B64:-}" ]; then
  echo "GH_DEPLOY_KEY_B64 ontbreekt." >&2
  exit 1
fi

rm -rf app
mkdir -p "$HOME/.ssh"
printf "%s" "$GH_DEPLOY_KEY_B64" | base64 -d > "$HOME/.ssh/render_politieke_tool_key"
chmod 600 "$HOME/.ssh/render_politieke_tool_key"
ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

GIT_SSH_COMMAND="ssh -i $HOME/.ssh/render_politieke_tool_key -o IdentitiesOnly=yes" \
  git clone --depth 1 git@github.com:jonathanvanderelst1997/politieke-tool-jonathan.git app

cd app
npm ci
npm run build
