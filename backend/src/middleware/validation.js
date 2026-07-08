const { body, param, validationResult } = require('express-validator');

/**
 * Common handler to process validation check results.
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg,
      })),
    });
  }
  next();
};

/**
 * Validator rules for user registration requests.
 */
const validateRegister = [
  body('name').trim().notEmpty().withMessage('Name is required.'),
  body('email').trim().isEmail().withMessage('A valid email address is required.'),
  body('password')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters long.')
    .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter.')
    .matches(/[a-z]/).withMessage('Password must contain at least one lowercase letter.')
    .matches(/[0-9]/).withMessage('Password must contain at least one digit.'),
  handleValidationErrors,
];

/**
 * Validator rules for user login requests.
 */
const validateLogin = [
  body('email').trim().isEmail().withMessage('A valid email address is required.'),
  body('password').notEmpty().withMessage('Password is required.'),
  handleValidationErrors,
];

/**
 * Validator rules for saving profile parameters.
 */
const validateProfile = [
  body('dob').isISO8601().withMessage('Date of birth must be a valid date.'),
  body('gender').isIn(['Male', 'Female', 'Other']).withMessage('Invalid gender value.'),
  body('state').trim().notEmpty().withMessage('State is required.'),
  body('district').trim().notEmpty().withMessage('District is required.'),
  body('village_city').trim().notEmpty().withMessage('Village/City is required.'),
  body('annual_income').isFloat({ min: 0 }).withMessage('Annual income must be a non-negative number.'),
  body('minority_status').isBoolean().withMessage('Minority community status must be a boolean.'),
  body('disability_status').isBoolean().withMessage('Disability status must be a boolean.'),
  body('is_student').isBoolean().withMessage('Student status must be a boolean.'),
  body('is_farmer').isBoolean().withMessage('Farmer status must be a boolean.'),
  body('is_business_owner').isBoolean().withMessage('Business owner status must be a boolean.'),
  body('bpl_apl_status').isIn(['None', 'APL', 'BPL']).withMessage('Invalid Ration Card status.'),
  handleValidationErrors,
];

/**
 * Middleware validator for UUID parameters in path parameters.
 * @param {string|string[]} paramNames Parameter name(s) to validate
 */
const validateParamsUUID = (paramNames) => {
  const names = Array.isArray(paramNames) ? paramNames : [paramNames];
  const checks = names.map(name =>
    param(name).isUUID(4).withMessage(`${name} parameter must be a valid UUID v4 format.`)
  );
  return [...checks, handleValidationErrors];
};

module.exports = {
  validateRegister,
  validateLogin,
  validateProfile,
  validateParamsUUID,
};
