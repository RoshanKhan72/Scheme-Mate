/**
 * Middleware to restrict access to admin users only
 * Must be mounted AFTER the protect middleware to have req.user populated
 */
function adminOnly(req, res, next) {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Administrator privileges required.',
    });
  }
}

module.exports = {
  adminOnly,
};
