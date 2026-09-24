# Quick Fix: Email Verification Not Working

## Problem
Verification emails not being delivered to real email addresses (Gmail, Outlook, etc.)

## Root Cause
Resend API key is in **Test Mode** which only allows emails to:
- `delivered@resend.dev`
- Verified custom domains

## ✅ SOLUTION 1: Use Test Email Addresses (Immediate - No Setup)

For testing User A + User B scenario RIGHT NOW:

### Register Users with These Emails:
```
User A (Alice):
Email: delivered+alice@resend.dev
Password: password123

User B (Bob):
Email: delivered+bob@resend.dev
Password: password123
```

**Why this works**: 
- Resend's test mode allows `delivered@resend.dev` and plus addressing
- Emails will be delivered even in test mode
- Each user gets a unique email address
- Perfect for development/testing

**Steps**:
1. Open AssetGuard app
2. Tap "Create Account"
3. Enter name and `delivered+alice@resend.dev`
4. Complete registration
5. Email will arrive at Resend inbox (check: https://resend.com/emails)
6. Tap verification link
7. ✅ Account verified!

**Note**: In Resend test mode, emails to `delivered@resend.dev` are accepted but not actually delivered to a real inbox. However, you can:
- View the email content in Resend dashboard (https://resend.com/emails)
- Copy the verification link manually
- Paste into a browser or deep link tester

## ✅ SOLUTION 2: Upgrade to Production API Key (5 minutes)

For sending to REAL email addresses (Gmail, Outlook, etc.):

### Steps:

1. **Go to Resend Dashboard**:
   - Visit: https://resend.com/api-keys
   - Log in to your Resend account

2. **Check Current Key Status**:
   - Check your Resend API key status in the dashboard
   - Check if it says "Test" or "Production"
   - Check daily limit

3. **Get Production Key**:
   - If current key is Test mode, create a new Production key
   - Click "Create API Key"
   - Name: "AssetGuard Production"
   - Permissions: "Sending access"
   - Click "Create"
   - **Copy the new key immediately** (shown only once)

4. **Update Backend Configuration**:
   - Open: `c:\flutter-project\assetguard\backend\.env`
   - Replace line:
     ```env
     RESEND_API_KEY=<your-production-key>
     ```
   - With your new Production key:
     ```env
     RESEND_API_KEY=re_YourNewProductionKey
     ```
   - Save file

5. **Restart Backend**:
   ```bash
   # Kill existing Node.js process
   taskkill /F /IM node.exe
   
   # Start backend again
   cd c:\flutter-project\assetguard\backend
   npm start
   ```

6. **Test Registration**:
   - Register with your real Gmail/Outlook address
   - Email should arrive within 1-2 minutes
   - Tap verification link
   - ✅ Account verified!

## Testing the Fix

### Verify Email Arrives:

**For Test Addresses** (`delivered+alice@resend.dev`):
- Check Resend dashboard: https://resend.com/emails
- Find email with subject "Verify your AssetGuard AI account"
- Copy the deep link starting with `assetguard://verify-email?token=...`
- On Android phone with app installed, open browser and paste link
- OR manually extract token and call API

**For Real Addresses** (after Production key):
- Check your email inbox (Gmail, Outlook, etc.)
- Look in Spam folder if not in Inbox
- Email from "AssetGuard AI <onboarding@resend.dev>"
- Tap "Verify My Email" button or tap the link

### Verification Link Format:
```
assetguard://verify-email?token=a1b2c3d4e5f6...
```

This deep link should open the AssetGuard app and automatically verify the account.

## Quick Test Command

Run this to verify Resend API is working:

```bash
cd c:\flutter-project\assetguard\backend
node test-resend.js
```

**Expected output**:
```
✅ Email sent successfully!
Email ID: 462b2f14-8447-4555-b43e-d134c6e2e5a6
=== Test Passed ===
```

## What if Email Still Doesn't Arrive?

### Check 1: Backend Console
Look for errors when registration happens:
```
Verification email failed to send: ...
```

If you see this error, the API key is still in Test mode or invalid.

### Check 2: Resend Dashboard
- Go to: https://resend.com/emails
- Check if email appears in the list
- Status should be "Delivered" (green)
- If "Bounced" (red), recipient email is invalid

### Check 3: Spam Folder
Real emails from `onboarding@resend.dev` might go to Spam initially.

### Check 4: API Key Permissions
In Resend dashboard, verify the API key has "Sending access" permission.

## For Multi-User Testing RIGHT NOW

Use this approach to test User A + User B scenario immediately:

```bash
# Device 1 or User A
Register: delivered+alice@resend.dev

# Device 2 or User B  
Register: delivered+bob@resend.dev

# Get verification links from Resend dashboard
# https://resend.com/emails

# Copy tokens and verify accounts
```

Both users can then:
- User A: Create asset, mark as LOST
- User B: Scan for BLE device → community detection reported
- Backend: Records detection with correct user relationships

## Environment Variables

**File**: `backend/.env`

Current configuration:
```env
RESEND_API_KEY=<configured securely in Render>
RESEND_FROM_EMAIL=onboarding@resend.dev
```

**If using Production key**, replace with your new key.

## No Code Changes Required

✅ Email service implementation is correct  
✅ Backend routes are correct  
✅ Flutter app integration is correct  
✅ Deep link handling is correct  

**Only configuration needed**: Production API key for real email addresses

## Summary

**Immediate Solution**: Use `delivered+<name>@resend.dev` for testing  
**Production Solution**: Get Production API key from Resend dashboard  
**Time Required**: 2 minutes (test emails) or 5 minutes (production key)  
**Code Changes**: None required  

The multi-user community detection system is ready to test once users can verify their accounts.
