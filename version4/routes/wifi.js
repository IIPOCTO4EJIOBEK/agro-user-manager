const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');

// WiFi page - requires Network Admins or WiFi Managers role
router.get('/', requireAuth, requireAnyRole(['network', 'wifi']), (req, res) => {
  res.render('pages/wifi', {
    title: 'WiFi & SMS Authentication',
    user: req.session.user
  });
});

// API endpoint to get WiFi stats (example)
router.get('/api/stats', requireAuth, requireAnyRole(['network', 'wifi']), async (req, res) => {
  try {
    // TODO: Implement actual MikroTik integration
    res.json({
      success: true,
      activeUsers: 42,
      totalSessions: 1250,
      smsSent: 8934
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
