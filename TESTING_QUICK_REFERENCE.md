# 🎯 ASSETGUARD TESTING - QUICK REFERENCE CARD

**Print this page and keep it handy during testing**

---

## ⚡ QUICK START (3 Commands)

```powershell
# 1. Check everything is ready
.\quick-test.ps1

# 2. Start backend server (keep running)
.\start-backend.ps1

# 3. Follow detailed steps in:
# START_TESTING_NOW.md
```

---

## 📱 MINIMUM TEST FLOW (5 Minutes)

| # | Action | Phone | Expected Result |
|---|--------|-------|-----------------|
| 1 | Register user | A | Auto-login to Home |
| 2 | Register user | B | Auto-login to Home |
| 3 | Create asset (AG-001) | A | Shows in My Assets |
| 4 | Mark as LOST | A | Status = LOST (red) |
| 5 | Enable Community Sensing | B | Notification appears |
| 6 | Bring phones close | Both | Wait 30 seconds |
| 7 | Check notification | A | "Asset detected" |
| 8 | View Track Asset map | A | Marker on map |
| 9 | Mark as Recovered | A | Status = RECOVERED |
| 10 | Bring phones close again | Both | NO notification |

---

## 🔧 CONFIGURATION CHECKLIST

```
✅ Backend running: http://localhost:5000
✅ MongoDB connected: Cloud Atlas
✅ APK installed: Both phones
✅ Network: Phones can reach backend
✅ Permissions: BLE + Location + Notifications
```

---

## 📋 TEST CREDENTIALS

**Phone A (Owner)**:
- Email: `owner@test.com`
- Password: `Test123!`
- Asset: `My Laptop (AG-001)`

**Phone B (Helper)**:
- Email: `helper@test.com`
- Password: `Test123!`

---

## 🎯 KEY FEATURES TO DEMONSTRATE

### 1. User Authentication ✅
- Registration (no email required)
- Login/Logout
- Token persistence

### 2. Asset Management ✅
- Create asset with tracker ID
- View/Edit/Delete
- Status changes (ACTIVE → LOST → RECOVERED)

### 3. Community Detection ✅
- Background scanning (BLE every 15s)
- Detection notification
- Debounce (60s between reports)

### 4. Notifications ✅
- Push to asset owner
- Shows tracker ID, location, time
- Room prediction (if on NIE Wi-Fi)
- Mark as read

### 5. Track Asset ✅
- Interactive map (OpenStreetMap)
- Markers at detection locations
- Popup with details

### 6. Status Check ✅
- Only LOST assets trigger notifications
- RECOVERED assets ignored (no spam)

---

## ❌ COMMON ISSUES & FIXES

| Problem | Quick Fix |
|---------|-----------|
| Backend won't start | Check MongoDB connection in .env |
| Can't connect from phone | Verify IP in `api_config.dart` matches laptop IP |
| No detection | Check asset is LOST, Community Sensing enabled |
| No notification | Check notification permissions on Phone A |
| No room prediction | ML server down (system still works) |
| "Tracker not found" | Create asset with exact ID "AG-001" |
| Detection spam | Status check working correctly (only LOST) |

---

## 🔍 BACKEND LOG PATTERNS

**Successful Detection**:
```
POST /api/community/detections
Asset found: My Laptop, status: LOST
Calling ML API: http://10.135.90.221:8000/predict-room
ML Response: {"room":"310","confidence":0.376667}
Notification created for owner
```

**Asset Not Lost** (Expected after recovery):
```
POST /api/community/detections
Asset AG-001 not currently lost, skipping detection
```

---

## 📱 PHONE NAVIGATION

### Phone A (Owner)
```
Home → Add Asset → Mark as Lost → Notifications → Track Asset → Mark as Recovered
```

### Phone B (Helper)
```
Home → Enable Community Sensing → (Background scanning starts)
```

---

## 🎓 PRESENTATION TALKING POINTS

**Why BLE + Wi-Fi?**
- BLE: Works indoors, low power, detect nearby devices
- Wi-Fi: Fingerprinting for room-level accuracy
- GPS: Fallback outdoor location

**Why Random Forest ML?**
- 97.96% accuracy
- Fast inference (<1s)
- Handles missing features gracefully
- 22 rooms, 106 BSSID features

**Why Status Check?**
- Prevents notification spam after recovery
- Only LOST assets trigger community detection
- Critical for user experience

**Why Foreground Service?**
- Android requirement for background BLE scanning
- Persistent notification keeps service alive
- ~10-15% battery per 8 hours (acceptable)

---

## 📊 PROJECT METRICS

- **Flutter App**: 26 screens, 15 services, 8 models
- **Backend**: 6 controllers, 6 models, 25+ endpoints
- **Database**: MongoDB with 6 collections
- **ML Server**: Python Random Forest, 97.96% accuracy
- **Scan Timing**: BLE 15s, Wi-Fi 15s, Debounce 60s
- **APK Size**: ~187 MB (debug build)

---

## 📚 DOCUMENTATION FILES

1. **START_TESTING_NOW.md** ← Start here
2. **END_TO_END_TESTING_GUIDE.md** ← Comprehensive testing
3. **COMPLETE_PROJECT_DOCUMENTATION_FOR_PRESENTATION.md** ← Full technical docs
4. **PRESENTATION_GUIDE.md** ← Quick presentation reference
5. **TESTING_QUICK_REFERENCE.md** ← This file (print it!)

---

## 🚀 START TESTING NOW

```powershell
# Terminal 1: Start backend
cd c:\flutter-project\assetguard
.\start-backend.ps1

# Terminal 2: Check status
.\quick-test.ps1

# Then follow: START_TESTING_NOW.md
```

---

## ✅ SUCCESS CRITERIA

Testing is successful when:

- ✅ Both users can register and login
- ✅ Asset can be created and marked LOST
- ✅ Community Sensing starts on Phone B
- ✅ Phone A receives notification when detected
- ✅ Notification includes tracker ID and location
- ✅ Track Asset map shows marker
- ✅ After marking RECOVERED, no more notifications
- ✅ Backend logs show "Asset not currently lost"

---

## 🎯 DEMO TIMING (4 Minutes)

```
0:00 - 0:30  Login + Create Asset + Mark LOST
0:30 - 1:00  Enable Community Sensing (Phone B)
1:00 - 2:30  Detection happening (show logs)
2:30 - 3:00  Notification received (show details)
3:00 - 3:30  Track Asset map
3:30 - 4:00  Mark as Recovered (explain status check)
```

**Practice this flow 3 times before presenting!**

---

## 📞 QUICK HELP

If stuck:
1. Check backend logs (PowerShell window)
2. Check phone logs: `adb logcat | Select-String "AssetGuard"`
3. Verify configuration: `.\quick-test.ps1`
4. Review troubleshooting in END_TO_END_TESTING_GUIDE.md
5. Check MongoDB collections in Compass

---

**GOOD LUCK! 🎉**

Remember: The system is designed to be resilient. Even if ML server is down, core detection still works with GPS location.
