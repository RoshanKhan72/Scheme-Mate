const { test, describe, beforeEach, after } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../../src/app');
const { cleanDatabase, closeConnections } = require('../helper');
const db = require('../../src/config/db');

describe('Schemes & Admin Control Integration Tests', () => {
  let userToken;
  let adminToken;

  beforeEach(async () => {
    await cleanDatabase();

    // 1. Register regular user
    const resUser = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Regular User',
        email: 'user@example.com',
        password: 'SecurePass123'
      });
    userToken = resUser.body.token;

    // 2. Register admin user
    const resAdmin = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Admin User',
        email: 'admin@example.com',
        password: 'SecurePass123'
      });
    adminToken = resAdmin.body.token;

    // Manually elevate regular admin user to admin role in clean test DB
    await db.query("UPDATE users SET role = 'admin' WHERE email = $1", ['admin@example.com']);
  });

  after(async () => {
    await closeConnections();
  });

  test('GET /api/v1/schemes - list schemes', async () => {
    const res = await request(app)
      .get('/api/v1/schemes')
      .expect(200);

    assert.strictEqual(res.body.success, true);
    assert.ok(Array.isArray(res.body.schemes));
  });

  test('GET /api/v1/schemes/:id - UUID validation checks', async () => {
    // 1. Send invalid non-UUID identifier (should be blocked by validateParamsUUID middleware)
    const resInvalid = await request(app)
      .get('/api/v1/schemes/not-a-valid-uuid')
      .expect(400);

    assert.strictEqual(resInvalid.body.success, false);
    assert.strictEqual(resInvalid.body.errors[0].field, 'id');

    // 2. Send valid UUID (but not existing in database)
    const validUuid = 'a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d';
    await request(app)
      .get(`/api/v1/schemes/${validUuid}`)
      .expect(404);
  });

  test('Admin-only blocks verification', async () => {
    const newScheme = {
      name: 'Central Farmer Scheme',
      description: 'Supports high yield farming outputs.',
      state: 'All India',
      category: 'Agriculture',
      benefits: 'Financial grants.',
      source_type: 'Official',
      official_department: 'Ministry of Agriculture'
    };

    // 1. Try to create as normal user (should be forbidden with 403)
    await request(app)
      .post('/api/v1/schemes')
      .set('Authorization', `Bearer ${userToken}`)
      .send(newScheme)
      .expect(403);

    // 2. Create as admin (should succeed with 201)
    const resAdminCreate = await request(app)
      .post('/api/v1/schemes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(newScheme)
      .expect(201);

    assert.strictEqual(resAdminCreate.body.success, true);
    assert.ok(resAdminCreate.body.scheme.id);
  });
});
