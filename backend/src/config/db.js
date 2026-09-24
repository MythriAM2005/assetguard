const mongoose = require('mongoose');

/**
 * Connect to MongoDB Atlas using MONGODB_URI from environment.
 * Logs success or failure clearly on startup.
 */
const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    console.error('❌  MONGODB_URI is not set in .env — database connection skipped.');
    return;
  }

  try {
    const conn = await mongoose.connect(uri, {
      dbName: 'assetguard',
    });
    console.log(`✅  MongoDB Atlas connected: ${conn.connection.host}`);
  } catch (err) {
    console.error(`❌  MongoDB connection failed: ${err.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
