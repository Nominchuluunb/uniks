#!/bin/bash
#
# Captures App Store screenshots from the iOS Simulator.
#
# Usage:
#   1. Make executable: chmod +x scripts/capture_screenshots.sh
#   2. Run: ./scripts/capture_screenshots.sh
#
# The script boots an iPhone simulator, installs the app with onboarding
# skipped, then prompts you to switch tabs and captures each screen.
#

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCREENS_DIR="${PROJECT_DIR}/fastlane/screenshots"
APP_BUNDLE="${PROJECT_DIR}/build/Release-iphonesimulator/uniks.app"

device_id=""

find_or_create_device() {
    # Prefer an existing iPhone 16 Pro simulator
    device_id=$(xcrun simctl list devices available | grep "iPhone 16 Pro" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

    if [[ -z "$device_id" ]]; then
        echo "No iPhone 16 Pro simulator found. Creating one..."
        local runtime
        runtime=$(xcrun simctl list runtimes available | grep "iOS" | tail -1 | awk '{print $NF}')
        device_id=$(xcrun simctl create "iPhone 16 Pro Screenshot" "iPhone 16 Pro" "$runtime")
    fi

    echo "Using simulator: $device_id"
}

boot_device() {
    local state
    state=$(xcrun simctl list devices | grep "${device_id}" | sed -E 's/.*\(([^)]+)\).*/\1/')

    if ! xcrun simctl list devices | grep "${device_id}" | grep -q "Booted"; then
        echo "Booting simulator..."
        xcrun simctl boot "$device_id"
    fi

    open -a Simulator
}

build_app() {
    echo "Building app for iOS Simulator..."
    mkdir -p "${PROJECT_DIR}/build"
    xcodebuild \
        -project "${PROJECT_DIR}/uniks.xcodeproj" \
        -scheme uniks \
        -destination "platform=iOS Simulator,id=$device_id" \
        -derivedDataPath "${PROJECT_DIR}/build/DerivedData" \
        -configuration Release \
        -skipMacroValidation \
        clean build \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        > "${PROJECT_DIR}/build/screenshot_build.log" 2>&1

    APP_BUNDLE=$(find "${PROJECT_DIR}/build/DerivedData" -name "uniks.app" -type d | head -1)
}

install_and_launch() {
    echo "Installing app..."
    xcrun simctl install booted "$APP_BUNDLE"

    echo "Launching app with onboarding skipped..."
    xcrun simctl launch --terminate-running booted uniks.uniks -skipOnboarding

    sleep 2
}

capture() {
    local name=$1
    local path="${SCREENS_DIR}/${name}.png"
    mkdir -p "$SCREENS_DIR"

    # Clean up status bar for consistent screenshots
    xcrun simctl status_bar booted override --time "09:41" --dataNetwork wifi --wifiMode active --cellularMode active --batteryState charged --batteryLevel 100

    xcrun simctl io booted screenshot "$path"
    echo "Saved $path"
}

main() {
    find_or_create_device
    boot_device
    build_app
    install_and_launch

    mkdir -p "$SCREENS_DIR"

    echo ""
    echo "=============================================="
    echo "App is running on the simulator."
    echo "Switch to the 'Events' tab, then press Enter."
    echo "=============================================="
    read -r
    capture "01_events"

    echo ""
    echo "Switch to the 'Dashboard' tab, then press Enter."
    read -r
    capture "02_dashboard"

    echo ""
    echo "Switch to the 'Settings' tab, then press Enter."
    read -r
    capture "03_settings"

    echo ""
    echo "=============================================="
    echo "Screenshots saved to: $SCREENS_DIR"
    echo "=============================================="
}

main "$@"
