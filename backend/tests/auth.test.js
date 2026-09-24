/**
 * Auth endpoint tests.
 * Run against the Express app without a real MongoDB or Resend connection.
 * All Mongoose model methods are mocked so no DB connection is needed.
 */
const request = require('supertest');

// ── Mock Mongoose User model before app is loaded ─────────────────────────
jest.mock('../src/models/User', () => ({
  findOne:  jest.fn(),
  find:     jest.fn(),
  create:   jest.fn(),
  findById: jest.fn(),
}));

// ── Mock email service so no Resend calls are made ────────────────────────
jest.mock('../src/services/emailService', () => ({
  sendVerificationEmail:       jest.fn().mockResolvedValue(undefined),
  sendResendVerificationEmail: jest.fn().mockResolvedValue(undefined),
  sendPasswordResetEmail:      jest.fn().mockResolvedValue(undefined),
}));

const app = require('../src/app');
const User = require('../src/models/User');

// ── Reset mocks between tests ─────────────────────────────────────────────
beforeEach(() => {
  jest.clearAllMocks();
});

// ── Registration — input validation ───────────────────────────────────────
describe('POST /api/auth/register — validation', () => {
  it('returns 422 when name is missing', async () => {
    const res = await request(app).post('/api/auth/register').send({
      email: 'test@example.com',
      password: 'password123',
    });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors).toBeDefined();
  });

  it('returns 422 when email is invalid', async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'Test User',
      email: 'not-an-email',
      password: 'password123',
    });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when password is too short', async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'Test User',
      email: 'test@example.com',
      password: '123',
    });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when name is too short', async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'A',
      email: 'test@example.com',
      password: 'password123',
    });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });
});

// ── Registration — business logic (mocked DB) ─────────────────────────────
describe('POST /api/auth/register — business logic', () => {
  it('returns 409 when email already exists', async () => {
    User.findOne.mockResolvedValue({ _id: 'existing-id', email: 'test@example.com' });

    const res = await request(app).post('/api/auth/register').send({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
    });
    expect(res.statusCode).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/already exists/i);
  });

  it('returns 201 and asks user to verify email on success', async () => {
    User.findOne.mockResolvedValue(null); // no existing user
    User.create.mockResolvedValue({
      _id: 'new-id',
      name: 'Test User',
      email: 'test@example.com',
      emailVerified: false,
      toJSON: () => ({ _id: 'new-id', name: 'Test User', email: 'test@example.com', emailVerified: false }),
    });

    const res = await request(app).post('/api/auth/register').send({
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
    });
    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/verify your account/i);
    // Registration must NOT return a JWT — user must verify first
    expect(res.body.token).toBeUndefined();
  });
});

// ── Login — input validation ───────────────────────────────────────────────
describe('POST /api/auth/login — validation', () => {
  it('returns 422 when email is missing', async () => {
    const res = await request(app).post('/api/auth/login').send({
      password: 'password123',
    });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when password is missing', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'test@example.com',
    });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });
});

// ── Login — email verification gate ──────────────────────────────────────
describe('POST /api/auth/login — email verification gate', () => {
  it('returns 403 when user has not verified their email', async () => {
    User.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue({
        _id: 'uid',
        email: 'test@example.com',
        emailVerified: false,
        comparePassword: jest.fn().mockResolvedValue(true),
        toJSON: () => ({}),
      }),
    });

    const res = await request(app).post('/api/auth/login').send({
      email: 'test@example.com',
      password: 'password123',
    });
    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/verify your email/i);
  });

  it('returns 401 for wrong password', async () => {
    User.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue({
        _id: 'uid',
        email: 'test@example.com',
        emailVerified: true,
        comparePassword: jest.fn().mockResolvedValue(false),
        toJSON: () => ({}),
      }),
    });

    const res = await request(app).post('/api/auth/login').send({
      email: 'test@example.com',
      password: 'wrongpassword',
    });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

// ── GET /api/auth/me — authentication guard ───────────────────────────────
describe('GET /api/auth/me — authentication', () => {
  it('returns 401 when no token is provided', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('returns 401 when an invalid token is provided', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer invalid.token.here');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

// ── GET /api/auth/verify-email — token validation ────────────────────────
describe('GET /api/auth/verify-email — input validation', () => {
  it('returns 400 when token query param is missing', async () => {
    const res = await request(app).get('/api/auth/verify-email');
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/token/i);
  });

  it('returns 400 for an invalid token when no candidates exist', async () => {
    // find() is chained with .select() in the controller
    User.find.mockReturnValue({ select: jest.fn().mockResolvedValue([]) });

    const res = await request(app)
      .get('/api/auth/verify-email')
      .query({ token: 'totallyfaketoken1234567890abcdef' });
    expect([400, 410]).toContain(res.statusCode);
    expect(res.body.success).toBe(false);
  });

  it('returns 410 for an expired token', async () => {
    const bcrypt = require('bcryptjs');
    const rawToken = 'expiredtoken1234567890abcdefghij';
    const hash = await bcrypt.hash(rawToken, 10);

    const expiredCandidate = {
      emailVerified: false,
      verificationTokenHash: hash,
      compareVerificationToken: async (t) => bcrypt.compare(t, hash),
    };

    // First find (non-expired candidates) → empty
    // Second find (expired candidates) → our candidate
    User.find
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([]) })
      .mockReturnValueOnce({ select: jest.fn().mockResolvedValue([expiredCandidate]) });

    const res = await request(app)
      .get('/api/auth/verify-email')
      .query({ token: rawToken });
    expect(res.statusCode).toBe(410);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/expired/i);
  });

  it('returns 200 and a JWT for a valid token', async () => {
    const bcrypt = require('bcryptjs');
    const rawToken = 'validtoken1234567890abcdefghijkl';
    const hash = await bcrypt.hash(rawToken, 10);

    const mockUser = {
      _id: 'uid123',
      name: 'Test User',
      email: 'test@example.com',
      emailVerified: false,
      verificationTokenHash: hash,
      verificationTokenExpires: new Date(Date.now() + 3600000),
      compareVerificationToken: async (t) => bcrypt.compare(t, hash),
      save: jest.fn().mockResolvedValue(true),
      toJSON: () => ({
        _id: 'uid123',
        name: 'Test User',
        email: 'test@example.com',
        emailVerified: true,
      }),
    };

    // First find (non-expired candidates) → our candidate
    User.find.mockReturnValueOnce({ select: jest.fn().mockResolvedValue([mockUser]) });

    const res = await request(app)
      .get('/api/auth/verify-email')
      .query({ token: rawToken });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/verified/i);
    expect(res.body.token).toBeDefined();
  });
});

// ── POST /api/auth/resend-verification ───────────────────────────────────
describe('POST /api/auth/resend-verification', () => {
  it('returns 400 when email is missing', async () => {
    const res = await request(app)
      .post('/api/auth/resend-verification')
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('returns 200 for an email not found (anti-enumeration)', async () => {
    User.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue(null),
    });

    const res = await request(app)
      .post('/api/auth/resend-verification')
      .send({ email: 'nobody@nowhere.com' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('returns 409 when email is already verified', async () => {
    User.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue({
        _id: 'uid',
        email: 'verified@example.com',
        emailVerified: true,
      }),
    });

    const res = await request(app)
      .post('/api/auth/resend-verification')
      .send({ email: 'verified@example.com' });
    expect(res.statusCode).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/already verified/i);
  });

  it('returns 200 and sends new email for unverified user', async () => {
    const mockUser = {
      _id: 'uid',
      name: 'Test User',
      email: 'unverified@example.com',
      emailVerified: false,
      verificationTokenHash: null,
      verificationTokenExpires: null,
      save: jest.fn().mockResolvedValue(true),
    };
    User.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue(mockUser),
    });

    const res = await request(app)
      .post('/api/auth/resend-verification')
      .send({ email: 'unverified@example.com' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/verification email/i);
  });
});
