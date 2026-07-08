const express = require('express');
const router = express.Router();
const schemeController = require('../controllers/schemeController');
const eligibilityController = require('../controllers/eligibilityController');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');

// Public route endpoints (accessible without logging in)
router.get('/', schemeController.getAllSchemes);

// Secured eligibility matching route (requires token, must precede parameterized details route)
router.get('/match', protect, eligibilityController.getMatchingSchemes);

// Parameterized detail lookup (public)
router.get('/:id', schemeController.getSchemeById);

// Guarded administrative CRUD routes (admin JWT required)
router.post('/', protect, adminOnly, schemeController.createScheme);
router.put('/:id', protect, adminOnly, schemeController.updateScheme);
router.delete('/:id', protect, adminOnly, schemeController.deleteScheme);

module.exports = router;
