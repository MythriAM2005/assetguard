const { body } = require('express-validator');
const { success, error } = require('../utils/response');

// ── Config ────────────────────────────────────────────────────────────────

/**
 * Base URL of the Python FastAPI ML server.
 * Loaded from ML_API_URL env var so the URL is never hard-coded in source.
 * Falls back to the development default if the var is not set.
 */
const ML_API_BASE = () =>
  (process.env.ML_API_URL || 'http://10.135.90.221:8000').replace(/\/$/, '');

/** How long (ms) to wait for the Python API before giving up. */
const ML_TIMEOUT_MS = 10_000;

// ── Validation ────────────────────────────────────────────────────────────

const predictRoomValidators = [
  body('wifiFingerprint')
    .isObject()
    .withMessage('wifiFingerprint must be an object mapping BSSID to RSSI'),
];

// ── Handler ───────────────────────────────────────────────────────────────

/**
 * POST /api/location/predict-room
 *
 * Accepts a Wi-Fi fingerprint from Flutter, forwards it to the Python ML API,
 * and returns the predicted room with confidence and top-3 predictions.
 *
 * Request body:
 *   { "wifiFingerprint": { "84:d8:1b:aa:bb:cc": -43, ... } }
 *
 * Response body (success):
 *   {
 *     "predictedRoom": "306",
 *     "confidence": 0.28,
 *     "confidencePercent": "28%",
 *     "top3": [
 *       { "room": "306", "probability": 0.28 },
 *       { "room": "209", "probability": 0.22 },
 *       { "room": "310", "probability": 0.17 }
 *     ]
 *   }
 */
const predictRoom = async (req, res) => {
  try {
    const { wifiFingerprint } = req.body;

    if (!wifiFingerprint || typeof wifiFingerprint !== 'object' ||
        Object.keys(wifiFingerprint).length === 0) {
      return error(res,
        'wifiFingerprint is required and must contain at least one BSSID → RSSI entry',
        400);
    }

    const mlUrl = `${ML_API_BASE()}/predict-room`;

    // Forward to Python ML API with a hard timeout
    let mlResponse;
    try {
      const controller = new AbortController();
      const timeoutId  = setTimeout(() => controller.abort(), ML_TIMEOUT_MS);

      mlResponse = await fetch(mlUrl, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ wifi: wifiFingerprint }),
        signal:  controller.signal,
      });

      clearTimeout(timeoutId);
    } catch (fetchErr) {
      if (fetchErr.name === 'AbortError') {
        return error(res,
          'Room prediction timed out. The ML service may be unavailable.',
          504);
      }
      return error(res,
        `Cannot reach the ML service: ${fetchErr.message}`,
        503);
    }

    if (!mlResponse.ok) {
      const body = await mlResponse.text().catch(() => '');
      console.error('ML API returned non-2xx:', mlResponse.status, body);
      return error(res,
        `ML service returned an error (HTTP ${mlResponse.status})`,
        502);
    }

    const mlData = await mlResponse.json();

    // Normalise the Python API response into our standard shape.
    // The Python API may return keys like:
    //   predicted_room, confidence, top_predictions
    // We map these to camelCase for Flutter.
    const predictedRoom      = mlData.predicted_room ?? mlData.predictedRoom ?? 'Unknown';
    const confidence         = mlData.confidence     ?? 0;
    const confidencePercent  = `${Math.round(confidence * 100)}%`;

    // top_predictions may be an array of { room, probability } or similar
    const rawTop = mlData.top_predictions ?? mlData.top3 ?? [];
    const top3 = rawTop.slice(0, 3).map((entry) => ({
      room:        String(entry.room ?? entry.predicted_room ?? '?'),
      probability: Number(entry.probability ?? entry.confidence ?? 0),
    }));

    success(res, {
      predictedRoom,
      confidence,
      confidencePercent,
      top3,
    });
  } catch (err) {
    console.error('predictRoom error:', err);
    error(res, 'Room prediction failed — please try again', 500);
  }
};

module.exports = { predictRoom, predictRoomValidators };
