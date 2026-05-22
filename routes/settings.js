const express = require('express');
const router = express.Router();
const ldapService = require('../models/ldap');
const config = require('../config/config');

// GET /api/groups - Get AD groups for settings
router.get('/ad-groups', async (req, res) => {
  try {
    const groups = await ldapService.getAllGroups();
    
    const result = groups.map(g => ({
      cn: g.cn,
      dn: g.distinguishedName
    }));

    res.json({ 
      success: true, 
      data: result,
      currentConfig: {
        adminsGroup: config.adGroups.admins,
        networkGroup: config.adGroups.network,
        wifiGroup: config.adGroups.wifi,
        monitoringGroup: config.adGroups.monitoring
      }
    });
  } catch (error) {
    console.error('Error getting AD groups:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// GET /api/ldap-status - Check LDAP connection status
router.get('/ldap-status', async (req, res) => {
  try {
    // Try to connect and search
    await ldapService.ensureConnected();
    
    const testSearch = await ldapService.searchUsers('(objectClass=domain)', ['name']);
    
    res.json({
      success: true,
      data: {
        connected: true,
        primaryHost: config.ldap.primary,
        secondaryHost: config.ldap.secondary,
        baseDN: config.ldap.baseDN,
        domainName: testSearch.length > 0 ? testSearch[0].name : 'Unknown'
      }
    });
  } catch (error) {
    res.json({
      success: false,
      data: {
        connected: false,
        error: error.message
      }
    });
  }
});

// POST /api/test-ldap - Test LDAP credentials
router.post('/test-ldap', async (req, res) => {
  try {
    const { adminDN, adminPassword } = req.body;
    
    if (!adminDN || !adminPassword) {
      return res.status(400).json({ 
        success: false, 
        message: 'Требуется DN и пароль администратора' 
      });
    }

    const client = require('ldapjs').createClient({
      url: config.ldap.primary,
      tlsOptions: {
        rejectUnauthorized: config.ldap.tlsRejectUnauthorized
      }
    });

    client.bind(adminDN, adminPassword, (err) => {
      client.destroy();
      
      if (err) {
        res.json({ 
          success: false, 
          message: 'Ошибка аутентификации: ' + err.message 
        });
      } else {
        res.json({ 
          success: true, 
          message: 'Успешное подключение к LDAP' 
        });
      }
    });
  } catch (error) {
    console.error('Error testing LDAP:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
