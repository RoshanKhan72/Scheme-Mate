const { test, describe, beforeEach, after } = require('node:test');
const assert = require('node:assert');
const request = require('supertest');
const app = require('../../src/app');
const { cleanDatabase, closeConnections } = require('../helper');
const db = require('../../src/config/db');

describe('Notifications Integration Tests', () => {
  let authToken;
  let userId;

  beforeEach(async () => {
    await cleanDatabase();

    // 1. Register user
    const resUser = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Notification Receiver',
        email: 'notifications@example.com',
        password: 'SecurePass123'
      });
    authToken = resUser.body.token;
    userId = resUser.body.user.id;
  });

  after(async () => {
    await closeConnections();
  });

  test('Notification Preferences operations', async () => {
    // 1. Fetch preferences
    const getPrefs = await request(app)
      .get('/api/v1/notifications/preferences')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    assert.strictEqual(getPrefs.body.success, true);
    assert.ok(getPrefs.body.preferences);

    // 2. Update preferences
    const updatePrefs = await request(app)
      .put('/api/v1/notifications/preferences')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        notify_new_matches: false,
        notify_scheme_updates: true,
        notify_closing_soon: true,
        notify_profile_reminders: false,
        notify_system: true
      })
      .expect(200);

    assert.strictEqual(updatePrefs.body.success, true);
    assert.strictEqual(updatePrefs.body.preferences.notify_scheme_updates, true);
    assert.strictEqual(updatePrefs.body.preferences.notify_new_matches, false);
  });

  test('Notification CRUD read and delete operations', async () => {
    // 1. Insert a mock notification into clean test DB using allowed type 'saved_scheme'
    const resNotify = await db.query(`
      INSERT INTO notifications (
        user_id, title, message, type, priority
      ) VALUES (
        $1, 'Scheme Updates', 'Your saved scheme has been edited.', 'saved_scheme', 'High'
      ) RETURNING id
    `, [userId]);
    const notificationId = resNotify.rows[0].id;

    // 2. Fetch list of notifications
    const getList = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    assert.strictEqual(getList.body.success, true);
    assert.strictEqual(getList.body.notifications.length, 1);
    assert.strictEqual(getList.body.notifications[0].id, notificationId);
    assert.strictEqual(getList.body.notifications[0].is_read, false);

    // 3. Mark notification as read
    await request(app)
      .put(`/api/v1/notifications/${notificationId}/read`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    // Verify it is marked as read
    const getListRead = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);
    assert.strictEqual(getListRead.body.notifications[0].is_read, true);

    // 4. Delete the notification
    await request(app)
      .delete(`/api/v1/notifications/${notificationId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    // Verify list is empty
    const getListFinal = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);
    assert.strictEqual(getListFinal.body.notifications.length, 0);
  });
});
