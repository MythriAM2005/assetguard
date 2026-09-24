# AssetGuard Backend Server Starter
# Quick script to start the backend with status checks

Write-Host "`n🚀 Starting AssetGuard Backend Server...`n" -ForegroundColor Cyan

# Check if in correct directory
if (-not (Test-Path ".\backend\server.js")) {
    Write-Host "❌ Error: backend/server.js not found" -ForegroundColor Red
    Write-Host "   Run this script from: c:\flutter-project\assetguard\" -ForegroundColor Yellow
    exit 1
}

# Check if node_modules exists
if (-not (Test-Path ".\backend\node_modules")) {
    Write-Host "⚠️  Dependencies not installed. Installing now...`n" -ForegroundColor Yellow
    Set-Location backend
    npm install
    Set-Location ..
    Write-Host ""
}

# Check if .env exists
if (-not (Test-Path ".\backend\.env")) {
    Write-Host "❌ Error: backend/.env not found" -ForegroundColor Red
    Write-Host "   Create .env file with MongoDB and other settings" -ForegroundColor Yellow
    exit 1
}

# Display configuration
Write-Host "📋 Configuration:" -ForegroundColor Cyan
$envContent = Get-Content ".\backend\.env" -Raw

if ($envContent -match "MONGODB_URI=mongodb") {
    Write-Host "   ✅ MongoDB: Configured" -ForegroundColor Green
}

if ($envContent -match "ML_API_URL=(.+)") {
    $mlUrl = $matches[1]
    Write-Host "   ✅ ML Server: $mlUrl" -ForegroundColor Green
}

if ($envContent -match "EMAIL_VERIFICATION_ENABLED=(.+)") {
    $emailVerif = $matches[1]
    if ($emailVerif -eq "false") {
        Write-Host "   ✅ Email Verification: DISABLED (Testing Mode)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Email Verification: ENABLED (Production Mode)" -ForegroundColor Yellow
    }
}

Write-Host "`n🔄 Starting server on port 5000..." -ForegroundColor Cyan
Write-Host "   Press Ctrl+C to stop`n" -ForegroundColor Gray
Write-Host "----------------------------------------`n" -ForegroundColor DarkGray

# Start the server
Set-Location backend
node server.js
