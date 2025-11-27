#!/bin/bash

# Script to verify backup files on Android device

echo "=== Verifying Backup Files on Device ==="
echo ""

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device found. Please connect your device."
    exit 1
fi

echo "✅ Device connected"
echo ""

# Define backup directory
BACKUP_DIR="/storage/emulated/0/Documents/Gateway Config/backup"

# Check Documents folder
echo "📁 Checking backup directory..."
echo "Path: $BACKUP_DIR"
echo ""

adb shell "ls -lh '$BACKUP_DIR/'" 2>/dev/null

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Backup folder exists!"
    echo ""

    # List all backup files with details
    echo "📄 Backup files found:"
    adb shell "ls -lh '$BACKUP_DIR'/*.json" 2>/dev/null

    # Count files
    FILE_COUNT=$(adb shell "ls '$BACKUP_DIR'/*.json 2>/dev/null | wc -l" | tr -d '\r')
    echo ""
    echo "📊 Total backup files: $FILE_COUNT"

    # Show latest file
    echo ""
    echo "📥 Latest backup file:"
    LATEST_FILE=$(adb shell "ls -t '$BACKUP_DIR'/*.json 2>/dev/null | head -1" | tr -d '\r')

    if [ ! -z "$LATEST_FILE" ]; then
        echo "File: $LATEST_FILE"

        # Get file size
        FILE_SIZE=$(adb shell "du -h '$LATEST_FILE'" 2>/dev/null | awk '{print $1}')
        echo "Size: $FILE_SIZE"

        echo ""
        echo "📋 File content preview (first 30 lines):"
        adb shell "cat '$LATEST_FILE'" | head -30

        echo ""
        echo "..."
        echo ""

        # Show backup_info section
        echo "📊 Backup Information:"
        adb shell "cat '$LATEST_FILE'" | grep -A 10 '"backup_info"' | head -11

        echo ""
        echo "💾 To download latest file to PC, run:"
        echo "adb pull '$LATEST_FILE' ./backup_$(date +%Y%m%d_%H%M%S).json"
    fi
else
    echo "❌ Backup folder does not exist yet"
    echo ""
    echo "💡 Tip: Download a backup from the app first"
    echo ""
    echo "To create folder manually (if needed):"
    echo "adb shell \"mkdir -p '$BACKUP_DIR'\""
fi

echo ""
echo "=== Verification Complete ===
