#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${DEVICE_ID:-00008140-000C02942169801C}"
PROJECT="${PROJECT:-$ROOT_DIR/ios/delts.xcodeproj}"
SCHEME="${SCHEME:-delts}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/delts-iphone-build}"
BUNDLE_ID="${BUNDLE_ID:-com.apoorvdarshan.delts}"
SCREENSHOT_PATH=""
INITIAL_TAB=""

usage() {
  printf 'Usage: %s [--device UDID] [--tab home|workouts|profile] [--screenshot PATH]\n' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      DEVICE_ID="$2"
      shift 2
      ;;
    --screenshot)
      SCREENSHOT_PATH="$2"
      shift 2
      ;;
    --tab)
      INITIAL_TAB="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/delts.app"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$DEVICE_ID" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
if [[ -n "$INITIAL_TAB" ]]; then
  xcrun devicectl device process launch --terminate-existing --device "$DEVICE_ID" "$BUNDLE_ID" --delts-tab "$INITIAL_TAB"
else
  xcrun devicectl device process launch --terminate-existing --device "$DEVICE_ID" "$BUNDLE_ID"
fi

if [[ -n "$SCREENSHOT_PATH" ]]; then
  mkdir -p "$(dirname "$SCREENSHOT_PATH")"
  if ! pymobiledevice3 developer dvt screenshot --udid "$DEVICE_ID" "$SCREENSHOT_PATH"; then
    printf 'Screenshot failed. Start the tunnel first: sudo python3 -m pymobiledevice3 remote tunneld\n' >&2
    exit 1
  fi
fi
