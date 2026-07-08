const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const userModel = require('../models/userModel');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'scheme_mate_super_secret_key_change_me_in_production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * Generate a JWT token for the user
 * @param {string} userId - UUID of the user
 * @returns {string} jwt token
 */
function generateToken(userId) {
  return jwt.sign({ id: userId }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  });
}

/**
 * @openapi
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     description: Sign up a new user to Scheme Mate with name, email, and password.
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *             properties:
 *               name:
 *                 type: string
 *                 description: User's full name
 *                 example: John Doe
 *               email:
 *                 type: string
 *                 format: email
 *                 description: User's unique email address
 *                 example: johndoe@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 minLength: 6
 *                 description: Password (must be at least 6 characters)
 *                 example: securepass123
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Registration successful.
 *                 token:
 *                   type: string
 *                   description: JWT access token
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       format: uuid
 *                       example: 4a3e7b1a-8c4b-4b2a-bf3b-9e32a67e8c1b
 *                     name:
 *                       type: string
 *                       example: John Doe
 *                     email:
 *                       type: string
 *                       example: johndoe@example.com
 *                     role:
 *                       type: string
 *                       example: user
 *       400:
 *         description: Bad request (missing fields, invalid email, short password, or user already exists)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Please enter a valid email address.
 *       500:
 *         description: Internal Server Error
 */
const logger = require('../utils/logger');

async function register(req, res) {
  try {
    const { name, email, password } = req.body;

    // 1. Validation
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, and password.',
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Please enter a valid email address.',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long.',
      });
    }

    // 2. Check if user already exists
    const userExists = await userModel.findByEmail(email);
    if (userExists) {
      logger.warn('Registration failed: Email already exists', { email });
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email address.',
      });
    }

    // 3. Hash Password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 4. Create User (UUID generated automatically in PostgreSQL schema)
    const newUser = await userModel.createUser(name, email, passwordHash);

    // 5. Generate JWT Token
    const token = generateToken(newUser.id);

    logger.info('User registered successfully', { userId: newUser.id, email: newUser.email });

    return res.status(201).json({
      success: true,
      message: 'Registration successful.',
      token,
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
      },
    });
  } catch (error) {
    logger.error('Registration unhandled error', error, { email: req.body.email });
    return res.status(500).json({
      success: false,
      message: 'Server error during user registration. Please try again.',
    });
  }
}

/**
 * @openapi
 * /api/auth/login:
 *   post:
 *     summary: Log in an existing user
 *     description: Authenticates user credentials and returns a JWT token for authorization.
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: User's registered email
 *                 example: johndoe@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 description: User's password
 *                 example: securepass123
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Login successful.
 *                 token:
 *                   type: string
 *                   description: JWT access token
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       format: uuid
 *                       example: 4a3e7b1a-8c4b-4b2a-bf3b-9e32a67e8c1b
 *                     name:
 *                       type: string
 *                       example: John Doe
 *                     email:
 *                       type: string
 *                       example: johndoe@example.com
 *                     role:
 *                       type: string
 *                       example: user
 *       401:
 *         description: Invalid email or password
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Invalid email or password.
 *       400:
 *         description: Missing fields
 *       500:
 *         description: Internal Server Error
 */
async function login(req, res) {
  try {
    const { email, password } = req.body;

    // 1. Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please enter both email and password.',
      });
    }

    // 2. Check for User
    const user = await userModel.findByEmail(email);
    if (!user) {
      logger.warn('Authentication failure: user not found', { email });
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    // 3. Compare Passwords
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      logger.warn('Authentication failure: password mismatch', { email, userId: user.id });
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    // 4. Generate JWT Token
    const token = generateToken(user.id);

    logger.info('User logged in successfully', { userId: user.id, email: user.email });

    return res.status(200).json({
      success: true,
      message: 'Login successful.',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    logger.error('Login unhandled error', error, { email: req.body.email });
    return res.status(500).json({
      success: false,
      message: 'Server error during login. Please try again.',
    });
  }
}

/**
 * @openapi
 * /api/auth/profile:
 *   get:
 *     summary: Get current user profile
 *     description: Retrieve details of the authenticated user. Requires a valid JWT token.
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                       format: uuid
 *                       example: 4a3e7b1a-8c4b-4b2a-bf3b-9e32a67e8c1b
 *                     name:
 *                       type: string
 *                       example: John Doe
 *                     email:
 *                       type: string
 *                       example: johndoe@example.com
 *                     role:
 *                       type: string
 *                       example: user
 *                     created_at:
 *                       type: string
 *                       format: date-time
 *                       example: 2026-07-02T14:40:00.000Z
 *                     updated_at:
 *                       type: string
 *                       format: date-time
 *                       example: 2026-07-02T14:40:00.000Z
 *       401:
 *         description: Unauthorized (missing or invalid token)
 *       500:
 *         description: Internal Server Error
 */
async function getProfile(req, res) {
  try {
    return res.status(200).json({
      success: true,
      user: req.user,
    });
  } catch (error) {
    console.error('Get Profile Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error fetching user profile.',
    });
  }
}

module.exports = {
  register,
  login,
  getProfile,
};
