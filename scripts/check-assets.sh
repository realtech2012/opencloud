#!/usr/bin/env sh
set -eu

missing=0
for dir in services/*/assets; do
  [ -d "$dir" ] || continue
  cnt=$(find "$dir" -type f ! -name '.keep' | wc -l | tr -d ' ')
  if [ "$cnt" -eq 0 ]; then
    echo "ERROR: $dir contains no assets (only .keep or empty). Run: make node-generate-prod"
    missing=1
  fi
done

if [ "$missing" -eq 1 ]; then
  exit 2
fi

echo "OK: frontend asset directories contain files"
