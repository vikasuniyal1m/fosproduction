#!/bin/bash
# =============================================================================
# FOS Productions — single store build script (Android AAB + iOS IPA)
# =============================================================================
# Run from project root in Terminal:
#
#   chmod +x build_store.sh          # once
#   ./build_store.sh                 # both (smallest release)
#   ./build_store.sh android         # Play Store AAB only
#   ./build_store.sh ios             # App Store IPA only (arm64 devices)
#   ./build_store.sh --clean         # clean caches first (fix Gradle errors)
#   ./build_store.sh --fast          # faster build, slightly larger
#   ./build_store.sh android --clean
#
# Outputs:
#   Android: build/app/outputs/bundle/release/app-release.aab
#   iOS:     build/ios/ipa/*.ipa
#
# Release build silences print/debugPrint via lib/utils/release_config.dart
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

BUILD_ANDROID=1
BUILD_IOS=1
DO_CLEAN=0
FAST=0
IOS_METHOD="app-store"

for arg in "$@"; do
  case "$arg" in
    android|aab)     BUILD_IOS=0 ;;
    ios|ipa)         BUILD_ANDROID=0 ;;
    --clean|-c)      DO_CLEAN=1 ;;
    --fast|-f)       FAST=1 ;;
    --both)          BUILD_ANDROID=1; BUILD_IOS=1 ;;
    app-store|ad-hoc|development) IOS_METHOD="$arg" ;;
    -h|--help)
      sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

step() { echo -e "\n${CYAN}==> $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}! $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

file_mb() {
  local f="$1"
  local bytes
  bytes=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
  echo "scale=1; $bytes / 1048576" | bc
}

START=$(date +%s)
echo -e "${GREEN}FOS Productions store build${NC}"
echo "Project: $ROOT"
echo "Android: $([ "$BUILD_ANDROID" = 1 ] && echo yes || echo skip) | iOS: $([ "$BUILD_IOS" = 1 ] && echo yes || echo skip) | Clean: $([ "$DO_CLEAN" = 1 ] && echo yes || echo no) | Fast: $([ "$FAST" = 1 ] && echo yes || echo no)"

# --- Preflight ---
command -v flutter >/dev/null 2>&1 || fail "flutter not in PATH"
flutter --version | head -1

if [ "$BUILD_ANDROID" = 1 ] && [ ! -f "android/key.properties" ]; then
  fail "Missing android/key.properties — add release keystore settings"
fi

if [ "$DO_CLEAN" = 1 ]; then
  step "Cleaning (fixes stuck Gradle/Kotlin caches)"
  if [ -f "android/gradlew" ]; then
    (cd android && ./gradlew --stop) 2>/dev/null || true
  fi
  flutter clean
  rm -rf build android/.gradle android/app/build android/build
  if [ "$BUILD_IOS" = 1 ]; then
    rm -rf ios/Pods ios/Podfile.lock ios/build
  fi
  if [ -f "android/gradlew" ]; then
    (cd android && ./gradlew clean --no-daemon) 2>/dev/null || true
  fi
  ok "Clean done"
fi

step "flutter pub get"
flutter pub get

mkdir -p build/symbols

# Smallest release flags (arm + arm64 Android, obfuscate, no unused icons)
if [ "$FAST" = 1 ]; then
  warn "FAST mode: skipping obfuscate (quicker, larger file)"
  ANDROID_FLAGS=(--release --tree-shake-icons --target-platform android-arm,android-arm64)
  IOS_FLAGS=(--release --tree-shake-icons)
else
  ANDROID_FLAGS=(
    --release
    --obfuscate
    --split-debug-info=build/symbols
    --tree-shake-icons
    --target-platform android-arm,android-arm64
  )
  IOS_FLAGS=(
    --release
    --obfuscate
    --split-debug-info=build/symbols
    --tree-shake-icons
  )
fi

# --- Android AAB ---
if [ "$BUILD_ANDROID" = 1 ]; then
  step "Building Android AAB (minify + shrink in Gradle)"
  echo "This usually takes 5–15 min on first run…"
  flutter build appbundle "${ANDROID_FLAGS[@]}"

  AAB="build/app/outputs/bundle/release/app-release.aab"
  [ -f "$AAB" ] || fail "AAB not found at $AAB"
  ok "Android AAB: $AAB ($(file_mb "$AAB") MB)"
fi

# --- iOS IPA (arm64 devices) ---
if [ "$BUILD_IOS" = 1 ]; then
  if [[ "$(uname)" != "Darwin" ]]; then
    warn "Skipping iOS — macOS + Xcode required"
  else
    step "CocoaPods (only if out of sync)"
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    cd ios
    if [ ! -f Pods/Manifest.lock ] || ! diff -q Podfile.lock Pods/Manifest.lock >/dev/null 2>&1; then
      pod install
    else
      echo "Pods OK — skip install"
    fi
    cd "$ROOT"

    step "Building iOS IPA ($IOS_METHOD, arm64)"
    echo "This usually takes 8–20 min…"
    flutter build ipa --export-method "$IOS_METHOD" "${IOS_FLAGS[@]}"

    IPA=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)
    [ -n "$IPA" ] && [ -f "$IPA" ] || fail "IPA not found under build/ios/ipa"
    ok "iOS IPA: $IPA ($(file_mb "$IPA") MB)"
  fi
fi

END=$(date +%s)
MINS=$(( (END - START) / 60 ))
SECS=$(( (END - START) % 60 ))

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Done in ${MINS}m ${SECS}s${NC}"
[ "$BUILD_ANDROID" = 1 ] && [ -f "build/app/outputs/bundle/release/app-release.aab" ] && \
  echo "  Android → build/app/outputs/bundle/release/app-release.aab"
[ "$BUILD_IOS" = 1 ] && IPA=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1) && \
  [ -n "$IPA" ] && echo "  iOS     → $IPA"
echo -e "${GREEN}========================================${NC}"
