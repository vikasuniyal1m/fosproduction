# Build IPA Script for Flutter iOS App (PowerShell)
# Note: iOS builds require macOS. This script is for reference.
# Usage: .\build_ipa.ps1 [app-store|ad-hoc|development]

param(
    [string]$Method = "ad-hoc"
)

Write-Host "🚀 Starting IPA Build Process..." -ForegroundColor Green
Write-Host "Distribution Method: $Method" -ForegroundColor Yellow
Write-Host ""

# Step 1: Navigate to project root
Write-Host "Step 1: Preparing project..." -ForegroundColor Green
Set-Location $PSScriptRoot

# Step 2: Clean
Write-Host "Step 2: Cleaning previous builds..." -ForegroundColor Green
flutter clean
flutter pub get

# Step 3: Clean iOS
Write-Host "Step 3: Cleaning iOS build folder..." -ForegroundColor Green
Set-Location ios
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force Pods -ErrorAction SilentlyContinue
Remove-Item -Force Podfile.lock -ErrorAction SilentlyContinue

# Step 4: Install CocoaPods
Write-Host "Step 4: Installing CocoaPods dependencies..." -ForegroundColor Green
pod install

# Step 5: Build iOS Release
Write-Host "Step 5: Building iOS release..." -ForegroundColor Green
Set-Location ..
flutter build ios --release

# Step 6: Create Archive
Write-Host "Step 6: Creating archive (this may take 5-10 minutes)..." -ForegroundColor Green
Set-Location ios
xcodebuild -workspace Runner.xcworkspace `
  -scheme Runner `
  -configuration Release `
  -archivePath build/Runner.xcarchive `
  -destination generic/platform=iOS `
  archive

# Step 7: Create ExportOptions.plist
Write-Host "Step 7: Creating ExportOptions.plist..." -ForegroundColor Green

$exportOptions = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$Method</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
"@

$exportOptions | Out-File -FilePath ExportOptions.plist -Encoding UTF8

Write-Host "⚠️  Please update YOUR_TEAM_ID in ExportOptions.plist" -ForegroundColor Yellow
Read-Host "Press Enter to continue"

# Step 8: Export IPA
Write-Host "Step 8: Exporting IPA..." -ForegroundColor Green
Remove-Item -Recurse -Force build/ipa -ErrorAction SilentlyContinue
xcodebuild -exportArchive `
  -archivePath build/Runner.xcarchive `
  -exportPath build/ipa `
  -exportOptionsPlist ExportOptions.plist

# Step 9: Verify
Write-Host "Step 9: Verifying IPA..." -ForegroundColor Green
if (Test-Path "build/ipa/Runner.ipa") {
    $ipaSize = (Get-Item "build/ipa/Runner.ipa").Length / 1MB
    Write-Host "✅ IPA created successfully!" -ForegroundColor Green
    Write-Host "📍 Location: $(Get-Location)\build\ipa\Runner.ipa" -ForegroundColor Green
    Write-Host "📦 Size: $([math]::Round($ipaSize, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "❌ IPA file not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Build complete!" -ForegroundColor Green



