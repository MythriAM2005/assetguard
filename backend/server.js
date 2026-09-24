require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');

const PORT = process.env.PORT || 5000;

const start = async () => {
  await connectDB();

  // Bind to 0.0.0.0 to accept connections from all network interfaces
  // Required for cloud hosting (Render, Railway, etc.)
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀  AssetGuard API running on port ${PORT}`);
    console.log(`   Health check: /api/health`);
  });
};

start();
