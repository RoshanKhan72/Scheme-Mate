const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');

// Secure all routes under protect middleware
router.get('/', protect, notificationController.getNotifications);
router.get('/preferences', protect, notificationController.getPreferences);
router.put('/preferences', protect, notificationController.updatePreferences);
router.put('/read-all', protect, notificationController.markAllRead);
router.put('/:id/read', protect, notificationController.markRead);
router.delete('/:id', protect, notificationController.deleteNotification);

// Admin analytics route guarded by admin privileges
router.get('/admin/analytics', protect, adminOnly, notificationController.getAnalytics);

module.exports = router;
