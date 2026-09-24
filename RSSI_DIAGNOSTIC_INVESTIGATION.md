# RSSI DIAGNOSTIC INVESTIGATION

## PURPOSE
Determine whether real Android Wi-Fi scans produce RSSI values outside [-120, 0] that cause V2 ML API 422 errors.

## DIAGNOSTIC LOGGING ADDED

### 1. Raw Wi-Fi Scan (wifi_scan_service.dart)
**Location**: Immediately after receiving results from wifi_scan plugin

**Logs**:
```
[WiFiScan] ═══════════════════════════════════════
[WiFiScan] RAW SCAN RESULTS ANALYSIS
[WiFiScan] Total APs found: XX
[WiFiScan] NIE APs found: XX
[WiFiScan] ───────────────────────────────────────
[WiFiScan] RSSI ANALYSIS:
[WiFiScan]   Type: int
[WiFiScan]   Min RSSI: -XX dBm
[WiFiScan]   Max RSSI: -XX dBm
[WiFiScan]   Out of range [-120,0]: X
[WiFiScan] ⚠️ WARNING: OUT-OF-RANGE RSSI VALUES DETECTED: (if any)
[WiFiScan]   ⚠️ BSSID: XX:XX:XX:XX:XX:XX, RSSI: XX dBm, SSID: XXX
[WiFiScan] ───────────────────────────────────────
[WiFiScan] SAMPLE DATA (first 3 NIE APs):
[WiFiScan]   BSSID: XX, RSSI: -XX dBm (type: int), SSID: NIE-STUDENTS
[WiFiScan] ═══════════════════════════════════════
[WiFiScan] POST-PROCESSING VERIFICATION:
[WiFiScan]   Min RSSI after mapping: -XX dBm
[WiFiScan]   Max RSSI after mapping: -XX dBm
[WiFiScan] ⚠️ OUT-OF-RANGE AFTER PROCESSING: X (if any)
```

**Captures**:
- Type of `ap.level` (expected: int)
- Min/max RSSI from raw Android scan
- Any RSSI < -120 or > 0
- RSSI values after NieAccessPoint mapping

### 2. Fingerprint Creation (community_sensing_service.dart)
**Location**: After converting scan results to Map<String, int>

**Logs**:
```
[CommunityWiFi] ✓ Wi-Fi scan success: XX NIE APs found
[CommunityWiFi] Fingerprint: XX BSSIDs
[CommunityWiFi] ───────────────────────────────────────
[CommunityWiFi] FINGERPRINT PAYLOAD VALIDATION:
[CommunityWiFi]   Payload type: _Map<String, int>
[CommunityWiFi]   RSSI value type: int
[CommunityWiFi]   Min RSSI in payload: -XX dBm
[CommunityWiFi]   Max RSSI in payload: -XX dBm
[CommunityWiFi] ⚠️⚠️⚠️ CRITICAL: INVALID RSSI IN PAYLOAD ⚠️⚠️⚠️ (if any)
[CommunityWiFi]   ✓ All RSSI values in valid range [-120, 0]
[CommunityWiFi]   Sample (first 3):
[CommunityWiFi]     XX:XX:XX:XX:XX:XX: -XX dBm (type: int)
[CommunityWiFi] ───────────────────────────────────────
```

**Captures**:
- Type of fingerprint (Map<String, int>)
- Type of RSSI values (expected: int)
- Min/max RSSI in fingerprint payload
- Any invalid RSSI values with BSSID

### 3. Cached Fingerprint (community_sensing_service.dart)
**Location**: When fingerprint is retrieved from cache for BLE detection

**Logs**:
```
[CommunityWiFi] ═══ Wi-Fi FINGERPRINT RETRIEVED FROM CACHE ═══
[CommunityWiFi]     BSSIDs: XX
[CommunityWiFi]     Sample: XX:XX:XX:XX:XX:XX:-XXdBm, ...
[CommunityWiFi] ───────────────────────────────────────
[CommunityWiFi] CACHED FINGERPRINT VALIDATION:
[CommunityWiFi]   Value type: int
[CommunityWiFi]   Min RSSI: -XX dBm
[CommunityWiFi]   Max RSSI: -XX dBm
[CommunityWiFi] ⚠️⚠️⚠️ INVALID RSSI IN CACHED FINGERPRINT ⚠️⚠️⚠️ (if any)
[CommunityWiFi]   ✓ All cached RSSI values valid [-120, 0]
[CommunityWiFi] ───────────────────────────────────────
```

**Captures**:
- Type of cached RSSI values
- Min/max RSSI from cache
- Any cache corruption

### 4. Backend ML Request (communityController.js)
**Location**: Already has comprehensive logging from previous enhancement

**Logs**:
```
[CommunityWiFi] ═══════════════════════════════════════
[CommunityWiFi] SENDING TO ML SERVER
[CommunityWiFi] 1. Payload type: object
[CommunityWiFi] 2. Number of BSSIDs: XX
[CommunityWiFi] 5. RSSI data types:
[CommunityWiFi]    - Numeric: XX
[CommunityWiFi]    - Non-numeric: X
[CommunityWiFi]    - Null/undefined: X
[CommunityWiFi] 6. RSSI range:
[CommunityWiFi]    - Minimum: -XX dBm
[CommunityWiFi]    - Maximum: -XX dBm
[CommunityWiFi]    - Out of range (-120 to 0): X
[CommunityWiFi] ═══════════════════════════════════════
[CommunityWiFi] ✗ ML API RESPONSE: HTTP 422 (if error)
[CommunityWiFi] ✗ Error response body: {...}
```

## CODE FLOW ANALYSIS

### Stage 1: Android Native → wifi_scan Plugin
```dart
WiFiAccessPoint.level → int (from Android ScanResult.level)
```
**Expected**: Integer in range [-120, 0] dBm
**Actual type**: `int` (confirmed from wifi_scan package)

### Stage 2: Plugin → NieAccessPoint
```dart
rssiDbm: ap.level  // Direct assignment, no conversion
```
**Transformation**: NONE
**Type**: int → int

### Stage 3: NieAccessPoint → Fingerprint Map
```dart
MapEntry<String, int> toMapEntry() => MapEntry(bssid, rssiDbm);
Map<String, int> toRssiMap() => Map.fromEntries(accessPoints.map((ap) => ap.toMapEntry()));
```
**Transformation**: NONE
**Type**: int → int (in Map<String, int>)

### Stage 4: Fingerprint → Cache
```dart
WifiFingerprintCache.update(Map<String, int> fingerprint)
```
**Transformation**: NONE
**Type**: Map<String, int> stored as-is

### Stage 5: Cache → Backend Payload
```dart
final wifiFingerprint = fingerprint.entries
    .map((e) => {'bssid': e.key, 'rssi': e.value})
    .toList();
```
**Transformation**: Map → List of objects
**Type**: int values preserved

### Stage 6: Backend → V2 ML Server
```javascript
body: JSON.stringify({ wifi: wifiFingerprint })
```
**Transformation**: JavaScript object → JSON
**Type**: Numbers preserved (if originally valid integers)

## CONCLUSIONS (TO BE VERIFIED WITH REAL DATA)

### Q1: What exact type is ap.level?
**A**: `int` - confirmed by wifi_scan package and Dart type system

### Q2: Is ap.level passed directly?
**A**: YES - Direct assignment with zero transformations

### Q3: Any arithmetic/conversion?
**A**: NO - No arithmetic, averaging, conversion, normalization, interpolation, or transformation

### Q4: Can runtime payload contain invalid values?
Based on code analysis:
- **RSSI > 0**: Only if Android native ScanResult.level returns > 0 (should not happen)
- **RSSI < -120**: Only if Android native ScanResult.level returns < -120 (should not happen)
- **Fractional RSSI**: NO - type is `int`, not `double`
- **Null RSSI**: NO - wifi_scan plugin returns non-null int values

### Q5: Potential corruption points?
1. **WiFi plugin bug** - wifi_scan 0.4.1+2 might have edge case bug
2. **Cache corruption** - Unlikely, but possible if cache is modified elsewhere
3. **JSON serialization** - JavaScript/JSON could introduce floating point if values become doubles
4. **Network transmission** - Corruption during HTTP transfer (unlikely)

## TESTING PROCEDURE

1. **Rebuild APK** with diagnostic logging
2. **Install on Phone B**:
   ```powershell
   flutter build apk --release
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```
3. **Enable Community Sensing**
4. **Monitor Flutter logs**:
   ```powershell
   adb logcat | Select-String "WiFiScan|CommunityWiFi"
   ```
5. **Monitor backend logs** (already configured)
6. **Trigger multiple automatic Wi-Fi scans** (wait 15 seconds × 5 = 75 seconds minimum)
7. **Trigger BLE detection** to use cached fingerprint
8. **Watch for 422 errors** and correlate with logged RSSI values

## EXPECTED OUTCOMES

### If Android produces valid values:
- All logs show RSSI in [-120, 0]
- No "OUT-OF-RANGE" warnings
- No "INVALID RSSI" warnings
- **Conclusion**: 422 error caused by something else (not RSSI range)

### If Android produces invalid values:
- Logs show specific RSSI < -120 or > 0
- Warnings appear at WiFiScan stage
- Invalid values persist through fingerprint creation
- Backend receives out-of-range values
- V2 returns 422
- **Conclusion**: Need defensive filtering

## FILES MODIFIED (DIAGNOSTIC ONLY)

- ✅ `lib/services/wifi_scan_service.dart` - Added raw scan diagnostics
- ✅ `lib/services/community_sensing_service.dart` - Added fingerprint & cache diagnostics
- ✅ `backend/src/controllers/communityController.js` - Already has ML request diagnostics

## NOT MODIFIED

- ❌ BLE code
- ❌ BLE timing/debounce/filtering
- ❌ Community Sensing timing
- ❌ Wi-Fi scan timing
- ❌ ML model
- ❌ Backend API logic
- ❌ Notification logic

## NEXT STEPS

1. User runs real phone test with diagnostic logging
2. User shares logs showing:
   - Multiple automatic Wi-Fi scans
   - Fingerprint creation logs
   - Cached fingerprint logs
   - Backend ML request logs
   - Any 422 errors with full error response
3. Analyze logs to answer:
   - **A**: Do real Flutter scans produce out-of-range RSSI?
   - **B**: Does any transformation create invalid values?
   - **C**: Can 422 be attributed to RSSI?
   - **D**: What is the correct fix?

## ROLLBACK

To remove diagnostic logging after investigation:
```bash
git diff lib/services/wifi_scan_service.dart
git diff lib/services/community_sensing_service.dart
# Revert the diagnostic sections
```
