/**
 * Asset endpoint tests — middleware/auth enforcement only.
 * All asset routes require a valid JWT, so these tests verify
 * the 401 guard works without a real database.
 */
const request = require('supertest');
const app = require('../src/app');

const ASSET_ROUTES = [
  { method: 'get', path: '/api/assets' },
  { method: 'get', path: '/api/assets/someId' },
  { method: 'post', path: '/api/assets' },
  { method: 'put', path: '/api/assets/someId' },
  { method: 'delete', path: '/api/assets/someId' },
  { method: 'patch', path: '/api/assets/someId/lost' },
  { method: 'patch', path: '/api/assets/someId/recovered' },
];

describe('Asset routes — unauthenticated access', () => {
  ASSET_ROUTES.forEach(({ method, path }) => {
    it(`${method.toUpperCase()} ${path} should return 401 without token`, async () => {
      const res = await request(app)[method](path);
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });
});

describe('POST /api/assets — validation with bad token', () => {
  it('should return 401 with invalid token', async () => {
    const res = await request(app)
      .post('/api/assets')
      .set('Authorization', 'Bearer bad.jwt.token')
      .send({ name: 'Test', category: 'Bag', trackerId: 'AG-001' });
    expect(res.statusCode).toBe(401);
  });
});
