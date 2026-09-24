const mongoose = require('mongoose');

/**
 * In-App Notification schema.
 *
 * Stores notifications for users about their assets being detected,
 * status changes, and other events.
 */
const notificationSchema = new mongoose.Schema(
  {
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      required: true,
      enum: ['asset_detected', 'asset_status_changed', 'system'],
      index: true,
    },
    title: {
      type: String,
      required: true,
      maxlength: 100,
    },
    message: {
      type: String,
      required: true,
      maxlength: 500,
    },
    // Related entities
    assetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Asset',
      default: null,
    },
    detectionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CommunityDetection',
      default: null,
    },
    // Detection metadata (denormalized for quick display)
    trackerId: {
      type: String,
      default: null,
    },
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
    rssi: {
      type: Number,
      min: -120,
      max: 0,
      default: null,
    },
    detectedAt: {
      type: Date,
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
    // Notification state
    read: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
  }
);

// Compound index for efficient queries
notificationSchema.index({ recipient: 1, read: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
