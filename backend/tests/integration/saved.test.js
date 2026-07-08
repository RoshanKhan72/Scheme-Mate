const { test, describe, beforeEach, after } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../../src/app');
const { cleanDatabase, closeConnections } = require('../helper');
const db = require('../../src/config/db');

describe('Saved Schemes Integration Tests', () => {
  let authToken;
  let schemeId;

  beforeEach(async () => {
    await cleanDatabase();

    // 1. Register user
    const resUser = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Saved Schemes Owner',
        email: 'saved@example.com',
        password: 'SecurePass123'
      });
    authToken = resUser.body.token;

    // 2. Insert a valid scheme to bookmark
    const resScheme = await db.query(`
      INSERT INTO schemes (
        name, description, state, category, required_documents, 
        benefits, source_type, official_department
      ) VALUES (
        'Central Student Scholarship', 'Scholarship details', 'All India', 'Education', ARRAY['ID'], 
        'Tuition waiver', 'Official', 'Ministry of Education'
      ) RETURNING id
    `);
    schemeId = resScheme.rows[0].id;
  });

  after(async () => {
    await closeConnections();
  });

  test('Saved Schemes CRUD operations & duplicates prevention', async () => {
    // 1. Get saved schemes initially (should be empty array)
    const listInitial = await request(app)
      .get('/api/v1/saved')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);
    assert.strictEqual(listInitial.body.success, true);
    assert.strictEqual(listInitial.body.schemes.length, 0);

    // 2. Bookmark the scheme
    const saveRes = await request(app)
      .post(`/api/v1/saved/${schemeId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ note: 'My favorite scheme' })
      .expect(200);
    assert.strictEqual(saveRes.body.success, true);

    // 3. Attempt duplicate save of the same scheme (updates note and returns 200 success due to ON CONFLICT DO UPDATE)
    const dupRes = await request(app)
      .post(`/api/v1/saved/${schemeId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ note: 'Duplicate note attempt' })
      .expect(200);
    assert.strictEqual(dupRes.body.success, true);

    // 4. Verify bookmarked scheme is in user list and note is updated
    const listAfter = await request(app)
      .get('/api/v1/saved')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);
    assert.strictEqual(listAfter.body.schemes.length, 1);
    assert.strictEqual(listAfter.body.schemes[0].id, schemeId);
    assert.strictEqual(listAfter.body.schemes[0].private_note, 'Duplicate note attempt');

    // 5. Unsave the scheme
    await request(app)
      .delete(`/api/v1/saved/${schemeId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    // 6. Verify list is empty again
    const listFinal = await request(app)
      .get('/api/v1/saved')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);
    assert.strictEqual(listFinal.body.schemes.length, 0);
  });
});
