# AssetGuard Deployment Security Audit

**Date**: 2026-09-23  
**Status**: ⚠️ CONTAINS EXPOSED SECRETS  
**Action Required**: Rotate secrets before public deployment

---

## Critical Security Issues

### 🔴 CRITICAL: Secrets Exposed in .env File

**File**: `backend/.env`

**Exposed Credentials**:
- ✅ MongoDB URI with password (visible in file)
- ✅ JWT_SECRET (visible in file)
- ✅ RESEND_API_KEY (visible in file)

**Risk Level**: HIGH if repository becomes public

**Current Protection**: 
- ✅ `.env` is in `.gitignore`
- ❌ Not a git repository yet (no commit history to audit)
- ✅ File is local only

**Action Required**:
1. **Before initializing git**: Verify `.env` is in `.gitignore` ✅
2. **Before first commit**: Double-check `.env` is not staged
3. **Before public deployment**: Rotate all secrets
4. **Before pushing to GitHub**: Run `git log --all --full-history -- "*.env"` to ensure no .env was ever committed

### Secrets Configuration

**MongoDB Atlas**:
```
MONGODB_URI=<configured securely in Render>
Format: mongodb+srv://<username>:<password>@<cluster>.mongodb.net/?appName=<appname>
```

**JWT Secret**:
```
JWT_SECRET=<configured securely in Render>
Generate with: openssl rand -hex 32
```

**Resend API Key**:
```
RESEND_API_KEY=<configured securely in Render>
Obtain from: https://resend.com/api-keys
```

**Status**: All production credentials must be set as environment variables in Render Dashboard.

---

## Files Containing Secrets

### Must NOT Be Committed

| File | Contains | Git Status | Protected? |
|------|----------|------------|------------|
| `backend/.env` | MongoDB URI, JWT_SECRET, RESEND_API_KEY | ✅ In .gitignore | ✅ Yes |

### Safe to Commit

| File | Purpose | Git Status |
|------|---------|------------|
| `backend/.env.example` | Template (no real values) | ✅ Safe to commit |
| `backend/src/**/*.js` | Source code (no secrets) | ✅ Safe to commit |
| `lib/**/*.dart` | Flutter code (no secrets) | ✅ Safe to commit |

---

## Environment Variables Security

### Backend (.env)

**Current Configuration**:
```bash
MONGODB_URI=<configured securely in Render>  # MongoDB Atlas connection
JWT_SECRET=<configured securely in Render>  # JWT signing secret
RESEND_API_KEY=<configured securely in Render>  # Email API key
ML_API_URL=http://localhost:8000  # ✅ Configurable
APP_BASE_URL=http://192.168.1.18:5000  # ✅ Configurable
EMAIL_VERIFICATION_ENABLED=false  # ✅ Safe
```

**Production Recommendations**:
1. Generate new JWT_SECRET: `openssl rand -hex 32`
2. Rotate MongoDB password in Atlas
3. Get new Resend API key if exposed
4. Set production URLs in Render dashboard

---

## Code Security Audit

### ✅ No Hardcoded Secrets in Source Code

**Backend**:
- ✅ No hardcoded MongoDB URIs
- ✅ No hardcoded API keys
- ✅ No hardcoded passwords
- ✅ All secrets loaded from environment variables

**Flutter**:
- ✅ No hardcoded backend URLs (uses Environment.apiBaseUrl)
- ✅ No API keys in code
- ✅ API URL configurable at build time

### ✅ No Hardcoded IPs/URLs in Production Code

**Backend**:
- ✅ ML_API_URL loaded from environment (not hardcoded)
- ✅ PORT from environment (Render-compatible)
- ✅ Binds to 0.0.0.0 (accepts connections from all interfaces)

**Flutter**:
- ✅ API_URL set via --dart-define at build time
- ✅ Default is development IP (safe fallback)
- ⚠️ Default should be changed for production builds

---

## CORS Configuration

**Current**: `app.use(cors())`

**Allows**: All origins

**Risk Assessment**: ✅ ACCEPTABLE for mobile app
- Mobile apps don't send Origin headers
- CORS is a browser-only security feature
- Backend is called directly from Flutter (not from web browser)

**Recommendation**: Keep as-is. No change needed.

---

## Authentication Security

### JWT Implementation

**Method**: bcrypt password hashing + JWT tokens

**Security Features**:
- ✅ Passwords hashed with bcrypt (not stored plain text)
- ✅ JWT tokens signed with secret
- ✅ Protected routes require valid JWT
- ✅ Tokens include user ID + email

**Potential Issues**:
- ⚠️ No token expiration visible (check auth middleware)
- ⚠️ No refresh token mechanism
- ⚠️ No rate limiting on login endpoint

**Recommendation**: Add rate limiting for production:
```javascript
npm install express-rate-limit
```

---

## Database Security

### MongoDB Atlas

**Current**:
- ✅ Hosted on Atlas (managed security)
- ✅ Connection uses SSL/TLS (mongodb+srv://)
- ✅ Authentication required
- ✅ Database name: 'assetguard'

**IP Whitelist**: Currently configured (check Atlas dashboard)

**Production Recommendation**:
- Add Render's outgoing IPs to whitelist
- Or use 0.0.0.0/0 for free tier simplicity (less secure but acceptable for testing)

---

## API Security

### Public Endpoints (No Auth Required)

- `POST /api/auth/register` - ⚠️ Should have rate limiting
- `POST /api/auth/login` - ⚠️ Should have rate limiting
- `GET /api/auth/verify-email` - ✅ Uses token
- `GET /api/health` - ✅ Safe

### Protected Endpoints (JWT Required)

All other endpoints require valid JWT:
- `GET /api/assets/*`
- `POST /api/detections/*`
- `POST /api/location/predict-room`
- `GET /api/notifications/*`
- etc.

**Security**: ✅ GOOD - sensitive operations protected

---

## ML Server Security

**Current Status**: Separate project (not audited here)

**Recommendations for ML Server**:
1. Add authentication (shared secret or JWT)
2. Rate limiting on /predict-room endpoint
3. Input validation (Wi-Fi fingerprint format)
4. Health endpoint should be public
5. Prediction endpoint should be protected

**Current Backend Implementation**:
- ✅ Backend acts as proxy (users call backend, not ML directly)
- ✅ Backend requires JWT for /predict-room
- ✅ ML server doesn't need to implement auth (backend protects it)

---

## Flutter APK Security

### Build Configuration

**Current**:
- API_URL set at build time (--dart-define)
- No secrets embedded in APK

**Recommendations**:
- ✅ Use HTTPS in production (Render provides free SSL)
- ✅ Sign APK with production keystore
- ❌ Do NOT commit keystore to git
- ❌ Do NOT commit key.properties with passwords

---

## Git Repository Security

### Not Yet Initialized

**Status**: Not a git repository yet

**Before `git init`**:
1. ✅ Verify `.gitignore` includes `.env`
2. ✅ Verify `.gitignore` includes `node_modules/`
3. ✅ Create `backend/.env.example` (done)
4. ✅ Add `*.jks` to `.gitignore` (for keystores)
5. ✅ Add `key.properties` to `.gitignore`

### Recommended .gitignore Additions

Add to root `.gitignore`:
```gitignore
# Backend secrets
backend/.env

# Android signing
*.jks
*.keystore
android/key.properties

# iOS signing
ios/Runner/GoogleService-Info.plist
```

---

## Deployment Secrets Management

### Render Dashboard

**How to Set Environment Variables**:
1. Render Dashboard → Service → Environment
2. Add each variable manually
3. Do NOT use render.yaml for secret values
4. Mark sensitive variables as "secret" in Render

**Variables to Set in Render**:
```bash
MONGODB_URI=<new rotated value>
JWT_SECRET=<new generated value>
ML_API_URL=https://assetguard-ml.onrender.com
APP_BASE_URL=https://assetguard-backend.onrender.com
RESEND_API_KEY=<from Resend dashboard>
RESEND_FROM_EMAIL=onboarding@resend.dev
EMAIL_VERIFICATION_ENABLED=false
```

---

## Pre-Deployment Checklist

### Secrets Rotation (Before Public Deployment)

- [ ] Generate new JWT_SECRET: `openssl rand -hex 32`
- [ ] Rotate MongoDB password in Atlas
- [ ] Verify Resend API key is for production account
- [ ] Store secrets in password manager (not in git)

### Git Security

- [ ] Initialize git repository
- [ ] Verify `.gitignore` is working: `git status` should NOT show `.env`
- [ ] Make first commit
- [ ] Check no secrets committed: `git log --all --patch -- "*.env"`

### Render Configuration

- [ ] Deploy ML server first
- [ ] Set all environment variables in Render dashboard
- [ ] Test health endpoint
- [ ] Deploy backend
- [ ] Test end-to-end

### Flutter APK

- [ ] Build with production URL
- [ ] Test on physical device
- [ ] Verify connects to production backend
- [ ] Sign with production keystore

---

## Security Recommendations Summary

### Immediate (Before Any Deployment)

1. ✅ `.env` is in `.gitignore` - DONE
2. ✅ Created `.env.example` - DONE
3. ⚠️ Rotate secrets before public deployment
4. ⚠️ Use HTTPS for production (Render provides this automatically)

### Short Term (Before Public Launch)

1. Add rate limiting to auth endpoints
2. Implement JWT token expiration
3. Add refresh token mechanism
4. Set up monitoring/alerts for suspicious activity

### Long Term (Production Hardening)

1. Regular security audits
2. Dependency updates (`npm audit fix`)
3. Penetration testing
4. Bug bounty program

---

## Current Risk Assessment

| Area | Risk Level | Mitigation Status |
|------|-----------|-------------------|
| Secrets in .env | 🟡 Medium | ✅ In .gitignore |
| Hardcoded credentials | 🟢 Low | ✅ None found |
| Database security | 🟢 Low | ✅ Atlas managed |
| API authentication | 🟢 Low | ✅ JWT implemented |
| Rate limiting | 🟡 Medium | ⚠️ Not implemented |
| HTTPS | 🟢 Low | ✅ Render provides |
| APK signing | 🟡 Medium | ⚠️ Manual setup needed |

**Overall**: ✅ Safe for initial deployment and testing. Implement rate limiting before public launch.

---

## Files Audit Summary

### Files Changed for Deployment

1. `backend/server.js` - Added 0.0.0.0 binding ✅
2. `backend/.env.example` - Created template ✅
3. `backend/render.yaml` - Created deployment config ✅
4. `CLOUD_DEPLOYMENT_GUIDE.md` - Created documentation ✅
5. `DEPLOYMENT_SECURITY_AUDIT.md` - This file ✅

### Files That Must NEVER Be Committed

1. `backend/.env` - Contains real secrets ❌
2. `*.jks` / `*.keystore` - Android signing keys ❌
3. `android/key.properties` - Keystore passwords ❌

### Files Safe to Commit

1. All source code (.js, .dart) ✅
2. Configuration examples (.env.example) ✅
3. Documentation (.md) ✅
4. Deployment configs (render.yaml with sync: false) ✅

---

## Action Required Before Deployment

1. **Review this security audit**
2. **Decide**: Keep current development secrets or rotate now?
3. **If rotating**: Generate new secrets and update Render dashboard
4. **If keeping**: Ensure .env never gets committed
5. **Initialize git**: `git init` and verify `.gitignore` working
6. **Deploy**: Follow CLOUD_DEPLOYMENT_GUIDE.md

**Current Status**: ✅ Ready for deployment with current development secrets  
**Production Status**: ⚠️ Rotate secrets before public launch
