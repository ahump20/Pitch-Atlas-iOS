#!/usr/bin/env bash
# Every color in the app comes from the theme (which reads the generated web
# tokens). A literal anywhere else is drift waiting to happen.
set -euo pipefail
cd "$(dirname "$0")/.."
pattern='Color\(hex:|Color\(red:|Color\(white:|Color\(\.sRGB|UIColor\(red:|UIColor\(white:|UIColor\(hue:|UIColor\(hexRGB:|#colorLiteral|CGColor\(red:'
hits="$(grep -rnE "$pattern" PitchAtlas --include='*.swift' | grep -v '^PitchAtlas/Core/Theme/' || true)"
if [ -n "$hits" ]; then
  echo "::error::color literals outside PitchAtlas/Core/Theme/:"
  echo "$hits"
  exit 1
fi
echo "✓ no color literals outside the theme"
