/**
 * Application-wide constants and configuration values.
 */

/**
 * Time window (in milliseconds) for considering a LOST asset as "actively tracked".
 * 
 * A LOST asset counts as actively tracked if it has received a community detection
 * within this time window. Used for dashboard statistics.
 * 
 * Default: 2 minutes (120000 ms)
 */
const ACTIVE_TRACKING_WINDOW_MS = 2 * 60 * 1000; // 2 minutes

module.exports = {
  ACTIVE_TRACKING_WINDOW_MS,
};
