#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

SCRIPT_ROOT="$(cd "$(dirname "$0")"; pwd)"
TARGET_DIR="${1:-"${SCRIPT_ROOT}/../content"}"
MAX_WIDTH=1200
QUALITY=85

echo "Scanning images in ${TARGET_DIR} (max-width: ${MAX_WIDTH}px, format: WebP, quality: ${QUALITY})..."

processed=0
skipped=0

while IFS= read -r -d '' img; do
  ext="${img##*.}"
  ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  dir="$(dirname "$img")"
  basename="$(basename "$img")"
  filename="${basename%.*}"

  # Read image width and height using ImageMagick identify
  dim="$(identify -format "%w %h" "$img" 2>/dev/null || echo "")"
  if [[ -z "$dim" ]]; then
    echo "Warning: Unable to read image dimensions for ${img}, skipping." >&2
    continue
  fi

  width="${dim%% *}"
  height="${dim##* }"

  # Calculate target dimensions
  resize_args=()
  target_width="$width"
  target_height="$height"
  if (( width > MAX_WIDTH )); then
    target_width="$MAX_WIDTH"
    target_height=$(( height * MAX_WIDTH / width ))
    resize_args=(-resize "$target_width" "$target_height")
  fi

  if [[ "$ext_lower" != "webp" ]]; then
    webp_file="${dir}/${filename}.webp"
    echo "Converting: ${basename} (${width}x${height} -> ${target_width}x${target_height}) -> ${filename}.webp"

    # Auto-orient JPEG if needed, then convert to WebP
    if [[ "$ext_lower" =~ ^(jpg|jpeg)$ ]]; then
      mogrify -auto-orient "$img" 2>/dev/null || true
    fi

    cwebp -quiet -q "$QUALITY" "${resize_args[@]}" "$img" -o "$webp_file"
    rm "$img"

    # Update markdown references in the target directory
    find "$TARGET_DIR" -name "*.md" -exec sed -i "s|${basename}|${filename}.webp|g" {} +
    processed=$((processed + 1))
  else
    if (( width > MAX_WIDTH )); then
      echo "Resizing WebP: ${basename} (${width}x${height} -> ${target_width}x${target_height})"
      cwebp -quiet -q "$QUALITY" -resize "$target_width" "$target_height" "$img" -o "${img}.tmp"
      mv "${img}.tmp" "$img"
      processed=$((processed + 1))
    else
      skipped=$((skipped + 1))
    fi
  fi
done < <(find "$TARGET_DIR" -type f \( \
  -iname "*.png" -o \
  -iname "*.jpg" -o \
  -iname "*.jpeg" -o \
  -iname "*.tiff" -o \
  -iname "*.bmp" -o \
  -iname "*.webp" \
\) -not -name ".*" -print0)

echo "Finished. Processed: ${processed}, Skipped (already optimal): ${skipped}."
