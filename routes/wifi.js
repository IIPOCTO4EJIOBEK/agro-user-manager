const express = require('express');
const router = express.Router();
const mikrotikService = require('../services/mikrotik');

// GET /api/stats - Get hotspot statistics
router.get('/stats', async (req, res) => {
  try {
    const stats = await mikrotikService.getHotspotStats();
    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('Error getting hotspot stats:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/sessions - Get active sessions
router.get('/sessions', async (req, res) => {
  try {
    const sessions = await mikrotikService.getActiveSessions();
    res.json({ success: true, data: sessions, total: sessions.length });
  } catch (error) {
    console.error('Error getting active sessions:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/bindings - Get MAC bindings
router.get('/bindings', async (req, res) => {
  try {
    const bindings = await mikrotikService.getMACBindings();
    res.json({ success: true, data: bindings, total: bindings.length });
  } catch (error) {
    console.error('Error getting MAC bindings:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/send-sms - Send SMS
router.post('/send-sms', async (req, res) => {
  try {
    const { phoneNumber, message } = req.body;

    if (!phoneNumber || !message) {
      return res.status(400).json({ 
        success: false, 
        message: 'Требуется номер телефона и сообщение' 
      });
    }

    const result = await mikrotikService.sendSMS(phoneNumber, message);

    if (result.success) {
      res.json({ success: true, message: result.message });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error sending SMS:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/authorize - Authorize MAC address
router.post('/authorize', async (req, res) => {
  try {
    const { macAddress, comment } = req.body;

    if (!macAddress) {
      return res.status(400).json({ success: false, message: 'Требуется MAC адрес' });
    }

    const result = await mikrotikService.authorizeMAC(macAddress, comment);

    if (result.success) {
      res.json({ success: true, message: result.message });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error authorizing MAC:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// DELETE /api/authorize - Remove MAC authorization
router.delete('/authorize', async (req, res) => {
  try {
    const { macAddress } = req.body;

    if (!macAddress) {
      return res.status(400).json({ success: false, message: 'Требуется MAC адрес' });
    }

    const result = await mikrotikService.removeMACAuthorization(macAddress);

    if (result.success) {
      res.json({ success: true, message: result.message });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error removing MAC authorization:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/kick - Kick user from hotspot
router.post('/kick', async (req, res) => {
  try {
    const { macAddress } = req.body;

    if (!macAddress) {
      return res.status(400).json({ success: false, message: 'Требуется MAC адрес' });
    }

    const result = await mikrotikService.kickUser(macAddress);

    if (result.success) {
      res.json({ success: true, message: result.message });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error kicking user:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/cleanup - Cleanup expired sessions
router.post('/cleanup', async (req, res) => {
  try {
    const result = await mikrotikService.cleanupExpiredSessions();

    if (result.success) {
      res.json({ success: true, message: result.message });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error cleaning up sessions:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
