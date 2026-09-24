const express = require('express');
const {
  getAssets,
  getAsset,
  createAsset,
  updateAsset,
  deleteAsset,
  markLost,
  markRecovered,
  createValidators,
  updateValidators,
} = require('../controllers/assetController');
const { protect } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// All asset routes require authentication
router.use(protect);

router.get('/', getAssets);
router.get('/:id', getAsset);
router.post('/', createValidators, validate, createAsset);
router.put('/:id', updateValidators, validate, updateAsset);
router.delete('/:id', deleteAsset);
router.patch('/:id/lost', markLost);
router.patch('/:id/recovered', markRecovered);

module.exports = router;
