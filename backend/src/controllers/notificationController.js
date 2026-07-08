const notificationService = require('../services/notificationService');

/**
 * @openapi
 * /api/v1/notifications:
 *   get:
 *     summary: Retrieve paginated notifications history
 *     description: Fetch notifications for the authenticated user, excluding scheduled and expired records.
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: Notifications list loaded
 */
async function getNotifications(req, res) {
  try {
    const limit = parseInt(req.query.limit, 10) || 20;
    const offset = parseInt(req.query.offset, 10) || 0;

    const data = await notificationService.getNotifications(req.user.id, limit, offset);

    return res.status(200).json({
      success: true,
      count: data.notifications.length,
      total: data.total,
      notifications: data.notifications,
    });
  } catch (error) {
    console.error('Get Notifications Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving notifications history.',
    });
  }
}

/**
 * @openapi
 * /api/v1/notifications/{id}/read:
 *   put:
 *     summary: Mark single notification as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Notification updated
 *       404:
 *         description: Notification not found
 */
async function markRead(req, res) {
  try {
    const { id } = req.params;
    const success = await notificationService.markAsRead(req.user.id, id);

    if (!success) {
      return res.status(404).json({
        success: false,
        message: 'Notification alert not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read successfully.',
    });
  } catch (error) {
    console.error('Mark Read Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error marking notification read.',
    });
  }
}

/**
 * @openapi
 * /api/v1/notifications/read-all:
 *   put:
 *     summary: Mark all notifications as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: All notifications marked read
 */
async function markAllRead(req, res) {
  try {
    const count = await notificationService.markAllAsRead(req.user.id);
    return res.status(200).json({
      success: true,
      message: 'All notifications marked read.',
      count,
    });
  } catch (error) {
    console.error('Mark All Read Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error marking notifications read.',
    });
  }
}

/**
 * @openapi
 * /api/v1/notifications/{id}:
 *   delete:
 *     summary: Delete notification record
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Notification deleted
 */
async function deleteNotification(req, res) {
  try {
    const { id } = req.params;
    const success = await notificationService.deleteNotification(req.user.id, id);

    if (!success) {
      return res.status(404).json({
        success: false,
        message: 'Notification alert not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Notification deleted successfully.',
    });
  } catch (error) {
    console.error('Delete Notification Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error deleting notification alert.',
    });
  }
}

/**
 * @openapi
 * /api/v1/notifications/preferences:
 *   get:
 *     summary: Get user notification preferences
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Preferences fetched
 */
async function getPreferences(req, res) {
  try {
    const prefs = await notificationService.getOrCreatePreferences(req.user.id);
    return res.status(200).json({
      success: true,
      preferences: prefs,
    });
  } catch (error) {
    console.error('Get Preferences Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error loading preferences settings.',
    });
  }
}

/**
 * @openapi
 * /api/v1/notifications/preferences:
 *   put:
 *     summary: Update user notification preferences
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               notify_new_matches:
 *                 type: boolean
 *               notify_scheme_updates:
 *                 type: boolean
 *               notify_closing_soon:
 *                 type: boolean
 *               notify_profile_reminders:
 *                 type: boolean
 *               notify_system:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Preferences updated
 */
async function updatePreferences(req, res) {
  try {
    const prefs = await notificationService.updatePreferences(req.user.id, req.body);
    return res.status(200).json({
      success: true,
      message: 'Notification preferences updated successfully.',
      preferences: prefs,
    });
  } catch (error) {
    console.error('Update Preferences Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating preferences.',
    });
  }
}

/**
 * @openapi
 * /api/v1/notifications/admin/analytics:
 *   get:
 *     summary: Retrieve administrative notifications metrics
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Analytics summaries loaded
 */
async function getAnalytics(req, res) {
  try {
    const stats = await notificationService.getAdminAnalytics();
    return res.status(200).json({
      success: true,
      analytics: stats,
    });
  } catch (error) {
    console.error('Get Analytics Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error compiling notifications metrics.',
    });
  }
}

module.exports = {
  getNotifications,
  markRead,
  markAllRead,
  deleteNotification,
  getPreferences,
  updatePreferences,
  getAnalytics,
};
