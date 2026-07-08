const feedbackModel = require('../models/feedbackModel');
const logger = require('../utils/logger');

/**
 * @openapi
 * /api/v1/feedback:
 *   post:
 *     summary: Submit feedback or report bugs
 *     description: Submit user reports regarding specific screens, schemes data or platform bugs.
 *     tags: [Feedback]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - screen
 *               - type
 *               - details
 *             properties:
 *               screen:
 *                 type: string
 *                 example: Scheme Detail Screen
 *               type:
 *                 type: string
 *                 enum: [incorrect_scheme, bug, feature_request, missing_scheme]
 *                 example: bug
 *               details:
 *                 type: string
 *                 example: The eligibility badge color did not update immediately after updating my age in profile.
 *               targetId:
 *                 type: string
 *                 format: uuid
 *                 nullable: true
 *                 example: a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d
 *     responses:
 *       201:
 *         description: Feedback recorded successfully
 *       400:
 *         description: Missing fields
 *       500:
 *         description: Server Error
 */
async function submitFeedback(req, res) {
  try {
    const { screen, type, details, targetId } = req.body;

    if (!screen || !type || !details) {
      return res.status(400).json({
        success: false,
        message: 'Please provide screen name, feedback type, and details description.',
      });
    }

    const recorded = await feedbackModel.createFeedback(req.user.id, {
      screen,
      type,
      details,
      targetId,
    });

    // Logging event via structured logger (as requested!)
    logger.info('User feedback submitted successfully', {
      feedbackId: recorded.id,
      userId: req.user.id,
      screen,
      type,
    });

    return res.status(201).json({
      success: true,
      message: 'Thank you for your feedback! It has been recorded successfully.',
      feedback: recorded,
    });
  } catch (error) {
    logger.error('Failed to submit user feedback', error, { userId: req.user.id });
    return res.status(500).json({
      success: false,
      message: 'Server error processing feedback submission.',
    });
  }
}

module.exports = {
  submitFeedback,
};
