const mongoose = require('mongoose');

/**
 * Community Detection schema.
 *
 * Records when a community user detects a LOST AssetGuard tracker.
 * Unlike regular detections (owner-only), these can be submitted by any
 * authenticated user and are only accepted if the asset is in LOST status.
 */
const communityDetectionSchema = new mongoose.Schema(
  {
    trackerId: {
      type: String,
      required: [true, 'Tracker ID is required'],
      trim: true,
      index: true,
    },
    assetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Asset',
      required: true,
      index: true,
    },
    detectedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    rssi: {
      type: Number,
      required: [true, 'RSSI is required'],
      min: -120,
      max: 0,
    },
    remoteId: {
      type: String,
      trim: true,
      default: null,
    },
    detectedAt: {
      type: Date,
      required: true,
      index: true,
    },
    // Detector's GPS location (optional)
    latitude: {
      type: Number,
      min: -90,
      max: 90,
      default: null,
    },
    longitude: {
      type: Number,
      min: -180,
      max: 180,
      default: null,
    },
    // ML room prediction (optional)
    predictedRoom: {
      type: String,
      trim: true,
      default: null,
    },
    roomConfidence: {
      type: Number,
      min: 0,
      max: 1,
      default: null,
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
  }
);

// Compound index for efficient queries by asset and time
communityDetectionSchema.index({ assetId: 1, detectedAt: -1 });

module.exports = mongoose.model('CommunityDetection', communityDetectionSchema);
