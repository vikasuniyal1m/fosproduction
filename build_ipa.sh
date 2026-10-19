#!/bin/bash
# Smallest IPA for App Store (default).
# Usage:
#   ./build_ipa.sh [app-store|ad-hoc|development]
#   FAST=1 ./build_ipa.sh        # faster, slightly larger
#   CLEAN=1 ./build_ipa.sh       # full clean + pod reinstall

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

METHOD=${1:-app-store}

cd "$(dirname "$0")"

if [ "${CLEAN:-0}" = "1" ]; then
  echo -e "${GREEN}Full clean requested${NC}"
  flutter clean
  rm -rf ios/Pods ios/Podfile.lock ios/build
fi

echo -e "${GREEN}Step 1: pub get${NC}"
flutter pub get

echo -e "${GREEN}Step 2: CocoaPods (only if out of sync)${NC}"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
cd ios
if [ ! -f Pods/Manifest.lock ] || ! diff -q Podfile.lock Pods/Manifest.lock >/dev/null 2>&1; then
  pod install
else
  echo "Pods already in sync — skipping pod install"
fi
cd ..

mkdir -p build/symbols

FLUTTER_FLAGS=(
  --release
  --obfuscate
  --split-debug-info=build/symbols
  --tree-shake-icons
)

if [ "${FAST:-0}" = "1" ]; then
  echo -e "${YELLOW}FAST=1: skipping obfuscate (larger IPA)${NC}"
  FLUTTER_FLAGS=(--release --tree-shake-icons)
fi

echo -e "${GREEN}Step 3: Build IPA (release, stripped)${NC}"
flutter build ipa --release "${FLUTTER_FLAGS[@]}"

IPA_FILE=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)
if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
  IPA_BYTES=$(stat -f%z "$IPA_FILE" 2>/dev/null || stat -c%s "$IPA_FILE")
  IPA_MB=$(echo "scale=1; $IPA_BYTES / 1048576" | bc)
  echo -e "${GREEN}IPA ready: ${IPA_FILE} (${IPA_MB} MB)${NC}"
else
  echo -e "${RED}IPA not found under build/ios/ipa${NC}"
  exit 1
fi

echo -e "${GREEN}Build complete.${NC}"
