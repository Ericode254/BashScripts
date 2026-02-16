#!/usr/bin/env bash
set -euo pipefail

URL="$1"
OUTDIR="$HOME/downloads/videos"

yt-dlp \
  --continue \
  --no-overwrites \
  --retries 10 \
  -f "bv*+ba/b" \
  -o "$OUTDIR/%(uploader)s/%(title)s.%(ext)s" \
  "$URL"
