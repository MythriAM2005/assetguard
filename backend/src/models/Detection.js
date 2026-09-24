const mongoose = require('mongoose');

const POSITION_METHODS = ['GPS', 'WIFI', 'HYBRID', 'BLE_ONLY'];

const wifiApSchema = new mongoose.Schema(
  {
    bssid: { type: String, required: true, trim: true },
    rssi:  { type: Number, required: true },
  },
  { _id: false }
);

const gpsSchema = new mongoose.Schema(
  {
    latitude:  { type: Number, required: true },
    longitude: { type: Number, required: true },
    accuracy:  { type: Number, required: true }, // metres
  },
  { _id: false }
);

const positionSchema = new mongoose.Schema(
  {
    latitude:  { type: Number },
    longitude: { type: Number },
    accuracy:  { type: Number },
    method: {
      type: String,
      enum: POSITION_METHODS,
      required: true,
    },
  },
  { _id: false }
);

const detectionSchema = new mongoose.Schema(
  {
    trackerId: {
      type: String,
      required: [true, 'trackerId is required'],
      trim: true,
    },
    assetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Asset',
      required: true,
      index: true,
    },
    // The user whose phone performed the scan.
    // In Phase 3B this is always the asset owner.
    // Phase 4B will extend to community reporters.
    detectedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    bleRssi: {
      type: Number,
      required: [true, 'bleRssi is required'],
    },
    // Raw GPS from device — may be absent
    gps: {
      type: gpsSchema,
      default: null,
    },
    // Raw Wi-Fi fingerprint — may be empty
    wifiFingerprint: {
      type: [wifiApSchema],
      default: [],
    },
    // Server-resolved best position
    position: {
      type: positionSchema,
      required: true,
    },
    // ISO timestamp supplied by the device
    timestamp: {
      type: Date,
      required: [true, 'timestamp is required'],
    },
  },
  {
    timestamps: true, // createdAt / updatedAt
  }
);

// Index for querying an asset's detection history
detectionSchema.index({ assetId: 1, timestamp: -1 });

module.exports = mongoose.model('Detection', detectionSchema);
module.exports.POSITION_METHODS = POSITION_METHODS;
