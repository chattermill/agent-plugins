#!/usr/bin/env bash
# Build the ZIP to upload to OpenAI's plugin portal (ChatGPT and Codex).
#
#   ./scripts/package-chatgpt.sh            # writes dist/chattermill-chatgpt-<version>.zip
#   ./scripts/package-chatgpt.sh <app-id>   # use a different portal entry ID
#
# The portal only accepts an upload into an existing entry when the package
# `name` is that entry's ID, so the ZIP's plugin.json carries the ID instead of
# "chattermill". The repo keeps "chattermill", which Codex and Copilot installs
# from GitHub use.
#
# The ZIP holds only what the portal reads: the Agent Plugins manifest
# (plugin.json, mcp.json), the skills, the icon, README and LICENSE.

set -euo pipefail

APP_ID="${1:-app-69b68494bb7c8191b63833394c527d52}"
root="$(cd "$(dirname "$0")/.." && pwd)"
version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$root/plugin.json")"
out="$root/dist/chattermill-chatgpt-$version.zip"

mkdir -p "$root/dist"
rm -f "$out"

python3 - "$root" "$out" "$APP_ID" <<'PY'
import json
import os
import sys
import zipfile

root, out, app_id = sys.argv[1:]
files = ["mcp.json", "README.md", "LICENSE", "assets/icon.png"]
for dirpath, _, names in os.walk(os.path.join(root, "skills")):
    for name in names:
        if name != ".DS_Store":
            files.append(os.path.relpath(os.path.join(dirpath, name), root))

manifest = json.load(open(os.path.join(root, "plugin.json")))
manifest["name"] = app_id

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    zf.writestr("plugin.json", json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    for rel in sorted(files):
        zf.write(os.path.join(root, rel), rel)
PY

echo "$out"
