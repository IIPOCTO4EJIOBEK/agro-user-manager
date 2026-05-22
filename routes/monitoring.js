const express = require('express');
const router = express.Router();
const ldapService = require('../models/ldap');

// GET /api/stats - Get AD statistics
router.get('/stats', async (req, res) => {
  try {
    // Count users
    const allUsers = await ldapService.searchUsers('(objectClass=user)', ['sAMAccountName']);
    const enabledUsers = allUsers.filter(u => !u.userAccountControl || (parseInt(u.userAccountControl) & 2) === 0);
    
    // Count groups
    const allGroups = await ldapService.getAllGroups();
    
    res.json({
      success: true,
      data: {
        totalUsers: allUsers.length,
        enabledUsers: enabledUsers.length,
        disabledUsers: allUsers.length - enabledUsers.length,
        totalGroups: allGroups.length
      }
    });
  } catch (error) {
    console.error('Error getting AD stats:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/groups - Get all groups
router.get('/groups', async (req, res) => {
  try {
    const groups = await ldapService.getAllGroups();
    
    const result = groups.map(g => ({
      cn: g.cn,
      dn: g.distinguishedName,
      memberCount: g.member ? (Array.isArray(g.member) ? g.member.length : 1) : 0
    }));

    res.json({ success: true, data: result, total: result.length });
  } catch (error) {
    console.error('Error getting groups:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
