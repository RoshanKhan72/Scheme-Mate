const { test, describe, beforeEach, after } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../../src/app');
const { cleanDatabase, closeConnections } = require('../helper');
const db = require('../../src/config/db');

describe('Auth & Rate Limiting Integration Tests', () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  after(async () => {
    await closeConnections();
  });

  test('POST /api/v1/auth/register - success and password policy validation', async () => {
    // 1. Invalid passwords (weak length)
    await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'John Test',
        email: 'john@example.com',
        password: 'weak'
      })
      .expect(400);

    // 2. Valid password satisfying complexity policy (8 chars, 1 uppercase, 1 lowercase, 1 number)
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'John Test',
        email: 'john@example.com',
        password: 'SecurePass123'
      })
      .expect(201);

    assert.strictEqual(res.body.success, true);
    assert.ok(res.body.token);
    assert.strictEqual(res.body.user.name, 'John Test');
    assert.strictEqual(res.body.user.email, 'john@example.com');
  });

  test('POST /api/v1/auth/register - rejects duplicate email', async () => {
    await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'First User',
        email: 'duplicate@example.com',
        password: 'SecurePass123'
      })
      .expect(201);

    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Second User',
        email: 'duplicate@example.com',
        password: 'AnotherSecure123'
      })
      .expect(400);

    assert.strictEqual(res.body.success, false);
  });

  test('POST /api/v1/auth/login - success and failure', async () => {
    // Register user
    await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Login User',
        email: 'login@example.com',
        password: 'SecurePass123'
      })
      .expect(201);

    // 1. Login success
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'login@example.com',
        password: 'SecurePass123'
      })
      .expect(200);

    assert.strictEqual(loginRes.body.success, true);
    assert.ok(loginRes.body.token);

    // 2. Login failure (wrong password)
    await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'login@example.com',
        password: 'WrongPassword123'
      })
      .expect(401);
  });

  test('GET /api/v1/auth/profile - requires valid token', async () => {
    // 1. Missing token
    await request(app)
      .get('/api/v1/auth/profile')
      .expect(401);

    // 2. Malformed token
    await request(app)
      .get('/api/v1/auth/profile')
      .set('Authorization', 'Bearer invalid_token_structure')
      .expect(401);
  });
});
