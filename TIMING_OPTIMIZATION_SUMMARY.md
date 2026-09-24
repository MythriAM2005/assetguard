# Timing Optimization Summary

**Date:** August 28, 2026  
**Status:** ✅ Implementation Complete  
**APK Ready:** Yes (built 11:59:05 AM)  

---

## What Changed

### Before (Original)
- **Scan interval:** 75 seconds
- **Debounce:** 60 seconds per tracker
- **Detections per hour:** ~48 (per continuously-present tracker)
- **Average latency:** ~37.5 seconds

### After (Optimized)
- **Scan interval:** 15 seconds (5× faster)
- **Debounce:** 30 seconds per tracker (2× faster cooldown)
- **Detections per hour:** ~120 (2.5× increase)
- **Average latency:** ~7.5 seconds (5× faster)

---

## Why the Change Was Needed

**User observation:** "19 scans, 0 detections"

After fixing the backend bug (`populate('owner')` → `populate('userId')`), the system worked but had **too much delay** between detections:
- First detection: Immediate (when Community Sensing starts)
- Second detection: 75 seconds later
- Subsequent detections: Every 75 seconds

For a lost asset tracking system, 75-second gaps are too slow. User A (asset owner) needs faster updates when User B (community member) is near the lost tracker.

---

## How It Works Now

### Scan Cycle (every 15 seconds)
```
T=0s    : Scan #1 starts → 8s BLE scan → AG-001 detected → HTTP POST → MongoDB ✓
T=15s   : Scan #2 starts → 8s BLE scan → AG-001 detected → DEBOUNCED (15s < 30s) ✗
T=30s   : Scan #3 starts → 8s BLE scan → AG-001 detected → HTTP POST → MongoDB ✓
T=45s   : Scan #4 starts → 8s BLE scan → AG-001 detected → DEBOUNCED (15s < 30s) ✗
T=60s   : Scan #5 starts → 8s BLE scan → AG-001 detected → HTTP POST → MongoDB ✓
...
```

**Key points:**
- BLE scans happen **4× per minute** (every 15 seconds)
- HTTP requests happen **2× per minute** (every 30 seconds, protected by debounce)
- MongoDB receives **2 documents per minute** per tracker (if continuously present)
- Battery impact: Minimal (<5% per hour expected)

---

## Files Modified

| File | Line | Change | Old Value | New Value |
|------|------|--------|-----------|-----------|
| `lib/utils/community_detection_config.dart` | 7 | Debounce interval | `60` | `30` |
| `lib/services/community_sensing_service.dart` | 163 | Foreground task repeat | `75000` | `15000` |
| `lib/services/community_sensing_service.dart` | 254 | Timer.periodic duration | `Duration(seconds: 75)` | `Duration(seconds: 15)` |

**Total:** 3 numeric constants in 2 files

**No changes to:**
- BLE scanning logic
- HTTP request construction
- Backend validation
- MongoDB schema
- Owner detection flow
- Manual "Scan for Devices"
- Security/ownership checks

---

## Safety Analysis

### What's Protected ✅

**Debounce still active:**
- Each tracker has a 30-second cooldown
- Prevents duplicate MongoDB records within 30s window
- Prevents backend flooding (max 120 requests/hour per tracker)

**Background sensing unchanged:**
- Still fully automatic (no button press required)
- Foreground service keeps running when app is backgrounded
- Notification remains visible

**Backend validation unchanged:**
- Asset must be LOST
- Detector cannot be the owner
- JWT authentication required
- All security gates still in place

### What's Increased ⚠️

**BLE scan frequency:**
- Old: Every 75 seconds
- New: Every 15 seconds
- Impact: Slightly higher battery usage (~5% increase expected)

**Network requests:**
- Old: ~48 per hour per tracker
- New: ~120 per hour per tracker
- Impact: Negligible (requests are small, ~500 bytes each)

**MongoDB growth:**
- Old: ~1,152 documents per day per tracker (if continuously detected)
- New: ~2,880 documents per day per tracker (if continuously detected)
- Impact: Negligible (documents are ~200 bytes each, ~576 KB/day per tracker)

---

## Expected Results

### User B's Phone (Community Member)

**Notification after 5 minutes:**
```
Community sensing active — BLE: 20 scans, 10 detections
```

**Notification after 10 minutes:**
```
Community sensing active — BLE: 40 scans, 20 detections
```

### MongoDB (communitydetections collection)

**After 5 minutes of continuous AG-001 presence:**
- 10 new documents
- Timestamps ~30 seconds apart
- Each with RSSI, GPS, detectedAt

**Example:**
```javascript
[
  { trackerId: 'AG-001', detectedBy: <User B>, rssi: -67, detectedAt: '2026-08-28T12:00:08Z', ... },
  { trackerId: 'AG-001', detectedBy: <User B>, rssi: -65, detectedAt: '2026-08-28T12:00:38Z', ... },
  { trackerId: 'AG-001', detectedBy: <User B>, rssi: -69, detectedAt: '2026-08-28T12:01:08Z', ... },
  { trackerId: 'AG-001', detectedBy: <User B>, rssi: -66, detectedAt: '2026-08-28T12:01:38Z', ... },
  ...
]
```

### User A's Phone (Asset Owner)

**Notifications:**
- Receives "Asset Detected" notification every ~30 seconds (instead of every 75 seconds)
- Can see AG-001's location updating more frequently in the app

---

## Test Procedure (Quick Reference)

### Pre-Test
1. User A: Ensure AG-001 is marked as **LOST**
2. User B: Install new APK (`app-debug.apk`, Aug 28 11:59 AM)
3. User B: Force-stop old app (clears debounce map)
4. User B: Login and start Community Sensing

### During Test (first 5 minutes)
1. Watch notification: Scans should increment every 15s
2. Watch notification: Detections should increment every ~30s
3. Monitor MongoDB: New documents every ~30s

### Success Criteria
- ✅ 20 scans after 5 minutes (old: 4 scans)
- ✅ 10 detections after 5 minutes (old: 4 detections)
- ✅ 10 MongoDB documents after 5 minutes (old: 4 documents)
- ✅ No duplicates within 30-second window
- ✅ Battery drain <5% per hour

---

## Rollback Plan

If battery drain is unacceptable or system becomes unstable:

**Option 1: Increase to 20s scans, keep 30s debounce**
```dart
// Moderate optimization (3× faster than original)
ForegroundTaskEventAction.repeat(20000)
Timer.periodic(const Duration(seconds: 20), ...)
debounceIntervalSeconds = 30; // unchanged
```

**Option 2: Increase to 30s scans, keep 30s debounce**
```dart
// Conservative optimization (2.5× faster than original)
ForegroundTaskEventAction.repeat(30000)
Timer.periodic(const Duration(seconds: 30), ...)
debounceIntervalSeconds = 30; // unchanged
```

**Option 3: Full revert**
```dart
// Back to original
ForegroundTaskEventAction.repeat(75000)
Timer.periodic(const Duration(seconds: 75), ...)
debounceIntervalSeconds = 60;
```

---

## Next Steps

1. **Install APK on User B's phone** (`build\app\outputs\flutter-apk\app-debug.apk`)
2. **Follow test procedure** in `TEST_PROCEDURE_TIMING_OPTIMIZATION.md`
3. **Monitor for 5-10 minutes** to confirm scan/detection rates
4. **Verify MongoDB** documents are being created correctly
5. **Check battery usage** after 1 hour of continuous running

**Full test procedure:** See `TEST_PROCEDURE_TIMING_OPTIMIZATION.md`  
**Timing analysis:** See `TIMING_ANALYSIS.md`  
**Diagnostic tools:** See `DIAGNOSIS_COMMUNITY_SENSING.md` (if issues arise)

---

## Questions & Answers

**Q: Will this drain User B's battery significantly?**  
A: Expected increase is <5% per hour. BLE scanning is low-power on modern Android. If battery drain is excessive, we can increase scan interval to 20s or 30s.

**Q: Will this flood the backend with requests?**  
A: No. Debounce limits each tracker to 2 requests per minute (120 per hour). Backend easily handles this.

**Q: Will this create duplicate MongoDB records?**  
A: No. Debounce prevents any two records for the same tracker within 30 seconds.

**Q: Does User B need to press any button?**  
A: No. Once Community Sensing is started (one-time toggle), everything is automatic.

**Q: Will this affect User A's manual "Scan for Devices"?**  
A: No. Owner detection flow is completely separate and unchanged.

**Q: What if AG-001 is not LOST?**  
A: Backend returns 404, Flutter logs it, and no MongoDB record is created. This is by design.

**Q: Can we make it even faster (e.g., 5-second scans)?**  
A: Technically yes, but battery drain would be significant. 15s is a good balance. If needed, we can try 10s scans with 20s debounce.

**Q: Will older APKs still work?**  
A: Yes, but they'll use the old 75s/60s timing. For the optimization, User B must install the new APK.

---

## Implementation Status

✅ Code changes complete  
✅ APK built and ready  
✅ Test procedure documented  
✅ Timing analysis documented  
✅ Rollback plan defined  
⏳ Two-phone testing pending  
⏳ Battery impact measurement pending  
⏳ MongoDB growth rate verification pending  

**Ready for testing on physical devices.**
