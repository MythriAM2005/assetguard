# 🧪 TEST APP CONNECTION

**Status**: Phone browser CAN reach backend ✅  
**Problem**: App CANNOT reach backend ❌

---

## 🔍 DIAGNOSIS STEPS

### What error does the app show?

When you try to sign in, you likely see one of these:

1. **"Cannot reach the server. Check your network connection."**
   - This is SocketException from api_service.dart
   - Means HTTP request failed

2. **"Validation failed" or specific field errors**
   - This means connection works!
   - Just empty fields

3. **Timeout / No response**
   - Request taking too long (>15 seconds)

4. **SSL/Certificate error**
   - Would be unusual for HTTP

---

## 🎯 MOST LIKELY CAUSES

Since browser works but app doesn't:

### Cause 1: App Using Old/Cached IP
The APK was built with a different IP address.

**Check**:
```
APK built: 2026-08-29 10:58:11
Current IP: 10.128.192.221
```

If IP changed after APK was built, app has old IP hardcoded.

**Fix**: Rebuild APK
```powershell
cd c:\flutter-project\assetguard
flutter build apk
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Cause 2: App Network Security Config
Even though usesCleartextTraffic=true, there might be additional restrictions.

**Fix**: Create network_security_config.xml

### Cause 3: DNS vs IP Issue
App might be doing something different with URL parsing.

**Test**: Try using IP with explicit port parsing

### Cause 4: App Permission Issue
App doesn't have INTERNET permission at runtime.

**Fix**: Check app permissions in phone settings

---

## 🚀 QUICK FIX - TRY THIS FIRST

### Step 1: Create Network Security Config

**Create file**: `android/app/src/main/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.128.192.221</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
```

**Edit**: `android/app/src/main/AndroidManifest.xml`

Find the `<application>` tag and add:
```xml
<application
    android:label="AssetGuard"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
```

**Rebuild**:
```powershell
flutter build apk
```

---

## 🔍 STEP 2: ADD LOGGING

Let's see the exact error. Add logging to api_service.dart:

**Edit**: `lib/services/api_service.dart`

In the `post` method, add:
```dart
Future<dynamic> post(String path, Map<String, dynamic> body) async {
  print('🔵 API POST: ${_uri(path)}'); // ADD THIS
  print('🔵 Headers: $_headers'); // ADD THIS
  print('🔵 Body: ${jsonEncode(body)}'); // ADD THIS
  
  try {
    final res = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    
    print('🔵 Response: ${res.statusCode}'); // ADD THIS
    return _process(res);
  } on SocketException catch (e) {
    print('❌ SocketException: $e'); // ADD THIS
    throw const ApiException('Cannot reach the server. Check your network connection.');
  } on ApiException {
    rethrow;
  } catch (e) {
    print('❌ Unexpected: $e'); // ADD THIS
    throw ApiException('Unexpected error: $e');
  }
}
```

**Then check logs**:
```powershell
adb logcat | Select-String "API POST|SocketException|Response"
```

---

## 🧪 STEP 3: VERIFY APP HAS CORRECT IP

Let's add a debug screen to see what IP the app thinks it's using:

**Create**: `lib/screens/debug_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../utils/api_config.dart';
import '../services/api_service.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  Future<void> _testConnection(BuildContext context) async {
    try {
      final response = await ApiService.instance.post('/api/auth/register', {
        'name': 'Test',
        'email': 'test@test.com',
        'password': 'test123',
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Connection works! Response: $response')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backend URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(ApiConfig.baseUrl, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testConnection(context),
              child: Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Add to app**: In `lib/screens/login_screen.dart`, add a debug button:

```dart
// At top of file
import 'debug_screen.dart';

// In the UI (maybe below login button)
TextButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => DebugScreen()),
  ),
  child: Text('Debug'),
)
```

---

## ⚡ FASTEST FIX - REBUILD APK

**Most likely the issue is**:
- APK built with old IP
- App needs to be rebuilt with current IP (10.128.192.221)

**Do this**:

```powershell
cd c:\flutter-project\assetguard

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build new APK
flutter build apk

# Install on phone
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

**Then test sign in again**

---

## 📊 VERIFICATION CHECKLIST

Before rebuilding, verify:

- [ ] `lib/utils/api_config.dart` has `http://10.128.192.221:5000`
- [ ] Your laptop IP is still `10.128.192.221` (run `ipconfig`)
- [ ] Backend is running (check PowerShell window)
- [ ] Phone browser CAN access `http://10.128.192.221:5000`

If all checked, rebuild APK.

---

## 🎯 EXPECTED RESULT

After rebuilding and installing:

1. Open app
2. Try to register:
   - Name: Test User
   - Email: user@test.com  
   - Password: Test123!
3. Tap Register

**Should see**:
- Success message
- Auto-login
- Navigate to Home screen

**Backend logs should show**:
```
POST /api/auth/register 201 Created
```

---

## 🚨 IF STILL DOESN'T WORK

Run full diagnostic:

```powershell
# 1. Check IP
ipconfig | Select-String "IPv4"

# 2. Check backend
curl http://10.128.192.221:5000/api/auth/register -Method POST -Body '{"name":"x","email":"x@x.com","password":"x"}' -ContentType "application/json" -UseBasicParsing

# 3. Check app config
Get-Content lib\utils\api_config.dart | Select-String "baseUrl"

# 4. Check APK date
Get-Item build\app\outputs\flutter-apk\app-debug.apk | Select-Object LastWriteTime

# 5. Check app logs during sign in
adb logcat | Select-String "AssetGuard|ApiService|SocketException"
```

Send me the output and exact error message from app.

---

**TL;DR**: Rebuild the APK - that's most likely the fix!
