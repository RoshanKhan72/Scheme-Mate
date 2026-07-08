const { test, describe, beforeEach, after } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../../src/app');
const { cleanDatabase, closeConnections } = require('../helper');

describe('Feedback Integration Tests', () => {
  let authToken;

  beforeEach(async () => {
    await cleanDatabase();

    // Register user to get an auth token
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Feedback Submitter',
        email: 'feedback@example.com',
        password: 'SecurePass123'
      });
    authToken = res.body.token;
  });

  after(async () => {
    await closeConnections();
  });

  test('POST /api/v1/feedback - success and validation checks', async () => {
    // 1. Success case
    const resSuccess = await request(app)
      .post('/api/v1/feedback')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        screen: 'Scheme Details',
        type: 'bug',
        details: 'The submit button is overlapping on mobile views.'
      })
      .expect(201);

    assert.strictEqual(resSuccess.body.success, true);
    assert.ok(resSuccess.body.feedback.id);
    assert.strictEqual(resSuccess.body.feedback.screen, 'Scheme Details');

    // 2. Reject missing core fields (e.g. details description)
    const resFail = await request(app)
      .post('/api/v1/feedback')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        screen: 'Scheme Details',
        type: 'bug'
      })
      .expect(400);

    assert.strictEqual(resFail.body.success, false);
  });
});
