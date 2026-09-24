# ✅ FINAL APK - CORRECT IP ADDRESS

**Status**: APK built with your current IP address  
**Your IP**: `10.151.32.221` (verified from ipconfig)  
**APK Location**: `build\app\outputs\flutter-apk\app-release.apk`  
**Size**: 52.9 MB  
**Built**: Just now

---

## 📊 IMPORTANT: WHY YOU NEEDED TO REBUILD

### The Issue:
When you build an APK, the IP address from `api_config.dart` gets **compiled into the APK**. It becomes hardcoded in the binary.

**This means**:
- Changing `api_config.dart` after building does NOT affect existing APK
- The old APK still has the old IP (`10.128.192.221`)
- The new APK now has the new IP (`10.151.32.221`)

### Your IP Changed:
- **Old IP**: `10.128.192.221` ❌
- **New IP**: `10.151.32.221` ✅ (current)
- **Reason**: Your laptop got a new IP from DHCP (router assigns IPs dynamically)

This is why the app couldn't connect - it was trying to reach the OLD IP!

---

## ✅ WHAT'S IN THE NEW APK

**Configuration**:
- Backend URL: `http://10.151.32.221:5000` ✅
- Network Security: HTTP allowed for your IPs ✅
- Cleartext Traffic: Enabled ✅
- Both old and new IPs allowed (in case it changes again) ✅

**Allowed IPs in Network Security Config**:
- `10.151.32.221` (current - primary)
- `10.128.192.221` (old - backup)
- `10.135.90.221` (ML server)
- `localhost` / `127.0.0.1`

---

## 📱 INSTALL NEW APK NOW

**Both phones need the new APK!**

```powershell
# Phone A (Asset Owner)
adb install -r build\app\outputs\flutter-apk\app-release.apk

# Phone B (Community Helper)
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

**Or manually**: Transfer APK file to phone → Tap to install

---

## 🧪 TEST CONNECTION

After installing:

### Step 1: Test from Phone Browser
```
http://10.151.32.221:5000
```
**Expected**: JSON error message (this is good!)

### Step 2: Test Registration in App

1. Open AssetGuard
2. Tap "Register"
3. Fill:
   - Name: `Test Owner`
   - Email: `owner@test.com`
   - Password: `Test123!`
4. Tap "Register"

**Expected**: ✅ Success → Auto-login → Home screen

---

## 🔧 BACKEND STATUS

**Check backend is running**:
```powershell
Get-Process -Name node
```

**If not running, start it**:
```powershell
cd c:\flutter-project\assetguard
.\start-backend.ps1
```

**Backend should be listening on**:
- Port: 5000 ✅
- IP: 0.0.0.0 (all interfaces) ✅
- Accessible at: `http://10.151.32.221:5000` ✅

---

## ⚠️ IF IP CHANGES AGAIN

Your laptop IP can change when:
- You disconnect/reconnect to Wi-Fi
- Router restarts
- DHCP lease expires
- You connect to different network

**When IP changes, you MUST**:

1. **Check new IP**:
   ```powershell
   ipconfig | Select-String "IPv4"
   ```

2. **Update api_config.dart**:
   ```dart
   static const String baseUrl = 'http://NEW_IP:5000';
   ```

3. **Rebuild APK**:
   ```powershell
   flutter build apk
   ```

4. **Reinstall on phones**:
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```

---

## 💡 TIP: PREVENT IP CHANGES

To avoid rebuilding APK every time:

### Option 1: Set Static IP (Recommended for Testing)

**In Windows**:
1. Control Panel → Network and Sharing Center
2. Change adapter settings → Right-click Wi-Fi → Properties
3. Internet Protocol Version 4 (TCP/IPv4) → Properties
4. Select "Use the following IP address"
5. Set:
   - IP: `10.151.32.221`
   - Subnet: `255.255.0.0` (or whatever your network uses)
   - Gateway: (your router IP, e.g., `10.151.0.1`)
   - DNS: `8.8.8.8` (Google DNS)

**OR in Router** (better):
1. Log into router admin panel
2. Find DHCP settings
3. Reserve IP `10.151.32.221` for your laptop's MAC address

### Option 2: Use Dynamic DNS (Advanced)
Set up a local DNS name instead of IP

### Option 3: Accept IP Changes
Just rebuild APK when needed (what we're doing now)

---

## 📊 CURRENT CONFIGURATION

| Component | Value | Status |
|-----------|-------|--------|
| **Laptop IP** | `10.151.32.221` | ✅ Current |
| **Backend URL** | `http://10.151.32.221:5000` | ✅ In APK |
| **Network Security** | Cleartext allowed | ✅ Configured |
| **APK Built** | Just now | ✅ Latest |
| **APK Size** | 52.9 MB | ✅ Optimized |

---

## 🎯 NEXT STEPS

1. **Install APK on both phones** (command above)
2. **Start backend** if not running (`.\start-backend.ps1`)
3. **Test from phone browser**: `http://10.151.32.221:5000`
4. **Test registration** in app
5. **Follow full testing**: `START_TESTING_NOW.md`

---

## ✅ SUCCESS CRITERIA

**Connection works when**:

✅ Phone browser shows JSON error at `http://10.151.32.221:5000`  
✅ App registration succeeds  
✅ Backend logs show `POST /api/auth/register 201`  
✅ User logged in and sees Home screen  

---

## 🚀 READY TO TEST!

**Your APK is now configured with the correct IP address.**

**Install command**:
```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

**Then test registration!**

---

## 📝 REMEMBER

Every time you see "Cannot reach server":

1. Check your laptop IP: `ipconfig`
2. Check if it matches api_config.dart
3. If different → Update api_config.dart → Rebuild APK
4. If same → Check backend running, firewall, network

---

**The app will now connect to your backend at the correct IP!** 🎉
