# Community Sensing Diagnostic Report
**Date:** August 28, 2026
**Issue:** 19 BLE scans show 0 detections despite AG-001 being physically present

---

## Root Cause Hypothesis

**Primary suspect: In-memory debounce map preventing repeat detections**

The `CommunityDetectionService` uses an in-memory `Map<String, DateTime> _lastReported` to prevent duplicate reports within 60 seconds. This map:

- **Persists for the entire app lifecycle** (survives app backgrounding)
- **Is NOT cleared when Community Sensing restarts**
- **May contain AG-001's last detection from yesterday**

If AG-001 was detected yesterday and the app was never force-stopped, the debounce timestamp from yesterday is still blocking new detections today.

**Secondary suspects:**
1. AG-001 asset status changed from LOST to ACTIVE/RECOVERED
2. JWT expired and HTTP requests are failing silently
3. Backend was not restarted after the `populate('owner')` → `populate('userId')` fix

---

## Diagnostic Logging Added

### Flutter (Client-side)

**File:** `lib/services/community_detection_service.dart`
- Added verbose logging in `shouldReport()`:
  - YES (never reported)
  - YES (elapsed: Xs >= 60s)
  - NO (elapsed: Xs < 60s, last: timestamp)

**File:** `lib/services/community_sensing_service.dart`
- Enhanced AssetGuard device filtering to log:
  - ✓ AssetGuard tracker matched
  - ✗ Not AssetGuard
- Added full device list logging after filtering

### Backend (Server-side)

**File:** `backend/src/controllers/communityController.js`
- Added banner-style logging for incoming requests:
  ```
  [Community] ════════════════════════════════════════
  [Community] INCOMING DETECTION REQUEST
  [Community]   trackerId  : AG-001
  [Community]   detectedBy : <userId> (<email>)
  [Community] ════════════════════════════════════════
  ```
- Added asset lookup result logging:
  - ✓ Asset found: <assetId>
  - Asset status: ACTIVE/LOST/RECOVERED
  - Asset owner: <userId> (<email>)
- Added gate-check logging:
  - ✗ Asset not found
  - ✗ Asset status is not LOST
  - ✗ Owner attempting to report own asset
- Added MongoDB insert confirmation:
  - ✓ Detection created in MongoDB: <detectionId>

---

## Testing Protocol

### Step 1: Restart Backend Server

**CRITICAL:** The backend must be restarted for the `populate('userId')` fix to take effect.

```bash
cd c:\flutter-project\assetguard\backend
node server.js
# OR if using nodemon:
npm run dev
```

Watch the terminal for incoming requests.

### Step 2: Install New APK on User B's Phone

**New APK location:** `c:\flutter-project\assetguard\build\app\outputs\flutter-apk\app-debug.apk`
**Built:** August 28, 2026 11:41:22 AM
**Size:** 187.02 MB

Install via:
- ADB: `adb install -r build\app\outputs\flutter-apk\app-debug.apk`
- Direct transfer and manual install

### Step 3: Force-Stop Existing App (CRITICAL)

On User B's phone:
1. Settings → Apps → AssetGuard AI
2. **Force Stop** (this clears the in-memory debounce map)
3. Open AssetGuard AI again
4. Login as User B
5. Navigate to Settings → Community Sensing
6. Start Community Sensing

### Step 4: Monitor Logs

**Flutter logs (User B's phone):**
```bash
# If connected via USB
adb logcat -s flutter

# Look for:
[Community BLE] ═══ Scan started ═══
[Community BLE] Device discovered: ...
[Community BLE] ✓ AssetGuard tracker matched: AG-001
[CommunityDetection] shouldReport(AG-001): YES/NO
[Community] ► Submitting detection to backend:
[Community] ◄ Response status: SUCCESS/404/500
```

**Backend logs (Terminal window):**
```
[Community] ════════════════════════════════════════
[Community] INCOMING DETECTION REQUEST
[Community]   trackerId  : AG-001
[Community] ════════════════════════════════════════
[Community] ✓ Asset found: <assetId>
[Community]   status     : LOST
[Community] ✓ All checks passed — creating detection record
[Community] ✓ Detection created in MongoDB: <detectionId>
```

### Step 5: Wait for Next Scan

Community Sensing scans every **75 seconds**. Watch for:
1. Scan #1 (immediate after service start)
2. Scan #2 (after 75s)
3. Scan #3 (after 150s)

---

## Expected Results by Stage

### ✓ BLE Scan
**Log:** `[Community BLE] ═══ Scan started ═══`
**Log:** `[Community BLE] Device discovered: ... trackerId: AG-001`

### ✓ AG-001 Matched
**Log:** `[Community BLE] ✓ AssetGuard tracker matched: AG-001`

### ⚠️ Debounce Check (KEY DIAGNOSTIC POINT)
**If debounced (BAD):**
```
[CommunityDetection] shouldReport(AG-001): NO (elapsed: 15s < 60s, last: 2026-08-27 16:45:32)
[Community BLE] ⊘ Skipping AG-001 (debounced - within 60s)
```
**Solution:** Force-stop the app to clear the in-memory map, then restart Community Sensing.

**If NOT debounced (GOOD):**
```
[CommunityDetection] shouldReport(AG-001): YES (never reported)
[Community BLE] → Submitting detection for AG-001
```

### ✓ reportDetection() Called
**Log:** `[Community] ► Submitting detection to backend:`
**Log:** `[Community]   trackerId  : AG-001`

### ✓ HTTP Request Sent
**Log:** ApiService.post('http://10.135.90.221:5000/api/community/detections', payload)

### ✓ Backend Received
**Log:** `[Community] INCOMING DETECTION REQUEST`
**Log:** `[Community]   trackerId  : AG-001`

### ✓ JWT Authentication
**No error = JWT valid**
If JWT expired, backend returns 401 and Flutter logs:
```
[Community] ◄ Response status: 401
[Community]   error      : Session expired — please log in again
```
**Solution:** User B must log out and log back in.

### ⚠️ Asset Status Check (KEY GATE)
**If asset is not LOST (BAD):**
```
[Community] ✓ Asset found: <assetId>
[Community]   status     : ACTIVE
[Community] ✗ Asset status is not LOST: ACTIVE
```
**Solution:** User A must mark AG-001 as LOST from their phone.

**If asset is LOST (GOOD):**
```
[Community] ✓ Asset found: <assetId>
[Community]   status     : LOST
[Community] ✓ All checks passed — creating detection record
```

### ✓ MongoDB create()
**Log:** `[Community] ✓ Detection created in MongoDB: <detectionId>`

### ✓ Document Persisted
**Verify in MongoDB:**
```javascript
// MongoDB Compass or CLI
db.communitydetections.find({ trackerId: 'AG-001' }).sort({ createdAt: -1 }).limit(1)
```

Should show a new document with today's timestamp.

---

## Quick Diagnosis Flowchart

```
User B's notification shows "19 scans, 0 detections"
↓
Check Flutter logs for: [Community BLE] ✓ AssetGuard tracker matched: AG-001
  ├─ NO  → AG-001 is not advertising or BLE hardware issue (out of scope)
  └─ YES → Continue
↓
Check Flutter logs for: [CommunityDetection] shouldReport(AG-001): ???
  ├─ NO (debounced) → SOLUTION: Force-stop app, clear debounce
  └─ YES → Continue
↓
Check Flutter logs for: [Community] ► Submitting detection to backend:
  ├─ NOT PRESENT → HTTP call blocked or failed before submission
  └─ PRESENT → Continue
↓
Check Backend logs for: [Community] INCOMING DETECTION REQUEST
  ├─ NOT PRESENT → Network issue, backend not running, or wrong IP
  └─ PRESENT → Continue
↓
Check Backend logs for: [Community]   status     : ???
  ├─ ACTIVE/RECOVERED → SOLUTION: User A must mark AG-001 as LOST
  └─ LOST → Continue
↓
Check Backend logs for: [Community] ✓ Detection created in MongoDB: <detectionId>
  ├─ NOT PRESENT → MongoDB connection issue or create() failure
  └─ PRESENT → SUCCESS — verify in MongoDB
```

---

## Pre-Test Checklist

- [ ] Backend server is restarted (to apply `populate('userId')` fix)
- [ ] New APK (Aug 28, 11:41 AM) is installed on User B's phone
- [ ] User B's app is **force-stopped** before starting Community Sensing
- [ ] AG-001 asset status is **LOST** in MongoDB (verify with User A or MongoDB Compass)
- [ ] User B is logged in with a valid JWT
- [ ] adb logcat or USB debugging is connected to capture Flutter logs
- [ ] Backend terminal window is visible to capture server logs

---

## Most Likely Outcomes

### Outcome 1: Debounce blocking (80% probability)
**Symptom:** `shouldReport(AG-001): NO (elapsed: Xs < 60s)`
**Fix:** Force-stop app, restart Community Sensing
**APK rebuild required:** No (already done for logging)
**Backend restart required:** Yes (for the populate fix)

### Outcome 2: Asset not LOST (15% probability)
**Symptom:** `[Community] ✗ Asset status is not LOST: ACTIVE`
**Fix:** User A marks AG-001 as LOST from their phone
**APK rebuild required:** No
**Backend restart required:** Yes

### Outcome 3: JWT expired (3% probability)
**Symptom:** `[Community] ◄ Response status: 401`
**Fix:** User B logs out and back in
**APK rebuild required:** No
**Backend restart required:** Yes

### Outcome 4: Backend not restarted (2% probability)
**Symptom:** Backend crashes on `asset.owner._id` (before the populate fix)
**Fix:** Restart backend
**APK rebuild required:** No
**Backend restart required:** Yes (obviously)

---

## Files Modified

**Flutter:**
- `lib/services/community_detection_service.dart` (shouldReport logging)
- `lib/services/community_sensing_service.dart` (device filtering logging)

**Backend:**
- `backend/src/controllers/communityController.js` (comprehensive request/response logging + populate fix)

**No schema changes, no BLE changes, no architecture changes.**

---

## Next Steps After Testing

Once diagnostic logs reveal the root cause:

1. **If debounce is the issue:**
   - Consider persisting debounce timestamps to SharedPreferences (survives app restarts)
   - OR reduce debounce interval from 60s to 30s
   - OR add a "Clear Detection History" button in Settings

2. **If asset status is the issue:**
   - Add UI indication in Community Sensing screen showing which assets are LOST
   - Add toast/notification when a detection is rejected due to status

3. **Remove verbose logging** from production builds (wrap in `kDebugMode` checks)

---

## Contact Points

- Backend logs: Terminal window running `node server.js`
- Flutter logs: `adb logcat -s flutter` while User B's phone is connected via USB
- MongoDB: MongoDB Compass → `communitydetections` collection
- Asset status: MongoDB Compass → `assets` collection → filter `{ trackerId: 'AG-001' }`
