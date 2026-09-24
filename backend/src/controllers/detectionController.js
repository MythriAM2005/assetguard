const { body } = require('express-validator');
const Asset = require('../models/Asset');
const Detection = require('../models/Detection');
const { success, error } = require('../utils/response');

// ── Constants ──────────────────────────────────────────────────────────────

/**
 * GPS accuracy threshold in metres.
 * ≤ GPS_GOOD_THRESHOLD  → method = 'GPS'
 * ≤ GPS_FAIR_THRESHOLD  → method = 'HYBRID' (if Wi-Fi also available)
 * > GPS_FAIR_THRESHOLD  → GPS not used; method = 'WIFI' or 'BLE_ONLY'
 */
const GPS_GOOD_THRESHOLD = 30;  // metres
const GPS_FAIR_THRESHOLD = 80;  // metres
const MIN_WIFI_APS = 2;          // minimum APs for Wi-Fi to be considered

// ── Position method selection ──────────────────────────────────────────────

/**
 * Determine the best position method and normalised position from the raw
 * sensor data provided by the device.
 *
 * Returns { position } where position matches positionSchema.
 */
const resolvePosition = (gps, wifiFingerprint) => {
  const hasGoodGps  = gps && gps.accuracy <= GPS_GOOD_THRESHOLD;
  const hasFairGps  = gps && gps.accuracy <= GPS_FAIR_THRESHOLD;
  const hasWifi     = Array.isArray(wifiFingerprint) &&
                      wifiFingerprint.length >= MIN_WIFI_APS;

  if (hasGoodGps) {
    return {
      latitude:  gps.latitude,
      longitude: gps.longitude,
      accuracy:  gps.accuracy,
      method: 'GPS',
    };
  }

  if (hasFairGps && hasWifi) {
    // Both available but GPS isn't reliable — report as HYBRID
    // A future ML phase will weight these; for now we use the GPS coordinate
    return {
      latitude:  gps.latitude,
      longitude: gps.longitude,
      accuracy:  gps.accuracy,
      method: 'HYBRID',
    };
  }

  if (hasWifi && gps) {
    // GPS accuracy is poor but we have Wi-Fi; use GPS coords + label as WIFI
    return {
      latitude:  gps.latitude,
      longitude: gps.longitude,
      accuracy:  gps.accuracy,
      method: 'WIFI',
    };
  }

  if (hasWifi) {
    // No GPS at all, just Wi-Fi — no coordinate yet (triangulation is Phase 4C)
    return {
      latitude:  null,
      longitude: null,
      accuracy:  null,
      method: 'WIFI',
    };
  }

  // No reliable positioning — BLE confirms proximity only
  return {
    latitude:  gps ? gps.latitude  : null,
    longitude: gps ? gps.longitude : null,
    accuracy:  gps ? gps.accuracy  : null,
    method: 'BLE_ONLY',
  };
};

// ── Human-readable location string ────────────────────────────────────────

const buildLocationString = (position) => {
  if (!position.latitude || !position.longitude) {
    return `Detected via BLE (${position.method})`;
  }
  const lat = position.latitude.toFixed(5);
  const lng = position.longitude.toFixed(5);
  const acc = position.accuracy ? ` ±${Math.round(position.accuracy)}m` : '';
  return `${lat}, ${lng}${acc} (${position.method})`;
};

// ── Validation chains ──────────────────────────────────────────────────────

const createDetectionValidators = [
  body('trackerId')
    .trim().notEmpty().withMessage('trackerId is required'),
  body('bleRssi')
    .isInt({ min: -120, max: 0 })
    .withMessage('bleRssi must be an integer between -120 and 0'),
  body('timestamp')
    .isISO8601().withMessage('timestamp must be a valid ISO 8601 date string'),
  // GPS is optional but if provided all sub-fields are required
  body('gps.latitude')
    .optional().isFloat({ min: -90, max: 90 })
    .withMessage('gps.latitude must be between -90 and 90'),
  body('gps.longitude')
    .optional().isFloat({ min: -180, max: 180 })
    .withMessage('gps.longitude must be between -180 and 180'),
  body('gps.accuracy')
    .optional().isFloat({ min: 0 })
    .withMessage('gps.accuracy must be a non-negative number'),
  // wifiFingerprint is optional — validated as array of objects
  body('wifiFingerprint')
    .optional().isArray()
    .withMessage('wifiFingerprint must be an array'),
  body('wifiFingerprint.*.bssid')
    .optional().trim().notEmpty().withMessage('Each Wi-Fi entry must have a bssid'),
  body('wifiFingerprint.*.rssi')
    .optional().isInt({ min: -120, max: 0 })
    .withMessage('Each Wi-Fi entry rssi must be an integer between -120 and 0'),
];

// ── Handler ────────────────────────────────────────────────────────────────

/**
 * POST /api/detections
 *
 * Authenticated. The JWT identifies the scanner (always the asset owner in
 * Phase 3B). Looks up the Asset by trackerId scoped to req.user._id.
 *
 * Saves a Detection document and updates Asset.lastDetectedLocation /
 * Asset.lastDetectedTime atomically.
 */
const createDetection = async (req, res) => {
  try {
    const {
      trackerId,
      bleRssi,
      gps          = null,
      wifiFingerprint = [],
      timestamp,
    } = req.body;

    // Find the asset owned by this user with the given trackerId
    const asset = await Asset.findOne({
      trackerId: trackerId.trim(),
      userId: req.user._id,
    });

    if (!asset) {
      return error(
        res,
        `No asset found for trackerId "${trackerId}" in your account`,
        404
      );
    }

    // Resolve the best available position
    const position = resolvePosition(gps, wifiFingerprint);

    // Persist the detection record
    const detection = await Detection.create({
      trackerId:       asset.trackerId,
      assetId:         asset._id,
      detectedBy:      req.user._id,
      bleRssi,
      gps:             gps || null,
      wifiFingerprint: wifiFingerprint || [],
      position,
      timestamp:       new Date(timestamp),
    });

    // Update the asset's last-detected fields
    asset.lastDetectedLocation = buildLocationString(position);
    asset.lastDetectedTime     = new Date(timestamp);
    await asset.save();

    success(res, {
      detection: {
        _id:       detection._id,
        trackerId: detection.trackerId,
        assetId:   asset._id,
        assetName: asset.name,
        position,
        bleRssi,
        timestamp: detection.timestamp,
      },
    }, 201);
  } catch (err) {
    console.error('createDetection error:', err);
    error(res, 'Failed to record detection — please try again', 500);
  }
};

module.exports = { createDetection, createDetectionValidators };
