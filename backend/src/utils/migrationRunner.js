const fs = require('fs');
const path = require('path');
const { pool } = require('../config/db');

const migrationsDir = path.join(__dirname, '../migrations');

async function run() {
  const isDown = process.argv.includes('--down') || process.argv.includes('--rollback');
  console.log(`[MIGRATION] Running database migrations in ${isDown ? 'DOWN (rollback)' : 'UP'} mode...`);

  const client = await pool.connect();
  try {
    // Ensure migrations meta table exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        name VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    if (isDown) {
      // 1. Rollback last migration
      const lastRes = await client.query('SELECT name FROM schema_migrations ORDER BY applied_at DESC LIMIT 1');
      if (lastRes.rowCount === 0) {
        console.log('[MIGRATION] No migrations found to rollback.');
        return;
      }

      const migrationName = lastRes.rows[0].name;
      const baseName = migrationName.replace('.sql', '');
      const downFileName = `${baseName}_down.sql`;
      const downFilePath = path.join(migrationsDir, downFileName);

      if (!fs.existsSync(downFilePath)) {
        throw new Error(`Rollback script not found for applied migration: ${downFileName}`);
      }

      console.log(`[MIGRATION] Executing rollback: ${downFileName}`);
      const sql = fs.readFileSync(downFilePath, 'utf8');
      
      await client.query('BEGIN');
      await client.query(sql);
      await client.query('DELETE FROM schema_migrations WHERE name = $1', [migrationName]);
      await client.query('COMMIT');
      
      console.log(`[MIGRATION] Rollback completed successfully: ${downFileName}`);
    } else {
      // 2. Apply outstanding migrations
      const files = fs.readdirSync(migrationsDir)
        .filter(f => f.endsWith('.sql') && !f.includes('_down'))
        .sort(); // Sort alphabetically by timestamp prefix

      const appliedRes = await client.query('SELECT name FROM schema_migrations');
      const appliedList = appliedRes.rows.map(r => r.name);

      let count = 0;
      for (const file of files) {
        if (!appliedList.includes(file)) {
          console.log(`[MIGRATION] Applying migration: ${file}`);
          const filePath = path.join(migrationsDir, file);
          const sql = fs.readFileSync(filePath, 'utf8');

          await client.query('BEGIN');
          await client.query(sql);
          await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file]);
          await client.query('COMMIT');

          console.log(`[MIGRATION] Migration applied successfully: ${file}`);
          count++;
        }
      }

      if (count === 0) {
        console.log('[MIGRATION] Database is up to date. No pending migrations.');
      } else {
        console.log(`[MIGRATION] Applied ${count} database migration(s).`);
      }
    }
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('[MIGRATION] Migration transaction execution failed:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
