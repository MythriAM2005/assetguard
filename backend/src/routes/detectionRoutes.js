const express = require('express');
const { createDetection, createDetectionValidators } = require('../controllers/detectionController');
const { protect } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// All detection routes require authentication
router.use(protect);

router.post('/', createDetectionValidators, validate, createDetection);

module.exports = router;
