const request = require('supertest');
const app = require('../src/app');

describe('GET /api/health', () => {
  it('should return 200 with success and message', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe('AssetGuard API is running');
    expect(res.body.database).toBeDefined();
    expect(res.body.timestamp).toBeDefined();
  });
});
