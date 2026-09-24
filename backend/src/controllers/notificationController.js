const Notification = require('../models/Notification');
const { success, error } = require('../utils/response');

/**
 * GET /api/notifications
 *
 * Fetch notifications for the authenticated user.
 * Returns unread notifications first, then read notifications.
 *
 * Query parameters:
 * - unreadOnly: true/false (default: false)
 * - limit: number (default: 50, max: 100)
 *
 * Response:
 * {
 *   "success": true,
 *   "notifications": [...],
 *   "unreadCount": 3
 * }
 */
const getNotifications = async (req, res) => {
  try {
    const unreadOnly = req.query.unreadOnly === 'true';
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);

    console.log('[Notification] User fetching notifications:', req.user.email);
    console.log('[Notification]   unreadOnly:', unreadOnly);
    console.log('[Notification]   limit:', limit);

    const query = { recipient: req.user._id };
    if (unreadOnly) {
      query.read = false;
    }

    const notifications = await Notification.find(query)
      .sort({ read: 1, createdAt: -1 }) // unread first, then newest first
      .limit(limit)
      .lean();

    const unreadCount = await Notification.countDocuments({
      recipient: req.user._id,
      read: false,
    });

    console.log('[Notification] Returning', notifications.length, 'notifications,', unreadCount, 'unread');

    success(res, {
      notifications,
      unreadCount,
    });
  } catch (err) {
    console.error('[Notification] getNotifications error:', err);
    error(res, 'Failed to fetch notifications', 500);
  }
};

/**
 * GET /api/notifications/unread/count
 *
 * Get count of unread notifications (lightweight endpoint for badge).
 *
 * Response:
 * {
 *   "success": true,
 *   "count": 3
 * }
 */
const getUnreadCount = async (req, res) => {
  try {
    console.log('[Notification] User polling for unread count:', req.user.email);
    
    const count = await Notification.countDocuments({
      recipient: req.user._id,
      read: false,
    });

    console.log('[Notification] Unread count for', req.user.email, ':', count);
    success(res, { count });
  } catch (err) {
    console.error('[Notification] getUnreadCount error:', err);
    error(res, 'Failed to get unread count', 500);
  }
};

/**
 * PUT /api/notifications/:id/read
 *
 * Mark a notification as read.
 *
 * Response:
 * {
 *   "success": true,
 *   "message": "Notification marked as read"
 * }
 */
const markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      {
        _id: req.params.id,
        recipient: req.user._id, // SECURITY: only owner can mark as read
      },
      { read: true },
      { new: true }
    );

    if (!notification) {
      return error(res, 'Notification not found', 404);
    }

    success(res, { message: 'Notification marked as read' });
  } catch (err) {
    console.error('[Notification] markAsRead error:', err);
    error(res, 'Failed to mark notification as read', 500);
  }
};

/**
 * PUT /api/notifications/read-all
 *
 * Mark all notifications as read for the authenticated user.
 *
 * Response:
 * {
 *   "success": true,
 *   "message": "All notifications marked as read",
 *   "count": 5
 * }
 */
const markAllAsRead = async (req, res) => {
  try {
    const result = await Notification.updateMany(
      {
        recipient: req.user._id,
        read: false,
      },
      { read: true }
    );

    success(res, {
      message: 'All notifications marked as read',
      count: result.modifiedCount,
    });
  } catch (err) {
    console.error('[Notification] markAllAsRead error:', err);
    error(res, 'Failed to mark all notifications as read', 500);
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
};
