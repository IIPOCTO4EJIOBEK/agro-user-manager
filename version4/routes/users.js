const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');

// Users page - requires AD Admins role
router.get('/', requireAuth, requireRole('admins'), (req, res) => {
  res.render('pages/users', {
    title: 'User Management',
    user: req.session.user
  });
});

// API endpoint to get users (example)
router.get('/api/list', requireAuth, requireRole('admins'), async (req, res) => {
  try {
    // TODO: Implement actual LDAP user listing
    res.json({
      success: true,
      users: [
        { name: 'John Doe', username: 'jdoe', email: 'jdoe@example.com' },
        { name: 'Jane Smith', username: 'jsmith', email: 'jsmith@example.com' }
      ]
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
