const db = require('../config/db');

/**
 * Fetch schemes with dynamic filtering, search, and ordering
 */
async function getAllSchemes(filters = {}) {
  const { search, state, category, status, beneficiaryType } = filters;
  
  let queryText = 'SELECT * FROM schemes WHERE 1=1';
  const values = [];

  if (search && search.trim().isNotEmpty) {
    // Add full-text search condition
    values.push(search.trim());
    queryText += ` AND to_tsvector('english', name || ' ' || description || ' ' || benefits || ' ' || official_department) @@ plainto_tsquery('english', $${values.length})`;
  }

  if (state && state !== 'All India') {
    values.push(state);
    // Return either 'All India' (central) or state-specific schemes
    queryText += ` AND (state = $${values.length} OR state = 'All India')`;
  } else if (state === 'All India') {
    queryText += " AND state = 'All India'";
  }

  if (category && category !== 'All') {
    values.push(category);
    queryText += ` AND category = $${values.length}`;
  }

  if (status) {
    values.push(status);
    queryText += ` AND status = $${values.length}`;
  } else {
    // By default, exclude archived schemes for public listings
    queryText += " AND status != 'Archived'";
  }

  if (beneficiaryType && beneficiaryType !== 'All Citizens') {
    values.push(beneficiaryType);
    queryText += ` AND $${values.length} = ANY(beneficiary_types)`;
  }

  // Order by views/popularity and name
  queryText += ' ORDER BY views_count DESC, name ASC';

  const { rows } = await db.query(queryText, values);
  return rows;
}

/**
 * Fetch a single scheme by its unique UUID
 */
async function getSchemeById(id) {
  const query = 'SELECT * FROM schemes WHERE id = $1';
  const { rows } = await db.query(query, [id]);
  return rows[0] || null;
}

/**
 * Increment the views count on a scheme details lookup
 */
async function incrementViews(id) {
  const query = 'UPDATE schemes SET views_count = views_count + 1 WHERE id = $1 RETURNING views_count';
  const { rows } = await db.query(query, [id]);
  return rows[0] ? rows[0].views_count : 0;
}

/**
 * Increment saves count
 */
async function incrementSaves(id) {
  const query = 'UPDATE schemes SET saves_count = saves_count + 1 WHERE id = $1 RETURNING saves_count';
  const { rows } = await db.query(query, [id]);
  return rows[0] ? rows[0].saves_count : 0;
}

/**
 * Decrement saves count
 */
async function decrementSaves(id) {
  const query = 'UPDATE schemes SET saves_count = GREATEST(0, saves_count - 1) WHERE id = $1 RETURNING saves_count';
  const { rows } = await db.query(query, [id]);
  return rows[0] ? rows[0].saves_count : 0;
}

/**
 * Create a new scheme and insert its initial version record in a transaction
 */
async function createScheme(adminId, s) {
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Insert Scheme
    const insertSchemeQuery = `
      INSERT INTO schemes (
        name, description, state, category, eligibility_rules, required_documents, 
        benefits, official_website, application_link, pdf_notification_link, 
        application_mode, status, source_type, official_department, 
        last_verified_date, start_date, end_date, beneficiary_types, tags, 
        version_number, last_updated_by
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, 1, $20
      ) RETURNING *
    `;
    const schemeValues = [
      s.name, s.description, s.state, s.category,
      s.eligibility_rules ? JSON.stringify(s.eligibility_rules) : '{}',
      s.required_documents || [],
      s.benefits, s.official_website, s.application_link, s.pdf_notification_link,
      s.application_mode || 'Online', s.status || 'Open',
      s.source_type, s.official_department, s.last_verified_date,
      s.start_date || null, s.end_date || null,
      s.beneficiary_types || [], s.tags || [],
      adminId
    ];

    const schemeResult = await client.query(insertSchemeQuery, schemeValues);
    const createdScheme = schemeResult.rows[0];

    // 2. Insert Initial version record
    const insertVersionQuery = `
      INSERT INTO scheme_versions (
        scheme_id, version_number, name, description, eligibility_rules, benefits, 
        change_summary, updated_by
      ) VALUES ($1, 1, $2, $3, $4, $5, $6, $7)
    `;
    const versionValues = [
      createdScheme.id,
      createdScheme.name,
      createdScheme.description,
      JSON.stringify(createdScheme.eligibility_rules),
      createdScheme.benefits,
      'Initial scheme creation',
      adminId
    ];

    await client.query(insertVersionQuery, versionValues);

    await client.query('COMMIT');
    return createdScheme;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Update an existing scheme and append to its version history in a transaction
 */
async function updateScheme(adminId, schemeId, s) {
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Fetch current scheme to check version
    const selectResult = await client.query('SELECT version_number FROM schemes WHERE id = $1', [schemeId]);
    if (selectResult.rows.length === 0) {
      throw new Error('Scheme not found');
    }
    const currentVersion = selectResult.rows[0].version_number;
    const nextVersion = currentVersion + 1;

    // 2. Update Scheme details and version count
    const updateQuery = `
      UPDATE schemes SET
        name = $1,
        description = $2,
        state = $3,
        category = $4,
        eligibility_rules = $5,
        required_documents = $6,
        benefits = $7,
        official_website = $8,
        application_link = $9,
        pdf_notification_link = $10,
        application_mode = $11,
        status = $12,
        source_type = $13,
        official_department = $14,
        last_verified_date = $15,
        start_date = $16,
        end_date = $17,
        beneficiary_types = $18,
        tags = $19,
        version_number = $20,
        last_updated_by = $21,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $22 RETURNING *
    `;
    const updateValues = [
      s.name, s.description, s.state, s.category,
      s.eligibility_rules ? JSON.stringify(s.eligibility_rules) : '{}',
      s.required_documents || [],
      s.benefits, s.official_website, s.application_link, s.pdf_notification_link,
      s.application_mode, s.status, s.source_type, s.official_department,
      s.last_verified_date, s.start_date || null, s.end_date || null,
      s.beneficiary_types || [], s.tags || [],
      nextVersion, adminId, schemeId
    ];

    const result = await client.query(updateQuery, updateValues);
    const updatedScheme = result.rows[0];

    // 3. Insert Version record
    const insertVersionQuery = `
      INSERT INTO scheme_versions (
        scheme_id, version_number, name, description, eligibility_rules, benefits, 
        change_summary, updated_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `;
    const versionValues = [
      schemeId,
      nextVersion,
      updatedScheme.name,
      updatedScheme.description,
      JSON.stringify(updatedScheme.eligibility_rules),
      updatedScheme.benefits,
      s.change_summary || `Updated scheme configuration to version ${nextVersion}`,
      adminId
    ];

    await client.query(insertVersionQuery, versionValues);

    await client.query('COMMIT');
    return updatedScheme;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Delete a scheme record
 */
async function deleteScheme(id) {
  const query = 'DELETE FROM schemes WHERE id = $1 RETURNING id';
  const { rows } = await db.query(query, [id]);
  return rows[0] || null;
}

module.exports = {
  getAllSchemes,
  getSchemeById,
  incrementViews,
  incrementSaves,
  decrementSaves,
  createScheme,
  updateScheme,
  deleteScheme,
};
