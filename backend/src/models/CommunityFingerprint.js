const mongoose = require('mongoose');

/**
 * Stores a single Wi-Fi fingerprint scan contributed by a community user.
 *
 * Kept in a separate collection from Detection so community data
 * never pollutes per-asset detection history.
 * No trackerId or asset reference — this is raw environmental data.
 */
const wifiApSchema = new mongoose.Schema(
  {
    bssid: { type: String, required: true, trim: true },
    rssi:  { type: Number, required: true },
  },
  { _id: false }
);

const communityFingerprintSchema = new mongoose.Schema(
  {
    // The user whose phone performed the scan (from JWT — never from request body)
    scannedBy: {
      type:     mongoose.Schema.Types.ObjectId,
      ref:      'User',
      required: true,
      index:    true,
    },
    // Raw Wi-Fi access points observed at scan time
    wifiFingerprint: {
      type:     [wifiApSchema],
      required: true,
      validate: {
        validator: (arr) => Array.isArray(arr) && arr.length > 0,
        message:   'wifiFingerprint must contain at least one access point',
      },
    },
    // Device-supplied timestamp (ISO 8601); defaults to server receive time
    timestamp: {
      type:    Date,
      default: () => new Date(),
      index:   true,
    },
  },
  {
    timestamps: true, // createdAt / updatedAt
  }
);

// Index for querying recent community scans efficiently
communityFingerprintSchema.index({ timestamp: -1 });

module.exports = mongoose.model('CommunityFingerprint', communityFingerprintSchema);
