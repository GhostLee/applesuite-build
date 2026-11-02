#!/bin/bash
set -euo pipefail
umask 077
[[ "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]]
printf '%s\n' "$SOURCE_DEPLOY_KEY" > "$RUNNER_TEMP/source-deploy-key"
unset SOURCE_DEPLOY_KEY
trap 'rm -f "$RUNNER_TEMP/source-deploy-key"' EXIT

# Host keys were verified against GitHub's authenticated HTTPS metadata endpoint.
export GIT_SSH_COMMAND="ssh -i $RUNNER_TEMP/source-deploy-key -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$GITHUB_WORKSPACE/github-known-hosts"
export GIT_TERMINAL_PROMPT=0
mkdir -p "$RUNNER_TEMP/private-source"
cd "$RUNNER_TEMP/private-source"
git init -q
git remote add origin git@github.com:GhostLee/applesuite.git
git fetch --no-tags --depth=1 origin "$SOURCE_SHA"
git -c advice.detachedHead=false checkout --detach FETCH_HEAD
test "$(git rev-parse HEAD)" = "$SOURCE_SHA"
printf '%s\n' "$SOURCE_SHA" > "$RUNNER_TEMP/private-output/source-sha.txt"
unset GIT_SSH_COMMAND
