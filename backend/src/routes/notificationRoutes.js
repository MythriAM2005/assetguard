const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const notificationController = require('../controllers/notificationController');

// All routes require authentication
router.use(protect);

// GET /api/notifications - Get notifications for authenticated user
router.get('/', notificationController.getNotifications);

// GET /api/notifications/unread/count - Get unread count (for badge)
router.get('/unread/count', notificationController.getUnreadCount);

// PUT /api/notifications/:id/read - Mark notification as read
router.put('/:id/read', notificationController.markAsRead);

// PUT /api/notifications/read-all - Mark all as read
router.put('/read-all', notificationController.markAllAsRead);

module.exports = router;
