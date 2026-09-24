# Email Verification Bypass - Quick Reference

## ⚡ Quick Toggle

### Enable Development Mode (Skip Email Verification)

1. Edit `backend/.env`:
   ```env
   EMAIL_VERIFICATION_ENABLED=false
   ```

2. Restart backend:
   ```bash
   cd backend
   node server.js
   ```

3. ✅ Users can now register and login immediately without email

### Enable Production Mode (Require Email Verification)

1. Edit `backend/.env`:
   ```env
   EMAIL_VERIFICATION_ENABLED=true
   RESEND_API_KEY=re_your_real_key
   RESEND_FROM_EMAIL=noreply@yourdomain.com
   ```

2. Restart backend:
   ```bash
   cd backend
   node server.js
   ```

3. ✅ Users must verify email before login

---

## 🧪 Quick Test

```bash
cd backend

# Test development mode
node test-dev-mode-logs.js

# Full test suite
node test-email-verification-bypass.js
```

---

## 📋 Current Settings

Check current mode:
```bash
# Windows (PowerShell)
Get-Content backend\.env | Select-String "EMAIL_VERIFICATION_ENABLED"

# View server logs
# (Look for ⚠️ warnings indicating development mode)
```

---

## 🔍 How to Verify Mode

### Development Mode Active
**Server logs show:**
```
⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.
✓ [Auth] User alice@example.com registered and auto-verified (development mode)
```

**Registration response includes:**
```json
{
  "token": "eyJhbGci...",
  "devMode": true
}
```

### Production Mode Active
**Server logs show:**
```
[Auth] Email verification ENABLED — sending verification email
```

**Registration response:**
```json
{
  "message": "Account created. Please check your email to verify your account.",
  "emailSent": true
}
```

---

## ⚠️ Important Notes

- **Development mode is for testing ONLY**
- **Backend must be restarted** after changing `.env`
- **Production code is intact** - just toggling a flag
- **Document your mode** before committing/deploying

---

## 📚 Full Documentation

See detailed docs:
- **`EMAIL_VERIFICATION_BYPASS.md`** - Complete feature documentation
- **`../IMPLEMENTATION_SUMMARY.md`** - Implementation details and test results
