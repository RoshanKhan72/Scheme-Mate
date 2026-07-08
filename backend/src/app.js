const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const { rateLimit } = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const authRoutes = require('./routes/authRoutes');
const profileRoutes = require('./routes/profileRoutes');
const schemeRoutes = require('./routes/schemeRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const savedRoutes = require('./routes/savedRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const swaggerSpec = require('./config/swagger');
const db = require('./config/db');

const app = express();

// Enable Helmet for security headers
app.use(helmet());

// Enable compression
app.use(compression());

// Configured CORS
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3000', 'http://localhost:5000', 'http://localhost:8000', 'http://localhost:5500'];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV !== 'production') {
      return callback(null, true);
    }
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));

// Rate limiting configurations
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: 100, // Limit each IP to 100 requests per window
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests from this IP, please try again after 15 minutes.' },
  handler: (req, res, next, options) => {
    const logger = require('./utils/logger');
    logger.warn('Rate limit exceeded (General)', { ip: req.ip, path: req.path });
    res.status(options.statusCode).send(options.message);
  }
});

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: 5, // Limit each IP to 5 requests per window
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { success: false, message: 'Too many login attempts from this IP, please try again after 15 minutes.' },
  handler: (req, res, next, options) => {
    const logger = require('./utils/logger');
    logger.warn('Rate limit exceeded (Login)', { ip: req.ip, path: req.path, email: req.body?.email });
    res.status(options.statusCode).send(options.message);
  }
});

const registerLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: 10, // Limit each IP to 10 requests per window
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { success: false, message: 'Too many accounts created from this IP, please try again after 15 minutes.' },
  handler: (req, res, next, options) => {
    const logger = require('./utils/logger');
    logger.warn('Rate limit exceeded (Registration)', { ip: req.ip, path: req.path, email: req.body?.email });
    res.status(options.statusCode).send(options.message);
  }
});

// Global API Version Header Middleware
app.use((req, res, next) => {
  const version = process.env.API_VERSION || '1.0.0';
  res.setHeader('X-API-Version', version);
  next();
});

// Body Parser Middleware with explicit payload limits (10kb)
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ limit: '10kb', extended: true }));

// Apply rate limits to specific route prefixes
app.use('/api/v1/auth/login', loginLimiter);
app.use('/api/v1/auth/register', registerLimiter);
app.use('/api', generalLimiter);

// Base Health Check Route Handler
const healthHandler = async (req, res) => {
  try {
    // Verify database pool connectivity
    await db.query('SELECT 1');
    res.status(200).json({
      status: 'ok',
      version: process.env.API_VERSION || '1.0.0',
      timestamp: new Date(),
      database: 'connected',
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      version: process.env.API_VERSION || '1.0.0',
      timestamp: new Date(),
      database: 'disconnected',
      error: error.message,
    });
  }
};

app.get('/health', healthHandler);
app.get('/api/v1/health', healthHandler);

// Swagger API Documentation Route
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Route Prefixing
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/profile', profileRoutes);
app.use('/api/v1/schemes', schemeRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/saved', savedRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/feedback', require('./routes/feedbackRoutes'));

// 404 Route handler
app.use((req, res, next) => {
  res.status(404).json({ success: false, message: 'Resource not found' });
});

// Global Error Handling Middleware
app.use((err, req, res, next) => {
  const logger = require('./utils/logger');
  logger.error('Unhandled Server Error', err, { path: req.path, method: req.method });
  
  const isProduction = process.env.NODE_ENV === 'production';
  res.status(err.status || 500).json({
    success: false,
    message: isProduction ? 'Internal Server Error' : (err.message || 'Internal Server Error'),
  });
});

module.exports = app;
