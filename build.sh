#!/usr/bin/env bash
set -euo pipefail

if [ -z "${GH_DEPLOY_KEY_B64:-}" ]; then
  echo "GH_DEPLOY_KEY_B64 ontbreekt." >&2
  exit 1
fi

rm -rf app
mkdir -p "$HOME/.ssh"
key_path="$HOME/.ssh/render_politieke_tool_key"
printf "%s" "$GH_DEPLOY_KEY_B64" | base64 -d > "$key_path"
chmod 600 "$key_path"
trap 'rm -f "$key_path"' EXIT
ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

private_branch="${POLITIEK_PRIVATE_BRANCH:-main}"
GIT_SSH_COMMAND="ssh -i $key_path -o IdentitiesOnly=yes" \
  git clone --depth 1 --branch "$private_branch" \
  git@github.com:jonathanvanderelst1997/politieke-tool-jonathan.git app

cd app
private_commit="$(git rev-parse HEAD)"
echo "PRIVATE_APP_COMMIT=$private_commit"
printf "%s\n" "$private_commit" > .render-private-commit

npm ci
npm run build
