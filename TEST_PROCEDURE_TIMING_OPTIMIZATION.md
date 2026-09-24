# Two-Phone Test Procedure: Timing Optimization

**Date:** August 28, 2026  
**APK:** `build\app\outputs\flutter-apk\app-debug.apk` (built 11:59:05 AM)  
**Changes:** Scan interval 75s→15s, Debounce 60s→30s  

---

## Pre-Test Setup

### User A's Phone (Asset Owner)

1. **Verify AG-001 status in app:**
   - Open AssetGuard AI
   - Login as User A
   - Navigate to "My Assets"
   - Find AG-001
   - **Status must be: LOST** (red indicator)
   - If not LOST: Long-press AG-001 → Mark as Lost

2. **Keep AG-001 tracker powered on and advertising:**
   - Ensure AG-001 has battery
   - Verify it's in BLE advertising mode
   - Place it within 5-10 meters of User B's test location

3. **User A's app can remain open or closed** — not required for test

### User B's Phone (Community Member)

1. **Uninstall old APK (if present):**
   - Settings → Apps → AssetGuard AI → Uninstall
   - OR: `adb uninstall com.example.assetguard` (if via USB)

2. **Install optimized APK:**
   - Transfer `app-debug.apk` to phone via USB/email/cloud
   - Tap APK and install
   - OR: `adb install -r build\app\outputs\flutter-apk\app-debug.apk`

3. **Launch and login:**
   - Open AssetGuard AI
   - Login as User B (NOT User A)
   - Grant all permissions when prompted (Location, Bluetooth, Notifications)

4. **Navigate to Community Sensing:**
   - Bottom nav → Settings (gear icon)
   - Tap "Community Sensing"

5. **Start Community Sensing:**
   - Toggle ON or tap "Start Community Sensing"
   - Notification should appear: "AssetGuard Community Sensing"

6. **Verify notification initial state:**
   - Pull down notification shade
   - Should show: "Community sensing active — starting BLE & Wi-Fi scans…"

---

## Test Execution

### Phase 1: Initial Detection (0-30 seconds)

**Time:** T=0 (Community Sensing just started)

1. **Watch notification:**
   - Within 8 seconds: "BLE: 1 scans" should appear
   - Check for "X detections" counter
   
2. **Expected first detection:**
   - **T=0-8s:** First BLE scan completes
   - **Notification:** "BLE: 1, Wi-Fi: 0 (1 detection)" (if AG-001 detected and reported)
   - **OR:** "BLE: 1, Wi-Fi: 0 (0 detections)" (if AG-001 not LOST or debounced from previous session)

3. **If 0 detections after first scan:**
   - Check User A's phone: Is AG-001 marked as LOST?
   - Check AG-001 tracker: Is it powered on and advertising?
   - Check backend logs: Did request arrive? What status code?

### Phase 2: Rapid Scan Cycles (30-90 seconds)

**Time:** T=15s, T=30s, T=45s, T=60s, T=75s

1. **Watch notification scan counter:**
   - **T=15s:** "BLE: 2 scans" (2nd scan completed)
   - **T=30s:** "BLE: 3 scans" (3rd scan completed)
   - **T=45s:** "BLE: 4 scans" (4th scan completed)
   - **T=60s:** "BLE: 5 scans" (5th scan completed)
   - **T=75s:** "BLE: 6 scans" (6th scan completed)

2. **Watch detection counter:**
   - **Expected:** Detections increment approximately every 30 seconds
   - **T=0s:** 1 detection (if first scan succeeded)
   - **T=30s:** 2 detections (debounce expired, 2nd detection reported)
   - **T=60s:** 3 detections (debounce expired, 3rd detection reported)

3. **Verify debounce is working (scans at T=15s, T=45s should be debounced):**
   - Notification should NOT show "2 detections" at T=15s
   - Notification should NOT show "3 detections" at T=45s
   - Detections should only increment every ~30 seconds, NOT every 15 seconds

### Phase 3: MongoDB Verification (after 90 seconds)

**Time:** After at least 3 detections reported

1. **Open MongoDB Compass:**
   - Connect to your MongoDB Atlas cluster
   - Navigate to database → `communitydetections` collection

2. **Filter for AG-001 detections by User B:**
   - Filter: `{ trackerId: 'AG-001', detectedBy: ObjectId('<User B's _id>') }`
   - Sort by: `createdAt: -1` (descending — newest first)

3. **Verify new records:**
   - Should see 3+ new documents with today's timestamps
   - Timestamps should be ~30 seconds apart:
     - Document 1: 11:59:08
     - Document 2: 11:59:38 (elapsed: 30s)
     - Document 3: 12:00:08 (elapsed: 30s)
   - Each document should contain:
     - `trackerId: 'AG-001'`
     - `detectedBy: <User B's ObjectId>`
     - `rssi: -XX` (negative integer)
     - `detectedAt: ISODate("...")`
     - `latitude: X.XXXX` (if GPS available)
     - `longitude: X.XXXX` (if GPS available)
     - `createdAt: ISODate("...")` (MongoDB auto-generated)
     - `updatedAt: ISODate("...")` (MongoDB auto-generated)

4. **Check for duplicates:**
   - NO two documents should have the same `detectedAt` timestamp
   - NO two documents should be created within the same 30-second window
   - If duplicates exist: Debounce is broken (should not happen)

### Phase 4: Extended Run (5-10 minutes)

**Time:** Let Community Sensing run for 5-10 minutes

1. **Watch notification scan counter:**
   - After 5 minutes: Should show ~20 scans (5×60÷15 = 20)
   - After 10 minutes: Should show ~40 scans (10×60÷15 = 40)

2. **Watch detection counter:**
   - After 5 minutes: Should show ~10 detections (5×60÷30 = 10)
   - After 10 minutes: Should show ~20 detections (10×60÷30 = 20)

3. **Verify MongoDB:**
   - Count documents: `db.communitydetections.countDocuments({ trackerId: 'AG-001', detectedBy: ObjectId('<User B>'), createdAt: { $gte: ISODate('2026-08-28T00:00:00Z') } })`
   - Should match detection counter in notification (±1 due to timing)

4. **Check battery usage:**
   - Settings → Battery → AssetGuard AI
   - Battery usage should be reasonable (<5% per hour)
   - If >10% per hour: Consider increasing scan interval to 20s or 30s

---

## Expected vs Actual Results

| Metric | Old (75s/60s) | New (15s/30s) | Actual (fill in) |
|--------|---------------|---------------|------------------|
| Scans per minute | 0.8 | 4 | ___ |
| Detections per minute | 0.8 | 2 | ___ |
| Scans in 5 minutes | 4 | 20 | ___ |
| Detections in 5 minutes | 4 | 10 | ___ |
| MongoDB docs in 5 min | 4 | 10 | ___ |
| Detection latency (avg) | ~37.5s | ~7.5s | ___ |
| Battery drain per hour | <2% | <5% | ___ |

---

## Success Criteria

✅ **BLE scans happen every 15 seconds** (notification counter increments 4× per minute)  
✅ **Detections happen every 30 seconds** (notification counter increments 2× per minute)  
✅ **MongoDB receives new records every ~30 seconds** (no duplicates within 30s window)  
✅ **Each record has RSSI, GPS, timestamp**  
✅ **Debounce prevents flooding** (scans at T=15s, T=45s, T=75s do NOT create MongoDB records)  
✅ **Background sensing remains automatic** (no button press required after initial start)  
✅ **Battery drain remains acceptable** (<5% per hour)  

---

## Troubleshooting

### Issue: Notification shows "0 detections" after multiple scans

**Possible causes:**
1. AG-001 is not marked as LOST → User A must mark it as LOST
2. AG-001 tracker is not advertising → Check battery, power on tracker
3. User B is the owner of AG-001 → Backend rejects (by design)
4. Backend not running → Start backend server
5. JWT expired → User B must logout and login again

**Diagnostic:**
- Connect User B's phone via USB: `adb logcat -s flutter`
- Look for: `[CommunityDetection] shouldReport(AG-001): YES/NO`
- Look for: `[Community] ► Submitting detection to backend:`
- Look for: `[Community] ◄ Response status: 404/403/500`

### Issue: Detections happen every 15 seconds (too frequent)

**Cause:** Debounce not working (should not happen if code is correct)

**Diagnostic:**
- Check logs: `[CommunityDetection] shouldReport(AG-001): ???`
- Should see NO every 15s for the same tracker
- Should see YES every 30s

**Fix:** Force-stop app, clear debounce map, restart Community Sensing

### Issue: Scans still happen every 75 seconds (not 15 seconds)

**Cause:** Old APK still installed (new APK not transferred correctly)

**Fix:**
1. Force-stop app
2. Uninstall completely
3. Reinstall new APK (verify timestamp: Aug 28, 11:59 AM)
4. Start Community Sensing again

### Issue: Battery drain is excessive (>10% per hour)

**Cause:** 15-second scans may be too aggressive for this device

**Fix:**
1. Stop Community Sensing
2. Increase scan interval to 20s or 30s (requires code change + rebuild)
3. Keep debounce at 30s
4. Rebuild APK and reinstall

---

## Post-Test Actions

### If successful:

1. **Document results:**
   - Fill in "Actual" column in table above
   - Note any unexpected behavior
   - Measure battery drain after 1 hour

2. **Keep running:**
   - Leave Community Sensing active on User B's phone
   - Monitor for 1-2 hours to confirm stability
   - Check MongoDB growth rate

3. **Optional: Remove verbose logging:**
   - Edit `community_detection_service.dart` and `community_sensing_service.dart`
   - Wrap debug logs in `if (kDebugMode) { ... }`
   - Rebuild APK for production use

### If unsuccessful:

1. **Capture logs:**
   - Flutter logs: `adb logcat -s flutter > flutter_logs.txt`
   - Backend logs: Copy terminal output to `backend_logs.txt`

2. **Check MongoDB:**
   - Export communitydetections collection (today's records only)
   - Count documents per tracker per user

3. **Rollback if necessary:**
   - Revert timing changes (75s/60s)
   - Rebuild APK
   - Test again

---

## Verification Checklist

Before reporting success, verify:

- [ ] Notification scan counter increments every 15 seconds
- [ ] Notification detection counter increments every ~30 seconds (not every 15s)
- [ ] MongoDB has 10+ new AG-001 documents after 5 minutes
- [ ] MongoDB documents are ~30 seconds apart (no closer than 29s)
- [ ] Each document has `rssi`, `detectedAt`, `latitude`, `longitude`
- [ ] No duplicate `detectedAt` timestamps within same 30-second window
- [ ] Backend logs show requests arriving every ~30 seconds (not every 15s)
- [ ] Battery drain is acceptable (<5% per hour)
- [ ] User B never pressed "Scan for Devices" button (automatic only)
- [ ] User A's manual "Scan for Devices" still works (not affected by this change)

---

## Files Modified (Summary)

**Flutter:**
1. `lib/utils/community_detection_config.dart` — debounce: 60s → 30s
2. `lib/services/community_sensing_service.dart` — scan interval: 75s → 15s (2 locations)

**Backend:**
- No changes required

**Total:** 3 numeric constants in 2 files

---

## Contact for Issues

If test fails or results are unexpected:
1. Capture full logs (Flutter + backend)
2. Export MongoDB records (today only)
3. Note exact failure point from flowchart in TIMING_ANALYSIS.md
4. Check Pre-Test Checklist — ensure all prerequisites met
