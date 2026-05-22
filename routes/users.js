const express = require('express');
const router = express.Router();
const ldapService = require('../models/ldap');

// GET /api/list - Search users
router.get('/list', async (req, res) => {
  try {
    const { query, limit = 50 } = req.query;
    
    let filter;
    if (query) {
      filter = `(|(sAMAccountName=*${query}*)(cn=*${query}*)(mail=*${query}*))`;
    } else {
      filter = '(objectClass=user)';
    }

    const users = await ldapService.searchUsers(filter);
    
    // Filter out computer accounts and disabled accounts info
    const result = users.slice(0, parseInt(limit)).map(user => ({
      dn: user.distinguishedName,
      cn: user.cn || user.sAMAccountName,
      sAMAccountName: user.sAMAccountName,
      mail: user.mail || '',
      enabled: !user.userAccountControl || (parseInt(user.userAccountControl) & 2) === 0,
      memberOf: user.memberOf ? (Array.isArray(user.memberOf) ? user.memberOf : [user.memberOf]) : []
    }));

    res.json({ success: true, data: result, total: result.length });
  } catch (error) {
    console.error('Error searching users:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/:dn - Get user details
router.get('/:dn', async (req, res) => {
  try {
    const dn = decodeURIComponent(req.params.dn);
    const user = await ldapService.getUserByDN(dn);
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const groups = user.memberOf ? (Array.isArray(user.memberOf) ? user.memberOf : [user.memberOf]).map(g => {
      const match = g.match(/CN=([^,]+)/);
      return match ? match[1] : g;
    }) : [];

    res.json({
      success: true,
      data: {
        dn: user.distinguishedName,
        cn: user.cn,
        sAMAccountName: user.sAMAccountName,
        mail: user.mail || '',
        telephoneNumber: user.telephoneNumber || '',
        department: user.department || '',
        title: user.title || '',
        enabled: !user.userAccountControl || (parseInt(user.userAccountControl) & 2) === 0,
        memberOf: groups,
        lastLogon: user.lastLogonTimestamp || null
      }
    });
  } catch (error) {
    console.error('Error getting user details:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// PATCH /api/:action/:dn - Enable/Disable user
router.patch('/:action/:dn', async (req, res) => {
  try {
    const { action } = req.params;
    const dn = decodeURIComponent(req.params.dn);
    
    if (!['enable', 'disable'].includes(action)) {
      return res.status(400).json({ success: false, message: 'Invalid action' });
    }

    const enabled = action === 'enable';
    const result = await ldapService.setUserEnabled(dn, enabled);

    if (result.success) {
      res.json({ 
        success: true, 
        message: `Пользователь ${enabled ? 'включен' : 'отключен'}` 
      });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/:dn/groups - Add user to group
router.post('/:dn/groups', async (req, res) => {
  try {
    const dn = decodeURIComponent(req.params.dn);
    const { groupDN } = req.body;

    if (!groupDN) {
      return res.status(400).json({ success: false, message: 'Group DN required' });
    }

    const result = await ldapService.addUserToGroup(dn, groupDN);

    if (result.success) {
      res.json({ success: true, message: 'Пользователь добавлен в группу' });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error adding user to group:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// DELETE /api/:dn/groups - Remove user from group
router.delete('/:dn/groups', async (req, res) => {
  try {
    const dn = decodeURIComponent(req.params.dn);
    const { groupDN } = req.body;

    if (!groupDN) {
      return res.status(400).json({ success: false, message: 'Group DN required' });
    }

    const result = await ldapService.removeUserFromGroup(dn, groupDN);

    if (result.success) {
      res.json({ success: true, message: 'Пользователь удален из группы' });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error) {
    console.error('Error removing user from group:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
