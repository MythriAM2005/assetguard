# AssetGuard Quick Test Script
# Run this script to quickly verify all components before testing

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ASSETGUARD - QUICK TEST VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allGood = $true

# Test 1: Check if APK exists
Write-Host "[1/8] Checking APK..." -NoNewline
$apkPath = ".\build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $apk = Get-Item $apkPath
    Write-Host " ✅ FOUND" -ForegroundColor Green
    Write-Host "      Path: $apkPath" -ForegroundColor Gray
    Write-Host "      Size: $([math]::Round($apk.Length/1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "      Built: $($apk.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host " ❌ NOT FOUND" -ForegroundColor Red
    Write-Host "      Run: flutter build apk" -ForegroundColor Yellow
    $allGood = $false
}

# Test 2: Check backend dependencies
Write-Host "`n[2/8] Checking backend dependencies..." -NoNewline
if (Test-Path ".\backend\node_modules") {
    Write-Host " ✅ INSTALLED" -ForegroundColor Green
} else {
    Write-Host " ❌ MISSING" -ForegroundColor Red
    Write-Host "      Run: cd backend && npm install" -ForegroundColor Yellow
    $allGood = $false
}

# Test 3: Check .env file
Write-Host "`n[3/8] Checking backend .env..." -NoNewline
if (Test-Path ".\backend\.env") {
    Write-Host " ✅ FOUND" -ForegroundColor Green
    $envContent = Get-Content ".\backend\.env" -Raw
    if ($envContent -match "MONGODB_URI=mongodb") {
        Write-Host "      MongoDB: Configured" -ForegroundColor Gray
    }
    if ($envContent -match "ML_API_URL=http://") {
        $mlUrl = ($envContent | Select-String "ML_API_URL=(.+)").Matches.Groups[1].Value
        Write-Host "      ML Server: $mlUrl" -ForegroundColor Gray
    }
    if ($envContent -match "EMAIL_VERIFICATION_ENABLED=false") {
        Write-Host "      Email Verification: DISABLED (Testing Mode)" -ForegroundColor Gray
    }
} else {
    Write-Host " ❌ NOT FOUND" -ForegroundColor Red
    $allGood = $false
}

# Test 4: Check Flutter config
Write-Host "`n[4/8] Checking Flutter API config..." -NoNewline
if (Test-Path ".\lib\utils\api_config.dart") {
    Write-Host " ✅ FOUND" -ForegroundColor Green
    $apiConfig = Get-Content ".\lib\utils\api_config.dart" -Raw
    if ($apiConfig -match "baseUrl = '(.+)'") {
        $baseUrl = $matches[1]
        Write-Host "      Backend URL: $baseUrl" -ForegroundColor Gray
    }
} else {
    Write-Host " ❌ NOT FOUND" -ForegroundColor Red
    $allGood = $false
}

# Test 5: Check if backend server is running
Write-Host "`n[5/8] Testing backend server..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000" -Method GET -TimeoutSec 2 -ErrorAction Stop
    Write-Host " ✅ RUNNING" -ForegroundColor Green
    Write-Host "      Status: Server is accessible" -ForegroundColor Gray
} catch {
    Write-Host " ❌ NOT RUNNING" -ForegroundColor Red
    Write-Host "      Start server: cd backend && node server.js" -ForegroundColor Yellow
    $allGood = $false
}

# Test 6: Test backend auth endpoint
Write-Host "`n[6/8] Testing backend API endpoints..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/auth/register" -Method POST -Body '{}' -ContentType "application/json" -TimeoutSec 2 -ErrorAction SilentlyContinue
    Write-Host " ✅ ACCESSIBLE" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host " ✅ ACCESSIBLE" -ForegroundColor Green
    } else {
        Write-Host " ⚠️ PARTIAL" -ForegroundColor Yellow
    }
}

# Test 7: Check ML Server
Write-Host "`n[7/8] Testing ML server..." -NoNewline
try {
    $envContent = Get-Content ".\backend\.env" -Raw
    $mlUrl = ($envContent | Select-String "ML_API_URL=(.+)").Matches.Groups[1].Value
    if ($mlUrl) {
        $response = Invoke-WebRequest -Uri $mlUrl -Method GET -TimeoutSec 3 -ErrorAction Stop
        Write-Host " ✅ ACCESSIBLE" -ForegroundColor Green
        Write-Host "      URL: $mlUrl" -ForegroundColor Gray
    } else {
        Write-Host " ⚠️ URL NOT CONFIGURED" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ❌ NOT ACCESSIBLE" -ForegroundColor Red
    Write-Host "      Note: System will work without room prediction" -ForegroundColor Yellow
}

# Test 8: Check ADB (for phone installation)
Write-Host "`n[8/8] Checking ADB (Android Debug Bridge)..." -NoNewline
try {
    $adbCheck = adb version 2>&1
    if ($adbCheck -match "Android Debug Bridge") {
        Write-Host " ✅ INSTALLED" -ForegroundColor Green
        
        # Check connected devices
        $devices = adb devices | Select-String -Pattern "device$"
        if ($devices) {
            Write-Host "      Connected devices: $($devices.Count)" -ForegroundColor Gray
        } else {
            Write-Host "      No devices connected" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host " ⚠️ NOT FOUND" -ForegroundColor Yellow
    Write-Host "      Install Android SDK Platform Tools for phone installation" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "✅ ALL CRITICAL COMPONENTS READY!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Install APK on phones: adb install $apkPath" -ForegroundColor White
    Write-Host "2. Follow END_TO_END_TESTING_GUIDE.md" -ForegroundColor White
    Write-Host "3. Start with Test Scenario 1 (User Registration)" -ForegroundColor White
} else {
    Write-Host "❌ SOME ISSUES FOUND - FIX BEFORE TESTING" -ForegroundColor Red
    Write-Host "`nReview the issues above and run this script again." -ForegroundColor Yellow
}
Write-Host "========================================`n" -ForegroundColor Cyan

# Offer to start backend server
if (-not $allGood) {
    $startServer = Read-Host "`nDo you want to start the backend server now? (y/n)"
    if ($startServer -eq "y") {
        Write-Host "`nStarting backend server..." -ForegroundColor Cyan
        Set-Location backend
        node server.js
    }
}
