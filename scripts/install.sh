#!/bin/bash
# Builds the Release version of the app and installs it into /Applications.
# A running instance (any copy) is quit first; the installed copy is started afterwards.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="TheTap"
BUILT_APP="build/Build/Products/Release/${APP_NAME}.app"
INSTALLED_APP="/Applications/${APP_NAME}.app"

scripts/build.sh Release ONLY_ACTIVE_ARCH=YES

# Quit a running instance (SIGTERM), wait up to 5 seconds for it to end.
if pgrep -x "$APP_NAME" > /dev/null; then
    pkill -x "$APP_NAME" || true
    for _ in {1..25}; do
        pgrep -x "$APP_NAME" > /dev/null || break
        sleep 0.2
    done
fi

rm -rf "$INSTALLED_APP"
ditto "$BUILT_APP" "$INSTALLED_APP"
codesign --verify --deep --strict "$INSTALLED_APP"

open "$INSTALLED_APP"
echo "Installed and started: $INSTALLED_APP"