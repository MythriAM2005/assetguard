const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/User');
const Asset = require('../src/models/Asset');
const CommunityDetection = require('../src/models/CommunityDetection');

describe('POST /api/community/detections', () => {
  let authToken;
  let userId;
  let otherUserId;
  let lostAssetId;
  let activeAssetId;

  beforeAll(async () => {
    // Register asset owner
    const ownerReg = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Asset Owner',
        email: 'owner-cd@test.com',
        password: 'password123',
      });
    otherUserId = ownerReg.body.user._id;

    // Register community member (detector)
    const detectorReg = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Community Member',
        email: 'detector-cd@test.com',
        password: 'password123',
      });
    userId = detectorReg.body.user._id;

    // Login as community user
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ email: 'detector-cd@test.com', password: 'password123' });
    authToken = loginRes.body.token;

    // Create LOST asset (owned by Asset Owner)
    const lostAsset = await Asset.create({
      name: 'Lost Laptop',
      category: 'Electronics',
      description: 'MacBook Pro',
      trackerId: 'AG-LOST-CD-001',
      status: 'LOST',
      userId: otherUserId,
    });
    lostAssetId = lostAsset._id;

    // Create ACTIVE asset (owned by Asset Owner)
    const activeAsset = await Asset.create({
      name: 'Active Laptop',
      category: 'Electronics',
      description: 'MacBook Air',
      trackerId: 'AG-ACTIVE-CD-001',
      status: 'ACTIVE',
      userId: otherUserId,
    });
    activeAssetId = activeAsset._id;
  });

  afterAll(async () => {
    await User.deleteMany({ email: { $in: ['owner-cd@test.com', 'detector-cd@test.com'] } });
    await Asset.deleteMany({ trackerId: { $regex: /^AG-(LOST|ACTIVE)-CD-/ } });
    await CommunityDetection.deleteMany({});
  });

  afterEach(async () => {
    await CommunityDetection.deleteMany({});
  });

  it('should reject request without auth token', async () => {
    const res = await request(app)
      .post('/api/community/detections')
      .send({
        trackerId: 'AG-LOST-CD-001',
        rssi: -57,
        detectedAt: new Date().toISOString(),
      });

    expect(res.statusCode).toBe(401);
  });

  it('should accept detection for LOST asset', async () => {
    const detectedAt = new Date();
    const res = await request(app)
      .post('/api/community/detections')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        trackerId: 'AG-LOST-CD-001',
        rssi: -57,
        remoteId: 'AA:BB:CC:DD:EE:FF',
        detectedAt: detectedAt.toISOString(),
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toContain('Community detection recorded');
    expect(res.body.detectionId).toBeDefined();

    // Verify database record
    const detection = await CommunityDetection.findById(res.body.detectionId);
    expect(detection).toBeDefined();
    expect(detection.trackerId).toBe('AG-LOST-CD-001');
    expect(detection.assetId.toString()).toBe(lostAssetId.toString());
    expect(detection.detectedBy.toString()).toBe(userId.toString());
    expect(detection.rssi).toBe(-57);
    expect(detection.remoteId).toBe('AA:BB:CC:DD:EE:FF');
  });

  it('should reject detection for ACTIVE asset', async () => {
    const res = await request(app)
      .post('/api/community/detections')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        trackerId: 'AG-ACTIVE-CD-001',
        rssi: -60,
        detectedAt: new Date().toISOString(),
      });

    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('not marked as LOST');
  });

  it('should reject detection for non-existent asset', async () => {
    const res = await request(app)
      .post('/api/community/detections')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        trackerId: 'AG-NONEXISTENT-999',
        rssi: -65,
        detectedAt: new Date().toISOString(),
      });

    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('not found');
  });

  it('should reject invalid RSSI value', async () => {
    const res = await request(app)
      .post('/api/community/detections')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        trackerId: 'AG-LOST-CD-001',
        rssi: 50, // invalid: should be between -120 and 0
        detectedAt: new Date().toISOString(),
      });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should reject invalid timestamp', async () => {
    const res = await request(app)
      .post('/api/community/detections')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        trackerId: 'AG-LOST-CD-001',
        rssi: -57,
        detectedAt: 'not-a-valid-timestamp',
      });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should accept detection without remoteId', async () => {
    const res = await request(app)
      .post('/api/community/detections')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        trackerId: 'AG-LOST-CD-001',
        rssi: -62,
        detectedAt: new Date().toISOString(),
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);

    const detection = await CommunityDetection.findById(res.body.detectionId);
    expect(detection.remoteId).toBeNull();
  });

  it('should record detectedBy from JWT, not request body', async () => {
    const res = await request(app)
      .post('/api/community/detections')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        trackerId: 'AG-LOST-CD-001',
        rssi: -55,
        detectedAt: new Date().toISOString(),
        detectedBy: 'fake-user-id', // should be ignored
      });

    expect(res.statusCode).toBe(201);

    const detection = await CommunityDetection.findById(res.body.detectionId);
    expect(detection.detectedBy.toString()).toBe(userId.toString());
    expect(detection.detectedBy.toString()).not.toBe('fake-user-id');
  });
});
