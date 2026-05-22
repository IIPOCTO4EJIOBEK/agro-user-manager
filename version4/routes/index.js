const express = require('express');
const router = express.Router();
const { requireAuth, requireRole, requireAnyRole } = require('../middleware/auth');

// Dashboard - requires authentication
router.get('/', requireAuth, (req, res) => {
  res.render('pages/dashboard', {
    title: 'Dashboard',
    user: req.session.user
  });
});

module.exports = router;
