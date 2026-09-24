# ASSETGUARD — FINAL DEPLOYMENT CHECKLIST

**Date:** 2026-08-28  
**Project:** AssetGuard AI v1.0.0+1  
**Package:** io.assetguard.app  
**Status:** READY FOR USER INPUT

---

## CRITICAL SECURITY NOTICE

⚠️ **SECRETS IDENTIFIED IN .env FILE**

The following secrets are present and must be rotated before public deployment:

1. **MONGODB_URI** - Contains database credentials - ⚠️ **ROTATE BEFORE PUBLIC DEPLOYMENT**
2. **JWT_SECRET** - Used for authentication tokens - ⚠️ **ROTATE BEFORE PUBLIC DEPLOYMENT**
3. **RESEND_API_KEY** - Email service API key - ⚠️ **ROTATE BEFORE PUBLIC DEPLOYMENT**

**Action Required:**
- Generate new production secrets
- Update `.env` on production server only
- Never commit production `.env` to source control
- Backend `.gitignore` already excludes `.env` ✓

---

## A. ALREADY COMPLETE ✅

### Flutter App

✅ **Package Name:** `io.assetguard.app` (changed from com.example.assetguard)  
✅ **Version:** 1.0.0+1 (from pubspec.yaml)  
✅ **App Name:** "AssetGuard" (verified in AndroidManifest.xml)  
✅ **Permissions:** All required permissions declared:
   - INTERNET
   - BLUETOOTH_SCAN
   - BLUETOOTH_CONNECT
   - BLUETOOTH (legacy)
   - BLUETOOTH_ADMIN (legacy)
   - ACCESS_FINE_LOCATION
   - ACCESS_COARSE_LOCATION
   - ACCESS_WIFI_STATE
   - CHANGE_WIFI_STATE
   - FOREGROUND_SERVICE
   - FOREGROUND_SERVICE_LOCATION
   - POST_NOTIFICATIONS

✅ **API URL Configuration:** Environment-based (lib/config/environment.dart)  
✅ **No Hardcoded IPs:** Verified - no localhost/192.168/10.x in Flutter code  
✅ **Debug Logging:** Fixed - using debugPrint() instead of print()  
✅ **Network Security:** Cleaned - no development IPs in config  
✅ **Build Validation:** Debug APK builds successfully (150MB)

### Flutter Analyze Issues (5 remaining, all NON-BLOCKING)

1. **unnecessary_import** (info) - Unnecessary Flutter/foundation import  
   - File: `lib\screens\asset_details_screen.dart:2:8`
   - Impact: None - code works correctly
   - Blocking: NO

2. **use_null_aware_elements** (info x3) - Style suggestion  
   - Files: `lib\services\community_detection_service.dart` (lines 73, 75, 76)
   - Impact: None - code works correctly
   - Blocking: NO

3. **invalid_use_of_visible_for_testing_member** (warning) - Expected warning  
   - File: `lib\services\community_sensing_service.dart:168:47`
   - Reason: Using `receivePort` from flutter_foreground_task (documented usage)
   - Impact: None - this is the correct way to use the API
   - Blocking: NO

**VERDICT:** All 5 analyzer issues are NON-BLOCKING and do NOT prevent deployment.

---

### Backend

✅ **MongoDB:** Atlas production connection configured  
✅ **JWT:** Secret present (must rotate for production)  
✅ **Email Service:** Resend API configured  
✅ **Environment Variables:** .env properly gitignored  
✅ **No Hardcoded IPs:** Verified - no localhost/development IPs in backend code  
✅ **API Routes:** All Flutter endpoints implemented  
✅ **Error Handling:** Complete  
✅ **Validation:** Input validation present  
✅ **Logging:** Production diagnostic logging kept

---

### V1 ML Server

✅ **Model:** V1 (assetguard_live_room_model.pkl)  
✅ **Features:** 105 BSSIDs  
✅ **Rooms:** 22 room classes  
✅ **Endpoints:** /health and /predict-room verified working  
✅ **Integration:** Backend → ML flow working  
✅ **Status:** FROZEN (not modified during audit)

---

### Database

✅ **MongoDB Atlas:** Production connection string configured  
✅ **Database Name:** `assetguard`  
✅ **Collections:** All required collections exist  
✅ **Security:** Connection string uses authentication  
✅ **No Test DB Risk:** Production URI configured

---

### Working Features (Verified FROZEN)

✅ **BLE Detection:** Working - NOT modified  
✅ **Wi-Fi Scanning:** Working - NOT modified  
✅ **Community Sensing:** Working - NOT modified  
✅ **V1 ML Integration:** Working - NOT modified  
✅ **Notifications:** Working - NOT modified  
✅ **Authentication:** Working - NOT modified  
✅ **Asset Management:** Working - NOT modified

---

## B. CODE CHANGES STILL REQUIRED

### ❌ NONE

All code changes have been completed. The application is code-complete and ready for deployment once user inputs are provided.

---

## C. USER/INFRASTRUCTURE INPUT REQUIRED

### 🔴 CRITICAL — DEPLOYMENT BLOCKERS

#### 1. BACKEND_LOCATION
**Question:** Where will the backend server be deployed?

**Options:**
- Local server (organization network)
- Cloud VPS (AWS/Azure/GCP/DigitalOcean)
- Dedicated server
- Personal server

**Required Information:**
```
BACKEND_LOCATION: [USER MUST PROVIDE]
```

**Why Needed:** Determines network configuration and accessibility

---

#### 2. BACKEND_PRODUCTION_URL
**Question:** What is the complete backend URL that the Flutter app will connect to?

**Examples:**
- `http://192.168.1.100:5000` (local network)
- `http://203.45.67.89:5000` (public IP)
- `http://api.yourdomain.com` (domain name)
- `https://api.yourdomain.com` (domain with HTTPS)

**Required Information:**
```
BACKEND_PRODUCTION_URL: [USER MUST PROVIDE]
```

**Why Needed:** 
- Flutter app must know where to send requests
- Used in build command: `flutter build apk --dart-define=API_URL=<THIS_VALUE>`
- Cannot build production APK without this

---

#### 3. ML_LOCATION
**Question:** Where will the V1 ML server be deployed?

**Options:**

**Option A: Co-located (same machine as backend)**
- ML server runs on same server as backend
- Backend connects via `http://localhost:8000`
- Best performance (no network latency)
- Simpler deployment
- **Current `.env` configuration:** `ML_API_URL=http://localhost:8000`

**Option B: Separate server**
- ML server runs on different machine
- Backend connects via `http://<ml-server-ip>:8000`
- Requires updating `.env` with ML server IP
- Requires firewall rules allowing backend → ML server on port 8000

**Required Information:**
```
ML_LOCATION: [USER MUST PROVIDE: same OR separate]

If separate:
ML_SERVER_IP: [USER MUST PROVIDE]
```

**Why Needed:** Backend must know how to reach ML server for room predictions

---

#### 4. PRODUCTION_PROTOCOL
**Question:** Will the backend use HTTP or HTTPS?

**Option A: HTTP (current configuration)**
- No SSL certificate needed
- Simpler setup
- Less secure (traffic not encrypted)
- **Current app configuration:** Allows cleartext (HTTP) traffic
- **No code changes needed**

**Option B: HTTPS**
- Requires SSL certificate
- More secure (encrypted traffic)
- Better for production
- **Code changes needed:**
  - Update `AndroidManifest.xml`: Set `usesCleartextTraffic="false"`
  - Configure SSL on backend server
  - Obtain SSL certificate (Let's Encrypt, commercial CA, etc.)

**Required Information:**
```
PRODUCTION_PROTOCOL: [USER MUST PROVIDE: HTTP OR HTTPS]

If HTTPS:
SSL_CERTIFICATE_SOURCE: [USER MUST PROVIDE]
```

**Why Needed:** 
- Determines app security configuration
- Affects server setup
- Affects backend URL format

---

#### 5. EMAIL_VERIFICATION_DECISION
**Question:** Will you enable email verification for user registration?

**Current State:** `EMAIL_VERIFICATION_ENABLED=false` (verification disabled)

**Option A: Keep Disabled (current)**
- Users can register and login immediately
- No email verification required
- Simpler user experience
- **No changes needed**
- `APP_BASE_URL` value irrelevant

**Option B: Enable Verification**
- Users must verify email before login
- More secure registration
- Requires working email service (Resend)
- **Requires updating `APP_BASE_URL` in `.env`:**
  - Current: `http://192.168.1.18:5000` (development)
  - Production: Must match `BACKEND_PRODUCTION_URL`
- **Requires updating `.env`:** `EMAIL_VERIFICATION_ENABLED=true`

**Required Information:**
```
EMAIL_VERIFICATION_ENABLED: [USER MUST PROVIDE: true OR false]

If true:
APP_BASE_URL: [USER MUST PROVIDE - same as BACKEND_PRODUCTION_URL]
```

**Why Needed:** 
- Affects user registration flow
- Determines if APP_BASE_URL must be updated
- Affects deployment complexity

**RECOMMENDATION:** Keep disabled initially (Option A), enable later if needed

---

#### 6. RELEASE_SIGNING_KEYSTORE
**Status:** DOES NOT EXIST

**Required:** Create Android release keystore for production APK signing

**Why Needed:**
- Google Play Store requires signed APKs
- Debug signing keys are insecure
- Production apps must use release keys
- Keystore must be backed up securely (if lost, cannot update app)

**CREATE KEYSTORE:**

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

# You will be prompted for:
# - Keystore password (choose strong password, save securely)
# - Key password (choose strong password, save securely)
# - Name, organization, city, state, country (fill in accurately)
```

**Windows Command:**
```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**AFTER CREATION:**

1. **Move keystore:**
```bash
mv upload-keystore.jks c:\flutter-project\assetguard\android\app\
```

2. **Create key.properties:**
```bash
# Copy template
cp c:\flutter-project\assetguard\android\key.properties.example c:\flutter-project\assetguard\android\key.properties

# Edit with your passwords
notepad c:\flutter-project\assetguard\android\key.properties
```

File contents:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=upload
storeFile=upload-keystore.jks
```

3. **CRITICAL SECURITY:**
- ⚠️ **BACKUP keystore file to secure location**
- ⚠️ **BACKUP passwords securely**
- ⚠️ **NEVER commit key.properties to git** (already in .gitignore)
- ⚠️ **If lost, cannot update app on Play Store**

**Required Information:**
```
KEYSTORE_CREATED: [USER MUST CONFIRM: YES/NO]
KEYSTORE_BACKED_UP: [USER MUST CONFIRM: YES/NO]
```

---

#### 7. PRODUCTION_SECRETS (Security Critical)

**Current State:** Development secrets in `.env` file

**⚠️ MUST ROTATE THESE SECRETS BEFORE PUBLIC DEPLOYMENT:**

```env
# Generate new production secrets:

# 1. JWT_SECRET (currently: development value)
# Generate new with:
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# 2. MONGODB_URI (secure credential management)
# Options:
#   A. Change MongoDB Atlas password
#   B. Create new MongoDB user with stronger password
#   C. Use separate production database cluster

# 3. RESEND_API_KEY (currently: development key)
# Options:
#   A. Keep if Resend account is production-ready
#   B. Create new Resend account for production
#   C. Rotate API key in Resend dashboard
```

**Required Actions:**
```
NEW_JWT_SECRET: [USER MUST GENERATE]
NEW_MONGODB_PASSWORD: [USER MUST SET]
RESEND_API_KEY_STATUS: [USER MUST CONFIRM: production-ready OR needs-rotation]
```

**Why Needed:** Development secrets should never be used in production

---

## D. FINAL DEPLOYMENT STEPS

### Prerequisites Check

Before proceeding, confirm ALL user inputs from Section C are provided:

- [ ] `BACKEND_LOCATION` specified
- [ ] `BACKEND_PRODUCTION_URL` specified
- [ ] `ML_LOCATION` specified (same or separate)
- [ ] `PRODUCTION_PROTOCOL` specified (HTTP or HTTPS)
- [ ] `EMAIL_VERIFICATION_DECISION` specified
- [ ] Release keystore created and backed up
- [ ] Production secrets generated
- [ ] Production server ready

---

### STEP 1: Configure Production Secrets

**On production server:**

```bash
# 1. Create production .env
cd /path/to/backend
cp .env.example .env

# 2. Edit with production values
nano .env
```

**Update these values:**
```env
# MongoDB (use NEW production credentials)
MONGODB_URI=mongodb+srv://ProductionUser:STRONG_NEW_PASSWORD@cluster.mongodb.net/?appName=AssetGuardCluster

# JWT (use NEW production secret)
JWT_SECRET=<64-character-hex-from-crypto-randomBytes-32>

# Server
PORT=5000

# Email service
RESEND_API_KEY=<production-or-rotated-key>
APP_BASE_URL=<matches BACKEND_PRODUCTION_URL if email enabled>
RESEND_FROM_EMAIL=noreply@yourdomain.com
EMAIL_VERIFICATION_ENABLED=false  # or true if enabling

# ML Server
ML_API_URL=http://localhost:8000  # or http://<ml-ip>:8000 if separate
```

**⚠️ NEVER commit production .env to source control**

---

### STEP 2: Deploy Backend Server

**Install dependencies:**
```bash
cd /path/to/backend
npm install --production
```

**Start with process manager (PM2):**
```bash
# Install PM2 globally
npm install -g pm2

# Start backend
pm2 start server.js --name assetguard-api

# Save PM2 process list
pm2 save

# Setup PM2 to start on system boot
pm2 startup
# Follow the command it displays

# Verify running
pm2 status
pm2 logs assetguard-api
```

**Test backend:**
```bash
# Health check
curl http://localhost:5000/api/health

# Expected: {"success":true,"message":"AssetGuard API is running"}
```

---

### STEP 3: Deploy ML V1 Server

**If co-located (Option A):**
```bash
# Ensure ML server is running on same machine
# Verify it's accessible on localhost:8000
curl http://localhost:8000/health

# Expected: {"status":"ok","model_loaded":true,"features":105,...}
```

**If separate server (Option B):**
```bash
# On ML server machine:
# 1. Start ML server on port 8000
# 2. Ensure firewall allows backend-ip → ml-server-ip:8000

# From backend server, test connectivity:
curl http://<ml-server-ip>:8000/health
```

---

### STEP 4: Update Android Configuration (If HTTPS)

**Only if `PRODUCTION_PROTOCOL=HTTPS`:**

```bash
# Edit AndroidManifest.xml
nano android/app/src/main/AndroidManifest.xml

# Change line:
# FROM: android:usesCleartextTraffic="true"
# TO:   android:usesCleartextTraffic="false"
```

**If using HTTP, no changes needed** (current configuration allows HTTP)

---

### STEP 5: Build Production APK

**Pre-build validation:**
```bash
cd c:\flutter-project\assetguard

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Analyze code (confirm no errors)
flutter analyze

# Expected: 5 info/warning issues (non-blocking)
```

**Build signed release APK:**
```bash
# Build with production URL
flutter build apk --release --dart-define=API_URL=<BACKEND_PRODUCTION_URL>

# Example:
# flutter build apk --release --dart-define=API_URL=http://203.45.67.89:5000
# flutter build apk --release --dart-define=API_URL=https://api.assetguard.io

# Output: build/app/outputs/flutter-apk/app-release.apk
# Expected size: ~50-60MB (smaller than debug build)
```

**Build app bundle (for Google Play Store):**
```bash
flutter build appbundle --release --dart-define=API_URL=<BACKEND_PRODUCTION_URL>

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

### STEP 6: Verify Build

**Check APK details:**
```powershell
# On Windows
cd c:\flutter-project\assetguard
$apk = Get-Item "build\app\outputs\flutter-apk\app-release.apk"
Write-Host "APK Size: $([math]::Round($apk.Length/1MB, 2)) MB"
Write-Host "Created: $($apk.LastWriteTime)"
Write-Host "Path: $($apk.FullName)"
```

**Expected:**
- Size: 50-60 MB (release is smaller than debug)
- Signed with: Release keystore (not debug keys)
- Package: io.assetguard.app

---

### STEP 7: Test Production APK

**Install on test device:**
```bash
# Connect Android device via USB
# Enable USB debugging on device

# Install release APK
adb install -r build\app\outputs\flutter-apk\app-release.apk

# Verify installation
adb shell pm list packages | findstr assetguard

# Expected: package:io.assetguard.app
```

**Run end-to-end test** (see STEP 8 below)

---

### STEP 8: End-to-End Production Test

#### Test Checklist

**PHONE A (Asset Owner - Alice):**

1. [ ] **Register Account**
   - Open AssetGuard app
   - Tap "Register"
   - Email: alice@production-test.com
   - Password: (test password)
   - Register successfully
   - If email verification enabled: Verify email
   - If email verification disabled: Login immediately

2. [ ] **Login**
   - Email: alice@production-test.com
   - Password: (test password)
   - Login successful

3. [ ] **Create Asset**
   - Tap "Add Asset"
   - Name: Test Laptop
   - Tracker ID: AG-001 (or actual tracker ID)
   - Category: Electronics
   - Description: Test asset
   - Save successfully

4. [ ] **Assign Tracker**
   - Asset created with tracker AG-001
   - Shows in "My Assets" list

5. [ ] **Mark Asset LOST**
   - Tap asset in list
   - Tap "Mark as Lost"
   - Confirm
   - Asset status: LOST (red indicator)

6. [ ] **Wait for Detection Notification**
   - Keep app open or in background
   - Phone B will detect tracker
   - Wait for notification to arrive

7. [ ] **Verify Notification Received**
   - Notification appears: "Asset Detected"
   - Message contains: "Your Test Laptop (AG-001) was detected near Room XXX"
   - Confidence percentage shown
   - Tap notification
   - Opens to asset details or notifications screen

8. [ ] **View Detection History**
   - Tap asset → "Track Asset"
   - Detection shown on map (if GPS)
   - Detection shown in list with room number
   - Room and confidence displayed

9. [ ] **Mark Asset RECOVERED**
   - Tap asset
   - Tap "Mark as Recovered"
   - Confirm
   - Asset status: RECOVERED (green indicator)

10. [ ] **Verify No More Notifications**
    - Phone B continues sensing
    - No new notifications arrive
    - Detection stopped for recovered asset

---

**PHONE B (Community Member - Bob):**

1. [ ] **Register/Login**
   - Open AssetGuard app
   - Register or login as bob@production-test.com
   - Different user from Phone A

2. [ ] **Enable Community Sensing**
   - Navigate to Settings or Community tab
   - Toggle "Community Sensing" ON
   - Grant permissions:
     - Location: Allow all the time
     - Bluetooth: Allow
     - Notifications: Allow (optional)
   - Foreground notification appears: "AssetGuard Community Sensing"

3. [ ] **Verify Automatic BLE Scanning**
   - Place Phone B within 10 meters of tracker
   - Wait 15-30 seconds
   - Check adb logs (optional):
     ```bash
     adb logcat | Select-String "Community|BLE"
     ```
   - Expected logs:
     - `[Community BLE] AssetGuard trackers detected: 1`
     - `[Community BLE] Processing tracker: AG-001`

4. [ ] **Verify Automatic Wi-Fi Scanning**
   - Community Sensing triggers Wi-Fi scan automatically
   - Check adb logs (optional):
     ```bash
     adb logcat | Select-String "WiFiScan|CommunityWiFi"
     ```
   - Expected logs:
     - `[CommunityWiFi] Wi-Fi scan success: XX NIE APs`
     - `[CommunityWiFi] Fingerprint: XX BSSIDs`

5. [ ] **Verify Detection Submitted**
   - Detection automatically sent to backend
   - Check adb logs (optional):
     - `[Community] ► SUBMITTING DETECTION TO BACKEND`
     - `[CommunityWiFi] ✓ Wi-Fi fingerprint INCLUDED in payload`

6. [ ] **Community Sensing Continues**
   - Notification remains visible
   - Scan count increments
   - Multiple detections may occur (debounced to 60 seconds)

---

**BACKEND VERIFICATION:**

Check backend logs:
```bash
pm2 logs assetguard-api --lines 100
```

**Expected log sequence:**
```
[Community] INCOMING DETECTION REQUEST
[Community]   trackerId  : AG-001
[CommunityWiFi] Wi-Fi fingerprint provided with XX BSSIDs
[CommunityWiFi] SENDING TO ML SERVER
[CommunityWiFi] ML HTTP STATUS: 200 OK
[CommunityWiFi] ✓ Predicted room: XXX
[CommunityWiFi] ✓ Confidence: 0.XX
[Community] Owner notification created
```

**Verify:**
- [ ] Detection received by backend
- [ ] Wi-Fi fingerprint included
- [ ] ML prediction called
- [ ] ML returned room + confidence
- [ ] No 422 errors
- [ ] No timeout errors
- [ ] Notification created for owner

---

**V1 ML SERVER VERIFICATION:**

If ML server has logs:
```bash
# Check ML server logs for prediction request
# Expected: POST /predict-room with 200 OK response
```

**Verify:**
- [ ] ML server received request
- [ ] Returned room prediction
- [ ] Returned confidence score
- [ ] Response time < 10 seconds
- [ ] 105 features model used

---

**MONGODB VERIFICATION:**

Check database collections:
```bash
# Use MongoDB Compass or mongo shell
# Connect to MongoDB Atlas

# Check collections:
use assetguard

# Assets
db.assets.find({trackerId: "AG-001"})
# Verify asset exists, status=LOST or RECOVERED

# Community Detections
db.communitydetections.find({trackerId: "AG-001"})
# Verify detection record created with room/confidence

# Notifications
db.notifications.find({trackerId: "AG-001"})
# Verify notification created for owner with room in message
```

**Verify:**
- [ ] Asset record exists
- [ ] Detection record created
- [ ] Detection has `predictedRoom` field
- [ ] Detection has `roomConfidence` field
- [ ] Notification record created
- [ ] Notification message includes room number

---

**NEGATIVE TEST - Recovered Asset:**

After marking asset as RECOVERED:

1. [ ] Phone B continues Community Sensing
2. [ ] Phone B detects tracker again
3. [ ] **Backend rejects detection** (asset not LOST)
4. [ ] **No notification sent to Phone A**
5. [ ] Check backend logs: "Detection ignored — asset AG-001 is RECOVERED"

---

### STEP 9: Deploy to Distribution Channel

**Option A: Direct APK Distribution**

```bash
# Share app-release.apk with users
# Users must enable "Install from unknown sources"
# Provide installation instructions
```

**Option B: Google Play Store (Recommended)**

1. **Create Google Play Console Account**
   - Go to: play.google.com/console
   - Pay one-time $25 registration fee
   - Complete developer profile

2. **Create New App**
   - App name: AssetGuard
   - Default language: English
   - App or game: App
   - Free or paid: Free (or Paid)

3. **Upload App Bundle**
   - Production → Create new release
   - Upload: `build/app/outputs/bundle/release/app-release.aab`
   - Release name: 1.0.0 (1)
   - Release notes: Initial release

4. **Complete Store Listing**
   - App details (name, description, category)
   - Graphics (icon, screenshots, feature graphic)
   - Categorization (app category, content rating)
   - Contact details (email, privacy policy)
   - Pricing & distribution (countries, age restrictions)

5. **Submit for Review**
   - Review and publish
   - Wait for Google review (1-7 days)
   - App goes live after approval

---

## E. FINAL CHECKLISTS

### Pre-Deployment Checklist

**Infrastructure:**
- [ ] Production server acquired/configured
- [ ] MongoDB Atlas accessible from server
- [ ] Firewall rules configured
- [ ] Domain name configured (if using domain)
- [ ] SSL certificate obtained (if using HTTPS)

**Secrets:**
- [ ] New JWT_SECRET generated
- [ ] New MongoDB password set
- [ ] Resend API key verified/rotated
- [ ] Production .env created (NOT committed)
- [ ] Keystore created and backed up

**Configuration:**
- [ ] Backend .env configured for production
- [ ] Backend NODE_ENV=production (optional)
- [ ] ML server location decided
- [ ] Email verification decision made
- [ ] HTTP vs HTTPS decided

**Code:**
- [ ] All code changes committed
- [ ] No hardcoded development values
- [ ] Flutter analyze passes
- [ ] Debug build successful
- [ ] Release keystore configured

---

### Deployment Checklist

**Backend:**
- [ ] Dependencies installed (`npm install --production`)
- [ ] Production .env in place
- [ ] Backend starts successfully
- [ ] `/api/health` responds 200 OK
- [ ] PM2 configured for auto-restart
- [ ] Logs are being written

**ML Server:**
- [ ] V1 server running on correct port
- [ ] `/health` endpoint responds
- [ ] Backend can reach ML server
- [ ] 105-feature model loaded
- [ ] Predictions return correctly

**Flutter App:**
- [ ] Built with production URL
- [ ] Signed with release keystore
- [ ] APK size reasonable (~50-60MB)
- [ ] Package name: io.assetguard.app
- [ ] Installation successful on test device

---

### Post-Deployment Monitoring

**First 24 Hours:**
- [ ] Monitor backend logs for errors
- [ ] Check MongoDB for data writes
- [ ] Verify user registrations work
- [ ] Verify detections arrive
- [ ] Verify ML predictions work
- [ ] Verify notifications deliver
- [ ] Check for crashes/ANRs

**First Week:**
- [ ] Collect user feedback
- [ ] Monitor detection success rate
- [ ] Monitor ML prediction accuracy
- [ ] Check for any error patterns
- [ ] Verify battery impact acceptable
- [ ] Verify network usage acceptable

---

## SUMMARY

### Deployment Readiness: WAITING FOR USER INPUT

**Code Status:** ✅ COMPLETE  
**Build Status:** ✅ DEBUG SUCCESSFUL  
**Test Status:** ✅ VALIDATED  
**Blocking Items:** 7 user decisions/inputs required

---

### Required User Actions

**MUST PROVIDE (Deployment Blockers):**

1. **BACKEND_PRODUCTION_URL** - Where Flutter app will connect
2. **ML_LOCATION** - Co-located or separate server
3. **PRODUCTION_PROTOCOL** - HTTP or HTTPS
4. **RELEASE_KEYSTORE** - Create and configure
5. **PRODUCTION_SECRETS** - Generate new JWT, rotate MongoDB password
6. **EMAIL_VERIFICATION_DECISION** - Enable or keep disabled
7. **BACKEND_LOCATION** - Where backend will be deployed

---

### Estimated Time to Complete Deployment

**After user inputs provided:**
- Configure production secrets: 30 minutes
- Deploy backend: 1 hour
- Deploy ML server: 30 minutes
- Build production APK: 15 minutes
- Test end-to-end: 1-2 hours
- **Total: 3-4 hours**

---

### No Further Code Changes Required

All necessary code changes have been completed. The application is production-ready pending infrastructure setup and user configuration decisions.

**V1 ML model is active, tested, and FROZEN.**  
**BLE, Wi-Fi, and Community Sensing are working and FROZEN.**  
**All functionality preserved during audit.**

---

## NEXT ACTION

**Provide the 7 required user inputs above, then proceed with STEP 1-9 in Section D.**

DO NOT PROCEED until all user inputs are confirmed.
