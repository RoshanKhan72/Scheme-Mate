const fs = require('fs');
const path = require('path');

const logsDir = path.join(__dirname, '../../logs');
const logFile = path.join(logsDir, 'app.log');

// Ensure log directory exists
try {
  if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
  }
} catch (e) {
  console.error('Failed to create logs directory:', e);
}

/**
 * Format and write structured logs to console and backend/logs/app.log
 */
function log(level, message, meta = {}) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    meta,
  };

  const logLine = JSON.stringify(logEntry) + '\n';

  // 1. Output to console with color coding
  let color = '\x1b[0m'; // Reset
  if (level === 'info') color = '\x1b[32m'; // Green
  if (level === 'warn') color = '\x1b[33m'; // Yellow
  if (level === 'error') color = '\x1b[31m'; // Red

  console.log(`${color}[${logEntry.timestamp}] [${level.toUpperCase()}] \x1b[0m${message}`, Object.keys(meta).length ? meta : '');

  // 2. Append to log file
  try {
    fs.appendFile(logFile, logLine, (err) => {
      if (err) console.error('Failed to write to log file:', err);
    });
  } catch (e) {
    console.error('File logging failure:', e);
  }
}

function info(message, meta) {
  log('info', message, meta);
}

function warn(message, meta) {
  log('warn', message, meta);
}

function error(message, err, meta = {}) {
  const errorMeta = {
    ...meta,
    error: err instanceof Error ? {
      name: err.name,
      message: err.message,
      stack: err.stack,
    } : err,
  };
  log('error', message, errorMeta);
}

module.exports = {
  info,
  warn,
  error,
};
