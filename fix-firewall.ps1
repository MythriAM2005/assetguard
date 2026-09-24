# Quick Firewall Fix for AssetGuard Backend
# Run as Administrator

Write-Host "`n🔧 AssetGuard Firewall Fix" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "`nRight-click PowerShell and select 'Run as Administrator'`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running as Administrator`n" -ForegroundColor Green

# Check if rule already exists
$existingRule = Get-NetFirewallRule -DisplayName "AssetGuard Backend (Port 5000)" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "ℹ️  Firewall rule already exists. Recreating..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName "AssetGuard Backend (Port 5000)"
}

# Create new firewall rule
Write-Host "Creating firewall rule for Port 5000..." -ForegroundColor Cyan

try {
    New-NetFirewallRule `
        -DisplayName "AssetGuard Backend (Port 5000)" `
        -Direction Inbound `
        -LocalPort 5000 `
        -Protocol TCP `
        -Action Allow `
        -Profile Any `
        -ErrorAction Stop
    
    Write-Host "✅ Firewall rule created successfully!`n" -ForegroundColor Green
    
    # Verify rule
    $rule = Get-NetFirewallRule -DisplayName "AssetGuard Backend (Port 5000)"
    Write-Host "Rule Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($rule.DisplayName)" -ForegroundColor White
    Write-Host "  Enabled: $($rule.Enabled)" -ForegroundColor White
    Write-Host "  Direction: $($rule.Direction)" -ForegroundColor White
    Write-Host "  Action: $($rule.Action)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Failed to create firewall rule: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get laptop IP
$ipAddress = (ipconfig | Select-String "IPv4" | Select-Object -First 1).ToString().Split(':')[-1].Trim()

Write-Host "`n✅ Firewall configured!`n" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host "NEXT STEP: Test from phone" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host "`nOn your phone's browser, go to:" -ForegroundColor White
Write-Host "http://$ipAddress:5000" -ForegroundColor Green -BackgroundColor Black
Write-Host "`nExpected: JSON error message (this is GOOD)`n" -ForegroundColor White
Write-Host "If still doesn't work, see: FIX_PHONE_CONNECTION.md`n" -ForegroundColor Yellow
