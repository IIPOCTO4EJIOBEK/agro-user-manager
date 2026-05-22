const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');

// Settings page - requires Super Admins role
router.get('/', requireAuth, requireRole('admins'), (req, res) => {
  res.render('pages/settings', {
    title: 'System Settings',
    user: req.session.user
  });
});

module.exports = router;
