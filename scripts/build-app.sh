#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$TASK_ROOT"
swift build -c release
TASK_BIN="$(swift build -c release --show-bin-path)"
TASK_APP="$TASK_ROOT/dist/口算练习.app"
mkdir -p "$TASK_APP/Contents/MacOS" "$TASK_APP/Contents/Resources"
swift scripts/make-icon.swift "$TASK_ROOT/.build/AppIcon.iconset"
iconutil -c icns "$TASK_ROOT/.build/AppIcon.iconset" -o "$TASK_APP/Contents/Resources/ArithmeticGlass.icns"
cp "$TASK_BIN/Grade2MathPractice" "$TASK_APP/Contents/MacOS/Grade2MathPractice"
# SwiftPM resolves Bundle.module relative to the executable's parent on macOS.
for TASK_BUNDLE in "$TASK_BIN"/*.bundle; do
  [ -d "$TASK_BUNDLE" ] || continue
  cp -R "$TASK_BUNDLE" "$TASK_APP/Contents/Resources/"
  cp -R "$TASK_BUNDLE" "$TASK_APP/Contents/MacOS/"
done
cat > "$TASK_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>口算练习</string>
<key>CFBundleDisplayName</key><string>口算练习</string>
<key>CFBundleIdentifier</key><string>dev.yangyao.MentalMathGlass</string>
<key>CFBundleExecutable</key><string>Grade2MathPractice</string>
<key>CFBundleIconFile</key><string>ArithmeticGlass.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.2.0</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$TASK_APP"
printf '\n应用已生成：%s\n' "$TASK_APP"
