const jwt = require('jsonwebtoken');

/**
 * Sign a JWT for a given user id.
 * Expires in 30 days — long enough for a mobile app to stay logged in.
 */
const signToken = (userId) =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '30d' });

module.exports = { signToken };
