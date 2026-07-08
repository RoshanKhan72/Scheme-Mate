const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { protect } = require('../middleware/authMiddleware');

// Dashboard endpoints (fully protected by authentication layer)
router.get('/', protect, dashboardController.getDashboardSummary);

module.exports = router;
