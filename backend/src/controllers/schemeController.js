const schemeModel = require('../models/schemeModel');
const logger = require('../utils/logger');

/**
 * @openapi
 * /api/schemes:
 *   get:
 *     summary: Retrieve list of government schemes
 *     description: Fetch schemes matching optional keywords, state limits, categories, and beneficiary types.
 *     tags: [Schemes]
 *     parameters:
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Keyword for full-text search across Name, Description, Benefits, and Department.
 *       - in: query
 *         name: state
 *         schema:
 *           type: string
 *         description: State filter. Selecting a state returns that state's schemes plus 'All India' schemes.
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Category filter (e.g. Education, Agriculture, Welfare).
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [Upcoming, Open, Closed, Suspended, Archived]
 *         description: Scheme availability status.
 *       - in: query
 *         name: beneficiaryType
 *         schema:
 *           type: string
 *         description: Match specific beneficiary profiles (e.g. Student, Farmer, Woman).
 *     responses:
 *       200:
 *         description: List of matching schemes retrieved successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 count:
 *                   type: integer
 *                   example: 3
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
 *                       description:
 *                         type: string
 *                       state:
 *                         type: string
 *                       category:
 *                         type: string
 *                       eligibility_rules:
 *                         type: object
 *                       required_documents:
 *                         type: array
 *                         items:
 *                           type: string
 *                       benefits:
 *                         type: string
 *                       official_website:
 *                         type: string
 *                       application_link:
 *                         type: string
 *                       pdf_notification_link:
 *                         type: string
 *                       application_mode:
 *                         type: string
 *                       status:
 *                         type: string
 *                       source_type:
 *                         type: string
 *                       official_department:
 *                         type: string
 *                       last_verified_date:
 *                         type: string
 *                         format: date
 *                       views_count:
 *                         type: integer
 *                       saves_count:
 *                         type: integer
 *                       beneficiary_types:
 *                         type: array
 *                         items:
 *                           type: string
 *                       tags:
 *                         type: array
 *                         items:
 *                           type: string
 *                       version_number:
 *                         type: integer
 *                       created_at:
 *                         type: string
 *                         format: date-time
 *                       updated_at:
 *                         type: string
 *                         format: date-time
 *       500:
 *         description: Internal Server Error
 */
async function getAllSchemes(req, res) {
  try {
    const { search, state, category, status, beneficiaryType } = req.query;
    
    const schemes = await schemeModel.getAllSchemes({
      search: search || '',
      state: state || '',
      category: category || '',
      status: status || '',
      beneficiaryType: beneficiaryType || '',
    });

    return res.status(200).json({
      success: true,
      count: schemes.length,
      schemes,
    });
  } catch (error) {
    console.error('Get All Schemes Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving schemes database.',
    });
  }
}

/**
 * @openapi
 * /api/schemes/{id}:
 *   get:
 *     summary: Retrieve single scheme details
 *     description: Fetch detailed parameters of a scheme. Increments views count on call.
 *     tags: [Schemes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Scheme UUID
 *     responses:
 *       200:
 *         description: Scheme details fetched
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 scheme:
 *                   type: object
 *       404:
 *         description: Scheme not found
 *       500:
 *         description: Server Error
 */
async function getSchemeById(req, res) {
  try {
    const { id } = req.params;
    const scheme = await schemeModel.getSchemeById(id);

    if (!scheme) {
      return res.status(404).json({
        success: false,
        message: 'Government scheme not found.',
      });
    }

    // Fire-and-forget views count increment (async)
    schemeModel.incrementViews(id).catch(err => {
      console.error('Views increment failed for scheme:', id, err.message);
    });

    // Manually increment views count locally for immediate API reflection
    scheme.views_count += 1;

    return res.status(200).json({
      success: true,
      scheme,
    });
  } catch (error) {
    console.error('Get Scheme By ID Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving scheme details.',
    });
  }
}

/**
 * @openapi
 * /api/schemes:
 *   post:
 *     summary: Create a new government scheme
 *     description: Restricted admin route to add a scheme. Automatically stores initial version history.
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *               - state
 *               - category
 *               - benefits
 *               - source_type
 *               - official_department
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               state:
 *                 type: string
 *               category:
 *                 type: string
 *               eligibility_rules:
 *                 type: object
 *               required_documents:
 *                 type: array
 *                 items:
 *                   type: string
 *               benefits:
 *                 type: string
 *               official_website:
 *                 type: string
 *               application_link:
 *                 type: string
 *               pdf_notification_link:
 *                 type: string
 *               application_mode:
 *                 type: string
 *                 enum: [Online, Offline, Both]
 *               status:
 *                 type: string
 *                 enum: [Upcoming, Open, Closed, Suspended, Archived]
 *               source_type:
 *                 type: string
 *               official_department:
 *                 type: string
 *               last_verified_date:
 *                 type: string
 *                 format: date
 *               start_date:
 *                 type: string
 *                 format: date
 *               end_date:
 *                 type: string
 *                 format: date
 *               beneficiary_types:
 *                 type: array
 *                 items:
 *                   type: string
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Scheme created successfully
 *       400:
 *         description: Missing fields
 *       403:
 *         description: Forbidden (Admin only)
 *       500:
 *         description: Server Error
 */
async function createScheme(req, res) {
  try {
    const {
      name, description, state, category, eligibility_rules, required_documents,
      benefits, official_website, application_link, pdf_notification_link,
      application_mode, status, source_type, official_department,
      last_verified_date, start_date, end_date, beneficiary_types, tags
    } = req.body;

    if (!name || !description || !state || !category || !benefits || 
        !source_type || !official_department) {
      return res.status(400).json({
        success: false,
        message: 'Please fill in all core required fields (Name, Description, State, Category, Benefits, Source Type, Department).',
      });
    }

    const created = await schemeModel.createScheme(req.user.id, {
      name, description, state, category, eligibility_rules, required_documents,
      benefits, official_website, application_link, pdf_notification_link,
      application_mode, status, source_type, official_department,
      last_verified_date: last_verified_date || new Date().toISOString().substring(0, 10),
      start_date, end_date, beneficiary_types, tags
    });

    logger.info('Admin created scheme', { adminId: req.user.id, schemeId: created.id, schemeName: name });

    return res.status(201).json({
      success: true,
      message: 'Government scheme added successfully.',
      scheme: created,
    });
  } catch (error) {
    console.error('Create Scheme Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error during scheme creation.',
    });
  }
}

/**
 * @openapi
 * /api/schemes/{id}:
 *   put:
 *     summary: Update an existing government scheme
 *     description: Restricted admin route to update scheme. Automatically saves a history version record.
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *               - state
 *               - category
 *               - benefits
 *               - change_summary
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               state:
 *                 type: string
 *               category:
 *                 type: string
 *               eligibility_rules:
 *                 type: object
 *               required_documents:
 *                 type: array
 *                 items:
 *                   type: string
 *               benefits:
 *                 type: string
 *               change_summary:
 *                 type: string
 *                 description: Brief explanation of updates for version history record
 *                 example: Updated maximum household income thresholds
 *     responses:
 *       200:
 *         description: Scheme updated successfully
 *       404:
 *         description: Scheme not found
 *       403:
 *         description: Forbidden (Admin only)
 *       500:
 *         description: Server Error
 */
async function updateScheme(req, res) {
  try {
    const { id } = req.params;
    const {
      name, description, state, category, eligibility_rules, required_documents,
      benefits, official_website, application_link, pdf_notification_link,
      application_mode, status, source_type, official_department,
      last_verified_date, start_date, end_date, beneficiary_types, tags,
      change_summary
    } = req.body;

    if (!name || !description || !state || !category || !benefits || !change_summary) {
      return res.status(400).json({
        success: false,
        message: 'Please provide required core updates and a change summary for history logs.',
      });
    }

    const updated = await schemeModel.updateScheme(req.user.id, id, {
      name, description, state, category, eligibility_rules, required_documents,
      benefits, official_website, application_link, pdf_notification_link,
      application_mode, status, source_type, official_department,
      last_verified_date: last_verified_date || new Date().toISOString().substring(0, 10),
      start_date, end_date, beneficiary_types, tags,
      change_summary
    });

    // Trigger SAVED_SCHEME_UPDATED event for users who bookmarked it
    try {
      const pool = require('../config/db');
      const notificationService = require('../services/notificationService');
      const bookmarks = await pool.query('SELECT DISTINCT user_id FROM saved_schemes WHERE scheme_id = $1', [id]);
      
      for (const row of bookmarks.rows) {
        await notificationService.triggerNotificationEvent(row.user_id, 'SAVED_SCHEME_UPDATED', {
          schemeId: id,
          schemeName: name,
          versionNumber: updated.version_number,
        });
      }
    } catch (e) {
      console.error('Failed to trigger saved scheme update notifications:', e);
    }

    logger.info('Admin updated scheme', { adminId: req.user.id, schemeId: id, schemeName: name, version: updated.version_number });

    return res.status(200).json({
      success: true,
      message: 'Government scheme updated successfully.',
      scheme: updated,
    });
  } catch (error) {
    console.error('Update Scheme Error:', error);
    if (error.message === 'Scheme not found') {
      return res.status(404).json({ success: false, message: 'Scheme not found' });
    }
    return res.status(500).json({
      success: false,
      message: 'Server error updating scheme details.',
    });
  }
}

/**
 * @openapi
 * /api/schemes/{id}:
 *   delete:
 *     summary: Delete a government scheme
 *     description: Restricted admin route to permanently delete a scheme.
 *     tags: [Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Scheme deleted
 *       404:
 *         description: Scheme not found
 *       500:
 *         description: Server Error
 */
async function deleteScheme(req, res) {
  try {
    const { id } = req.params;
    const deleted = await schemeModel.deleteScheme(id);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: 'Scheme not found.',
      });
    }

    logger.info('Admin deleted scheme', { adminId: req.user.id, schemeId: id });

    return res.status(200).json({
      success: true,
      message: 'Government scheme deleted successfully.',
    });
  } catch (error) {
    console.error('Delete Scheme Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error during scheme deletion.',
    });
  }
}

module.exports = {
  getAllSchemes,
  getSchemeById,
  createScheme,
  updateScheme,
  deleteScheme,
};
