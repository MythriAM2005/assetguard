# Testing Checklist: Background BLE Community Sensing

## Pre-Test Setup

### Requirements
- [ ] Two physical Android phones (Phone A and Phone B)
- [ ] One ESP32 AssetGuard tracker (AG-001)
- [ ] MongoDB access to verify detections
- [ ] Debug APK installed on both phones
- [ ] Two test accounts (User A and User B)

### Installation
```bash
# Build APK
cd c:\flutter-project\assetguard
flutter build apk --debug

# Install on Phone A
adb -s <Phone-A-Serial> install build\app\outputs\flutter-apk\app-debug.apk

# Install on Phone B
adb -s <Phone-B-Serial> install build\app\outputs\flutter-apk\app-debug.apk
```

## Test 1: Permission Flow & Auto-Start

### Phone B (User B)
- [ ] 1. Clear app data or fresh install
- [ ] 2. Launch app
- [ ] 3. Login as User B
- [ ] 4. **VERIFY:** Bluetooth permission dialog appears immediately after login
- [ ] 5. Grant Bluetooth permission
- [ ] 6. **VERIFY:** Location permission dialog appears
- [ ] 7. Grant Location permission
- [ ] 8. **VERIFY:** Navigate to Home screen
- [ ] 9. Pull down notification shade
- [ ] 10. **VERIFY:** "AssetGuard Community Sensing" notification visible
- [ ] 11. **VERIFY:** Notification text: "Community sensing active — starting BLE & Wi-Fi scans…"

**Expected Result:** ✅ Community sensing starts automatically after login

---

## Test 2: Background Detection (Core Feature)

### Phone A (User A) - Setup
- [ ] 1. Login as User A
- [ ] 2. Navigate to "My Assets"
- [ ] 3. Verify AG-001 is registered
- [ ] 4. Tap AG-001 → Mark as LOST
- [ ] 5. **VERIFY:** Status changes to "LOST"
- [ ] 6. Place AG-001 tracker in a fixed location

### Phone B (User B) - Detection
- [ ] 7. Phone B already has community sensing active (from Test 1)
- [ ] 8. Lock Phone B screen
- [ ] 9. Carry Phone B to within 5 meters of AG-001
- [ ] 10. Wait 90 seconds (allow one full scan cycle)
- [ ] 11. Unlock Phone B
- [ ] 12. Pull down notification shade
- [ ] 13. **VERIFY:** Notification updated with detection count: "BLE: 1, Wi-Fi: 1 (1 detection)"

### MongoDB Verification
```javascript
// Connect to MongoDB
use assetguard_db

// Check communitydetections collection
db.communitydetections.find().sort({createdAt: -1}).limit(1).pretty()
```

- [ ] 14. **VERIFY:** New document exists:
```javascript
{
  _id: ObjectId("..."),
  asset: ObjectId("..."), // User A's AG-001 asset ID
  detectedBy: ObjectId("..."), // User B's user ID
  trackerId: "AG-001",
  rssi: -65, // or similar BLE signal strength
  detectedAt: ISODate("2026-08-27T..."),
  remoteId: "XX:XX:XX:XX:XX:XX", // ESP32 MAC address
  createdAt: ISODate("2026-08-27T..."),
  __v: 0
}
```

- [ ] 15. **VERIFY:** `detectedBy` is User B's ObjectId (NOT User A)
- [ ] 16. **VERIFY:** `asset` is User A's AG-001 asset ObjectId

**Expected Result:** ✅ Community detection created automatically in background

---

## Test 3: Owner's Own Tracker (No Detection)

### Phone A (User A) - Own Tracker
- [ ] 1. Phone A has community sensing active
- [ ] 2. AG-001 marked as LOST (from Test 2)
- [ ] 3. Move Phone A near AG-001
- [ ] 4. Wait 90 seconds
- [ ] 5. Pull down notification shade
- [ ] 6. **VERIFY:** Notification shows scan count incremented

### MongoDB Verification
```javascript
// Count detections by User A for AG-001
db.communitydetections.countDocuments({
  trackerId: "AG-001",
  detectedBy: ObjectId("...") // User A's ObjectId
})
```

- [ ] 7. **VERIFY:** Count is 0 (no community detection for owner)

### ADB Logs (Optional)
```bash
adb -s <Phone-A-Serial> logcat | grep CommunitySensing
```

- [ ] 8. **VERIFY:** Log shows: `[CommunityDetection] Tracker AG-001 not LOST or not found (status 404) — skipping`

**Expected Result:** ✅ Owner's phone does NOT create community detection

---

## Test 4: NOT LOST Asset (No Detection)

### Phone A (User A) - Mark as ACTIVE
- [ ] 1. Navigate to "My Assets"
- [ ] 2. Tap AG-001 → Change status to ACTIVE
- [ ] 3. **VERIFY:** Status is ACTIVE (not LOST)

### Phone B (User B) - Try Detection
- [ ] 4. Phone B near AG-001
- [ ] 5. Wait 90 seconds
- [ ] 6. Pull down notification shade
- [ ] 7. **VERIFY:** Scan count increments but detection count does NOT

### MongoDB Verification
```javascript
// Count detections after status changed to ACTIVE
const countBefore = db.communitydetections.countDocuments({trackerId: "AG-001"})
// Wait for scan
const countAfter = db.communitydetections.countDocuments({trackerId: "AG-001"})
// countBefore === countAfter (no new detection)
```

- [ ] 8. **VERIFY:** No new community detection created

**Expected Result:** ✅ ACTIVE (not LOST) assets are NOT reported

---

## Test 5: Debouncing (60-second interval)

### Phone B (User B) - Repeated Detection
- [ ] 1. Mark AG-001 as LOST again (Phone A)
- [ ] 2. Phone B near AG-001
- [ ] 3. Wait 90 seconds → First detection
- [ ] 4. **VERIFY:** Detection count increments to 1
- [ ] 5. Wait 30 seconds (total 120s, but within 60s debounce)
- [ ] 6. Next scan cycle occurs
- [ ] 7. **VERIFY:** Detection count does NOT increment (debounced)
- [ ] 8. Wait another 45 seconds (total 75s+ since first detection, debounce expired)
- [ ] 9. Next scan cycle occurs
- [ ] 10. **VERIFY:** Detection count increments (debounce expired, new detection)

### MongoDB Verification
```javascript
// Check timestamps
db.communitydetections.find({
  trackerId: "AG-001",
  detectedBy: ObjectId("...") // User B
}).sort({detectedAt: -1}).limit(2)
```

- [ ] 11. **VERIFY:** Two detections exist
- [ ] 12. **VERIFY:** Time difference between them is ≥ 60 seconds

**Expected Result:** ✅ Same tracker reported max once per 60 seconds

---

## Test 6: Non-AssetGuard Devices Ignored

### Environment Setup
- [ ] 1. Ensure other Bluetooth devices nearby (phones, headphones, etc.)
- [ ] 2. Phone B community sensing active

### Detection Test
- [ ] 3. Wait 90 seconds for scan
- [ ] 4. Pull down notification shade
- [ ] 5. **VERIFY:** Only AssetGuard trackers (AG-XXX) reported

### ADB Logs
```bash
adb -s <Phone-B-Serial> logcat | grep BleService
```

- [ ] 6. **VERIFY:** Log shows multiple devices detected:
```
[BleService] Device found: iPhone 13 (rssi: -55)
[BleService] Device found: Galaxy Buds (rssi: -72)
[BleService] Device found: AG-001 (rssi: -65)
[CommunitySensing] AssetGuard trackers detected: 1
```

- [ ] 7. **VERIFY:** Only AG-001 reported, others ignored

**Expected Result:** ✅ Non-AssetGuard devices ignored

---

## Test 7: App Backgrounded / Screen Locked

### Phone B (User B) - Background Test
- [ ] 1. Community sensing active
- [ ] 2. Note current scan counts (e.g., BLE: 5, Wi-Fi: 5)
- [ ] 3. Lock screen
- [ ] 4. Wait 5 minutes (4 scan cycles at 75s each)
- [ ] 5. Unlock screen
- [ ] 6. Pull down notification shade
- [ ] 7. **VERIFY:** Scan counts incremented (e.g., BLE: 9, Wi-Fi: 9)
- [ ] 8. **VERIFY:** Service continued running while locked

**Expected Result:** ✅ Service survives screen lock

---

## Test 8: App Minimized / Switching Apps

### Phone B (User B) - Minimize Test
- [ ] 1. Community sensing active
- [ ] 2. Press Home button (minimize app)
- [ ] 3. Open Chrome / YouTube / other app
- [ ] 4. Use other app for 3 minutes
- [ ] 5. Pull down notification shade
- [ ] 6. **VERIFY:** "AssetGuard Community Sensing" notification still visible
- [ ] 7. **VERIFY:** Scan counts incremented
- [ ] 8. Reopen AssetGuard
- [ ] 9. **VERIFY:** App resumes normally

**Expected Result:** ✅ Service survives app minimize

---

## Test 9: Process Kill & Auto-Restart

### Phone B (User B) - Force Stop
- [ ] 1. Community sensing active
- [ ] 2. Open Android Settings → Apps → AssetGuard
- [ ] 3. Tap "Force Stop"
- [ ] 4. **VERIFY:** Notification disappears
- [ ] 5. Pull down notification shade
- [ ] 6. **VERIFY:** "AssetGuard Community Sensing" notification gone
- [ ] 7. Reopen AssetGuard app
- [ ] 8. **VERIFY:** Auto-login occurs (no login screen)
- [ ] 9. **VERIFY:** No permission dialogs (already granted)
- [ ] 10. Wait 5 seconds
- [ ] 11. Pull down notification shade
- [ ] 12. **VERIFY:** "AssetGuard Community Sensing" notification reappears
- [ ] 13. **VERIFY:** Community sensing restarted automatically

**Expected Result:** ✅ Auto-restart after process kill

---

## Test 10: Manual Toggle On/Off

### Phone B (User B) - Toggle Test
- [ ] 1. Navigate to "Nearby Devices"
- [ ] 2. Scroll down to "Community Sensing" section
- [ ] 3. **VERIFY:** Toggle is ON (enabled)
- [ ] 4. Tap toggle to OFF
- [ ] 5. **VERIFY:** Notification disappears
- [ ] 6. Wait 90 seconds
- [ ] 7. **VERIFY:** No new scans occur (service stopped)
- [ ] 8. Tap toggle to ON
- [ ] 9. **VERIFY:** Notification reappears
- [ ] 10. **VERIFY:** Scans resume

**Expected Result:** ✅ Manual toggle works correctly

---

## Test 11: Permissions Already Granted

### Phone A (User A) - Re-login Test
- [ ] 1. Logout from Phone A
- [ ] 2. Login as User A again
- [ ] 3. **VERIFY:** NO permission dialogs appear (already granted)
- [ ] 4. **VERIFY:** Navigate directly to Home
- [ ] 5. Pull down notification shade
- [ ] 6. **VERIFY:** "AssetGuard Community Sensing" notification appears immediately

**Expected Result:** ✅ No redundant permission requests

---

## Test 12: Permission Denial Handling

### Clean Phone (Phone C or Reset Phone B)
- [ ] 1. Fresh install / clear app data
- [ ] 2. Login
- [ ] 3. **VERIFY:** Bluetooth permission dialog appears
- [ ] 4. Tap "Deny"
- [ ] 5. **VERIFY:** Location permission dialog appears
- [ ] 6. Tap "Deny"
- [ ] 7. **VERIFY:** Explanation dialog appears:
   ```
   "Permissions Required
   
   AssetGuard needs Bluetooth and Location permissions to:
   • Detect nearby AssetGuard trackers
   • Help find lost assets
   • Provide accurate location tracking
   
   You can grant these permissions later in Settings..."
   ```
- [ ] 8. Tap "Continue Anyway"
- [ ] 9. **VERIFY:** Navigate to Home
- [ ] 10. **VERIFY:** No community sensing notification (permissions denied)
- [ ] 11. Navigate to "Nearby Devices"
- [ ] 12. Tap "Scan for Devices"
- [ ] 13. **VERIFY:** Error message: "Bluetooth or Location permission is required..."

**Expected Result:** ✅ Graceful handling of permission denial

---

## Test 13: Battery Usage (24-hour test)

### Phone B (User B) - Battery Monitor
- [ ] 1. Fully charge Phone B to 100%
- [ ] 2. Enable community sensing
- [ ] 3. Use phone normally for 24 hours
- [ ] 4. Check battery stats:
   - Android Settings → Battery → Battery Usage
   - Find "AssetGuard" in the list
- [ ] 5. **RECORD:** Battery percentage used by AssetGuard
- [ ] 6. **RECORD:** Total screen-on time
- [ ] 7. **RECORD:** Total background time

### Expected Results:
- AssetGuard battery usage: 5-15% (varies by device)
- Background scans continue even with screen off
- Phone remains usable throughout the day

**Note:** Battery impact varies significantly by device manufacturer and Android version.

---

## Test 14: Multi-User Isolation (Security Test)

### MongoDB Verification
```javascript
// User A's assets
db.assets.find({owner: ObjectId("...")}).pretty() // User A's ObjectId

// User B's assets
db.assets.find({owner: ObjectId("...")}).pretty() // User B's ObjectId
```

- [ ] 1. **VERIFY:** User B CANNOT see User A's assets in "My Assets"
- [ ] 2. **VERIFY:** Community detections link to correct owner:
```javascript
db.communitydetections.aggregate([
  {
    $lookup: {
      from: "assets",
      localField: "asset",
      foreignField: "_id",
      as: "assetDetails"
    }
  },
  {$match: {trackerId: "AG-001"}},
  {$limit: 1}
])
```
- [ ] 3. **VERIFY:** `assetDetails.owner` is User A (NOT User B)

**Expected Result:** ✅ User isolation maintained

---

## Test 15: Notification Updates

### Phone B (User B) - Notification Text
- [ ] 1. Community sensing active
- [ ] 2. AG-001 NOT nearby
- [ ] 3. Wait for 3 scan cycles (225 seconds)
- [ ] 4. Pull down notification shade
- [ ] 5. **VERIFY:** Notification shows: "Community sensing active — BLE: 3, Wi-Fi: 3 (0 detections)"
- [ ] 6. Move near AG-001 (LOST)
- [ ] 7. Wait 90 seconds
- [ ] 8. **VERIFY:** Notification updates: "Community sensing active — BLE: 4, Wi-Fi: 4 (1 detection)"

**Expected Result:** ✅ Notification updates dynamically

---

## Performance Metrics

### Record During Testing

| Metric | Target | Actual |
|--------|--------|--------|
| Scan frequency | Every 75s | ___ seconds |
| BLE scan duration | ~8s | ___ seconds |
| Detection latency | <90s | ___ seconds |
| Battery drain (24h) | 5-15% | ___% |
| Process restarts | 0 (unless killed) | ___ times |
| Failed detections | 0 | ___ times |

---

## Known Issues to Watch For

- [ ] ❌ Notification doesn't appear → Check permissions
- [ ] ❌ Scans not incrementing → Check process is alive
- [ ] ❌ Detections not created in MongoDB → Check tracker is LOST
- [ ] ❌ Owner's detection created → Backend bug (should reject)
- [ ] ❌ Service stops after 10 minutes → Android battery optimization
- [ ] ❌ BLE scan timeout → Bluetooth hardware issue

---

## Post-Testing

### Cleanup
- [ ] 1. Stop community sensing on all phones
- [ ] 2. Mark AG-001 as ACTIVE (not LOST)
- [ ] 3. Clear test community detections:
```javascript
db.communitydetections.deleteMany({
  trackerId: "AG-001",
  detectedAt: {$gte: ISODate("2026-08-27T00:00:00Z")}
})
```

### Report
- [ ] Document any failures
- [ ] Note device-specific behaviors
- [ ] Record battery usage statistics
- [ ] Identify improvements needed

---

## Sign-Off

- [ ] All tests passed
- [ ] Battery usage acceptable
- [ ] No security issues identified
- [ ] Ready for production

**Tester:** _______________
**Date:** _______________
**Devices Tested:** _______________
