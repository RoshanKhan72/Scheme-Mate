const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { protect } = require('../middleware/authMiddleware');
const { validateProfile } = require('../middleware/validation');

// Secure profile routes using Bearer JWT authentication
router.get('/', protect, profileController.getProfile);
router.put('/', protect, validateProfile, profileController.updateProfile);

module.exports = router;
