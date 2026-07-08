const app = require('./app');
const db = require('./config/db');
require('dotenv').config();

const PORT = process.env.PORT || 5000;

// Verify Database Connection before starting the server
async function startServer() {
  try {
    // Attempt a basic query to make sure connection parameters are correct
    console.log('Testing database connection...');
    await db.query('SELECT NOW()');
    console.log('Database connection verification passed.');

    app.listen(PORT, () => {
      console.log(`Scheme Mate server is running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server due to Database Connection error:');
    console.error(error.message);
    console.log('\n--- Troubleshooting Tips ---');
    console.log('1. Make sure your local PostgreSQL server is running.');
    console.log(`2. Verify database "${process.env.DB_DATABASE || 'schememate'}" exists.`);
    console.log(`3. Check login credentials in backend/.env: User="${process.env.DB_USER}", Port="${process.env.DB_PORT}"`);
    console.log('----------------------------\n');
    
    // We will still start the server in recovery mode so it can run if DB starts later,
    // or we can exit. For convenience of debugging, let's start the server anyway so the user
    // can connect, but log DB status.
    app.listen(PORT, () => {
      console.log(`Scheme Mate server running on port ${PORT} (DATABASE OFFLINE)`);
    });
  }
}

startServer();
// Trigger reload post database setup

