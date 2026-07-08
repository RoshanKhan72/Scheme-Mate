const { pool } = require('../config/db');

/**
 * Bookmark/Save a government scheme for a user
 * 
 * Executed as a transactional block to increment saves_count
 * 
 * @param {string} userId - User UUID
 * @param {string} schemeId - Scheme UUID
 * @param {string} [privateNote] - Optional initial private note
 */
async function saveScheme(userId, schemeId, privateNote = '') {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // 1. Insert save record
    const insertQuery = `
      INSERT INTO saved_schemes (user_id, scheme_id, private_note)
      VALUES ($1, $2, $3)
      ON CONFLICT (user_id, scheme_id) DO UPDATE 
      SET private_note = EXCLUDED.private_note, last_viewed_at = CURRENT_TIMESTAMP
      RETURNING *;
    `;
    const res = await client.query(insertQuery, [userId, schemeId, privateNote]);

    // 2. Increment saves_count in schemes
    await client.query(
      'UPDATE schemes SET saves_count = saves_count + 1 WHERE id = $1',
      [schemeId]
    );

    await client.query('COMMIT');
    return res.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Remove bookmark for a scheme
 * 
 * Executed as a transactional block to decrement saves_count
 */
async function unsaveScheme(userId, schemeId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Delete save record
    const deleteQuery = `
      DELETE FROM saved_schemes 
      WHERE user_id = $1 AND scheme_id = $2
      RETURNING *;
    `;
    const res = await client.query(deleteQuery, [userId, schemeId]);

    if (res.rowCount > 0) {
      // 2. Decrement saves_count in schemes (preventing negative values)
      await client.query(
        'UPDATE schemes SET saves_count = GREATEST(0, saves_count - 1) WHERE id = $1',
        [schemeId]
      );
    }

    await client.query('COMMIT');
    return res.rowCount > 0;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Retrieve all schemes saved by a user, joined with bookmark metadata
 */
async function getSavedSchemesByUserId(userId) {
  const query = `
    SELECT s.*, 
           ss.private_note, 
           ss.created_at AS saved_at, 
           ss.last_viewed_at
    FROM schemes s
    INNER JOIN saved_schemes ss ON s.id = ss.scheme_id
    WHERE ss.user_id = $1
    ORDER BY ss.created_at DESC;
  `;
  const res = await pool.query(query, [userId]);
  return res.rows;
}

/**
 * Retrieve metadata for a single saved scheme
 */
async function getSavedMetadata(userId, schemeId) {
  const query = `
    SELECT private_note, created_at AS saved_at, last_viewed_at
    FROM saved_schemes
    WHERE user_id = $1 AND scheme_id = $2;
  `;
  const res = await pool.query(query, [userId, schemeId]);
  return res.rows[0] || null;
}

/**
 * Update private note and bump last_viewed_at
 */
async function updateSavedMetadata(userId, schemeId, note) {
  const query = `
    UPDATE saved_schemes
    SET private_note = $1, last_viewed_at = CURRENT_TIMESTAMP
    WHERE user_id = $2 AND scheme_id = $3
    RETURNING private_note, created_at AS saved_at, last_viewed_at;
  `;
  const res = await pool.query(query, [note, userId, schemeId]);
  return res.rows[0] || null;
}

module.exports = {
  saveScheme,
  unsaveScheme,
  getSavedSchemesByUserId,
  getSavedMetadata,
  updateSavedMetadata,
};
