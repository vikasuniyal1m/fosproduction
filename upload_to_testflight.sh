#!/bin/bash

# Upload iOS App to TestFlight Script
# Usage: ./upload_to_testflight.sh

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting TestFlight Upload Process...${NC}\n"

# Step 1: Navigate to project
echo -e "${GREEN}Step 1: Preparing project...${NC}"
cd "$(dirname "$0")"

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

# Step 7: Create ExportOptions.plist for App Store
echo -e "${GREEN}Step 7: Creating ExportOptions.plist for App Store...${NC}"

# Get Team ID
TEAM_ID=$(grep -o 'DEVELOPMENT_TEAM = [^;]*' Runner.xcodeproj/project.pbxproj | head -1 | cut -d' ' -f3 || echo "YOUR_TEAM_ID")

cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

echo -e "${YELLOW}⚠️  Team ID: ${TEAM_ID}${NC}"
echo -e "${YELLOW}   Verify this is correct in ExportOptions.plist${NC}"

# Step 8: Export IPA
echo -e "${GREEN}Step 8: Exporting IPA...${NC}"
rm -rf build/ipa
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist

# Step 9: Verify IPA
if [ ! -f "build/ipa/Runner.ipa" ]; then
    echo -e "${RED}❌ IPA file not found!${NC}"
    exit 1
fi

IPA_SIZE=$(du -h build/ipa/Runner.ipa | cut -f1)
echo -e "${GREEN}✅ IPA created: ${IPA_SIZE}${NC}"

# Step 10: Upload options
echo -e "\n${GREEN}Step 9: Choose upload method:${NC}"
echo -e "1. Upload via Xcode (Recommended - Open Organizer)"
echo -e "2. Upload via Transporter App"
echo -e "3. Upload via Command Line (requires App-Specific Password)"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo -e "${GREEN}Opening Xcode Organizer...${NC}"
        open -a Xcode
        echo -e "${YELLOW}In Xcode: Window > Organizer > Select Archive > Distribute App${NC}"
        ;;
    2)
        echo -e "${GREEN}Opening Transporter...${NC}"
        open -a Transporter
        echo -e "${YELLOW}Drag and drop: $(pwd)/build/ipa/Runner.ipa${NC}"
        ;;
    3)
        read -p "Enter Apple ID: " APPLE_ID
        read -sp "Enter App-Specific Password: " APP_PASSWORD
        echo ""
        
        echo -e "${GREEN}Uploading to App Store Connect...${NC}"
        xcrun altool --upload-app \
          --type ios \
          --file build/ipa/Runner.ipa \
          --username "$APPLE_ID" \
          --password "$APP_PASSWORD" \
          --asc-provider "$TEAM_ID"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Upload successful!${NC}"
            echo -e "${YELLOW}Processing takes 10-30 minutes in App Store Connect${NC}"
        else
            echo -e "${RED}❌ Upload failed!${NC}"
            exit 1
        fi
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Opening Xcode Organizer...${NC}"
        open -a Xcode
        ;;
esac

echo -e "\n${GREEN}📍 IPA Location: $(pwd)/build/ipa/Runner.ipa${NC}"
echo -e "${GREEN}🎉 Next steps:${NC}"
echo -e "1. Wait for processing in App Store Connect (10-30 min)"
echo -e "2. Go to TestFlight tab"
echo -e "3. Add testers"
echo -e "4. Submit for Beta Review (external testers only)"



