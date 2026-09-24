# AssetGuard Production Deployment Guide

## Prerequisites

- GitHub repository: `MythiAM2005/assetguard`
- Deployment branch: `clean-main`
- MongoDB Atlas account
- Render account (for backend hosting)
- Email service account (Resend - optional)

## Backend Deployment (Render)

### 1. Create Render Web Service

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository: `MythiAM2005/assetguard`
4. Select branch: `clean-main`

### 2. Configure Render Service

**Build Settings:**
- **Name**: `assetguard-backend` (or your choice)
- **Region**: Choose closest to your users
- **Branch**: `clean-main`
- **Root Directory**: `backend`
- **Runtime**: `Node`
- **Build Command**: `npm install`
- **Start Command**: `npm start`

### 3. Environment Variables (Render Dashboard)

Configure these in Render's Environment section. **DO NOT** commit these values to Git.

#### Required Variables

| Variable Name | Description | How to Get |
|--------------|-------------|------------|
| `MONGODB_URI` | MongoDB Atlas connection string | See MongoDB Setup section below |
| `JWT_SECRET` | Random secret for JWT signing | Generate with: `openssl rand -hex 32` |
| `ML_API_URL` | Python ML server URL | `https://wifi-server-sl6b.onrender.com` |
| `APP_BASE_URL` | Your backend URL | `https://YOUR-APP-NAME.onrender.com` |
| `NODE_ENV` | Environment mode | `production` |
| `PORT` | Server port | Auto-provided by Render |

#### Optional Variables (Email Verification)

| Variable Name | Description | How to Get |
|--------------|-------------|------------|
| `RESEND_API_KEY` | Email service API key | Sign up at [resend.com](https://resend.com) |
| `RESEND_FROM_EMAIL` | Verified sender email | Configure in Resend dashboard |
| `EMAIL_VERIFICATION_ENABLED` | Enable email verification | `false` (set to `true` when ready) |

### 4. Deploy

1. Click "Create Web Service"
2. Render will automatically deploy from `clean-main`
3. Wait for deployment to complete (check logs)
4. Test health endpoint: `https://your-app.onrender.com/api/health`

---

## MongoDB Atlas Setup

### 1. Create Database

1. Go to [MongoDB Atlas](https://cloud.mongodb.com)
2. Create a new cluster (free tier available)
3. Database name: `assetguard`

### 2. Configure Network Access

1. Go to "Network Access" in Atlas
2. Add IP Address: `0.0.0.0/0` (allow from anywhere)
   - For production, consider restricting to Render's IP ranges

### 3. Create Database User

1. Go to "Database Access"
2. Create new user with password
3. Grant "Read and write to any database" permission

### 4. Get Connection String

1. Click "Connect" on your cluster
2. Choose "Connect your application"
3. Copy connection string
4. Format: `mongodb+srv://username:password@cluster.mongodb.net/?appName=assetguard`
5. Replace `username` and `password` with your database user credentials
6. Add this as `MONGODB_URI` in Render environment variables

---

## Android Production Build

### 1. Generate Keystore (One-Time Setup)

**⚠️ SECURITY WARNING: Never commit the keystore or key.properties file!**

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Follow prompts to set:
- Keystore password (save securely!)
- Key password (can be same as keystore password)
- Your name and organization details

**Store the keystore and passwords securely!** You'll need them for all future releases.

### 2. Configure Signing

Create `android/key.properties` file:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=upload
storeFile=upload-keystore.jks
```

**⚠️ This file is excluded from Git - do not commit it!**

### 3. Build Release APK

Replace `YOUR_BACKEND_URL` with your Render backend URL:

```bash
flutter build apk \
  --dart-define=API_URL=https://YOUR_BACKEND_URL.onrender.com \
  --dart-define=ML_API_URL=https://wifi-server-sl6b.onrender.com
```

Or for app bundle (Google Play):

```bash
flutter build appbundle \
  --dart-define=API_URL=https://YOUR_BACKEND_URL.onrender.com \
  --dart-define=ML_API_URL=https://wifi-server-sl6b.onrender.com
```

### 4. Locate Build Output

- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`

---

## Post-Deployment Verification

### 1. Test Backend Health

```bash
curl https://your-backend.onrender.com/api/health
```

Expected response:
```json
{
  "success": true,
  "data": {
    "message": "AssetGuard API is running",
    "database": "connected",
    "timestamp": "2024-01-01T00:00:00.000Z"
  }
}
```

### 2. Test Backend API

Try registering a test user through the mobile app or via API:

```bash
curl -X POST https://your-backend.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#",
    "name": "Test User"
  }'
```

### 3. Test Mobile App

1. Install APK on Android device
2. Register new account
3. Add test asset
4. Verify API communication

---

## Security Checklist

Before going live, verify:

- [ ] `backend/.env` is NOT committed to Git
- [ ] `backend/.env.backup` is NOT committed to Git
- [ ] `android/key.properties` is NOT committed to Git
- [ ] `android/app/*.jks` keystores are NOT committed to Git
- [ ] `JWT_SECRET` is a strong random value (32+ characters)
- [ ] MongoDB credentials are secure and not shared
- [ ] `MONGODB_URI` uses a strong password
- [ ] Keystore password is stored securely offline
- [ ] Production APK is signed with production keystore
- [ ] CORS is configured appropriately for your domains
- [ ] No hardcoded API keys in source code
- [ ] GitHub Secret Scanning shows no alerts

---

## Troubleshooting

### Backend won't start on Render

- Check Render logs for errors
- Verify all required environment variables are set
- Test MongoDB connection string locally first
- Ensure `clean-main` branch is pushed to GitHub

### MongoDB connection fails

- Verify IP whitelist includes `0.0.0.0/0`
- Check database user has correct permissions
- Verify connection string format
- Test connection string locally first

### Android build fails

- Ensure `key.properties` exists and has correct values
- Verify keystore file path is correct
- Check keystore passwords are correct
- Try building with debug config first: `flutter build apk --debug`

### App can't connect to backend

- Verify backend URL in build command
- Check backend is deployed and health endpoint works
- Verify device has internet connection
- Check Android network security config allows cleartext if using HTTP

---

## Production Maintenance

### Updating Backend

1. Push changes to `clean-main` branch
2. Render will auto-deploy (if enabled)
3. Or manually trigger deploy in Render dashboard

### Updating Mobile App

1. Increment version in `pubspec.yaml`
2. Build new release APK/AAB with updated version
3. Distribute to users or upload to Play Store

### Monitoring

- Monitor Render logs for backend errors
- Monitor MongoDB Atlas for performance and storage
- Check health endpoint regularly
- Set up Render alerts for downtime

---

## Environment Variable Quick Reference

### Required for Backend

```bash
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/?appName=assetguard
JWT_SECRET=<generated-with-openssl-rand-hex-32>
ML_API_URL=https://wifi-server-sl6b.onrender.com
APP_BASE_URL=https://your-backend.onrender.com
NODE_ENV=production
EMAIL_VERIFICATION_ENABLED=false
```

### Required for Flutter Build

```bash
--dart-define=API_URL=https://your-backend.onrender.com
--dart-define=ML_API_URL=https://wifi-server-sl6b.onrender.com
```

---

## Support

For issues or questions:
- Check backend logs in Render dashboard
- Review MongoDB Atlas logs
- Check GitHub repository issues
- Review documentation in repository
