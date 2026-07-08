const { test, describe, beforeEach, after } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../../src/app');
const { cleanDatabase, closeConnections } = require('../helper');

describe('Profile Integration Tests', () => {
  let authToken;

  beforeEach(async () => {
    await cleanDatabase();

    // Register user to get an auth token
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Profile Owner',
        email: 'profile@example.com',
        password: 'SecurePass123'
      });
    authToken = res.body.token;
  });

  after(async () => {
    await closeConnections();
  });

  test('GET /api/v1/profile - fetches profile data', async () => {
    // 1. Initial fetch should return null profile
    const resInitial = await request(app)
      .get('/api/v1/profile')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    assert.strictEqual(resInitial.body.success, true);
    assert.strictEqual(resInitial.body.profile, null);

    // 2. Put a valid profile
    await request(app)
      .put('/api/v1/profile')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        dob: '1995-10-15',
        gender: 'Male',
        state: 'Karnataka',
        district: 'Bangalore',
        village_city: 'Bangalore City',
        occupation: 'Student',
        education: 'Undergraduate',
        annual_income: 350000,
        marital_status: 'Single',
        category: 'General',
        minority_status: false,
        disability_status: false,
        is_student: true,
        is_farmer: false,
        is_business_owner: false,
        bpl_apl_status: 'APL'
      })
      .expect(200);

    // 3. Fetch again (should be returned and match)
    const resAfter = await request(app)
      .get('/api/v1/profile')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    assert.strictEqual(resAfter.body.success, true);
    assert.ok(resAfter.body.profile);
    assert.strictEqual(resAfter.body.profile.state, 'Karnataka');
  });

  test('PUT /api/v1/profile - success and validations', async () => {
    // 1. Success case
    const updateRes = await request(app)
      .put('/api/v1/profile')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        dob: '1995-10-15',
        gender: 'Male',
        state: 'Karnataka',
        district: 'Bangalore',
        village_city: 'Bangalore City',
        occupation: 'Student',
        education: 'Undergraduate',
        annual_income: 350000,
        marital_status: 'Single',
        category: 'General',
        minority_status: false,
        disability_status: false,
        is_student: true,
        is_farmer: false,
        is_business_owner: false,
        bpl_apl_status: 'APL'
      })
      .expect(200);

    assert.strictEqual(updateRes.body.success, true);
    assert.strictEqual(updateRes.body.profile.state, 'Karnataka');

    // 2. Reject negative income validation
    await request(app)
      .put('/api/v1/profile')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        dob: '1995-10-15',
        gender: 'Male',
        state: 'Karnataka',
        district: 'Bangalore',
        village_city: 'Bangalore City',
        occupation: 'Student',
        education: 'Undergraduate',
        annual_income: -500, // Invalid negative value
        marital_status: 'Single',
        category: 'General',
        minority_status: false,
        disability_status: false,
        is_student: true,
        is_farmer: false,
        is_business_owner: false,
        bpl_apl_status: 'APL'
      })
      .expect(400);

    // 3. Reject invalid bpl_apl_status value
    await request(app)
      .put('/api/v1/profile')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        dob: '1995-10-15',
        gender: 'Male',
        state: 'Karnataka',
        district: 'Bangalore',
        village_city: 'Bangalore City',
        occupation: 'Student',
        education: 'Undergraduate',
        annual_income: 120000,
        marital_status: 'Single',
        category: 'General',
        minority_status: false,
        disability_status: false,
        is_student: true,
        is_farmer: false,
        is_business_owner: false,
        bpl_apl_status: 'INVALID_STATUS' // Invalid enumeration value
      })
      .expect(400);
  });
});
