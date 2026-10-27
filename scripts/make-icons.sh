#!/bin/bash
# Creates all macOS icon sizes from design/AppIcon-1024.png using sips.
set -euo pipefail

cd "$(dirname "$0")/.."

master="design/AppIcon-1024.png"
out="App/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$master" ]; then
  echo "Fehlt: $master" >&2
  exit 1
fi

width=$(sips -g pixelWidth "$master" | awk '/pixelWidth/ {print $2}')
height=$(sips -g pixelHeight "$master" | awk '/pixelHeight/ {print $2}')
if [ "$width" != "1024" ] || [ "$height" != "1024" ]; then
  echo "Das Bild muss 1024 x 1024 Pixel groß sein (ist ${width} x ${height})." >&2
  exit 1
fi

mkdir -p "$out"

resize() {
  sips -z "$1" "$1" "$master" --out "$out/$2" > /dev/null
}

resize 16 icon_16x16.png
resize 32 icon_16x16@2x.png
resize 32 icon_32x32.png
resize 64 icon_32x32@2x.png
resize 128 icon_128x128.png
resize 256 icon_128x128@2x.png
resize 256 icon_256x256.png
resize 512 icon_256x256@2x.png
resize 512 icon_512x512.png
cp "$master" "$out/icon_512x512@2x.png"

echo "Fertig: 10 Icon-Größen in $out"