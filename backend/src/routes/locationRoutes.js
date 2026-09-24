const express = require('express');
const { predictRoom, predictRoomValidators } = require('../controllers/locationController');
const { protect } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// Requires a valid JWT so anonymous callers cannot use the ML API via this proxy
router.use(protect);

router.post('/predict-room', predictRoomValidators, validate, predictRoom);

module.exports = router;
