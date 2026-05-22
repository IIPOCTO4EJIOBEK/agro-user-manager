const express = require('express');
const router = express.Router();
const ldapService = require('../models/ldap');

router.get('/stats', async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const exec = require('util').promisify(require('child_process').exec);
    const run = async (filter) => {
      const cmd = 'ldapsearch -x -E pr=10000/noprompt -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "' + filter + '" dn -LLL 2>/dev/null | grep -c "^dn:" || echo 0';
      try { const r = await exec(cmd, {shell: '/bin/bash', timeout: 20000}); return parseInt(r.stdout.trim()) || 0; }
      catch(e) { return 0; }
    };
    const [totalUsers, enabledUsers, disabledUsers, totalGroups] = await Promise.all([
      run('(&(objectClass=user)(!(objectClass=computer)))'),
      run('(&(objectClass=user)(!(objectClass=computer))(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'),
      run('(&(objectClass=user)(!(objectClass=computer))(userAccountControl:1.2.840.113556.1.4.803:=2))'),
      run('(&(objectClass=group)(groupType:1.2.840.113556.1.4.803:=2147483648))')
    ]);
    res.json({ success: true, data: { totalUsers, enabledUsers, disabledUsers, totalGroups } });
  } catch (error) {
    console.error('Stats error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/groups', async (req, res) => {
  try {
    const groups = await ldapService.getAllGroups();
    const result = groups.map(g => ({ cn: g.cn, dn: g.distinguishedName, memberCount: g.member ? (Array.isArray(g.member) ? g.member.length : 1) : 0 }));
    res.json({ success: true, data: result, total: result.length });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
