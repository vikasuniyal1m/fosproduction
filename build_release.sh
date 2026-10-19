#!/bin/bash

# Build both store uploads: iOS IPA + Android AAB
# Usage: ./build_release.sh [app-store]

set -e

cd "$(dirname "$0")"
chmod +x build_ipa.sh build_aab.sh

echo "=== iOS IPA ==="
./build_ipa.sh "${1:-app-store}"

echo ""
echo "=== Android AAB ==="
./build_aab.sh

echo ""
echo "Done. Upload:"
echo "  iOS:     build/ios/ipa/*.ipa"
echo "  Android: build/app/outputs/bundle/release/app-release.aab"
