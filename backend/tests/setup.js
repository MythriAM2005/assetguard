// Set required env vars before any test runs
process.env.JWT_SECRET = 'test-secret-key-for-jest-only';
process.env.MONGODB_URI = ''; // empty — no DB connection during unit tests
process.env.PORT = '5001';
process.env.ML_API_URL = 'http://localhost:9999'; // dummy — mocked in location tests
