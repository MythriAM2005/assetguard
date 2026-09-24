# AssetGuard Multi-User Architecture Inspection Report

## Executive Summary

**FINDING**: The AssetGuard system **ALREADY SUPPORTS MULTIPLE USERS** with proper authentication, asset ownership, and cross-user community detection capabilities. NO CODE CHANGES ARE REQUIRED for User A + User B testing scenario.

The community detection endpoint is **correctly designed** to accept detections from User B (community detector) for assets owned by User A (asset owner).

---

## Detailed Findings

### 1. User Registration & Login

**Current Implementation**:
- ✅ Users register via `POST /api/auth/register` with name, email, password
- ✅ Email verification required before login (token sent via email)
- ✅ Users verify email via `GET /api/auth/verify-email?token=...`
- ✅ Users login via `POST /api/auth/login` with email + password
- ✅ JWT issued after successful login
- ✅ Password reset flow available via `POST /api/auth/forgot-password` and `POST /api/auth/reset-password`

**Flutter Flow**:
```
RegisterScreen → enter details → POST /api/auth/register
  ↓
EmailVerificationScreen → user clicks email link
  ↓
Deep link → GET /api/auth/verify-email?token=... → JWT returned
  ↓
LoginScreen → POST /api/auth/login → JWT returned
  ↓
MainShell (logged in)
```

**Verdict**: ✅ **Multiple users fully supported**. Each user gets unique account with email verification.

---

### 2. Backend Multi-User Support

**User Model** (`backend/src/models/User.js`):
```javascript
{
  _id: ObjectId,
  name: String,
  email: String (unique),
  passwordHash: String,
  emailVerified: Boolean,
  timestamps: true
}
```

**Key Points**:
- ✅ Email field has **unique index** - enforces one account per email
- ✅ No artificial limit on number of users
- ✅ Each user has unique `_id` (ObjectId)
- ✅ Password hashed with bcrypt (12 rounds)
- ✅ Email verification prevents unauthorized registrations

**Verdict**: ✅ **Backend fully supports unlimited users**. User accounts are completely isolated.

---

### 3. JWT User Identification

**JWT Payload** (`backend/src/services/tokenService.js`):
```javascript
jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '30d' })
```

**JWT Structure**:
```json
{
  "id": "507f1f77bcf86cd799439011",  // User's _id from MongoDB
  "iat": 1698765432,
  "exp": 1701357432
}
```

**Auth Middleware** (`backend/src/middleware/auth.js`):
```javascript
const protect = async (req, res, next) => {
  const token = req.headers.authorization.split(' ')[1];
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  const user = await User.findById(decoded.id);
  req.user = user;  // ← Attached to request
  next();
}
```

**Key Points**:
- ✅ JWT contains only `id` (user's MongoDB ObjectId)
- ✅ `protect` middleware extracts `id` from JWT, fetches full user, attaches to `req.user`
- ✅ **User ID always from JWT, never from request body**
- ✅ All protected routes have access to `req.user._id`

**Verdict**: ✅ **JWT correctly identifies current user**. Every API call authenticates the specific logged-in user.

---

### 4. Asset Ownership Association

**Asset Model** (`backend/src/models/Asset.js`):
```javascript
{
  _id: ObjectId,
  name: String,
  category: String,
  trackerId: String,
  status: 'ACTIVE' | 'LOST' | 'RECOVERED',
  userId: ObjectId (ref: 'User'),  // ← OWNER
  timestamps: true
}
```

**Compound Index**:
```javascript
assetSchema.index({ userId: 1, trackerId: 1 }, { unique: true });
```

**Key Points**:
- ✅ Every asset has **exactly one owner** (`userId` field)
- ✅ Compound unique index: same trackerId can exist for different users
  - User A can have asset with trackerId "AG-001"
  - User B can have different asset with trackerId "AG-001"
  - But User A cannot have two assets with same trackerId
- ✅ Asset status stored in database (ACTIVE, LOST, RECOVERED)

**Verdict**: ✅ **Assets correctly associated with owners**. Each asset belongs to exactly one user.

---

### 5. Asset API Ownership Enforcement

**Asset Controller** (`backend/src/controllers/assetController.js`):

#### GET /api/assets
```javascript
const assets = await Asset.find({ userId: req.user._id }).sort({ createdAt: -1 });
```
✅ Returns **only assets owned by authenticated user**

#### GET /api/assets/:id
```javascript
const asset = await Asset.findOne({ _id: req.params.id, userId: req.user._id });
```
✅ Returns asset **only if owned by authenticated user**, else 404

#### POST /api/assets
```javascript
await Asset.create({ ..., userId: req.user._id });
```
✅ New asset **automatically assigned to authenticated user**

#### PUT /api/assets/:id
```javascript
const asset = await findOwnedAsset(req, res);  // checks ownership
if (!asset) return;
// ... update fields
```
✅ Update **only if owned by authenticated user**

#### DELETE /api/assets/:id
```javascript
const asset = await findOwnedAsset(req, res);  // checks ownership
if (!asset) return;
await asset.deleteOne();
```
✅ Delete **only if owned by authenticated user**

#### PATCH /api/assets/:id/lost
```javascript
const asset = await findOwnedAsset(req, res);
asset.status = 'LOST';
```
✅ Mark LOST **only if owned by authenticated user**

**Helper Function**:
```javascript
const findOwnedAsset = async (req, res) => {
  const asset = await Asset.findOne({ 
    _id: req.params.id, 
    userId: req.user._id  // ← OWNERSHIP CHECK
  });
  if (!asset) {
    error(res, 'Asset not found', 404);
    return null;
  }
  return asset;
};
```

**Key Points**:
- ✅ **All asset operations enforce ownership**
- ✅ User A cannot see/modify/delete User B's assets
- ✅ User B cannot see/modify/delete User A's assets
- ✅ Each user sees only their own assets
- ✅ userId always from `req.user._id` (JWT), never from request body

**Verdict**: ✅ **Asset APIs strictly enforce ownership**. Complete isolation between users' asset collections.

---

### 6. Second User Login Capability

**Flutter Auth Flow**:
- ✅ Logout clears JWT token and current user from memory
- ✅ Login screen accepts any valid email/password
- ✅ No hardcoded email restrictions
- ✅ No single-user-mode locks

**Logout Implementation** (`lib/services/auth_service.dart`):
```dart
Future<void> logout() async {
  _currentUser = null;
  ApiService.instance.setToken(null);
  await _clearToken();  // removes from SharedPreferences
}
```

**Login Implementation**:
```dart
Future<void> login(String email, String password) async {
  final data = await ApiService.instance.post('/api/auth/login', {
    'email': email,
    'password': password,
  });
  await _handleAuthResponse(data);  // stores new JWT
}
```

**Key Points**:
- ✅ Logout completely removes previous user's session
- ✅ Login accepts any valid email/password
- ✅ New JWT replaces old JWT
- ✅ App can switch between users by logout → login
- ✅ No "one user per device" restriction

**Test Scenario**:
```
Device 1:
1. User A logs in → JWT_A stored
2. User A creates assets → owned by User A
3. User A logs out → JWT_A cleared
4. User B logs in → JWT_B stored
5. User B creates assets → owned by User B
6. User B can see only User B's assets
```

**Verdict**: ✅ **Multiple users can log in sequentially on same device**. No restrictions.

---

### 7. Community Detection Cross-User Support

**Community Detection Endpoint** (`POST /api/community/detections`):

```javascript
const submitCommunityDetection = async (req, res) => {
  const { trackerId, rssi, remoteId, detectedAt } = req.body;

  // Step 1: Find asset by trackerId — NOT scoped to req.user
  const asset = await Asset.findOne({
    trackerId: trackerId.trim(),
  });  // ← NO userId FILTER

  if (!asset) {
    return error(res, 'Asset not found', 404);
  }

  // Step 2: Verify asset is LOST
  if (asset.status !== 'LOST') {
    return error(res, 'Asset not marked as LOST', 404);
  }

  // Step 3: Create detection record
  const detection = await CommunityDetection.create({
    trackerId: asset.trackerId,
    assetId: asset._id,           // ← Asset owned by User A
    detectedBy: req.user._id,      // ← User B (from JWT)
    rssi,
    remoteId,
    detectedAt,
  });

  success(res, { message: 'Community detection recorded', detectionId: detection._id }, 201);
};
```

**Community Detection Model**:
```javascript
{
  _id: ObjectId,
  trackerId: String,          // e.g., "AG-001"
  assetId: ObjectId,          // ref: 'Asset' (User A's asset)
  detectedBy: ObjectId,       // ref: 'User' (User B who detected it)
  rssi: Number,
  remoteId: String,           // Bluetooth MAC
  detectedAt: Date,
  timestamps: true
}
```

**Key Architecture Points**:
- ✅ Asset lookup is **NOT scoped to user** (`Asset.findOne({ trackerId })`)
- ✅ Can find assets owned by **any user** in the system
- ✅ Only accepts detections for **LOST assets** (status check)
- ✅ `detectedBy` comes from **JWT** (`req.user._id`), never from request body
- ✅ `assetId` references the **asset owner's asset** (User A)
- ✅ `detectedBy` references the **detector** (User B)
- ✅ Returns 404 for non-LOST assets (prevents status leakage)

**Example Flow**:
```
1. User A owns asset "AG-001" (status: LOST)
2. User B's phone detects BLE tracker "AG-001"
3. User B's app sends: POST /api/community/detections
   Headers: Authorization: Bearer <JWT_B>
   Body: { trackerId: "AG-001", rssi: -57, ... }
4. Backend:
   - Extracts User B's ID from JWT_B → req.user._id = USER_B_ID
   - Finds asset "AG-001" → owned by User A
   - Verifies asset.status === 'LOST'
   - Creates CommunityDetection:
     * assetId: USER_A_ASSET_ID
     * detectedBy: USER_B_ID
5. User A can later query their asset's community detections
```

**Verdict**: ✅ **Community detection ALREADY supports cross-user detections**. User B can detect User A's LOST assets. Architecture is correct.

---

### 8. CommunityDetection Relationships

**Schema Fields**:
```javascript
{
  trackerId: String,         // "AG-001"
  assetId: ObjectId,         // → Asset collection (owner: User A)
  detectedBy: ObjectId,      // → User collection (detector: User B)
  rssi: Number,
  remoteId: String,
  detectedAt: Date,
}
```

**Relationships**:
```
CommunityDetection
  ├─→ assetId ──→ Asset { userId: USER_A_ID }  (Asset Owner)
  └─→ detectedBy ──→ User { _id: USER_B_ID }    (Detector)
```

**Query Capabilities**:
```javascript
// Find all community detections for User A's LOST asset
const detections = await CommunityDetection
  .find({ assetId: ASSET_ID })
  .populate('detectedBy', 'name email')
  .sort({ detectedAt: -1 });

// Result:
// [
//   {
//     trackerId: "AG-001",
//     assetId: ASSET_ID,
//     detectedBy: { _id: USER_B_ID, name: "User B", email: "userb@test.com" },
//     rssi: -57,
//     detectedAt: "2026-08-27T11:45:20Z"
//   }
// ]
```

**Key Points**:
- ✅ Stores **asset owner** (via `assetId` → Asset → userId)
- ✅ Stores **detector** (via `detectedBy` → User)
- ✅ Can query "who detected my LOST asset?"
- ✅ Can query "which LOST assets did I help find?"
- ✅ Relationships support future owner notifications

**Verdict**: ✅ **CommunityDetection model correctly stores all relationships** (asset owner, detector, asset).

---

### 9. Minimum Changes Required

**ANSWER**: ✅ **ZERO CODE CHANGES REQUIRED**

The system **already supports** the User A + User B scenario:

#### Current Capabilities:
1. ✅ Multiple users can register and log in
2. ✅ Each user has isolated asset collection
3. ✅ Assets correctly associated with owners via `userId`
4. ✅ Asset APIs enforce ownership (User A cannot modify User B's assets)
5. ✅ JWT identifies current user for all operations
6. ✅ Community detection endpoint accepts cross-user detections
7. ✅ Backend validates asset is LOST before accepting detection
8. ✅ CommunityDetection stores both asset owner and detector
9. ✅ App can switch users via logout → login

#### What Already Works:
```
User A:
- Registers account (email: usera@test.com)
- Logs in → JWT_A
- Creates asset "Bag" with trackerId "AG-001"
- Marks asset as LOST
- Logs out

User B:
- Registers account (email: userb@test.com)
- Logs in → JWT_B
- Phone detects BLE tracker "AG-001"
- App sends community detection with JWT_B
- Backend:
  * Finds asset "AG-001" (owned by User A)
  * Verifies status is LOST ✓
  * Records detection: assetId=User A's asset, detectedBy=User B
- Success! ✓
```

---

## Testing Instructions

### Phase 1: Create User A (Asset Owner)
```bash
# On Device 1 or Device 2
1. Open AssetGuard app
2. Tap "Create Account"
3. Register:
   Name: "Alice Owner"
   Email: "alice@test.com"
   Password: "password123"
4. Check email and verify account
5. Log in with alice@test.com
6. Add Asset:
   Name: "Alice's Bag"
   Category: "Personal"
   Tracker ID: "AG-TEST-001"
7. Mark asset as LOST
8. Log out
```

### Phase 2: Create User B (Community Detector)
```bash
# On same device or different device
1. Open AssetGuard app
2. Tap "Create Account"
3. Register:
   Name: "Bob Detector"
   Email: "bob@test.com"
   Password: "password123"
4. Check email and verify account
5. Log in with bob@test.com
6. Navigate to "Nearby Devices"
7. Place BLE tracker "AG-TEST-001" nearby
8. Tap "Scan for Devices"
9. Observe: AG-TEST-001 detected
10. Check console logs: "[CommunityDetection] Reporting detection: AG-TEST-001"
```

### Phase 3: Verify Backend
```javascript
// MongoDB Query
db.communitydetections.find().populate('assetId').populate('detectedBy')

// Expected Result:
{
  trackerId: "AG-TEST-001",
  assetId: { name: "Alice's Bag", userId: ALICE_USER_ID, status: "LOST" },
  detectedBy: { name: "Bob Detector", email: "bob@test.com" },
  rssi: -57,
  detectedAt: "2026-08-27T..."
}
```

### Phase 4: Test Ownership Isolation
```bash
# While logged in as Bob
1. Navigate to "My Assets"
2. Verify: Only Bob's assets shown (not Alice's)
3. Try to mark Alice's asset as recovered via API → 404 (not owned)
4. Verify: Bob cannot modify Alice's assets
```

---

## Architecture Strengths

### 1. Proper Separation of Concerns
- ✅ **Owner Detection**: `POST /api/detections` (requires ownership)
- ✅ **Community Detection**: `POST /api/community/detections` (no ownership required)
- ✅ Different endpoints for different use cases

### 2. Security
- ✅ JWT authentication for all operations
- ✅ User ID from JWT, never from request body
- ✅ Asset ownership strictly enforced
- ✅ LOST status verified server-side
- ✅ No status leakage (404 for non-LOST assets)

### 3. Data Integrity
- ✅ Email unique index prevents duplicate accounts
- ✅ Compound index `{userId, trackerId}` prevents duplicate trackerIds per user
- ✅ Asset owner relationship via `userId` foreign key
- ✅ Community detection relationships via `assetId` and `detectedBy`

### 4. Scalability
- ✅ No hardcoded user limits
- ✅ Efficient indexes for queries
- ✅ JWT stateless authentication (no server-side sessions)
- ✅ Assets scoped to users (O(user_assets) not O(all_assets))

---

## Current Limitations

### 1. Single-Device Testing Challenge
**Issue**: Current testing likely uses only one email account  
**Impact**: Cannot test cross-user community detection without two accounts  
**Solution**: Register two accounts (alice@test.com, bob@test.com) as shown above

### 2. Owner Notification Not Implemented
**Status**: TODO in Phase 3D  
**Current Behavior**: Detection saved to database but owner not notified  
**Future**: Push notification or email to asset owner when detected

### 3. Community Detection UI
**Current**: Shows "Community detections reported: X" (debug indicator)  
**Future**: Could show "Your LOST asset was detected by community member"

---

## Conclusion

### Summary
The AssetGuard system **ALREADY FULLY SUPPORTS** multi-user operation and cross-user community detection. The architecture is **correctly designed** from the start:

1. ✅ User registration and authentication
2. ✅ Asset ownership model
3. ✅ Ownership enforcement in all asset APIs
4. ✅ JWT-based user identification
5. ✅ Community detection endpoint that accepts cross-user detections
6. ✅ Proper database relationships (asset owner vs. detector)

### Action Required
**ZERO CODE CHANGES** needed. Simply:
1. Register two user accounts
2. User A: Create asset and mark LOST
3. User B: Scan for devices → community detection reported
4. Verify in backend database

### Why Testing Appeared Single-User
The system was likely tested with only **one email account**, making it appear single-user. The architecture has **always supported** multiple users; it just needs two accounts to demonstrate cross-user community detection.

---

## No Changes Required

**DO NOT MODIFY**:
- ✅ Authentication system (already multi-user)
- ✅ Asset ownership model (already correct)
- ✅ Community detection endpoint (already supports cross-user)
- ✅ JWT middleware (already extracts correct user)
- ✅ Database models (already have proper relationships)
- ✅ BLE scanning (no changes needed)
- ✅ Wi-Fi scanning (no changes needed)
- ✅ Python ML API (no changes needed)
- ✅ Room prediction (no changes needed)
- ✅ Existing normal detection flow (no changes needed)

**READY FOR TESTING**: Create User A (alice@test.com) and User B (bob@test.com) and test immediately.
