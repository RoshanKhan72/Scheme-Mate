const profileModel = require('../models/profileModel');

/**
 * @openapi
 * /api/profile:
 *   get:
 *     summary: Get current user profile
 *     description: Retrieve the eligibility profile for the authenticated user.
 *     tags: [Profile]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile fetched successfully (may return null if profile not created yet)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 profile:
 *                   type: object
 *                   nullable: true
 *                   properties:
 *                     id:
 *                       type: string
 *                       format: uuid
 *                       example: a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d
 *                     user_id:
 *                       type: string
 *                       format: uuid
 *                       example: 4a3e7b1a-8c4b-4b2a-bf3b-9e32a67e8c1b
 *                     dob:
 *                       type: string
 *                       format: date
 *                       example: 1995-08-15
 *                     gender:
 *                       type: string
 *                       example: Male
 *                     state:
 *                       type: string
 *                       example: Karnataka
 *                     district:
 *                       type: string
 *                       example: Davanagere
 *                     taluk:
 *                       type: string
 *                       nullable: true
 *                       example: Harihara
 *                     village_city:
 *                       type: string
 *                       example: Harihara Town
 *                     occupation:
 *                       type: string
 *                       example: Student
 *                     education:
 *                       type: string
 *                       example: Undergraduate
 *                     annual_income:
 *                       type: number
 *                       example: 250000.00
 *                     marital_status:
 *                       type: string
 *                       example: Single
 *                     category:
 *                       type: string
 *                       example: OBC
 *                     minority_status:
 *                       type: boolean
 *                       example: false
 *                     disability_status:
 *                       type: boolean
 *                       example: false
 *                     is_student:
 *                       type: boolean
 *                       example: true
 *                     is_farmer:
 *                       type: boolean
 *                       example: false
 *                     is_business_owner:
 *                       type: boolean
 *                       example: false
 *                     bpl_apl_status:
 *                       type: string
 *                       example: APL
 *                     documents:
 *                       type: object
 *                       description: Checklist of user documents and expiry dates
 *                       example: { "Aadhaar": { "exists": true, "expiryDate": null }, "Income Certificate": { "exists": true, "expiryDate": "2029-03-31" } }
 *                     extra_eligibility:
 *                       type: object
 *                       example: {}
 *                     created_at:
 *                       type: string
 *                       format: date-time
 *                     updated_at:
 *                       type: string
 *                       format: date-time
 *       401:
 *         description: Unauthorized (missing or invalid token)
 *       500:
 *         description: Internal Server Error
 */
async function getProfile(req, res) {
  try {
    const profile = await profileModel.getProfileByUserId(req.user.id);
    return res.status(200).json({
      success: true,
      profile,
    });
  } catch (error) {
    console.error('Get Profile Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving eligibility profile.',
    });
  }
}

/**
 * @openapi
 * /api/profile:
 *   put:
 *     summary: Update or Create user profile
 *     description: Save demographic, economic, and document parameters for eligibility matching.
 *     tags: [Profile]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - dob
 *               - gender
 *               - state
 *               - district
 *               - village_city
 *               - occupation
 *               - education
 *               - annual_income
 *               - marital_status
 *               - category
 *             properties:
 *               dob:
 *                 type: string
 *                 format: date
 *                 description: Date of birth (must be in the past)
 *                 example: 1995-08-15
 *               gender:
 *                 type: string
 *                 example: Male
 *               state:
 *                 type: string
 *                 example: Karnataka
 *               district:
 *                 type: string
 *                 example: Davanagere
 *               taluk:
 *                 type: string
 *                 example: Harihara
 *               village_city:
 *                 type: string
 *                 example: Harihara Town
 *               occupation:
 *                 type: string
 *                 example: Student
 *               education:
 *                 type: string
 *                 example: Undergraduate
 *               annual_income:
 *                 type: number
 *                 description: Total annual family income
 *                 example: 250000
 *               marital_status:
 *                 type: string
 *                 example: Single
 *               category:
 *                 type: string
 *                 example: OBC
 *               minority_status:
 *                 type: boolean
 *                 example: false
 *               disability_status:
 *                 type: boolean
 *                 example: false
 *               is_student:
 *                 type: boolean
 *                 example: true
 *               is_farmer:
 *                 type: boolean
 *                 example: false
 *               is_business_owner:
 *                 type: boolean
 *                 example: false
 *               bpl_apl_status:
 *                 type: string
 *                 example: APL
 *               documents:
 *                 type: object
 *                 description: JSON mapping of document availability and optional expiry dates
 *                 example: { "Aadhaar": { "exists": true, "expiryDate": null }, "Income Certificate": { "exists": true, "expiryDate": "2029-03-31" } }
 *               extra_eligibility:
 *                 type: object
 *                 example: {}
 *     responses:
 *       200:
 *         description: Profile upserted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Profile updated successfully.
 *                 profile:
 *                   type: object
 *       400:
 *         description: Invalid parameters (DOB in future, negative income, or missing fields)
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Server Error
 */
async function updateProfile(req, res) {
  try {
    const {
      dob, gender, state, district, taluk, village_city,
      occupation, education, annual_income, marital_status, category,
      minority_status, disability_status, is_student, is_farmer,
      is_business_owner, bpl_apl_status, documents, extra_eligibility
    } = req.body;

    // 1. Core Parameter Validation
    if (!dob || !gender || !state || !district || !village_city ||
        !occupation || !education || annual_income === undefined ||
        !marital_status || !category) {
      return res.status(400).json({
        success: false,
        message: 'Please fill in all required profile fields.',
      });
    }

    // 2. Date of birth validation
    const parsedDob = new Date(dob);
    if (isNaN(parsedDob.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Please select a valid date of birth.',
      });
    }
    if (parsedDob >= new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Date of birth must be in the past.',
      });
    }

    // 3. Income validation
    const parsedIncome = parseFloat(annual_income);
    if (isNaN(parsedIncome) || parsedIncome < 0) {
      return res.status(400).json({
        success: false,
        message: 'Annual income must be a valid positive number.',
      });
    }

    // 4. Save to database (Upsert query handles insert or edit)
    const profile = await profileModel.upsertProfile(req.user.id, {
      dob, gender, state, district, taluk, village_city,
      occupation, education, annual_income: parsedIncome, marital_status, category,
      minority_status, disability_status, is_student, is_farmer,
      is_business_owner, bpl_apl_status, documents, extra_eligibility
    });

    // 5. Trigger event checks
    try {
      const notificationService = require('../services/notificationService');
      await notificationService.clearProfileIncompleteAlerts(req.user.id);
      
      const expectedDocs = ['Aadhaar', 'Income Certificate', 'Caste Certificate'];
      const profileDocs = profile.documents || {};
      const missingDocs = expectedDocs.filter(d => !profileDocs[d] || !profileDocs[d].exists);

      for (const doc of missingDocs) {
        await notificationService.triggerNotificationEvent(req.user.id, 'DOCUMENT_MISSING', { docName: doc });
      }
    } catch (e) {
      console.error('Failed to trigger profile notifications:', e);
    }

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      profile,
    });
  } catch (error) {
    console.error('Update Profile Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error saving profile parameters.',
    });
  }
}

module.exports = {
  getProfile,
  updateProfile,
};
