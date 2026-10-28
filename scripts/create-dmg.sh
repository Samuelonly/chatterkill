#!/bin/bash
# Package dist/Chatterkill.app into a drag-to-install DMG.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Chatterkill.app"
DMG="$ROOT/dist/Chatterkill.dmg"
STAGE="$ROOT/dist/dmg-stage"

[ -d "$APP" ] || { echo "Missing $APP — run ./scripts/build-app.sh first" >&2; exit 1; }

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
cp "$ROOT/Resources/READ ME（先读我）.txt" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create -volname "Chatterkill" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo "OK -> $DMG"
