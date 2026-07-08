const profileModel = require('../models/profileModel');
const schemeModel = require('../models/schemeModel');
const eligibilityEngine = require('../utils/eligibilityEngine');

/**
 * @openapi
 * /api/schemes/match:
 *   get:
 *     summary: Retrieve matched schemes for logged-in user
 *     description: Evaluate the authenticated user's profile against all schemes in the database.
 *     tags: [Eligibility Matching]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of schemes with resolved eligibility scores and status checks
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 schemes:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         format: uuid
 *                       name:
 *                         type: string
 *                       eligibilityResult:
 *                         type: object
 *                         properties:
 *                           status:
 *                             type: string
 *                             enum: [Eligible, Partially Eligible, Not Eligible, Unknown]
 *                           matchScore:
 *                             type: integer
 *                             example: 92
 *                           confidence:
 *                             type: integer
 *                             example: 100
 *                           checks:
 *                             type: array
 *                             items:
 *                               type: object
 *                               properties:
 *                                 ruleId:
 *                                   type: string
 *                                 passed:
 *                                   type: boolean
 *                                   nullable: true
 *                                 message:
 *                                   type: string
 *                           missingFields:
 *                             type: array
 *                             items:
 *                               type: string
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Server Error
 */
async function getMatchingSchemes(req, res) {
  try {
    // 1. Fetch current user's profile
    const profile = await profileModel.getProfileByUserId(req.user.id);

    // 2. Fetch all schemes from database
    const schemes = await schemeModel.getAllSchemes();

    // 3. Evaluate matching metrics on each scheme
    const matchedSchemes = schemes.map(scheme => {
      const eligibilityResult = eligibilityEngine.evaluateSchemeEligibility(profile, scheme);
      
      // Convert row to plain object to attach new property
      const schemeObj = { ...scheme };
      schemeObj.eligibilityResult = eligibilityResult;
      
      return schemeObj;
    });

    // 4. Sort results: Eligible -> Partially Eligible -> Unknown -> Not Eligible, ordered by matchScore descending
    const statusPriority = {
      'Eligible': 0,
      'Partially Eligible': 1,
      'Unknown': 2,
      'Not Eligible': 3
    };

    matchedSchemes.sort((a, b) => {
      const aPriority = statusPriority[a.eligibilityResult.status];
      const bPriority = statusPriority[b.eligibilityResult.status];
      
      if (aPriority !== bPriority) {
        return aPriority - bPriority;
      }
      
      return b.eligibilityResult.matchScore - a.eligibilityResult.matchScore;
    });

    return res.status(200).json({
      success: true,
      count: matchedSchemes.length,
      schemes: matchedSchemes,
    });
  } catch (error) {
    console.error('Get Matching Schemes Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error calculating rules matching engine.',
    });
  }
}

module.exports = {
  getMatchingSchemes,
};
