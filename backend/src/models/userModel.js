const db = require('../config/db');

/**
 * Find a user by their email address
 * @param {string} email 
 * @returns {Promise<object|null>} user object or null
 */
async function findByEmail(email) {
  const query = 'SELECT * FROM users WHERE email = $1';
  const values = [email.toLowerCase().trim()];
  const { rows } = await db.query(query, values);
  return rows[0] || null;
}

/**
 * Find a user by their unique ID
 * @param {number} id 
 * @returns {Promise<object|null>} user object or null
 */
async function findById(id) {
  const query = 'SELECT id, name, email, role, created_at, updated_at FROM users WHERE id = $1';
  const values = [id];
  const { rows } = await db.query(query, values);
  return rows[0] || null;
}

/**
 * Create a new user in the database
 * @param {string} name 
 * @param {string} email 
 * @param {string} passwordHash 
 * @param {string} role 
 * @returns {Promise<object>} created user object
 */
async function createUser(name, email, passwordHash, role = 'user') {
  const query = `
    INSERT INTO users (name, email, password_hash, role)
    VALUES ($1, $2, $3, $4)
    RETURNING id, name, email, role, created_at, updated_at
  `;
  const values = [name.trim(), email.toLowerCase().trim(), passwordHash, role];
  const { rows } = await db.query(query, values);
  return rows[0];
}

module.exports = {
  findByEmail,
  findById,
  createUser,
};
