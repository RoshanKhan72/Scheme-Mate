const savedSchemeModel = require('../models/savedSchemeModel');
const profileModel = require('../models/profileModel');
const eligibilityEngine = require('../utils/eligibilityEngine');

/**
 * @openapi
 * /api/v1/saved:
 *   get:
 *     summary: Retrieve list of saved schemes with eligibility results
 *     description: Fetch all bookmarks saved by the authenticated user. Eligibility matching runs in memory.
 *     tags: [Saved Schemes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Saved schemes list loaded
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
 *                       name:
 *                         type: string
 *                       private_note:
 *                         type: string
 *                       saved_at:
 *                         type: string
 *                         format: date-time
 *                       last_viewed_at:
 *                         type: string
 *                         format: date-time
 *                       eligibilityResult:
 *                         type: object
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Server Error
 */
async function getSaved(req, res) {
  try {
    const profile = await profileModel.getProfileByUserId(req.user.id);
    const saved = await savedSchemeModel.getSavedSchemesByUserId(req.user.id);

    // Apply rule engine evaluation in memory for consistency
    const formattedSaved = saved.map(scheme => {
      const eligibilityResult = eligibilityEngine.evaluateSchemeEligibility(profile, scheme);
      return {
        ...scheme,
        eligibilityResult,
      };
    });

    return res.status(200).json({
      success: true,
      count: formattedSaved.length,
      schemes: formattedSaved,
    });
  } catch (error) {
    console.error('Get Saved Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving saved bookmarks list.',
    });
  }
}

/**
 * @openapi
 * /api/v1/saved/{schemeId}:
 *   get:
 *     summary: Retrieve single bookmark metadata
 *     description: Returns private notes and timestamps for a specific saved scheme.
 *     tags: [Saved Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: schemeId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Bookmark metadata fetched
 *       404:
 *         description: Bookmark not found
 *       500:
 *         description: Server Error
 */
async function getSavedById(req, res) {
  try {
    const { schemeId } = req.params;
    const metadata = await savedSchemeModel.getSavedMetadata(req.user.id, schemeId);

    if (!metadata) {
      return res.status(404).json({
        success: false,
        message: 'Saved bookmark record not found for this scheme.',
      });
    }

    return res.status(200).json({
      success: true,
      saved: metadata,
    });
  } catch (error) {
    console.error('Get Saved By ID Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error looking up bookmark metadata.',
    });
  }
}

/**
 * @openapi
 * /api/v1/saved/{schemeId}:
 *   post:
 *     summary: Save/Bookmark a scheme
 *     description: Saves a government scheme to the user's bookmarks. Accepts an optional private note.
 *     tags: [Saved Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: schemeId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               note:
 *                 type: string
 *                 example: Ask father about eligibility.
 *     responses:
 *       200:
 *         description: Scheme saved successfully
 *       500:
 *         description: Server Error
 */
async function saveScheme(req, res) {
  try {
    const { schemeId } = req.params;
    const { note } = req.body;

    const record = await savedSchemeModel.saveScheme(req.user.id, schemeId, note || '');

    return res.status(200).json({
      success: true,
      message: 'Government scheme saved to bookmarks successfully.',
      saved: record,
    });
  } catch (error) {
    console.error('Save Scheme Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error during scheme bookmarking.',
    });
  }
}

/**
 * @openapi
 * /api/v1/saved/{schemeId}:
 *   put:
 *     summary: Update saved scheme note
 *     description: Modify private note contents and updates last_viewed_at.
 *     tags: [Saved Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: schemeId
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
 *               - note
 *             properties:
 *               note:
 *                 type: string
 *     responses:
 *       200:
 *         description: Bookmark updated
 *       404:
 *         description: Bookmark not found
 *       500:
 *         description: Server Error
 */
async function updateSaved(req, res) {
  try {
    const { schemeId } = req.params;
    const { note } = req.body;

    if (note === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Please provide note value to update.',
      });
    }

    const updated = await savedSchemeModel.updateSavedMetadata(req.user.id, schemeId, note);

    if (!updated) {
      return res.status(404).json({
        success: false,
        message: 'Bookmark record not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Saved bookmark note updated successfully.',
      saved: updated,
    });
  } catch (error) {
    console.error('Update Saved Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating bookmark parameters.',
    });
  }
}

/**
 * @openapi
 * /api/v1/saved/{schemeId}:
 *   delete:
 *     summary: Remove bookmark
 *     description: Unbookmark/remove a scheme from the user's saved list. Decrements saves_count.
 *     tags: [Saved Schemes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: schemeId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Bookmark removed
 *       404:
 *         description: Bookmark not found
 *       500:
 *         description: Server Error
 */
async function unsaveScheme(req, res) {
  try {
    const { schemeId } = req.params;
    const removed = await savedSchemeModel.unsaveScheme(req.user.id, schemeId);

    if (!removed) {
      return res.status(404).json({
        success: false,
        message: 'Saved bookmark record not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Government scheme removed from saved list.',
    });
  } catch (error) {
    console.error('Unsave Scheme Controller Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error removing scheme bookmark.',
    });
  }
}

module.exports = {
  getSaved,
  getSavedById,
  saveScheme,
  updateSaved,
  unsaveScheme,
};
