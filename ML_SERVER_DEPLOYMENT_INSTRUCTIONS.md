# ML Server Deployment Instructions

**Status**: ML Server is a **SEPARATE PROJECT** (not in this repository)

---

## Important Notice

The Python ML server for AssetGuard is **NOT** included in this repository. It is a separate codebase that must be obtained and deployed independently.

According to project documentation:
- **Model**: V1 (`assetguard_live_room_model.pkl`)
- **Features**: 105 BSSIDs
- **Accuracy**: 97.96%
- **Classes**: 22 rooms
- **Framework**: FastAPI + scikit-learn

---

## Required ML Server Files

The ML server repository must contain:

```
ml-server/
├── main.py (or room_prediction_api.py)
├── assetguard_live_room_model.pkl
├── assetguard_bssid_features.pkl
├── requirements.txt
└── README.md
```

### main.py (FastAPI Application)

The ML server must expose these endpoints:

#### GET /health
Health check endpoint (used by Render and monitoring)

**Response**:
```json
{
  "status": "healthy",
  "model": "V1",
  "features": 105,
  "rooms": 22
}
```

#### POST /predict-room
Room prediction endpoint

**Request**:
```json
{
  "wifi": {
    "84:d8:1b:aa:bb:cc": -43,
    "00:11:22:33:44:55": -67,
    "aa:bb:cc:dd:ee:ff": -52
  }
}
```

**Response**:
```json
{
  "predicted_room": "306",
  "confidence": 0.376667,
  "top_predictions": [
    {"room": "306", "probability": 0.376667},
    {"room": "310", "probability": 0.242857},
    {"room": "209", "probability": 0.180556}
  ]
}
```

### requirements.txt

Minimum required packages:

```txt
fastapi==0.104.1
uvicorn==0.24.0
scikit-learn==1.3.2
numpy==1.26.2
pandas==2.1.3
pydantic==2.5.0
```

---

## Render Deployment Configuration

### Service Settings

```
Service Type: Web Service
Name: assetguard-ml
Region: Oregon (US West) or closest to your users
Branch: main
Root Directory: / (or specify if ML server is in subdirectory)
Runtime: Python 3
Build Command: pip install -r requirements.txt
Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
Instance Type: Free
Health Check Path: /health
```

### Environment Variables

**None required** if model files are in the repository.

If models are stored externally (S3, etc.):
```bash
MODEL_PATH=/path/to/assetguard_live_room_model.pkl
FEATURES_PATH=/path/to/assetguard_bssid_features.pkl
```

---

## Python Application Requirements

### HOST Binding

**CRITICAL**: The ML server MUST bind to `0.0.0.0` to accept connections from Render's proxy:

```python
if __name__ == "__main__":
    import uvicorn
    import os
    
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",  # REQUIRED for Render
        port=port,       # Use Render's PORT
        reload=False
    )
```

### PORT Handling

Render automatically sets the `PORT` environment variable. The ML server must read and use it:

```python
import os
PORT = int(os.environ.get("PORT", 8000))
```

**DO NOT hardcode port 8000** - it will fail on Render.

---

## Model Files

### V1 Model (DO NOT REPLACE)

**File**: `assetguard_live_room_model.pkl`

**Details**:
- Algorithm: Random Forest
- Features: 105 BSSIDs
- Classes: 22 rooms
- Accuracy: 97.96%
- Trained: July 2026

**IMPORTANT**: This is the V1 production model. Do NOT replace it with V2/V3/V4 models.

### Feature File

**File**: `assetguard_bssid_features.pkl`

Contains the list of 105 BSSIDs the model expects as features. Used to transform incoming Wi-Fi fingerprints into the correct feature vector.

---

## Testing the ML Server

### Local Testing (Before Deployment)

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run locally**:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

3. **Test health endpoint**:
   ```bash
   curl http://localhost:8000/health
   ```

   Expected:
   ```json
   {"status": "healthy", "model": "V1", "features": 105}
   ```

4. **Test prediction**:
   ```bash
   curl -X POST http://localhost:8000/predict-room \
     -H "Content-Type: application/json" \
     -d '{"wifi": {"84:d8:1b:aa:bb:cc": -43, "00:11:22:33:44:55": -67}}'
   ```

   Expected:
   ```json
   {
     "predicted_room": "306",
     "confidence": 0.376667,
     "top_predictions": [...]
   }
   ```

### Post-Deployment Testing

After deploying to Render:

1. **Test health**:
   ```bash
   curl https://assetguard-ml.onrender.com/health
   ```

2. **Test prediction**:
   ```bash
   curl -X POST https://assetguard-ml.onrender.com/predict-room \
     -H "Content-Type: application/json" \
     -d '{"wifi": {"84:d8:1b:aa:bb:cc": -43}}'
   ```

3. **Note the URL** for backend configuration:
   ```
   https://assetguard-ml.onrender.com
   ```

---

## Integration with Backend

After ML server deployment, configure the backend:

### Backend Environment Variable

Set in Render Dashboard → Backend Service → Environment:

```bash
ML_API_URL=https://assetguard-ml.onrender.com
```

**DO NOT** include trailing slash.

### Backend Usage

The backend calls the ML server in `backend/src/controllers/locationController.js`:

```javascript
const ML_API_BASE = () =>
  (process.env.ML_API_URL || 'http://localhost:8000').replace(/\/$/, '');

const mlUrl = `${ML_API_BASE()}/predict-room`;
```

The backend:
1. Receives Wi-Fi fingerprint from Flutter
2. Requires JWT authentication
3. Forwards request to ML server
4. Returns prediction to Flutter

**Security**: ML server does NOT need authentication because backend acts as authenticated proxy.

---

## Troubleshooting

### Health Endpoint Returns 404

**Problem**: ML server not running or health endpoint not implemented

**Fix**:
1. Check ML server logs in Render dashboard
2. Verify `/health` endpoint exists in main.py
3. Check start command uses correct app name: `main:app`

### Prediction Returns Error

**Problem**: Model file not loaded or wrong format

**Fix**:
1. Verify `assetguard_live_room_model.pkl` is in repository
2. Check file is not corrupted (should be ~1MB)
3. Verify scikit-learn version matches training version
4. Check logs for model loading errors

### Backend Can't Reach ML Server

**Problem**: ML server URL incorrect or ML server down

**Fix**:
1. Test ML health endpoint directly: `curl https://assetguard-ml.onrender.com/health`
2. Verify `ML_API_URL` in backend environment variables
3. Check ML server hasn't spun down (ping to wake up)
4. Verify no typo in URL (no trailing slash)

### Cold Start Delays

**Problem**: First request takes 30+ seconds after idle

**Fix**: This is normal for Render free tier. Options:
1. Set up UptimeRobot to ping `/health` every 14 minutes
2. Upgrade to Render paid tier ($7/month)
3. Accept cold starts for testing/demo

---

## render.yaml (Optional)

If using Infrastructure as Code:

```yaml
services:
  - type: web
    name: assetguard-ml
    runtime: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
    healthCheckPath: /health
    envVars:
      - key: PYTHON_VERSION
        value: 3.11
```

---

## Security Considerations

### Model File Security

**Model files contain training data**:
- 105 BSSIDs (Wi-Fi access point MAC addresses)
- Room labels and relationships

**Recommendation**:
- If BSSIDs are sensitive: host privately, use authentication
- For campus deployment: likely acceptable to be public
- Consider if BSSID list reveals security-relevant information

### API Security

**Current**: No authentication on ML server (backend proxies all requests)

**This is acceptable because**:
1. Backend requires JWT to call ML server
2. ML server is only called by backend (not by Flutter directly)
3. Rate limiting happens at backend level

**Optional Enhancement**:
Add shared secret between backend and ML server:

```python
# ML server
API_KEY = os.environ.get("ML_API_KEY", "")

@app.post("/predict-room")
async def predict_room(request: Request):
    api_key = request.headers.get("X-API-Key", "")
    if api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")
    # ... rest of prediction logic
```

---

## Performance Considerations

### Free Tier Limitations

**Render Free Tier**:
- Spins down after 15 minutes idle
- Cold start: 30-60 seconds
- 512MB RAM
- Shared CPU

**Is this sufficient?**
- ✅ Yes for testing/demo
- ✅ Yes for low traffic (<100 predictions/day)
- ❌ No for production with real-time requirements

### Optimization Tips

1. **Keep ML server warm**: UptimeRobot ping every 14 minutes
2. **Reduce model size**: Use model compression (if accuracy acceptable)
3. **Cache predictions**: Cache common fingerprints (if privacy acceptable)
4. **Batch requests**: Process multiple fingerprints in one request

### When to Upgrade

Upgrade to Render paid tier ($7/month) if:
- Cold starts become unacceptable
- Need guaranteed uptime
- Prediction volume > 1000/day
- Response time < 1 second required

---

## Next Steps

1. **Obtain ML server code** from original developers
2. **Verify V1 model files** are present and uncorrupted
3. **Test locally** before deploying
4. **Deploy to Render** following configuration above
5. **Test health endpoint** after deployment
6. **Update backend** `ML_API_URL` environment variable
7. **Test end-to-end** from Flutter → Backend → ML

---

## Support

**ML Server Issues**:
1. Check Render deployment logs
2. Test ML server directly (curl health endpoint)
3. Verify model files are loaded
4. Check Python version compatibility

**Integration Issues**:
1. Verify backend `ML_API_URL` is correct
2. Test ML server independently first
3. Check network connectivity
4. Review backend logs for ML server errors

**Documentation**:
- FastAPI: https://fastapi.tiangolo.com/
- Render Python: https://render.com/docs/deploy-fastapi
- scikit-learn: https://scikit-learn.org/stable/
