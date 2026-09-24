# Wi-Fi Community Sensing Authentication Fix

**Date**: August 28, 2026, 2:15 PM  
**Status**: ✅ FIXED

---

## Problem Identified

### Root Cause

The automatic Wi-Fi scanning was working correctly and finding NIE networks (76 APs), but the upload was failing with:

```
[CommunityWiFi] Wi-Fi scan error: Not authorised [no token provided]
Stack trace: ApiService._process
```

**Why**: The Wi-Fi upload was happening in the **foreground task isolate**, which is a separate isolate from the main Flutter app. This isolate did not have access to `ApiService.instance._token` because:

1. Dart isolates have separate memory spaces
2. The `ApiService` singleton with the authentication token exists in the main isolate
3. The foreground task isolate was trying to call `ApiService.instance.post()` without the token

---

## Solution

### Architecture Change

**Before** (Broken):
```
Foreground Task Isolate:
  Wi-Fi scan → fingerprint → ApiService.post() ❌ (no token)
```

**After** (Fixed):
```
Foreground Task Isolate:
  Wi-Fi scan → fingerprint → Send to Main Isolate

Main Isolate:
  Receive fingerprint → ApiService.post() ✅ (has token)
```

### Implementation

Moved the Wi-Fi upload from the foreground task isolate to the main isolate using inter-isolate messaging, matching the existing BLE scanning pattern.

---

## Files Changed

### 1. `lib/services/community_sensing_service.dart`

**Changes**: 3 modifications

#### A. Task Isolate: Send Wi-Fi Data Instead of Uploading

**Before**:
```dart
Future<void> _performWifiScan() async {
  final result = await WifiScanService.instance.scanNieAccessPoints();
  
  if (result is WifiScanSuccess && result.accessPoints.isNotEmpty) {
    final fingerprint = result.toRssiMap();
    
    // Direct upload in task isolate ❌
    await _uploadWifiScan(fingerprint);
  }
}

Future<void> _uploadWifiScan(Map<String, int> fingerprint) async {
  final wifiFingerprint = fingerprint.entries
      .map((e) => {'bssid': e.key, 'rssi': e.value})
      .toList();

  await ApiService.instance.post('/api/community/scan', {
    'wifiFingerprint': wifiFingerprint,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  });
}
```

**After**:
```dart
Future<void> _performWifiScan() async {
  final result = await WifiScanService.instance.scanNieAccessPoints();

  if (result is WifiScanSuccess && result.accessPoints.isNotEmpty) {
    final fingerprint = result.toRssiMap();
    
    debugPrint('[CommunityWiFi] ✓ Wi-Fi scan success: ${result.accessPoints.length} NIE APs found');
    debugPrint('[CommunityWiFi] Fingerprint: ${fingerprint.length} BSSIDs');
    debugPrint('[CommunityWiFi] Fingerprint prepared — sending to main isolate for upload');
    
    // Send to main isolate for authenticated upload ✅
    FlutterForegroundTask.sendDataToMain({
      'action': 'uploadWifiScan',
      'fingerprint': fingerprint,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    
    _wifiScanCount++;
    debugPrint('[CommunityWiFi] Wi-Fi scan #$_wifiScanCount sent to main isolate');
  }
}
```

**Key Changes**:
- Removed direct `ApiService.instance.post()` call from task isolate
- Added `FlutterForegroundTask.sendDataToMain()` to send fingerprint to main isolate
- Added logging: "Fingerprint prepared — sending to main isolate for upload"

---

#### B. Main Isolate: Handle Wi-Fi Upload Message

**Before**:
```dart
void _handleDataFromTask(dynamic data) {
  if (data is Map<String, dynamic>) {
    final action = data['action'] as String?;
    
    if (action == 'performBleScan') {
      _performBleScan();
    }
  }
}
```

**After**:
```dart
void _handleDataFromTask(dynamic data) {
  if (data is Map<String, dynamic>) {
    final action = data['action'] as String?;
    
    if (action == 'performBleScan') {
      debugPrint('[CommunitySensing] BLE scan requested by foreground task');
      _performBleScan();
    } else if (action == 'uploadWifiScan') {
      debugPrint('[CommunityWiFi] Wi-Fi upload requested by foreground task');
      final fingerprint = data['fingerprint'] as Map<String, dynamic>?;
      final timestamp = data['timestamp'] as String?;
      
      if (fingerprint != null) {
        // Convert dynamic map to Map<String, int>
        final typedFingerprint = fingerprint.map(
          (key, value) => MapEntry(key as String, value as int),
        );
        
        _uploadWifiScan(typedFingerprint, timestamp);
      }
    }
  }
}
```

**Key Changes**:
- Added handler for `uploadWifiScan` action
- Converts fingerprint data from dynamic map to typed map
- Calls `_uploadWifiScan()` in main isolate

---

#### C. Main Isolate: Upload Wi-Fi with Authentication

**New Method**:
```dart
/// Upload Wi-Fi fingerprint to backend with authentication.
/// This runs in the main isolate because it needs ApiService with auth token.
Future<void> _uploadWifiScan(Map<String, int> fingerprint, String? timestamp) async {
  try {
    debugPrint('[CommunityWiFi] Uploading fingerprint with ${fingerprint.length} BSSIDs');
    
    // Store in cache for BLE detections to use
    WifiFingerprintCache.instance.update(fingerprint);
    
    final wifiFingerprint = fingerprint.entries
        .map((e) => {'bssid': e.key, 'rssi': e.value})
        .toList();

    await ApiService.instance.post('/api/community/scan', {
      'wifiFingerprint': wifiFingerprint,
      'timestamp': timestamp ?? DateTime.now().toUtc().toIso8601String(),
    });
    
    debugPrint('[CommunityWiFi] ✓ Upload success');
    
    // Notify task isolate of successful upload (optional)
    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'wifiUploadCompleted',
        'success': true,
      });
    } catch (e) {
      // Ignore errors - task isolate communication is optional
    }
  } catch (e) {
    debugPrint('[CommunityWiFi] ✗ Upload failed: $e');
    
    // Notify task isolate of failed upload (optional)
    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'wifiUploadCompleted',
        'success': false,
        'error': e.toString(),
      });
    } catch (e) {
      // Ignore errors - task isolate communication is optional
    }
  }
}
```

**Key Features**:
- Runs in main isolate (has access to `ApiService.instance._token`)
- Caches fingerprint for BLE detections
- Uploads to `/api/community/scan` with authentication
- Logs success/failure
- Optionally notifies task isolate of result

---

## How Authentication Token is Obtained

### Token Storage

**Location**: `lib/services/api_service.dart`

```dart
class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
```

### Token Set During Login

**Location**: `lib/services/auth_service.dart`

```dart
Future<void> login(String email, String password) async {
  final data = await ApiService.instance.post('/api/auth/login', {
    'email': email,
    'password': password,
  });
  
  final token = data['token'] as String;
  
  // Store token in ApiService
  ApiService.instance.setToken(token);
  
  // ... rest of login logic
}
```

### Token Used in All API Calls

When `ApiService.instance.post()` is called, it automatically includes the token:

```dart
Future<dynamic> post(String path, Map<String, dynamic> body) async {
  final res = await http.post(
    _uri(path),
    headers: _headers, // ← Includes 'Authorization: Bearer <token>'
    body: jsonEncode(body),
  );
  return _process(res);
}
```

**Why It Works Now**:
- Wi-Fi upload happens in **main isolate**
- Main isolate has the `ApiService.instance` with `_token` set during login
- Token is automatically included in HTTP headers
- Backend validates token and accepts request

---

## Expected Log Output

### Task Isolate Logs

```
[CommunityWiFi] Starting automatic Wi-Fi scan...
[CommunityWiFi] ✓ Wi-Fi scan success: 76 NIE APs found
[CommunityWiFi] Fingerprint: 76 BSSIDs
[CommunityWiFi] Fingerprint prepared — sending to main isolate for upload
[CommunityWiFi] Wi-Fi scan #1 sent to main isolate
```

### Main Isolate Logs

```
[CommunityWiFi] Wi-Fi upload requested by foreground task
[CommunityWiFi] Uploading fingerprint with 76 BSSIDs
[CommunityWiFi] ✓ Upload success
```

### Backend Logs

```
POST /api/community/scan
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Body: {
  "wifiFingerprint": [
    {"bssid": "84:d8:1b:aa:bb:cc", "rssi": -43},
    ...
  ],
  "timestamp": "2026-08-28T10:15:00.000Z"
}
Response: 201 Created
```

---

## What Was NOT Changed

✅ **BLE scanning** - Unchanged  
✅ **BLE timing** - Still 15 seconds  
✅ **BLE debounce** - Still 30 seconds  
✅ **BLE filtering** - AG-XXX pattern unchanged  
✅ **BLE notification** - Unchanged  
✅ **Asset tracking** - Unchanged  
✅ **Mark as Recovered** - Unchanged  
✅ **ML model/server** - Unchanged  
✅ **Manual Wi-Fi scan UI** - Unchanged  
✅ **Wi-Fi scan interval** - Still 15 seconds  
✅ **NIE AP filtering** - Still NIE-STUDENTS/NIE-STAFF  
✅ **BSSID/RSSI format** - Unchanged  

---

## Testing Verification

### Test 1: Wi-Fi Upload with Authentication

**Expected Result**:
1. Wi-Fi scan finds NIE APs
2. Fingerprint sent to main isolate
3. Main isolate uploads with token
4. Backend accepts request (201 Created)
5. No "Not authorised" error

**Logs to Check**:
```bash
adb logcat | grep CommunityWiFi
```

**Success Indicators**:
- ✅ "Fingerprint prepared — sending to main isolate for upload"
- ✅ "Uploading fingerprint with X BSSIDs"
- ✅ "✓ Upload success"
- ❌ No "Not authorised" error

---

### Test 2: Backend Receives Fingerprint

**Backend Check**:
```javascript
// In communityController.js submitScan()
console.log('Received Wi-Fi fingerprint:', req.body.wifiFingerprint.length, 'BSSIDs');
```

**MongoDB Check**:
```javascript
db.communityfingerprints.find().sort({createdAt: -1}).limit(1)
```

**Success Indicators**:
- ✅ New document in `communityfingerprints` collection
- ✅ `scannedBy` field contains user ID
- ✅ `wifiFingerprint` array has 76 entries
- ✅ `timestamp` is recent

---

### Test 3: ML Room Prediction (if ML server available)

**Prerequisite**: ML server running on port 8000

**Expected Flow**:
1. User B detects AG-001 (BLE)
2. Wi-Fi fingerprint attached to detection
3. Backend calls ML API
4. ML predicts room
5. User A receives notification with room

**Logs to Check**:
```
[CommunityWiFi] Including Wi-Fi fingerprint: 76 BSSIDs
[CommunityWiFi] ✓ ML predicted room: 310
[CommunityWiFi] ✓ Confidence: 0.38
```

---

## Why This Approach

### Alternative Approaches Considered

1. **Pass token to task isolate**
   - ❌ Security risk (token in isolate message)
   - ❌ Token could expire
   - ❌ Complex token refresh handling

2. **Use shared preferences in task isolate**
   - ❌ Requires async disk I/O
   - ❌ Token could be stale
   - ❌ Still security concern

3. **Send fingerprint to main isolate** ✅
   - ✅ Main isolate has authenticated ApiService
   - ✅ Token automatically included
   - ✅ Matches existing BLE pattern
   - ✅ Secure (no token passing)
   - ✅ Simple and maintainable

### Why It Matches BLE Pattern

**BLE Scanning**:
```
Task Isolate: "performBleScan" → Main Isolate: _performBleScan()
```

**Wi-Fi Upload** (Fixed):
```
Task Isolate: "uploadWifiScan" → Main Isolate: _uploadWifiScan()
```

Both use the same inter-isolate messaging pattern for operations that require main isolate resources.

---

## Summary

### What Was Fixed

✅ **Wi-Fi upload authentication** - Now uses main isolate with token  
✅ **Inter-isolate messaging** - Matches BLE pattern  
✅ **Error handling** - Graceful upload failure logging  
✅ **Logging** - Clear diagnostic output  

### Files Changed

- **1 file**: `lib/services/community_sensing_service.dart`
- **3 changes**:
  1. Task isolate: Send fingerprint instead of uploading
  2. Main isolate: Handle upload message
  3. Main isolate: Upload with authentication

### Build Status

✅ **APK Built**: `build\app\outputs\flutter-apk\app-debug.apk`  
✅ **Build Time**: August 28, 2:14 PM  
✅ **No Compilation Errors**  

### Token Mechanism

✅ **Token stored in**: `ApiService.instance._token`  
✅ **Token set during**: Login via `AuthService`  
✅ **Token used in**: All `ApiService` HTTP calls  
✅ **Token automatically included**: In `Authorization: Bearer <token>` header  
✅ **Token NOT logged**: Security maintained  

---

## Next Steps

1. **Install APK**:
   ```bash
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

2. **Enable Community Sensing**

3. **Check Logs**:
   ```bash
   adb logcat | grep CommunityWiFi
   ```

4. **Verify Success**:
   - ✅ "✓ Upload success" appears
   - ❌ No "Not authorised" error
   - ✅ Backend receives fingerprints

5. **Test ML Integration** (if server available):
   - Mark asset as LOST
   - Detect with BLE
   - Verify room prediction in notification

---

**Fix Complete**: August 28, 2026, 2:15 PM  
**Status**: ✅ READY FOR TESTING
