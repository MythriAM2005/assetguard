# Track Asset Feature - Current State & Implementation Plan

**Date:** August 28, 2026  
**Current Status:** Placeholder only - needs full implementation  

---

## Current State Analysis

### ✅ What Exists

**Backend:**
- ✅ CommunityDetection MongoDB model with all required fields
- ✅ POST /api/community/detections (working - creates detections)
- ✅ Detection data includes: trackerId, assetId, detectedBy, rssi, latitude, longitude, detectedAt
- ❌ **NO GET endpoint** to retrieve detections for an asset

**Flutter:**
- ✅ Asset model with lastDetectedLocation and lastDetectedTime fields
- ✅ AssetDetailsScreen showing asset info
- ✅ "Track Asset" button exists (line 224)
- ❌ Track Asset currently shows placeholder toast: "Live BLE tracking will be available in the next phase"
- ❌ **NO TrackAssetScreen exists**
- ❌ **NO map implementation**
- ❌ **NO CommunityDetection Flutter model**
- ❌ Asset details shows hardcoded "Not yet detected" and "BLE tracking not yet active"

**Dependencies:**
- ✅ geolocator: ^13.0.2 (for GPS - already in pubspec.yaml)
- ❌ **NO map package** (google_maps_flutter, flutter_map, etc.)

---

## Missing Pieces

### 1. Backend GET Endpoint ❌

**Need:** `GET /api/community/detections/asset/:assetId`

**Requirements:**
- JWT protected
- Verify asset belongs to authenticated user (via asset.userId)
- Return detections for that asset only
- Sort by detectedAt descending (newest first)
- Include: trackerId, rssi, latitude, longitude, detectedAt, createdAt
- Exclude: detectedBy (privacy - don't expose User B identity)

### 2. Flutter Map Package ❌

**Need:** Choose and add a map package

**Options:**
- **google_maps_flutter** (official, requires API key, widely used)
- **flutter_map** (open source, uses OpenStreetMap, no API key needed)

**Recommendation:** flutter_map (no API key required, free, works offline with cached tiles)

### 3. Flutter CommunityDetection Model ❌

**Need:** Dart model to deserialize backend detection data

**Fields:**
- id, trackerId, assetId, rssi, latitude, longitude, detectedAt, createdAt

### 4. Flutter CommunityDetectionService ❌

**Need:** API client to fetch detections

**Methods:**
- `getDetectionsForAsset(String assetId)` → List<CommunityDetection>

### 5. TrackAssetScreen ❌

**Need:** Full screen with map + detection details

**Features:**
- Interactive map showing detection locations
- Latest detection marker (primary)
- Previous detection markers (history)
- Detection info card below map
- Detection history list
- Refresh functionality
- Human-readable location (reverse geocoding)
- Proper loading/error/empty states

### 6. Asset Details Update ❌

**Need:** Fetch latest detection and update lastDetectedLocation/Time/Signal

**Current problem:** Shows hardcoded "Not yet detected" even when detections exist

---

## Implementation Plan

### Phase 1: Backend API (30 min)

**File:** `backend/src/controllers/communityController.js`

Create `getDetectionsForAsset`:
```javascript
router.get('/detections/asset/:assetId', getDetectionsForAsset);
```

Logic:
1. Get assetId from params
2. Verify asset exists and belongs to req.user._id
3. Query CommunityDetection.find({ assetId }).sort({ detectedAt: -1 })
4. Return detections (exclude detectedBy)

**File:** `backend/src/routes/communityRoutes.js`

Add route:
```javascript
router.get('/detections/asset/:assetId', getDetectionsForAsset);
```

### Phase 2: Add Map Dependency (5 min)

**File:** `pubspec.yaml`

Add:
```yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1  # Required by flutter_map
```

Run: `flutter pub get`

### Phase 3: Flutter Models & Services (20 min)

**Create:** `lib/models/community_detection_model.dart`
```dart
class CommunityDetection {
  final String id;
  final String trackerId;
  final String assetId;
  final int rssi;
  final double? latitude;
  final double? longitude;
  final DateTime detectedAt;
  final DateTime createdAt;
  
  factory CommunityDetection.fromJson(Map<String, dynamic> json) { ... }
}
```

**Create:** `lib/services/community_detection_retrieval_service.dart`
```dart
class CommunityDetectionRetrievalService {
  static final instance = CommunityDetectionRetrievalService._();
  
  Future<List<CommunityDetection>> getDetectionsForAsset(String assetId) async {
    final response = await ApiService.instance.get(
      '/api/community/detections/asset/$assetId'
    );
    return (response['detections'] as List)
        .map((json) => CommunityDetection.fromJson(json))
        .toList();
  }
}
```

### Phase 4: TrackAssetScreen (60 min)

**Create:** `lib/screens/track_asset_screen.dart`

**Structure:**
```dart
class TrackAssetScreen extends StatefulWidget {
  final Asset asset;
  ...
}

class _TrackAssetScreenState extends State<TrackAssetScreen> {
  List<CommunityDetection> _detections = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDetections();
  }
  
  Future<void> _loadDetections() async {
    final detections = await CommunityDetectionRetrievalService.instance
        .getDetectionsForAsset(widget.asset.id);
    setState(() {
      _detections = detections;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track ${widget.asset.trackerId}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDetections,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_detections.isEmpty) return _buildEmptyState();
    
    final latest = _detections.first;
    
    return Column(
      children: [
        Expanded(child: _buildMap(latest, _detections)),
        _buildDetectionCard(latest),
        _buildHistoryList(_detections),
      ],
    );
  }
  
  Widget _buildMap(CommunityDetection latest, List<CommunityDetection> all) {
    // flutter_map implementation
    return FlutterMap(...);
  }
  
  Widget _buildDetectionCard(CommunityDetection detection) { ... }
  Widget _buildHistoryList(List<CommunityDetection> detections) { ... }
  Widget _buildEmptyState() { ... }
}
```

**Map implementation:**
```dart
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(latest.latitude!, latest.longitude!),
    initialZoom: 15.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.assetguard',
    ),
    MarkerLayer(
      markers: _buildMarkers(_detections),
    ),
  ],
)
```

### Phase 5: Update AssetDetailsScreen (15 min)

**File:** `lib/screens/asset_details_screen.dart`

1. Add `_latestDetection` state variable
2. Load latest detection in `initState()`
3. Update `_infoRow` to show real data:
   - Location: coordinates or reverse geocoded location
   - Time: detectedAt formatted
   - Signal: "${rssi} dBm"
4. Change `_trackAsset()` to navigate to TrackAssetScreen:
   ```dart
   void _trackAsset() {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => TrackAssetScreen(asset: _asset),
       ),
     );
   }
   ```

### Phase 6: Reverse Geocoding (Optional - 20 min)

**Package:** Use `geocoding` package or HTTP reverse geocoding API

**Implementation:**
```dart
Future<String?> _getAddressFromCoordinates(double lat, double lng) async {
  try {
    // Using geocoding package or Nominatim API
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return '${place.locality}, ${place.administrativeArea}';
    }
  } catch (e) {
    debugPrint('[ReverseGeocode] Failed: $e');
  }
  return null; // Fallback to coordinates
}
```

---

## Security Verification

✅ Asset ownership verified via `asset.userId === req.user._id`  
✅ detectedBy field excluded from response (User B identity hidden)  
✅ JWT required on all endpoints  
✅ User can only fetch detections for their own assets  

---

## UI/UX Requirements

### Track Asset Screen

**AppBar:**
- Title: "Track [trackerId]"
- Refresh button

**Map (50% of screen):**
- Latest detection: Red marker with label
- Previous detections: Gray markers
- Zoom/pan enabled
- OpenStreetMap tiles

**Latest Detection Card:**
```
┌─────────────────────────────────┐
│ Last Detected                   │
│                                 │
│ Asset: Your laptop              │
│ Tracker: AG-001                 │
│ Location: Near Campus Library   │
│ Coordinates: 12.3711, 76.5853   │
│ Detected: Aug 28, 12:30 PM      │
│ Signal: -60 dBm                 │
│                                 │
│ ⏱ Last seen 2 minutes ago       │
└─────────────────────────────────┘
```

**Detection History (scrollable):**
```
┌─────────────────────────────────┐
│ Detection History               │
│                                 │
│ 12:30 PM    📍 Location A       │
│             -60 dBm             │
│                                 │
│ 12:00 PM    📍 Location B       │
│             -62 dBm             │
│                                 │
│ 11:30 AM    📍 Location B       │
│             -59 dBm             │
└─────────────────────────────────┘
```

### Asset Details Screen Updates

**Before:**
```
Location: Not yet detected
Time: Not yet detected
Signal: BLE tracking not yet active
```

**After (with detections):**
```
Location: 12.3711, 76.5853
Time: Today, 12:30 PM
Signal: -60 dBm (Community detected)
```

**After (no detections):**
```
Location: No community detections yet
Time: —
Signal: —
```

---

## Implementation Estimate

| Phase | Time | Status |
|-------|------|--------|
| Backend API | 30 min | ❌ Not started |
| Map dependency | 5 min | ❌ Not started |
| Flutter models/services | 20 min | ❌ Not started |
| TrackAssetScreen | 60 min | ❌ Not started |
| AssetDetailsScreen update | 15 min | ❌ Not started |
| Reverse geocoding | 20 min | ⚠️ Optional |
| Testing & refinement | 30 min | ❌ Not started |
| **Total** | **3 hours** | ❌ |

---

## Files to Create

**Backend:**
- None (modify existing files only)

**Flutter:**
1. `lib/models/community_detection_model.dart` (NEW)
2. `lib/services/community_detection_retrieval_service.dart` (NEW)
3. `lib/screens/track_asset_screen.dart` (NEW)

**Files to Modify:**
1. `pubspec.yaml` (add flutter_map)
2. `backend/src/controllers/communityController.js` (add getDetectionsForAsset)
3. `backend/src/routes/communityRoutes.js` (add GET route)
4. `lib/screens/asset_details_screen.dart` (update _trackAsset, fetch latest detection)

---

## Testing Checklist

### Backend Testing
- [ ] GET /api/community/detections/asset/:assetId returns detections
- [ ] Returns 401 if not authenticated
- [ ] Returns 403/404 if asset doesn't belong to user
- [ ] Detections sorted newest first
- [ ] detectedBy field excluded from response

### Flutter Testing
- [ ] "Track Asset" button opens TrackAssetScreen
- [ ] Map displays with correct center
- [ ] Latest detection marker appears
- [ ] Detection card shows correct data
- [ ] Detection history list shows all detections
- [ ] Refresh button fetches new detections
- [ ] Empty state shown when no detections
- [ ] Asset details shows latest detection info
- [ ] Coordinates displayed as fallback
- [ ] Human-readable location shown (if reverse geocoding implemented)

### Integration Testing (Two Phones)
- [ ] User B detects AG-001 → detection created in MongoDB
- [ ] User A opens Track Asset → sees detection on map
- [ ] User B moves and detects again → User A refreshes → new location shown
- [ ] Detection history shows multiple points
- [ ] Map trail connects detection points (if implemented)
- [ ] User B identity not exposed anywhere

---

## Known Limitations

1. **Not real-time GPS tracking** — AG-001 has no GPS, only shows community detection locations
2. **Polling-based updates** — User A must manually refresh (acceptable for Phase 3)
3. **No battery info** — Tracker battery status not available yet
4. **Reverse geocoding optional** — Falls back to coordinates if not implemented
5. **Map requires internet** — OpenStreetMap tiles need network (can cache for offline later)

---

## Next Steps

1. Implement backend GET endpoint
2. Add flutter_map to pubspec.yaml
3. Create Flutter models and services
4. Build TrackAssetScreen with map
5. Update AssetDetailsScreen
6. Test end-to-end with two phones
7. Build APK and verify on physical devices
