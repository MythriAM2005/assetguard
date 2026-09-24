# AssetGuard Deployment - Quick Start

**Status**: ✅ Ready for $0 cloud deployment  
**Time Required**: ~1 hour  
**Cost**: $0/month

---

## 🚦 Before You Start

### What You Need
- [ ] Render.com account (create at https://render.com - free)
- [ ] ML server code (separate Python project - contact original developers)
- [ ] MongoDB Atlas connection string (already have: check `backend/.env`)
- [ ] Resend API key (optional, for emails: https://resend.com - free)

### What's Already Done ✅
- Backend configured for cloud hosting
- Flutter configured for production builds
- Environment variable templates created
- Deployment documentation written
- Security audit complete

---

## 🎯 Deployment Order (MUST FOLLOW THIS ORDER)

```
1. ML Server (Render)
        ↓
2. Backend (Render)
        ↓
3. Flutter APK (Build)
        ↓
4. Distribute (Upload)
```

---

## 1️⃣ Deploy ML Server First

**Why First?** Backend needs ML server URL to work.

### Quick Steps

1. **Get ML server code** (separate project)
   - Files needed: `main.py`, `*.pkl` models, `requirements.txt`
   - See: `ML_SERVER_DEPLOYMENT_INSTRUCTIONS.md`

2. **Deploy to Render**:
   ```
   Service Type: Web Service
   Name: assetguard-ml
   Runtime: Python 3
   Build: pip install -r requirements.txt
   Start: uvicorn main:app --host 0.0.0.0 --port $PORT
   ```

3. **Test it works**:
   ```bash
   curl https://assetguard-ml.onrender.com/health
   ```

4. **Copy the URL**: `https://assetguard-ml.onrender.com`

**Time**: ~30 minutes

---

## 2️⃣ Deploy Backend

### Quick Steps

1. **Create Render Web Service**:
   ```
   Service Type: Web Service
   Name: assetguard-backend
   Runtime: Node
   Root Directory: backend
   Build: npm install
   Start: npm start
   ```

2. **Set Environment Variables** (in Render Dashboard):
   ```bash
   MONGODB_URI=<configured securely in Render>
   JWT_SECRET=<configured securely in Render>
   ML_API_URL=https://assetguard-ml.onrender.com
   APP_BASE_URL=https://assetguard-backend.onrender.com
   EMAIL_VERIFICATION_ENABLED=false
   ```

3. **Deploy** (Render will auto-deploy)

4. **Whitelist Render IP in MongoDB Atlas**:
   - MongoDB Atlas → Network Access → Add IP
   - Use `0.0.0.0/0` for simplicity (or Render's specific IPs)

5. **Test it works**:
   ```bash
   curl https://assetguard-backend.onrender.com/api/health
   ```
   
   Should return:
   ```json
   {"success": true, "data": {"message": "AssetGuard API is running", "database": "connected"}}
   ```

6. **Copy the URL**: `https://assetguard-backend.onrender.com`

**Time**: ~20 minutes

---

## 3️⃣ Build Production APK

### Quick Steps

1. **Open PowerShell** in project directory:
   ```powershell
   cd c:\flutter-project\assetguard
   ```

2. **Build APK with production URL**:
   ```powershell
   flutter build apk --release `
     --dart-define=API_URL=https://assetguard-backend.onrender.com
   ```

3. **APK Location**:
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```

4. **Test on phone**:
   - Copy APK to phone
   - Install and launch
   - Try registering/logging in
   - Verify it connects to cloud backend

**Time**: ~15 minutes

---

## 4️⃣ Distribute APK

### Option A: Google Drive (Simplest)
1. Upload `app-release.apk` to Google Drive
2. Get shareable link
3. Share with users
4. Users download and install

### Option B: GitHub Releases
1. Create GitHub repository
2. Create release
3. Upload APK as release asset
4. Share release URL

### Option C: Simple Website (Vercel)
1. Create `index.html` with download button
2. Deploy to Vercel (free)
3. Share website URL

**Time**: ~10 minutes

---

## 🆘 Troubleshooting

### Backend health shows "database": "disconnected"
**Fix**: Add `0.0.0.0/0` to MongoDB Atlas IP whitelist

### Backend can't reach ML server
**Fix**: Check `ML_API_URL` in Render environment variables (no trailing slash)

### APK shows "Network Error" on login
**Fix**: Verify backend is running, rebuild APK with correct URL

### First request takes 30+ seconds
**Normal**: Render free tier cold start. Set up UptimeRobot to keep services warm.

---

## 📊 Post-Deployment Checklist

After deployment, test these features:

- [ ] User registration works
- [ ] User login works
- [ ] Dashboard loads
- [ ] Can add asset
- [ ] BLE scanning works (if device supports)
- [ ] Wi-Fi scanning works (needs location permission)
- [ ] Room prediction works (if Wi-Fi fingerprint available)
- [ ] Notifications appear

---

## 📞 Need Help?

**Full Documentation**:
- Detailed guide: `CLOUD_DEPLOYMENT_GUIDE.md`
- Security info: `DEPLOYMENT_SECURITY_AUDIT.md`
- ML server: `ML_SERVER_DEPLOYMENT_INSTRUCTIONS.md`
- Status summary: `DEPLOYMENT_READINESS_SUMMARY.md`

**Common Issues**:
1. Check health endpoints first (backend and ML)
2. Review Render deployment logs
3. Verify environment variables are set correctly
4. Test each component individually

---

## 💰 Free Tier Limits

| Service | Limit | Acceptable For |
|---------|-------|----------------|
| Render (per service) | 750 hrs/month, spins down after 15 min | ✅ Testing, demos |
| MongoDB Atlas M0 | 512MB storage | ✅ Hundreds of users |
| Resend | 100 emails/day | ✅ Small user base |

**Upgrade When**:
- Cold starts become annoying (Render: $7/month)
- Need more storage (MongoDB: $9/month)
- Need more emails (Resend: $20/month)

---

## ⏱️ Time Estimate

| Phase | Time | Can Skip? |
|-------|------|-----------|
| ML deployment | 30 min | ❌ No |
| Backend deployment | 20 min | ❌ No |
| APK build | 15 min | ❌ No |
| APK distribution | 10 min | ⚪ Can do later |
| Testing | 15 min | ⚪ Recommended |
| **Total** | **~1.5 hours** | |

---

## ✅ Ready to Deploy?

1. Read this guide ✅
2. Have Render account ready
3. Have ML server code ready
4. Follow steps 1 → 2 → 3 → 4 in order
5. Don't skip ML server (backend needs it)

**DO NOT deploy everything at once**. Deploy step-by-step and test each component.

**Good luck! 🚀**
