# Track Asset Feature - Two-Phone Test Procedure

**Date:** August 28, 2026  
**APK:** `build\app\outputs\flutter-apk\app-debug.apk`  
**Feature:** Track Asset with real map showing community detection locations  

---

## Implementation Summary

### ✅ What Was Built

**Backend:**
- ✅ `GET /api/community/detections/asset/:assetId` endpoint
- ✅ JWT protected, verifies asset ownership
- ✅ Returns detections sorted newest first
- ✅ Excludes detectedBy field (privacy)

**Flutter:**
- ✅ `CommunityDetection` model
- ✅ `CommunityDetectionRetrievalService` for fetching detections
- ✅ `TrackAssetScreen` with interactive map
- ✅ flutter_map + OpenStreetMap integration
- ✅ Latest detection card with details
- ✅ Detection history list
- ✅ Refresh functionality
- ✅ AssetDetailsScreen integration
- ✅ Latest detection info in asset details

**Files Created:**
1. `lib/models/community_detection_model.dart`
2. `lib/services/community_detection_retrieval_service.dart`
3. `lib/screens/track_asset_screen.dart`

**Files Modified:**
1. `backend/src/controllers/communityController.js` (added GET endpoint)
2. `backend/src/routes/communityRoutes.js` (added route)
3. `lib/screens/asset_details_screen.dart` (Track Asset navigation + latest detection display)
4. `pubspec.yaml` (added flutter_map + latlong2)

---

## Prerequisites

### User A (Asset Owner)

1. **Owns AG-001 asset**
2. **AG-001 marked as LOST**
3. **New APK installed** (with Track Asset feature)
4. **Logged in**

### User B (Community Member)

1. **Community Sensing active**
2. **AG-001 tracker nearby** (powered on, advertising)
3. **GPS enabled** (for location coordinates in detections)

### Backend

1. **Server running** with latest code (GET endpoint)
2. **MongoDB connected**

---

## Test Procedure

### Phase 1: Initial State (No Detections)

**User A's Phone:**

1. Login as User A
2. Navigate to "My Assets" or "Lost" tab
3. Find and tap AG-001 asset
4. **Asset Details Screen should show:**
   ```
   Last Known Location
   Location: No community detections yet
   Time: —
   Signal: —
   ```

5. Tap **"Track Asset"** button
6. **Track Asset Screen should show:**
   - Empty state: "No community detections yet"
   - Message: "When AG-001 is detected by the community, locations will appear here."
   - "Check Again" button

7. Leave Track Asset screen open (or close and return later)

### Phase 2: First Detection

**User B's Phone:**

1. Ensure Community Sensing is running
2. Keep AG-001 tracker within 5-10 meters
3. **Wait for automatic detection** (within 15-30 seconds)
4. **Verify notification shows:** "BLE: X scans, Y detections"

**Backend Terminal:**

Look for logs:
```
[Community] INCOMING DETECTION REQUEST
[Community]   trackerId  : AG-001
[Community] ✓ Detection created in MongoDB: <detection-id>
[Community] Owner notification created: <notification-id>
```

**MongoDB Verification:**

```javascript
db.communitydetections.find({ trackerId: 'AG-001' }).sort({ createdAt: -1 }).limit(1)
// Should show new detection with latitude, longitude, rssi, detectedAt
```

### Phase 3: View Detection on Map (User A)

**User A's Phone:**

1. Return to AG-001 Asset Details
2. **Asset Details should NOW show:**
   ```
   Last Known Location
   Location: 12.3711, 76.5853 (or actual coordinates)
   Time: Today, 12:30 PM (or actual time)
   Signal: -67 dBm (Community detected)
   ```

3. Tap **"Track Asset"** button again
4. **Track Asset Screen should NOW show:**
   - **Map** (top 40% of screen):
     - OpenStreetMap tiles loaded
     - Red marker at detection location
     - Map centered on marker
     - Zoom/pan works
   
   - **Latest Detection Card** (below map):
     ```
     Last Detected Location
     
     Asset: Your laptop (or actual name)
     Tracker: AG-001
     Coordinates: 12.3711, 76.5853
     Detected: Aug 28, 2026 • 12:30 PM
     Signal: -67 dBm
     Source: Community detection
     
     ⏱ Last seen 2 minutes ago
     ```
   
   - **No Detection History yet** (only 1 detection so far)

5. **Tap the red marker on map:**
   - Dialog should open:
     ```
     Latest Detection
     
     Time: Aug 28, 2026 • 12:30 PM
     Signal: -67 dBm
     Coordinates: 12.3711, 76.5853
     2 minutes ago
     ```

### Phase 4: Multiple Detections

**User B's Phone:**

1. **Keep Community Sensing running**
2. **Wait ~30 seconds** for debounce to expire
3. **Second detection should occur automatically**
4. (Optional) Move to a different location if possible to get different GPS coordinates
5. **Wait another 30 seconds**
6. **Third detection should occur**

**User A's Phone:**

1. On Track Asset screen, tap **Refresh button** (top-right)
2. **Map should update:**
   - Latest detection: Red marker
   - Previous detection(s): Gray marker(s)
   - If locations different, multiple markers visible
   - If locations same, markers overlap (expected)

3. **Latest Detection Card updates:**
   - Shows newest detection time
   - "Last seen X minutes ago" updates

4. **Detection History appears:**
   ```
   Detection History                 3 detections
   
   12:30 PM  📍 12.37, 76.59  -60 dBm
   
   12:00 PM  📍 12.37, 76.58  -62 dBm
   
   11:30 AM  📍 12.37, 76.58  -59 dBm
   ```

5. **Tap a gray marker:**
   - Dialog shows: "Previous Detection"
   - Shows time, signal, coordinates for that detection

### Phase 5: Backend API Testing

**Test GET endpoint directly:**

```bash
# Get User A's JWT token (from login response or asset_service logs)
TOKEN="eyJhbGc..."

# Get AG-001 asset ID (from MongoDB or API response)
ASSET_ID="66ce1234abcd5678efgh9012"

# Call API
curl -H "Authorization: Bearer $TOKEN" \
     http://10.135.90.221:5000/api/community/detections/asset/$ASSET_ID
```

**Expected response:**
```json
{
  "success": true,
  "detections": [
    {
      "_id": "...",
      "trackerId": "AG-001",
      "assetId": "...",
      "rssi": -67,
      "latitude": 12.3711,
      "longitude": 76.5853,
      "detectedAt": "2026-08-28T04:30:00.000Z",
      "createdAt": "2026-08-28T04:30:01.123Z"
    },
    ...
  ]
}
```

**Test security (should fail):**

```bash
# Try to fetch another user's asset (should return 404)
OTHER_ASSET_ID="..."
curl -H "Authorization: Bearer $TOKEN" \
     http://10.135.90.221:5000/api/community/detections/asset/$OTHER_ASSET_ID
# Expected: {"success": false, "message": "Asset not found"}
```

### Phase 6: Edge Cases

**Test 1: Asset with no detections**

1. User A creates new asset AG-002 (not detected yet)
2. Mark as LOST
3. Open Asset Details → should show "No community detections yet"
4. Tap Track Asset → should show empty state

**Test 2: Detection without GPS**

1. User B turns off GPS
2. User B detects AG-001 (detection created without latitude/longitude)
3. User A opens Track Asset
4. Map should show: "Location unavailable"
5. Detection card should still show time, signal, but no coordinates

**Test 3: Rapid refresh**

1. Tap Refresh multiple times quickly
2. Should not crash or duplicate detections
3. Loading state should appear briefly

---

## Acceptance Criteria

### ✅ Core Functionality

- [ ] "Track Asset" button opens TrackAssetScreen
- [ ] Map displays with OpenStreetMap tiles
- [ ] Latest detection shown as red marker
- [ ] Map centers on latest detection
- [ ] Map supports zoom and pan
- [ ] Detection card shows asset name, tracker ID, coordinates, time, signal
- [ ] "Last seen X ago" calculates correctly
- [ ] Refresh button fetches latest detections

### ✅ Detection History

- [ ] Multiple detections shown in history list
- [ ] History sorted newest first
- [ ] Each entry shows time, location, signal
- [ ] Previous detections shown as gray markers on map
- [ ] Tapping marker shows detection details

### ✅ Asset Details Integration

- [ ] Asset details shows latest detection coordinates
- [ ] Asset details shows latest detection time
- [ ] Asset details shows signal with "Community detected" label
- [ ] Shows "No community detections yet" when no detections exist

### ✅ Security & Privacy

- [ ] User A can only fetch detections for their own assets
- [ ] detectedBy field not exposed to User A
- [ ] User B identity remains private
- [ ] JWT authentication required on GET endpoint
- [ ] Unauthorized requests return 404

### ✅ UX & Error Handling

- [ ] Loading state shown while fetching
- [ ] Empty state when no detections
- [ ] Error state with retry button
- [ ] "Location unavailable" when GPS missing
- [ ] No crashes on rapid refresh
- [ ] Back navigation works correctly

### ✅ Regression Testing

- [ ] Community detection still works (POST endpoint)
- [ ] BLE scanning unchanged
- [ ] Notification flow unchanged
- [ ] 30-second debounce unchanged
- [ ] MongoDB writes unchanged

---

## Expected Results Summary

### Before Any Detections

| Screen | Expected Display |
|--------|-----------------|
| Asset Details - Location | "No community detections yet" |
| Asset Details - Time | "—" |
| Asset Details - Signal | "—" |
| Track Asset | Empty state with "No community detections yet" |

### After First Detection

| Screen | Expected Display |
|--------|-----------------|
| Asset Details - Location | "12.3711, 76.5853" |
| Asset Details - Time | "Today, 12:30 PM" |
| Asset Details - Signal | "-67 dBm (Community detected)" |
| Track Asset - Map | Red marker at detection location |
| Track Asset - Card | Full detection details |
| Track Asset - History | Empty (only 1 detection) |

### After Multiple Detections

| Screen | Expected Display |
|--------|-----------------|
| Asset Details - Location | Latest coordinates |
| Asset Details - Time | Latest time |
| Asset Details - Signal | Latest signal |
| Track Asset - Map | Red marker (latest) + gray markers (previous) |
| Track Asset - Card | Latest detection details |
| Track Asset - History | List of previous detections |

---

## Troubleshooting

### Issue: Map not loading

**Symptoms:** Gray screen, no tiles

**Causes:**
- No internet connection
- OpenStreetMap servers down
- Incorrect URL template

**Solution:**
- Check internet connection
- Wait and retry
- Tiles cached after first successful load

### Issue: "Asset not found" error

**Symptoms:** 404 error when fetching detections

**Causes:**
- Asset doesn't belong to authenticated user
- Asset ID incorrect
- JWT expired

**Solution:**
- Verify asset ownership in MongoDB
- Check User A is logged in
- Re-login if JWT expired

### Issue: Empty state despite detections in MongoDB

**Symptoms:** Track Asset shows "No community detections yet" but MongoDB has records

**Causes:**
- Detection belongs to different asset
- Backend not returning detections
- Network error

**Solution:**
- Verify MongoDB: `db.communitydetections.find({ assetId: ObjectId("...") })`
- Check backend logs for GET request
- Test API endpoint directly with curl

### Issue: Markers overlap/not visible

**Symptoms:** Multiple detections but only one marker

**Causes:**
- All detections have same GPS coordinates
- Normal behavior when phone hasn't moved

**Solution:**
- Not a bug — expected when detections happen at same location
- Detection history list shows all detections
- Move phone to different location for next detection

---

## Backend Logs (Expected)

**When User A fetches detections:**
```
[CommunityDetection] Fetching detections for asset: 66ce1234abcd5678efgh9012
[CommunityDetection] Requested by: usera@example.com
[CommunityDetection] Asset verified: AG-001
[CommunityDetection] Found 3 detections
```

**When unauthorized user tries:**
```
[CommunityDetection] Fetching detections for asset: <other-asset-id>
[CommunityDetection] Requested by: userb@example.com
[CommunityDetection] Asset not found or unauthorized
```

---

## Flutter Logs (Expected)

**When loading Track Asset:**
```
[CommunityDetectionRetrieval] Fetching detections for asset: 66ce1234abcd5678efgh9012
[CommunityDetectionRetrieval] Loaded 3 detections
```

**When loading Asset Details:**
```
[AssetDetails] Failed to load latest detection: <error>  (if no detections)
(or no log if successful)
```

---

## MongoDB Verification Queries

**Check detections for AG-001:**
```javascript
db.communitydetections.find({ 
  trackerId: 'AG-001' 
}).sort({ createdAt: -1 }).limit(10).pretty()
```

**Count detections per asset:**
```javascript
db.communitydetections.aggregate([
  { $group: { _id: "$assetId", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
])
```

**Find detections with GPS:**
```javascript
db.communitydetections.find({
  trackerId: 'AG-001',
  latitude: { $ne: null },
  longitude: { $ne: null }
}).count()
```

---

## Success Metrics

✅ **Track Asset opens successfully**  
✅ **Map displays OpenStreetMap tiles**  
✅ **Latest detection marker visible**  
✅ **Detection details accurate**  
✅ **Multiple detections shown correctly**  
✅ **Refresh fetches new detections**  
✅ **Asset details shows latest info**  
✅ **User B identity not exposed**  
✅ **Security enforced on API**  
✅ **No regressions to existing features**  

---

## Next Steps After Testing

### If Successful:

1. **Document any issues found** (minor UI tweaks, performance)
2. **Optional enhancements:**
   - Add reverse geocoding for human-readable locations
   - Add detection path/trail on map
   - Add export detection history
   - Add "Open in Maps" button

### If Issues Found:

1. **Capture logs** (backend + Flutter)
2. **Screenshot error states**
3. **Note exact steps to reproduce**
4. **Check MongoDB data matches UI expectations**

---

## Files Changed Summary

**Backend (2 files):**
- `backend/src/controllers/communityController.js` (+65 lines)
- `backend/src/routes/communityRoutes.js` (+2 lines)

**Flutter (7 files):**
- `pubspec.yaml` (+2 dependencies)
- `lib/models/community_detection_model.dart` (NEW, 66 lines)
- `lib/services/community_detection_retrieval_service.dart` (NEW, 42 lines)
- `lib/screens/track_asset_screen.dart` (NEW, 620 lines)
- `lib/screens/asset_details_screen.dart` (~30 lines modified)

**Total:** ~795 lines of new code, 2 files created backend, 3 files created Flutter

---

## APK Info

**Location:** `build\app\outputs\flutter-apk\app-debug.apk`  
**Built:** August 28, 2026  
**Dependencies Added:** flutter_map ^7.0.2, latlong2 ^0.9.1  
**Backend Restart Required:** Yes (for GET endpoint)  

Ready for two-phone testing.
