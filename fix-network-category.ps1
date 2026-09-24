# Fix Network Category to Allow Connections
# RIGHT-CLICK → RUN AS ADMINISTRATOR

Write-Host "`n🔧 AssetGuard Network Fix" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Must run as Administrator!`n" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'`n" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Running as Administrator`n" -ForegroundColor Green

# Get current network
$profile = Get-NetConnectionProfile | Select-Object -First 1

Write-Host "Current Network:" -ForegroundColor Yellow
Write-Host "  Name: $($profile.Name)" -ForegroundColor White
Write-Host "  Category: $($profile.NetworkCategory)" -ForegroundColor White

if ($profile.NetworkCategory -eq "Private") {
    Write-Host "`n✅ Network is already PRIVATE. No fix needed!" -ForegroundColor Green
    Write-Host "`nIf phone still can't connect, try adding firewall rule:`n" -ForegroundColor Yellow
    Write-Host "New-NetFirewallRule -DisplayName 'AssetGuard 5000' \" -ForegroundColor Gray
    Write-Host "  -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow`n" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host "`n⚠️  Network is PUBLIC - this blocks incoming connections" -ForegroundColor Yellow
Write-Host "`nChanging to PRIVATE..." -ForegroundColor Cyan

try {
    Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private
    Write-Host "✅ SUCCESS! Network changed to PRIVATE`n" -ForegroundColor Green
    
    # Verify
    $newProfile = Get-NetConnectionProfile | Select-Object -First 1
    Write-Host "New Network Category: $($newProfile.NetworkCategory)" -ForegroundColor Green
    
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "NEXT STEP: Test from phone" -ForegroundColor Yellow
    Write-Host "================================`n" -ForegroundColor Cyan
    
    $ip = (ipconfig | Select-String "IPv4" | Select-Object -First 1).ToString().Split(':')[-1].Trim()
    Write-Host "1. Open phone browser" -ForegroundColor White
    Write-Host "2. Go to: http://$ip:5000" -ForegroundColor Green
    Write-Host "3. Should see JSON error (this is good!)" -ForegroundColor White
    Write-Host "4. Then test AssetGuard app registration`n" -ForegroundColor White
    
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)`n" -ForegroundColor Red
    
    Write-Host "ALTERNATIVE: Add firewall rule instead:`n" -ForegroundColor Yellow
    Write-Host "New-NetFirewallRule -DisplayName 'AssetGuard 5000' \" -ForegroundColor Gray
    Write-Host "  -Direction Inbound -LocalPort 5000 -Protocol TCP \" -ForegroundColor Gray
    Write-Host "  -Action Allow -Profile Public`n" -ForegroundColor Gray
}

Read-Host "`nPress Enter to exit"
