# V1 ML MODEL - TEST ENVIRONMENT READY ✅

## STATUS: READY FOR REAL-WORLD TESTING

**Date:** 2026-08-28  
**Time:** Test can begin immediately

---

## ✅ PRE-TEST VERIFICATION COMPLETE

### Backend Server
- ✅ Running on `http://10.151.32.221:5000`
- ✅ Health check: 200 OK
- ✅ ML_API_URL: `http://localhost:8000` (configured)
- ✅ Diagnostic logging: ACTIVE

### V1 ML Server
- ✅ Running on `http://localhost:8000`
- ✅ Health check: 200 OK
- ✅ Model: `assetguard_live_room_model.pkl`
- ✅ Features: **105 BSSIDs**
- ✅ Model loaded: TRUE
- ✅ Response time: ~130ms (tested)

### Flutter App
- ✅ Backend URL: `http://10.151.32.221:5000`
- ✅ Wi-Fi payload format: Compatible with V1
- ✅ Response parsing: Compatible with V1
- ✅ No code changes needed
- ✅ Diagnostic logging: ACTIVE

---

## 📋 TEST EXECUTION STEPS

### 1. Start Monitoring Terminals

**Terminal 1: Backend Logs**
```powershell
cd c:\flutter-project\assetguard
.\monitor-v1-test.ps1
```

**Terminal 2: Phone B Logs**
```powershell
cd c:\flutter-project\assetguard
.\monitor-phone-b.ps1
```

### 2. Prepare Phones

**Phone A (Alice - Owner):**
- Open AssetGuard app
- Login as alice@test.com
- Navigate to "My Assets"
- Find tracker (e.g., "Laptop")
- **Mark asset as LOST** (if not already)

**Phone B (Bob - Detector):**
- Open AssetGuard app
- Login as bob@test.com
- Navigate to Settings or Community tab
- **Enable Community Sensing**
- Verify notification appears

### 3. Position & Wait

1. Place Phone B near the BLE tracker (~5-10 meters)
2. **Record physical room location:** ___________
3. Wait 15-30 seconds for automatic detection
4. Watch both monitoring terminals

### 4. Collect Results

Watch for this log sequence:

**Backend Terminal:**
```
[Community] INCOMING DETECTION REQUEST
[CommunityWiFi] Wi-Fi fingerprint provided with XX BSSIDs
[CommunityWiFi] ML HTTP STATUS: 200 OK
[CommunityWiFi] ✓ Predicted room: XXX
[Community] Owner notification created
```

**Phone B Terminal:**
```
[Community BLE] AssetGuard trackers detected: 1
[CommunityWiFi] Wi-Fi scan success: XX NIE APs
[CommunityWiFi] ✓ Predicted room: XXX
```

**Phone A:**
- Check notifications
- Should show: "Your Laptop (AG-001) was detected near Room XXX. (XX% confidence)"

---

## 📊 DATA TO COLLECT

For each detection, record:

### Wi-Fi Data
- [ ] Number of BSSIDs collected: _____
- [ ] Number matched to V1's 105 features: _____
- [ ] RSSI range: _____ to _____ dBm
- [ ] Any out-of-range RSSI? YES / NO

### ML Prediction
- [ ] Predicted room: _____
- [ ] Confidence: _____%
- [ ] Top 3 predictions: _____, _____, _____
- [ ] ML response time: _____ ms
- [ ] HTTP status: _____

### E2E Flow
- [ ] Backend received prediction? YES / NO
- [ ] Phone A notification received? YES / NO
- [ ] Room shown in notification: _____
- [ ] Timeout occurred? YES / NO

### Accuracy
- [ ] **Actual physical room:** _____
- [ ] **Predicted room:** _____
- [ ] **CORRECT?** YES / NO

---

## 🎯 SUCCESS CRITERIA

**PASS if:**
- ✅ Detection occurs within 30 seconds
- ✅ Wi-Fi fingerprint collected (any number of BSSIDs)
- ✅ ML returns prediction (any room, any confidence)
- ✅ No timeout (response < 10 seconds)
- ✅ No 422 errors
- ✅ Phone A receives notification

**Accuracy NOT Required:**
- Wrong room prediction = ACCEPTABLE
- Low confidence = ACCEPTABLE
- Goal is END-TO-END flow verification only

---

## 📁 FILES CREATED

Test documentation:
- `V1_REAL_WORLD_TEST_PROCEDURE.md` - Detailed test guide
- `V1_TEST_READY.md` - This file (quick reference)

Monitoring scripts:
- `monitor-v1-test.ps1` - Backend log monitor
- `monitor-phone-b.ps1` - Phone B log monitor

---

## 🚨 IMPORTANT REMINDERS

**DO NOT modify during test:**
- ❌ BLE code
- ❌ Wi-Fi scanning
- ❌ Community Sensing timing
- ❌ Backend logic
- ❌ Notification system
- ❌ ML model

**If prediction is wrong:**
- ✅ Record the result
- ✅ Note actual vs predicted room
- ✅ Do NOT fix or retrain yet
- ✅ Report findings

---

## 🔄 WHAT HAPPENS DURING TEST

### Automatic Detection Flow:
```
1. Phone B: BLE scan every 15 seconds
   └─> Detects AG-001 tracker

2. Phone B: Wi-Fi scan (triggered by BLE detection)
   └─> Collects 30-60 BSSID/RSSI pairs

3. Phone B: Sends to backend
   └─> POST /api/community/detections
       {
         trackerId: "AG-001",
         rssi: -67,
         wifiFingerprint: { "XX:XX:XX": -45, ... }
       }

4. Backend: Validates asset is LOST
   └─> Owned by Alice, status=LOST ✓

5. Backend: Calls V1 ML
   └─> POST http://localhost:8000/predict-room
       { wifi: { "XX:XX:XX": -45, ... } }

6. V1 ML: Predicts room (~130ms)
   └─> Returns: { room: "305", confidence: 0.26, ... }

7. Backend: Creates notification
   └─> Stores in MongoDB for Alice

8. Phone A: Receives notification
   └─> "Your Laptop (AG-001) was detected near Room 305. (26% confidence)"
```

**Total time:** 15-30 seconds from proximity to notification

---

## ✅ READY TO BEGIN

All systems verified. Execute test procedure and record findings.

**See:** `V1_REAL_WORLD_TEST_PROCEDURE.md` for detailed instructions.
