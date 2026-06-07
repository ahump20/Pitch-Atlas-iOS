#!/usr/bin/env bash
# Thin xcodebuild wrapper for Pitch Atlas iOS. Regenerates the project from
# project.yml first so the .xcodeproj is never a hand-edited artifact.
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="PitchAtlas"
DERIVED=".build/DerivedData"
BUILD_DEST="${PA_BUILD_DEST:-generic/platform=iOS Simulator}"
TEST_DEST="${PA_TEST_DEST:-platform=iOS Simulator,name=iPhone 16 Pro,OS=latest}"
cmd="${1:-build}"

if command -v xcodegen >/dev/null 2>&1; then
  echo "› xcodegen generate"
  xcodegen generate >/dev/null
fi

case "$cmd" in
  build)
    xcodebuild build \
      -scheme "$SCHEME" -sdk iphonesimulator \
      -destination "$BUILD_DEST" -derivedDataPath "$DERIVED" \
      -quiet | tail -20
    ;;
  test)
    xcodebuild test \
      -scheme "$SCHEME" -sdk iphonesimulator \
      -destination "$TEST_DEST" -derivedDataPath "$DERIVED" \
      | xcpretty 2>/dev/null || true
    ;;
  clean)
    rm -rf "$DERIVED" && echo "cleaned $DERIVED"
    ;;
  generate)
    : # xcodegen already ran above
    ;;
  *)
    echo "usage: build.sh [build|test|clean|generate]"; exit 1 ;;
esac
