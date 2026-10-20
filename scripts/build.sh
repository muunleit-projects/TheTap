#!/bin/bash
# Generates the Xcode project and builds the app (Debug).
set -euo pipefail

cd "$(dirname "$0")/.."

xcodegen generate

xcodebuild \
    -project TheTap.xcodeproj \
    -scheme TheTap \
    -configuration Debug \
    -derivedDataPath build \
    build