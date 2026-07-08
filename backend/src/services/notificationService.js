const pool = require('../config/db');

/**
 * Ensures user has a preferences record, returning it.
 */
async function getOrCreatePreferences(userId) {
  const selectQuery = 'SELECT * FROM notification_preferences WHERE user_id = $1';
  const res = await pool.query(selectQuery, [userId]);
  
  if (res.rowCount > 0) {
    return res.rows[0];
  }

  const insertQuery = `
    INSERT INTO notification_preferences (user_id) 
    VALUES ($1) 
    ON CONFLICT (user_id) DO NOTHING
    RETURNING *;
  `;
  const insertRes = await pool.query(insertQuery, [userId]);
  return insertRes.rows[0] || (await pool.query(selectQuery, [userId])).rows[0];
}

/**
 * Update user preferences parameters
 */
async function updatePreferences(userId, prefs) {
  const current = await getOrCreatePreferences(userId);
  
  const notifyNewMatches = prefs.notify_new_matches !== undefined ? prefs.notify_new_matches : current.notify_new_matches;
  const notifySchemeUpdates = prefs.notify_scheme_updates !== undefined ? prefs.notify_scheme_updates : current.notify_scheme_updates;
  const notifyClosingSoon = prefs.notify_closing_soon !== undefined ? prefs.notify_closing_soon : current.notify_closing_soon;
  const notifyProfileReminders = prefs.notify_profile_reminders !== undefined ? prefs.notify_profile_reminders : current.notify_profile_reminders;
  const notifySystem = prefs.notify_system !== undefined ? prefs.notify_system : current.notify_system;

  const query = `
    UPDATE notification_preferences
    SET notify_new_matches = $1,
        notify_scheme_updates = $2,
        notify_closing_soon = $3,
        notify_profile_reminders = $4,
        notify_system = $5,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = $6
    RETURNING *;
  `;
  const res = await pool.query(query, [
    notifyNewMatches,
    notifySchemeUpdates,
    notifyClosingSoon,
    notifyProfileReminders,
    notifySystem,
    userId
  ]);
  return res.rows[0];
}

/**
 * Core event routing mechanism decoupling emitters from database alert creation
 */
async function triggerNotificationEvent(userId, eventType, data = {}) {
  const prefs = await getOrCreatePreferences(userId);

  let title = '';
  let message = '';
  let type = '';
  let priority = 'Medium';
  let targetType = 'none';
  let targetId = null;
  let expiresAt = null;
  let scheduledAt = data.scheduledAt ? new Date(data.scheduledAt) : new Date();

  // 1. Process Event specifications
  switch (eventType) {
    case 'SCHEME_MATCH_FOUND':
      if (!prefs.notify_new_matches) return null;
      title = 'New Match Found';
      message = `New matching scheme found: ${data.schemeName}. Complete your application today!`;
      type = 'eligibility';
      priority = 'High';
      targetType = 'scheme';
      targetId = data.schemeId;
      if (data.endDate) expiresAt = new Date(data.endDate);
      break;

    case 'SAVED_SCHEME_CLOSING':
      if (!prefs.notify_closing_soon) return null;
      title = 'Deadline Reminder';
      message = `Saved scheme '${data.schemeName}' closes in ${data.daysLeft} days!`;
      type = 'saved_scheme';
      priority = 'Critical';
      targetType = 'scheme';
      targetId = data.schemeId;
      if (data.endDate) expiresAt = new Date(data.endDate);
      break;

    case 'SAVED_SCHEME_UPDATED':
      if (!prefs.notify_scheme_updates) return null;
      title = 'Scheme Updated';
      message = `Saved scheme '${data.schemeName}' was updated to Version ${data.versionNumber}. Check out what changed.`;
      type = 'saved_scheme';
      priority = 'Medium';
      targetType = 'scheme';
      targetId = data.schemeId;
      break;

    case 'PROFILE_INCOMPLETE':
      if (!prefs.notify_profile_reminders) return null;
      title = 'Complete Profile';
      message = `Complete your socioeconomic profile details (currently at ${data.completionScore}%) to verify match eligibility scores.`;
      type = 'profile';
      priority = 'Medium';
      targetType = 'profile';
      break;

    case 'DOCUMENT_MISSING':
      if (!prefs.notify_profile_reminders) return null;
      title = 'Missing Document Alert';
      message = `Submit missing document '${data.docName}' to verify matching eligibility criteria.`;
      type = 'profile';
      priority = 'High';
      targetType = 'profile';
      break;

    case 'SYSTEM_ANNOUNCEMENT':
      if (!prefs.notify_system) return null;
      title = data.title || 'System Announcement';
      message = data.message || 'System update registered.';
      type = 'system';
      priority = data.priority || 'Medium';
      break;

    default:
      console.warn(`Unregistered notification event type received: ${eventType}`);
      return null;
  }

  // 2. Prevent Duplicates (delete previous unread matching alerts)
  const deleteDupQuery = `
    DELETE FROM notifications
    WHERE user_id = $1 
      AND type = $2 
      AND target_type = $3 
      AND (target_id = $4 OR (target_id IS NULL AND $4 IS NULL))
      AND is_read = false;
  `;
  await pool.query(deleteDupQuery, [userId, type, targetType, targetId]);

  // 3. Create Notification
  const insertQuery = `
    INSERT INTO notifications (user_id, title, message, type, priority, target_type, target_id, scheduled_at, expires_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    RETURNING *;
  `;
  const res = await pool.query(insertQuery, [
    userId,
    title,
    message,
    type,
    priority,
    targetType,
    targetId,
    scheduledAt,
    expiresAt
  ]);

  return res.rows[0];
}

/**
 * Clean up/expire notifications that are completed
 * e.g., if a user completes their profile, we clear PROFILE_INCOMPLETE
 */
async function clearProfileIncompleteAlerts(userId) {
  const query = `
    DELETE FROM notifications
    WHERE user_id = $1 AND type = 'profile' AND is_read = false;
  `;
  await pool.query(query, [userId]);
}

/**
 * Fetch notifications list support page paginations
 */
async function getNotifications(userId, limit = 20, offset = 0) {
  const query = `
    SELECT * FROM notifications
    WHERE user_id = $1
      AND (scheduled_at <= NOW())
      AND (expires_at IS NULL OR expires_at > NOW())
    ORDER BY created_at DESC
    LIMIT $2 OFFSET $3;
  `;
  const countQuery = `
    SELECT COUNT(*) FROM notifications
    WHERE user_id = $1
      AND (scheduled_at <= NOW())
      AND (expires_at IS NULL OR expires_at > NOW());
  `;
  const res = await pool.query(query, [userId, limit, offset]);
  const countRes = await pool.query(countQuery, [userId]);
  
  return {
    notifications: res.rows,
    total: parseInt(countRes.rows[0].count, 10),
  };
}

/**
 * Mark a single notification read
 */
async function markAsRead(userId, notificationId) {
  const query = `
    UPDATE notifications
    SET is_read = true
    WHERE id = $1 AND user_id = $2
    RETURNING *;
  `;
  const res = await pool.query(query, [notificationId, userId]);
  return res.rowCount > 0;
}

/**
 * Mark all notifications read
 */
async function markAllAsRead(userId) {
  const query = `
    UPDATE notifications
    SET is_read = true
    WHERE user_id = $1 AND is_read = false;
  `;
  const res = await pool.query(query, [userId]);
  return res.rowCount;
}

/**
 * Delete notification
 */
async function deleteNotification(userId, notificationId) {
  const query = `
    DELETE FROM notifications
    WHERE id = $1 AND user_id = $2;
  `;
  const res = await pool.query(query, [notificationId, userId]);
  return res.rowCount > 0;
}

/**
 * Retrieve admin metrics overview logs
 */
async function getAdminAnalytics() {
  const totalCreatedQuery = 'SELECT COUNT(*) FROM notifications';
  const readQuery = 'SELECT COUNT(*) FROM notifications WHERE is_read = true';
  const typeQuery = 'SELECT type, COUNT(*) FROM notifications GROUP BY type';
  const priorityQuery = 'SELECT priority, COUNT(*) FROM notifications GROUP BY priority';

  const [totalRes, readRes, typeRes, priorityRes] = await Promise.all([
    pool.query(totalCreatedQuery),
    pool.query(readQuery),
    pool.query(typeQuery),
    pool.query(priorityQuery),
  ]);

  const total = parseInt(totalRes.rows[0].count, 10);
  const read = parseInt(readRes.rows[0].count, 10);

  return {
    totalCreated: total,
    totalRead: read,
    readRate: total > 0 ? (read / total) * 100 : 0,
    byType: typeRes.rows.reduce((acc, row) => {
      acc[row.type] = parseInt(row.count, 10);
      return acc;
    }, {}),
    byPriority: priorityRes.rows.reduce((acc, row) => {
      acc[row.priority] = parseInt(row.count, 10);
      return acc;
    }, {}),
  };
}

module.exports = {
  getOrCreatePreferences,
  updatePreferences,
  triggerNotificationEvent,
  clearProfileIncompleteAlerts,
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getAdminAnalytics,
};
