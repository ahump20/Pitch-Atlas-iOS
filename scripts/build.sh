#!/usr/bin/env bash
# Thin xcodebuild wrapper for Pitch Atlas iOS. Regenerates the project from
# project.yml first so the .xcodeproj is never a hand-edited artifact.
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="PitchAtlas"
DERIVED=".build/DerivedData"
BUILD_DEST="${PA_BUILD_DEST:-generic/platform=iOS Simulator}"
TEST_DEST="${PA_TEST_DEST:-platform=iOS Simulator,name=iPhone 17 Pro,OS=latest}"
TEST_TIMEOUT_SECONDS="${PA_TEST_TIMEOUT_SECONDS:-180}"
cmd="${1:-build}"

shutdown_simulators() {
  xcrun simctl shutdown all >/dev/null 2>&1 &
  local shutdown_pid=$!
  local elapsed=0
  while kill -0 "$shutdown_pid" >/dev/null 2>&1; do
    if [ "$elapsed" -ge 20 ]; then
      pkill -TERM -P "$shutdown_pid" >/dev/null 2>&1 || true
      kill -TERM "$shutdown_pid" >/dev/null 2>&1 || true
      wait "$shutdown_pid" >/dev/null 2>&1 || true
      killall Simulator >/dev/null 2>&1 || true
      killall com.apple.CoreSimulator.CoreSimulatorService >/dev/null 2>&1 || true
      sleep 5
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  wait "$shutdown_pid" >/dev/null 2>&1 || true
}

restart_core_simulator() {
  shutdown_simulators
  killall Simulator >/dev/null 2>&1 || true
  killall com.apple.CoreSimulator.CoreSimulatorService >/dev/null 2>&1 || true
  sleep 5
}

destination_simulator_id() {
  case "$TEST_DEST" in
    *id=*)
      local id_part="${TEST_DEST#*id=}"
      printf '%s\n' "${id_part%%,*}"
      ;;
    *)
      return 1
      ;;
  esac
}

wait_for_test_simulator() {
  local simulator_id
  simulator_id="$(destination_simulator_id)" || return 0

  xcrun simctl boot "$simulator_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$simulator_id" -b &
  local boot_pid=$!
  local elapsed=0
  while kill -0 "$boot_pid" >/dev/null 2>&1; do
    if [ "$elapsed" -ge 120 ]; then
      echo "simulator ${simulator_id} did not finish booting after 120s." >&2
      pkill -TERM -P "$boot_pid" >/dev/null 2>&1 || true
      kill -TERM "$boot_pid" >/dev/null 2>&1 || true
      wait "$boot_pid" >/dev/null 2>&1 || true
      return 124
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  wait "$boot_pid"
}

run_test_once() {
  if command -v xcpretty >/dev/null 2>&1; then
    xcodebuild test-without-building \
      -scheme "$SCHEME" -sdk iphonesimulator \
      -destination "$TEST_DEST" -derivedDataPath "$DERIVED" \
      -parallel-testing-enabled NO -enableCodeCoverage NO \
      | xcpretty
  else
    xcodebuild test-without-building \
      -scheme "$SCHEME" -sdk iphonesimulator \
      -destination "$TEST_DEST" -derivedDataPath "$DERIVED" \
      -parallel-testing-enabled NO -enableCodeCoverage NO
  fi
}

run_test_with_timeout() {
  local status_file=".build/test-status.$$"
  rm -f "$status_file"
  (
    set +e
    run_test_once
    echo "$?" > "$status_file"
  ) &
  local runner_pid=$!
  local elapsed=0

  while kill -0 "$runner_pid" >/dev/null 2>&1; do
    if [ "$elapsed" -ge "$TEST_TIMEOUT_SECONDS" ]; then
      echo "xcodebuild test timed out after ${TEST_TIMEOUT_SECONDS}s; restarting CoreSimulator and retrying once." >&2
      pkill -INT -P "$runner_pid" >/dev/null 2>&1 || true
      kill -INT "$runner_pid" >/dev/null 2>&1 || true
      sleep 3
      pkill -TERM -P "$runner_pid" >/dev/null 2>&1 || true
      kill -TERM "$runner_pid" >/dev/null 2>&1 || true
      wait "$runner_pid" >/dev/null 2>&1 || true
      rm -f "$status_file"
      return 124
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done

  wait "$runner_pid" >/dev/null 2>&1 || true
  local status=1
  if [ -f "$status_file" ]; then
    status="$(cat "$status_file")"
  fi
  rm -f "$status_file"
  return "$status"
}

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
    set -o pipefail
    shutdown_simulators
    xcodebuild build-for-testing \
      -scheme "$SCHEME" -sdk iphonesimulator \
      -destination "$TEST_DEST" -derivedDataPath "$DERIVED" \
      -enableCodeCoverage NO \
      -quiet
    shutdown_simulators
    wait_for_test_simulator
    set +e
    run_test_with_timeout
    test_status=$?
    set -e
    if [ "$test_status" -eq 124 ]; then
      restart_core_simulator
      wait_for_test_simulator
      run_test_with_timeout
    else
      exit "$test_status"
    fi
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
