# AssetGuard Production Testing & Screenshot Guide

This guide provides step-by-step instructions for testing your deployed AssetGuard backend API and capturing screenshots for documentation.

---

## 🌐 Production URLs

### Backend API
- **Base URL:** `https://assetguard-qynw.onrender.com`
- **Health Check:** `https://assetguard-qynw.onrender.com/api/health`

### ML Server
- **Base URL:** `https://wifi-server-sl6b.onrender.com`
- **Predict Room:** `https://wifi-server-sl6b.onrender.com/predict-room`

---

## 📸 Screenshot Checklist

### Backend API Testing
- [ ] Health check response
- [ ] User registration response
- [ ] User login response
- [ ] Get user profile response
- [ ] Create asset response
- [ ] List assets response
- [ ] Asset detection submission
- [ ] Dashboard statistics

### Browser/Postman Testing
- [ ] API endpoints in browser
- [ ] API endpoints in Postman
- [ ] Response status codes
- [ ] Response headers
- [ ] JSON response bodies

### Mobile App Testing
- [ ] Registration screen
- [ ] Login screen
- [ ] Asset list screen
- [ ] Create asset screen
- [ ] Asset details screen
- [ ] BLE scanning screen
- [ ] Community detection screen
- [ ] Dashboard screen

---

## 🧪 API Testing Methods

### Method 1: Browser Testing (Easy)

#### 1. Health Check
**URL:** `https://assetguard-qynw.onrender.com/api/health`

**Instructions:**
1. Open your web browser (Chrome, Firefox, Edge)
2. Copy and paste the URL above
3. Press Enter
4. Take a screenshot of the JSON response

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "message": "AssetGuard API is running",
    "database": "connected",
    "timestamp": "2026-09-24T18:00:00.000Z"
  }
}
```

**Screenshot Tips:**
- Show the full URL in the address bar
- Capture the entire JSON response
- Use browser's JSON formatter (install JSON Viewer extension)

---

### Method 2: PowerShell/Command Line Testing

#### 1. Health Check
```powershell
# Windows PowerShell
Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/health" | ConvertTo-Json -Depth 10
```

**Screenshot Tips:**
- Run in PowerShell
- Capture command + output
- Show the full JSON response

#### 2. User Registration (Create Test Account)
```powershell
$body = @{
    name = "Test User"
    email = "testuser@example.com"
    password = "Test123!@#"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/auth/register" `
    -Method POST `
    -Body $body `
    -ContentType "application/json" | ConvertTo-Json -Depth 10
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "_id": "66f2a1b3c4d5e6f7g8h9i0j1",
      "name": "Test User",
      "email": "testuser@example.com"
    }
  },
  "message": "Registration successful"
}
```

#### 3. User Login
```powershell
$body = @{
    email = "testuser@example.com"
    password = "Test123!@#"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/auth/login" `
    -Method POST `
    -Body $body `
    -ContentType "application/json" | ConvertTo-Json -Depth 10
```

**Save the token for authenticated requests:**
```powershell
$response = Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/auth/login" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"

$token = $response.data.token
Write-Host "Token: $token"
```

#### 4. Create Asset (Authenticated)
```powershell
$body = @{
    name = "Test Laptop"
    description = "MacBook Pro 2024"
    category = "electronics"
    bluetoothId = "AA:BB:CC:DD:EE:FF"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $token"
}

Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/assets" `
    -Method POST `
    -Headers $headers `
    -Body $body `
    -ContentType "application/json" | ConvertTo-Json -Depth 10
```

#### 5. List All Assets (Authenticated)
```powershell
$headers = @{
    "Authorization" = "Bearer $token"
}

Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/assets" `
    -Method GET `
    -Headers $headers | ConvertTo-Json -Depth 10
```

#### 6. Get Dashboard Statistics (Authenticated)
```powershell
$headers = @{
    "Authorization" = "Bearer $token"
}

Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/dashboard/stats" `
    -Method GET `
    -Headers $headers | ConvertTo-Json -Depth 10
```

---

### Method 3: cURL Testing (Cross-Platform)

#### 1. Health Check
```bash
curl https://assetguard-qynw.onrender.com/api/health
```

#### 2. User Registration
```bash
curl -X POST https://assetguard-qynw.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "testuser@example.com",
    "password": "Test123!@#"
  }'
```

#### 3. User Login
```bash
curl -X POST https://assetguard-qynw.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "Test123!@#"
  }'
```

#### 4. Create Asset (Replace YOUR_TOKEN)
```bash
curl -X POST https://assetguard-qynw.onrender.com/api/assets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Test Laptop",
    "description": "MacBook Pro 2024",
    "category": "electronics",
    "bluetoothId": "AA:BB:CC:DD:EE:FF"
  }'
```

#### 5. List Assets
```bash
curl -X GET https://assetguard-qynw.onrender.com/api/assets \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### Method 4: Postman Testing (Professional)

#### Setup Postman:
1. Download Postman: https://www.postman.com/downloads/
2. Create a new collection: "AssetGuard API"
3. Set base URL variable: `{{baseUrl}}` = `https://assetguard-qynw.onrender.com`

#### Request 1: Health Check
- **Method:** GET
- **URL:** `{{baseUrl}}/api/health`
- **Headers:** None needed
- **Body:** None
- **Screenshot:** Response tab showing success

#### Request 2: Register User
- **Method:** POST
- **URL:** `{{baseUrl}}/api/auth/register`
- **Headers:** `Content-Type: application/json`
- **Body (JSON):**
```json
{
  "name": "Test User",
  "email": "testuser@example.com",
  "password": "Test123!@#"
}
```
- **Screenshot:** Request + Response

#### Request 3: Login
- **Method:** POST
- **URL:** `{{baseUrl}}/api/auth/login`
- **Headers:** `Content-Type: application/json`
- **Body (JSON):**
```json
{
  "email": "testuser@example.com",
  "password": "Test123!@#"
}
```
- **Screenshot:** Response with token
- **Action:** Copy token to environment variable `{{authToken}}`

#### Request 4: Get Profile (Authenticated)
- **Method:** GET
- **URL:** `{{baseUrl}}/api/auth/me`
- **Headers:** `Authorization: Bearer {{authToken}}`
- **Body:** None
- **Screenshot:** User profile response

#### Request 5: Create Asset (Authenticated)
- **Method:** POST
- **URL:** `{{baseUrl}}/api/assets`
- **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer {{authToken}}`
- **Body (JSON):**
```json
{
  "name": "MacBook Pro",
  "description": "Company laptop - 16 inch M3 Pro",
  "category": "electronics",
  "bluetoothId": "A1:B2:C3:D4:E5:F6"
}
```
- **Screenshot:** Request + Response

#### Request 6: List Assets (Authenticated)
- **Method:** GET
- **URL:** `{{baseUrl}}/api/assets`
- **Headers:** `Authorization: Bearer {{authToken}}`
- **Body:** None
- **Screenshot:** List of assets

#### Request 7: Mark Asset as Lost (Authenticated)
- **Method:** PATCH
- **URL:** `{{baseUrl}}/api/assets/ASSET_ID/lost`
- **Headers:** `Authorization: Bearer {{authToken}}`
- **Body:** None
- **Screenshot:** Updated asset status

#### Request 8: Dashboard Stats (Authenticated)
- **Method:** GET
- **URL:** `{{baseUrl}}/api/dashboard/stats`
- **Headers:** `Authorization: Bearer {{authToken}}`
- **Body:** None
- **Screenshot:** Statistics response

---

## 🌐 Browser Testing URLs (Direct Access)

### Open These URLs in Browser:

1. **Health Check (Works without auth):**
   ```
   https://assetguard-qynw.onrender.com/api/health
   ```
   ✅ Should show JSON with "database": "connected"

2. **Check Server Status:**
   ```
   https://assetguard-qynw.onrender.com
   ```
   ✅ May show "Cannot GET /" (normal - API only serves /api/* routes)

---

## 📱 Mobile App Testing

### Screenshots to Capture:

1. **Registration Screen**
   - Open AssetGuard app
   - Go to registration
   - Fill in test details
   - Screenshot before submitting
   - Submit and screenshot success message

2. **Login Screen**
   - Enter credentials
   - Screenshot before login
   - Screenshot after successful login

3. **Asset List Screen**
   - Screenshot empty state
   - Screenshot with assets

4. **Create Asset Screen**
   - Screenshot form
   - Screenshot after creation

5. **Asset Details Screen**
   - Open an asset
   - Screenshot details
   - Screenshot status (SAFE/LOST/RECOVERED)

6. **BLE Scanning**
   - Start BLE scan
   - Screenshot scanning state
   - Screenshot detected devices

7. **Location Detection**
   - Screenshot Wi-Fi scan
   - Screenshot room prediction result

8. **Dashboard**
   - Screenshot statistics
   - Screenshot charts/graphs

---

## 🧪 Complete Test Workflow

### Step-by-Step Testing Sequence:

```powershell
# 1. Check backend health
Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/health"
# ✅ Screenshot this

# 2. Register a new user
$registerBody = @{
    name = "Demo User"
    email = "demo@assetguard.io"
    password = "Demo123!@#"
} | ConvertTo-Json

$registerResponse = Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/auth/register" `
    -Method POST -Body $registerBody -ContentType "application/json"
$token = $registerResponse.data.token
# ✅ Screenshot this

# 3. Login with the user
$loginBody = @{
    email = "demo@assetguard.io"
    password = "Demo123!@#"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/auth/login" `
    -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.data.token
# ✅ Screenshot this

# 4. Create assets
$headers = @{ "Authorization" = "Bearer $token" }

$asset1 = @{
    name = "MacBook Pro"
    description = "Company laptop"
    category = "electronics"
    bluetoothId = "AA:BB:CC:DD:EE:F1"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/assets" `
    -Method POST -Headers $headers -Body $asset1 -ContentType "application/json"
# ✅ Screenshot this

# 5. List all assets
Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/assets" `
    -Method GET -Headers $headers
# ✅ Screenshot this

# 6. Get dashboard statistics
Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/dashboard/stats" `
    -Method GET -Headers $headers
# ✅ Screenshot this
```

---

## 📊 Render Dashboard Screenshots

### To capture Render deployment screenshots:

1. **Go to Render Dashboard:**
   ```
   https://dashboard.render.com
   ```

2. **Navigate to your service:**
   - Click on "assetguard-backend" service
   - Screenshot the overview page

3. **Environment Variables:**
   - Click "Environment" tab
   - Screenshot (blur sensitive values)

4. **Deployment Logs:**
   - Click "Logs" tab
   - Screenshot successful deployment logs

5. **Settings:**
   - Screenshot build settings
   - Screenshot health check configuration

---

## 🎯 Screenshot Organization

### Recommended Folder Structure:
```
screenshots/
├── 01-backend-testing/
│   ├── health-check.png
│   ├── user-registration.png
│   ├── user-login.png
│   ├── create-asset.png
│   ├── list-assets.png
│   └── dashboard-stats.png
├── 02-mobile-app/
│   ├── registration-screen.png
│   ├── login-screen.png
│   ├── asset-list.png
│   ├── asset-details.png
│   ├── ble-scanning.png
│   └── dashboard.png
├── 03-postman/
│   ├── postman-collection.png
│   ├── postman-requests.png
│   └── postman-responses.png
└── 04-render-dashboard/
    ├── service-overview.png
    ├── deployment-logs.png
    └── environment-vars.png
```

---

## 🛠️ Tools for Screenshots

### Windows:
- **Snipping Tool** (Win + Shift + S)
- **Snip & Sketch** (Built-in)
- **ShareX** (Free, advanced)

### Mac:
- **Screenshot** (Cmd + Shift + 4)
- **Preview** (Built-in)

### Browser Extensions:
- **Awesome Screenshot**
- **Nimbus Screenshot**
- **Full Page Screen Capture**

### Mobile:
- **Android:** Power + Volume Down
- **iOS:** Side Button + Volume Up

---

## ✅ Testing Checklist

### Backend API Testing
- [ ] Health check returns 200 OK
- [ ] Database shows "connected"
- [ ] User registration works
- [ ] User login returns JWT token
- [ ] Authenticated requests work with token
- [ ] Asset creation works
- [ ] Asset listing works
- [ ] Dashboard statistics work

### Mobile App Testing
- [ ] App launches successfully
- [ ] Registration flow works end-to-end
- [ ] Login flow works
- [ ] Assets can be created
- [ ] Assets can be listed
- [ ] BLE scanning works
- [ ] Location detection works
- [ ] Dashboard shows statistics

### Production Verification
- [ ] No localhost URLs in responses
- [ ] All URLs show production domain
- [ ] HTTPS is enforced
- [ ] Database is MongoDB Atlas
- [ ] No debug/development artifacts

---

## 📧 API Testing Examples Output

### Example 1: Health Check Success
```json
{
  "success": true,
  "data": {
    "message": "AssetGuard API is running",
    "database": "connected",
    "timestamp": "2026-09-24T18:30:45.123Z"
  }
}
```

### Example 2: Registration Success
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NmYy...",
    "user": {
      "_id": "66f2a1b3c4d5e6f7g8h9i0j1",
      "name": "Test User",
      "email": "testuser@example.com",
      "emailVerified": false
    }
  },
  "message": "Registration successful"
}
```

### Example 3: Asset List Success
```json
{
  "success": true,
  "data": [
    {
      "_id": "66f2b4c5d6e7f8g9h0i1j2k3",
      "name": "MacBook Pro",
      "description": "Company laptop",
      "category": "electronics",
      "status": "SAFE",
      "bluetoothId": "AA:BB:CC:DD:EE:F1",
      "owner": "66f2a1b3c4d5e6f7g8h9i0j1",
      "createdAt": "2026-09-24T18:31:00.000Z"
    }
  ]
}
```

---

## 🎓 Pro Tips

1. **Use JSON Formatter:** Install a JSON viewer browser extension for prettier output
2. **Save Tokens:** Store auth tokens in environment variables for repeated testing
3. **Use Postman Collections:** Export and share complete test collections
4. **Document Errors:** Screenshot both successes AND error responses
5. **Test Edge Cases:** Try invalid inputs, missing fields, etc.
6. **Compare Environments:** Test both local and production to show differences

---

## 🚀 Quick Start Commands

**Copy and paste this into PowerShell for instant testing:**

```powershell
# Quick Test Script
Write-Host "Testing AssetGuard Production API..." -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Health Check..." -ForegroundColor Yellow
$health = Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/health"
$health | ConvertTo-Json
Write-Host "✅ Health Check Passed" -ForegroundColor Green
Write-Host ""

Write-Host "2. Testing Registration..." -ForegroundColor Yellow
$regBody = @{
    name = "Test User $(Get-Date -Format 'HHmmss')"
    email = "test$(Get-Date -Format 'HHmmss')@example.com"
    password = "Test123!@#"
} | ConvertTo-Json

$regResponse = Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/auth/register" `
    -Method POST -Body $regBody -ContentType "application/json"
$token = $regResponse.data.token
Write-Host "✅ Registration Passed - Token received" -ForegroundColor Green
Write-Host ""

Write-Host "3. Creating Asset..." -ForegroundColor Yellow
$headers = @{ "Authorization" = "Bearer $token" }
$assetBody = @{
    name = "Test Asset"
    description = "Testing asset creation"
    category = "electronics"
} | ConvertTo-Json

$asset = Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/assets" `
    -Method POST -Headers $headers -Body $assetBody -ContentType "application/json"
Write-Host "✅ Asset Created Successfully" -ForegroundColor Green
$asset | ConvertTo-Json

Write-Host ""
Write-Host "🎉 All Tests Passed!" -ForegroundColor Green
```

---

**Happy Testing! 🚀**

For questions or issues, check the main documentation at DEPLOYMENT.md or README.md.
