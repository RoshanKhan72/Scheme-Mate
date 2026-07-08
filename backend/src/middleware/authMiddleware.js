const jwt = require('jsonwebtoken');
const userModel = require('../models/userModel');
require('dotenv').config();

if (!process.env.JWT_SECRET) {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('FATAL ERROR: JWT_SECRET environment variable is not defined in production.');
  }
  console.warn('WARNING: JWT_SECRET environment variable is not defined. Using insecure default for development.');
}

const JWT_SECRET = process.env.JWT_SECRET || 'scheme_mate_super_secret_key_change_me_in_production';

/**
 * Authentication check middleware
 */
async function protect(req, res, next) {
  let token;

  // Check for token in headers
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      // Verify token enforcing HS256 algorithm explicitly
      const decoded = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });

      // Fetch user from DB, attach to request (excluding password_hash)
      const user = await userModel.findById(decoded.id);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Not authorized, user not found'
        });
      }

      req.user = user;
      next();
    } catch (error) {
      console.error('Token validation error:', error.message);
      let message = 'Not authorized, token invalid or expired';
      if (error.name === 'TokenExpiredError') {
        message = 'Not authorized, token expired';
      } else if (error.name === 'JsonWebTokenError') {
        message = 'Not authorized, token invalid';
      }
      return res.status(401).json({
        success: false,
        message
      });
    }
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized, no token provided'
    });
  }
}

module.exports = {
  protect,
};
