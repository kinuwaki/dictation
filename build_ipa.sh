#!/bin/bash

# Distribution IPA Build Script for Dictation
# Usage: ./build_ipa.sh

set -e  # Exit on error

echo "Starting Distribution IPA build..."
echo ""

# Configuration
SCHEME="Dictation"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/output/Dictation.xcarchive"
EXPORT_PATH="./build/output/ipa"
EXPORT_OPTIONS_PLIST="./build/config/ExportOptions_Distribution.plist"

# Create output directory
mkdir -p build/output

echo "Step 1: Archiving project..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="WS9392R3N8" \
    -allowProvisioningUpdates

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Archive not created!"
    exit 1
fi

echo ""
echo "Archive completed!"
echo ""

echo "Step 2: Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -allowProvisioningUpdates

if [ ! -f "$EXPORT_PATH/Dictation.ipa" ]; then
    echo "IPA file not created!"
    exit 1
fi

echo ""
echo "IPA export completed!"
echo ""

# Get version and build number
VERSION=$(agvtool what-marketing-version 2>/dev/null | grep "CFBundleShortVersionString" | head -1 | awk '{print $NF}' | tr -d '"')
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi
BUILD=$(agvtool what-version -terse 2>/dev/null)

echo "Build Information:"
echo "   Version: $VERSION"
echo "   Build: $BUILD"
echo "   Archive: $ARCHIVE_PATH"
echo "   IPA: $EXPORT_PATH/Dictation.ipa"
echo ""

# Check if IPA was created
if [ -f "$EXPORT_PATH/Dictation.ipa" ]; then
    IPA_SIZE=$(du -h "$EXPORT_PATH/Dictation.ipa" | cut -f1)
    echo "IPA successfully created! ($IPA_SIZE)"
    echo ""
    echo "Location: $EXPORT_PATH/Dictation.ipa"
else
    echo "IPA file not found!"
    exit 1
fi

echo ""
echo "Build process completed successfully!"
