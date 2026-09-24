/**
 * POST /api/community/scan — unit tests.
 * Mongoose and JWT are mocked — no real DB needed.
 */
const request = require('supertest');
const jwt     = require('jsonwebtoken');

// ── Mocks ──────────────────────────────────────────────────────────────────

jest.mock('../src/models/User', () => ({
  findOne:  jest.fn(),
  find:     jest.fn(),
  create:   jest.fn(),
  findById: jest.fn(),
}));

jest.mock('../src/models/CommunityFingerprint', () => ({
  create: jest.fn(),
}));

jest.mock('../src/services/emailService', () => ({
  sendVerificationEmail:       jest.fn().mockResolvedValue(undefined),
  sendResendVerificationEmail: jest.fn().mockResolvedValue(undefined),
  sendPasswordResetEmail:      jest.fn().mockResolvedValue(undefined),
}));

const app                  = require('../src/app');
const User                 = require('../src/models/User');
const CommunityFingerprint = require('../src/models/CommunityFingerprint');

const makeToken = (userId = 'testuser') =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '1h' });

const mockAuthUser = () =>
  User.findById.mockResolvedValue({ _id: 'testuser', emailVerified: true });

const VALID_PAYLOAD = {
  wifiFingerprint: [
    { bssid: '84:d8:1b:aa:bb:cc', rssi: -43 },
    { bssid: '84:d8:1b:11:22:33', rssi: -67 },
  ],
};

beforeEach(() => jest.clearAllMocks());

// ── Auth guard ─────────────────────────────────────────────────────────────

describe('POST /api/community/scan — auth guard', () => {
  it('returns 401 without a token', async () => {
    const res = await request(app)
      .post('/api/community/scan')
      .send(VALID_PAYLOAD);
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('returns 401 with an invalid token', async () => {
    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', 'Bearer bad.token')
      .send(VALID_PAYLOAD);
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

// ── Input validation ───────────────────────────────────────────────────────

describe('POST /api/community/scan — input validation', () => {
  beforeEach(mockAuthUser);

  it('returns 422 when wifiFingerprint is missing', async () => {
    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({});
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors).toBeDefined();
  });

  it('returns 422 when wifiFingerprint is an empty array', async () => {
    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: [] });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when an AP has a missing bssid', async () => {
    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: [{ rssi: -50 }] });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when an AP rssi is out of range (positive)', async () => {
    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: [{ bssid: 'aa:bb:cc:dd:ee:ff', rssi: 10 }] });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when timestamp is not valid ISO 8601', async () => {
    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ ...VALID_PAYLOAD, timestamp: 'not-a-date' });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });
});

// ── Business logic ─────────────────────────────────────────────────────────

describe('POST /api/community/scan — business logic', () => {
  beforeEach(mockAuthUser);

  it('returns 201 and records the scan on success', async () => {
    CommunityFingerprint.create.mockResolvedValue({ _id: 'scan123' });

    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(VALID_PAYLOAD);

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/recorded/i);
    expect(res.body.scanId).toBe('scan123');
  });

  it('stores the scan using req.user._id (not from body)', async () => {
    CommunityFingerprint.create.mockResolvedValue({ _id: 'scan456' });

    await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken('user-abc')}`)
      .send(VALID_PAYLOAD);

    expect(CommunityFingerprint.create).toHaveBeenCalledTimes(1);
    const createArg = CommunityFingerprint.create.mock.calls[0][0];
    // scannedBy must come from the JWT, not the request body
    expect(createArg.scannedBy).toBe('testuser');
    // Body cannot override scannedBy
    expect(createArg).not.toHaveProperty('userId');
  });

  it('normalises BSSIDs to lowercase', async () => {
    CommunityFingerprint.create.mockResolvedValue({ _id: 'scan789' });

    await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({
        wifiFingerprint: [{ bssid: '84:D8:1B:AA:BB:CC', rssi: -50 }],
      });

    const createArg = CommunityFingerprint.create.mock.calls[0][0];
    expect(createArg.wifiFingerprint[0].bssid).toBe('84:d8:1b:aa:bb:cc');
  });

  it('accepts an optional ISO 8601 timestamp', async () => {
    CommunityFingerprint.create.mockResolvedValue({ _id: 'scan999' });
    const ts = '2026-08-17T10:30:00.000Z';

    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ ...VALID_PAYLOAD, timestamp: ts });

    expect(res.statusCode).toBe(201);
    const createArg = CommunityFingerprint.create.mock.calls[0][0];
    expect(createArg.timestamp).toEqual(new Date(ts));
  });

  it('uses server time when timestamp is omitted', async () => {
    CommunityFingerprint.create.mockResolvedValue({ _id: 'scanNow' });
    const before = Date.now();

    await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(VALID_PAYLOAD);

    const after = Date.now();
    const createArg = CommunityFingerprint.create.mock.calls[0][0];
    const stored = createArg.timestamp.getTime();
    expect(stored).toBeGreaterThanOrEqual(before);
    expect(stored).toBeLessThanOrEqual(after);
  });

  it('returns 500 when the database write fails', async () => {
    CommunityFingerprint.create.mockRejectedValue(new Error('DB error'));

    const res = await request(app)
      .post('/api/community/scan')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(VALID_PAYLOAD);

    expect(res.statusCode).toBe(500);
    expect(res.body.success).toBe(false);
  });
});
