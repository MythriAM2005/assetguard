/**
 * POST /api/location/predict-room — unit tests.
 *
 * The Python ML API (fetch) and the User model (JWT auth) are both mocked
 * so no real network call or DB connection is needed.
 */
const request = require('supertest');
const jwt     = require('jsonwebtoken');

// ── Mock User (auth middleware) ───────────────────────────────────────────
jest.mock('../src/models/User', () => ({
  findOne:  jest.fn(),
  find:     jest.fn(),
  create:   jest.fn(),
  findById: jest.fn(),
}));

// ── Mock email service (imported transitively by authController) ──────────
jest.mock('../src/services/emailService', () => ({
  sendVerificationEmail:       jest.fn().mockResolvedValue(undefined),
  sendResendVerificationEmail: jest.fn().mockResolvedValue(undefined),
  sendPasswordResetEmail:      jest.fn().mockResolvedValue(undefined),
}));

// ── Mock global fetch (used by locationController) ────────────────────────
global.fetch = jest.fn();

const app  = require('../src/app');
const User = require('../src/models/User');

// Helper — sign a test JWT
const makeToken = (userId = 'testuser') =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '1h' });

// Helper — make auth middleware pass
const mockAuthUser = () => {
  User.findById.mockResolvedValue({ _id: 'testuser', emailVerified: true });
};

// Sample Wi-Fi fingerprint (realistic NIE campus data)
const SAMPLE_FINGERPRINT = {
  '84:d8:1b:aa:bb:cc': -43,
  '84:d8:1b:11:22:33': -67,
  '84:d8:1b:44:55:66': -81,
};

beforeEach(() => {
  jest.clearAllMocks();
});

// ── Auth guard ─────────────────────────────────────────────────────────────

describe('POST /api/location/predict-room — auth guard', () => {
  it('returns 401 without a token', async () => {
    const res = await request(app)
      .post('/api/location/predict-room')
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('returns 401 with an invalid token', async () => {
    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', 'Bearer bad.token.here')
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

// ── Input validation ───────────────────────────────────────────────────────

describe('POST /api/location/predict-room — input validation', () => {
  beforeEach(mockAuthUser);

  it('returns 422 when wifiFingerprint is missing', async () => {
    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({});
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors).toBeDefined();
  });

  it('returns 422 when wifiFingerprint is not an object', async () => {
    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: 'not-an-object' });
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 400 when wifiFingerprint is an empty object', async () => {
    // passes express-validator (is an object) but fails the controller guard
    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: {} });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/at least one/i);
  });
});

// ── ML API proxy behaviour ─────────────────────────────────────────────────

describe('POST /api/location/predict-room — ML API proxy', () => {
  beforeEach(mockAuthUser);

  it('returns 503 when the ML API is unreachable', async () => {
    global.fetch.mockRejectedValue(new TypeError('fetch failed'));

    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });

    expect(res.statusCode).toBe(503);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/cannot reach the ML service/i);
  });

  it('returns 504 when the ML API times out (AbortError)', async () => {
    const abortErr = new Error('The operation was aborted');
    abortErr.name  = 'AbortError';
    global.fetch.mockRejectedValue(abortErr);

    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });

    expect(res.statusCode).toBe(504);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/timed out/i);
  });

  it('returns 502 when the ML API returns a non-2xx status', async () => {
    global.fetch.mockResolvedValue({
      ok:     false,
      status: 500,
      text:   async () => 'Internal Server Error',
    });

    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });

    expect(res.statusCode).toBe(502);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/ML service returned an error/i);
  });

  it('returns 200 with normalised prediction on success', async () => {
    // Simulate the Python API returning predicted_room + top_predictions
    global.fetch.mockResolvedValue({
      ok:   true,
      json: async () => ({
        predicted_room: '306',
        confidence:     0.28,
        top_predictions: [
          { room: '306', probability: 0.28 },
          { room: '209', probability: 0.22 },
          { room: '310', probability: 0.17 },
        ],
      }),
    });

    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.predictedRoom).toBe('306');
    expect(res.body.confidence).toBeCloseTo(0.28);
    expect(res.body.confidencePercent).toBe('28%');
    expect(res.body.top3).toHaveLength(3);
    expect(res.body.top3[0].room).toBe('306');
    expect(res.body.top3[1].room).toBe('209');
    expect(res.body.top3[2].room).toBe('310');
  });

  it('forwards the wifiFingerprint as wifi to the ML API', async () => {
    global.fetch.mockResolvedValue({
      ok:   true,
      json: async () => ({
        predicted_room: '209',
        confidence: 0.55,
        top_predictions: [],
      }),
    });

    await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });

    // Verify fetch was called with the correct payload shape
    expect(global.fetch).toHaveBeenCalledTimes(1);
    const [calledUrl, calledOptions] = global.fetch.mock.calls[0];
    expect(calledUrl).toContain('/predict-room');
    const sentBody = JSON.parse(calledOptions.body);
    expect(sentBody).toHaveProperty('wifi');
    expect(sentBody.wifi).toEqual(SAMPLE_FINGERPRINT);
  });

  it('handles ML API response with camelCase keys (predictedRoom)', async () => {
    global.fetch.mockResolvedValue({
      ok:   true,
      json: async () => ({
        predictedRoom: '310',   // camelCase variant
        confidence:    0.40,
        top3: [
          { room: '310', probability: 0.40 },
        ],
      }),
    });

    const res = await request(app)
      .post('/api/location/predict-room')
      .set('Authorization', `Bearer ${makeToken()}`)
      .send({ wifiFingerprint: SAMPLE_FINGERPRINT });

    expect(res.statusCode).toBe(200);
    expect(res.body.predictedRoom).toBe('310');
    expect(res.body.top3).toHaveLength(1);
  });
});
