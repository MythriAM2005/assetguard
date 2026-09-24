const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { error } = require('../utils/response');

/**
 * Protect routes — verifies Bearer JWT and attaches req.user.
 * The userId is always taken from the verified token, never from the client body.
 */
const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return error(res, 'Not authorised — no token provided', 401);
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Fetch user (exclude passwordHash)
    const user = await User.findById(decoded.id);
    if (!user) {
      return error(res, 'Not authorised — user not found', 401);
    }

    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return error(res, 'Session expired — please log in again', 401);
    }
    return error(res, 'Not authorised — invalid token', 401);
  }
};

module.exports = { protect };
