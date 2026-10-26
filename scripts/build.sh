#!/bin/bash
# Generates the Xcode project and builds the app.
# Usage: scripts/build.sh [Debug|Release] [extra xcodebuild arguments]
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${1:-Debug}"
shift || true

xcodegen generate

xcodebuild \
    -project TheTap.xcodeproj \
    -scheme TheTap \
    -configuration "$CONFIGURATION" \
    -derivedDataPath build \
    build \
    "$@"