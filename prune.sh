#!/bin/bash
# prune.sh — git rm any staged MP4 whose queue row already says published, then push.
# The URLs pin commit SHAs, so removing a file never breaks an already-published post:
# Meta fetched it once at publish time and never asks again.
set -euo pipefail
cd "$(dirname "$0")"
Q="${1:-$HOME/Dropshipping/queue/queue.jsonl}"
[ -f "$Q" ] || { echo "no queue at $Q — nothing to prune against"; exit 0; }
mapfile -t GONE < <(python3 - "$Q" <<'PY'
import json, os, sys, glob
pub = set()
for l in open(sys.argv[1]):
    l = l.strip()
    if not l: continue
    try: r = json.loads(l)
    except: continue
    if r.get("status") == "published" and r.get("videoUrl"):
        pub.add(os.path.basename(r["videoUrl"]))
for f in sorted(glob.glob("media/*.mp4")):
    if os.path.basename(f) in pub: print(f)
PY
)
if [ "${#GONE[@]}" -eq 0 ]; then echo "nothing to prune"; exit 0; fi
for f in "${GONE[@]}"; do git rm -q "$f"; echo "  pruned $(basename "$f")"; done
git commit -q -m "prune ${#GONE[@]} published"
git push -q origin main
echo "${#GONE[@]} pruned and pushed"
