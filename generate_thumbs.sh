#!/usr/bin/env bash
# Generate thumbnails and short preview clips for mp4 files in this folder.
# Requires: ffmpeg installed and available on PATH.
#
# Usage:
#   chmod +x scripts/generate_thumbs.sh
#   ./scripts/generate_thumbs.sh
#
# Output for each file `name.mp4`:
#   - `name-thumb.jpg`  (single-frame poster at 640x360)
#   - `name-preview.mp4` (6s low-bitrate preview, 640px wide)

set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg not found. Install ffmpeg and retry." >&2; exit 1; }

shopt -s nullglob
MP4S=( *.mp4 )
if [ ${#MP4S[@]} -eq 0 ]; then
  echo "No .mp4 files found in $DIR"
  exit 0
fi

echo "Found ${#MP4S[@]} .mp4 files. Generating thumbnails and previews..."

for f in "${MP4S[@]}"; do
  base="${f%.*}"
  thumb="${base}-thumb.jpg"
  preview="${base}-preview.mp4"

  echo "Processing: $f -> $thumb, $preview"

  # Generate a single-frame poster at 640x360 using frame at 00:00:01 (if available)
  if [ ! -f "$thumb" ]; then
    ffmpeg -hide_banner -loglevel error -y -ss 1 -i "$f" -vframes 1 -vf "scale=640:-2,format=yuvj420p" "$thumb" || {
      echo "Failed to create $thumb from $f" >&2
    }
  else
    echo "  $thumb already exists, skipping"
  fi

  # Generate a short low-bitrate preview (6 seconds), 640px wide
  if [ ! -f "$preview" ]; then
    ffmpeg -hide_banner -loglevel error -y -ss 0 -i "$f" -t 6 -c:v libx264 -preset veryfast -crf 28 -vf "scale=640:-2" -an "$preview" || {
      echo "Failed to create $preview from $f" >&2
    }
  else
    echo "  $preview already exists, skipping"
  fi
done

echo "Done. Thumbnails and previews created where missing."
