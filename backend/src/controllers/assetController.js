const { body } = require('express-validator');
const Asset = require('../models/Asset');
const { success, error } = require('../utils/response');

// ── Validation chains ──────────────────────────────────────────────────────

const createValidators = [
  body('name').trim().notEmpty().withMessage('Asset name is required')
    .isLength({ max: 100 }).withMessage('Asset name must not exceed 100 characters'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('trackerId').trim().notEmpty().withMessage('Tracker ID is required'),
  body('description').optional().isLength({ max: 500 }),
];

const updateValidators = [
  body('name').optional().trim().notEmpty().withMessage('Asset name cannot be empty')
    .isLength({ max: 100 }),
  body('category').optional().trim().notEmpty(),
  body('trackerId').optional().trim().notEmpty(),
  body('description').optional().isLength({ max: 500 }),
  body('status').optional().isIn(['ACTIVE', 'LOST', 'RECOVERED'])
    .withMessage('Status must be ACTIVE, LOST, or RECOVERED'),
];

// ── Helpers ────────────────────────────────────────────────────────────────

/** Find an asset that belongs to the authenticated user. Returns null and sends 404 if missing. */
const findOwnedAsset = async (req, res) => {
  const asset = await Asset.findOne({ _id: req.params.id, userId: req.user._id });
  if (!asset) {
    error(res, 'Asset not found', 404);
    return null;
  }
  return asset;
};

// ── Handlers ───────────────────────────────────────────────────────────────

/** GET /api/assets */
const getAssets = async (req, res) => {
  try {
    const assets = await Asset.find({ userId: req.user._id }).sort({ createdAt: -1 });
    success(res, { assets, total: assets.length });
  } catch (err) {
    console.error('getAssets error:', err);
    error(res, 'Failed to fetch assets', 500);
  }
};

/** GET /api/assets/:id */
const getAsset = async (req, res) => {
  try {
    const asset = await findOwnedAsset(req, res);
    if (!asset) return;
    success(res, { asset });
  } catch (err) {
    console.error('getAsset error:', err);
    error(res, 'Failed to fetch asset', 500);
  }
};

/** POST /api/assets */
const createAsset = async (req, res) => {
  try {
    const { name, category, description, trackerId } = req.body;

    // Check for duplicate trackerId within the same user's assets
    const duplicate = await Asset.findOne({ userId: req.user._id, trackerId });
    if (duplicate) {
      return error(res, `Tracker ID "${trackerId}" is already assigned to another asset`, 409);
    }

    const asset = await Asset.create({
      name,
      category,
      description: description || '',
      trackerId,
      status: 'ACTIVE',
      userId: req.user._id,
    });

    success(res, { asset }, 201);
  } catch (err) {
    console.error('createAsset error:', err);
    error(res, 'Failed to create asset', 500);
  }
};

/** PUT /api/assets/:id */
const updateAsset = async (req, res) => {
  try {
    const asset = await findOwnedAsset(req, res);
    if (!asset) return;

    const { name, category, description, trackerId, status } = req.body;

    // If changing trackerId, check for duplicates (excluding this asset)
    if (trackerId && trackerId !== asset.trackerId) {
      const dup = await Asset.findOne({
        userId: req.user._id,
        trackerId,
        _id: { $ne: asset._id },
      });
      if (dup) {
        return error(res, `Tracker ID "${trackerId}" is already in use`, 409);
      }
    }

    if (name !== undefined) asset.name = name;
    if (category !== undefined) asset.category = category;
    if (description !== undefined) asset.description = description;
    if (trackerId !== undefined) asset.trackerId = trackerId;
    if (status !== undefined) asset.status = status;

    await asset.save();
    success(res, { asset });
  } catch (err) {
    console.error('updateAsset error:', err);
    error(res, 'Failed to update asset', 500);
  }
};

/** DELETE /api/assets/:id */
const deleteAsset = async (req, res) => {
  try {
    const asset = await findOwnedAsset(req, res);
    if (!asset) return;
    await asset.deleteOne();
    success(res, { message: 'Asset deleted successfully' });
  } catch (err) {
    console.error('deleteAsset error:', err);
    error(res, 'Failed to delete asset', 500);
  }
};

/** PATCH /api/assets/:id/lost */
const markLost = async (req, res) => {
  try {
    const asset = await findOwnedAsset(req, res);
    if (!asset) return;
    asset.status = 'LOST';
    await asset.save();
    success(res, { asset });
  } catch (err) {
    console.error('markLost error:', err);
    error(res, 'Failed to update asset status', 500);
  }
};

/** PATCH /api/assets/:id/recovered */
const markRecovered = async (req, res) => {
  try {
    const asset = await findOwnedAsset(req, res);
    if (!asset) return;
    asset.status = 'RECOVERED';
    await asset.save();
    success(res, { asset });
  } catch (err) {
    console.error('markRecovered error:', err);
    error(res, 'Failed to update asset status', 500);
  }
};

module.exports = {
  getAssets,
  getAsset,
  createAsset,
  updateAsset,
  deleteAsset,
  markLost,
  markRecovered,
  createValidators,
  updateValidators,
};
