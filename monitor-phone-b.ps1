# Phone B (Community Detector) Log Monitor
# Run this script in a separate terminal to monitor Phone B logs

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PHONE B (BOB) - COMMUNITY DETECTION MONITOR" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check ADB connection
Write-Host "Checking ADB connection..." -ForegroundColor Yellow
$devices = adb devices | Select-String -Pattern "device$"
if ($devices.Count -eq 0) {
    Write-Host "✗ No Android devices connected!" -ForegroundColor Red
    Write-Host "  - Connect Phone B via USB" -ForegroundColor Yellow
    Write-Host "  - Enable USB debugging" -ForegroundColor Yellow
    Write-Host "  - Run: adb devices" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Connected devices:" -ForegroundColor Green
adb devices
Write-Host ""

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Monitoring Phone B logs... Press Ctrl+C to stop" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Waiting for Community Sensing activity..." -ForegroundColor Yellow
Write-Host ""

# Clear logcat buffer (optional)
# adb logcat -c

# Monitor Flutter logs from Phone B
# Filter for Community, WiFi, and BLE-related logs
adb logcat -v time | Select-String -Pattern "Community|WiFiScan|CommunityWiFi" | ForEach-Object {
    $line = $_.ToString()
    
    # Highlight important log lines
    if ($line -match 'BLE.*AssetGuard trackers detected') {
        Write-Host $line -ForegroundColor Cyan
    }
    elseif ($line -match 'Processing tracker.*AG-') {
        Write-Host $line -ForegroundColor Yellow
    }
    elseif ($line -match 'Wi-Fi scan success.*NIE APs') {
        Write-Host $line -ForegroundColor Green
    }
    elseif ($line -match 'Fingerprint:.*BSSIDs') {
        Write-Host $line -ForegroundColor Yellow
    }
    elseif ($line -match 'SUBMITTING DETECTION TO BACKEND') {
        Write-Host $line -ForegroundColor Cyan
    }
    elseif ($line -match 'ML ROOM PREDICTION RECEIVED') {
        Write-Host $line -ForegroundColor Magenta
    }
    elseif ($line -match 'Predicted room:') {
        Write-Host $line -ForegroundColor Magenta
    }
    elseif ($line -match 'Confidence:') {
        Write-Host $line -ForegroundColor Magenta
    }
    elseif ($line -match '⚠️|WARNING|ERROR|✗|INVALID') {
        Write-Host $line -ForegroundColor Red
    }
    elseif ($line -match '✓') {
        Write-Host $line -ForegroundColor Green
    }
    else {
        Write-Host $line
    }
}
