#!/bin/bash
set -euo pipefail
umask 077
[[ "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]]
printf '%s\n' "$SOURCE_DEPLOY_KEY" > "$RUNNER_TEMP/source-deploy-key"
unset SOURCE_DEPLOY_KEY
trap 'rm -f "$RUNNER_TEMP/source-deploy-key"' EXIT

# Get GitHub's host keys over authenticated HTTPS, never accept an unknown key.
curl --fail --silent --show-error --retry 3 https://api.github.com/meta \
  -o "$RUNNER_TEMP/github-meta.json"
python3 - <<'PY'
import json
import os
from pathlib import Path
root = Path(os.environ["RUNNER_TEMP"])
keys = json.loads((root / "github-meta.json").read_text())["ssh_keys"]
assert keys and all("\n" not in key for key in keys)
(root / "github-known-hosts").write_text("".join("github.com " + key + "\n" for key in keys))
PY
export GIT_SSH_COMMAND="ssh -i $RUNNER_TEMP/source-deploy-key -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$RUNNER_TEMP/github-known-hosts"
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
