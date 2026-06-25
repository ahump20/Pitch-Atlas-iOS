#!/usr/bin/env bash
# Capture repeatable build 9 simulator screenshots for release review.
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="PitchAtlas"
BUNDLE_ID="com.pitchatlas.app"
SIMULATOR="${PA_SCREENSHOT_SIMULATOR:-iPhone 17 Pro}"
DESTINATION="platform=iOS Simulator,name=${SIMULATOR},OS=latest"
DERIVED="${PA_DERIVED_DATA:-.build/DerivedData}"
APP_PATH="${DERIVED}/Build/Products/Debug-iphonesimulator/PitchAtlas.app"
OUT_DIR="${PA_SCREENSHOT_OUT:-docs/review-evidence/build-9-screenshots}"
REPORT_PATH="${OUT_DIR}/2026-06-24-build-9-screenshot-report.md"
WAIT_SECONDS="${PA_SCREENSHOT_WAIT:-3}"
READY_ATTEMPTS="${PA_SCREENSHOT_READY_ATTEMPTS:-40}"

mkdir -p "$OUT_DIR"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate >/dev/null
fi

xcodebuild build \
  -scheme "$SCHEME" -sdk iphonesimulator \
  -destination "$DESTINATION" -derivedDataPath "$DERIVED" \
  -quiet

xcrun simctl boot "$SIMULATOR" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIMULATOR" -b >/dev/null
xcrun simctl install "$SIMULATOR" "$APP_PATH"

wait_for_app() {
  local pid="$1"
  local attempt
  for attempt in $(seq 1 "$READY_ATTEMPTS"); do
    if ps -p "$pid" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  printf 'Timed out waiting for %s pid %s to be ready\n' "$BUNDLE_ID" "$pid" >&2
  return 1
}

capture() {
  local name="$1"
  local result_var="$2"
  local launch_output
  local pid
  local path
  shift 2
  xcrun simctl terminate "$SIMULATOR" "$BUNDLE_ID" >/dev/null 2>&1 || true
  launch_output="$(env "$@" xcrun simctl launch --terminate-running-process "$SIMULATOR" "$BUNDLE_ID")"
  pid="$(printf '%s\n' "$launch_output" | sed -n 's/.*: \([0-9][0-9]*\)$/\1/p')"
  if [[ -z "$pid" ]]; then
    printf 'Could not read launch pid from: %s\n' "$launch_output" >&2
    exit 1
  fi
  if ! wait_for_app "$pid"; then
    exit 1
  fi
  sleep "$WAIT_SECONDS"
  path="${OUT_DIR}/${name}.png"
  xcrun simctl io "$SIMULATOR" screenshot "$path" >/dev/null
  printf -v "$result_var" '%s' "$path"
  printf '%s\n' "$path"
}

capture atlas-home atlas_path SIMCTL_CHILD_PA_TAB=atlas
capture pitch-detail-four-seam detail_path SIMCTL_CHILD_PA_PITCH=four-seam
capture index index_path SIMCTL_CHILD_PA_TAB=index
capture grips grips_path SIMCTL_CHILD_PA_TAB=grips
capture sources sources_path SIMCTL_CHILD_PA_TAB=sources
capture account-safety account_path SIMCTL_CHILD_PA_ACCOUNT=1

cat > "$REPORT_PATH" <<REPORT
# Pitch Atlas iOS Build 9 Screenshot Report

Date: 2026-06-24
Device: ${SIMULATOR} simulator
Bundle: ${BUNDLE_ID}
Version target: 1.0.1 (9)

## Captures

- Atlas: \`${atlas_path}\`
- Pitch detail: \`${detail_path}\`
- Index: \`${index_path}\`
- Grips: \`${grips_path}\`
- Sources: \`${sources_path}\`
- Account/Safety: \`${account_path}\`

## Critique Checks

- Atlas: seal, title, and featured specimen should read above the tab bar.
- Detail: specimen number, family, provenance, and action affordance should be legible.
- Index: search remains first-class, chips fit, aliases wrap cleanly, and row metadata has contrast.
- Grips: no-fake-data disclaimer remains high and first-party grip thumbnails appear early.
- Sources: tier numbers accompany dots, source rows say content checked, and labels are readable.
- Account/Safety: email label is visible, disabled magic-link state is clear, and safety notes scan.
REPORT

printf 'Screenshot report: %s\n' "$REPORT_PATH"
