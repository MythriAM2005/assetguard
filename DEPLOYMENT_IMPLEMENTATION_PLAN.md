# ASSETGUARD DEPLOYMENT IMPLEMENTATION PLAN

## MUST FIX ITEMS - IMPLEMENTATION APPROACH

### Items I CAN Fix Now (Without User Decisions)

#### ✅ A2. Package Name - Change from com.example.assetguard
**Action:** Change to production package name  
**Recommendation:** `io.assetguard.app` (following reverse domain convention)  
**Files to modify:**
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml` (verify namespace)

#### ✅ B1. Network Security Config - Remove Dev IPs
**Action:** Remove hardcoded development IPs, leave production-ready config  
**File:** `android/app/src/main/res/xml/network_security_config.xml`

#### ✅ B2. Diagnostic Logging - Remove/Gate Console Logs
**Action:** Remove diagnostic logging added during V1/V2 debugging  
**Files:** `backend/src/controllers/communityController.js`  
**Note:** Keep error logging, remove verbose diagnostic logs

---

### Items REQUIRING User Decisions/Actions

#### ⚠️ A1. Flutter API URL - USER ACTION REQUIRED
**Issue:** Hardcoded `http://10.151.32.221:5000`  
**Options:**
1. Use environment variable configuration (requires rebuild per environment)
2. Use configurable settings screen (requires UI development)
3. Use build flavors (requires gradle configuration)

**RECOMMENDED SOLUTION:**
Create a simple `lib/config/environment.dart` file with build-time configuration:
```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.151.32.221:5000', // development default
  );
}
```

Then build with: `flutter build apk --dart-define=API_URL=http://your-production-url:5000`

**USER MUST PROVIDE:** Production backend URL

---

#### ⚠️ A3. Release Signing - USER ACTION REQUIRED
**Issue:** Using debug signing keys  
**USER MUST PROVIDE:**
1. Production keystore file (`upload-keystore.jks`)
2. Keystore password
3. Key alias
4. Key password

**Once provided, I will:**
1. Create `android/key.properties` (gitignored)
2. Update `android/app/build.gradle.kts` with release signing config

**For now:** I can create the structure, but user must provide actual keystore

---

#### ⚠️ A4. Cleartext Traffic - USER DECISION REQUIRED
**Question:** Will production backend use HTTP or HTTPS?

**If HTTP (simpler deployment):**
- Keep `usesCleartextTraffic="true"`
- Keep current network security config

**If HTTPS (more secure):**
- Remove `usesCleartextTraffic="true"`
- Update network security config to require HTTPS
- User must obtain SSL certificate for backend

**RECOMMENDATION:** Start with HTTP for initial deployment, migrate to HTTPS later

---

#### ⚠️ A5. ML Server URL - USER DECISION REQUIRED
**Question:** Where will ML V1 server be deployed?

**Option A: Co-located with backend (same machine)**
- Keep `ML_API_URL=http://localhost:8000`
- No changes needed

**Option B: Separate machine**
- User must provide ML server IP/domain
- Update `.env` with `ML_API_URL=http://<ml-server-ip>:8000`

**RECOMMENDATION:** Co-locate ML server with backend (Option A)

---

#### ⚠️ A6. APP_BASE_URL - Already Resolved
**Status:** Email verification is disabled, so this is NOT a blocker
**Action:** No immediate action required
**Note:** If user enables email verification later, they must update this

---

## IMPLEMENTATION SEQUENCE

### Phase 1: Safe Changes (I will do now)
1. ✅ Change package name to `io.assetguard.app`
2. ✅ Clean up network security config
3. ✅ Remove diagnostic logging from backend
4. ✅ Create signing config structure (user must add keystore)
5. ✅ Create environment config structure for API URL

### Phase 2: User Actions Required
1. ⚠️ Decide: HTTP or HTTPS?
2. ⚠️ Decide: ML server deployment location
3. ⚠️ Provide: Production backend URL/domain
4. ⚠️ Provide: Release keystore file + passwords
5. ⚠️ Configure: Production server IP addresses

### Phase 3: Final Build (After user actions)
1. Build release APK with production configuration
2. Test end-to-end flow
3. Deploy backend to production server
4. Deploy ML V1 server
5. Verify complete system

---

## PROCEEDING WITH PHASE 1 NOW

I will implement all safe changes that don't require user decisions.
