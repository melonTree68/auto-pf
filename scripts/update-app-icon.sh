#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/source-image.png" >&2
  exit 1
fi

source_image="$1"
if [[ "$source_image" != /* ]]; then
  source_image="$(pwd)/$source_image"
fi

if [ ! -f "$source_image" ]; then
  echo "Source image not found: $source_image" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
icon_dir="$repo_root/AutoPF/Assets.xcassets/AppIcon.appiconset"

sips -z 1024 1024 "$source_image" --out "$icon_dir/icon-1024.png" >/dev/null
sips -z 512 512 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-512.png" >/dev/null
sips -z 512 512 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-256@2x.png" >/dev/null
sips -z 256 256 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-256.png" >/dev/null
sips -z 256 256 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-128@2x.png" >/dev/null
sips -z 128 128 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-128.png" >/dev/null
sips -z 64 64 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-32@2x.png" >/dev/null
sips -z 32 32 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-32.png" >/dev/null
sips -z 32 32 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-16@2x.png" >/dev/null
sips -z 16 16 "$icon_dir/icon-1024.png" --out "$icon_dir/icon-16.png" >/dev/null

echo "Updated AppIcon assets from: $source_image"
