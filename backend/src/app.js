const express = require('express');
const cors = require('cors');

const healthRoutes     = require('./routes/healthRoutes');
const authRoutes       = require('./routes/authRoutes');
const assetRoutes      = require('./routes/assetRoutes');
const detectionRoutes  = require('./routes/detectionRoutes');
const locationRoutes   = require('./routes/locationRoutes');
const communityRoutes  = require('./routes/communityRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const dashboardRoutes  = require('./routes/dashboardRoutes');
const { error } = require('./utils/response');

const app = express();

// ── Middleware ─────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// ── Routes ─────────────────────────────────────────────────────────────────
app.use('/api/health',     healthRoutes);
app.use('/api/auth',       authRoutes);
app.use('/api/assets',     assetRoutes);
app.use('/api/detections', detectionRoutes);
app.use('/api/location',   locationRoutes);
app.use('/api/community',  communityRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/dashboard',  dashboardRoutes);

// ── 404 handler ────────────────────────────────────────────────────────────
app.use((req, res) => {
  error(res, `Route ${req.method} ${req.originalUrl} not found`, 404);
});

// ── Global error handler ───────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  error(res, 'Internal server error', 500);
});

module.exports = app;
