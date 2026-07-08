const express = require('express');
const router = express.Router();
const savedSchemeController = require('../controllers/savedSchemeController');
const { protect } = require('../middleware/authMiddleware');

// All saved routes are secured and require active token authorization
router.get('/', protect, savedSchemeController.getSaved);
router.get('/:schemeId', protect, savedSchemeController.getSavedById);
router.post('/:schemeId', protect, savedSchemeController.saveScheme);
router.put('/:schemeId', protect, savedSchemeController.updateSaved);
router.delete('/:schemeId', protect, savedSchemeController.unsaveScheme);

module.exports = router;
