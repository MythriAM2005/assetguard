const { Resend } = require('resend');

let _resend = null;

const getResend = () => {
  if (!_resend) {
    const key = process.env.RESEND_API_KEY;
    if (!key) {
      throw new Error('RESEND_API_KEY is not configured in environment variables.');
    }
    _resend = new Resend(key);
  }
  return _resend;
};

/**
 * Wraps a Resend SDK call in a hard timeout.
 *
 * The Resend SDK has no built-in timeout. If the outbound HTTPS call to
 * api.resend.com stalls at the network layer (TLS hang, DNS delay, etc.),
 * the await never resolves and any Express handler waiting on it never sends
 * a response — causing Flutter's 15-second timeout to fire.
 *
 * This helper races the SDK call against a timer. If the SDK call does not
 * settle within timeoutMs, the returned promise rejects with a plain Error
 * that the existing controller try/catch can handle normally.
 *
 * @param {Promise} sdkPromise  - the promise returned by getResend().emails.send(...)
 * @param {number}  timeoutMs   - max wait in milliseconds (default 8 000)
 * @returns {Promise}           - resolves/rejects exactly like the SDK call, or
 *                                rejects with a timeout error if it takes too long
 */
const withEmailTimeout = (sdkPromise, timeoutMs = 8000) => {
  const timer = new Promise((_, reject) =>
    setTimeout(
      () => reject(new Error(`Email service timed out after ${timeoutMs}ms`)),
      timeoutMs
    )
  );
  return Promise.race([sdkPromise, timer]);
};

/**
 * Build the verification link.
 *
 * - Primary: custom URI scheme that opens the Flutter app directly.
 *   Format: assetguard://verify-email?token=<rawToken>
 *
 * - The token is never logged; only its length is safe to log.
 *
 * For production with a real HTTPS domain you would switch to an App Link
 * (https://yourdomain.com/verify-email?token=...) — change this one function.
 */
const buildVerificationLink = (rawToken) =>
  `assetguard://verify-email?token=${encodeURIComponent(rawToken)}`;

// ── Shared HTML template ───────────────────────────────────────────────────

const verificationHtml = (toName, link, isResend) => `
  <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 32px 24px; background: #f8faff;">
    <div style="background: linear-gradient(135deg, #0D47A1 0%, #1A73E8 100%); border-radius: 16px; padding: 28px 24px; text-align: center; margin-bottom: 28px;">
      <h1 style="color: #ffffff; font-size: 22px; margin: 0 0 6px;">AssetGuard AI</h1>
      <p style="color: rgba(255,255,255,0.8); font-size: 13px; margin: 0;">Smart Asset Tracking &amp; Recovery</p>
    </div>

    <div style="background: #ffffff; border-radius: 12px; padding: 28px 24px; border: 1px solid #E8EDF5;">
      <h2 style="color: #1A1A2E; font-size: 18px; margin: 0 0 12px;">Hi ${toName},</h2>
      <p style="color: #4B5563; font-size: 14px; line-height: 1.6; margin: 0 0 24px;">
        ${
          isResend
            ? 'Here is your new email verification link for AssetGuard AI. The previous link has been invalidated.'
            : 'Thanks for registering with AssetGuard AI! Please verify your email address to activate your account.'
        }
      </p>

      <div style="text-align: center; margin: 0 0 24px;">
        <a href="${link}"
           style="display: inline-block; background: #1A73E8; color: #ffffff; font-size: 15px; font-weight: 600; text-decoration: none; padding: 14px 32px; border-radius: 10px;">
          Verify My Email
        </a>
      </div>

      <p style="color: #6B7280; font-size: 12px; line-height: 1.6; margin: 0 0 8px;">
        This link expires in <strong>24 hours</strong>.
        ${isResend ? '' : "If you did not create an account, you can safely ignore this email."}
      </p>
      <p style="color: #9CA3AF; font-size: 11px; word-break: break-all; margin: 0;">
        Open this link on your phone to verify inside the AssetGuard app:<br/>
        <a href="${link}" style="color: #1A73E8;">${link}</a>
      </p>
    </div>

    <p style="color: #D1D5DB; font-size: 11px; text-align: center; margin: 20px 0 0;">
      AssetGuard AI — Final Year Engineering Project
    </p>
  </div>
`;

// ── Public functions ───────────────────────────────────────────────────────

/**
 * Send initial verification email after registration.
 */
const sendVerificationEmail = async (toEmail, toName, rawToken) => {
  const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
  const link = buildVerificationLink(rawToken);

  const { error } = await withEmailTimeout(
    getResend().emails.send({
      from: `AssetGuard AI <${fromEmail}>`,
      to: [toEmail],
      subject: 'Verify your AssetGuard AI account',
      html: verificationHtml(toName, link, false),
    })
  );

  if (error) {
    throw new Error(`Failed to send verification email: ${error.message}`);
  }
};

/**
 * Send a new verification email when the user requests a resend.
 * Invalidates the old token (done by the controller before calling this).
 */
const sendResendVerificationEmail = async (toEmail, toName, rawToken) => {
  const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
  const link = buildVerificationLink(rawToken);

  const { error } = await withEmailTimeout(
    getResend().emails.send({
      from: `AssetGuard AI <${fromEmail}>`,
      to: [toEmail],
      subject: 'New verification link — AssetGuard AI',
      html: verificationHtml(toName, link, true),
    })
  );

  if (error) {
    throw new Error(`Failed to send verification email: ${error.message}`);
  }
};

/**
 * Send a password-reset email.
 * Uses the same deep-link scheme so tapping opens the Flutter app.
 */
const sendPasswordResetEmail = async (toEmail, toName, rawToken) => {
  const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
  const link = `assetguard://reset-password?token=${encodeURIComponent(rawToken)}`;

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 32px 24px; background: #f8faff;">
      <div style="background: linear-gradient(135deg, #0D47A1 0%, #1A73E8 100%); border-radius: 16px; padding: 28px 24px; text-align: center; margin-bottom: 28px;">
        <h1 style="color: #ffffff; font-size: 22px; margin: 0 0 6px;">AssetGuard AI</h1>
        <p style="color: rgba(255,255,255,0.8); font-size: 13px; margin: 0;">Smart Asset Tracking &amp; Recovery</p>
      </div>

      <div style="background: #ffffff; border-radius: 12px; padding: 28px 24px; border: 1px solid #E8EDF5;">
        <h2 style="color: #1A1A2E; font-size: 18px; margin: 0 0 12px;">Hi ${toName},</h2>
        <p style="color: #4B5563; font-size: 14px; line-height: 1.6; margin: 0 0 24px;">
          We received a request to reset your AssetGuard AI password.
          Tap the button below on your phone to set a new password.
        </p>

        <div style="text-align: center; margin: 0 0 24px;">
          <a href="${link}"
             style="display: inline-block; background: #1A73E8; color: #ffffff; font-size: 15px; font-weight: 600; text-decoration: none; padding: 14px 32px; border-radius: 10px;">
            Reset My Password
          </a>
        </div>

        <p style="color: #6B7280; font-size: 12px; line-height: 1.6; margin: 0 0 8px;">
          This link expires in <strong>15 minutes</strong>.
          If you did not request a password reset, you can safely ignore this email — your password will not change.
        </p>
        <p style="color: #9CA3AF; font-size: 11px; word-break: break-all; margin: 0;">
          Open this link on your phone:<br/>
          <a href="${link}" style="color: #1A73E8;">${link}</a>
        </p>
      </div>

      <p style="color: #D1D5DB; font-size: 11px; text-align: center; margin: 20px 0 0;">
        AssetGuard AI — Final Year Engineering Project
      </p>
    </div>
  `;

  const { error } = await withEmailTimeout(
    getResend().emails.send({
      from: `AssetGuard AI <${fromEmail}>`,
      to: [toEmail],
      subject: 'Reset your AssetGuard AI password',
      html,
    })
  );

  if (error) {
    throw new Error(`Failed to send password-reset email: ${error.message}`);
  }
};

module.exports = { sendVerificationEmail, sendResendVerificationEmail, sendPasswordResetEmail };
