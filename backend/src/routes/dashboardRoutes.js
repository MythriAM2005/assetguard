const express = require('express');
const { getDashboardStats } = require('../controllers/dashboardController');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All dashboard routes require authentication
router.use(protect);

router.get('/stats', getDashboardStats);

module.exports = router;
