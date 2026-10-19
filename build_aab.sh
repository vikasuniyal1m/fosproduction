#!/bin/bash
# Smallest AAB for Play Store (default).
# Usage:
#   ./build_aab.sh              # small release AAB
#   FAST=1 ./build_aab.sh       # faster build, larger AAB (no minify path in gradle — use debug)
#   CLEAN=1 ./build_aab.sh      # full clean first

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")"

if [ ! -f "android/key.properties" ]; then
  echo -e "${RED}Missing android/key.properties (release signing).${NC}"
  echo "Create it with storeFile, storePassword, keyAlias, keyPassword"
  exit 1
fi

if [ "${CLEAN:-0}" = "1" ]; then
  echo -e "${GREEN}Full clean requested${NC}"
  flutter clean
fi

echo -e "${GREEN}Step 1: pub get${NC}"
flutter pub get

mkdir -p build/symbols

# Smallest bundle: arm only (covers 99%+ phones), strip unused icons, obfuscate Dart
FLUTTER_FLAGS=(
  --release
  --obfuscate
  --split-debug-info=build/symbols
  --tree-shake-icons
  --target-platform android-arm,android-arm64
)

if [ "${FAST:-0}" = "1" ]; then
  echo -e "${YELLOW}FAST=1: skipping obfuscate (larger AAB)${NC}"
  FLUTTER_FLAGS=(--release --tree-shake-icons --target-platform android-arm,android-arm64)
fi

echo -e "${GREEN}Step 2: Build AAB (minify + shrink in Gradle)${NC}"
flutter build appbundle "${FLUTTER_FLAGS[@]}"

AAB_FILE="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_FILE" ]; then
  AAB_BYTES=$(stat -f%z "$AAB_FILE" 2>/dev/null || stat -c%s "$AAB_FILE")
  AAB_MB=$(echo "scale=1; $AAB_BYTES / 1048576" | bc)
  echo -e "${GREEN}AAB ready: ${AAB_FILE} (${AAB_MB} MB)${NC}"
  echo -e "${GREEN}Play Store will serve smaller per-device APKs from this bundle.${NC}"
else
  echo -e "${RED}AAB not found at ${AAB_FILE}${NC}"
  exit 1
fi

echo -e "${GREEN}Build complete.${NC}"
