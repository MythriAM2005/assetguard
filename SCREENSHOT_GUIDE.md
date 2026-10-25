# 📸 AssetGuard Screenshot Guide for Documentation

Quick reference for capturing professional screenshots of your deployed AssetGuard system.

---

## 🎯 Essential Screenshots Needed

### 1️⃣ Backend Health Check (Browser)
**URL to open:** `https://assetguard-qynw.onrender.com/api/health`

**What to capture:**
- Browser address bar showing the URL
- JSON response showing:
  - "success": true
  - "database": "connected"
  - Timestamp

**Tips:**
- Install "JSON Viewer" Chrome extension for pretty formatting
- Press F12 and go to Network tab to show the 200 OK status

---

### 2️⃣ Postman API Testing
**Download Postman:** https://www.postman.com/downloads/

**Screenshots needed:**

#### A. Health Check Request
1. Create new request
2. Set method: GET
3. Set URL: `https://assetguard-qynw.onrender.com/api/health`
4. Click Send
5. **Screenshot:** Full window showing request + response

#### B. User Registration
1. Create new request
2. Set method: POST
3. Set URL: `https://assetguard-qynw.onrender.com/api/auth/register`
4. Go to Headers tab, add: `Content-Type: application/json`
5. Go to Body tab, select "raw" and "JSON"
6. Paste:
```json
{
  "name": "Demo User",
  "email": "demo@assetguard.io",
  "password": "Demo123!@#"
}
```
7. Click Send
8. **Screenshot:** Request body + response with token

#### C. Create Asset (Authenticated)
1. First, copy token from registration response
2. Create new request
3. Set method: POST
4. Set URL: `https://assetguard-qynw.onrender.com/api/assets`
5. Go to Authorization tab:
   - Type: Bearer Token
   - Token: [paste your token]
6. Go to Body tab, paste:
```json
{
  "name": "MacBook Pro",
  "description": "Company laptop - 16 inch",
  "category": "electronics",
  "bluetoothId": "AA:BB:CC:DD:EE:FF"
}
```
7. Click Send
8. **Screenshot:** Request + successful response

---

### 3️⃣ PowerShell Testing
**Open PowerShell and run these commands:**

```powershell
# Test 1: Health Check
Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/health" | ConvertTo-Json
```
**Screenshot:** Command + JSON output

```powershell
# Test 2: Full test workflow
$body = @{
    name = "Test User"
    email = "test@example.com"
    password = "Test123!@#"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://assetguard-qynw.onrender.com/api/auth/register" `
    -Method POST -Body $body -ContentType "application/json" | ConvertTo-Json
```
**Screenshot:** Registration response showing token

---

### 4️⃣ Render Dashboard
**Go to:** https://dashboard.render.com

**Screenshots needed:**

1. **Service Overview**
   - Navigate to your "assetguard-backend" service
   - **Screenshot:** Service status showing "Live"

2. **Deployment Logs**
   - Click on "Logs" tab
   - **Screenshot:** Successful deployment logs showing:
     - "npm install" success
     - "npm start" success
     - "AssetGuard API running on port 10000"
     - "MongoDB Atlas connected"

3. **Environment Variables**
   - Click on "Environment" tab
   - **Screenshot:** List of environment variables (BLUR THE VALUES!)
   - Show variable names only:
     - MONGODB_URI
     - JWT_SECRET
     - ML_API_URL
     - NODE_ENV
     - etc.

4. **Settings Page**
   - Click on "Settings" tab
   - **Screenshot:** Build & deploy configuration
   - Show:
     - Build Command: npm install
     - Start Command: npm start
     - Health Check Path: /api/health

---

### 5️⃣ Mobile App Screenshots

**On your Android phone with AssetGuard installed:**

#### Registration Flow
1. Open app
2. **Screenshot:** Welcome/splash screen
3. Tap "Register"
4. **Screenshot:** Registration form (empty)
5. Fill in details
6. **Screenshot:** Registration form (filled)
7. Tap Register
8. **Screenshot:** Success message / automatic login

#### Login Flow
1. **Screenshot:** Login screen
2. Enter credentials
3. **Screenshot:** Successful login / home screen

#### Dashboard
1. Navigate to Dashboard
2. **Screenshot:** Dashboard showing statistics

#### Asset List
1. Navigate to Assets
2. **Screenshot:** Empty asset list (if first time)
3. Create an asset
4. **Screenshot:** Asset list with items

#### Create Asset
1. Tap "Add Asset" button
2. **Screenshot:** Create asset form
3. Fill in details
4. **Screenshot:** Form filled
5. Save asset
6. **Screenshot:** Success message

#### Asset Details
1. Tap on an asset
2. **Screenshot:** Asset details screen showing:
   - Name, description, category
   - Status (SAFE/LOST/RECOVERED)
   - Last seen location
   - Bluetooth ID

#### BLE Scanning
1. Go to BLE scan feature
2. Grant permissions
3. **Screenshot:** Permission dialog
4. Start scanning
5. **Screenshot:** Scanning in progress
6. **Screenshot:** Detected devices list

#### Location Detection
1. Go to room prediction feature
2. Start Wi-Fi scan
3. **Screenshot:** Wi-Fi scanning
4. **Screenshot:** Predicted room result

---

### 6️⃣ MongoDB Atlas Dashboard
**Go to:** https://cloud.mongodb.com

**Screenshots needed:**

1. **Cluster Overview**
   - Navigate to your cluster
   - **Screenshot:** Cluster showing "Healthy" status

2. **Collections**
   - Click "Browse Collections"
   - **Screenshot:** Database "assetguard" with collections:
     - users
     - assets
     - detections
     - communitysensings
     - etc.

3. **Metrics**
   - Click "Metrics" tab
   - **Screenshot:** Database activity graphs

---

## 🎨 Screenshot Best Practices

### General Tips:
1. **Clean Desktop:** Close unnecessary windows
2. **Full Screen:** Capture complete windows
3. **High Resolution:** Use native screen resolution
4. **Good Contrast:** Light theme for code/data
5. **Annotations:** Add arrows/highlights if needed
6. **Consistent Style:** Same tools throughout

### For JSON Responses:
1. **Pretty Print:** Use JSON formatter
2. **Syntax Highlighting:** Use tools with color coding
3. **Complete Response:** Show full JSON, don't crop

### For Mobile:
1. **Portrait Mode:** Standard phone orientation
2. **Clean Status Bar:** Remove notifications if possible
3. **Good Lighting:** Bright, clear screen
4. **No Glare:** Avoid reflections

### For Browser:
1. **Zoom 100%:** Default zoom level
2. **Developer Tools:** Show Network tab for status codes
3. **URL Visible:** Always show address bar
4. **Tab Title:** Shows page/API name

---

## 🛠️ Recommended Tools

### Browser Extensions:
- **JSON Viewer** (Chrome/Edge)
- **JSONView** (Firefox)
- **Awesome Screenshot** (All browsers)

### Desktop Apps:
- **ShareX** (Windows - Free)
- **Lightshot** (Cross-platform)
- **Snagit** (Professional)
- **Greenshot** (Free, open-source)

### Mobile Apps:
- **Screenshot Touch** (Android)
- **Stitch It!** (iOS - for long scrolling screenshots)

### Video Recording (Optional):
- **OBS Studio** (Free)
- **Camtasia** (Professional)
- **Loom** (Browser-based)

---

## 📁 Organization Template

```
AssetGuard_Screenshots/
│
├── 01_Backend_API/
│   ├── health_check_browser.png
│   ├── health_check_postman.png
│   ├── user_registration.png
│   ├── user_login.png
│   ├── create_asset.png
│   ├── list_assets.png
│   └── dashboard_stats.png
│
├── 02_Mobile_App/
│   ├── splash_screen.png
│   ├── registration_form.png
│   ├── login_screen.png
│   ├── dashboard.png
│   ├── asset_list.png
│   ├── asset_details.png
│   ├── ble_scanning.png
│   └── room_prediction.png
│
├── 03_Deployment/
│   ├── render_dashboard.png
│   ├── render_logs.png
│   ├── render_environment.png
│   └── render_settings.png
│
├── 04_Database/
│   ├── mongodb_cluster.png
│   ├── mongodb_collections.png
│   └── mongodb_metrics.png
│
└── 05_Testing/
    ├── postman_collection.png
    ├── powershell_tests.png
    └── api_responses.png
```

---

## 🎬 Quick Recording Checklist

### Video Demo (Optional):
Record a 2-3 minute demo showing:

1. **Introduction** (10 sec)
   - "Welcome to AssetGuard production deployment"

2. **Backend Health** (20 sec)
   - Open browser, show health check
   - Show Render dashboard

3. **API Testing** (30 sec)
   - Open Postman
   - Show registration → login → create asset flow

4. **Mobile App** (60 sec)
   - Open app on phone
   - Show registration/login
   - Create an asset
   - Show BLE scanning
   - Show dashboard

5. **Conclusion** (10 sec)
   - "AssetGuard successfully deployed and operational"

---

## ✅ Screenshot Checklist

Print this and check off as you capture:

### Backend API:
- [ ] Health check (browser)
- [ ] Health check (Postman)
- [ ] User registration (Postman)
- [ ] User login (Postman)
- [ ] Create asset (Postman)
- [ ] List assets (Postman)
- [ ] Dashboard stats (Postman)
- [ ] PowerShell test output

### Deployment:
- [ ] Render service overview
- [ ] Render deployment logs
- [ ] Render environment variables (BLURRED)
- [ ] Render settings page
- [ ] MongoDB Atlas cluster
- [ ] MongoDB collections
- [ ] MongoDB metrics

### Mobile App:
- [ ] Splash/welcome screen
- [ ] Registration form
- [ ] Login screen
- [ ] Dashboard
- [ ] Asset list (empty)
- [ ] Asset list (with items)
- [ ] Create asset form
- [ ] Asset details
- [ ] BLE scanning
- [ ] Room prediction
- [ ] Permission dialogs

### Bonus:
- [ ] GitHub repository page
- [ ] Commit history showing deployment commits
- [ ] Network tab showing API calls
- [ ] MongoDB Compass (if using)

---

## 🚀 Start Here: 1-Minute Quick Test

**Open this URL in your browser RIGHT NOW:**
```
https://assetguard-qynw.onrender.com/api/health
```

**You should see:**
```json
{
  "success": true,
  "message": "AssetGuard API is running",
  "database": "connected",
  "timestamp": "2026-09-24T..."
}
```

**Take screenshot #1 ✅**

Then download Postman and continue with the guide above!

---

**Good luck with your documentation! 📸🚀**
