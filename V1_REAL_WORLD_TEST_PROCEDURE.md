# V1 ML MODEL - REAL-WORLD TEST PROCEDURE

## TEST STATUS: READY TO EXECUTE

**Date:** 2026-08-28  
**V1 Model:** `assetguard_live_room_model.pkl`  
**Features:** 105 BSSIDs  
**Backend:** Running on `http://10.151.32.221:5000`  
**ML Server:** Running on `http://localhost:8000`

---

## PRE-TEST VERIFICATION ✅

### Backend Status
```
✅ Backend running on port 5000
✅ Health check: http://localhost:5000/api/health → 200 OK
✅ ML_API_URL configured: http://localhost:8000
```

### ML Server Status
```
✅ ML Server running on port 8000
✅ Health check: http://localhost:8000/health → 200 OK
✅ Model loaded: assetguard_live_room_model.pkl
✅ Features: 105
✅ Model status: Loaded and ready
```

---

## TEST SETUP

### Phone A (Asset Owner)
- **User:** alice@test.com
- **Role:** Asset owner
- **Asset:** Laptop tracker (AG-001 or similar)
- **Status:** Asset marked as **LOST**
- **App State:** Logged in, notifications enabled

### Phone B (Community Member)
- **User:** bob@test.com
- **Role:** Community detector
- **App State:** Logged in, Community Sensing **ENABLED**
- **Permissions:** Location, Bluetooth, Notifications all granted

### BLE Tracker
- **Tracker ID:** AG-001 (or your actual tracker)
- **Owner:** Phone A (alice@test.com)
- **Status:** LOST (must be marked LOST for community detection)

---

## MONITORING COMMANDS

### Terminal 1: Backend Logs (Real-time)
```powershell
# Run this in a separate PowerShell window
cd c:\flutter-project\assetguard\backend
node server.js

# Watch for these log patterns:
# [Community] INCOMING DETECTION REQUEST
# [CommunityWiFi] Wi-Fi fingerprint provided with X BSSIDs
# [CommunityWiFi] SENDING TO ML SERVER
# [CommunityWiFi] ML HTTP STATUS: 200 OK
# [CommunityWiFi] ML RESPONSE BODY: {...}
# [CommunityWiFi] ✓ Predicted room: XXX
# [Community] Owner notification created
```

### Terminal 2: Phone B Logs (Flutter/ADB)
```powershell
# Run this in a separate PowerShell window to monitor Phone B
adb logcat | Select-String "Community|WiFiScan"

# Watch for these log patterns:
# [Community BLE] AssetGuard trackers detected: X
# [Community BLE] Processing tracker: AG-001
# [CommunityWiFi] Wi-Fi scan success: X NIE APs found
# [CommunityWiFi] Fingerprint: X BSSIDs
# [CommunityWiFi] FINGERPRINT PAYLOAD VALIDATION
# [Community] ► SUBMITTING DETECTION TO BACKEND
# [CommunityWiFi] ✓ Predicted room: XXX
```

### Terminal 3: Phone A Logs (Flutter/ADB)
```powershell
# Optional: Monitor Phone A for notification receipt
adb -s <phone-a-serial> logcat | Select-String "Notification"
```

---

## TEST PROCEDURE

### Step 1: Start Monitoring
1. Open 3 PowerShell windows
2. Start backend monitoring (Terminal 1)
3. Start Phone B ADB logging (Terminal 2)
4. Start Phone A ADB logging (Terminal 3)

### Step 2: Verify Asset Status
1. On **Phone A**, open AssetGuard app
2. Navigate to "My Assets"
3. Find the tracker (e.g., "Laptop")
4. Verify status shows **LOST** (red indicator)
5. If not LOST, tap the asset → Mark as Lost

### Step 3: Enable Community Sensing on Phone B
1. On **Phone B**, open AssetGuard app
2. Navigate to Settings or Community tab
3. Enable "Community Sensing"
4. Verify notification appears: "AssetGuard Community Sensing - Community sensing active"

### Step 4: Position Devices
1. Place **Phone A** away (does not need to be near tracker)
2. Place **Phone B** within BLE range of the tracker (~10 meters)
3. **Record the ACTUAL PHYSICAL ROOM** where Phone B is located: ____________

### Step 5: Wait for Automatic Detection
- Community Sensing scans every **15 seconds**
- BLE scan: 8 seconds
- Wi-Fi scan: happens automatically
- **Expected time to first detection:** 15-30 seconds

### Step 6: Monitor Backend Logs
Watch Terminal 1 for this sequence:
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

### Step 7: Check Phone A Notification
1. On **Phone A**, pull down notification shade
2. Look for notification: "Asset Detected"
3. Message should read: "Your Laptop (AG-001) was detected near Room XXX. (XX% confidence)"

### Step 8: Record Results
Use the TEST RESULTS TEMPLATE below

---

## TEST RESULTS TEMPLATE

Copy this section and fill in actual values:

```
═══════════════════════════════════════════════════════════
V1 ML MODEL - REAL-WORLD TEST REPORT
═══════════════════════════════════════════════════════════

Test Date/Time: _______________
Test Duration: _____ minutes
Physical Location: Room _____ (actual room where Phone B was placed)

─── DETECTION #1 ───

Wi-Fi Fingerprint:
  ✓ BSSIDs collected: _____ 
  ✓ BSSIDs matched to V1's 105 features: _____ 
  ✓ BSSIDs outside V1 features: _____ 
  ✓ RSSI range: _____ to _____ dBm
  ✓ Any out-of-range RSSI? YES / NO

V1 ML Prediction:
  ✓ Predicted room: _____ 
  ✓ Confidence: _____% 
  ✓ Top predictions:
    1. Room _____ : _____% 
    2. Room _____ : _____% 
    3. Room _____ : _____% 

Backend:
  ✓ Backend received prediction? YES / NO
  ✓ ML response time: _____ ms
  ✓ HTTP status from ML: _____ 
  ✓ Timeout occurred? YES / NO

Phone A Notification:
  ✓ Notification received? YES / NO
  ✓ Notification text: "______________________________"
  ✓ Room shown in notification: _____ 
  ✓ Confidence shown: _____% 

Accuracy:
  ✓ Actual room: _____ 
  ✓ Predicted room: _____ 
  ✓ PREDICTION CORRECT? YES / NO
  ✓ If NO, error distance: _____ rooms away / different floor

─── DETECTION #2 (if multiple detections occurred) ───

[Repeat above template]

─── DETECTION #3 ───

[Repeat above template]

═══════════════════════════════════════════════════════════
END OF TEST REPORT
═══════════════════════════════════════════════════════════
```

---

## TROUBLESHOOTING

### If No BLE Detection Occurs:
- Verify tracker is powered on
- Verify Phone B has Bluetooth enabled
- Verify Phone B has Location permission
- Check Phone B logs for "BLE scan started"
- Move Phone B closer to tracker

### If No Wi-Fi Fingerprint:
- Verify Phone B has Location permission (required for Wi-Fi scanning)
- Check Phone B logs for "[CommunityWiFi] Starting automatic Wi-Fi scan"
- Verify NIE access points are in range

### If ML Returns 422:
- Check backend logs for RSSI validation warnings
- Check for "OUT OF RANGE RSSI VALUES DETECTED"
- This should NOT happen with V1 + localhost configuration

### If Backend Times Out (>10 seconds):
- This should NOT happen with localhost ML server
- Check ML server is running: `http://localhost:8000/health`
- Verify ML_API_URL in `.env` is `http://localhost:8000`

### If No Notification on Phone A:
- Verify asset status is LOST
- Verify Phone A has notifications enabled
- Check backend logs for "Owner notification created"
- Pull to refresh notifications screen

---

## EXPECTED RESULTS

### Success Criteria:
✅ BLE detection occurs within 30 seconds  
✅ Wi-Fi fingerprint collected (30-60 BSSIDs typical)  
✅ ML prediction received (any room, any confidence)  
✅ No timeout (response < 500ms expected)  
✅ No 422 errors  
✅ Phone A receives notification with room number  

### Accuracy NOT Required:
- V1 prediction accuracy is NOT being tested
- Wrong room prediction is ACCEPTABLE
- Low confidence is ACCEPTABLE
- Goal: Verify END-TO-END flow works

---

## AFTER TEST COMPLETION

**DO NOT:**
- ❌ Modify code to fix wrong predictions
- ❌ Retrain the model
- ❌ Change BLE/Wi-Fi scanning
- ❌ Change timing parameters

**DO:**
- ✅ Record all results in template above
- ✅ Save backend logs
- ✅ Save Phone B logs
- ✅ Save Phone A notification screenshot (optional)
- ✅ Report results back

---

## READY TO TEST

**All systems verified and ready.**

Please proceed with the test procedure and record your findings in the TEST RESULTS TEMPLATE.
