/**
 * Detection endpoint tests.
 * Mongoose models and JWT are mocked — no real DB needed.
 */
const request = require('supertest');

// ── Mock models ────────────────────────────────────────────────────────────
jest.mock('../src/models/User', () => ({
  findOne:  jest.fn(),
  find:     jest.fn(),
  create:   jest.fn(),
  findById: jest.fn(),
}));

jest.mock('../src/models/Asset', () => ({
  findOne: jest.fn(),
  find:    jest.fn(),
  create:  jest.fn(),
}));

jest.mock('../src/models/Detection', () => ({
  create: jest.fn(),
}));

jest.mock('../src/services/emailService', () => ({
  sendVerificationEmail:       jest.fn().mockResolvedValue(undefined),
  sendResendVerificationEmail: jest.fn().mockResolvedValue(undefined),
  sendPasswordResetEmail:      jest.fn().mockResolvedValue(undefined),
}));

const app       = require('../src/app');
const jwt       = require('jsonwebtoken');
const User      = require('../src/models/User');
const Asset     = require('../src/models/Asset');
const Detection = require('../src/models/Detection');

// Generate a valid JWT signed with the test secret from setup.js
const makeToken = (userId = 'testuser123') =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '1h' });

// Valid base payload
const VALID_PAYLOAD = {
  trackerId: 'AG-001',
  bleRssi: -58,
  gps: { latitude: 12.9716, longitude: 77.5946, accuracy: 8.5 },
  wifiFingerprint: [
    { bssid: 'aa:bb:cc:dd:ee:ff', rssi: -45 },
    { bssid: '11:22:33:44:55:66', rssi: -72 },
  ],
  timestamp: '2026-08-17T10:30:00.000Z',
};

beforeEach(() => jest.clearAllMocks());

// ── Auth guard ─────────────────────────────────────────────────────────────

describe('POST /api/detections — auth guard', () => {
  it('returns 401 without token', async () => {
    const res = await request(app).post('/api/detections').send(VALID_PAYLOAD);
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('returns 401 with invalid token', async () => {
    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', 'Bearer bad.jwt.token')
      .send(VALID_PAYLOAD);
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

// ── Input validation ───────────────────────────────────────────────────────

describe('POST /api/detections — input validation', () => {
  // auth middleware calls User.findById — mock it for all validation tests
  beforeEach(() => {
    const User = require('../src/models/User');
    User.findById.mockResolvedValue({ _id: 'testuser123', emailVerified: true });
  });

  it('returns 422 when trackerId is missing', async () => {
    const { trackerId, ...body } = VALID_PAYLOAD;
    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(body);
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when bleRssi is out of range', async () => {
    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ ...VALID_PAYLOAD, bleRssi: 10 }); // positive dBm is invalid
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when timestamp is invalid', async () => {
    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ ...VALID_PAYLOAD, timestamp: 'not-a-date' });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 422 when gps.latitude is out of range', async () => {
    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ ...VALID_PAYLOAD, gps: { latitude: 999, longitude: 77, accuracy: 5 } });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });
});

// ── Business logic ─────────────────────────────────────────────────────────

describe('POST /api/detections — business logic', () => {
  beforeEach(() => {
    const User = require('../src/models/User');
    User.findById.mockResolvedValue({ _id: 'testuser123', emailVerified: true });
  });

  it('returns 404 when trackerId does not match any owned asset', async () => {
    Asset.findOne.mockResolvedValue(null);

    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(VALID_PAYLOAD);

    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/no asset found/i);
  });

  it('returns 201 with GPS method when accuracy ≤ 30m', async () => {
    const mockAsset = {
      _id: 'asset123',
      trackerId: 'AG-001',
      name: 'College Bag',
      lastDetectedLocation: null,
      lastDetectedTime: null,
      save: jest.fn().mockResolvedValue(true),
    };
    Asset.findOne.mockResolvedValue(mockAsset);
    Detection.create.mockResolvedValue({
      _id: 'det123',
      trackerId: 'AG-001',
      timestamp: new Date(VALID_PAYLOAD.timestamp),
    });

    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(VALID_PAYLOAD); // accuracy = 8.5m → GPS method

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.detection.position.method).toBe('GPS');
    expect(res.body.detection.assetName).toBe('College Bag');
    expect(mockAsset.save).toHaveBeenCalled();
    // Asset.lastDetectedLocation should be updated
    expect(mockAsset.lastDetectedLocation).toMatch(/GPS/);
  });

  it('resolves HYBRID method when GPS accuracy is between 30–80m and Wi-Fi available', async () => {
    const mockAsset = {
      _id: 'asset123',
      trackerId: 'AG-001',
      name: 'Laptop',
      save: jest.fn().mockResolvedValue(true),
    };
    Asset.findOne.mockResolvedValue(mockAsset);
    Detection.create.mockResolvedValue({
      _id: 'det124',
      trackerId: 'AG-001',
      timestamp: new Date(VALID_PAYLOAD.timestamp),
    });

    const payload = {
      ...VALID_PAYLOAD,
      gps: { latitude: 12.97, longitude: 77.59, accuracy: 55 }, // fair GPS
    };

    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(payload);

    expect(res.statusCode).toBe(201);
    expect(res.body.detection.position.method).toBe('HYBRID');
  });

  it('resolves WIFI method when GPS accuracy > 80m', async () => {
    const mockAsset = {
      _id: 'asset123', trackerId: 'AG-001', name: 'Laptop',
      save: jest.fn().mockResolvedValue(true),
    };
    Asset.findOne.mockResolvedValue(mockAsset);
    Detection.create.mockResolvedValue({ _id: 'det125', trackerId: 'AG-001',
      timestamp: new Date() });

    const payload = {
      ...VALID_PAYLOAD,
      gps: { latitude: 12.97, longitude: 77.59, accuracy: 100 }, // poor GPS
    };

    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(payload);

    expect(res.statusCode).toBe(201);
    expect(res.body.detection.position.method).toBe('WIFI');
  });

  it('resolves BLE_ONLY when no GPS and no Wi-Fi', async () => {
    const mockAsset = {
      _id: 'asset123', trackerId: 'AG-001', name: 'ID Card',
      save: jest.fn().mockResolvedValue(true),
    };
    Asset.findOne.mockResolvedValue(mockAsset);
    Detection.create.mockResolvedValue({ _id: 'det126', trackerId: 'AG-001',
      timestamp: new Date() });

    const payload = {
      trackerId: 'AG-001',
      bleRssi: -72,
      wifiFingerprint: [],
      timestamp: VALID_PAYLOAD.timestamp,
      // no gps field
    };

    const res = await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(payload);

    expect(res.statusCode).toBe(201);
    expect(res.body.detection.position.method).toBe('BLE_ONLY');
  });

  it('updates asset lastDetectedLocation and lastDetectedTime on success', async () => {
    const mockAsset = {
      _id: 'asset123', trackerId: 'AG-001', name: 'Bag',
      lastDetectedLocation: null,
      lastDetectedTime: null,
      save: jest.fn().mockResolvedValue(true),
    };
    Asset.findOne.mockResolvedValue(mockAsset);
    Detection.create.mockResolvedValue({ _id: 'det127', trackerId: 'AG-001',
      timestamp: new Date(VALID_PAYLOAD.timestamp) });

    await request(app)
      .post('/api/detections')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send(VALID_PAYLOAD);

    expect(mockAsset.lastDetectedLocation).toBeTruthy();
    expect(mockAsset.lastDetectedTime).toBeInstanceOf(Date);
    expect(mockAsset.save).toHaveBeenCalledTimes(1);
  });
});
