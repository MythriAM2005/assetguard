# ASSETGUARD PRE-DEPLOYMENT AUDIT FINDINGS

**Audit Date:** 2026-08-28  
**Current State:** V1 ML model active, BLE working, Community Sensing working  
**Deployment Target:** Production Android app + Backend API + ML V1 server

---

## PHASE 2: CLASSIFIED FINDINGS

### ═══════════════════════════════════════════════════════════
### A. MUST FIX BEFORE DEPLOYMENT (Blockers)
### ═══════════════════════════════════════════════════════════

#### A1. Flutter API URL - Hardcoded Development IP
**File:** `lib/utils/api_config.dart`  
**Issue:** `static const String baseUrl = 'http://10.151.32.221:5000';`  
**Impact:** App will fail to connect to backend in production  
**Fix Required:** Use environment-based configuration or make configurable  
**Blocker:** YES - App cannot work without valid backend URL

#### A2. Android Package Name - Example Identifier
**File:** `android/app/build.gradle.kts`  
**Issue:** `applicationId = "com.example.assetguard"`  
**Impact:** Cannot publish to Play Store with example package name  
**Fix Required:** Change to production package ID (e.g., `com.assetguard.app`)  
**Blocker:** YES - Google Play Store will reject

#### A3. Android Signing - Debug Keys Only
**File:** `android/app/build.gradle.kts`  
**Issue:** `signingConfig = signingConfigs.getByName("debug")`  
**Impact:** Release APK signed with debug keys (insecure, cannot publish)  
**Fix Required:** Create release signing config with production keystore  
**Blocker:** YES - Cannot deploy to production without proper signing  
**User Action Required:** Create/provide production keystore file

#### A4. Network Security - Cleartext Traffic Allowed
**File:** `android/app/src/main/AndroidManifest.xml`  
**Issue:** `android:usesCleartextTraffic="true"`  
**Impact:** App allows HTTP (insecure), required for current HTTP backend  
**Fix Required:** Either use HTTPS backend OR keep for HTTP deployment  
**Blocker:** NO if HTTP backend is acceptable, YES if HTTPS required  
**Decision Required:** HTTP or HTTPS for production?

#### A5. Backend ML API URL - Localhost Only
**File:** `backend/.env`  
**Issue:** `ML_API_URL=http://localhost:8000`  
**Impact:** Backend can only reach ML server on same machine  
**Fix Required:** Configure production ML server URL (or keep if co-located)  
**Blocker:** DEPENDS on deployment architecture  
**Decision Required:** ML server deployment location

#### A6. Backend APP_BASE_URL - Development IP
**File:** `backend/.env`  
**Issue:** `APP_BASE_URL=http://192.168.1.18:5000`  
**Impact:** Email verification links point to development server  
**Fix Required:** Update to production domain/IP  
**Blocker:** YES if email verification is enabled, NO if disabled  
**Current State:** Email verification disabled, so NOT a blocker

---

### ═══════════════════════════════════════════════════════════
### B. SHOULD FIX BEFORE DEPLOYMENT (Important but not blockers)
### ═══════════════════════════════════════════════════════════

#### B1. Network Security Config - Hardcoded Dev IPs
**File:** `android/app/src/main/res/xml/network_security_config.xml`  
**Issue:** Multiple development IPs whitelisted (10.151.32.221, 10.128.192.221, etc.)  
**Impact:** Unnecessary whitelist entries in production app  
**Fix:** Remove development IPs, keep only production domain/IP  
**Priority:** SHOULD FIX - cleaner production config

#### B2. Diagnostic Logging - Console.log in Backend
**Files:** `backend/src/controllers/communityController.js` and others  
**Issue:** Extensive diagnostic logging (e.g., `[CommunityWiFi]`, `[Community]`)  
**Impact:** Verbose logs in production, potential performance impact  
**Fix:** Remove or gate behind DEBUG environment variable  
**Priority:** SHOULD FIX - production logs should be cleaner  
**Note:** These were added for debugging V1/V2 issue, now resolved

#### B3. CORS Configuration - Allow All Origins
**File:** `backend/src/app.js`  
**Issue:** `app.use(cors());` allows all origins  
**Impact:** Any website can call the API (potential security risk)  
**Fix:** Restrict to production Flutter app origin  
**Priority:** SHOULD FIX - better security posture  
**Note:** May not be critical if API uses JWT authentication

#### B4. Flutter App Icons - Default Icons
**Location:** `android/app/src/main/res/mipmap-*`  
**Issue:** Likely using default Flutter launcher icons  
**Impact:** App looks unprofessional with default icon  
**Fix:** Replace with custom AssetGuard branding  
**Priority:** SHOULD FIX - branding/UX

#### B5. Splash Screen - Not Audited
**Issue:** Splash screen not checked for branding  
**Impact:** Default Flutter splash may show on app launch  
**Fix:** Customize splash screen with AssetGuard branding  
**Priority:** SHOULD FIX - user experience

---

### ═══════════════════════════════════════════════════════════
### C. OPTIONAL / FUTURE (Can wait)
### ═══════════════════════════════════════════════════════════

#### C1. ProGuard/R8 Obfuscation
**File:** `android/app/build.gradle.kts`  
**Issue:** No ProGuard rules configured  
**Impact:** Unobfuscated release code (easier to reverse engineer)  
**Priority:** OPTIONAL - security improvement

#### C2. MongoDB Indexes
**Database:** Production MongoDB  
**Issue:** No explicit index configuration verified  
**Impact:** Query performance may degrade with scale  
**Priority:** OPTIONAL - monitor and add as needed

#### C3. Backend Health Endpoint Enhancement
**File:** `backend/src/routes/healthRoutes.js`  
**Issue:** Basic health check, no dependency checks  
**Impact:** Cannot verify MongoDB/ML server health from health endpoint  
**Priority:** OPTIONAL - better monitoring

#### C4. Error Tracking Service
**Issue:** No error tracking (e.g., Sentry, LogRocket)  
**Impact:** Cannot monitor production errors remotely  
**Priority:** OPTIONAL - operational improvement

#### C5. Analytics
**Issue:** No analytics tracking configured  
**Impact:** Cannot measure app usage, feature adoption  
**Priority:** OPTIONAL - product insights

#### C6. Backend Rate Limiting
**Issue:** No rate limiting on API endpoints  
**Impact:** Vulnerable to abuse/DDoS  
**Priority:** OPTIONAL - security improvement

#### C7. API Documentation
**Issue:** No OpenAPI/Swagger documentation  
**Impact:** Harder to maintain/integrate  
**Priority:** OPTIONAL - developer experience

---

## ITEMS NOT REQUIRING CHANGES (Working Correctly)

✅ **Android Permissions** - All necessary permissions declared  
✅ **App Name** - "AssetGuard" set correctly  
✅ **Version/Build Number** - 1.0.0+1 set correctly  
✅ **Foreground Service** - Properly configured for Community Sensing  
✅ **Deep Links** - assetguard:// scheme configured  
✅ **MongoDB Connection** - Production Atlas URI present  
✅ **JWT Authentication** - Secret configured, auth working  
✅ **Email Service** - Resend API configured (verification disabled)  
✅ **Database Schema** - Models defined correctly  
✅ **API Routes** - All endpoints properly structured  
✅ **.gitignore** - .env properly excluded  
✅ **BLE Detection** - Working, must NOT be changed  
✅ **Community Sensing** - Working, must NOT be changed  
✅ **Wi-Fi Scanning** - Working, must NOT be changed  
✅ **V1 ML Integration** - Working, must NOT be changed  
✅ **Notification Flow** - Working correctly

---

## DEPLOYMENT ARCHITECTURE DECISIONS REQUIRED

### Decision 1: HTTP vs HTTPS Backend
**Current:** HTTP (cleartext traffic enabled)  
**Options:**  
- A) Deploy with HTTP (simpler, no SSL cert needed)  
- B) Deploy with HTTPS (more secure, requires SSL cert)  

**If A (HTTP):** Keep cleartext traffic enabled  
**If B (HTTPS):** Get SSL cert, update backend, remove cleartext permission

### Decision 2: ML Server Deployment
**Current:** ML server on localhost:8000  
**Options:**  
- A) Deploy ML server on same machine as backend (keep localhost)  
- B) Deploy ML server on separate machine (need IP/domain)  

**If A:** Keep `ML_API_URL=http://localhost:8000`  
**If B:** Update `ML_API_URL=http://<ml-server-ip>:8000`

### Decision 3: Backend Deployment Location
**Current:** Running locally for development  
**Options:**  
- A) Deploy on local network (LAN IP)  
- B) Deploy on cloud server (public IP/domain)  
- C) Deploy on VPS with domain name  

**Choice affects:**  
- Flutter API URL configuration  
- Network security whitelist  
- SSL certificate requirement

### Decision 4: Database Deployment
**Current:** MongoDB Atlas (production-ready)  
**Action:** ✅ Already production-ready, no changes needed

---

## SUMMARY

**Total Issues Found:** 17  
**Must Fix (Blockers):** 6 (4 confirmed, 2 decision-dependent)  
**Should Fix:** 5  
**Optional:** 7  

**Deployment Readiness:** NOT READY (blockers present)

**Next Steps:** Implement Phase 3 (MUST FIX items) based on deployment architecture decisions
