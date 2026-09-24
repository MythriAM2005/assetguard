# AssetGuard Cloud Deployment Guide ($0 Tier)

**Architecture**: Flutter APK → Node.js Backend (Render) → Python ML Server (Render) → MongoDB Atlas

**Status**: READY FOR DEPLOYMENT (preparation complete)

---

## Prerequisites

- [x] MongoDB Atlas account (free tier)
- [ ] Render.com account (free)
- [ ] Resend.com account for emails (free tier)
- [x] AssetGuard backend code
- [ ] AssetGuard V1 ML server code (separate repository)

---

## Deployment Order

1. **MongoDB Atlas** (already configured)
2. **ML Server** → Render Web Service
3. **Backend** → Render Web Service  
4. **Flutter APK** → Build with production URL
5. **Optional**: Deploy download page to Vercel

---

## 1. MongoDB Atlas (Already Configured)

✅ **Status**: Already running on free tier

**Current Connection String**:
```
mongodb+srv://AssetDatabase:<password>@assetguardcluster.5y4lguf.mongodb.net/?appName=AssetGuardCluster
```

**Action Required**: None (already configured)

**Important**: Add Render's outgoing IP addresses to Atlas IP whitelist after backend deployment.

---

## 2. ML Server Deployment (Render)

### Prerequisites

**IMPORTANT**: The ML server is a **separate Python project** not included in this repository.

Required files in ML server repository:
- `room_prediction_api.py` or `main.py` (FastAPI app)
- `assetguard_live_room_model.pkl` (V1 model - DO NOT REPLACE)
- `assetguard_bssid_features.pkl` (105 BSSIDs)
- `requirements.txt`

### Render Configuration

**Service Type**: Web Service

**Settings**:
```
Name: assetguard-ml
Region: Oregon (or closest to your users)
Branch: main
Root Directory: / (or ml-server/ if nested)
Runtime: Python 3
Build Command: pip install -r requirements.txt
Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
```

**Environment Variables**: None required (model files should be in repo)

**Instance Type**: Free

### Verify ML Server Health

After deployment, test the health endpoint:
```bash
curl https://assetguard-ml.onrender.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "model": "V1",
  "features": 105
}
```

Test prediction endpoint:
```bash
curl -X POST https://assetguard-ml.onrender.com/predict-room \
  -H "Content-Type: application/json" \
  -d '{"wifi": {"84:d8:1b:aa:bb:cc": -43, "00:11:22:33:44:55": -67}}'
```

**⚠️ IMPORTANT**: Note your ML server URL for backend configuration:
```
https://assetguard-ml.onrender.com
```

---

## 3. Backend Deployment (Render)

### Render Configuration

**Service Type**: Web Service

**Settings**:
```
Name: assetguard-backend
Region: Oregon (or closest to ML server)
Branch: main
Root Directory: backend
Runtime: Node
Build Command: npm install
Start Command: npm start
```

**Instance Type**: Free

### Environment Variables

Set these in Render Dashboard → Environment:

```bash
# Required
MONGODB_URI=<configured securely in Render>
JWT_SECRET=<configured securely in Render>
ML_API_URL=https://assetguard-ml.onrender.com
APP_BASE_URL=https://assetguard-backend.onrender.com

# Optional (Email)
RESEND_API_KEY=<configured securely in Render>
RESEND_FROM_EMAIL=onboarding@resend.dev
EMAIL_VERIFICATION_ENABLED=false

# PORT is automatically set by Render - DO NOT SET IT
```

### Post-Deployment Steps

1. **Whitelist Render IP in MongoDB Atlas**:
   - Get Render's outgoing IP from deployment logs
   - Add to MongoDB Atlas → Network Access → IP Access List
   - Or allow all IPs: `0.0.0.0/0` (less secure but simpler for free tier)

2. **Test Health Endpoint**:
   ```bash
   curl https://assetguard-backend.onrender.com/api/health
   ```

   Expected response:
   ```json
   {
     "success": true,
     "data": {
       "message": "AssetGuard API is running",
       "database": "connected",
       "timestamp": "2026-09-23T..."
     }
   }
   ```

3. **Test ML Integration**:
   ```bash
   curl -X POST https://assetguard-backend.onrender.com/api/location/predict-room \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <JWT_TOKEN>" \
     -d '{"wifiFingerprint": {"84:d8:1b:aa:bb:cc": -43}}'
   ```

---

## 4. Flutter APK Deployment

### Build Production APK

```powershell
cd c:\flutter-project\assetguard

# Build with production backend URL
flutter build apk --release `
  --dart-define=API_URL=https://assetguard-backend.onrender.com

# APK will be at: build\app\outputs\flutter-apk\app-release.apk
```

### Sign APK (Optional but Recommended)

For production distribution, sign the APK:

1. **Generate Keystore** (first time only):
   ```powershell
   keytool -genkey -v -keystore assetguard-release-key.jks `
     -keyalg RSA -keysize 2048 -validity 10000 `
     -alias assetguard
   ```

2. **Create key.properties**:
   ```properties
   # android/key.properties
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=assetguard
   storeFile=<path-to>/assetguard-release-key.jks
   ```

3. **Update android/app/build.gradle.kts** (already configured in project)

4. **Build signed APK**:
   ```powershell
   flutter build apk --release `
     --dart-define=API_URL=https://assetguard-backend.onrender.com
   ```

### Distribute APK

**Option 1: Direct Download**
- Upload `app-release.apk` to Google Drive / Dropbox / GitHub Releases
- Share download link with users

**Option 2: Simple Download Page (Vercel)**
- Create `index.html` with download button
- Deploy to Vercel (free)
- Users visit website to download APK

**Option 3: Internal Testing**
- Upload to Google Play Console (Internal Testing track)
- No review required for internal testing
- Distribute to testers via email

---

## 5. Optional: Download Page (Vercel)

### Create Download Page

```html
<!-- public/index.html -->
<!DOCTYPE html>
<html>
<head>
  <title>AssetGuard - Download</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial; text-align: center; padding: 50px; }
    .btn { 
      background: #4CAF50; 
      color: white; 
      padding: 15px 30px; 
      border-radius: 5px; 
      text-decoration: none;
      display: inline-block;
      margin: 20px;
    }
  </style>
</head>
<body>
  <h1>AssetGuard</h1>
  <p>Indoor Asset Tracking System</p>
  <a href="/assetguard.apk" class="btn" download>Download APK</a>
  <p><small>Version 1.0.0</small></p>
</body>
</html>
```

### Deploy to Vercel

```bash
npm install -g vercel
vercel login
vercel --prod
```

---

## Post-Deployment Checklist

### Backend
- [ ] Health endpoint responds: `GET /api/health`
- [ ] MongoDB connection shows "connected"
- [ ] ML server URL is correct in environment variables
- [ ] Registration works: `POST /api/auth/register`
- [ ] Login works: `POST /api/auth/login`
- [ ] Protected routes require JWT

### ML Server
- [ ] Health endpoint responds: `GET /health`
- [ ] Prediction endpoint works: `POST /predict-room`
- [ ] Returns room number and confidence
- [ ] V1 model is loaded (105 features)

### Flutter App
- [ ] APK installs on Android device
- [ ] Login screen appears
- [ ] Can register new account
- [ ] Can login with credentials
- [ ] Dashboard loads user data
- [ ] BLE scanning works (if enabled on device)
- [ ] Wi-Fi scanning works (requires location permission)
- [ ] Asset registration works
- [ ] Community detection triggers notifications

---

## Cost Breakdown

| Service | Tier | Cost |
|---------|------|------|
| MongoDB Atlas | M0 (Free) | $0 |
| Render Web Service (Backend) | Free | $0 |
| Render Web Service (ML) | Free | $0 |
| Vercel (Download Page) | Free | $0 |
| Resend (Email) | Free (100/day) | $0 |
| **Total** | | **$0/month** |

### Free Tier Limitations

**Render Free Tier**:
- Services spin down after 15 minutes of inactivity
- First request after sleep: 30-60 second cold start
- 750 hours/month (enough for 1 service)

**Workaround**: Use a free uptime monitor (UptimeRobot) to ping health endpoint every 14 minutes

**MongoDB Atlas Free Tier**:
- 512MB storage
- Shared CPU
- No backups
- Good for testing/demo

**Resend Free Tier**:
- 100 emails/day
- 1 domain
- Enough for testing

---

## Monitoring

### Health Check URLs

Add to UptimeRobot (free) to prevent cold starts:

- Backend: `https://assetguard-backend.onrender.com/api/health` (every 14 min)
- ML Server: `https://assetguard-ml.onrender.com/health` (every 14 min)

### Logs

**Render Logs**:
- Dashboard → Service → Logs
- View real-time logs
- Search and filter

**MongoDB Atlas Logs**:
- Monitoring → Logs
- Connection attempts
- Slow queries

---

## Troubleshooting

### Backend Can't Connect to MongoDB

**Symptom**: Health endpoint shows `"database": "disconnected"`

**Fix**:
1. Check MongoDB Atlas IP whitelist
2. Add `0.0.0.0/0` to allow all IPs (or Render's specific IPs)
3. Verify `MONGODB_URI` environment variable is correct

### Backend Can't Reach ML Server

**Symptom**: Predict room returns "Cannot reach the ML service"

**Fix**:
1. Verify ML server is running: `curl https://assetguard-ml.onrender.com/health`
2. Check `ML_API_URL` environment variable in backend
3. Ensure ML server hasn't spun down (ping it to wake up)

### APK Won't Install

**Symptom**: "App not installed" error

**Fix**:
1. Enable "Install from Unknown Sources" in Android settings
2. Uninstall any previous version first
3. Check APK is not corrupted (download again)

### App Shows "Network Error"

**Symptom**: Login fails with timeout or network error

**Fix**:
1. Verify backend is running: `curl https://assetguard-backend.onrender.com/api/health`
2. Check phone has internet connection
3. Verify APK was built with correct `API_URL`
4. Rebuild APK with correct URL if needed

### Cold Start Delays

**Symptom**: First request takes 30+ seconds

**Fix**:
1. This is normal for Render free tier after 15 minutes idle
2. Set up UptimeRobot to ping every 14 minutes
3. Or upgrade to Render paid tier ($7/month per service)

---

## Security Considerations

### Environment Variables

**DO NOT commit to git**:
- ❌ `backend/.env` (contains real secrets)
- ❌ `key.properties` (contains keystore password)
- ❌ `*.jks` (keystore file)

**Safe to commit**:
- ✅ `backend/.env.example` (template only)
- ✅ Source code
- ✅ Configuration files

### Production Secrets

**Before going to production**:
1. Rotate all secrets (JWT_SECRET, MONGODB_URI password, RESEND_API_KEY)
2. Use strong passwords (32+ characters)
3. Enable MongoDB Atlas IP whitelist (don't use 0.0.0.0/0)
4. Enable HTTPS only (Render provides free SSL)
5. Sign APK with production keystore
6. Store keystore securely (not in git)

### API Security

**Current protection**:
- JWT authentication on protected routes
- CORS enabled (all origins - fine for mobile app)
- MongoDB connection string not exposed in code
- ML server only accessible through backend proxy

**Additional recommendations for production**:
- Rate limiting on auth endpoints
- Email verification enabled
- Monitor for suspicious activity
- Regular security updates

---

## Maintenance

### Regular Tasks

**Monthly**:
- Check Render usage (ensure within free tier)
- Review MongoDB Atlas storage (512MB limit)
- Check error logs for issues

**As Needed**:
- Update dependencies: `npm audit fix`
- Flutter updates: `flutter upgrade`
- Monitor Resend email quota

### Scaling Considerations

**When to upgrade from free tier**:
- Cold starts become unacceptable (>30s delay)
- Need 24/7 uptime
- MongoDB storage exceeds 512MB
- More than 100 users (email limit)

**Next tier costs**:
- Render Starter: $7/month per service
- MongoDB Atlas M10: $9/month
- Resend Pro: $20/month (50k emails)

---

## Next Steps

1. **Deploy ML Server first** (backend depends on it)
2. **Deploy Backend** with ML_API_URL pointing to ML server
3. **Test end-to-end** using curl/Postman
4. **Build Flutter APK** with production backend URL
5. **Test on physical device**
6. **Distribute APK** to users

**DO NOT** deploy automatically - proceed manually and test each step.

---

## Support

**Issues during deployment?**

1. Check this guide's Troubleshooting section
2. Review Render deployment logs
3. Test each component individually (DB → ML → Backend → App)
4. Verify environment variables are set correctly

**Documentation**:
- Render: https://render.com/docs
- MongoDB Atlas: https://www.mongodb.com/docs/atlas/
- Flutter: https://docs.flutter.dev/deployment/android
