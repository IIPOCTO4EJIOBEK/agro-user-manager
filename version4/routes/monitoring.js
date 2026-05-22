const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');

// Monitoring page - requires Monitoring Group role
router.get('/', requireAuth, requireRole('monitor'), (req, res) => {
  res.render('pages/monitoring', {
    title: 'System Monitoring',
    user: req.session.user
  });
});

// API endpoint to get monitoring data (example)
router.get('/api/metrics', requireAuth, requireRole('monitor'), async (req, res) => {
  try {
    // TODO: Implement actual system metrics collection
    res.json({
      success: true,
      cpu: 45.2,
      memory: 67.8,
      disk: 34.5,
      uptime: '15d 4h 23m'
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
