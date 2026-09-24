const mongoose = require('mongoose');

const ASSET_STATUSES = ['ACTIVE', 'LOST', 'RECOVERED'];

const assetSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Asset name is required'],
      trim: true,
      maxlength: [100, 'Asset name must not exceed 100 characters'],
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      trim: true,
      maxlength: [50, 'Category must not exceed 50 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, 'Description must not exceed 500 characters'],
      default: '',
    },
    trackerId: {
      type: String,
      required: [true, 'Tracker ID is required'],
      trim: true,
      maxlength: [50, 'Tracker ID must not exceed 50 characters'],
    },
    status: {
      type: String,
      enum: {
        values: ASSET_STATUSES,
        message: 'Status must be ACTIVE, LOST, or RECOVERED',
      },
      default: 'ACTIVE',
    },
    // BLE tracking will populate these fields in Phase 3
    lastDetectedLocation: {
      type: String,
      default: null,
    },
    lastDetectedTime: {
      type: Date,
      default: null,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index: per-user tracker IDs must be unique
assetSchema.index({ userId: 1, trackerId: 1 }, { unique: true });

module.exports = mongoose.model('Asset', assetSchema);
module.exports.ASSET_STATUSES = ASSET_STATUSES;
