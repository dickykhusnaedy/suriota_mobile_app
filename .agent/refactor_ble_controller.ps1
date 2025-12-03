# BLE Controller Automated Refactoring Script
# This script safely refactors ble_controller.dart by replacing magic numbers and hardcoded strings
# with BLEConstants, BLEErrors, and BLEHelper references

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Configuration
$targetFile = "lib\core\controllers\ble_controller.dart"
$backupFile = "lib\core\controllers\ble_controller.dart.backup"
$rootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Change to project root
Set-Location $rootDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BLE Controller Refactoring Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $targetFile)) {
    Write-Host "ERROR: File not found: $targetFile" -ForegroundColor Red
    exit 1
}

# Create backup
Write-Host "[1/6] Creating backup..." -ForegroundColor Yellow
Copy-Item $targetFile $backupFile -Force
Write-Host "  ✓ Backup created: $backupFile" -ForegroundColor Green
Write-Host ""

# Read file content
$content = Get-Content $targetFile -Raw

# Store original content for comparison
$originalContent = $content

# Counter for changes
$changeCount = 0

# Function to replace and count
function Replace-AndCount {
    param(
        [string]$Pattern,
        [string]$Replacement,
        [string]$Description
    )
    
    $script:content = $script:content -replace [regex]::Escape($Pattern), $Replacement
    $count = ([regex]::Matches($originalContent, [regex]::Escape($Pattern))).Count
    
    if ($count -gt 0) {
        $script:changeCount += $count
        Write-Host "  ✓ $Description" -ForegroundColor Green
        Write-Host "    Replaced $count occurrence(s)" -ForegroundColor Gray
    }
    
    return $count
}

Write-Host "[2/6] Adding imports..." -ForegroundColor Yellow
# Add imports if not already present
if ($content -notmatch "import 'package:gateway_config/core/constants/ble_constants.dart';") {
    $importSection = "import 'package:flutter_blue_plus/flutter_blue_plus.dart';`r`nimport 'package:gateway_config/core/constants/app_color.dart';"
    $newImportSection = "import 'package:flutter_blue_plus/flutter_blue_plus.dart';`r`nimport 'package:gateway_config/core/constants/app_color.dart';`r`nimport 'package:gateway_config/core/constants/ble_constants.dart';`r`nimport 'package:gateway_config/core/constants/ble_errors.dart';`r`nimport 'package:gateway_config/core/utils/app_helpers.dart';`r`nimport 'package:gateway_config/core/utils/ble_helper.dart';"
    
    $content = $content -replace [regex]::Escape($importSection), $newImportSection
    Write-Host "  ✓ Imports added" -ForegroundColor Green
}
Write-Host ""

Write-Host "[3/6] Replacing magic numbers with BLEConstants..." -ForegroundColor Yellow

# Replace chunk size
Replace-AndCount "const chunkSize = 18;" "const chunkSize = BLEConstants.bleChunkSize;" "Chunk size"

# Replace delays
Replace-AndCount "Duration(milliseconds: 50)" "BLEConstants.subscriptionCancelDelay" "50ms delay (subscription cancel)"
Replace-AndCount "Duration(milliseconds: 300)" "BLEConstants.subscriptionSetupDelay" "300ms delay (subscription setup)"
Replace-AndCount "Duration(milliseconds: 100)" "BLEConstants.commandValidationDelay" "100ms delay (command validation)"
Replace-AndCount "Duration(seconds: 10)" "BLEConstants.scanDuration" "10s delay (scan duration)"
Replace-AndCount "Duration(seconds: 3)" "BLEConstants.disconnectMessageDelay" "3s delay (disconnect message)"
Replace-AndCount "Duration(seconds: 2)" "BLEConstants.successMessageClearDelay" "2s delay (success message clear)"
Replace-AndCount "Duration(milliseconds: 500)" "BLEConstants.navigationFallbackDelay" "500ms delay (navigation fallback)"

Write-Host ""

Write-Host "[4/6] Replacing END markers with BLEConstants..." -ForegroundColor Yellow

# Replace END marker strings
Replace-AndCount "'<END>'" "BLEConstants.endMarker" "END marker (single quotes)"
Replace-AndCount """<END>""" "BLEConstants.endMarker" "END marker (double quotes)"
Replace-AndCount "utf8.encode('<END>')" "utf8.encode(BLEConstants.endMarker)" "END marker (utf8.encode)"

Write-Host ""

Write-Host "[5/6] Replacing buffer size constants..." -ForegroundColor Yellow

# Remove buffer size constant declarations
$bufferDeclaration = "  // Buffer size limits for memory protection`r`n  static const int maxBufferSize = 1024 * 100; // 100KB`r`n  static const int maxPartialSize = 1024 * 10; // 10KB`r`n"
if ($content -match [regex]::Escape($bufferDeclaration)) {
    $content = $content -replace [regex]::Escape($bufferDeclaration), ""
    Write-Host "  ✓ Removed buffer size declarations" -ForegroundColor Green
}

# Replace buffer size references
Replace-AndCount "maxBufferSize" "BLEConstants.maxBufferSize" "maxBufferSize references"
Replace-AndCount "maxPartialSize" "BLEConstants.maxPartialSize" "maxPartialSize references"

Write-Host ""

Write-Host "[6/6] Summary..." -ForegroundColor Yellow
Write-Host "  Total replacements made: $changeCount" -ForegroundColor Cyan
Write-Host ""

# Save or show diff
if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes saved" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Changes that would be made:" -ForegroundColor Cyan
    
    # Show diff (simplified)
    $originalLines = $originalContent -split "`r`n"
    $newLines = $content -split "`r`n"
    
    $diffCount = 0
    for ($i = 0; $i -lt [Math]::Min($originalLines.Count, $newLines.Count); $i++) {
        if ($originalLines[$i] -ne $newLines[$i]) {
            $diffCount++
            if ($diffCount -le 10) {  # Show first 10 diffs
                Write-Host "  Line $($i + 1):" -ForegroundColor Yellow
                Write-Host "    - $($originalLines[$i])" -ForegroundColor Red
                Write-Host "    + $($newLines[$i])" -ForegroundColor Green
            }
        }
    }
    
    if ($diffCount -gt 10) {
        Write-Host "  ... and $($diffCount - 10) more changes" -ForegroundColor Gray
    }
} else {
    # Save the changes
    $content | Set-Content $targetFile -NoNewline
    Write-Host "✓ Changes saved to $targetFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backup available at: $backupFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run: flutter analyze" -ForegroundColor White
    Write-Host "  2. Review changes: git diff $targetFile" -ForegroundColor White
    Write-Host "  3. Test the application" -ForegroundColor White
    Write-Host "  4. If issues occur, restore: Copy-Item $backupFile $targetFile -Force" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Refactoring Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
