const { validationResult } = require('express-validator');
const { error } = require('../utils/response');

/**
 * Run express-validator result check.
 * Attach after validator chains in routes.
 */
const validate = (req, res, next) => {
  const result = validationResult(req);
  if (!result.isEmpty()) {
    const errors = result.array().map((e) => ({ field: e.path, message: e.msg }));
    return error(res, 'Validation failed', 422, errors);
  }
  next();
};

module.exports = { validate };
