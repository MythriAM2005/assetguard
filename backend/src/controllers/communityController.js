const { body } = require('express-validator');
const CommunityFingerprint = require('../models/CommunityFingerprint');
const CommunityDetection = require('../models/CommunityDetection');
const Notification = require('../models/Notification');
const Asset = require('../models/Asset');
const { success, error } = require('../utils/response');

// ── Validation chains ──────────────────────────────────────────────────────

const submitScanValidators = [
  body('wifiFingerprint')
    .isArray({ min: 1 })
    .withMessage('wifiFingerprint must be a non-empty array'),
  body('wifiFingerprint.*.bssid')
    .trim()
    .notEmpty()
    .withMessage('Each Wi-Fi entry must have a non-empty bssid'),
  body('wifiFingerprint.*.rssi')
    .isInt({ min: -120, max: 0 })
    .withMessage('Each Wi-Fi entry rssi must be an integer between -120 and 0'),
  // Optional device-supplied timestamp; validated as ISO 8601 if present
  body('timestamp')
    .optional()
    .isISO8601()
    .withMessage('timestamp must be a valid ISO 8601 date string'),
];

// ── Handler ────────────────────────────────────────────────────────────────

/**
 * POST /api/community/scan
 *
 * Stores a raw Wi-Fi fingerprint contributed by the authenticated user.
 * No trackerId or asset ownership check — this is community environmental data.
 *
 * Request body:
 * {
 *   "wifiFingerprint": [
 *     { "bssid": "84:d8:1b:aa:bb:cc", "rssi": -43 },
 *     { "bssid": "84:d8:1b:11:22:33", "rssi": -67 }
 *   ],
 *   "timestamp": "2026-08-17T10:30:00.000Z"   // optional
 * }
 *
 * Response body:
 * {
 *   "success": true,
 *   "message": "Community scan recorded.",
 *   "scanId": "<MongoDB _id>"
 * }
 */
const submitScan = async (req, res) => {
  try {
    const { wifiFingerprint, timestamp } = req.body;

    const scan = await CommunityFingerprint.create({
      scannedBy:       req.user._id,   // always from JWT — never from body
      wifiFingerprint: wifiFingerprint.map((ap) => ({
        bssid: ap.bssid.trim().toLowerCase(),
        rssi:  ap.rssi,
      })),
      timestamp: timestamp ? new Date(timestamp) : new Date(),
    });

    success(res, {
      message: 'Community scan recorded.',
      scanId:  scan._id,
    }, 201);
  } catch (err) {
    console.error('submitScan error:', err);
    error(res, 'Failed to record community scan — please try again', 500);
  }
};

// ── Community BLE Detection ────────────────────────────────────────────────

const submitCommunityDetectionValidators = [
  body('trackerId')
    .trim()
    .notEmpty()
    .withMessage('trackerId is required'),
  body('rssi')
    .isInt({ min: -120, max: 0 })
    .withMessage('rssi must be an integer between -120 and 0'),
  body('remoteId')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('remoteId must be a non-empty string if provided'),
  body('detectedAt')
    .isISO8601()
    .withMessage('detectedAt must be a valid ISO 8601 date string'),
  body('latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('latitude must be between -90 and 90'),
  body('longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('longitude must be between -180 and 180'),
  body('wifiFingerprint')
    .optional()
    .isObject()
    .withMessage('wifiFingerprint must be an object mapping BSSID to RSSI'),
];

/**
 * POST /api/community/detections
 *
 * Records a community member's detection of a LOST AssetGuard tracker.
 * Unlike owner detections, this does NOT require asset ownership.
 * The asset MUST have status='LOST' for the detection to be accepted.
 *
 * NEW: Optionally accepts Wi-Fi fingerprint for ML room prediction.
 *
 * Request body:
 * {
 *   "trackerId": "AG-001",
 *   "rssi": -57,
 *   "remoteId": "AA:BB:CC:DD:EE:FF",   // optional
 *   "detectedAt": "2026-08-27T11:45:20Z",
 *   "latitude": 1.3521,                // optional - detector's GPS
 *   "longitude": 103.8198,             // optional - detector's GPS
 *   "wifiFingerprint": {               // optional - for ML room prediction
 *     "84:d8:1b:aa:bb:cc": -43,
 *     "84:d8:1b:dd:ee:ff": -67
 *   }
 * }
 *
 * Response:
 * {
 *   "success": true,
 *   "message": "Community detection recorded. Asset owner will be notified.",
 *   "detectionId": "<MongoDB _id>",
 *   "predictedRoom": "310",            // if Wi-Fi fingerprint provided
 *   "confidence": 0.38                 // if Wi-Fi fingerprint provided
 * }
 */
const submitCommunityDetection = async (req, res) => {
  try {
    const { trackerId, rssi, remoteId, detectedAt, latitude, longitude, wifiFingerprint } = req.body;

    console.log('[Community] ════════════════════════════════════════');
    console.log('[Community] INCOMING DETECTION REQUEST');
    console.log('[Community]   trackerId  :', trackerId);
    console.log('[Community]   rssi       :', rssi, 'dBm');
    console.log('[Community]   remoteId   :', remoteId || 'N/A');
    console.log('[Community]   detectedAt :', detectedAt);
    console.log('[Community]   location   :', latitude && longitude ? `${latitude}, ${longitude}` : 'N/A');
    console.log('[Community]   detectedBy :', req.user._id, '(' + req.user.email + ')');
    console.log('[Community] ════════════════════════════════════════');

    // Look up the asset by trackerId — NOT scoped to user
    // (community members detect other people's assets)
    const asset = await Asset.findOne({
      trackerId: trackerId.trim(),
    }).populate('userId', 'name email');

    if (!asset) {
      console.log('[Community] ✗ Asset not found:', trackerId);
      return error(
        res,
        `Asset with trackerId "${trackerId}" not found in the system`,
        404
      );
    }

    console.log('[Community] ✓ Asset found:', asset._id);
    console.log('[Community]   name       :', asset.name);
    console.log('[Community]   status     :', asset.status);
    console.log('[Community]   owner      :', asset.userId?._id, '(' + asset.userId?.email + ')');

    // CRITICAL: Only accept detections for LOST assets
    // If asset is RECOVERED or ACTIVE, ignore the detection silently
    // Return generic 404 to avoid leaking asset name/status to unauthorized users
    if (asset.status !== 'LOST') {
      console.log('[Community] Detection ignored — asset', trackerId, 'is', asset.status, '(not LOST)');
      return error(
        res,
        `Asset with trackerId "${trackerId}" not found in the system`,
        404
      );
    }

    // SECURITY: Prevent owner from reporting their own asset
    // (owner should use the regular detection flow)
    if (asset.userId._id.toString() === req.user._id.toString()) {
      console.log('[Community] ✗ Owner attempting to report own asset');
      return error(
        res,
        `Asset with trackerId "${trackerId}" not found in the system`,
        404
      );
    }

    console.log('[Community] ✓ All checks passed — creating detection record');

    // ── ML Room Prediction (if Wi-Fi fingerprint provided) ─────────────────

    let predictedRoom = null;
    let roomConfidence = null;

    if (wifiFingerprint && typeof wifiFingerprint === 'object' && Object.keys(wifiFingerprint).length > 0) {
      console.log('[CommunityWiFi] Wi-Fi fingerprint provided with', Object.keys(wifiFingerprint).length, 'BSSIDs');
      console.log('[CommunityWiFi] Calling ML room prediction...');

      try {
        const mlUrl = `${process.env.ML_API_URL || 'http://10.135.90.221:8000'}/predict-room`;
        const mlController = new AbortController();
        const mlTimeoutId = setTimeout(() => mlController.abort(), 10000); // 10 second timeout

        // ═══ COMPREHENSIVE DIAGNOSTIC LOGGING ═══
        const mlPayload = { wifi: wifiFingerprint };
        const bssids = Object.keys(wifiFingerprint);
        const rssiValues = Object.values(wifiFingerprint);
        
        console.log('[CommunityWiFi] ═══════════════════════════════════════');
        console.log('[CommunityWiFi] SENDING TO ML SERVER');
        console.log('[CommunityWiFi] URL:', mlUrl);
        console.log('[CommunityWiFi] ───────────────────────────────────────');
        console.log('[CommunityWiFi] 1. Payload type:', typeof wifiFingerprint);
        console.log('[CommunityWiFi] 2. Number of BSSIDs:', bssids.length);
        console.log('[CommunityWiFi] 3. Is wifi empty?', bssids.length === 0 ? 'YES ⚠️' : 'NO');
        console.log('[CommunityWiFi] 4. Is wifi null?', wifiFingerprint === null ? 'YES ⚠️' : 'NO');
        
        // Validate RSSI values
        const numericRssi = rssiValues.filter(v => typeof v === 'number');
        const nonNumericRssi = rssiValues.filter(v => typeof v !== 'number');
        const nullRssi = rssiValues.filter(v => v === null || v === undefined);
        
        console.log('[CommunityWiFi] 5. RSSI data types:');
        console.log('[CommunityWiFi]    - Numeric:', numericRssi.length);
        console.log('[CommunityWiFi]    - Non-numeric:', nonNumericRssi.length, nonNumericRssi.length > 0 ? '⚠️' : '');
        console.log('[CommunityWiFi]    - Null/undefined:', nullRssi.length, nullRssi.length > 0 ? '⚠️' : '');
        
        if (numericRssi.length > 0) {
          const minRssi = Math.min(...numericRssi);
          const maxRssi = Math.max(...numericRssi);
          const outOfRange = numericRssi.filter(v => v < -120 || v > 0);
          
          console.log('[CommunityWiFi] 6. RSSI range:');
          console.log('[CommunityWiFi]    - Minimum:', minRssi, 'dBm', minRssi < -120 ? '⚠️ OUT OF RANGE' : '');
          console.log('[CommunityWiFi]    - Maximum:', maxRssi, 'dBm', maxRssi > 0 ? '⚠️ OUT OF RANGE' : '');
          console.log('[CommunityWiFi]    - Out of range (-120 to 0):', outOfRange.length, outOfRange.length > 0 ? '⚠️' : '');
          
          if (outOfRange.length > 0) {
            console.log('[CommunityWiFi]    - Invalid values:', outOfRange.slice(0, 5));
          }
        }
        
        if (nonNumericRssi.length > 0) {
          console.log('[CommunityWiFi] 7. Non-numeric RSSI values ⚠️:', nonNumericRssi.slice(0, 5));
        }
        
        console.log('[CommunityWiFi] 8. Sample data (first 3):');
        bssids.slice(0, 3).forEach((bssid, i) => {
          console.log(`[CommunityWiFi]    - ${bssid}: ${wifiFingerprint[bssid]} (type: ${typeof wifiFingerprint[bssid]})`);
        });
        
        console.log('[CommunityWiFi] 9. Payload preview:', JSON.stringify(mlPayload).substring(0, 300) + '...');
        console.log('[CommunityWiFi] ═══════════════════════════════════════');

        const mlResponse = await fetch(mlUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(mlPayload),
          signal: mlController.signal,
        });

        clearTimeout(mlTimeoutId);

        // ═══ LOG HTTP STATUS IMMEDIATELY ═══
        console.log('[CommunityWiFi] ML HTTP STATUS:', mlResponse.status, mlResponse.statusText);

        if (mlResponse.ok) {
          const mlData = await mlResponse.json();
          
          // ═══ LOG SUCCESSFUL RESPONSE BODY ═══
          console.log('[CommunityWiFi] ML RESPONSE BODY:', JSON.stringify(mlData));
          
          predictedRoom = mlData.room || mlData.predicted_room || mlData.predictedRoom;
          roomConfidence = mlData.confidence;

          console.log('[CommunityWiFi] ═══════════════════════════════════════');
          console.log('[CommunityWiFi] ✓ ML API RESPONSE: 200 OK');
          console.log('[CommunityWiFi] ✓ Predicted room:', predictedRoom);
          console.log('[CommunityWiFi] ✓ Confidence:', roomConfidence);
          console.log('[CommunityWiFi] ═══════════════════════════════════════');
        } else {
          console.log('[CommunityWiFi] ═══════════════════════════════════════');
          console.log('[CommunityWiFi] ✗ ML API RESPONSE: HTTP', mlResponse.status, mlResponse.statusText);
          console.log('[CommunityWiFi] ═══════════════════════════════════════');
          
          // DIAGNOSTIC: Capture the full error response body
          try {
            const errorText = await mlResponse.text();
            console.log('[CommunityWiFi] ML RESPONSE BODY:', errorText);
            console.log('[CommunityWiFi] ───────────────────────────────────────');
            
            // Try to parse as JSON for structured error details
            try {
              const errorJson = JSON.parse(errorText);
              console.log('[CommunityWiFi] ✗ Parsed error JSON:');
              console.log(JSON.stringify(errorJson, null, 2));
            } catch (e) {
              console.log('[CommunityWiFi] (Error response is not JSON)');
            }
          } catch (readErr) {
            console.log('[CommunityWiFi] ✗ Could not read error response:', readErr.message);
          }
          console.log('[CommunityWiFi] ═══════════════════════════════════════');
        }
      } catch (mlErr) {
        if (mlErr.name === 'AbortError') {
          console.log('[CommunityWiFi] ✗ ML prediction timed out (>10 seconds)');
        } else {
          console.log('[CommunityWiFi] ✗ ML prediction failed:', mlErr.message);
        }
        // Continue without room prediction - don't fail the detection
      }
    }

    console.log('[Community] Detection submitted:');
    console.log('[Community]   trackerId  :', trackerId);
    console.log('[Community]   assetId    :', asset._id);
    console.log('[Community]   detectedBy :', req.user._id);
    console.log('[Community]   ownerId    :', asset.userId._id);
    console.log('[Community]   assetName  :', asset.name);
    console.log('[Community]   rssi       :', rssi, 'dBm');
    if (latitude && longitude) {
      console.log('[Community]   location   :', `${latitude}, ${longitude}`);
    }

    // Create the community detection record
    const detection = await CommunityDetection.create({
      trackerId: asset.trackerId,
      assetId: asset._id,
      detectedBy: req.user._id, // from JWT — never from request body
      rssi,
      remoteId: remoteId || null,
      detectedAt: new Date(detectedAt),
      latitude: latitude || null,
      longitude: longitude || null,
      predictedRoom,
      roomConfidence,
    });

    console.log('[Community] ✓ Detection created in MongoDB:', detection._id);

    // Create notification for asset owner
    try {
      let message;
      let title = 'Asset Detected';
      
      if (predictedRoom) {
        // Room prediction available
        message = `Your ${asset.name} (${trackerId}) was detected near Room ${predictedRoom}.`;
        if (roomConfidence) {
          const confidencePercent = Math.round(roomConfidence * 100);
          message += ` (${confidencePercent}% confidence)`;
        }
      } else if (latitude && longitude) {
        // GPS location available but no room
        message = `Your ${asset.name} (${trackerId}) was detected at ${latitude.toFixed(4)}, ${longitude.toFixed(4)}.`;
      } else {
        // Basic detection
        message = `Your ${asset.name} (${trackerId}) was detected nearby.`;
      }

      const notification = await Notification.create({
        recipient: asset.userId._id,
        type: 'asset_detected',
        title,
        message,
        assetId: asset._id,
        detectionId: detection._id,
        trackerId: asset.trackerId,
        latitude: latitude || null,
        longitude: longitude || null,
        rssi,
        detectedAt: new Date(detectedAt),
        predictedRoom,
        roomConfidence,
        read: false,
      });

      console.log('[Community] Owner notification created:', notification._id);
      console.log('[Community] Notification sent to:', asset.userId.email);
      console.log('[Community]   title   :', notification.title);
      console.log('[Community]   message :', notification.message);
    } catch (notifErr) {
      // DO NOT fail the detection if notification creation fails
      console.error('[Community] Failed to create notification:', notifErr);
      console.error('[Community] Detection still recorded successfully');
    }

    success(
      res,
      {
        message: 'Community detection recorded. Asset owner will be notified.',
        detectionId: detection._id,
        ...(predictedRoom && { predictedRoom, confidence: roomConfidence }),
      },
      201
    );
  } catch (err) {
    console.error('[Community] submitCommunityDetection error:', err);
    error(res, 'Failed to record community detection — please try again', 500);
  }
};

// ── Get Community Detections for Asset ────────────────────────────────────

/**
 * GET /api/community/detections/asset/:assetId
 *
 * Fetch all community detections for a specific asset owned by the authenticated user.
 * Used by the "Track Asset" feature to display detection history on a map.
 *
 * Security:
 * - Verifies the asset belongs to the authenticated user
 * - Excludes detectedBy field (User B identity remains private)
 *
 * Response:
 * {
 *   "success": true,
 *   "detections": [
 *     {
 *       "_id": "...",
 *       "trackerId": "AG-001",
 *       "assetId": "...",
 *       "rssi": -67,
 *       "latitude": 12.3711,
 *       "longitude": 76.5853,
 *       "detectedAt": "2026-08-28T04:30:00.000Z",
 *       "createdAt": "2026-08-28T04:30:01.123Z"
 *     },
 *     ...
 *   ]
 * }
 */
const getDetectionsForAsset = async (req, res) => {
  try {
    const { assetId } = req.params;

    console.log('[CommunityDetection] Fetching detections for asset:', assetId);
    console.log('[CommunityDetection] Requested by:', req.user.email);

    // Verify asset exists and belongs to authenticated user
    const asset = await Asset.findOne({
      _id: assetId,
      userId: req.user._id, // SECURITY: Only fetch user's own assets
    });

    if (!asset) {
      console.log('[CommunityDetection] Asset not found or unauthorized');
      return error(res, 'Asset not found', 404);
    }

    console.log('[CommunityDetection] Asset verified:', asset.trackerId);

    // Fetch all community detections for this asset, sorted newest first
    const detections = await CommunityDetection.find({ assetId })
      .select('-detectedBy') // PRIVACY: Exclude User B identity
      .sort({ detectedAt: -1 }) // Newest first
      .lean();

    console.log('[CommunityDetection] Found', detections.length, 'detections');

    success(res, { detections });
  } catch (err) {
    console.error('[CommunityDetection] getDetectionsForAsset error:', err);
    error(res, 'Failed to fetch community detections', 500);
  }
};

module.exports = { 
  submitScan, 
  submitScanValidators, 
  submitCommunityDetection, 
  submitCommunityDetectionValidators,
  getDetectionsForAsset 
};
