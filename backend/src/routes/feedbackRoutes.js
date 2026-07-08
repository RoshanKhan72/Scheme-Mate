const express = require('express');
const router = express.Router();
const feedbackController = require('../controllers/feedbackController');
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, feedbackController.submitFeedback);

module.exports = router;
