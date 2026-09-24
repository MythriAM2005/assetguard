# ASSETGUARD AI - PRESENTATION QUICK REFERENCE GUIDE

## 🎯 PROJECT OVERVIEW (30 seconds)

**What**: Indoor asset tracking system for campus using community-powered detection + ML room prediction

**Problem**: Lost laptops/wallets on campus, GPS doesn't work indoors

**Solution**: 
1. Students attach BLE trackers (AG-001) to belongings
2. Other students' phones automatically scan for lost items
3. Wi-Fi fingerprinting + ML predicts which room
4. Owner gets notification: "Your Laptop detected in Room 310"

---

## 📊 SYSTEM ARCHITECTURE

### Three Components:
```
1. Flutter App (Android)
   ├─ User interface
   ├─ BLE scanning
   └─ Wi-Fi scanning

2. Node.js Backend (Express + MongoDB)
   ├─ User authentication (JWT)
   ├─ Asset management
   ├─ Community detection logic
   └─ Notification system

3. Python ML Server (FastAPI + scikit-learn)
   └─ Random Forest model (97.96% accuracy)
```

---

## 🔑 KEY TECHNOLOGIES

| Layer | Technology | Why |
|-------|-----------|-----|
| Mobile | Flutter | Cross-platform, single codebase |
| BLE | flutter_blue_plus | Low-power proximity detection |
| Wi-Fi | wifi_scan | Indoor positioning fingerprints |
| Backend | Node.js + Express | Fast, async, JavaScript ecosystem |
| Database | MongoDB | Flexible schema, geospatial queries |
| Auth | JWT | Stateless, scalable authentication |
| ML | Random Forest (scikit-learn) | High accuracy, interpretable |

---

## 📱 USER FLOW

### Owner (User A) Flow:
```
1. Register → Login
2. Add Asset ("Laptop", tracker "AG-001")
3. Asset gets lost
4. Mark as LOST
5. Wait for community detection
6. Receive notification: "Detected in Room 310"
7. View Track Asset map
8. Find asset → Mark as RECOVERED
```

### Community Member (User B) Flow:
```
1. Register → Login
2. Enable "Community Sensing"
3. App runs in background
4. Automatic BLE + Wi-Fi scanning every 15s
5. Detects lost tracker → Sends to backend
6. Helps others find their belongings
```

---

## 🔵 BLUETOOTH (BLE) SYSTEM

### What Gets Detected:
- **Tracker ID**: AG-001, AG-002, etc.
- **RSSI**: Signal strength (-40 dBm = close, -90 dBm = far)
- **MAC Address**: Device identifier

### Detection Process:
```
Every 15 seconds:
1. Scan for BLE devices (8 seconds)
2. Filter AssetGuard trackers (AG-XXX)
3. Check debounce (60s minimum between reports)
4. Get cached Wi-Fi fingerprint
5. Send to backend with tracker ID + RSSI + Wi-Fi
```

### Why BLE?
- Low power (months on coin battery)
- 10-50m range indoors
- Privacy (no internet needed)
- Every phone has BLE
- RSSI indicates proximity

---

## 📶 WI-FI FINGERPRINTING

### What is a Wi-Fi Fingerprint?
Map of visible access points + signal strengths:
```json
{
  "84:d8:1b:aa:bb:cc": -43,  // AP 1
  "84:d8:1b:11:22:33": -67,  // AP 2
  "84:d8:1b:44:55:66": -89   // AP 3
}
```

### Why Wi-Fi?
- GPS doesn't work indoors
- Wi-Fi APs are everywhere on campus
- Different rooms see different APs
- Signal strength varies by location
- Perfect ML features

### BSSID vs SSID:
- **SSID**: "NIE-STUDENTS" (network name) - Same everywhere
- **BSSID**: "84:d8:1b:aa:bb:cc" (AP MAC address) - Unique per AP

### Scanning:
- **Interval**: Every 15 seconds
- **Filter**: Only NIE-STUDENTS and NIE-STAFF networks
- **Typical**: 70-100 BSSIDs per scan
- **Cache**: 2 minute validity

---

## 🤖 MACHINE LEARNING

### Model Type: Random Forest Classifier

### Input Features:
- **106 BSSID features**: Most common access points on campus
- Each feature = RSSI value for that BSSID
- Missing BSSIDs = -100 dBm (not visible)

### Output:
- **22 room classes**: "310", "312", "314", etc.
- **Confidence score**: 0.0 to 1.0 (e.g., 0.38 = 38%)

### Training:
1. Collected Wi-Fi fingerprints from 22 rooms
2. Multiple samples per room (different times/positions)
3. Trained Random Forest with 100 trees
4. Accuracy: 97.96%

### ML Server Communication:
```
Backend → POST http://10.135.90.221:8000/predict-room
Request:  {"wifi": {"84:d8:1b:aa:bb:cc": -43, ...}}
Response: {"room": "310", "confidence": 0.376667}
```

### Why Random Forest?
- High accuracy on Wi-Fi data
- Handles missing features well
- Fast prediction (<100ms)
- Interpretable results
- Robust to outliers

---

## 🔐 AUTHENTICATION

### JWT (JSON Web Token):
```
Login → Backend generates JWT → Flutter stores in SharedPreferences
Every API call → Include JWT in Authorization header
Backend verifies JWT → Extracts user ID → Processes request
```

### Security Features:
- Passwords hashed with bcrypt
- JWT expires after 7 days
- Token verified on every request
- Email verification (production mode)
- Ownership checks (user can only edit own assets)

---

## 📊 MONGODB COLLECTIONS

### Users:
- `_id`, `name`, `email`, `password` (hashed)
- `emailVerified`, `tokens`

### Assets:
- `_id`, `name`, `trackerId`, `status`, `userId`
- Status: 'ACTIVE', 'LOST', 'RECOVERED'

### CommunityDetections:
- `_id`, `trackerId`, `assetId`, `detectedBy`
- `rssi`, `latitude`, `longitude`
- `predictedRoom`, `roomConfidence`
- `detectedAt`

### Notifications:
- `_id`, `recipient`, `type`, `title`, `message`
- `assetId`, `trackerId`, `predictedRoom`
- `read`, `createdAt`

---

## 🌊 COMPLETE DETECTION FLOW

```
User B (Community Member):
├─ Community Sensing enabled
├─ Background scanning:
│  ├─ BLE scan every 15s → Detects AG-001
│  └─ Wi-Fi scan every 15s → Caches fingerprint
│
├─ Detection triggered:
│  ├─ Check debounce (>60s since last report?)
│  ├─ Get Wi-Fi from cache
│  └─ POST /api/community/detections {trackerId, rssi, wifiFingerprint}
│
Backend:
├─ Lookup asset by trackerId
├─ Check asset.status === 'LOST'? (Critical check!)
├─ Verify detector ≠ owner
├─ Call ML: POST /predict-room → Get room + confidence
├─ Create CommunityDetection record
├─ Create Notification for owner
│
User A (Asset Owner):
├─ Receives push notification
├─ Opens app → Notifications screen
└─ Sees: "Your Laptop (AG-001) detected in Room 310 (38% confidence)"
```

---

## 🎨 UI SCREENS

1. **SplashScreen**: Auto-login check
2. **LoginScreen**: Email + password
3. **RegisterScreen**: Create account
4. **HomeScreen**: Dashboard (Total/Lost/Tracking counts)
5. **MyAssetsScreen**: List all assets
6. **AssetDetailsScreen**: View/Edit/Delete/Mark Lost/Mark Recovered
7. **TrackAssetScreen**: Map with detection markers
8. **NotificationsScreen**: Detection notifications with room predictions
9. **ProfileScreen**: User info, Community Sensing toggle

---

## 🚨 CRITICAL FEATURES

### 1. Status Check (Prevents Spam):
```javascript
// backend/src/controllers/communityController.js
if (asset.status !== 'LOST') {
  return error(res, 'Asset not found', 404);
}
```
**Why**: After recovery, detections are ignored (no more notifications)

### 2. Ownership Verification:
```javascript
if (asset.userId._id === req.user._id) {
  return error(res, 'Cannot report own asset', 404);
}
```
**Why**: Owner cannot report their own asset (prevents abuse)

### 3. Debounce (60s):
Prevents duplicate reports for same tracker within 60 seconds

### 4. Cache (2min):
Wi-Fi fingerprint cached to include with BLE detections

### 5. Foreground Service:
Required for background BLE/Wi-Fi scanning on Android

---

## 📈 DASHBOARD STATISTICS

### Total Assets:
Count of all user's assets (any status)

### Lost:
Count of assets with `status = 'LOST'`

### Tracking:
**Definition**: Lost assets with recent community detections (last 7 days)

**Query**:
```javascript
// Find lost assets
const lostAssets = await Asset.find({userId, status: 'LOST'});

// For each lost asset, check for recent detections
const tracking = await Promise.all(
  lostAssets.map(async (asset) => {
    const recentDetection = await CommunityDetection.findOne({
      assetId: asset._id,
      detectedAt: {$gte: new Date(Date.now() - 7*24*60*60*1000)}
    });
    return recentDetection ? 1 : 0;
  })
);

const trackingCount = tracking.reduce((a,b) => a+b, 0);
```

---

## 🛠️ MARK AS RECOVERED

### What Happens:
```
User taps "Mark as Recovered"
↓
PUT /api/assets/:id/recover
↓
Backend updates: asset.status = 'RECOVERED'
↓
Future detections:
  Backend checks: asset.status === 'LOST'?
  NO → Return 404 (detection ignored)
  NO notification created
```

### Why Important:
- Stops notifications after user finds asset
- Prevents spam
- User explicitly confirms recovery

---

## ⚠️ ERROR HANDLING

### No Wi-Fi Fingerprint:
- Detection succeeds without fingerprint
- No room prediction
- Notification shows GPS instead
- Graceful degradation

### ML Server Down:
- 10 second timeout
- Detection succeeds without room
- System continues working

### Bluetooth Off:
- Show error: "Please enable Bluetooth"
- Community Sensing cannot start

### No Permissions:
- Request on startup
- Show rationale
- Guide user to settings if denied

---

## 🔒 SECURITY CONSIDERATIONS

1. **Authentication**: JWT on every request
2. **Authorization**: Ownership verified (user A cannot edit user B's assets)
3. **Password Storage**: Bcrypt hashing (never plain text)
4. **API Protection**: All endpoints except login/register require auth
5. **Privacy**: Detector identity hidden from owner
6. **Validation**: Input validated on client and server

---

## TOP 10 FILES TO KNOW

### Flutter:
1. **`lib/main.dart`** - Entry point, deep links
2. **`lib/services/community_sensing_service.dart`** - Background scanning orchestrator
3. **`lib/services/ble_service.dart`** - Bluetooth detection
4. **`lib/services/wifi_scan_service.dart`** - Wi-Fi scanning
5. **`lib/services/auth_service.dart`** - Authentication + JWT management

### Backend:
6. **`backend/src/controllers/communityController.js`** - Detection logic + ML integration
7. **`backend/src/controllers/authController.js`** - Login/register
8. **`backend/src/models/Asset.js`** - Asset schema (LOST status check)
9. **`backend/src/middleware/auth.js`** - JWT verification
10. **`backend/src/models/CommunityDetection.js`** - Detection records + room data

---

## 📝 30 VIVA QUESTIONS & ANSWERS

### Architecture Questions

**Q1: Why Flutter instead of native Android/iOS?**
A: Single codebase for both platforms, faster development, hot reload for quick iteration, large community support.

**Q2: Why Node.js backend instead of Python/Java?**
A: JavaScript full-stack (easier team collaboration), async/await for I/O operations, npm ecosystem, fast for API servers.

**Q3: Why MongoDB instead of MySQL/PostgreSQL?**
A: Flexible schema (easy to add fields like predictedRoom later), JSON-native (matches API responses), geospatial queries built-in.

**Q4: Why separate ML server from backend?**
A: Different tech stacks (Python for ML, Node for API), independent scaling, ML server can be updated without affecting backend, security isolation.

**Q5: Explain the complete system architecture.**
A: Three-tier: Flutter app (presentation layer), Node.js backend (business logic + data), MongoDB (persistence). Plus Python ML server for room prediction.

---

### Bluetooth Questions

**Q6: Why BLE instead of classic Bluetooth?**
A: BLE uses 100x less power, longer battery life for trackers, designed for IoT devices, all modern phones support it.

**Q7: What is RSSI and how is it used?**
A: Received Signal Strength Indicator in dBm. Range -120 (weak) to 0 (strong). Indicates proximity: -40 dBm = very close, -90 dBm = far. Displayed in notifications and debugging.

**Q8: Why scan for 8 seconds every 15 seconds?**
A: 8s: Long enough to discover devices but not drain battery. 15s interval: Balance between detection speed and battery life. Too frequent = battery drain, too slow = miss movement.

**Q9: What is the debounce period and why?**
A: 60 seconds. Prevents duplicate notifications if User B's phone detects same tracker multiple times. Balance: too short = spam, too long = miss room changes.

**Q10: Why does BLE scanning require location permission?**
A: Android security: BLE can determine location, treated as location data. Even though AssetGuard doesn't use for navigation, permission required by OS.

---

### Wi-Fi Questions

**Q11: What is Wi-Fi fingerprinting?**
A: Snapshot of visible Wi-Fi access points and their signal strengths. Each location has unique "signature" of APs. Used for indoor positioning where GPS fails.

**Q12: What is BSSID and why not just use SSID?**
A: BSSID = MAC address of specific access point (unique). SSID = network name (e.g., "NIE-STUDENTS", same across many APs). Need BSSID to distinguish individual APs for room-level accuracy.

**Q13: Why filter only NIE-STUDENTS and NIE-STAFF?**
A: Campus-specific: Only campus infrastructure APs are relevant. Filters out: personal hotspots, neighboring buildings, home Wi-Fi. Ensures fingerprints are from consistent infrastructure.

**Q14: Why cache Wi-Fi fingerprints for 2 minutes?**
A: BLE and Wi-Fi scans are independent. Cache ensures BLE detection can include recent Wi-Fi data. 2 min: APs don't move (stable), but not too stale if user moves rooms.

**Q15: What happens if no Wi-Fi fingerprint available?**
A: Graceful degradation: Detection succeeds without fingerprint. No ML prediction. Notification shows GPS coordinates instead of room number. System still works!

---

### ML Questions

**Q16: Why Random Forest classifier?**
A: High accuracy on Wi-Fi data (97.96%), handles missing features well (APs not always visible), fast prediction, interpretable results, robust to outliers.

**Q17: What are the input features?**
A: 106 BSSID features (most common APs on campus). Each feature = RSSI value (-120 to 0 dBm). Missing BSSIDs = -100 dBm (not visible).

**Q18: What are the output classes?**
A: 22 room numbers on campus (e.g., "310", "312", "314"). Model also returns confidence score (0.0 to 1.0).

**Q19: Why 106 BSSIDs specifically?**
A: Feature selection: Most frequently appearing BSSIDs across all training locations. Balances: too few = poor accuracy, too many = overfitting/slow.

**Q20: How was the model trained?**
A: Collected Wi-Fi fingerprints from 22 rooms, multiple samples per room (different times/positions), trained Random Forest with 100 trees, cross-validation for accuracy.

---

### Community Sensing Questions

**Q21: What is Community Sensing?**
A: Users help each other find lost items. When User B enables it, their phone automatically scans for lost trackers in background and reports detections to owners.

**Q22: Why foreground service with notification?**
A: Android requirement: Background location/BLE access needs foreground service. Persistent notification keeps service alive and transparent to user (they know it's running).

**Q23: How does detector help without knowing whose asset?**
A: Backend handles matching: User B reports "AG-001 detected". Backend looks up owner of AG-001, creates notification for them. User B never knows who they helped (privacy).

**Q24: Why can't owner report their own asset?**
A: Prevents abuse: Owner could spam fake detections. Community sensing is for *others* to help. Owner uses normal tracking features.

**Q25: What happens when asset is marked RECOVERED?**
A: Status changes to 'RECOVERED'. Backend checks status on every detection. If not 'LOST', detection is rejected (returns 404). No notification created. Stops spam after recovery.

---

### Technical Implementation Questions

**Q26: How does authentication work?**
A: JWT (JSON Web Token): Login → backend generates JWT with user ID → Flutter stores in SharedPreferences → Every API call includes "Authorization: Bearer <JWT>" header → Backend verifies signature → Extracts user ID → Processes request.

**Q27: Explain the complete detection flow.**
A: User B: BLE detects AG-001 + Wi-Fi fingerprint → POST /api/community/detections → Backend: Lookup asset, check status='LOST', verify not owner, call ML server, create detection record + notification → User A: Receives push notification, opens app, sees "Detected in Room 310".

**Q28: What prevents duplicate detections?**
A: Two mechanisms: 1) Debounce (60s minimum between reports for same tracker), 2) Status check (only LOST assets generate notifications).

**Q29: Why is ML server separate?**
A: Different tech stacks (Python scikit-learn vs Node.js), independent deployment/scaling, security isolation, can update ML model without touching backend.

**Q30: What are the main database collections?**
A: Users (accounts), Assets (belongings + tracker IDs), CommunityDetections (detection history with GPS/room), Notifications (messages to owners with room predictions).

---

## 🎤 PRESENTATION STRUCTURE (15 minutes)

### 1. Problem Statement (2 min)
- Lost items on campus (laptops, wallets)
- GPS doesn't work indoors
- Need community-powered solution

### 2. Solution Overview (2 min)
- BLE trackers for proximity detection
- Wi-Fi fingerprinting for room location
- ML model for room prediction
- Community helping each other

### 3. System Architecture (3 min)
- Show diagram: Flutter ↔ Backend ↔ ML Server
- Explain each component's role
- Database schema

### 4. Demo (5 min)
- User A creates asset, marks as LOST
- User B enables Community Sensing
- Show detection happening (logs)
- User A receives notification with room
- Track Asset map view

### 5. Technical Deep Dive (2 min)
- BLE: How trackers are detected
- Wi-Fi: How fingerprints work
- ML: Random Forest with 97.96% accuracy

### 6. Results & Conclusion (1 min)
- System works end-to-end
- 22 rooms, 106 features
- Real campus deployment ready
- Future improvements

---

## 🚀 DEMO CHECKLIST

Before presentation:
- [ ] Backend running (port 5000)
- [ ] ML server running (port 8000)
- [ ] MongoDB running
- [ ] Two Android phones ready
- [ ] Phone A: User A logged in, asset AG-001 marked LOST
- [ ] Phone B: User B logged in, Community Sensing enabled
- [ ] Test detection once to verify

During demo:
1. Show Phone A: Asset marked LOST
2. Show Phone B: Community Sensing ON (persistent notification)
3. Bring phones close together
4. Show logs: BLE detection → Wi-Fi included → Backend response
5. Show Phone A: New notification with room number
6. Open Track Asset: Show detection on map

---

## 💡 FUTURE IMPROVEMENTS

1. **iOS Support**: Currently Android-only due to BLE background limitations
2. **More Rooms**: Expand from 22 to full campus (100+ rooms)
3. **Real-time Updates**: WebSocket for instant notifications
4. **Battery Optimization**: Adaptive scan frequency based on movement
5. **Privacy**: End-to-end encryption for detection data
6. **Analytics**: Heatmaps of common loss locations
7. **Social Features**: Thank community members who helped

---

## 📚 KEY REFERENCES

- Flutter BLE: `flutter_blue_plus` package documentation
- Wi-Fi Scan: `wifi_scan` package documentation
- Foreground Service: `flutter_foreground_task` package
- Random Forest: scikit-learn documentation
- JWT: jsonwebtoken library (Node.js)
- MongoDB: Mongoose ODM documentation

---

**GOOD LUCK WITH YOUR PRESENTATION! 🎓**

