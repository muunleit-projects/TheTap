#!/bin/bash
# Builds the app, quits a running instance and starts the fresh build.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="TheTap"
APP_PATH="build/Build/Products/Debug/${APP_NAME}.app"

scripts/build.sh

# Quit a running instance (SIGTERM), wait up to 5 seconds for it to end.
if pgrep -x "$APP_NAME" > /dev/null; then
    pkill -x "$APP_NAME" || true
    for _ in {1..25}; do
        pgrep -x "$APP_NAME" > /dev/null || break
        sleep 0.2
    done
fi

open "$APP_PATH"