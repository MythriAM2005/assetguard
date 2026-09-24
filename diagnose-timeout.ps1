# AssetGuard Timeout Diagnostic
# Run this to diagnose why phone times out

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TIMEOUT DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. Check laptop IP
Write-Host "[1] Laptop IP Address:" -ForegroundColor Yellow
$currentIp = (ipconfig | Select-String "IPv4" | Select-Object -First 1).ToString().Split(':')[-1].Trim()
Write-Host "    $currentIp" -ForegroundColor Green

# 2. Check api_config.dart
Write-Host "`n[2] APK Configuration:" -ForegroundColor Yellow
$apiConfig = Get-Content "lib\utils\api_config.dart" -Raw
if ($apiConfig -match "baseUrl = '(.+)'") {
    $configUrl = $matches[1]
    Write-Host "    $configUrl" -ForegroundColor Green
    if ($configUrl -match "http://(.+):") {
        $configIp = $matches[1]
        if ($configIp -eq $currentIp) {
            Write-Host "    ✅ IP matches!" -ForegroundColor Green
        } else {
            Write-Host "    ❌ IP MISMATCH!" -ForegroundColor Red
            Write-Host "       Config: $configIp" -ForegroundColor Yellow
            Write-Host "       Current: $currentIp" -ForegroundColor Yellow
        }
    }
}

# 3. Check APK build time
Write-Host "`n[3] APK Build Time:" -ForegroundColor Yellow
$apk = Get-Item "build\app\outputs\flutter-apk\app-release.apk" -ErrorAction SilentlyContinue
if ($apk) {
    Write-Host "    Built: $($apk.LastWriteTime)" -ForegroundColor Green
    $timeSince = (Get-Date) - $apk.LastWriteTime
    Write-Host "    Age: $([Math]::Round($timeSince.TotalMinutes, 1)) minutes ago" -ForegroundColor Gray
} else {
    Write-Host "    ❌ APK not found" -ForegroundColor Red
}

# 4. Check backend
Write-Host "`n[4] Backend Server:" -ForegroundColor Yellow
$node = Get-Process -Name node -ErrorAction SilentlyContinue
if ($node) {
    Write-Host "    ✅ Running (PID: $($node.Id))" -ForegroundColor Green
} else {
    Write-Host "    ❌ NOT running" -ForegroundColor Red
    Write-Host "    ACTION: Run .\start-backend.ps1" -ForegroundColor Cyan
}

# 5. Check port 5000
Write-Host "`n[5] Port 5000 Status:" -ForegroundColor Yellow
$portCheck = netstat -an | Select-String ":5000.*LISTENING"
if ($portCheck) {
    Write-Host "    ✅ Listening on port 5000" -ForegroundColor Green
} else {
    Write-Host "    ❌ Port 5000 not listening" -ForegroundColor Red
}

# 6. Test from laptop
Write-Host "`n[6] Test from Laptop:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
    Write-Host "    ✅ Backend responding on localhost" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -match "404|not found") {
        Write-Host "    ✅ Backend responding (404 is OK)" -ForegroundColor Green
    } else {
        Write-Host "    ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 7. Test on IP
Write-Host "`n[7] Test on IP ($currentIp):" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$currentIp:5000" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
    Write-Host "    ✅ Backend responding on $currentIp" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -match "404|not found") {
        Write-Host "    ✅ Backend responding (404 is OK)" -ForegroundColor Green
    } else {
        Write-Host "    ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 8. Check Windows Firewall
Write-Host "`n[8] Windows Firewall:" -ForegroundColor Yellow
$firewallRules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
    ($_.DisplayName -like "*Node*" -or $_.DisplayName -like "*5000*" -or $_.DisplayName -like "*AssetGuard*") -and 
    $_.Enabled -eq $true
}
if ($firewallRules) {
    Write-Host "    ✅ Found $($firewallRules.Count) active rule(s)" -ForegroundColor Green
    foreach ($rule in $firewallRules) {
        Write-Host "       - $($rule.DisplayName) ($($rule.Direction))" -ForegroundColor Gray
    }
} else {
    Write-Host "    ⚠️  No firewall rules found" -ForegroundColor Yellow
    Write-Host "       May need to add rule for port 5000" -ForegroundColor Yellow
}

# 9. Check network profile
Write-Host "`n[9] Network Profile:" -ForegroundColor Yellow
$profile = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object -First 1
if ($profile) {
    Write-Host "    Network: $($profile.Name)" -ForegroundColor Gray
    Write-Host "    Category: $($profile.NetworkCategory)" -ForegroundColor Gray
    if ($profile.NetworkCategory -eq "Public") {
        Write-Host "    ⚠️  PUBLIC network may block incoming connections" -ForegroundColor Yellow
    } else {
        Write-Host "    ✅ PRIVATE network" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHONE TESTING CHECKLIST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "CRITICAL: Test these on your phone:`n" -ForegroundColor Yellow

Write-Host "1. PHONE BROWSER TEST (Most Important!)" -ForegroundColor Cyan
Write-Host "   Open phone browser, go to:" -ForegroundColor White
Write-Host "   http://$currentIp:5000" -ForegroundColor Green -BackgroundColor Black
Write-Host ""
Write-Host "   Expected Results:" -ForegroundColor White
Write-Host "   ✅ GOOD: See JSON error {'success':false,...}" -ForegroundColor Green
Write-Host "      → Network is fine, problem is app config" -ForegroundColor Gray
Write-Host "   ❌ BAD: Timeout or 'can't reach this page'" -ForegroundColor Red
Write-Host "      → Network problem (firewall/router/Wi-Fi)" -ForegroundColor Gray
Write-Host ""

Write-Host "2. CHECK PHONE WI-FI" -ForegroundColor Cyan
Write-Host "   Phone Settings → Wi-Fi" -ForegroundColor White
Write-Host "   Make sure phone is on SAME Wi-Fi as laptop" -ForegroundColor White
Write-Host ""

Write-Host "3. PING TEST (Optional)" -ForegroundColor Cyan
Write-Host "   Install 'PingTools' or 'Fing' app on phone" -ForegroundColor White
Write-Host "   Try to ping: $currentIp" -ForegroundColor White
Write-Host "   If ping fails → Router has AP Isolation" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "QUICK FIXES TO TRY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "IF PHONE BROWSER TIMES OUT:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Disable Firewall (TEST ONLY)" -ForegroundColor Cyan
Write-Host "  1. Windows Security → Firewall" -ForegroundColor White
Write-Host "  2. Turn OFF (temporarily)" -ForegroundColor White
Write-Host "  3. Test from phone browser" -ForegroundColor White
Write-Host "  4. Turn firewall back ON" -ForegroundColor White
Write-Host "  5. If this worked, add firewall rule (see below)" -ForegroundColor White
Write-Host ""

Write-Host "Option 2: Add Firewall Rule (Run as Admin)" -ForegroundColor Cyan
Write-Host "  New-NetFirewallRule -DisplayName 'AssetGuard 5000' \" -ForegroundColor Gray
Write-Host "    -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 3: Change Network to Private" -ForegroundColor Cyan
Write-Host "  Set-NetConnectionProfile -NetworkCategory Private" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 4: USB Tethering" -ForegroundColor Cyan
Write-Host "  1. Enable USB tethering on phone" -ForegroundColor White
Write-Host "  2. Connect via USB" -ForegroundColor White
Write-Host "  3. Get new IP: ipconfig" -ForegroundColor White
Write-Host "  4. Update api_config.dart" -ForegroundColor White
Write-Host "  5. Rebuild APK" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WHAT TO REPORT BACK" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Tell me:" -ForegroundColor White
Write-Host "1. Phone browser test result (timeout or JSON error?)" -ForegroundColor Yellow
Write-Host "2. Are phone and laptop on same Wi-Fi network?" -ForegroundColor Yellow
Write-Host "3. What is the phone's Wi-Fi network name?" -ForegroundColor Yellow
Write-Host ""

Write-Host "Get laptop's Wi-Fi network:" -ForegroundColor White
Write-Host "netsh wlan show interfaces | Select-String SSID" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================`n" -ForegroundColor Cyan
