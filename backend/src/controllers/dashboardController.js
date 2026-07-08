const dashboardService = require('../services/dashboardService');

/**
 * @openapi
 * /api/dashboard:
 *   get:
 *     summary: Retrieve personalized dashboard indicators and feeds
 *     description: Fetches dynamic metrics (completion score, counts, missing document tags) and lightweight recommended/trending feeds.
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard statistics and feed slices compiled successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 dashboard:
 *                   type: object
 *                   properties:
 *                     profileCompletion:
 *                       type: integer
 *                     lastUpdated:
 *                       type: string
 *                       format: date-time
 *                     eligibleCount:
 *                       type: integer
 *                     partiallyEligibleCount:
 *                       type: integer
 *                     missingDocumentsCount:
 *                       type: integer
 *                     missingDocuments:
 *                       type: array
 *                       items:
 *                         type: string
 *                     feeds:
 *                       type: object
 *                       properties:
 *                         recommended:
 *                           type: array
 *                         newSchemes:
 *                           type: array
 *                         trending:
 *                           type: array
 *                         closingSoon:
 *                           type: array
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Server Error
 */
async function getDashboardSummary(req, res) {
  try {
    const data = await dashboardService.getDashboardSummary(req.user.id);
    
    return res.status(200).json({
      success: true,
      dashboard: data,
    });
  } catch (error) {
    console.error('Get Dashboard Summary Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error loading personalized dashboard summaries.',
    });
  }
}

module.exports = {
  getDashboardSummary,
};
