const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { protect } = require('../middleware/authMiddleware');

// Secure profile routes using Bearer JWT authentication
router.get('/', protect, profileController.getProfile);
router.put('/', protect, profileController.updateProfile);

module.exports = router;
