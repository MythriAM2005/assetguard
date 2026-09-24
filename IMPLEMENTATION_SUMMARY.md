# Implementation Summary: Automatic Background BLE Community Sensing

## What Was Built

Automatic background BLE community sensing that detects lost AssetGuard trackers **without user interaction**.

## Key Changes

### 1. Permission Flow (Previous Task)
- ✅ Moved permissions from "Scan for Devices" button to login flow
- ✅ Permissions requested immediately after successful login
- ✅ Navigation blocked until permissions granted/denied

### 2. Background BLE Sensing (This Task)
- ✅ Automatic BLE scanning every 75 seconds in background
- ✅ Foreground service with persistent notification
- ✅ AssetGuard tracker detection (AG-XXX pattern)
- ✅ Automatic community detection reporting
- ✅ Auto-start after login

## Files Modified

| File | Changes |
|------|---------|
| `lib/services/community_sensing_service.dart` | Added BLE scanning, inter-isolate communication, automatic detection reporting |
| `lib/services/permission_service.dart` | Added automatic community sensing startup after login |
| `lib/screens/nearby_devices_screen.dart` | Added `bluetoothPermissionDenied` case handling |

## User Flow

### Before
```
User B → Open Nearby Devices → Press "Scan for Devices" → Detects AG-001
```

### After
```
User B → Login → (automatic) → AG-001 detected in background
```

## Technical Architecture

```
Every 75 seconds:
  Foreground Task Isolate (timer)
    ↓
  Sends "performBleScan" via SendPort
    ↓
  Main Isolate receives message
    ↓
  Calls flutter_blue_plus.scan() (8 seconds)
    ↓
  Filters AssetGuard trackers (AG-XXX)
    ↓
  Reports to POST /api/community/detections
    ↓
  Backend verifies: LOST + not owner
    ↓
  Creates CommunityDetection record
```

## Permissions Required

- ✅ BLUETOOTH_SCAN (already declared)
- ✅ BLUETOOTH_CONNECT (already declared)
- ✅ ACCESS_FINE_LOCATION (already declared)
- ✅ FOREGROUND_SERVICE (already declared)
- ✅ FOREGROUND_SERVICE_LOCATION (already declared)

**No new permissions added.**

## Android Notification

**Persistent notification required by Android:**
- Channel: "Community Sensing"
- Title: "AssetGuard Community Sensing"
- Text: "Community sensing active — BLE: 2, Wi-Fi: 3 (1 detection)"
- Priority: LOW
- Cannot be dismissed while service is running

## Critical Limitations

### ❌ Cannot Survive Process Termination
- If Android kills the app process → sensing stops
- User must reopen app to restart
- **Mitigation:** Auto-restarts on app reopen (implemented)

### ⚠️ Notification Cannot Be Hidden
- Android requirement for foreground services
- Users see persistent notification
- **Mitigation:** LOW priority (silent, non-intrusive)

### ⚠️ Battery Impact
- Continuous BLE + Wi-Fi scanning drains battery
- 75-second scan interval is a compromise
- **Mitigation:** Users can toggle off in Nearby Devices

### ⚠️ BLE Range Limitations
- Typical range: 10-30 meters indoors
- Must be physically close to trackers

## Testing Requirements

### MUST Test on Real Android Devices

**Cannot test in emulator:**
- BLE hardware required
- Background service behavior varies by device
- Battery optimization affects reliability

### Two-Phone Test
```
Phone A (User A):
1. Mark AG-001 as LOST

Phone B (User B):
1. Login
2. Grant permissions
3. Lock screen / minimize app
4. Move near AG-001
5. Wait 75-90 seconds
6. Check MongoDB: communitydetections collection
   ✅ New detection with User B as detectedBy
```

## Build Status

- ✅ Flutter analyzer passed
- ✅ Debug APK built successfully
- ✅ Location: `build\app\outputs\flutter-apk\app-debug.apk`
- ✅ Build time: 28.6s

## What Was NOT Modified

- ✅ Backend API (no changes)
- ✅ Database schema (no changes)
- ✅ Asset ownership logic (no changes)
- ✅ Email verification (no changes)
- ✅ "Scan for Devices" button (still works for manual scans)
- ✅ Wi-Fi room prediction (no changes)

## Next Steps

1. **Deploy to test devices**
2. **Test with two physical Android phones**
3. **Verify communitydetections in MongoDB**
4. **Monitor battery usage**
5. **Gather user feedback on notification**

## Key Metrics

- **Scan Frequency:** Every 75 seconds
- **Scan Duration:** 8 seconds
- **Debounce Interval:** 60 seconds (same tracker)
- **Duty Cycle:** ~10.7%

## Recommendations

### Immediate
1. Add "Stop on Logout" functionality
2. Test on Android 12, 13, 14, 15 devices
3. Monitor battery drain over 24 hours

### Future
1. Make scan interval configurable (60s / 90s / 120s)
2. Add battery optimization guidance to UI
3. Persist toggle state across app restarts
4. Include GPS location in detections

## Documentation

- **Detailed:** `BACKGROUND_BLE_COMMUNITY_SENSING.md`
- **Permission Changes:** `PERMISSION_FLOW_CHANGES.md`
- **This Summary:** `IMPLEMENTATION_SUMMARY.md`

---

**Status: ✅ Ready for device testing**
