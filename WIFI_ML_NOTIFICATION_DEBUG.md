# Wi-Fi ML Room Prediction Notification Debugging Guide

**Date**: August 28, 2026, 2:45 PM  
**Status**: ✅ ENHANCED LOGGING ADDED

---

## Overview

Enhanced logging has been added to trace the complete Wi-Fi → ML → Notification flow. This guide explains how to use the logs to diagnose issues.

---

## Complete Flow with Logging

### 1. Wi-Fi Scan (Task Isolate)

**What happens**: Automatic Wi-Fi scan every 15 seconds

**Expected logs**:
```
[CommunityWiFi] Starting automatic Wi-Fi scan...
[CommunityWiFi] ✓ Wi-Fi scan success: 76 NIE APs found
[CommunityWiFi] Fingerprint: 76 BSSIDs
[CommunityWiFi] Fingerprint prepared — sending to main isolate for upload
[CommunityWiFi] Wi-Fi scan #1 sent to main isolate
```

**If missing**: Wi-Fi scanning is not working

---

### 2. Wi-Fi Upload (Main Isolate)

**What happens**: Main isolate receives fingerprint and uploads with authentication

**Expected logs**:
```
[CommunityWiFi] Wi-Fi upload requested by foreground task
[CommunityWiFi] Uploading fingerprint with 76 BSSIDs
[CommunityWiFi] ✓ Upload success
[WiFiCache] ✓ Fingerprint cached: 76 BSSIDs at 2026-08-28T14:30:00.000Z
```

**If missing**: Authentication or upload failing

---

### 3. BLE Detection (Main Isolate)

**What happens**: BLE scan finds AG-001 tracker

**Expected logs**:
```
[Community BLE] ═══ Scan started ═══
[Community BLE] Starting flutter_blue_plus scan (8 seconds)...
[Community BLE] Scan #1 complete: 19 total devices found
[Community BLE] ✓ AssetGuard tracker matched: AG-001
```

**If missing**: BLE scanning not finding AG-001

---

### 4. Wi-Fi Cache Retrieval

**What happens**: BLE detection retrieves cached Wi-Fi fingerprint

**Expected logs**:
```
[Community BLE] → Submitting detection for AG-001:
[WiFiCache] ✓ Fingerprint retrieved from cache (age: 5s, 76 BSSIDs)
[CommunityWiFi] ═══ Wi-Fi FINGERPRINT RETRIEVED FROM CACHE ═══
[CommunityWiFi]     BSSIDs: 76
[CommunityWiFi]     Sample: 84:d8:1b:aa:bb:cc:-43dBm, 8a:d8:1b:dd:ee:ff:-67dBm, ...
```

**If shows "No fingerprint in cache"**:
- Wi-Fi scan happened >2 minutes ago
- Wi-Fi upload failed
- Cache not being populated

---

### 5. Detection Submission to Backend

**What happens**: Flutter sends detection with Wi-Fi fingerprint to backend

**Expected logs**:
```
[Community] ═══════════════════════════════════════
[Community] ► SUBMITTING DETECTION TO BACKEND
[Community]   trackerId  : AG-001
[Community]   rssi       : -67 dBm
[CommunityWiFi] ✓ Wi-Fi fingerprint INCLUDED in payload
[CommunityWiFi]   BSSIDs: 76
[CommunityWiFi]   Sample: 84:d8:1b:aa:bb:cc:-43dBm, ...
[Community] ═══════════════════════════════════════
```

**If shows "NO Wi-Fi fingerprint in payload"**:
- Cache was empty
- Cache expired
- Wi-Fi scan never ran

---

### 6. Backend Receives Detection

**What happens**: Backend validates asset is LOST and owned by someone else

**Expected backend logs**:
```
[Community] ════════════════════════════════════════
[Community] INCOMING DETECTION REQUEST
[Community]   trackerId  : AG-001
[Community]   rssi       : -67 dBm
[Community]   detectedBy : <User B ID> (userb@test.com)
[Community] ════════════════════════════════════════
[Community] ✓ Asset found: <Asset ID>
[Community]   name       : Laptop
[Community]   status     : LOST
[Community]   owner      : <User A ID> (usera@test.com)
[Community] ✓ All checks passed — creating detection record
```

**If shows "Detection ignored — asset is RECOVERED"**:
- Asset was recovered, detection correctly blocked

**If shows "Asset not found"**:
- Tracker ID doesn't exist or asset not LOST

---

### 7. ML Room Prediction (Backend)

**What happens**: Backend sends Wi-Fi fingerprint to ML server

**Expected backend logs**:
```
[CommunityWiFi] Wi-Fi fingerprint provided with 76 BSSIDs
[CommunityWiFi] Calling ML room prediction...
```

**Then ML request**:
```bash
POST http://10.135.90.221:8000/predict-room
Content-Type: application/json

{
  "wifi": {
    "84:d8:1b:aa:bb:cc": -43,
    "8a:d8:1b:dd:ee:ff": -67,
    ...
  }
}
```

**ML server response (200 OK)**:
```json
{
  "room": "310",
  "confidence": 0.376667,
  "top_predictions": [
    {"room": "310", "probability": 0.376667},
    {"room": "209", "probability": 0.193333}
  ]
}
```

**Expected backend logs after ML**:
```
[CommunityWiFi] ✓ ML predicted room: 310
[CommunityWiFi] ✓ Confidence: 0.376667
```

**If shows "ML prediction failed"**:
- ML server not running
- ML server not reachable
- ML server returned error
- Timeout (>10 seconds)

**If shows "ML API returned status: 500"**:
- ML server internal error
- Check ML server logs

---

### 8. Detection Stored in MongoDB

**What happens**: Backend creates CommunityDetection document

**Expected backend logs**:
```
[Community] Detection submitted:
[Community]   trackerId  : AG-001
[Community]   assetId    : <Asset ID>
[Community]   ownerId    : <User A ID>
[Community] ✓ Detection created in MongoDB: <Detection ID>
```

**MongoDB document**:
```javascript
{
  trackerId: "AG-001",
  assetId: ObjectId("..."),
  detectedBy: ObjectId("..."), // User B
  rssi: -67,
  latitude: 12.9716,
  longitude: 77.5946,
  predictedRoom: "310",      // ← ML prediction
  roomConfidence: 0.376667,  // ← ML confidence
  detectedAt: ISODate("2026-08-28T14:30:00Z"),
  createdAt: ISODate("2026-08-28T14:30:01Z")
}
```

---

### 9. Owner Notification Created

**What happens**: Backend creates notification for asset owner (User A)

**Expected backend logs**:
```
[Community] Owner notification created: <Notification ID>
[Community] Notification sent to: usera@test.com
[Community]   title   : Asset Detected
[Community]   message : Your Laptop (AG-001) was detected near Room 310. (38% confidence)
```

**MongoDB notification document**:
```javascript
{
  recipient: ObjectId("..."), // User A ID
  type: "asset_detected",
  title: "Asset Detected",
  message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)",
  assetId: ObjectId("..."),
  detectionId: ObjectId("..."),
  trackerId: "AG-001",
  latitude: 12.9716,
  longitude: 77.5946,
  rssi: -67,
  detectedAt: ISODate("2026-08-28T14:30:00Z"),
  predictedRoom: "310",      // ← Room included
  roomConfidence: 0.376667,  // ← Confidence included
  read: false,
  createdAt: ISODate("2026-08-28T14:30:01Z")
}
```

---

### 10. Backend Response to Flutter

**What happens**: Backend returns success with room prediction

**Backend response**:
```json
{
  "success": true,
  "message": "Community detection recorded. Asset owner will be notified.",
  "detectionId": "66c4d8e7f1234567890abce0",
  "predictedRoom": "310",
  "confidence": 0.376667
}
```

**Expected Flutter logs**:
```
[Community] ═══════════════════════════════════════
[Community] ◄ BACKEND RESPONSE RECEIVED
[Community]   status     : SUCCESS (201/200)
[Community]   message    : Community detection recorded...
[CommunityWiFi] ═══ ML ROOM PREDICTION RECEIVED ═══
[CommunityWiFi] ✓ Predicted room: 310
[CommunityWiFi] ✓ Confidence: 0.376667
[CommunityWiFi] ═══════════════════════════════════
[Community] ═══════════════════════════════════════
[Community BLE] ✓ Detection reported successfully: AG-001
```

---

### 11. User A Receives Notification

**What happens**: User A's app fetches notifications from backend

**User A app requests**:
```
GET /api/notifications?unreadOnly=true
Authorization: Bearer <User A token>
```

**Backend returns**:
```json
{
  "success": true,
  "notifications": [
    {
      "_id": "...",
      "type": "asset_detected",
      "title": "Asset Detected",
      "message": "Your Laptop (AG-001) was detected near Room 310. (38% confidence)",
      "predictedRoom": "310",
      "roomConfidence": 0.376667,
      "read": false,
      "createdAt": "2026-08-28T14:30:01.000Z"
    }
  ],
  "unreadCount": 1
}
```

**User A sees**:
- Bell icon shows badge: "1"
- Notification list shows: "Asset Detected"
- Message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)"

---

## Diagnostic Checklist

### Step 1: Verify Wi-Fi Scanning

**Check logs**:
```bash
adb logcat | grep CommunityWiFi
```

**Expected every 15 seconds**:
```
[CommunityWiFi] Starting automatic Wi-Fi scan...
[CommunityWiFi] ✓ Wi-Fi scan success: X NIE APs found
[CommunityWiFi] ✓ Upload success
[WiFiCache] ✓ Fingerprint cached: X BSSIDs
```

**If failing**:
- ❌ No logs → Community Sensing not enabled
- ❌ "Wi-Fi scan failed" → Check permissions
- ❌ "Upload failed: Not authorised" → Check authentication (should be fixed)
- ❌ "0 NIE APs" → Not on NIE campus or no NIE networks in range

---

### Step 2: Verify BLE Detection

**Check logs**:
```bash
adb logcat | grep "Community BLE"
```

**Expected when AG-001 nearby**:
```
[Community BLE] Scan #X complete: Y total devices found
[Community BLE] ✓ AssetGuard tracker matched: AG-001
```

**If failing**:
- ❌ No AG-001 found → Tracker not in range or powered off
- ❌ "Not AssetGuard" → Tracker ID doesn't match AG-XXX pattern

---

### Step 3: Verify Wi-Fi Cache

**Check logs when BLE detects AG-001**:
```bash
adb logcat | grep WiFiCache
```

**Expected**:
```
[WiFiCache] ✓ Fingerprint retrieved from cache (age: Xs, Y BSSIDs)
```

**If failing**:
- ❌ "No fingerprint in cache" → Wi-Fi scan never ran or failed
- ❌ "Fingerprint expired" → BLE detection happened >2 min after Wi-Fi scan

---

### Step 4: Verify Fingerprint Included in Detection

**Check logs**:
```bash
adb logcat | grep "SUBMITTING DETECTION"
```

**Expected**:
```
[CommunityWiFi] ✓ Wi-Fi fingerprint INCLUDED in payload
[CommunityWiFi]   BSSIDs: 76
```

**If shows**:
```
[CommunityWiFi] ✗ NO Wi-Fi fingerprint in payload
```

**Root cause**: Cache was empty or expired

---

### Step 5: Verify Backend ML Call

**Check backend terminal**:

**Expected**:
```
[CommunityWiFi] Wi-Fi fingerprint provided with X BSSIDs
[CommunityWiFi] Calling ML room prediction...
[CommunityWiFi] ✓ ML predicted room: 310
[CommunityWiFi] ✓ Confidence: 0.376667
```

**If shows**:
```
[CommunityWiFi] ✗ ML prediction failed: fetch failed
```

**Verify ML server**:
```bash
curl http://10.135.90.221:8000/health
# Should return: {"status": "ok"}
```

---

### Step 6: Verify Notification Created

**Check backend terminal**:

**Expected**:
```
[Community] Owner notification created: <ID>
[Community] Notification sent to: usera@test.com
[Community]   message: Your Laptop (AG-001) was detected near Room 310. (38% confidence)
```

**Verify MongoDB**:
```javascript
db.notifications.find({
  type: "asset_detected",
  trackerId: "AG-001"
}).sort({createdAt: -1}).limit(1)

// Should show:
// - predictedRoom: "310"
// - roomConfidence: 0.376667
// - message includes room number
```

---

### Step 7: Verify User A Receives Notification

**User A phone**:
1. Open app
2. Check bell icon → Should show badge
3. Tap notifications → Should see "Asset Detected"
4. Message should include "Room 310"

**If not appearing**:
- Check User A is the asset owner
- Check notification was created for correct user ID
- Check User A app is fetching notifications

---

## Common Issues and Solutions

### Issue 1: Wi-Fi Fingerprint Never Cached

**Symptoms**:
```
[WiFiCache] ✗ No fingerprint in cache
```

**Diagnosis**:
```bash
# Check Wi-Fi scan logs
adb logcat | grep CommunityWiFi | grep "scan success"
```

**Possible causes**:
1. Wi-Fi scanning failing
2. Upload failing (authentication)
3. Not on NIE campus (0 NIE APs)

**Solution**:
- Ensure on NIE campus
- Check Wi-Fi enabled on device
- Check location permission granted
- Verify authentication token present

---

### Issue 2: Wi-Fi Fingerprint Expired

**Symptoms**:
```
[WiFiCache] ✗ Fingerprint expired (age: 150s > 120s)
```

**Diagnosis**: BLE detection happened >2 minutes after Wi-Fi scan

**Solution**:
- Both Wi-Fi and BLE scan every 15 seconds
- Cache should never expire if both are running
- Check if Wi-Fi scanning stopped

---

### Issue 3: ML Server Not Responding

**Symptoms**:
```
[CommunityWiFi] ✗ ML prediction failed: fetch failed
```

**Diagnosis**:
```bash
curl http://10.135.90.221:8000/health
# Should return 200 OK
```

**Solution**:
- Start ML server: `uvicorn main:app --host 0.0.0.0 --port 8000`
- Check firewall allows port 8000
- Verify ML_API_URL in backend/.env

---

### Issue 4: ML Server Returns Error

**Symptoms**:
```
[CommunityWiFi] ✗ ML API returned status: 500
```

**Check ML server logs** for error details

**Common causes**:
- Model files missing
- BSSID format incorrect
- Feature count mismatch

---

### Issue 5: Notification Created But No Room

**Symptoms**:
- Notification exists in MongoDB
- `predictedRoom` field is `null`
- Message doesn't include room

**Diagnosis**:
```bash
# Check if Wi-Fi fingerprint was included
adb logcat | grep "Wi-Fi fingerprint INCLUDED"
```

**Possible causes**:
1. Wi-Fi fingerprint not included in detection
2. ML prediction failed
3. ML prediction timed out

---

### Issue 6: Notification Created With Room But User A Doesn't See It

**Symptoms**:
- MongoDB shows notification with room
- User A doesn't see it in app

**Diagnosis**:
1. Verify `recipient` field matches User A's ID
2. Verify User A is asset owner
3. Check User A app is fetching notifications

**Check MongoDB**:
```javascript
// Find User A's ID
db.users.findOne({email: "usera@test.com"})

// Find asset owner
db.assets.findOne({trackerId: "AG-001"})

// Find notification recipient
db.notifications.findOne({trackerId: "AG-001"}).recipient

// All three IDs should match
```

---

## Files Changed (Logging Only)

### 1. `lib/services/community_sensing_service.dart`
- Enhanced BLE detection logs
- Show Wi-Fi fingerprint retrieval status
- Show sample BSSIDs

### 2. `lib/services/community_detection_service.dart`
- Enhanced detection submission logs
- Show payload contents clearly
- Show ML response parsing

### 3. `lib/services/wifi_fingerprint_cache.dart`
- Added import for `debugPrint`
- Log cache updates
- Log cache retrievals
- Show cache age and expiry

---

## Testing Commands

### Start ML Server
```bash
cd ml-server
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Monitor Flutter Logs (Comprehensive)
```bash
adb logcat | grep -E "Community|CommunityWiFi|WiFiCache"
```

### Monitor Flutter Logs (Wi-Fi Only)
```bash
adb logcat | grep CommunityWiFi
```

### Monitor Flutter Logs (BLE Only)
```bash
adb logcat | grep "Community BLE"
```

### Test ML Server
```bash
curl -X POST http://10.135.90.221:8000/predict-room \
  -H "Content-Type: application/json" \
  -d '{"wifi":{"84:d8:1b:aa:bb:cc":-43,"8a:d8:1b:dd:ee:ff":-67}}'

# Should return:
# {"room":"310","confidence":0.38,"top_predictions":[...]}
```

### Check Backend Health
```bash
curl http://10.135.90.221:5000/api/health
```

### Check MongoDB Notifications
```javascript
use assetguard_db
db.notifications.find({
  type: "asset_detected",
  trackerId: "AG-001"
}).sort({createdAt: -1}).limit(1).pretty()
```

---

## Expected Complete Log Sequence

**Perfect flow from Wi-Fi scan to notification**:

```
// Wi-Fi Scan
[CommunityWiFi] Starting automatic Wi-Fi scan...
[CommunityWiFi] ✓ Wi-Fi scan success: 76 NIE APs found
[CommunityWiFi] Fingerprint prepared — sending to main isolate for upload
[CommunityWiFi] Wi-Fi upload requested by foreground task
[CommunityWiFi] Uploading fingerprint with 76 BSSIDs
[CommunityWiFi] ✓ Upload success
[WiFiCache] ✓ Fingerprint cached: 76 BSSIDs at 2026-08-28T14:30:00.000Z

// BLE Detection (5 seconds later)
[Community BLE] ═══ Scan started ═══
[Community BLE] ✓ AssetGuard tracker matched: AG-001
[WiFiCache] ✓ Fingerprint retrieved from cache (age: 5s, 76 BSSIDs)
[CommunityWiFi] ═══ Wi-Fi FINGERPRINT RETRIEVED FROM CACHE ═══
[CommunityWiFi]     BSSIDs: 76

// Submission
[Community] ═══════════════════════════════════════
[Community] ► SUBMITTING DETECTION TO BACKEND
[CommunityWiFi] ✓ Wi-Fi fingerprint INCLUDED in payload
[CommunityWiFi]   BSSIDs: 76

// Response
[Community] ◄ BACKEND RESPONSE RECEIVED
[CommunityWiFi] ═══ ML ROOM PREDICTION RECEIVED ═══
[CommunityWiFi] ✓ Predicted room: 310
[CommunityWiFi] ✓ Confidence: 0.376667
[Community BLE] ✓ Detection reported successfully: AG-001
```

---

## Build Status

✅ **APK Built**: `build\app\outputs\flutter-apk\app-debug.apk`  
✅ **Build Time**: August 28, 2:44 PM  
✅ **Enhanced Logging**: Added  
✅ **Ready for Testing**: YES  

---

## Next Steps

1. **Install APK**:
   ```bash
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

2. **Start ML Server** (if not running):
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

3. **Enable Community Sensing** on Phone B

4. **Monitor Logs**:
   ```bash
   adb logcat | grep -E "Community|CommunityWiFi|WiFiCache"
   ```

5. **Place AG-001 near Phone B**

6. **Watch for complete log sequence** above

7. **Check User A's notifications**

8. **Verify notification includes room**: "Room 310"

---

**Report Complete**: August 28, 2026, 2:45 PM  
**Status**: ✅ READY FOR DIAGNOSTIC TESTING
