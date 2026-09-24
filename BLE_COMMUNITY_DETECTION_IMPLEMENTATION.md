# BLE Community Detection Implementation

## Overview
Implemented BLE community detection system that allows users to report sightings of LOST AssetGuard trackers. This feature enables community members to help locate missing assets by automatically reporting BLE detections to the backend.

## Architecture

### Data Flow
```
AssetGuard BLE Tracker (ESP32)
    ↓
Community User's Phone (BLE Scan)
    ↓
Flutter App (CommunityDetectionService)
    ↓
Node.js Backend (POST /api/community/detections)
    ↓
MongoDB (CommunityDetection collection)
    ↓
Asset Owner Notification (Phase 3D - TODO)
```

## Implementation Summary

### Flutter Changes

#### 1. Enhanced BleDetectedDevice Model
**File**: `lib/models/detection_model.dart`
- Added `remoteId` field (Bluetooth MAC address)
- Added `detectedAt` field (scan timestamp)
- Preserves all existing fields: `trackerId`, `deviceName`, `rssi`

#### 2. Updated BLE Service
**File**: `lib/services/ble_service.dart`
- Populates new `remoteId` field from `r.device.remoteId.str`
- Populates `detectedAt` with `DateTime.now()` at scan time
- **NO CHANGES** to existing scan logic - only adds fields to returned objects

#### 3. Community Detection Service
**File**: `lib/services/community_detection_service.dart`
- **Debouncing**: In-memory map prevents duplicate reports within 60 seconds
- **API Integration**: Sends detections to `POST /api/community/detections`
- **Error Handling**: Gracefully handles 404 (asset not LOST or not found)
- **Authentication**: Uses existing JWT from `ApiService.instance`

#### 4. Configuration
**File**: `lib/utils/community_detection_config.dart`
- `debounceIntervalSeconds = 60` (configurable constant)

#### 5. UI Integration
**File**: `lib/screens/nearby_devices_screen.dart`
- Automatically reports community detections after each BLE scan
- Filters to only report trackerIds that match registered assets
- Backend validates asset is LOST before accepting
- Shows count: "Community detections reported: X"
- No UI redesign - minimal debug indicator only

### Backend Changes

#### 1. CommunityDetection Model
**File**: `backend/src/models/CommunityDetection.js`
- Schema fields:
  - `trackerId` (String, required, indexed)
  - `assetId` (ObjectId, required, indexed)
  - `detectedBy` (ObjectId, required, indexed - from JWT)
  - `rssi` (Number, -120 to 0)
  - `remoteId` (String, optional - Bluetooth MAC)
  - `detectedAt` (Date, required, indexed)
  - `createdAt`, `updatedAt` (automatic timestamps)
- Compound index: `{assetId: 1, detectedAt: -1}` for efficient queries

#### 2. Community Controller
**File**: `backend/src/controllers/communityController.js`
- Added `submitCommunityDetection` function
- **Validation**: trackerId, rssi (-120 to 0), detectedAt (ISO 8601), optional remoteId
- **Asset Lookup**: Finds asset by trackerId (NOT scoped to user)
- **LOST Verification**: Only accepts detections for assets with `status === 'LOST'`
- **Security**: Always uses `detectedBy` from JWT, never from request body
- Returns 404 for non-LOST or non-existent assets (prevents status leakage)

#### 3. Routes
**File**: `backend/src/routes/communityRoutes.js`
- Added `POST /api/community/detections` endpoint
- Protected with JWT authentication
- Uses validators and validation middleware

#### 4. Tests
**File**: `backend/tests/community-detection.test.js`
- 8 test cases covering:
  - Authentication required
  - LOST asset accepted
  - ACTIVE asset rejected (404)
  - Non-existent asset rejected (404)
  - Invalid RSSI rejected (400)
  - Invalid timestamp rejected (400)
  - Optional remoteId works
  - detectedBy enforced from JWT

## Security Features

1. **JWT Authentication**: All community detection requests require valid auth token
2. **LOST Status Enforcement**: Backend verifies asset is LOST before accepting
3. **User ID from JWT**: detectedBy always extracted from token, never from request
4. **No Status Leakage**: 404 returned for both non-LOST and non-existent assets
5. **Input Validation**: RSSI range, ISO 8601 timestamp, optional remoteId

## Debouncing Logic

**Purpose**: Prevent flooding backend with duplicate reports

**Implementation**:
- In-memory map: `Map<String, DateTime> _lastReported`
- Before reporting, checks if 60 seconds elapsed since last report for same trackerId
- Configurable via `CommunityDetectionConfig.debounceIntervalSeconds`
- Per-app-instance (resets on app restart)

**Trade-offs**:
- ✅ Simple, fast, no backend load
- ❌ Doesn't persist across app restarts
- ❌ Doesn't coordinate between users

## Tracker Identification

**Existing Mechanism Preserved**:
- Uses `trackerId` string from BLE scan results
- Extracted from `advName` (advertisement name) or `platformName` (cached name)
- Matches against registered assets in `_registeredAssets`
- Example: "AG-001", "ESP32-TRACKER-001", etc.

**BLE Service Priority**:
1. `r.advertisementData.advName` (most reliable)
2. `r.device.platformName` (Android cached)
3. Service UUID hint (for unnamed ESP32 devices)
4. Fallback to MAC address

## Testing

### Flutter
```bash
flutter analyze
flutter build apk --debug
```
**Status**: ✅ Builds successfully (minor linting warnings only)

### Backend
```bash
cd backend
npm test -- community-detection
```
**Status**: Needs MongoDB connection for integration tests

## User Flow

### Foreground Detection (Current Implementation)
1. User opens "Nearby Devices" screen
2. Taps "Scan for Devices"
3. BLE scan discovers nearby trackers (8 seconds)
4. For each detected tracker matching a registered asset:
   - Check debounce (60 seconds)
   - If not debounced, report to backend
   - Backend validates asset is LOST
   - If LOST, save CommunityDetection record
5. UI shows "Community detections reported: X"

### Background Detection (Not Implemented Yet)
- Will use similar architecture
- Periodic scans in background
- Report only LOST assets
- Respect debounce interval

## API Endpoint

### POST /api/community/detections

**Authentication**: JWT required (Bearer token)

**Request Body**:
```json
{
  "trackerId": "AG-001",
  "rssi": -57,
  "remoteId": "AA:BB:CC:DD:EE:FF",  // optional
  "detectedAt": "2026-08-27T11:45:20Z"
}
```

**Success Response** (201):
```json
{
  "success": true,
  "message": "Community detection recorded. Asset owner will be notified.",
  "detectionId": "507f1f77bcf86cd799439011"
}
```

**Error Responses**:
- `401`: Authentication required
- `400`: Validation error (invalid RSSI, timestamp, etc.)
- `404`: Asset not found OR asset not LOST (prevents status leakage)
- `500`: Server error

## Database Schema

### CommunityDetection Collection
```javascript
{
  _id: ObjectId,
  trackerId: "AG-001",
  assetId: ObjectId,  // reference to Asset
  detectedBy: ObjectId,  // reference to User (from JWT)
  rssi: -57,
  remoteId: "AA:BB:CC:DD:EE:FF",  // optional
  detectedAt: ISODate("2026-08-27T11:45:20Z"),
  createdAt: ISODate("2026-08-27T11:45:22Z"),  // auto
  updatedAt: ISODate("2026-08-27T11:45:22Z")   // auto
}
```

**Indexes**:
- `{trackerId: 1}`
- `{assetId: 1}`
- `{detectedBy: 1}`
- `{detectedAt: 1}`
- `{assetId: 1, detectedAt: -1}` (compound)

## Files Modified/Created

### Flutter
- ✅ `lib/models/detection_model.dart` (modified - enhanced BleDetectedDevice)
- ✅ `lib/services/ble_service.dart` (modified - populate new fields)
- ✅ `lib/services/community_detection_service.dart` (new)
- ✅ `lib/utils/community_detection_config.dart` (new)
- ✅ `lib/screens/nearby_devices_screen.dart` (modified - integration)

### Backend
- ✅ `backend/src/models/CommunityDetection.js` (new)
- ✅ `backend/src/controllers/communityController.js` (modified - new function)
- ✅ `backend/src/routes/communityRoutes.js` (modified - new route)
- ✅ `backend/tests/community-detection.test.js` (new)

## Known Limitations

1. **Debouncing**: Per-app-instance only (doesn't persist)
2. **Background Scanning**: Not implemented yet (foreground only)
3. **Owner Notification**: TODO in Phase 3D (push/email)
4. **Location**: No GPS/WiFi included in community detections
5. **Filter Accuracy**: Reports all matching trackerIds - backend validates LOST status

## Future Enhancements (Not Implemented)

1. **Owner Notifications**: Push notification or email when their LOST asset is detected
2. **Background Scanning**: Periodic BLE scans when app is in background
3. **Debounce Persistence**: Store debounce state in local storage
4. **Location Context**: Include approximate location (WiFi fingerprint or GPS) with detection
5. **Community Detection History**: Show detected locations on asset detail screen
6. **Privacy Controls**: Let users opt out of community detection reporting
7. **Detection Analytics**: Heatmap of where LOST assets were detected

## Verification Checklist

- [x] Flutter code compiles without errors
- [x] BleDetectedDevice model enhanced with remoteId and detectedAt
- [x] BLE service populates new fields without changing scan logic
- [x] CommunityDetectionService created with debouncing
- [x] Configuration file created
- [x] UI integration added to NearbyDevicesScreen
- [x] Backend model created with proper schema and indexes
- [x] Backend controller validates LOST status
- [x] Backend route added with authentication
- [x] Backend tests created (8 test cases)
- [x] Debug APK builds successfully
- [ ] Backend tests pass (requires MongoDB connection)
- [ ] Device testing on real Android phone
- [ ] End-to-end test: detect LOST asset → verify backend record

## Next Steps

1. **Start Backend**: Ensure Node.js backend is running on port 5000
2. **Start MongoDB**: Ensure MongoDB connection is available
3. **Run Backend Tests**: `npm test -- community-detection`
4. **Install Debug APK**: Transfer to Android phone and install
5. **Create Test Asset**: Register asset and mark it as LOST
6. **Scan for Devices**: Trigger BLE scan and verify community detection report
7. **Verify Backend**: Check CommunityDetection collection in MongoDB
8. **Test Debouncing**: Scan again within 60 seconds → should not report
9. **Test Active Asset**: Mark asset as ACTIVE → should not report (404)

## Notes

- Existing BLE scanning implementation remains **completely intact**
- Only minimal integration added - no rewrites or redesigns
- Backend enforces LOST status - Flutter doesn't need to filter
- Debouncing prevents spam but isn't perfect (per-app-instance only)
- Security: JWT authentication + detectedBy from token only
- Privacy: No GPS/WiFi fingerprint sent (just BLE RSSI)
