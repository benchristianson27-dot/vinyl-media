#!/bin/bash
# stage.sh <file.mp4> — publish a finished post to the public CDN and print its URL.
#
# Meta fetches the file over HTTPS at publish time, so it must be live and typed video/mp4
# BEFORE publish.mjs runs. The URL pins the commit SHA, not the branch: jsDelivr caches
# @main for hours, so a branch URL can 404 or serve a stale file right after a push.
set -euo pipefail
SRC="${1:?usage: stage.sh <file.mp4>}"
[ -f "$SRC" ] || { echo "no such file: $SRC"; exit 1; }
cd "$(dirname "$0")"

REPO_USER="benchristianson27-dot"
REPO_NAME="vinyl-media"
MAX=$((20 * 1024 * 1024))   # jsDelivr /gh/ caps one file at 20 MB

SZ=$(stat -f%z "$SRC")
if [ "$SZ" -gt "$MAX" ]; then
  echo "refusing: $(basename "$SRC") is $((SZ/1024/1024)) MB, over jsDelivr's 20 MB /gh/ limit."
  echo "re-encode smaller, or move to a real object store."; exit 1
fi

BN="$(basename "$SRC")"
cp "$SRC" "media/$BN"
git add "media/$BN"
git commit -q -m "stage $BN" || { echo "nothing to commit — is $BN already staged?"; }
git push -q origin main
SHA="$(git rev-parse HEAD)"

URL="https://cdn.jsdelivr.net/gh/${REPO_USER}/${REPO_NAME}@${SHA}/media/${BN}"

# Prove the contract before handing the URL on: 200 AND video/mp4, or publish will fail
# later with a much less obvious error. jsDelivr can take a few seconds to see a new commit.
for i in $(seq 1 20); do
  read -r CODE CT < <(curl -s -o /dev/null -w '%{http_code} %{content_type}' "$URL" || echo "000 -")
  case "$CODE:$CT" in
    200:video/mp4*) echo "$URL"; echo "  verified: 200 video/mp4  (${SZ} bytes)"; exit 0;;
  esac
  sleep 3
done
echo "staged but NOT yet fetchable: last was $CODE $CT" >&2
echo "$URL" >&2
exit 1
