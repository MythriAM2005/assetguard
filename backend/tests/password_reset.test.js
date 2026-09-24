/**
 * Password-reset endpoint tests.
 * Mongoose User model and email service are mocked — no real DB or Resend calls.
 */
const request = require('supertest');

jest.mock('../src/models/User', () => ({
  findOne: jest.fn(),
  find:    jest.fn(),
  create:  jest.fn(),
}));

jest.mock('../src/services/emailService', () => ({
  sendVerificationEmail:       jest.fn().mockResolvedValue(undefined),
  sendResendVerificationEmail: jest.fn().mockResolvedValue(undefined),
  sendPasswordResetEmail:      jest.fn().mockResolvedValue(undefined),
}));

const app  = require('../src/app');
const User = require('../src/models/User');
const { sendPasswordResetEmail } = require('../src/services/emailService');

beforeEach(() => jest.clearAllMocks());

// ── POST /api/auth/forgot-password ────────────────────────────────────────

describe('POST /api/auth/forgot-password — validation', () => {
  it('returns 422 for missing email', async () => {
    const res = await request(app).post('/api/auth/forgot-password').send({});
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 for invalid email format', async () => {
    const res = await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: 'not-an-email' });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });
});

describe('POST /api/auth/forgot-password — business logic', () => {
  it('returns 200 generic response for unknown email (anti-enumeration)', async () => {
    User.findOne.mockResolvedValue(null);

    const res = await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: 'nobody@nowhere.com' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/if an account/i);
    // Email must NOT be sent for unknown address
    expect(sendPasswordResetEmail).not.toHaveBeenCalled();
  });

  it('returns 200 generic response for unverified account (anti-enumeration)', async () => {
    User.findOne.mockResolvedValue({
      _id: 'uid',
      email: 'unverified@example.com',
      emailVerified: false,
    });

    const res = await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: 'unverified@example.com' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(sendPasswordResetEmail).not.toHaveBeenCalled();
  });

  it('sends reset email and returns 200 for a verified account', async () => {
    const mockUser = {
      _id: 'uid',
      name: 'Test User',
      email: 'verified@example.com',
      emailVerified: true,
      resetPasswordTokenHash: null,
      resetPasswordTokenExpires: null,
      save: jest.fn().mockResolvedValue(true),
    };
    User.findOne.mockResolvedValue(mockUser);

    const res = await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: 'verified@example.com' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/if an account/i);

    // Email should be sent
    expect(sendPasswordResetEmail).toHaveBeenCalledTimes(1);
    expect(sendPasswordResetEmail).toHaveBeenCalledWith(
      'verified@example.com',
      'Test User',
      expect.any(String) // raw token — we don't expose its value in tests
    );

    // Token must have been stored (save() called)
    expect(mockUser.save).toHaveBeenCalled();
    // Token hash must be set, not the raw token
    expect(mockUser.resetPasswordTokenHash).toBeDefined();
    expect(mockUser.resetPasswordTokenHash).not.toBe('');
  });

  it('invalidates previous reset token when a new request is made', async () => {
    const mockUser = {
      _id: 'uid',
      name: 'Test User',
      email: 'verified@example.com',
      emailVerified: true,
      resetPasswordTokenHash: 'old-hash',
      resetPasswordTokenExpires: new Date(Date.now() + 60000),
      save: jest.fn().mockResolvedValue(true),
    };
    User.findOne.mockResolvedValue(mockUser);

    await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: 'verified@example.com' });

    // New hash must differ from old one
    expect(mockUser.resetPasswordTokenHash).not.toBe('old-hash');
    expect(mockUser.save).toHaveBeenCalled();
  });
});

// ── POST /api/auth/reset-password ────────────────────────────────────────

describe('POST /api/auth/reset-password — validation', () => {
  it('returns 422 when token is missing', async () => {
    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ password: 'newpassword123' });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when password is missing', async () => {
    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: 'sometoken' });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when password is too short', async () => {
    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: 'sometoken', password: '123' });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });
});

describe('POST /api/auth/reset-password — business logic', () => {
  it('returns 400 for an invalid/unknown token', async () => {
    // No candidates with non-expired tokens
    User.find
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([]) })
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([]) });

    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: 'invalidtoken1234567890abcdefghij', password: 'newpassword123' });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/invalid/i);
  });

  it('returns 410 for an expired token', async () => {
    const bcrypt = require('bcryptjs');
    const rawToken = 'expiredresettoken12345678901234';
    const hash = await bcrypt.hash(rawToken, 10);

    const expiredUser = {
      resetPasswordTokenHash: hash,
      compareResetToken: async (t) => bcrypt.compare(t, hash),
    };

    // Non-expired find → empty; expired find → match
    User.find
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([]) })
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([expiredUser]) });

    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: rawToken, password: 'newpassword123' });

    expect(res.statusCode).toBe(410);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/expired/i);
  });

  it('resets password and invalidates token for a valid token', async () => {
    const bcrypt = require('bcryptjs');
    const rawToken = 'validresettoken1234567890abcdef';
    const hash = await bcrypt.hash(rawToken, 10);

    const mockUser = {
      _id: 'uid',
      name: 'Test User',
      email: 'user@example.com',
      emailVerified: true,
      resetPasswordTokenHash: hash,
      resetPasswordTokenExpires: new Date(Date.now() + 900000),
      compareResetToken: async (t) => bcrypt.compare(t, hash),
      save: jest.fn().mockResolvedValue(true),
      toJSON: () => ({ _id: 'uid', email: 'user@example.com' }),
    };

    User.find.mockReturnValueOnce({ select: jest.fn().mockResolvedValue([mockUser]) });

    const res = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: rawToken, password: 'newpassword123' });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/password reset successfully/i);

    // Token must be cleared
    expect(mockUser.resetPasswordTokenHash).toBeUndefined();
    expect(mockUser.resetPasswordTokenExpires).toBeUndefined();

    // Password must have been updated (save called)
    expect(mockUser.save).toHaveBeenCalled();

    // Response must not contain a JWT — user must log in manually
    expect(res.body.token).toBeUndefined();
  });

  it('token cannot be reused after successful reset', async () => {
    const bcrypt = require('bcryptjs');
    const rawToken = 'reusedtoken1234567890abcdefghij';
    const hash = await bcrypt.hash(rawToken, 10);

    const mockUser = {
      _id: 'uid',
      resetPasswordTokenHash: hash,
      resetPasswordTokenExpires: new Date(Date.now() + 900000),
      compareResetToken: async (t) => bcrypt.compare(t, hash),
      save: jest.fn().mockImplementation(function () {
        // Simulate save clearing the token (as the controller does)
        this.resetPasswordTokenHash = undefined;
        this.resetPasswordTokenExpires = undefined;
        return Promise.resolve(true);
      }),
    };

    // First use — success
    User.find.mockReturnValueOnce({ select: jest.fn().mockResolvedValue([mockUser]) });
    const first = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: rawToken, password: 'firstpassword123' });
    expect(first.statusCode).toBe(200);

    // Second use — token gone, no candidates
    User.find
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([]) })  // non-expired
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([]) }); // expired

    const second = await request(app)
      .post('/api/auth/reset-password')
      .send({ token: rawToken, password: 'secondpassword123' });
    expect(second.statusCode).toBe(400);
  });
});
