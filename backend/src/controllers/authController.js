const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { body } = require('express-validator');
const User = require('../models/User');
const { signToken } = require('../services/tokenService');
const { sendVerificationEmail, sendResendVerificationEmail, sendPasswordResetEmail } = require('../services/emailService');
const { success, error } = require('../utils/response');

// ── Constants ──────────────────────────────────────────────────────────────
const VERIFICATION_TOKEN_BYTES = 32;
const VERIFICATION_EXPIRES_MS  = 24 * 60 * 60 * 1000; // 24 hours
const RESET_TOKEN_BYTES        = 32;
const RESET_EXPIRES_MS         = 15 * 60 * 1000;       // 15 minutes
const BCRYPT_ROUNDS_TOKEN      = 10;

// ── Helpers ────────────────────────────────────────────────────────────────

/** Generate a cryptographically random URL-safe token and its bcrypt hash. */
const generateVerificationToken = async () => {
  const rawToken = crypto.randomBytes(VERIFICATION_TOKEN_BYTES).toString('hex');
  const tokenHash = await bcrypt.hash(rawToken, BCRYPT_ROUNDS_TOKEN);
  return { rawToken, tokenHash };
};

// ── Validation chains ──────────────────────────────────────────────────────

const registerValidators = [
  body('name').trim().notEmpty().withMessage('Name is required')
    .isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('email').trim().isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

const loginValidators = [
  body('email').trim().isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

// ── Handlers ───────────────────────────────────────────────────────────────

/**
 * POST /api/auth/register
 * Creates account, sends verification email (if enabled).
 * Returns 201 with a message or JWT depending on EMAIL_VERIFICATION_ENABLED.
 * 
 * DEVELOPMENT MODE (EMAIL_VERIFICATION_ENABLED=false):
 *   - Account created with emailVerified=true
 *   - No email sent
 *   - JWT returned immediately
 * 
 * PRODUCTION MODE (EMAIL_VERIFICATION_ENABLED=true):
 *   - Account created with emailVerified=false
 *   - Verification email sent
 *   - User must verify email before login
 */
const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const existing = await User.findOne({ email });
    if (existing) {
      return error(res, 'An account with this email already exists', 409);
    }

    // Check if email verification is enabled
    const emailVerificationEnabled = process.env.EMAIL_VERIFICATION_ENABLED !== 'false';

    let user;
    let token = null;

    if (emailVerificationEnabled) {
      // PRODUCTION MODE: Email verification required
      console.log('[Auth] Email verification ENABLED — sending verification email');
      
      const { rawToken, tokenHash } = await generateVerificationToken();

      user = await User.create({
        name,
        email,
        passwordHash: password,
        emailVerified: false,
        verificationTokenHash: tokenHash,
        verificationTokenExpires: new Date(Date.now() + VERIFICATION_EXPIRES_MS),
      });

      // Send verification email — non-fatal: account is created regardless
      try {
        await sendVerificationEmail(user.email, user.name, rawToken);
      } catch (emailErr) {
        console.error('Verification email failed to send:', emailErr.message);
        // Continue — user can request a resend
      }

      success(res, {
        message: 'Account created. Please check your email to verify your account.',
        emailSent: true,
      }, 201);
    } else {
      // DEVELOPMENT MODE: Email verification disabled
      console.log('⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.');
      
      user = await User.create({
        name,
        email,
        passwordHash: password,
        emailVerified: true, // ← Automatically verified in dev mode
      });

      // Issue JWT immediately so user can login
      token = signToken(user._id);

      console.log(`✓ [Auth] User ${email} registered and auto-verified (development mode)`);

      success(res, {
        message: 'Account created successfully. You can now sign in.',
        token,
        user: user.toJSON(),
        devMode: true, // Signal to client that email verification was bypassed
      }, 201);
    }
  } catch (err) {
    console.error('register error:', err);
    error(res, 'Registration failed — please try again', 500);
  }
};

/**
 * GET /api/auth/verify-email?token=<rawToken>
 * Validates token, marks email as verified, invalidates token.
 */
const verifyEmail = async (req, res) => {
  try {
    const { token: rawToken } = req.query;

    if (!rawToken || typeof rawToken !== 'string') {
      return error(res, 'Verification token is required', 400);
    }

    // Find users with a non-expired token (we must check against hash)
    // We query by expiry first to narrow the candidate set efficiently
    const candidates = await User.find({
      emailVerified: false,
      verificationTokenExpires: { $gt: new Date() },
    }).select('+verificationTokenHash +verificationTokenExpires');

    let matchedUser = null;
    for (const candidate of candidates) {
      const matches = await candidate.compareVerificationToken(rawToken);
      if (matches) {
        matchedUser = candidate;
        break;
      }
    }

    if (!matchedUser) {
      // Check if there's an expired token to give a better message
      const expiredCandidates = await User.find({
        emailVerified: false,
        verificationTokenExpires: { $lte: new Date() },
      }).select('+verificationTokenHash');

      for (const candidate of expiredCandidates) {
        const matches = await candidate.compareVerificationToken(rawToken);
        if (matches) {
          return error(res, 'Verification link has expired. Please request a new one.', 410);
        }
      }

      return error(res, 'Invalid or already-used verification token', 400);
    }

    // Mark verified and clear the token
    matchedUser.emailVerified = true;
    matchedUser.verificationTokenHash = undefined;
    matchedUser.verificationTokenExpires = undefined;
    await matchedUser.save();

    // Issue JWT so the user is immediately logged in after verifying
    const jwtToken = signToken(matchedUser._id);

    success(res, {
      message: 'Email verified successfully. Welcome to AssetGuard AI!',
      token: jwtToken,
      user: matchedUser.toJSON(),
    });
  } catch (err) {
    console.error('verifyEmail error:', err);
    error(res, 'Verification failed — please try again', 500);
  }
};

/**
 * POST /api/auth/resend-verification
 * Issues a new token and resends the email for unverified accounts.
 */
const resendVerification = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return error(res, 'Email address is required', 400);
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() })
      .select('+verificationTokenHash +verificationTokenExpires');

    // Always respond the same way whether the user exists or not (anti-enumeration)
    if (!user) {
      return success(res, {
        message: 'If that email is registered and unverified, a new link has been sent.',
      });
    }

    if (user.emailVerified) {
      return error(res, 'This email address is already verified', 409);
    }

    const { rawToken, tokenHash } = await generateVerificationToken();
    user.verificationTokenHash = tokenHash;
    user.verificationTokenExpires = new Date(Date.now() + VERIFICATION_EXPIRES_MS);
    await user.save();

    try {
      await sendResendVerificationEmail(user.email, user.name, rawToken);
    } catch (emailErr) {
      console.error('Resend verification email failed:', emailErr.message);
      return error(res, 'Failed to send email — please try again shortly', 500);
    }

    success(res, {
      message: 'A new verification email has been sent.',
    });
  } catch (err) {
    console.error('resendVerification error:', err);
    error(res, 'Could not resend verification email — please try again', 500);
  }
};

/**
 * POST /api/auth/login
 * Requires emailVerified=true (unless EMAIL_VERIFICATION_ENABLED=false).
 * 
 * DEVELOPMENT MODE (EMAIL_VERIFICATION_ENABLED=false):
 *   - Allows login even if emailVerified=false
 *   - Logs warning about development mode
 * 
 * PRODUCTION MODE (EMAIL_VERIFICATION_ENABLED=true):
 *   - Requires emailVerified=true
 *   - Rejects unverified users with 403
 */
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select('+passwordHash');
    if (!user) {
      return error(res, 'Invalid email or password', 401);
    }

    const match = await user.comparePassword(password);
    if (!match) {
      return error(res, 'Invalid email or password', 401);
    }

    // Check if email verification is enabled
    const emailVerificationEnabled = process.env.EMAIL_VERIFICATION_ENABLED !== 'false';

    if (emailVerificationEnabled && !user.emailVerified) {
      // PRODUCTION MODE: Reject unverified users
      return error(
        res,
        'Please verify your email address before logging in. Check your inbox or request a new link.',
        403
      );
    }

    if (!emailVerificationEnabled && !user.emailVerified) {
      // DEVELOPMENT MODE: Allow unverified users
      console.log(`⚠️  [Auth] Email verification DISABLED — allowing unverified user ${email} to login (development mode)`);
    }

    const token = signToken(user._id);
    const userObj = user.toJSON();
    success(res, { token, user: userObj });
  } catch (err) {
    console.error('login error:', err);
    error(res, 'Login failed — please try again', 500);
  }
};

/**
 * GET /api/auth/me
 */
const getMe = async (req, res) => {
  success(res, { user: req.user });
};

const forgotPasswordValidators = [
  body('email').trim().isEmail().withMessage('Valid email is required').normalizeEmail(),
];

const resetPasswordValidators = [
  body('token').trim().notEmpty().withMessage('Reset token is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

/**
 * POST /api/auth/forgot-password
 * Always returns a generic 200. Prevents email enumeration.
 * If the account exists and is verified, generates a 15-min reset token and emails it.
 */
const forgotPassword = async (req, res) => {
  // Generic message sent regardless of whether the account exists
  const GENERIC_MSG = 'If an account with that email exists, a password-reset link has been sent.';

  try {
    const { email } = req.body;

    const user = await User.findOne({ email });

    if (!user || !user.emailVerified) {
      // Respond generically — do not reveal account existence
      return success(res, { message: GENERIC_MSG });
    }

    const rawToken  = crypto.randomBytes(RESET_TOKEN_BYTES).toString('hex');
    const tokenHash = await bcrypt.hash(rawToken, BCRYPT_ROUNDS_TOKEN);

    // Invalidate any previous reset token and set the new one
    user.resetPasswordTokenHash    = tokenHash;
    user.resetPasswordTokenExpires = new Date(Date.now() + RESET_EXPIRES_MS);
    await user.save();

    try {
      await sendPasswordResetEmail(user.email, user.name, rawToken);
    } catch (emailErr) {
      console.error('Password reset email failed to send:', emailErr.message);
      // Still return generic response — don't leak internal errors
    }

    success(res, { message: GENERIC_MSG });
  } catch (err) {
    console.error('forgotPassword error:', err);
    error(res, 'Could not process request — please try again', 500);
  }
};

/**
 * POST /api/auth/reset-password
 * Validates token, updates password, invalidates token.
 * Does NOT log the user in automatically.
 */
const resetPassword = async (req, res) => {
  try {
    const { token: rawToken, password } = req.body;

    // Find candidates with a non-expired reset token
    const candidates = await User.find({
      resetPasswordTokenExpires: { $gt: new Date() },
    }).select('+resetPasswordTokenHash +resetPasswordTokenExpires');

    let matchedUser = null;
    for (const candidate of candidates) {
      const matches = await candidate.compareResetToken(rawToken);
      if (matches) {
        matchedUser = candidate;
        break;
      }
    }

    if (!matchedUser) {
      // Check if there is an expired token to give a better message
      const expiredCandidates = await User.find({
        resetPasswordTokenExpires: { $lte: new Date() },
        resetPasswordTokenHash: { $exists: true, $ne: null },
      }).select('+resetPasswordTokenHash');

      for (const candidate of expiredCandidates) {
        const matches = await candidate.compareResetToken(rawToken);
        if (matches) {
          return error(res, 'Password-reset link has expired. Please request a new one.', 410);
        }
      }

      return error(res, 'Invalid or already-used reset token', 400);
    }

    // Update the password — the pre-save hook will hash it
    matchedUser.passwordHash             = password;
    matchedUser.resetPasswordTokenHash   = undefined;
    matchedUser.resetPasswordTokenExpires = undefined;
    await matchedUser.save();

    success(res, { message: 'Password reset successfully. Please sign in with your new password.' });
  } catch (err) {
    console.error('resetPassword error:', err);
    error(res, 'Password reset failed — please try again', 500);
  }
};

module.exports = {
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
};
