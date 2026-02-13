#!/bin/bash

# Build IPA Script for Flutter iOS App
# Usage: ./build_ipa.sh [app-store|ad-hoc|development]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get distribution method (default: ad-hoc)
METHOD=${1:-ad-hoc}

echo -e "${GREEN}🚀 Starting IPA Build Process...${NC}"
echo -e "${YELLOW}Distribution Method: ${METHOD}${NC}\n"

# Step 1: Navigate to project root
echo -e "${GREEN}Step 1: Preparing project...${NC}"
cd "$(dirname "$0")"
pwd

# Step 2: Clean
echo -e "${GREEN}Step 2: Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Step 3: Clean iOS
echo -e "${GREEN}Step 3: Cleaning iOS build folder...${NC}"
cd ios
rm -rf build
rm -rf Pods Podfile.lock

# Step 4: Install CocoaPods
echo -e "${GREEN}Step 4: Installing CocoaPods dependencies...${NC}"
pod install

# Step 5: Build iOS Release
echo -e "${GREEN}Step 5: Building iOS release...${NC}"
cd ..
flutter build ios --release

# Step 6: Create Archive
echo -e "${GREEN}Step 6: Creating archive (this may take 5-10 minutes)...${NC}"
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  -destination generic/platform=iOS \
  archive

# Step 7: Create ExportOptions.plist
echo -e "${GREEN}Step 7: Creating ExportOptions.plist...${NC}"

# Get Team ID (try to extract from existing config)
TEAM_ID=$(grep -o 'DEVELOPMENT_TEAM = [^;]*' Runner.xcodeproj/project.pbxproj | head -1 | cut -d' ' -f3 || echo "YOUR_TEAM_ID")

cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${METHOD}</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
EOF

if [ "$METHOD" = "app-store" ]; then
    cat >> ExportOptions.plist << EOF
    <key>uploadSymbols</key>
    <true/>
EOF
fi

cat >> ExportOptions.plist << EOF
</dict>
</plist>
EOF

echo -e "${YELLOW}⚠️  Please verify Team ID in ExportOptions.plist: ${TEAM_ID}${NC}"
echo -e "${YELLOW}   If incorrect, edit ios/ExportOptions.plist before continuing${NC}"
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Step 8: Export IPA
echo -e "${GREEN}Step 8: Exporting IPA (this may take 1-2 minutes)...${NC}"
rm -rf build/ipa
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist

# Step 9: Verify
echo -e "${GREEN}Step 9: Verifying IPA...${NC}"
if [ -f "build/ipa/Runner.ipa" ]; then
    IPA_SIZE=$(du -h build/ipa/Runner.ipa | cut -f1)
    echo -e "${GREEN}✅ IPA created successfully!${NC}"
    echo -e "${GREEN}📍 Location: $(pwd)/build/ipa/Runner.ipa${NC}"
    echo -e "${GREEN}📦 Size: ${IPA_SIZE}${NC}"
else
    echo -e "${RED}❌ IPA file not found!${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 Build complete!${NC}"



