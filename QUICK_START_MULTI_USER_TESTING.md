# Quick Start: Multi-User Testing

## 🚀 Ready to Test User A + User B Community Detection

Email verification has been **temporarily disabled** for development testing.

---

## Current Configuration

✅ **EMAIL_VERIFICATION_ENABLED=false** (in `backend/.env`)  
✅ Backend running on port 5000  
✅ Debug APK built: `build/app/outputs/flutter-apk/app-debug.apk`  
✅ Users can register with ANY email address  
✅ No email delivery required  
✅ Automatic login after registration  

---

## Step-by-Step Testing Guide

### Step 1: Install Debug APK on Device

```bash
# Transfer APK to Android phone
adb install build/app/outputs/flutter-apk/app-debug.apk

# OR manually:
# - Copy APK to phone
# - Open file and install
# - Allow installation from unknown sources if prompted
```

---

### Step 2: Register User A (Asset Owner)

**On Device / Emulator**:
1. Open AssetGuard app
2. Tap **"Create Account"**
3. Enter details:
   - **Name**: Alice Owner
   - **Email**: alice@gmail.com *(any email works)*
   - **Password**: password123
   - **Confirm Password**: password123
4. Tap **"Create Account"**
5. ✅ **Automatically logged in** (no email verification needed)
6. ✅ App navigates to **home screen**

---

### Step 3: Create and Mark Asset as LOST

**As User A (Alice)**:
1. Navigate to **"My Assets"**
2. Tap **"Add Asset"** (+) button
3. Enter asset details:
   - **Name**: Alice's Bag
   - **Category**: Personal
   - **Description**: Blue backpack
   - **Tracker ID**: AG-001 *(match your ESP32 tracker)*
4. Tap **"Add Asset"**
5. Find the asset in list
6. Tap on the asset card
7. Tap **"Mark as LOST"** button
8. ✅ Asset status changed to **LOST**

---

### Step 4: Logout User A

1. Navigate to **Profile** (bottom navigation)
2. Tap **"Logout"**
3. ✅ Returned to **login screen**

---

### Step 5: Register User B (Community Detector)

**On Same Device or Different Device**:
1. Tap **"Create Account"**
2. Enter details:
   - **Name**: Bob Detector
   - **Email**: bob@outlook.com *(any different email)*
   - **Password**: password123
   - **Confirm Password**: password123
3. Tap **"Create Account"**
4. ✅ **Automatically logged in**
5. ✅ App navigates to **home screen**

---

### Step 6: Verify User Isolation

**As User B (Bob)**:
1. Navigate to **"My Assets"**
2. ✅ **Empty list** or only Bob's assets
3. ❌ **Cannot see** Alice's "Alice's Bag" asset
4. ✅ **User isolation confirmed**

---

### Step 7: Test Community Detection

**As User B (Bob)**:
1. Place **ESP32 tracker "AG-001"** nearby (the one Alice marked as LOST)
2. Navigate to **"Nearby Devices"**
3. Tap **"Scan for Devices"**
4. Wait 8 seconds for scan to complete
5. ✅ Tracker **"AG-001"** appears in detected devices list
6. ✅ Check for message: **"Community detections reported: 1"**

---

### Step 8: Verify Backend Received Detection

**Check backend console** (where `npm start` is running):
```
✓ [Auth] User bob@outlook.com registered and auto-verified (development mode)
[CommunityDetection] Reporting detection: AG-001 (rssi: -57 dBm, remoteId: AA:BB:CC:DD:EE:FF)
[CommunityDetection] Report accepted: Community detection recorded
```

**Query MongoDB**:
```javascript
db.communitydetections.find().pretty()

// Expected Result:
{
  _id: ObjectId("..."),
  trackerId: "AG-001",
  assetId: ObjectId("..."), // Alice's asset
  detectedBy: ObjectId("..."), // Bob's user ID
  rssi: -57,
  remoteId: "AA:BB:CC:DD:EE:FF",
  detectedAt: ISODate("2026-08-27T...")
}
```

✅ **Community detection working!**

---

### Step 9: Switch Back to User A (Optional)

**Verify Alice can see the detection** (future feature):
1. Logout User B
2. Login as User A:
   - **Email**: alice@gmail.com
   - **Password**: password123
3. Navigate to asset details for "Alice's Bag"
4. *(Future)* View community detection history
5. *(Future)* See "Detected by Bob at [location] on [time]"

---

## Quick Reference

### User A (Asset Owner)
- **Email**: alice@gmail.com
- **Password**: password123
- **Asset**: Alice's Bag (AG-001)
- **Status**: LOST

### User B (Community Detector)
- **Email**: bob@outlook.com
- **Password**: password123
- **Action**: Scans for nearby devices
- **Detects**: Alice's LOST asset AG-001

---

## Troubleshooting

### Backend Not Running
```bash
cd c:\flutter-project\assetguard\backend
npm start

# Should see:
# ✅ MongoDB Atlas connected
# 🚀 AssetGuard API running on port 5000
```

### User Already Exists
```bash
# If "alice@gmail.com" already registered, use different email:
alice2@gmail.com
alice.test@gmail.com
etc.
```

### Asset Not Detected
1. ✅ Verify tracker is powered on
2. ✅ Verify tracker ID matches asset (AG-001)
3. ✅ Verify asset is marked as **LOST** (not ACTIVE)
4. ✅ Move phone closer to tracker
5. ✅ Try scanning again

### Registration Takes You to Email Verification Screen
**Solution**: Email verification bypass not active
```bash
# 1. Check backend/.env
EMAIL_VERIFICATION_ENABLED=false  # Should be false

# 2. Restart backend
cd backend
npm start

# 3. Try registration again
```

### Community Detection Not Reported
**Check**:
1. ✅ Asset is marked as **LOST** (backend validates this)
2. ✅ Backend is running
3. ✅ Phone has internet connection
4. ✅ Check backend console for errors
5. ✅ JWT token is valid (login successful)

---

## Expected Console Output

### Backend Logs During Testing

```bash
# User A Registration
⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.
✓ [Auth] User alice@gmail.com registered and auto-verified (development mode)

# User A Login
POST /api/auth/login 200

# User A Creates Asset
POST /api/assets 201

# User A Marks Asset as LOST
PATCH /api/assets/6a8ff429e71377d787f753c0/lost 200

# User B Registration
⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.
✓ [Auth] User bob@outlook.com registered and auto-verified (development mode)

# User B Scans BLE
GET /api/assets 200 (Bob's assets - empty or only Bob's)

# User B Detects Alice's LOST Asset
POST /api/community/detections 201
Community detection recorded. Asset owner will be notified.
```

---

## Switching Back to Production Mode

When ready to deploy or test with real emails:

```bash
# 1. Edit backend/.env
EMAIL_VERIFICATION_ENABLED=true

# 2. Get Production Resend API key
# Visit: https://resend.com/api-keys

# 3. Update backend/.env
RESEND_API_KEY=re_YourProductionKey

# 4. Restart backend
npm start

# 5. Users now MUST verify email before login
# 6. Emails delivered to real inboxes
```

---

## Success Criteria

✅ User A registers successfully without email  
✅ User A creates asset and marks as LOST  
✅ User B registers successfully without email  
✅ User B cannot see User A's assets  
✅ User B detects User A's LOST tracker via BLE  
✅ Backend records community detection  
✅ Community detection links User B (detector) to User A's asset (owner)  
✅ JWT authentication works for both users  
✅ Multi-user architecture confirmed working  

---

## What's Next

After confirming multi-user community detection works:

1. **Test with Multiple Trackers**: Create more LOST assets
2. **Test Debouncing**: Scan same tracker multiple times (60s interval)
3. **Test ACTIVE Assets**: Verify only LOST assets reported
4. **Test Background Scanning**: Community sensing feature (90-second WiFi scans)
5. **Enable Production Mode**: Test with real email delivery
6. **Add Owner Notifications**: Notify User A when User B detects their LOST asset

---

## Need Help?

**Check Documentation**:
- `EMAIL_VERIFICATION_BYPASS_IMPLEMENTATION.md` - Full implementation details
- `MULTI_USER_ARCHITECTURE_INSPECTION.md` - Multi-user architecture analysis
- `BLE_COMMUNITY_DETECTION_IMPLEMENTATION.md` - Community detection details

**Backend Console**: Watch for error messages and log output  
**Flutter Console**: Check debug prints with `[CommunityDetection]` prefix  
**MongoDB**: Query `communitydetections` collection to verify data  

**The system is ready for multi-user community detection testing! 🚀**
