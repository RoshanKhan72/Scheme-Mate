const pool = require('../config/db');

/**
 * Persist user feedback or bug report
 */
async function createFeedback(userId, { screen, type, details, targetId = null }) {
  const query = `
    INSERT INTO feedback (user_id, screen, type, details, target_id)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *;
  `;
  const res = await pool.query(query, [userId, screen, type, details, targetId]);
  return res.rows[0];
}

module.exports = {
  createFeedback,
};
