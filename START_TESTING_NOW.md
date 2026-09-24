# 🚀 START TESTING ASSETGUARD NOW

**Quick Start Guide - Get Testing in 5 Minutes**

---

## ⚡ QUICK STATUS CHECK

Run this command first:
```powershell
cd c:\flutter-project\assetguard
.\quick-test.ps1
```

This will check if everything is ready.

---

## 🔧 STEP 1: START BACKEND SERVER

**Open PowerShell Window #1** (keep it running):

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
- MongoDB error → Check internet connection
- Port error → Stop other services on port 5000

**KEEP THIS WINDOW OPEN!**

---

## 📱 STEP 2: INSTALL APP ON PHONES

### Option A: Via USB Cable (Requires ADB)

**Connect Phone A** (Asset Owner):
```powershell
# Check phone is connected
adb devices

# Install APK
adb install c:\flutter-project\assetguard\build\app\outputs\flutter-apk\app-debug.apk
```

**Connect Phone B** (Community Helper):
```powershell
# Install APK
adb install c:\flutter-project\assetguard\build\app\outputs\flutter-apk\app-debug.apk
```

### Option B: Transfer APK Manually

1. Copy APK file to phone storage
2. On phone, open Files app
3. Find `app-debug.apk`
4. Tap to install (enable "Install from Unknown Sources" if asked)

**APK Location**: `c:\flutter-project\assetguard\build\app\outputs\flutter-apk\app-debug.apk`

---

## 🎯 STEP 3: FIRST TEST - USER REGISTRATION

### Phone A (Asset Owner)

1. Open **AssetGuard** app
2. Tap **"Register"**
3. Fill form:
   - Name: `Test Owner`
   - Email: `owner@test.com`
   - Password: `Test123!`
4. Tap **"Register"**

**Expected**: ✅ Auto-login → Home screen with "Welcome Test Owner"

### Phone B (Community Helper)

1. Open **AssetGuard** app
2. Tap **"Register"**
3. Fill form:
   - Name: `Test Helper`
   - Email: `helper@test.com`
   - Password: `Test123!`
4. Tap **"Register"**

**Expected**: ✅ Auto-login → Home screen

---

## 🎯 STEP 4: CREATE ASSET (Phone A)

1. Tap **"Add Asset"** button
2. Fill form:
   - **Name**: `My Laptop`
   - **Category**: `Electronics`
   - **Description**: `Dell Inspiron 15`
   - **Tracker ID**: `AG-001` ⚠️ Important!
3. Tap **"Save"**

**Expected**: ✅ Asset appears in "My Assets" with green "ACTIVE" status

---

## 🎯 STEP 5: MARK AS LOST (Phone A)

1. Go to **"My Assets"**
2. Tap on **"My Laptop"** card
3. Tap **"Mark as Lost"** button
4. Confirm

**Expected**: ✅ Status changes to red "LOST"

**Check Dashboard**:
- Go to Home screen
- Should show: **Lost: 1**

---

## 🎯 STEP 6: ENABLE COMMUNITY SENSING (Phone B)

1. On **Phone B**, go to Home screen
2. Tap **"Enable Community Sensing"** button
3. **Grant ALL permissions when asked**:
   - ✅ Bluetooth
   - ✅ Location (Precise location)
   - ✅ Notifications
4. **Expected**: 
   - ✅ Button changes to "Disable Community Sensing"
   - ✅ Persistent notification appears: "AssetGuard Community Sensing"
   - ✅ Scanning starts in background

---

## 🎯 STEP 7: TEST DETECTION

### ⚠️ IMPORTANT: BLE Tracker Requirement

The app is configured to detect trackers with ID **"AG-001"**.

**You have 3 options**:

### Option 1: Real BLE Tracker (Best)
If you have a physical BLE tracker programmed with ID "AG-001":
1. Place tracker near Phone B
2. Wait 15-30 seconds
3. Check Phone A for notification

### Option 2: Simulate with BLE Beacon App
1. Install a BLE beacon app on a 3rd device
2. Configure it to broadcast name "AG-001"
3. Place near Phone B
4. Wait for detection

### Option 3: Temporary Test Mode (Modify Code)

**For testing without real tracker**, temporarily modify the filter:

1. Edit `lib/services/community_sensing_service.dart`
2. Find line ~380: `if (trackerId.startsWith('AG-'))`
3. Comment it out to detect any BLE device
4. Rebuild APK: `flutter build apk`
5. Reinstall on Phone B

**Detection Flow**:
1. Bring phones/tracker close together (< 2 meters)
2. Wait 15-30 seconds (BLE scan cycle)
3. **Phone A should receive notification**

---

## ✅ VERIFY DETECTION WORKED

### Phone A (Asset Owner)

1. Pull down notification shade
2. Should see: **"Your My Laptop (AG-001) was detected"**
3. Open app → Tap Notifications icon
4. Should see detection notification with:
   - Tracker ID: AG-001
   - GPS coordinates
   - Time
   - (Optional) Room prediction if on NIE Wi-Fi

### Backend Server Window

Check logs for:
```
POST /api/community/detections - Received detection for AG-001
Asset found: My Laptop, status: LOST
Notification created for owner
```

---

## 🎯 STEP 8: VIEW ON MAP (Phone A)

1. Go to **"My Assets"**
2. Tap **"My Laptop"**
3. Tap **"Track Asset"** button
4. **Expected**: Map opens with red marker at detection location
5. Tap marker → See detection details

---

## 🎯 STEP 9: MARK AS RECOVERED (Phone A)

1. In asset details, tap **"Mark as Recovered"**
2. Confirm
3. **Expected**: 
   - ✅ Status changes to orange "RECOVERED"
   - ✅ Dashboard shows Lost: 0

### Critical Test: Verify No More Notifications

1. Keep Community Sensing enabled on Phone B
2. Bring phones close again
3. **Expected**: ❌ NO new notification (asset is recovered)

**Check backend logs**:
```
Asset AG-001 not currently lost, skipping detection
```

This proves the status check works correctly!

---

## 🎯 STEP 10: WI-FI ROOM PREDICTION (Optional)

**Only works if**:
- Phone B is on **NIE-STUDENTS** or **NIE-STAFF** Wi-Fi
- ML Server at `http://10.135.90.221:8000` is running

**To test**:
1. Mark asset as LOST again
2. Ensure Phone B is on NIE Wi-Fi
3. Enable Community Sensing
4. Trigger detection
5. **Expected**: Notification includes "Room 310 (38%)" or similar

---

## 📊 TESTING SUMMARY

After completing all steps, you should have verified:

✅ **User Management**
- [x] Registration works
- [x] Login works
- [x] Two separate users created

✅ **Asset Management**
- [x] Create asset
- [x] View asset details
- [x] Edit asset

✅ **Asset Lifecycle**
- [x] Mark as LOST
- [x] Mark as RECOVERED
- [x] Dashboard updates correctly

✅ **Community Detection**
- [x] Community Sensing starts
- [x] Background scanning works
- [x] BLE detection happens
- [x] Notification sent to owner
- [x] Status check prevents RECOVERED spam

✅ **Notifications**
- [x] Notification received
- [x] Shows tracker ID
- [x] Shows location/time
- [x] Mark as read works

✅ **Track Asset**
- [x] Map displays
- [x] Markers show detection locations
- [x] Popup shows details

---

## ❌ TROUBLESHOOTING

### "Backend connection failed"
- ✅ Check backend server is running (PowerShell window)
- ✅ Check IP address in `lib/utils/api_config.dart`
- ✅ Phone and laptop on same network

### "Registration failed"
- ✅ Check backend logs for errors
- ✅ Try different email
- ✅ Check MongoDB connection

### "Community Sensing won't start"
- ✅ Grant ALL permissions
- ✅ Check Android version (requires 10+)
- ✅ Restart app

### "No detection happening"
- ✅ Asset must be LOST on Phone A
- ✅ Community Sensing enabled on Phone B
- ✅ Check if using real AG-001 tracker
- ✅ Or modify filter as shown above
- ✅ Check backend logs

### "Notification not received"
- ✅ Check notification permissions on Phone A
- ✅ Pull down notification shade
- ✅ Check Notifications screen in app
- ✅ Check backend logs for "Notification created"

### "No room prediction"
- ✅ Check Phone B is on NIE Wi-Fi
- ✅ Check ML server running: `curl http://10.135.90.221:8000`
- ✅ System still works without it (shows GPS only)

---

## 📱 CURRENT CONFIGURATION

**Backend Server IP**: Port 5000 (localhost on your laptop)  
**Flutter App Backend**: `http://10.128.192.221:5000` (in api_config.dart)  
**ML Server**: `http://10.135.90.221:8000`  
**MongoDB**: Cloud Atlas (configured in .env)  
**Email Verification**: DISABLED (testing mode)  

**⚠️ IP Address Note**: 
- Flutter app points to `10.128.192.221:5000`
- Make sure your laptop has this IP, or update `lib/utils/api_config.dart`
- Check with: `ipconfig` in PowerShell

---

## 🎓 FOR PRESENTATION DEMO

**4-Minute Demo Flow**:

1. **(30s)** Show Phone A - Login, show asset, mark as LOST
2. **(30s)** Show Phone B - Enable Community Sensing
3. **(90s)** Bring phones close, show detection happening
4. **(60s)** Show Phone A - Notification received, Track Asset map
5. **(30s)** Mark as Recovered

**Practice this 2-3 times before presenting!**

---

## 📚 DOCUMENTATION

- **Complete Guide**: `COMPLETE_PROJECT_DOCUMENTATION_FOR_PRESENTATION.md`
- **Quick Reference**: `PRESENTATION_GUIDE.md`
- **Detailed Testing**: `END_TO_END_TESTING_GUIDE.md`
- **This Guide**: `START_TESTING_NOW.md` (you are here)

---

## 🚀 YOU'RE READY!

Follow the steps above in order. If you encounter issues, check the Troubleshooting section.

**Start with Step 1: Start Backend Server** ☝️

Good luck with your testing! 🎉
