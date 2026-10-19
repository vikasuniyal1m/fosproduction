#!/bin/bash
# Run before Xcode Archive if you see "sandbox is not in sync with Podfile.lock"
set -e
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
cd "$(dirname "$0")"
flutter pub get
pod install
echo "Pods ready. Open Runner.xcworkspace (not .xcodeproj)"
