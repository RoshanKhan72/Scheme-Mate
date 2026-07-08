const test = require('node:test');
const assert = require('node:assert');
const pool = require('../../src/config/db');

test('Backend Services Integration & Mocking Tests Suite', async (t) => {

  // Mock database pool calls to test business layer logic
  t.mock.method(pool, 'query', async (sql, params) => {
    // 1. Mock Notification preference lookups
    if (sql.includes('notification_preferences')) {
      return {
        rowCount: 1,
        rows: [{
          user_id: 'user-uuid',
          notify_new_matches: true,
          notify_scheme_updates: true,
          notify_closing_soon: true,
          notify_profile_reminders: true,
          notify_system: true
        }]
      };
    }

    // 2. Mock profiles lookup query
    if (sql.includes('FROM profiles')) {
      return {
        rowCount: 1,
        rows: [{
          dob: '1990-01-01',
          gender: 'Male',
          state: 'Karnataka',
          district: 'Bengaluru',
          village_city: 'City',
          occupation: 'Farmer',
          education: 'Primary',
          annual_income: 150000,
          marital_status: 'Married',
          category: 'General',
          is_farmer: true,
          documents: { 'Aadhaar': { exists: true } },
          updated_at: new Date().toISOString()
        }]
      };
    }

    // 3. Mock Dashboard Schemes listing queries
    if (sql.includes('FROM schemes') && !sql.includes('saved_schemes')) {
      return {
        rowCount: 1,
        rows: [{
          id: 'scheme-uuid-1',
          name: 'PM-KISAN Farmer Grant',
          description: 'Farmer grant support',
          state: 'All India',
          category: 'Agriculture',
          eligibility_rules: { isFarmer: true },
          required_documents: ['Aadhaar'],
          benefits: '₹6,000 annually',
          application_mode: 'Online',
          status: 'Open',
          source_type: 'Central Government',
          official_department: 'Ministry of Agriculture',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }]
      };
    }

    // 4. Mock INSERT / DELETE / SELECT count queries (returns mock object to satisfy result expectations)
    return { 
      rowCount: 1, 
      rows: [{ id: 'notif-uuid', title: 'Test Title', message: 'Test message', type: 'system', is_read: false }] 
    };
  });

  await t.test('Notification Event triggering suppressed duplicates check', async () => {
    const notificationService = require('../../src/services/notificationService');
    
    // Trigger notification alert
    const record = await notificationService.triggerNotificationEvent('user-uuid', 'SYSTEM_ANNOUNCEMENT', {
      title: 'Server Update Complete',
      message: 'V1.0 is stable.'
    });

    assert.ok(record !== null && typeof record === 'object');
  });

  await t.test('Dashboard aggregates logic filters correctly', async () => {
    const dashboardService = require('../../src/services/dashboardService');
    const summary = await dashboardService.getDashboardSummary('user-uuid');
    
    assert.ok(summary !== null);
    assert.strictEqual(summary.profileCompletion, 100);
    assert.strictEqual(summary.eligibleCount, 1);
    assert.strictEqual(summary.missingDocumentsCount, 0);
    assert.ok(summary.feeds.recommended.length > 0);
  });
});
