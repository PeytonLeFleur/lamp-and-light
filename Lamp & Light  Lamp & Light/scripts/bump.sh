#!/usr/bin/env bash
set -euo pipefail
proj="Lamp & Light  Lamp & Light.xcodeproj"
scheme="Lamp & Light  Lamp & Light"

if [ $# -lt 2 ]; then
  echo "Usage: bump.sh <marketing_version> <build_number>"
  exit 1
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $1" "Lamp & Light  Lamp & Light/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $2" "Lamp & Light  Lamp & Light/Info.plist"

xcodebuild -project "$proj" -scheme "$scheme" -configuration Release -derivedDataPath build clean build
echo "Bumped to $1 ($2)" 