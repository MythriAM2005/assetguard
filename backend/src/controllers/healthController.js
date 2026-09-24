const mongoose = require('mongoose');
const { success } = require('../utils/response');

/**
 * GET /api/health
 * Returns API status and MongoDB connection state.
 */
const getHealth = (req, res) => {
  const dbState = mongoose.connection.readyState;
  // 0 = disconnected, 1 = connected, 2 = connecting, 3 = disconnecting
  const dbStatus = ['disconnected', 'connected', 'connecting', 'disconnecting'][dbState] || 'unknown';

  success(res, {
    message: 'AssetGuard API is running',
    database: dbStatus,
    timestamp: new Date().toISOString(),
  });
};

module.exports = { getHealth };
