# Quick Reference: Background BLE Community Sensing

## How It Works (User Perspective)

### User A (Asset Owner)
1. Register AG-001 tracker
2. Mark AG-001 as **LOST**
3. AssetGuard automatically broadcasts location

### User B (Community Helper)
1. Login to AssetGuard
2. Grant Bluetooth + Location permissions
3. **That's it!** Community sensing runs automatically

**User B does NOT need to:**
- ❌ Open "Nearby Devices"
- ❌ Press "Scan for Devices"
- ❌ Know AG-001 exists
- ❌ Do anything manually

## Technical Overview

| Aspect | Details |
|--------|---------|
| **Scan Frequency** | Every 75 seconds |
| **Scan Duration** | 8 seconds per scan |
| **Tracker Detection** | AssetGuard trackers only (AG-XXX pattern) |
| **Debouncing** | 60 seconds per tracker |
| **Service Type** | Android Foreground Service |
| **Notification** | Persistent, LOW priority |
| **Battery Impact** | 5-15% per 24 hours (varies) |

## Key Files

| File | Purpose |
|------|---------|
| `community_sensing_service.dart` | BLE + Wi-Fi background scanning |
| `permission_service.dart` | Auto-start after login |
| `ble_service.dart` | BLE scanning via flutter_blue_plus |
| `community_detection_service.dart` | Backend reporting + debouncing |

## Permissions

All permissions already declared in `AndroidManifest.xml`:

- ✅ `BLUETOOTH_SCAN`
- ✅ `BLUETOOTH_CONNECT`
- ✅ `ACCESS_FINE_LOCATION`
- ✅ `FOREGROUND_SERVICE`
- ✅ `FOREGROUND_SERVICE_LOCATION`
- ✅ `POST_NOTIFICATIONS`

**No new permissions added.**

## API Endpoint

```
POST /api/community/detections
Authorization: Bearer <JWT>

Request:
{
  "trackerId": "AG-001",
  "rssi": -65,
  "remoteId": "XX:XX:XX:XX:XX:XX",
  "detectedAt": "2026-08-27T10:30:00.000Z"
}

Response (201 Created):
{
  "success": true,
  "message": "Community detection recorded"
}

Response (404 Not Found):
{
  "error": "Asset not found or not LOST"
}
```

## Backend Verification Logic

The backend automatically checks:

1. ✅ Asset exists (global lookup by trackerId)
2. ✅ Asset status is **LOST**
3. ✅ Detector is **NOT** the owner
4. ✅ Creates `CommunityDetection` record

**App does NOT perform these checks client-side.**

## MongoDB Schema

```javascript
// communitydetections collection
{
  _id: ObjectId,
  asset: ObjectId,        // Reference to assets._id (User A's asset)
  detectedBy: ObjectId,   // Reference to users._id (User B)
  trackerId: "AG-001",    // Tracker identifier
  rssi: -65,              // BLE signal strength (dBm)
  detectedAt: ISODate,    // When detected
  remoteId: "XX:XX:...",  // BLE MAC address
  createdAt: ISODate,     // When recorded
  __v: 0
}
```

## Notification

```
┌─────────────────────────────────────┐
│ 🔵 AssetGuard Community Sensing    │
│                                     │
│ Community sensing active —          │
│ BLE: 12, Wi-Fi: 12 (3 detections)  │
└─────────────────────────────────────┘
  ↑              ↑                ↑
  |              |                └─ Detection count
  |              └─ Scan counts (BLE and Wi-Fi)
  └─ Service name
```

**Priority:** LOW (silent, non-intrusive)
**Can be dismissed:** ❌ No (while service is running)

## Debug Logs

Enable ADB logging to see detailed activity:

```bash
# Filter AssetGuard logs
adb logcat | grep -E "CommunitySensing|BleService|CommunityDetection"
```

**Key log messages:**
```
[Permissions] Starting community sensing automatically...
[CommunitySensing] Foreground service started successfully
[CommunitySensing] BLE scan requested by foreground task
[CommunitySensing] Starting BLE scan (known trackers: 2)
[BleService] Device found: AG-001 (rssi: -65 dBm)
[CommunitySensing] AssetGuard trackers detected: 1
[CommunityDetection] Reporting detection: AG-001 (rssi: -65)
[CommunityDetection] Report accepted
[CommunitySensing] BLE scan complete: 1 detections reported
```

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| No notification appears | Permissions denied | Re-grant in Settings → Apps → AssetGuard |
| Scans not incrementing | Process killed | Reopen app (auto-restart) |
| No detections created | Tracker not LOST | Verify asset status in MongoDB |
| Owner's detection created | Backend bug | Check backend verification logic |
| Service stops after 10min | Battery optimization | Disable for AssetGuard in Settings |

## Testing Commands

```bash
# Build and install
flutter build apk --debug
adb install build\app\outputs\flutter-apk\app-debug.apk

# Monitor logs
adb logcat | grep CommunitySensing

# Check MongoDB
mongosh assetguard_db
db.communitydetections.find().sort({createdAt: -1}).limit(10).pretty()

# Count detections by user
db.communitydetections.countDocuments({detectedBy: ObjectId("...")})

# Check asset status
db.assets.findOne({trackerId: "AG-001"})
```

## Scan Timing

```
t=0s:    Scan starts
t=8s:    Scan completes, process results
t=75s:   Next scan starts
t=83s:   Next scan completes
t=150s:  Next scan starts
...
```

**Effective duty cycle:** ~10.7% (8s scan / 75s interval)

## Battery Optimization

### To Maximize Detection Reliability:

**Android Settings:**
1. Settings → Apps → AssetGuard
2. Battery → Unrestricted (or "Not optimized")
3. Permissions → Allow all required permissions

**Trade-off:**
- More battery usage
- More reliable background scanning

### To Minimize Battery Usage:

**In App:**
1. Open "Nearby Devices"
2. Scroll to "Community Sensing"
3. Toggle OFF

**Trade-off:**
- Less battery usage
- No automatic community detections

## Architecture Diagram

```
┌────────────────────────────────────────────┐
│            Flutter App Process             │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │   Foreground Task Isolate (Timer)   │ │
│  │                                      │ │
│  │  • Every 75s timer event             │ │
│  │  • Wi-Fi scan (can run in isolate)  │ │
│  │  • Send "performBleScan" message     │ │
│  └──────────────┬───────────────────────┘ │
│                 │ SendPort                 │
│                 ↓                          │
│  ┌──────────────────────────────────────┐ │
│  │   Main Flutter Isolate               │ │
│  │                                      │ │
│  │  • flutter_blue_plus (platform)      │ │
│  │  • BLE scan (8s)                     │ │
│  │  • Filter AssetGuard trackers        │ │
│  │  • Report to backend                 │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
                   │ HTTP
                   ↓
         ┌──────────────────┐
         │  Backend API     │
         │  /api/community/ │
         │   detections     │
         └─────────┬────────┘
                   │
                   ↓
              ┌─────────┐
              │ MongoDB │
              └─────────┘
```

## Stop Community Sensing

### Method 1: Toggle in App
1. Open "Nearby Devices"
2. Scroll to "Community Sensing" section
3. Toggle OFF

### Method 2: Force Stop App
1. Settings → Apps → AssetGuard
2. Force Stop

**Note:** Automatically restarts on next app open (if permissions granted)

## Start Community Sensing

### Automatic (Default):
- Starts automatically after login with permissions

### Manual:
1. Open "Nearby Devices"
2. Scroll to "Community Sensing" section
3. Toggle ON

## Limitations

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| Process termination stops service | If Android kills app, sensing stops | Auto-restart on reopen |
| Persistent notification required | User sees notification always | LOW priority (less intrusive) |
| Battery drain | 5-15% per 24 hours | Adjustable scan interval (future) |
| BLE range limitation | 10-30m range | Physical proximity required |
| Cannot run in emulator | Needs real device for testing | Use physical Android phones |

## Build Info

- **APK Location:** `build\app\outputs\flutter-apk\app-debug.apk`
- **Flutter Version:** 3.47.0
- **Dart Version:** 3.13.0
- **Target SDK:** Android 13-15 (likely)
- **Min SDK:** Android 8.0+ (likely)

## Support

**Documentation:**
- Detailed: `BACKGROUND_BLE_COMMUNITY_SENSING.md`
- Summary: `IMPLEMENTATION_SUMMARY.md`
- Testing: `TESTING_CHECKLIST.md`
- This reference: `QUICK_REFERENCE.md`

**Contact:** See main project README

---

**Last Updated:** 2026-08-27
**Version:** 1.0.0
**Status:** ✅ Ready for device testing
