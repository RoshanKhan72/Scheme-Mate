const path = require('path');

// Configure test environment override
process.env.NODE_ENV = 'test';
if (process.env.DATABASE_URL_TEST) {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TEST;
} else {
  // Safe local PostgreSQL test database fallback
  process.env.DATABASE_URL = 'postgresql://postgres:postgres@localhost:5432/scheme_mate_test';
}

const db = require('../src/config/db');

/**
 * Truncates all tables in the test database to ensure isolation.
 */
async function cleanDatabase() {
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('TRUNCATE users, schemes, saved_schemes, notifications, feedback CASCADE');
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Clean up database connection pools at the end of a test run.
 */
async function closeConnections() {
  await db.pool.end();
}

module.exports = {
  cleanDatabase,
  closeConnections,
};
