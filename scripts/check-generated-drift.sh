#!/usr/bin/env bash
# Fails when anything the generator owns differs from what is committed —
# including brand-new files, which `git diff --quiet` cannot see.
set -euo pipefail
cd "$(dirname "$0")/.."
paths=(
  PitchAtlas/Resources/Content
  PitchAtlas/Core/Theme/Generated
  PitchAtlas/Resources/Assets.xcassets/AccentColor.colorset
  PitchAtlas/Resources/Assets.xcassets/LaunchBackground.colorset
)
drift="$(git status --porcelain -- "${paths[@]}")"
if [ -n "$drift" ]; then
  echo "::error::generated files are stale - a web change was not regenerated into the app."
  echo "Fix: cd tools/generate-content && PITCH_ATLAS_WEB=/path/to/Pitch-Atlas npm run generate  (then commit the result)."
  echo "$drift"
  git --no-pager diff --stat -- "${paths[@]}" || true
  exit 1
fi
echo "✓ generated files match web source"
