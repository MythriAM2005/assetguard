# Two-Phone Owner Notification Test Procedure

**Date:** August 28, 2026  
**APK:** `build\app\outputs\flutter-apk\app-debug.apk` (built 12:21:06 PM)  
**Feature:** User A (asset owner) receives notifications when User B (community member) detects AG-001  

---

## Test Overview

**Goal:** Verify that when User B automatically detects AG-001 in the background, User A receives an in-app notification with detection details and can navigate to the asset.

**Flow:**
```
User B detects AG-001 (automatic background)
    ↓
Backend creates community detection (MongoDB communitydetections)
    ↓
Backend creates notification for User A (MongoDB notifications)
    ↓
User A's app polls for unread count (every 15 seconds)
    ↓
Badge appears on notification bell (home screen)
    ↓
User A taps bell → sees notification list
    ↓
User A taps notification → navigates to AG-001 asset details
    ↓
Notification marked as read
```

---

## Prerequisites

### User A (Asset Owner)

1. **User A account exists** (e.g., usera@example.com)
2. **User A owns AG-001** in MongoDB:
   ```javascript
   db.assets.findOne({ trackerId: 'AG-001' })
   // Verify userId matches User A's ObjectId
   ```
3. **AG-001 status is LOST:**
   - User A's phone → Login → My Assets → Long-press AG-001 → Mark as Lost
   - OR MongoDB: `db.assets.updateOne({ trackerId: 'AG-001' }, { $set: { status: 'LOST' } })`

### User B (Community Member)

1. **User B account exists** (e.g., userb@example.com)
2. **User B is NOT the owner of AG-001** (different user)
3. **New APK installed** (Aug 28, 12:21 PM with 15s notification polling)

### AG-001 Tracker

1. **Powered on** and advertising BLE
2. **Within 5-10 meters** of User B's phone during test
3. **Battery sufficient** for continuous advertising

### Backend

1. **Backend server running** on `http://10.135.90.221:5000` (or correct IP)
2. **MongoDB connected** and accessible
3. **Terminal visible** to observe backend logs

---

## Test Procedure

### Step 1: Prepare User A's Phone

**1.1 Install APK (if not already installed)**
- Transfer `app-debug.apk` to User A's phone
- Install APK (allow unknown sources if prompted)

**1.2 Login as User A**
- Open AssetGuard AI
- Login with User A credentials (usera@example.com)

**1.3 Navigate to Home Screen**
- ⚠️ **CRITICAL:** Must open home screen to start notification polling
- Verify home screen shows "Hello, [User A name]"
- Verify notification bell icon visible in top-right corner

**1.4 Check Current Notifications (Optional)**
- Tap notification bell
- Note current unread count (if any)
- Return to home screen

**1.5 Keep App Open or Backgrounded**
- App can be minimized but must remain logged in
- Notification polling continues in background

### Step 2: Prepare User B's Phone

**2.1 Install APK (if needed)**
- Transfer `app-debug.apk` to User B's phone
- Uninstall old version if present
- Install new APK

**2.2 Force-Stop Old App (if updating)**
- Settings → Apps → AssetGuard AI → Force Stop
- This clears the in-memory debounce map

**2.3 Login as User B**
- Open AssetGuard AI
- Login with User B credentials (userb@example.com)

**2.4 Start Community Sensing**
- Navigate to Settings (bottom nav)
- Tap "Community Sensing"
- Toggle ON or tap "Start Community Sensing"
- Grant permissions if prompted (Location, Bluetooth, Notifications)

**2.5 Verify Community Sensing Active**
- Pull down notification shade
- Should see: "AssetGuard Community Sensing"
- Initial message: "Community sensing active — starting BLE & Wi-Fi scans…"

### Step 3: Monitor Detection (User B)

**3.1 Wait for First BLE Scan**
- Within 8 seconds, first scan completes
- Notification updates: "BLE: 1 scans, Wi-Fi: 0 (X detections)"

**3.2 Check Detection Count**
- If AG-001 is detected and LOST: "1 detection"
- If AG-001 is not detected or not LOST: "0 detections"

**3.3 Wait for Second Scan**
- At T=15s, second scan runs
- At T=30s, third scan runs (if first detection succeeded, this should create a new detection after debounce)
- Notification should show increasing scan count: "BLE: 2 scans", "BLE: 3 scans", etc.

**3.4 Verify Detection Pattern**
- Detections should increment every ~30 seconds (debounce working)
- NOT every 15 seconds (would indicate debounce broken)

### Step 4: Monitor Notification (User A)

**4.1 Watch Home Screen Notification Bell**
- Look at top-right corner
- Wait up to 15 seconds after User B's detection

**4.2 Expected: Red Badge Appears**
- Small red circle with number "1" (or increment if already had unread)
- Badge appears because polling fetched new unread count

**4.3 If Badge Doesn't Appear After 15 Seconds**
- Force refresh: Pull down on home screen (if refresh supported)
- OR: Navigate away and back to home screen
- OR: Tap notification bell manually to fetch

**4.4 Tap Notification Bell**
- Opens Notifications Screen
- Should show list of notifications sorted by unread first

### Step 5: Verify Notification Details (User A)

**5.1 Check New Notification**
- Should appear at top of list (unread)
- Background color: Blue/light blue (unread state)
- Icon: Location pin (blue)
- Title: **"Asset Detected"**
- Timestamp: "Just now" or "Xm ago"
- Red dot indicator on right side

**5.2 Check Notification Message**
- Should read: **"Your [asset name] (AG-001) was detected at [latitude], [longitude]."**
- Example: "Your Laptop (AG-001) was detected at 1.3521, 103.8198."

**5.3 Check Notification Details (Info Chips)**
- **Tracker ID chip:** AG-001
- **RSSI chip:** -XX dBm (negative number, e.g., -67 dBm)
- **GPS chip:** latitude, longitude coordinates
- **Time chip:** Detection timestamp (e.g., "Aug 28, 12:25 PM")

**5.4 Verify User B's Identity NOT Shown**
- No mention of User B's name or email
- No "Detected by" field
- Privacy maintained ✅

### Step 6: Tap Notification (User A)

**6.1 Tap the Notification Card**
- Notification background changes from blue to white/gray (marked as read)
- Red dot disappears
- Navigation starts to Asset Details Screen

**6.2 Verify Asset Details Screen Opens**
- Should show AG-001 details:
  - Asset name (e.g., "Laptop")
  - Category (e.g., "Electronics")
  - Tracker ID: AG-001
  - Status: LOST (red indicator)
  - Description
  - Last detected info (if available)

**6.3 Verify Correct Asset**
- Confirm this is the AG-001 asset owned by User A
- Confirm it's NOT a different asset

**6.4 Return to Notifications Screen**
- Tap back button or swipe back
- Should return to Notifications Screen

**6.5 Verify Notification Marked as Read**
- Notification background: white/gray (read state)
- Blue background gone
- Notification moved below other unread notifications (if any)

**6.6 Check Badge Count**
- Return to home screen
- Badge count should decrement by 1
- If was "1", badge should disappear completely

### Step 7: Backend Verification

**7.1 Check Backend Terminal Logs**

Look for community detection creation:
```
[Community] ════════════════════════════════════════
[Community] INCOMING DETECTION REQUEST
[Community]   trackerId  : AG-001
[Community]   detectedBy : <User B ObjectId> (userb@example.com)
[Community] ════════════════════════════════════════
[Community] ✓ Asset found: <Asset ObjectId>
[Community]   name       : Laptop
[Community]   status     : LOST
[Community]   owner      : <User A ObjectId> (usera@example.com)
[Community] ✓ All checks passed — creating detection record
[Community] ✓ Detection created in MongoDB: <Detection ObjectId>
[Community] Owner notification created: <Notification ObjectId>
[Community] Notification sent to: usera@example.com
[Community]   title   : Asset Detected
[Community]   message : Your Laptop (AG-001) was detected at 1.3521, 103.8198.
```

Look for User A polling:
```
[Notification] User polling for unread count: usera@example.com
[Notification] Unread count for usera@example.com : 1
```

Look for User A fetching notifications:
```
[Notification] User fetching notifications: usera@example.com
[Notification]   unreadOnly: false
[Notification]   limit: 50
[Notification] Returning 5 notifications, 1 unread
```

**7.2 Check MongoDB communitydetections Collection**

```javascript
db.communitydetections.find({ trackerId: 'AG-001' }).sort({ createdAt: -1 }).limit(1).pretty()
```

Expected document:
```javascript
{
  _id: ObjectId("..."),
  trackerId: "AG-001",
  assetId: ObjectId("<AG-001 asset _id>"),
  detectedBy: ObjectId("<User B _id>"),
  rssi: -67,
  remoteId: "AA:BB:CC:DD:EE:FF",
  detectedAt: ISODate("2026-08-28T04:25:15.000Z"),
  latitude: 1.3521,
  longitude: 103.8198,
  createdAt: ISODate("2026-08-28T04:25:15.123Z"),
  updatedAt: ISODate("2026-08-28T04:25:15.123Z")
}
```

**7.3 Check MongoDB notifications Collection**

```javascript
db.notifications.find({ trackerId: 'AG-001' }).sort({ createdAt: -1 }).limit(1).pretty()
```

Expected document:
```javascript
{
  _id: ObjectId("..."),
  recipient: ObjectId("<User A _id>"),
  type: "asset_detected",
  title: "Asset Detected",
  message: "Your Laptop (AG-001) was detected at 1.3521, 103.8198.",
  assetId: ObjectId("<AG-001 asset _id>"),
  detectionId: ObjectId("<detection _id from above>"),
  trackerId: "AG-001",
  latitude: 1.3521,
  longitude: 103.8198,
  rssi: -67,
  detectedAt: ISODate("2026-08-28T04:25:15.000Z"),
  read: false,  // or true if User A already tapped it
  createdAt: ISODate("2026-08-28T04:25:15.123Z"),
  updatedAt: ISODate("2026-08-28T04:25:15.123Z")
}
```

Verify:
- ✅ `recipient` is User A's ObjectId (NOT User B)
- ✅ `trackerId` is AG-001
- ✅ `message` includes asset name, tracker ID, coordinates
- ✅ `latitude` and `longitude` are present
- ✅ `rssi` is negative integer
- ✅ `detectedAt` matches detection time
- ✅ `read: false` initially, then `read: true` after User A tapped it

### Step 8: Flutter Logs (Optional — Detailed Diagnostics)

**8.1 Connect User A's Phone via USB**
```bash
adb logcat -s flutter
```

**8.2 Look for Notification Service Logs**

Polling started:
```
[Notification] Starting polling (15s interval)
[Notification] Polling for unread count...
[Notification] Unread count: 0
```

After detection:
```
[Notification] Polling for unread count...
[Notification] Unread count: 1
[Notification] Fetched 5 notifications, 1 unread
```

After marking as read:
```
[Notification] Marked <notification-id> as read
[Notification] Polling for unread count...
[Notification] Unread count: 0
```

**8.3 Look for Community Detection Logs (User B)**

If monitoring User B's phone:
```
[Community BLE] ═══ Scan started ═══
[Community BLE] Device discovered: ... trackerId: AG-001
[Community BLE] ✓ AssetGuard tracker matched: AG-001
[CommunityDetection] shouldReport(AG-001): YES (never reported)
[Community] ► Submitting detection to backend:
[Community]   trackerId  : AG-001
[Community]   rssi       : -67 dBm
[Community] ◄ Response status: SUCCESS (201/200)
[Community]   message    : Community detection recorded. Asset owner will be notified.
```

---

## Success Criteria

### Acceptance Criteria

✅ **A. Detection works** — User B detects AG-001 automatically (community sensing)  
✅ **B. MongoDB detection created** — communitydetections has new record  
✅ **C. Owner resolved correctly** — Notification recipient is User A (asset.userId)  
✅ **D. Notification created** — MongoDB notifications has new record for User A  
✅ **E. Notification retrieved** — User A's app polls and fetches unread count  
✅ **F. Badge appears** — Red badge with count shows on notification bell  
✅ **G. Notification visible** — User A sees notification in list (unread = blue)  
✅ **H. Details correct** — Title, message, tracker ID, GPS, RSSI, timestamp all present  
✅ **I. Navigation works** — Tapping notification opens AG-001 asset details  
✅ **J. Mark as read** — Notification background changes, badge decrements  
✅ **K. Privacy maintained** — User B's identity NOT shown anywhere  
✅ **L. Security maintained** — Only User A can see their notifications  

### Timing Expectations

| Event | Time | Expected Result |
|-------|------|-----------------|
| User B detection | T=0 | Backend receives detection, creates notification |
| User A polling #1 | T=15s | Badge appears (or next poll) |
| User A polling #2 | T=30s | Badge visible (if missed first poll) |
| User A taps bell | T=45s | Notification list opens, new notification at top |
| User A taps notification | T=60s | Asset details open, notification marked read |
| User A returns home | T=75s | Badge count decremented |

**Maximum notification latency:** 15 seconds (polling interval)

---

## Troubleshooting

### Issue: User A sees NO badge after 30 seconds

**Check #1: Did User A open home screen?**
- Polling only starts when home screen (MainShell) loads
- Solution: User A must open home screen after login

**Check #2: Is User A authenticated?**
- JWT might be expired
- Solution: User A logs out and logs back in

**Check #3: Was notification created in MongoDB?**
- Query: `db.notifications.find({ recipient: ObjectId("<User A>") }).sort({ createdAt: -1 }).limit(1)`
- If missing: Backend notification creation failed (check backend logs)
- If present: Flutter polling issue (check Flutter logs)

**Check #4: Is backend reachable?**
- Check `ApiConfig.baseUrl` in Flutter app
- Ping backend: `curl http://10.135.90.221:5000/api/health`
- If unreachable: Wrong IP or backend not running

**Check #5: Backend logs show notification creation?**
- If backend logs show notification created but User A doesn't see it
- Check recipient ObjectId matches User A's _id exactly

### Issue: Badge shows wrong count

**Cause:** Cached count not refreshed

**Solution:**
- Pull-to-refresh on notifications screen
- OR Force-stop and restart app
- OR Check MongoDB: `db.notifications.countDocuments({ recipient: ObjectId("<User A>"), read: false })`

### Issue: Tapping notification doesn't navigate

**Cause:** Asset not found or deleted

**Flutter logs:**
```
[Notification] Failed to load asset details
```

**Solution:**
- Verify asset exists: `db.assets.findById("<assetId from notification>")`
- If missing: Asset was deleted after notification created (edge case)

### Issue: Multiple notifications for same detection

**Cause:** Debounce not working (should not happen)

**Solution:**
- Check debounce interval: `CommunityDetectionConfig.debounceIntervalSeconds = 30`
- Check logs for `shouldReport(AG-001): NO (debounced)`
- If all show YES: Debounce broken (app not preserving state)

### Issue: User B's identity visible

**Cause:** UI bug (should not happen — detectedBy field not shown)

**Solution:**
- Check notifications_screen.dart — verify detectedBy not rendered
- If visible: Bug in notification card UI (needs fix)

---

## Post-Test Actions

### If Successful

1. **Document results:**
   - Screenshot of notification bell with badge
   - Screenshot of notification list
   - Screenshot of notification details
   - Screenshot of asset details opened from notification

2. **Verify MongoDB:**
   - Count detection documents: `db.communitydetections.countDocuments({ trackerId: 'AG-001', createdAt: { $gte: ISODate('2026-08-28T00:00:00Z') } })`
   - Count notification documents: `db.notifications.countDocuments({ trackerId: 'AG-001', createdAt: { $gte: ISODate('2026-08-28T00:00:00Z') } })`

3. **Optional: Reduce polling interval further (if needed)**
   - Current: 15 seconds
   - Could reduce to 10 seconds for even faster notifications
   - Trade-off: Slightly more battery drain

### If Unsuccessful

1. **Capture logs:**
   - Backend terminal output (full session)
   - Flutter logs (adb logcat -s flutter > user_a_logs.txt)
   - User B logs (adb logcat -s flutter > user_b_logs.txt)

2. **Export MongoDB documents:**
   - communitydetections (AG-001, today only)
   - notifications (User A, today only)
   - assets (AG-001 document)

3. **Check flow diagram:**
   - Identify exactly where flow stopped
   - Compare expected vs actual behavior at each stage

4. **Review diagnosis document:**
   - `NOTIFICATION_FLOW_DIAGNOSIS.md` has detailed troubleshooting

---

## Files Modified (Summary)

**Flutter:**
- `lib/services/notification_service.dart` — Reduced polling from 30s to 15s, added diagnostic logs

**Backend:**
- `backend/src/controllers/notificationController.js` — Added diagnostic logs for polling and fetching

**Total:** 2 files, minimal changes (only polling timing + logging)

**No changes to:**
- Notification creation logic (already working)
- Notification model/schema (already correct)
- Notification UI (already implemented)
- Community sensing (untouched)
- BLE scanning (untouched)
- Detection timing (untouched)

---

## Next Steps

1. **Install APK on both phones** (Aug 28, 12:21 PM build)
2. **Follow test procedure** above step-by-step
3. **Verify all acceptance criteria** checked
4. **Capture success screenshots** or failure logs
5. **Report results** with MongoDB verification

**Expected outcome:** ✅ Complete end-to-end owner notification flow working correctly.
