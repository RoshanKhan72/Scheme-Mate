const db = require('../config/db');

/**
 * Fetch a profile by its associated User UUID
 * @param {string} userId - User UUID
 * @returns {Promise<object|null>} Profile object or null
 */
async function getProfileByUserId(userId) {
  const query = 'SELECT * FROM profiles WHERE user_id = $1';
  const values = [userId];
  const { rows } = await db.query(query, values);
  return rows[0] || null;
}

/**
 * Insert or update user profile parameters
 * @param {string} userId - User UUID
 * @param {object} p - Profile parameters
 * @returns {Promise<object>} Upserted Profile object
 */
async function upsertProfile(userId, p) {
  const query = `
    INSERT INTO profiles (
      user_id, dob, gender, state, district, taluk, village_city, 
      occupation, education, annual_income, marital_status, category, 
      minority_status, disability_status, is_student, is_farmer, 
      is_business_owner, bpl_apl_status, documents, extra_eligibility
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
    )
    ON CONFLICT (user_id) DO UPDATE SET
      dob = EXCLUDED.dob,
      gender = EXCLUDED.gender,
      state = EXCLUDED.state,
      district = EXCLUDED.district,
      taluk = EXCLUDED.taluk,
      village_city = EXCLUDED.village_city,
      occupation = EXCLUDED.occupation,
      education = EXCLUDED.education,
      annual_income = EXCLUDED.annual_income,
      marital_status = EXCLUDED.marital_status,
      category = EXCLUDED.category,
      minority_status = EXCLUDED.minority_status,
      disability_status = EXCLUDED.disability_status,
      is_student = EXCLUDED.is_student,
      is_farmer = EXCLUDED.is_farmer,
      is_business_owner = EXCLUDED.is_business_owner,
      bpl_apl_status = EXCLUDED.bpl_apl_status,
      documents = EXCLUDED.documents,
      extra_eligibility = EXCLUDED.extra_eligibility,
      updated_at = CURRENT_TIMESTAMP
    RETURNING *
  `;
  const values = [
    userId,
    p.dob,
    p.gender,
    p.state,
    p.district,
    p.taluk || null,
    p.village_city,
    p.occupation,
    p.education,
    p.annual_income,
    p.marital_status,
    p.category,
    p.minority_status || false,
    p.disability_status || false,
    p.is_student || false,
    p.is_farmer || false,
    p.is_business_owner || false,
    p.bpl_apl_status || 'None',
    p.documents ? JSON.stringify(p.documents) : '{}',
    p.extra_eligibility ? JSON.stringify(p.extra_eligibility) : '{}',
  ];

  const { rows } = await db.query(query, values);
  return rows[0];
}

module.exports = {
  getProfileByUserId,
  upsertProfile,
};
