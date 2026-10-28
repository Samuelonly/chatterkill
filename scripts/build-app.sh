#!/bin/bash
# Build Chatterkill.app without Xcode (CommandLineTools only).
# arm64 only, ad-hoc signed (PRD 7).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-release}"
APP="$ROOT/dist/Chatterkill.app"

echo "==> swift build (-c $CONFIG)"
swift build -c "$CONFIG" --product Chatterkill

BIN="$(swift build -c "$CONFIG" --show-bin-path)/Chatterkill"

echo "==> assemble $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/zh-Hans.lproj"
cp "$BIN" "$APP/Contents/MacOS/Chatterkill"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/Chatterkill"

if [ -f "$ROOT/Resources/zh-Hans.lproj/InfoPlist.strings" ]; then
  cp "$ROOT/Resources/zh-Hans.lproj/InfoPlist.strings" "$APP/Contents/Resources/zh-Hans.lproj/InfoPlist.strings"
fi

if [ -d "$ROOT/Resources/web" ]; then
  cp -R "$ROOT/Resources/web" "$APP/Contents/Resources/web"
fi

if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" 2>/dev/null || true
fi

echo "==> sign"
# 本机自签名证书：签名稳定，重编不会让辅助功能授权失效。
# 证书不存在时回落到 ad-hoc（那种情况下每次重编都要重新授权）。
IDENTITY="Chatterkill Local Signing"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
  codesign --force --deep --sign "$IDENTITY" "$APP"
else
  echo "    ! 没找到 \"$IDENTITY\" 证书，回落到 ad-hoc 签名"
  codesign --force --deep --sign - "$APP"
fi

echo "==> verify architecture"
ARCH="$(file "$APP/Contents/MacOS/Chatterkill")"
echo "$ARCH"
if echo "$ARCH" | grep -q "x86_64"; then
  echo "ERROR: universal/x86_64 slice found — PRD 7 requires arm64 only." >&2
  exit 1
fi

echo "OK -> $APP"
