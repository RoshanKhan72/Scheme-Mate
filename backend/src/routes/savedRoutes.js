const express = require('express');
const router = express.Router();
const savedSchemeController = require('../controllers/savedSchemeController');
const { protect } = require('../middleware/authMiddleware');
const { validateParamsUUID } = require('../middleware/validation');

// All saved routes are secured and require active token authorization
router.get('/', protect, savedSchemeController.getSaved);
router.get('/:schemeId', protect, validateParamsUUID('schemeId'), savedSchemeController.getSavedById);
router.post('/:schemeId', protect, validateParamsUUID('schemeId'), savedSchemeController.saveScheme);
router.put('/:schemeId', protect, validateParamsUUID('schemeId'), savedSchemeController.updateSaved);
router.delete('/:schemeId', protect, validateParamsUUID('schemeId'), savedSchemeController.unsaveScheme);

module.exports = router;
