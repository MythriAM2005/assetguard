const Asset = require('../models/Asset');
const CommunityDetection = require('../models/CommunityDetection');
const { success, error } = require('../utils/response');
const { ACTIVE_TRACKING_WINDOW_MS } = require('../config/constants');

/**
 * GET /api/dashboard/stats
 * 
 * Returns dashboard statistics for the authenticated user:
 * - totalAssets: All assets owned by the user
 * - lostAssets: Assets currently marked as LOST
 * - activeTrackingAssets: LOST assets with recent community detections
 * 
 * "Recent" is defined by ACTIVE_TRACKING_WINDOW_MS (default: 2 minutes)
 */
const getDashboardStats = async (req, res) => {
  try {
    const userId = req.user._id;

    // Get all user's assets
    const allAssets = await Asset.find({ userId });
    const totalAssets = allAssets.length;

    // Get LOST assets
    const lostAssets = allAssets.filter(a => a.status === 'LOST');
    const lostCount = lostAssets.length;

    // Calculate active tracking count
    // (LOST assets with community detections within the tracking window)
    let activeTrackingCount = 0;

    if (lostCount > 0) {
      const cutoffTime = new Date(Date.now() - ACTIVE_TRACKING_WINDOW_MS);
      const lostAssetIds = lostAssets.map(a => a._id);

      // Find which LOST assets have recent detections
      const recentDetections = await CommunityDetection.aggregate([
        {
          $match: {
            assetId: { $in: lostAssetIds },
            detectedAt: { $gte: cutoffTime },
          },
        },
        {
          $group: {
            _id: '$assetId',
          },
        },
      ]);

      activeTrackingCount = recentDetections.length;
    }

    console.log('[Dashboard] Stats calculated for user:', req.user.email);
    console.log('[Dashboard]   totalAssets          :', totalAssets);
    console.log('[Dashboard]   lostAssets           :', lostCount);
    console.log('[Dashboard]   activeTrackingAssets :', activeTrackingCount);
    console.log('[Dashboard]   tracking window      :', ACTIVE_TRACKING_WINDOW_MS / 1000, 'seconds');

    success(res, {
      totalAssets,
      lostAssets: lostCount,
      activeTrackingAssets: activeTrackingCount,
    });
  } catch (err) {
    console.error('[Dashboard] getDashboardStats error:', err);
    error(res, 'Failed to fetch dashboard statistics', 500);
  }
};

module.exports = {
  getDashboardStats,
};
