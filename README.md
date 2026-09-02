# vinyl-media

Public file host with one job: **Meta FETCHES a Reel over HTTPS**, so a finished MP4 has to sit on
a public URL at publish time. Not a CDN of record, not an archive — a staging shelf.

    ./stage.sh <file.mp4>   copy in, commit, push, print the public URL (and prove it fetches)
    ./prune.sh              git rm anything already marked published, push

## Why jsDelivr and not Pages or raw

Meta needs `200` **and** `Content-Type: video/mp4`. Measured 2026-09-02:

| host | result |
|---|---|
| `raw.githubusercontent.com` | 200 but `application/octet-stream` + `nosniff` — Meta rejects |
| `<user>.github.io` (Pages) | needs Pages enabled per repo, and an extra manual settings step |
| `cdn.jsdelivr.net/gh/...` | **200 `video/mp4`** — works as-is on any public repo |

## Why the URL pins a commit SHA

`@main` is cached by jsDelivr for hours, so a freshly pushed file can 404 or serve a stale one.
`@<sha>` is immutable, always fresh, and never collides with a later push. `stage.sh` reads the
SHA from the push it just made and builds the URL from it.

## Limits worth knowing

- jsDelivr `/gh/` caps a single file at **20 MB**. Posts run ~13 MB; `stage.sh` refuses anything
  over 20 MB rather than let it fail at publish time.
- The repo is **public**. That is not a choice — Meta has to fetch it unauthenticated.
- Git keeps deleted blobs in history, so `prune.sh` shrinks the working tree, not the repo. At
  12 posts/day expect to re-cut history (or start a fresh repo) every few months.
