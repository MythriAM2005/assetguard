# Email Verification Bypass (Development Mode)

## Overview

This document describes the **development-only** email verification bypass feature implemented in AssetGuard AI. This feature allows developers and testers to register and log in immediately without requiring email verification, which is useful when:

- **Resend is in test mode** and cannot send emails to real email addresses
- **Testing locally** without access to email services
- **Rapid development** where email verification would slow down testing

**⚠️ IMPORTANT:** This is a **DEVELOPMENT-ONLY** feature. The production email verification implementation remains intact and will be re-enabled before deployment.

---

## Configuration

### Environment Variable

The bypass is controlled by a single environment variable in `.env`:

```env
EMAIL_VERIFICATION_ENABLED=false
```

- **`false`**: Email verification is **disabled** (development mode)
- **`true`**: Email verification is **enabled** (production mode)

### Where to Configure

**Backend `.env` file:**
```
c:\flutter-project\assetguard\backend\.env
```

**Example `.env` entry:**
```env
# Email verification (set to false for development/testing)
# When false: users can register and login immediately without email verification
# When true: requires email verification via Resend before login
EMAIL_VERIFICATION_ENABLED=false
```

---

## Behavior

### When `EMAIL_VERIFICATION_ENABLED=false` (Development Mode)

#### Registration (`POST /api/auth/register`)
1. ✅ Account is created with `emailVerified: true`
2. ✅ **No email is sent** (Resend API is not called)
3. ✅ **JWT token returned immediately** in the response
4. ✅ User can log in without any additional steps
5. ✅ Backend logs show clear development mode warnings:
   ```
   ⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.
   ✓ [Auth] User alice@example.com registered and auto-verified (development mode)
   ```

**Response Example:**
```json
{
  "success": true,
  "message": "Account created successfully. You can now sign in.",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "6a8ff6ad929dca45f16848be",
    "name": "Alice Developer",
    "email": "alice@example.com",
    "emailVerified": true,
    "createdAt": "2026-08-27T10:30:00.000Z",
    "updatedAt": "2026-08-27T10:30:00.000Z"
  },
  "devMode": true
}
```

#### Login (`POST /api/auth/login`)
1. ✅ Allows login even if `emailVerified: false` (for legacy accounts)
2. ✅ Backend logs warning when allowing unverified users:
   ```
   ⚠️  [Auth] Email verification DISABLED — allowing unverified user alice@example.com to login (development mode)
   ```

#### Flutter Frontend
1. ✅ Checks if user is logged in after registration
2. ✅ **Skips the "Verify Your Email" screen** automatically
3. ✅ Navigates directly to `MainShell` (logged-in app)

---

### When `EMAIL_VERIFICATION_ENABLED=true` (Production Mode)

This is the **production behavior** that requires email verification:

#### Registration (`POST /api/auth/register`)
1. ✅ Account is created with `emailVerified: false`
2. ✅ Verification token is generated and hashed
3. ✅ **Verification email is sent** via Resend
4. ✅ **No JWT token is returned**
5. ✅ User must click the verification link in the email
6. ✅ Backend logs show production mode behavior:
   ```
   [Auth] Email verification ENABLED — sending verification email
   ```

**Response Example:**
```json
{
  "success": true,
  "message": "Account created. Please check your email to verify your account.",
  "emailSent": true
}
```

#### Email Verification (`GET /api/auth/verify-email?token=...`)
1. ✅ Validates the token
2. ✅ Marks account as verified (`emailVerified: true`)
3. ✅ Returns JWT token for immediate login

#### Login (`POST /api/auth/login`)
1. ✅ **Rejects unverified users** with `403 Forbidden`
2. ✅ Error message: "Please verify your email address before logging in"
3. ✅ User must verify email before login is allowed

#### Flutter Frontend
1. ✅ Shows "Verify Your Email" screen after registration
2. ✅ User waits for email and clicks verification link
3. ✅ Deep link handler processes verification
4. ✅ User is logged in after verification

---

## Implementation Details

### Backend Files Modified

1. **`backend/src/controllers/authController.js`**
   - `register()`: Checks `EMAIL_VERIFICATION_ENABLED` and branches logic
   - `login()`: Allows unverified users when verification is disabled
   - Adds clear console logging for development mode

2. **`backend/.env`**
   - Added `EMAIL_VERIFICATION_ENABLED=false`

3. **`backend/.env.example`**
   - Documented the `EMAIL_VERIFICATION_ENABLED` flag

### Frontend Files (Already Implemented)

1. **`lib/services/auth_service.dart`**
   - `register()`: Handles token in response (development mode)
   - Stores JWT immediately if returned by server

2. **`lib/screens/register_screen.dart`**
   - Checks if user is logged in after registration
   - Skips email verification screen if logged in
   - Navigates directly to `MainShell`

### Unchanged Components

The following remain **completely unchanged** to ensure the production verification flow is intact:

- ✅ Email service (`emailService.js`)
- ✅ Token service (`tokenService.js`)
- ✅ Verification endpoints (`/api/auth/verify-email`, `/api/auth/resend-verification`)
- ✅ User model schema (verification fields)
- ✅ Password reset flow
- ✅ JWT architecture
- ✅ Multi-user/multi-tenant logic
- ✅ Database ownership checks
- ✅ BLE scanning
- ✅ Wi-Fi scanning
- ✅ Community detection
- ✅ ML API integration
- ✅ Asset ownership logic

---

## Testing

### Test Script

A comprehensive test script is provided:

```bash
cd backend
node test-email-verification-bypass.js
```

**Tests performed:**
- ✅ **Test A**: Register User A with Gmail address
- ✅ **Test B**: Register User B with Outlook address
- ✅ **Test C**: Login User A
- ✅ **Test D**: Login User B
- ✅ **Test E**: Verify separate accounts
- ✅ **Test F**: Verify JWT/session correctness
- ✅ **Test G**: Verify multi-user functionality
- ✅ **Test H**: Document production mode verification

### Development Mode Logs Test

```bash
cd backend
node test-dev-mode-logs.js
```

Registers a new user and verifies:
- ✅ Server logs show development mode warnings
- ✅ JWT token is returned immediately
- ✅ User is marked as verified
- ✅ Login works immediately

### Manual Testing Checklist

#### Development Mode (`EMAIL_VERIFICATION_ENABLED=false`)

- [ ] Register a new user → Should receive JWT immediately
- [ ] Check backend logs → Should show ⚠️ development mode warnings
- [ ] Login with the new user → Should succeed immediately
- [ ] Check user in MongoDB → `emailVerified` should be `true`
- [ ] Flutter app → Should skip "Verify Your Email" screen

#### Production Mode (`EMAIL_VERIFICATION_ENABLED=true`)

- [ ] Set `EMAIL_VERIFICATION_ENABLED=true` in `.env`
- [ ] Restart backend server: `node server.js`
- [ ] Register a new user → Should NOT receive JWT
- [ ] Check backend logs → Should show "Email verification ENABLED"
- [ ] Try to login immediately → Should fail with 403
- [ ] Check user in MongoDB → `emailVerified` should be `false`
- [ ] Visit verification link → Should verify and log in
- [ ] Login again → Should now succeed

---

## Security Considerations

### ⚠️ Development Mode Security

**When `EMAIL_VERIFICATION_ENABLED=false`:**
- ❌ **Anyone can register** with any email address
- ❌ **No proof of email ownership** required
- ❌ Email addresses are **not validated** beyond syntax
- ⚠️ **Use ONLY for development/testing**

**Backend logs clearly indicate this mode:**
```
⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.
```

### ✅ Production Mode Security

**When `EMAIL_VERIFICATION_ENABLED=true`:**
- ✅ Email ownership is verified via Resend
- ✅ Only verified users can log in
- ✅ Tokens expire after 24 hours
- ✅ Unverified users cannot access protected resources

### Configuration Security

- ✅ Flag is **backend-controlled** (not client-controlled)
- ✅ Flutter client **cannot bypass** verification on its own
- ✅ All verification logic is server-side
- ✅ `.env` file is **gitignored** (not committed)

---

## Production Deployment Checklist

Before deploying to production:

1. [ ] Set `EMAIL_VERIFICATION_ENABLED=true` in production `.env`
2. [ ] Verify Resend API key is valid and not in test mode
3. [ ] Configure production `RESEND_FROM_EMAIL` (verified sender)
4. [ ] Update `APP_BASE_URL` to production domain
5. [ ] Test full verification flow in production environment
6. [ ] Verify deep links work correctly in production app
7. [ ] Remove or disable test user accounts
8. [ ] Monitor backend logs for unexpected development mode warnings

---

## Troubleshooting

### Issue: User registered but can't login

**Development Mode:**
- Check `.env`: Is `EMAIL_VERIFICATION_ENABLED=false`?
- Restart backend server after changing `.env`
- Check backend logs for development mode warnings

**Production Mode:**
- Verify user clicked the email verification link
- Check MongoDB: Is `emailVerified: true`?
- Check spam folder for verification email
- Use `/api/auth/resend-verification` to send new link

### Issue: Flutter app stuck on "Verify Your Email" screen

- Check if user is actually logged in (`AuthService.instance.isLoggedIn`)
- Verify backend returned a token in registration response
- Check `EMAIL_VERIFICATION_ENABLED` in backend `.env`
- Restart backend server if `.env` was changed

### Issue: Backend logs show production mode but .env says false

- Restart the backend server → `.env` is only read on startup
- Verify you edited the correct `.env` file (not `.env.example`)
- Check for typos: `EMAIL_VERIFICATION_ENABLED=false` (no quotes)

---

## Switching Between Modes

### Enable Development Mode

1. Edit `backend/.env`:
   ```env
   EMAIL_VERIFICATION_ENABLED=false
   ```

2. Restart backend:
   ```bash
   cd backend
   # Stop existing server (Ctrl+C)
   node server.js
   ```

3. Verify logs show:
   ```
   ⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.
   ```

### Enable Production Mode

1. Edit `backend/.env`:
   ```env
   EMAIL_VERIFICATION_ENABLED=true
   ```

2. Verify Resend configuration:
   ```env
   RESEND_API_KEY=re_your_production_key
   RESEND_FROM_EMAIL=noreply@yourdomain.com
   ```

3. Restart backend:
   ```bash
   cd backend
   # Stop existing server (Ctrl+C)
   node server.js
   ```

4. Verify logs show:
   ```
   [Auth] Email verification ENABLED — sending verification email
   ```

---

## Summary

### Development Mode Benefits
- ⚡ **Fast testing** without email delays
- 🧪 **Easy account creation** for testing multi-user features
- 🔧 **No Resend dependency** during development

### Production Mode Benefits
- 🔒 **Email ownership verification**
- ✅ **Account security** against fake registrations
- 📧 **Welcome emails** for real users

### Key Design Principles
1. ✅ **Simple toggle** via environment variable
2. ✅ **Production code preserved** (not deleted)
3. ✅ **Clear logging** to indicate active mode
4. ✅ **Backend-controlled** security (client cannot bypass)
5. ✅ **Zero impact** on other features

---

**Current Status:**
- ✅ Development mode implemented and tested
- ✅ Production mode code path intact
- ✅ All test cases passing
- ✅ Multi-user functionality verified
- ⏳ Ready for production when Resend exits test mode

**Next Steps:**
1. Continue development with `EMAIL_VERIFICATION_ENABLED=false`
2. Before final deployment: Set `EMAIL_VERIFICATION_ENABLED=true`
3. Test production verification flow end-to-end
4. Deploy to production with email verification enabled
