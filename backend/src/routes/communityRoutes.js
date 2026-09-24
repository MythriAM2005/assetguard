const express = require('express');
const { 
  submitScan, 
  submitScanValidators,
  submitCommunityDetection,
  submitCommunityDetectionValidators,
  getDetectionsForAsset
} = require('../controllers/communityController');
const { protect } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// All community routes require a valid JWT
router.use(protect);

router.post('/scan', submitScanValidators, validate, submitScan);
router.post('/detections', submitCommunityDetectionValidators, validate, submitCommunityDetection);
router.get('/detections/asset/:assetId', getDetectionsForAsset);

module.exports = router;
