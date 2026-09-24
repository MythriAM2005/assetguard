# V1 ML Test Monitoring Script
# Run this script to monitor backend logs during the test

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  V1 ML MODEL - REAL-WORLD TEST MONITOR" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check backend is running
Write-Host "Checking services..." -ForegroundColor Yellow
try {
    $backendHealth = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -Method GET -UseBasicParsing -TimeoutSec 3
    Write-Host "✓ Backend running on port 5000" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend NOT running - start it first!" -ForegroundColor Red
    exit 1
}

try {
    $mlHealth = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -UseBasicParsing -TimeoutSec 3 | Select-Object -ExpandProperty Content | ConvertFrom-Json
    Write-Host "✓ ML Server running: $($mlHealth.model_file) ($($mlHealth.features) features)" -ForegroundColor Green
} catch {
    Write-Host "✗ ML Server NOT running!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Monitoring backend logs... Press Ctrl+C to stop" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Waiting for detection..." -ForegroundColor Yellow
Write-Host ""

# Start monitoring backend process
# This will show new log output as it appears

$backendPath = "c:\flutter-project\assetguard\backend"
cd $backendPath

# Monitor Node.js backend logs
# Filter for community detection and ML-related logs
& node server.js 2>&1 | ForEach-Object {
    $line = $_.ToString()
    
    # Highlight important log lines
    if ($line -match '\[Community\] INCOMING DETECTION REQUEST') {
        Write-Host $line -ForegroundColor Cyan
    }
    elseif ($line -match '\[CommunityWiFi\].*BSSIDs') {
        Write-Host $line -ForegroundColor Yellow
    }
    elseif ($line -match '\[CommunityWiFi\].*ML HTTP STATUS') {
        if ($line -match '200') {
            Write-Host $line -ForegroundColor Green
        } else {
            Write-Host $line -ForegroundColor Red
        }
    }
    elseif ($line -match '\[CommunityWiFi\].*Predicted room') {
        Write-Host $line -ForegroundColor Magenta
    }
    elseif ($line -match '\[CommunityWiFi\].*Confidence') {
        Write-Host $line -ForegroundColor Magenta
    }
    elseif ($line -match '\[Community\].*notification created') {
        Write-Host $line -ForegroundColor Green
    }
    elseif ($line -match 'OUT OF RANGE|⚠️|✗') {
        Write-Host $line -ForegroundColor Red
    }
    elseif ($line -match '✓') {
        Write-Host $line -ForegroundColor Green
    }
    else {
        Write-Host $line
    }
}
