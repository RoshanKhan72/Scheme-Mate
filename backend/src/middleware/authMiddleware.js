const jwt = require('jsonwebtoken');
const userModel = require('../models/userModel');
require('dotenv').config();

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

      // Verify token
      const decoded = jwt.verify(token, JWT_SECRET);

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
      return res.status(401).json({
        success: false,
        message: 'Not authorized, token invalid or expired'
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
