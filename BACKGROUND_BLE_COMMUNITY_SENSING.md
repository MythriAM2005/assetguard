# Background BLE Community Sensing Implementation

## Executive Summary

Successfully implemented **automatic background BLE community sensing** that detects lost AssetGuard trackers without requiring users to open the Nearby Devices screen or press "Scan for Devices". The service runs in the background using an Android foreground service with a persistent notification.

## Problem Statement

**BEFORE:**
- User B had to manually open "Nearby Devices" and press "Scan for Devices"
- Community detection was manual and user-initiated
- Lost trackers could only be detected when users actively scanned
- No automatic background detection

**AFTER:**
- User B logs in → Community sensing starts automatically
- BLE scanning happens in the background every 75 seconds
- Lost trackers are automatically detected and reported
- User B does NOT need to open Nearby Devices
- User B does NOT need to know which trackers exist
- Persistent notification shows community sensing is active

## Architecture Overview

### Technology Stack

**BLE Package:** `flutter_blue_plus: ^1.35.5`
- Supports foreground BLE scanning only
- Requires main Flutter isolate (platform channels)
- Cannot run in background Dart isolate

**Background Service:** `flutter_foreground_task: ^8.15.0`
- Provides Android foreground service infrastructure
- Runs a background timer/repeating task
- Communicates between main isolate and task isolate via SendPort

**Target Android Versions:** Android 8+ (likely Android 13-15 based on Flutter 3.47.0)

### Implementation Strategy

Due to `flutter_blue_plus` limitations (requires platform channels, cannot run in isolate), the implementation uses a **hybrid approach**:

1. **Foreground Task Isolate**: Handles Wi-Fi scans and timer events
2. **Main Flutter Isolate**: Performs BLE scans (requires platform channels)
3. **Inter-Isolate Communication**: Task isolate sends "perform BLE scan" messages to main isolate

```
┌─────────────────────────────────────────────┐
│        Foreground Task Isolate              │
│  (flutter_foreground_task background timer)│
│                                             │
│  • Runs every 75 seconds                    │
│  • Performs Wi-Fi scans                     │
│  • Sends "performBleScan" message to main   │
│  • Updates notification with scan counts    │
└──────────────┬──────────────────────────────┘
               │ SendPort
               ↓
┌─────────────────────────────────────────────┐
│          Main Flutter Isolate               │
│     (platform channels available)           │
│                                             │
│  • Receives "performBleScan" message        │
│  • Calls flutter_blue_plus scan()           │
│  • Filters AssetGuard trackers (AG-XXX)     │
│  • Reports community detections             │
│  • Sends "bleScanCompleted" back to task    │
└─────────────────────────────────────────────┘
```

## Files Changed

### 1. `lib/services/community_sensing_service.dart`
**Major Refactoring:**

**Added:**
- BLE community sensing capability
- Inter-isolate communication for BLE scans
- Automatic background BLE scanning every 75 seconds
- AssetGuard tracker filtering (AG-XXX pattern)
- Community detection reporting
- Scan count tracking (separate for BLE and Wi-Fi)

**Changed:**
- Task handler now triggers BLE scans via SendPort messages
- Notification channel description updated to include "BLE & Wi-Fi"
- Added `bluetoothPermissionDenied` to start result enum
- Scan interval changed from 90s to 75s for better responsiveness

**Key Methods:**
```dart
// Main isolate - handle BLE scan requests from task isolate
void _handleDataFromTask(dynamic data)

// Main isolate - perform actual BLE scan using flutter_blue_plus
Future<void> _performBleScan()

// Task isolate - send BLE scan request to main isolate
void onRepeatEvent(DateTime timestamp)

// Task isolate - receive BLE scan completion from main isolate
void onReceiveData(Object data)
```

### 2. `lib/services/permission_service.dart`
**Added:**
- Automatic community sensing startup after login
- `_startCommunitySensingIfNeeded()` method
- Integrated with existing permission flow

**Behavior:**
- After successful login and permission grant, automatically starts community sensing
- If permissions already granted, starts community sensing immediately
- If permissions denied, logs warning but doesn't block navigation
- Non-blocking startup (doesn't delay navigation)

### 3. `lib/screens/nearby_devices_screen.dart`
**Added:**
- Handle new `bluetoothPermissionDenied` case in community sensing toggle

**No Changes Needed:**
- "Scan for Devices" button remains unchanged
- Manual scanning still works for owners
- Community sensing toggle UI remains unchanged

## Permissions

### Required Permissions (Already Declared)
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Permission Request Flow
1. User logs in
2. Permission dialogs appear:
   - Bluetooth Scan (Android 12+)
   - Bluetooth Connect (Android 12+)
   - Location (all Android versions)
3. User grants permissions
4. **Community sensing starts automatically**
5. Persistent notification appears: "AssetGuard Community Sensing - Community sensing active — starting BLE & Wi-Fi scans…"

## Community Detection Flow

### Automatic Background Detection

```
User A: Marks AG-001 as LOST
         ↓
User B: Logs into AssetGuard
         ↓
         Grants permissions
         ↓
         Community sensing starts automatically
         ↓
         Foreground service notification appears
         ↓
         User B carries phone normally
         ↓
         [Every 75 seconds]
         ↓
         Task isolate timer fires
         ↓
         Sends "performBleScan" message to main isolate
         ↓
         Main isolate performs BLE scan (8 seconds)
         ↓
         Detects all BLE devices
         ↓
         Filters for AssetGuard trackers (AG-XXX pattern or known IDs)
         ↓
         For each AssetGuard tracker:
           ↓
           Check debounce (60s interval)
           ↓
           POST /api/community/detections
             {
               trackerId: "AG-001",
               rssi: -65,
               remoteId: "XX:XX:XX:XX:XX:XX",
               detectedAt: "2026-08-27T10:30:00Z"
             }
           ↓
           Backend verifies:
             • Asset exists globally (cross-user lookup)
             • Asset status is LOST
             • Detector is NOT the owner
             • Creates CommunityDetection record
           ↓
         Updates notification: "BLE: 1, Wi-Fi: 1 (1 detection)"
```

### Backend Processing

**Endpoint:** `POST /api/community/detections`

**Backend Logic (NOT MODIFIED):**
1. Look up asset by `trackerId` (cross-user, global lookup)
2. Verify asset status is `LOST`
3. Verify requesting user is NOT the asset owner
4. Create `CommunityDetection` record:
   ```javascript
   {
     asset: ObjectId (User A's asset),
     detectedBy: ObjectId (User B),
     trackerId: "AG-001",
     rssi: -65,
     detectedAt: Date,
     remoteId: "XX:XX:XX:XX:XX:XX"
   }
   ```
5. Return 201 Created or 404 Not Found (asset not LOST or not found)

### Debouncing

**Configuration:** `lib/utils/community_detection_config.dart`
```dart
static const int debounceIntervalSeconds = 60;
```

**Behavior:**
- Same tracker detected multiple times within 60 seconds → only first detection reported
- Prevents flooding backend with duplicate detections
- In-memory debounce map: `Map<String, DateTime>`

## Scan Timing & Frequency

### Scan Intervals
- **BLE Scan Duration:** 8 seconds (per scan)
- **Scan Frequency:** Every 75 seconds
- **Effective Duty Cycle:** ~10.7% (8s scan / 75s interval)

### Battery Optimization
- Scans are periodic, not continuous
- 75-second interval balances responsiveness vs battery
- Foreground service prevents Android from killing the process
- Wi-Fi scans run concurrently with BLE scans

### Android Throttling
- Android may throttle scan frequency on some devices
- Battery optimization settings may affect scan reliability
- Foreground service with notification maximizes reliability

## Tracker Identification

### AssetGuard Tracker Detection

**Criteria for "AssetGuard tracker":**
1. **Tracker ID starts with "AG-"** (e.g., AG-001, AG-002)
   - Matches the naming convention
   - Case-insensitive matching
2. **OR known tracker ID** from user's registered assets
   - Handles custom tracker IDs

**Implementation:**
```dart
final assetGuardDevices = devices.where((device) {
  return device.trackerId.toUpperCase().startsWith('AG-') ||
         knownTrackerIds.contains(device.trackerId);
}).toList();
```

**Ignored Devices:**
- Random Bluetooth devices (phones, headphones, etc.)
- Non-AssetGuard BLE beacons
- Devices without AG-XXX pattern

### Name Resolution

**Priority (from `ble_service.dart`):**
1. Advertisement name (`advName`)
2. Platform cached name (`platformName`)
3. Service UUID match (ESP32 UUID)
4. MAC address (last resort)

## Notification

### Persistent Notification

**Android Requirement:**
- Foreground services MUST show a persistent notification
- User cannot dismiss it while service is running
- Only disappears when service stops

**Notification Details:**
- **Channel:** "Community Sensing"
- **Title:** "AssetGuard Community Sensing"
- **Text:** "Community sensing active — BLE: 2, Wi-Fi: 3 (1 detection)"
- **Priority:** LOW (doesn't interrupt user)
- **Importance:** LOW (silent, no sound/vibration)

**Updates:**
- Notification text updates after each scan cycle
- Shows BLE scan count, Wi-Fi scan count, and detection count
- Example: "BLE: 5, Wi-Fi: 5 (2 detections)"

## Ownership & Security

### Owner vs Community Detection

**Owner's Own Tracker:**
- User A owns AG-001
- User A's phone detects AG-001
- **NO community detection created**
- Backend rejects with 404 (asset not LOST or user is owner)

**Community Detection (Other User's Lost Tracker):**
- User A owns AG-001, marks it LOST
- User B's phone detects AG-001
- **Community detection created**
- Backend accepts and creates record

**NOT LOST Asset:**
- User A owns AG-001, status is ACTIVE
- User B's phone detects AG-001
- Backend rejects with 404 (asset not LOST)
- **NO community detection created**

### Backend Verification (Unchanged)

The backend performs ALL security checks:
- ✅ Asset lookup (cross-user, global)
- ✅ Status verification (must be LOST)
- ✅ Ownership verification (detector ≠ owner)
- ✅ Duplicate detection prevention

The app does NOT perform ownership checks client-side.

## Service Lifecycle

### Start Conditions
1. User completes login
2. Permissions granted
3. `PermissionService.requestPermissionsAfterLogin()` completes
4. **Automatic:** `CommunitySensingService.instance.start()` called
5. Foreground service starts
6. Notification appears

### Stop Conditions
1. User manually stops community sensing (toggle in Nearby Devices)
2. User logs out (NOT IMPLEMENTED YET - see Recommendations)
3. User force-stops the app
4. Android kills the app process (low memory, battery optimization)

### Survival Scenarios

| Scenario | Community Sensing Survives? |
|----------|----------------------------|
| App minimized | ✅ Yes |
| Screen locked | ✅ Yes |
| Switching apps | ✅ Yes |
| Navigation within app | ✅ Yes |
| Android kills process (low memory) | ❌ No |
| User force-stops app | ❌ No |
| Device reboot | ❌ No (autoRunOnBoot: false) |
| Battery optimization kills app | ❌ No |

### Restart Behavior

**After Process Kill:**
- User reopens app
- Auto-login via stored JWT
- Permissions already granted (no dialogs)
- **Community sensing restarts automatically**
- Notification reappears

## Testing

### Manual Test Plan

#### TEST 1: Automatic Start After Login
```
1. Fresh install / clear app data
2. Login as User B
3. Grant Bluetooth + Location permissions
4. Wait for login to complete
5. ✅ VERIFY: Navigate to Home
6. ✅ VERIFY: Notification appears: "AssetGuard Community Sensing"
7. Pull down notification shade
8. ✅ VERIFY: Notification shows "Community sensing active — starting BLE & Wi-Fi scans…"
```

#### TEST 2: Background Detection (Two Phones Required)

**Setup:**
- Phone A: User A logged in, AG-001 registered
- Phone B: User B logged in

**Steps:**
```
Phone A:
1. Mark AG-001 as LOST
2. Leave AG-001 tracker broadcasting

Phone B:
1. Login as User B
2. Grant permissions
3. ✅ VERIFY: Notification appears
4. Lock screen / minimize app
5. Carry Phone B near AG-001
6. Wait 75-90 seconds (one scan cycle)

MongoDB Verification:
7. Check communitydetections collection:
   ✅ VERIFY: New document exists:
      - assetId: User A's AG-001 ObjectId
      - detectedBy: User B's ObjectId
      - trackerId: "AG-001"
      - rssi: (BLE signal strength)
      - detectedAt: (timestamp)
      - remoteId: (ESP32 MAC address)

Phone B Notification:
8. Pull down notification shade
9. ✅ VERIFY: Notification updated:
   "Community sensing active — BLE: 1, Wi-Fi: 1 (1 detection)"
```

#### TEST 3: Owner's Own Tracker (No Community Detection)
```
Phone A:
1. User A logged in
2. AG-001 registered to User A
3. Mark AG-001 as LOST
4. ✅ VERIFY: Community sensing notification appears
5. Move Phone A near AG-001
6. Wait 75-90 seconds

MongoDB Verification:
7. ✅ VERIFY: NO new community detection created
8. ✅ VERIFY: Backend rejects (404) because detector is owner

Debug Logs:
9. ✅ VERIFY: "[CommunityDetection] Tracker AG-001 not LOST or not found (status 404) — skipping"
```

#### TEST 4: NOT LOST Asset
```
Phone A:
1. User A owns AG-001
2. Status: ACTIVE (NOT LOST)

Phone B:
1. User B logged in
2. Move Phone B near AG-001
3. Wait 75-90 seconds

MongoDB Verification:
4. ✅ VERIFY: NO community detection created
5. ✅ VERIFY: Backend rejects (404) because status is ACTIVE
```

#### TEST 5: Debouncing
```
Phone B:
1. User B logged in, near AG-001 (LOST tracker owned by User A)
2. First scan cycle (t=0s)
   ✅ VERIFY: Detection created
3. Wait 30 seconds
4. Trigger manual scan or wait for next cycle (t=75s)
   ✅ VERIFY: Detection NOT reported (within 60s debounce)
5. Wait another 45 seconds (total 75s + debounce)
6. Next scan cycle
   ✅ VERIFY: Detection reported again (debounce expired)

Debug Logs:
✅ VERIFY: "[CommunitySensing] Skipping AG-001 (debounced)"
```

#### TEST 6: Non-AssetGuard Devices Ignored
```
Setup:
- Random Bluetooth devices nearby (phone, headphones, etc.)

Phone B:
1. User B logged in
2. BLE scan detects 10+ devices
3. Only 1 is an AssetGuard tracker (AG-001)

✅ VERIFY: Only AG-001 is reported
✅ VERIFY: Other devices ignored
✅ VERIFY: Debug log: "[CommunitySensing] AssetGuard trackers detected: 1"
```

#### TEST 7: App Backgrounded / Screen Locked
```
Phone B:
1. User B logged in
2. Community sensing active
3. Lock screen
4. Wait 5+ minutes
5. Unlock phone
6. Pull down notification

✅ VERIFY: Notification shows updated scan counts
✅ VERIFY: BLE scan count incremented
✅ VERIFY: Service survived screen lock
```

#### TEST 8: Process Kill & Restart
```
Phone B:
1. User B logged in
2. Community sensing active
3. Force-stop app (Settings → Apps → AssetGuard → Force Stop)
4. Reopen app
5. ✅ VERIFY: Auto-login happens
6. ✅ VERIFY: No permission dialogs (already granted)
7. ✅ VERIFY: Community sensing restarts automatically
8. ✅ VERIFY: Notification reappears
```

### Debug Logging

**Key Log Messages:**
```
[Permissions] Starting community sensing automatically...
[CommunitySensing] Foreground service started successfully
[CommunitySensing] BLE scan requested by foreground task
[CommunitySensing] Starting BLE scan (known trackers: 2)
[BleService] Device found: AG-001, rssi: -65 dBm
[CommunitySensing] BLE scan complete: 5 devices found
[CommunitySensing] AssetGuard trackers detected: 1
[CommunitySensing] Reported AG-001
[CommunitySensing] BLE scan complete: 1 detections reported
```

## Android Limitations & Constraints

### Known Limitations

❌ **Cannot Survive Process Termination**
- If Android kills the app process (low memory, battery optimization), community sensing stops
- User must reopen the app to restart
- Workaround: Auto-login and auto-restart on app reopen (implemented)

❌ **Requires Persistent Notification**
- Android requirement for foreground services
- User sees notification permanently while community sensing is active
- Cannot be hidden or dismissed

❌ **Battery Impact**
- Continuous BLE + Wi-Fi scanning drains battery
- 75-second scan interval is a compromise
- Users may need to charge more frequently

⚠️ **Android Throttling**
- Android may throttle scan frequency on battery saver mode
- Some manufacturers (Samsung, Xiaomi) have aggressive battery optimization
- Scan reliability may vary by device

⚠️ **BLE Range Limitations**
- BLE range: typically 10-30 meters indoors
- Walls, obstacles reduce range
- Must be physically close to detect trackers

⚠️ **No Cross-Process Persistence**
- Service runs within the app process
- If process dies, service dies
- Cannot run independently like a native Android service

### Why Not Use Native Android Service?

**flutter_blue_plus Limitation:**
- Requires Flutter platform channels
- Platform channels require the Flutter engine
- Flutter engine requires the app process
- Cannot run in a separate native Android service process

**Alternative Considered:**
- Write native Android code using Kotlin/Java
- Use Android BluetoothLeScanner directly
- Complexity: Would require maintaining parallel native codebases
- Decision: Use foreground service within Flutter process (current implementation)

## Recommendations

### Future Improvements

1. **Stop Service on Logout**
   - Currently: Service continues running after logout
   - Recommendation: Stop community sensing when user logs out
   - Implementation: Add `CommunitySensingService.instance.stop()` to logout flow

2. **User Toggle Persistence**
   - Currently: Toggle state not persisted across app restarts
   - Recommendation: Save toggle state to `shared_preferences`
   - Auto-start based on saved preference

3. **Battery Optimization Guidance**
   - Show in-app message explaining battery usage
   - Link to "Disable Battery Optimization" settings
   - Educate users on why notification is necessary

4. **Scan Interval Configuration**
   - Currently: Hard-coded 75 seconds
   - Recommendation: Allow users to choose (e.g., 60s, 90s, 120s)
   - Trade-off: Responsiveness vs battery life

5. **Service Health Monitoring**
   - Detect when service stops unexpectedly
   - Show banner: "Community sensing stopped - tap to restart"
   - Auto-restart on network recovery

6. **GPS Location in Community Detections**
   - Currently: Only BLE RSSI + timestamp reported
   - Recommendation: Include GPS location if available
   - Requires LocationService integration (NOT IMPLEMENTED)

7. **Native Android Service (Long-term)**
   - Rewrite BLE scanning in native Kotlin/Java
   - Run as true background service
   - Survives process termination
   - Complexity: High, requires native development

## Build Output

**APK Location:** `build\app\outputs\flutter-apk\app-debug.apk`
**Build Time:** 28.6 seconds
**Build Status:** ✅ Success

**Analyzer Warnings:**
- 1 `@visibleForTesting` warning (receivePort) - expected, documented usage
- 3 pre-existing warnings (unrelated)

## Summary

### What Was Implemented

✅ Automatic background BLE community sensing
✅ Foreground service with persistent notification
✅ Periodic BLE scanning (every 75 seconds)
✅ AssetGuard tracker filtering (AG-XXX pattern)
✅ Community detection reporting to backend
✅ Debouncing (60-second interval per tracker)
✅ Auto-start after login with permissions
✅ Survives app backgrounding and screen lock
✅ Scan count tracking and notification updates
✅ Owner vs community detection differentiation (backend)
✅ Wi-Fi + BLE concurrent scanning

### What Was NOT Modified

✅ Backend API (no changes)
✅ Database schema (no changes)
✅ Email verification (no changes)
✅ Authentication flow (no changes)
✅ Asset ownership logic (no changes)
✅ "Scan for Devices" button (still works for manual owner scans)
✅ Wi-Fi room prediction (no changes)
✅ Existing community detection endpoint (no changes)

### User Experience

**For User A (Asset Owner):**
1. Mark AG-001 as LOST
2. Community sensing runs automatically (optional toggle)
3. User A can also manually scan for own tracker

**For User B (Community Helper):**
1. Login → automatic community sensing starts
2. No action required
3. Carries phone normally
4. Trackers detected and reported automatically
5. User B never opens "Nearby Devices"
6. User B never presses "Scan for Devices"
7. Persistent notification shows service is active

### Critical Constraints

⚠️ **MUST test on real Android device**
- BLE scanning cannot be tested in emulator
- Background service behavior varies by device
- Battery optimization settings affect reliability

⚠️ **Process termination stops sensing**
- If Android kills the app, sensing stops
- Must reopen app to restart
- This is a fundamental Android + flutter_blue_plus limitation

⚠️ **Notification is mandatory**
- Cannot hide or remove notification
- Android requires it for foreground services
- Users may find it annoying

⚠️ **Battery impact**
- Continuous BLE+Wi-Fi scanning drains battery
- Users should be informed
- Consider adding battery usage disclaimer

## Next Steps

1. **Deploy APK to test devices**
2. **Test with two physical Android phones**
3. **Verify MongoDB community detections are created**
4. **Monitor battery usage over 24 hours**
5. **Test on different Android versions (if available)**
6. **Gather user feedback on notification intrusiveness**
7. **Consider implementing "Stop on Logout" recommendation**
8. **Add battery optimization guidance to UI**

**Ready for device testing.**
