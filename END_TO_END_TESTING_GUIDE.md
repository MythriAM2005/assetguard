# ASSETGUARD - END-TO-END TESTING GUIDE

**Last Updated**: Current Session  
**Purpose**: Complete step-by-step guide to test all AssetGuard features from setup to community detection

---

## TABLE OF CONTENTS

1. [Prerequisites](#1-prerequisites)
2. [Environment Setup](#2-environment-setup)
3. [Backend Setup & Testing](#3-backend-setup--testing)
4. [ML Server Verification](#4-ml-server-verification)
5. [Flutter App Installation](#5-flutter-app-installation)
6. [Test Scenario 1: User Registration & Login](#test-scenario-1-user-registration--login)
7. [Test Scenario 2: Asset Management](#test-scenario-2-asset-management)
8. [Test Scenario 3: Mark Asset as Lost](#test-scenario-3-mark-asset-as-lost)
9. [Test Scenario 4: Community Detection (BLE)](#test-scenario-4-community-detection-ble)
10. [Test Scenario 5: Wi-Fi Room Prediction](#test-scenario-5-wifi-room-prediction)
11. [Test Scenario 6: Notifications](#test-scenario-6-notifications)
12. [Test Scenario 7: Track Asset Map](#test-scenario-7-track-asset-map)
13. [Test Scenario 8: Mark as Recovered](#test-scenario-8-mark-as-recovered)
14. [Troubleshooting](#troubleshooting)
15. [Testing Checklist](#testing-checklist)

---

## 1. PREREQUISITES

### Hardware Required
- ✅ **2 Android phones** (Phone A = Asset Owner, Phone B = Community Helper)
- ✅ **Development Laptop** (running backend server)
- ✅ **BLE Tracker** (optional - can simulate with second phone's MAC)
- ✅ **Wi-Fi Network** (NIE-STUDENTS or NIE-STAFF for room prediction)

### Software Required
- ✅ **Node.js** (v14+) installed
- ✅ **MongoDB** (Atlas cloud connection configured)
- ✅ **Flutter SDK** (for building APK)
- ✅ **Python ML Server** (running at http://10.135.90.221:8000)
- ✅ **ADB** (Android Debug Bridge) for installing APK

### Network Configuration
- ✅ All devices on same LAN (or ML server accessible)
- ✅ Backend server IP: **10.135.90.221:5000** (configured in api_config.dart)
- ✅ ML server IP: **10.135.90.221:8000** (configured in backend .env)

---

## 2. ENVIRONMENT SETUP

### Check Current Configuration

**Backend URL (Flutter → Backend)**:
```
File: lib/utils/api_config.dart
Current: http://10.135.90.221:5000
```

**ML Server URL (Backend → ML)**:
```
File: backend/.env
Current: ML_API_URL=http://10.135.90.221:8000
```

**MongoDB Connection**:
```
File: backend/.env
Current: mongodb+srv://AssetDatabase:...@assetguardcluster.5y4lguf.mongodb.net/
```

**Email Verification**:
```
File: backend/.env
Current: EMAIL_VERIFICATION_ENABLED=false (TESTING MODE - NO EMAIL REQUIRED)
```

### Verify IP Addresses

If testing on different network, update IPs:

1. **Find your laptop's IP**:
   ```powershell
   ipconfig
   # Look for "IPv4 Address" under your Wi-Fi adapter
   # Example: 192.168.1.42
   ```

2. **Update Flutter API config** (if needed):
   ```
   File: lib/utils/api_config.dart
   Change: baseUrl = 'http://YOUR_LAPTOP_IP:5000'
   ```

3. **Update Backend ML URL** (if needed):
   ```
   File: backend/.env
   Change: ML_API_URL=http://YOUR_ML_SERVER_IP:8000
   ```

---

## 3. BACKEND SETUP & TESTING

### Step 1: Install Dependencies

```powershell
cd c:\flutter-project\assetguard\backend
npm install
```

### Step 2: Start Backend Server

```powershell
cd c:\flutter-project\assetguard\backend
node server.js
```

**Expected Output**:
```
✅ MongoDB Connected: assetguardcluster.5y4lguf.mongodb.net
✅ Server running on port 5000
```

**If you see errors**:
- MongoDB connection failed → Check MONGODB_URI in .env
- Port 5000 already in use → Stop other processes or change PORT in .env

### Step 3: Test Backend Health

Open new PowerShell window:

```powershell
# Test 1: Server is running
curl http://localhost:5000

# Test 2: MongoDB connection (should return empty array or assets)
curl http://localhost:5000/api/assets

# Test 3: Register endpoint exists
curl http://localhost:5000/api/auth/register
```

**Keep backend server running throughout testing!**

---

## 4. ML SERVER VERIFICATION

### Step 1: Verify ML Server is Running

```powershell
curl http://10.135.90.221:8000
```

**Expected**: JSON response with status or API info

### Step 2: Test Room Prediction Endpoint

```powershell
curl -X POST http://10.135.90.221:8000/predict-room `
  -H "Content-Type: application/json" `
  -d '{
    "fingerprint": {
      "00:11:22:33:44:55": -45,
      "AA:BB:CC:DD:EE:FF": -67
    }
  }'
```

**Expected Response**:
```json
{
  "room": "310",
  "confidence": 0.376667,
  "top_predictions": [...]
}
```

**If ML server is not accessible**:
- System will work WITHOUT room prediction
- Notifications will show GPS location only
- No functional impact, just missing room feature

---

## 5. FLUTTER APP INSTALLATION

### Option A: Use Existing APK

```powershell
# Check if APK exists
ls c:\flutter-project\assetguard\build\app\outputs\flutter-apk\app-debug.apk

# Install on Phone A
adb -s PHONE_A_SERIAL install c:\flutter-project\assetguard\build\app\outputs\flutter-apk\app-debug.apk

# Install on Phone B
adb -s PHONE_B_SERIAL install c:\flutter-project\assetguard\build\app\outputs\flutter-apk\app-debug.apk
```

### Option B: Build Fresh APK

```powershell
cd c:\flutter-project\assetguard

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --debug

# APK will be at: build/app/outputs/flutter-apk/app-debug.apk
```

### Verify Installation

- Open AssetGuard app on both phones
- Should see splash screen → login screen
- No crashes on startup

---

## TEST SCENARIO 1: USER REGISTRATION & LOGIN

### Phone A (Asset Owner)

1. **Open AssetGuard app**
2. **Tap "Register"**
3. **Fill registration form**:
   - Name: `Test Owner`
   - Email: `owner@test.com`
   - Password: `Test123!`
4. **Tap "Register"**
5. **Expected**: 
   - ✅ Success message
   - ✅ Automatic login (EMAIL_VERIFICATION_ENABLED=false)
   - ✅ Redirect to Home screen

### Phone B (Community Helper)

1. **Open AssetGuard app**
2. **Tap "Register"**
3. **Fill registration form**:
   - Name: `Test Helper`
   - Email: `helper@test.com`
   - Password: `Test123!`
4. **Tap "Register"**
5. **Expected**:
   - ✅ Success message
   - ✅ Automatic login
   - ✅ Redirect to Home screen

### Verification

**Check backend logs**:
```
POST /api/auth/register 201 - User registered
POST /api/auth/login 200 - Login successful
```

**Check MongoDB**:
```powershell
# If you have MongoDB Compass, connect and check:
# Database: assetguard_db
# Collection: users
# Should see 2 users: owner@test.com, helper@test.com
```

### Test Login/Logout

1. **Tap profile icon** (bottom right)
2. **Tap "Logout"**
3. **Login again**:
   - Email: `owner@test.com`
   - Password: `Test123!`
4. **Expected**: ✅ Successful login to home screen

---

## TEST SCENARIO 2: ASSET MANAGEMENT

### Phone A (Asset Owner)

#### Create Asset

1. **From Home screen, tap "Add Asset"** (or go to My Assets → + button)
2. **Fill asset form**:
   - Name: `Laptop`
   - Category: `Electronics`
   - Description: `Dell Inspiron`
   - Tracker ID: `AG-001`
3. **Tap "Save"**
4. **Expected**:
   - ✅ Success message
   - ✅ Asset appears in "My Assets" list
   - ✅ Status shows "ACTIVE" (green chip)

#### View Asset Details

1. **Tap on "Laptop" asset card**
2. **Expected**: Asset details screen showing:
   - Name, category, description
   - Tracker ID: AG-001
   - Status: ACTIVE
   - Buttons: Edit, Delete, Mark as Lost, Track Asset

#### Edit Asset

1. **Tap "Edit" button**
2. **Change description** to `Dell Inspiron 15`
3. **Tap "Save"**
4. **Expected**: ✅ Updated description shown

#### Dashboard Stats

1. **Go to Home screen**
2. **Expected**:
   - Total Assets: **1**
   - Lost: **0**
   - Tracking: **0**

### Phone B (Optional - Create Asset)

You can create a dummy asset on Phone B too, or leave it without assets.

---

## TEST SCENARIO 3: MARK ASSET AS LOST

### Phone A (Asset Owner)

1. **Go to My Assets**
2. **Tap "Laptop" asset**
3. **Tap "Mark as Lost"**
4. **Confirm the action**
5. **Expected**:
   - ✅ Status changes to "LOST" (red chip)
   - ✅ "Mark as Lost" button disappears
   - ✅ "Mark as Recovered" button appears
   - ✅ Success message shown

#### Verify Dashboard Update

1. **Go to Home screen**
2. **Expected**:
   - Total Assets: **1**
   - Lost: **1** ← Changed
   - Tracking: **0** (no detections yet)

---

## TEST SCENARIO 4: COMMUNITY DETECTION (BLE)

### Phone B (Community Helper)

#### Enable Community Sensing

1. **Go to Home screen**
2. **Tap "Enable Community Sensing" button**
3. **Grant permissions if prompted**:
   - ✅ Bluetooth
   - ✅ Location (Fine/Coarse)
   - ✅ Notifications
4. **Expected**:
   - ✅ Persistent notification appears: "AssetGuard Community Sensing - Scanning for lost assets"
   - ✅ Button changes to "Disable Community Sensing"
   - ✅ Background scanning starts

#### Monitor Scanning Logs (Optional)

If you have ADB connected:

```powershell
adb -s PHONE_B_SERIAL logcat | Select-String "AssetGuard|BLE|Community"
```

**Expected log patterns**:
```
[AssetGuard] Starting BLE scan...
[AssetGuard] BLE scan completed. Found X devices
[AssetGuard] Starting Wi-Fi scan...
[AssetGuard] Wi-Fi scan success: XX NIE APs found
[AssetGuard] Fingerprint prepared (XX BSSIDs)
[AssetGuard] Wi-Fi fingerprint cached
```

### Phone A & B Together

#### Simulate Detection

**If using real BLE tracker (AG-001)**:
1. Place tracker near Phone B
2. Wait 15-30 seconds
3. Check Phone A for notification

**If simulating with BLE device**:
1. Bring phones close together (< 2 meters)
2. Wait for BLE scan cycle (every 15 seconds)
3. Phone B should detect any nearby BLE devices

**IMPORTANT**: The app filters for tracker IDs starting with "AG-". If you don't have a real AG-001 tracker, you need to:

**Option 1: Modify filter temporarily** (for testing):
```dart
// In lib/services/ble_service.dart
// Comment out the AG- filter to detect any BLE device
```

**Option 2: Use a BLE beacon app**:
- Install a BLE beacon app on a third device
- Configure it to broadcast with name "AG-001"

#### Expected Detection Flow

**Phone B (Detector)**:
1. BLE scan detects AG-001 tracker
2. RSSI captured (e.g., -65 dBm)
3. Wi-Fi fingerprint retrieved from cache
4. Detection reported to backend with:
   - Tracker ID: AG-001
   - RSSI: -65
   - GPS location
   - Wi-Fi fingerprint (if available)

**Backend**:
1. Receives detection POST /api/community/detections
2. Validates tracker ID → finds Asset
3. Checks asset status → must be "LOST"
4. Sends Wi-Fi fingerprint to ML server
5. Receives room prediction (e.g., Room 310, 38% confidence)
6. Creates notification for asset owner

**Phone A (Owner)**:
1. Receives notification (app may need to be open or in background)
2. Notification shows:
   - "Your Laptop (AG-001) was detected"
   - "Near Room 310 (38% confidence)" ← If Wi-Fi worked
   - Or "At GPS coordinates" ← If no Wi-Fi
3. Badge shows unread notification count

---

## TEST SCENARIO 5: WIFI ROOM PREDICTION

This tests if ML integration is working.

### Prerequisites

- ✅ Phone B is on NIE-STUDENTS or NIE-STAFF Wi-Fi
- ✅ ML server at 10.135.90.221:8000 is running
- ✅ Community Sensing enabled on Phone B

### Verify Wi-Fi Scanning

**Check Phone B logs**:
```
[AssetGuard] Wi-Fi scan success: 74 NIE APs found
[AssetGuard] Fingerprint: 74 BSSIDs
[AssetGuard] Fingerprint prepared — sending to main isolate for upload
```

### Verify ML Prediction

**Check backend logs** (when detection happens):
```
POST /api/community/detections - Received detection for AG-001
Calling ML API: http://10.135.90.221:8000/predict-room
ML Response: {"room":"310","confidence":0.376667}
Notification created with room: 310
```

### Expected Notification on Phone A

```
🚨 Asset Detected
Your Laptop (AG-001) was detected near Room 310 (38% confidence)

Details:
📍 Tracker: AG-001
🚪 Room: 310 (38%)
📶 RSSI: -65 dBm
📍 GPS: 12.9716, 77.5946
⏰ Time: 2026-08-28 14:35:22
```

### If Room Prediction Missing

Check:
1. ❌ Wi-Fi scan failed on Phone B
2. ❌ ML server not responding
3. ❌ Wi-Fi fingerprint not cached properly
4. ❌ Backend ML integration error

**Graceful Degradation**: System works WITHOUT room prediction, just shows GPS.

---

## TEST SCENARIO 6: NOTIFICATIONS

### Phone A (Asset Owner)

#### View Notifications

1. **Tap Notifications icon** (bell icon in navigation)
2. **Expected**: List of notifications showing:
   - Asset detection notifications
   - Each shows: Title, message, timestamp
   - Unread notifications have blue dot
   - Info chips: Tracker ID, Room (if predicted), RSSI, GPS, Time

#### Notification Details

Each notification card should show:
- **Top**: Title and timestamp
- **Body**: Message text
- **Chips**: 
  - 📍 Tracker: AG-001
  - 🚪 Room: 310 (38%) ← Blue background
  - 📶 RSSI: -65 dBm
  - 📍 GPS: 12.97, 77.59
  - ⏰ Time: ...

#### Mark as Read

1. **Tap on a notification card**
2. **Expected**: Blue dot disappears (marked as read)

#### Verify Unread Count

1. **Go to Home screen**
2. **Check notifications icon badge**
3. **Expected**: Shows count of unread notifications

---

## TEST SCENARIO 7: TRACK ASSET MAP

### Phone A (Asset Owner)

1. **Go to My Assets**
2. **Tap "Laptop" asset**
3. **Tap "Track Asset" button**
4. **Expected**: Map screen opens showing:
   - OpenStreetMap base layer
   - Red markers at each detection location
   - Tap marker → Popup shows:
     - Detection timestamp
     - RSSI
     - Predicted room (if available)
     - Room confidence

### Map Features

- **Zoom**: Pinch or use +/- buttons
- **Pan**: Drag to move map
- **Markers**: Show detection locations
- **Popup**: Tap marker for details

### Multiple Detections

To test multiple markers:
1. Move Phone B to different location
2. Wait for new detection
3. Refresh Track Asset map
4. Should see multiple markers

---

## TEST SCENARIO 8: MARK AS RECOVERED

### Phone A (Asset Owner)

1. **Go to My Assets**
2. **Tap "Laptop" asset** (should be LOST status)
3. **Tap "Mark as Recovered"**
4. **Confirm the action**
5. **Expected**:
   - ✅ Status changes to "RECOVERED" (orange chip)
   - ✅ "Mark as Recovered" button disappears
   - ✅ "Mark as Lost" button reappears
   - ✅ Success message shown

#### Verify No More Detections

**CRITICAL TEST**: After marking as recovered, Phone B should NOT trigger new notifications for this asset.

1. **Keep Community Sensing enabled on Phone B**
2. **Bring phones close again**
3. **Expected**:
   - ❌ NO new notification on Phone A
   - Backend logs: "Asset AG-001 not currently lost, skipping detection"

This tests the **status check** at line ~141 in `backend/src/controllers/communityController.js`.

#### Verify Dashboard Update

1. **Go to Home screen**
2. **Expected**:
   - Total Assets: **1**
   - Lost: **0** ← Changed back
   - Tracking: **0**

---

## TROUBLESHOOTING

### Backend Issues

**Problem**: Backend won't start
- ❌ MongoDB connection failed → Check MONGODB_URI in .env
- ❌ Port already in use → Change PORT or kill process
- ❌ Missing dependencies → Run `npm install`

**Problem**: Assets not saving
- ❌ Check backend logs for errors
- ❌ Verify MongoDB connection in Compass
- ❌ Check JWT token in Flutter (logout/login)

### Flutter App Issues

**Problem**: App crashes on startup
- ❌ Check backend URL in api_config.dart
- ❌ Rebuild APK: `flutter clean && flutter build apk`
- ❌ Check ADB logs: `adb logcat`

**Problem**: Login fails
- ❌ Check backend is running
- ❌ Check network connectivity
- ❌ Verify credentials match registered user

**Problem**: Community Sensing won't start
- ❌ Grant all permissions (Bluetooth, Location, Notifications)
- ❌ Check Android version (requires Android 10+)
- ❌ Restart app

### Detection Issues

**Problem**: No detections happening
- ❌ Asset must be marked LOST on Phone A
- ❌ Community Sensing enabled on Phone B
- ❌ Phones within 2-10 meters (BLE range)
- ❌ Check if using real AG-001 tracker (or modify filter)
- ❌ Check backend logs for "Asset not currently lost"

**Problem**: Detection but no notification
- ❌ Check backend logs for errors
- ❌ Check Phone A notification permissions
- ❌ Pull down notification shade manually
- ❌ Check notifications screen in app

### Wi-Fi/ML Issues

**Problem**: No room prediction in notifications
- ❌ Check ML server: `curl http://10.135.90.221:8000`
- ❌ Check Phone B is on NIE Wi-Fi
- ❌ Check backend logs: "ML Response: ..."
- ✅ System still works, just missing room feature

**Problem**: Wi-Fi scan failing
- ❌ Grant Location permission (required for Wi-Fi scan)
- ❌ Enable Location services on phone
- ❌ Check if on NIE-STUDENTS or NIE-STAFF network

### Debounce Issues

**Problem**: Too many notifications
- ✅ Debounce is 60 seconds (by design)
- ✅ Should only get 1 notification per minute per asset

**Problem**: Detection delayed
- ✅ BLE scans every 15 seconds
- ✅ May take 15-30 seconds to detect
- ✅ Normal behavior

---

## TESTING CHECKLIST

### Pre-Test Setup
- [ ] Backend running (port 5000)
- [ ] MongoDB connected
- [ ] ML server accessible (port 8000)
- [ ] APK installed on both phones
- [ ] Both phones on same network (or backend accessible)

### User Management
- [ ] Register Phone A (owner@test.com)
- [ ] Register Phone B (helper@test.com)
- [ ] Login successful on both
- [ ] Logout/Login works

### Asset Management
- [ ] Create asset (AG-001) on Phone A
- [ ] Asset shows in My Assets
- [ ] Edit asset works
- [ ] Asset details screen shows correctly

### Asset Lifecycle
- [ ] Mark asset as LOST
- [ ] Status changes to LOST (red)
- [ ] Dashboard shows Lost: 1
- [ ] Mark as RECOVERED later
- [ ] Status changes to RECOVERED (orange)
- [ ] Dashboard updates correctly

### Community Detection
- [ ] Enable Community Sensing on Phone B
- [ ] Persistent notification appears
- [ ] Background scanning starts
- [ ] BLE scan logs visible (optional)
- [ ] Wi-Fi scan logs visible (optional)

### Detection Flow
- [ ] Phone B detects AG-001 tracker
- [ ] Backend receives detection
- [ ] Backend validates asset is LOST
- [ ] Phone A receives notification
- [ ] Notification shows tracker ID
- [ ] Notification includes detection time

### Wi-Fi/ML Integration
- [ ] Phone B scans Wi-Fi (NIE APs)
- [ ] Wi-Fi fingerprint cached
- [ ] ML server receives request
- [ ] ML server returns room prediction
- [ ] Notification includes room + confidence
- [ ] Room chip shows blue styling

### Notifications
- [ ] Notification appears on Phone A
- [ ] Notification list shows all detections
- [ ] Unread indicator (blue dot) works
- [ ] Mark as read works
- [ ] Unread count badge correct

### Track Asset
- [ ] Track Asset map opens
- [ ] Markers show at detection locations
- [ ] Tap marker shows popup
- [ ] Popup includes room (if predicted)
- [ ] Multiple detections show multiple markers

### Recovery Flow
- [ ] Mark asset as RECOVERED on Phone A
- [ ] Status changes correctly
- [ ] New detections DO NOT create notifications
- [ ] Backend logs "not currently lost"
- [ ] Dashboard updates (Lost: 0)

### Edge Cases
- [ ] Detection with no Wi-Fi (shows GPS only)
- [ ] ML server down (graceful degradation)
- [ ] Multiple assets detected
- [ ] Debounce prevents spam (60s)
- [ ] Community Sensing survives app background
- [ ] Community Sensing stops when disabled

---

## SUCCESS CRITERIA

✅ **Complete End-to-End Test Passed** if:

1. ✅ User can register and login
2. ✅ Asset can be created with tracker ID
3. ✅ Asset can be marked LOST
4. ✅ Phone B Community Sensing starts successfully
5. ✅ Phone B detects AG-001 when nearby
6. ✅ Phone A receives notification
7. ✅ Notification includes tracker ID and location
8. ✅ (Bonus) Notification includes predicted room from ML
9. ✅ Track Asset map shows detection marker
10. ✅ Asset can be marked RECOVERED
11. ✅ After recovery, no new notifications triggered

---

## PERFORMANCE BENCHMARKS

### Expected Timings

- Registration/Login: < 2 seconds
- Asset creation: < 1 second
- BLE scan cycle: 15 seconds interval, 8 seconds duration
- Wi-Fi scan cycle: 15 seconds interval
- Detection → Notification: 2-5 seconds
- ML prediction: < 1 second
- Map loading: 2-3 seconds

### Battery Impact

- Community Sensing active: ~10-15% per 8 hours
- Idle app: < 1% per hour
- Background scanning: Acceptable for community benefit

---

## NEXT STEPS

After successful testing:

1. **Document Issues**: Note any bugs found
2. **Performance Tuning**: Adjust scan intervals if needed
3. **Production Deployment**: 
   - Enable EMAIL_VERIFICATION_ENABLED=true
   - Set up proper backend hosting
   - Configure production MongoDB
   - Set up Firebase Cloud Messaging for push notifications
4. **Scale Testing**: Test with more users and assets
5. **Security Audit**: Review before public release

---

## DEMO PREPARATION

For presentation/viva demo (4 minutes):

**Minute 1**: 
- Show login
- Show asset creation
- Mark as LOST

**Minute 2**:
- Enable Community Sensing on second phone
- Show persistent notification

**Minute 3**:
- Bring phones close
- Show detection happening (logs optional)
- Show notification received

**Minute 4**:
- Show notification details (with room)
- Show Track Asset map
- Mark as Recovered

**Practice this flow 2-3 times before actual presentation!**

---

**GOOD LUCK WITH TESTING! 🧪**

If you encounter issues, check the Troubleshooting section or review the backend logs for specific error messages.
