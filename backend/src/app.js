const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const authRoutes = require('./routes/authRoutes');
const profileRoutes = require('./routes/profileRoutes');
const schemeRoutes = require('./routes/schemeRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const savedRoutes = require('./routes/savedRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const swaggerSpec = require('./config/swagger');

const app = express();

// Enable CORS
app.use(cors());

// Global API Version Header Middleware
app.use((req, res, next) => {
  res.setHeader('X-API-Version', '1.0.0');
  next();
});

// Body Parser Middleware (JSON parsing)
app.use(express.json());

// Base Health Check Route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date() });
});

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
  res.status(500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

module.exports = app;
