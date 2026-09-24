# AssetGuard Connection Diagnostic Script
# Run this to diagnose phone connectivity issues

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ASSETGUARD CONNECTION DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Get laptop IP
Write-Host "[1] Checking Laptop IP Address..." -ForegroundColor Yellow
$ipAddress = (ipconfig | Select-String "IPv4" | Select-Object -First 1).ToString().Split(':')[-1].Trim()
Write-Host "    Laptop IP: $ipAddress" -ForegroundColor Green

# Check Flutter config
Write-Host "`n[2] Checking Flutter API Config..." -ForegroundColor Yellow
$apiConfig = Get-Content ".\lib\utils\api_config.dart" -Raw
if ($apiConfig -match "baseUrl = '(.+)'") {
    $configuredUrl = $matches[1]
    Write-Host "    Configured URL: $configuredUrl" -ForegroundColor Green
    
    if ($configuredUrl -match "http://(.+):5000") {
        $configuredIp = $matches[1]
        if ($configuredIp -eq $ipAddress) {
            Write-Host "    ✅ IP Match: Configuration matches current laptop IP" -ForegroundColor Green
        } else {
            Write-Host "    ❌ IP Mismatch!" -ForegroundColor Red
            Write-Host "       Config has: $configuredIp" -ForegroundColor Yellow
            Write-Host "       Laptop has: $ipAddress" -ForegroundColor Yellow
            Write-Host "       ACTION: Rebuild APK after updating api_config.dart" -ForegroundColor Cyan
        }
    }
}

# Check if backend is running
Write-Host "`n[3] Checking Backend Server..." -ForegroundColor Yellow
$nodeProcess = Get-Process -Name node -ErrorAction SilentlyContinue
if ($nodeProcess) {
    Write-Host "    ✅ Backend is running (PID: $($nodeProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "    ❌ Backend is NOT running" -ForegroundColor Red
    Write-Host "       ACTION: Run .\start-backend.ps1" -ForegroundColor Cyan
    exit 1
}

# Test localhost:5000
Write-Host "`n[4] Testing Backend on localhost:5000..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/auth/register" -Method POST -Body '{}' -ContentType "application/json" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    Write-Host "    ✅ Backend responding on localhost" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "    ✅ Backend responding on localhost (validation error is OK)" -ForegroundColor Green
    } else {
        Write-Host "    ❌ Backend not responding: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test on laptop IP
Write-Host "`n[5] Testing Backend on $ipAddress:5000..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$ipAddress:5000/api/auth/register" -Method POST -Body '{}' -ContentType "application/json" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    Write-Host "    ✅ Backend responding on $ipAddress" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "    ✅ Backend responding on $ipAddress (validation error is OK)" -ForegroundColor Green
    } else {
        Write-Host "    ❌ Backend not responding: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check Windows Firewall
Write-Host "`n[6] Checking Windows Firewall..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "Node.js*" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "    ✅ Firewall rule exists for Node.js" -ForegroundColor Green
} else {
    Write-Host "    ⚠️  No explicit firewall rule found" -ForegroundColor Yellow
    Write-Host "       May need to allow Node.js through firewall" -ForegroundColor Yellow
}

# Network interfaces
Write-Host "`n[7] Network Interfaces..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
foreach ($adapter in $adapters) {
    Write-Host "    - $($adapter.Name): $($adapter.InterfaceDescription)" -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHONE CONNECTIVITY TROUBLESHOOTING" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "If phone can't connect, try these steps:`n" -ForegroundColor Yellow

Write-Host "1. VERIFY PHONE IS ON SAME NETWORK" -ForegroundColor Cyan
Write-Host "   - Check phone Wi-Fi settings" -ForegroundColor White
Write-Host "   - Must be on same network as laptop" -ForegroundColor White
Write-Host "   - Open phone browser: http://$ipAddress:5000" -ForegroundColor White
Write-Host "   - Should see: 'Route GET / not found' (this is GOOD)" -ForegroundColor White

Write-Host "`n2. CHECK WINDOWS FIREWALL" -ForegroundColor Cyan
Write-Host "   Run this command as Administrator:" -ForegroundColor White
Write-Host "   New-NetFirewallRule -DisplayName 'Node.js 5000' -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow" -ForegroundColor Gray

Write-Host "`n3. TEST FROM PHONE BROWSER" -ForegroundColor Cyan
Write-Host "   Open phone Chrome/browser:" -ForegroundColor White
Write-Host "   URL: http://$ipAddress:5000" -ForegroundColor Yellow
Write-Host "   Expected: JSON error message (proves connection works)" -ForegroundColor White

Write-Host "`n4. CHECK APK IS UP TO DATE" -ForegroundColor Cyan
$apk = Get-Item ".\build\app\outputs\flutter-apk\app-debug.apk"
Write-Host "   APK Built: $($apk.LastWriteTime)" -ForegroundColor White
Write-Host "   If IP changed since APK was built, you must rebuild:" -ForegroundColor White
Write-Host "   flutter build apk" -ForegroundColor Gray

Write-Host "`n5. TRY CREATING FIREWALL RULE" -ForegroundColor Cyan
Write-Host "   If all else fails, create Windows Firewall rule:" -ForegroundColor White
Write-Host "   Control Panel → Windows Defender Firewall → Advanced Settings" -ForegroundColor White
Write-Host "   → Inbound Rules → New Rule → Port → TCP 5000 → Allow" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "QUICK TEST FROM PHONE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "On your phone's browser, go to:" -ForegroundColor Yellow
Write-Host "http://$ipAddress:5000" -ForegroundColor Green -BackgroundColor Black
Write-Host "`nIf you see a JSON error, connection works!" -ForegroundColor White
Write-Host "If timeout/no response, firewall is blocking." -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan
