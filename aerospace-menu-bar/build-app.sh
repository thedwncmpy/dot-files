#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
swift build -c release

binary_dir="$(swift build -c release --show-bin-path)"
app_dir="$PWD/dist/AeroSpaceMenuBar.app"
mkdir -p "$app_dir/Contents/MacOS"
cp "$binary_dir/AeroSpaceMenuBar" "$app_dir/Contents/MacOS/AeroSpaceMenuBar"
cp Info.plist "$app_dir/Contents/Info.plist"
codesign --force --sign - "$app_dir"
echo "$app_dir"
