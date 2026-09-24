const express = require('express');
const {
  register,
  login,
  getMe,
  verifyEmail,
  resendVerification,
  forgotPassword,
  resetPassword,
  registerValidators,
  loginValidators,
  forgotPasswordValidators,
  resetPasswordValidators,
} = require('../controllers/authController');
const { validate } = require('../middleware/validate');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.post('/register',              registerValidators,       validate, register);
router.post('/login',                 loginValidators,          validate, login);
router.get('/me',                     protect,                           getMe);
router.get('/verify-email',                                              verifyEmail);
router.post('/resend-verification',                                      resendVerification);
router.post('/forgot-password',       forgotPasswordValidators, validate, forgotPassword);
router.post('/reset-password',        resetPasswordValidators,  validate, resetPassword);

module.exports = router;
