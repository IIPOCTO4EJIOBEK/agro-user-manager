const express = require('express');
const router = express.Router();
const ldap = require('ldapjs');
const config = require('../config/config');

// Simple auth check for API routes (compatible with v3/v4 session format)
function isAuth(req, res, next) {
  if (req.session?.authenticated || req.session?.user || req.session?.uid) return next();
  res.status(401).json({ error: 'Требуется авторизация' });
}

// Get LDAP bind credentials from session or globals
function getBindInfo(req) {
  // v4 format: global variables
  if (global.currentBindDN && global.currentBindPass) {
    return {
      bindDN: global.currentBindDN,
      bindPass: global.currentBindPass,
      host: global.currentLdapHost || 'ldap://10.0.2.21:389'
    };
  }
  // v3 format: req.session.adUser/adPass/adUrl
  if (req.session?.adUser && req.session?.adPass) {
    return {
      bindDN: req.session.adUser,
      bindPass: req.session.adPass,
      host: req.session.adUrl || 'ldap://10.0.2.21:389'
    };
  }
  // Fallback from req.session.user
  if (req.session?.user?.password && req.session?.user?.sAMAccountName) {
    return {
      bindDN: req.session.user.sAMAccountName.includes('@') ? req.session.user.sAMAccountName : req.session.user.sAMAccountName + '@rusagroeco.ru',
      bindPass: req.session.user.password,
      host: req.session.adServer ? 'ldap://' + req.session.adServer + ':389' : 'ldap://10.0.2.21:389'
    };
  }
  return {
    bindDN: 'vardo001@rusagroeco.ru',
    bindPass: '!P09710023p2023',
    host: 'ldap://10.0.2.21:389'
  };
}

// Cache for AD data
let cache = {
  users: [], ous: [], groups: [], computers: [],
  depts: [], comps: [], titles: [], locations: [],
  offices: [], descriptions: [], assistants: [],
  dbStats: {}, syncing: false, lastUpdate: 0
};

// Helper: async LDAP search
function ldapSearch(client, baseDN, filter, attrs) {
  return new Promise((resolve, reject) => {
    const opts = { filter, scope: 'sub', attributes: attrs, paged: { pageSize: 1000 } };
    client.search(baseDN, opts, (err, res) => {
      if (err) return reject(err);
      const results = [];
      res.on('searchEntry', (entry) => {
        const obj = { dn: entry.objectName || '' };
        entry.attributes.forEach(attr => {
          obj[attr.type] = attr.values.length === 1 ? attr.values[0] : attr.values;
        });
        results.push(obj);
      });
      res.on('end', () => resolve(results));
      res.on('error', reject);
    });
  });
}

// Helper: get single attribute value
function getAttr(obj, attr) {
  const val = obj[attr];
  return Array.isArray(val) ? val[0] || '' : val || '';
}

// Load all AD data
async function loadADData(req) {
  if (cache.syncing) return cache;
  cache.syncing = true;
  
  const bind = getBindInfo(req);
  const client = ldap.createClient({ url: bind.host, tlsOptions: { rejectUnauthorized: false } });
  
  try {
    await new Promise((resolve, reject) => {
      client.bind(bind.bindDN, bind.bindPass, (err) => err ? reject(err) : resolve());
    });
    
    const [users, ous, groups, computers] = await Promise.all([
      ldapSearch(client, config.ldap.baseDN, '(&(objectClass=user)(objectCategory=person))',
        ['sAMAccountName', 'mail', 'displayName', 'department', 'company', 'title', 'l', 'st',
         'manager', 'info', 'telephoneNumber', 'mobile', 'homePhone', 'extensionAttribute1',
         'extensionAttribute2', 'extensionAttribute3', 'assistant', 'userAccountControl',
         'physicalDeliveryOfficeName', 'description', 'homeMDB', 'memberOf', 'sn', 'givenName',
         'pwdLastSet', 'msDS-UserPasswordExpiryTimeComputed', 'accountExpires', 'lastLogon',
         'lastLogonTimestamp', 'whenCreated', 'whenChanged']),
      ldapSearch(client, config.ldap.baseDN, '(objectClass=organizationalUnit)', ['ou', 'description']),
      ldapSearch(client, config.ldap.baseDN, '(objectClass=group)', ['cn', 'description', 'member', 'sAMAccountName']),
      ldapSearch(client, config.ldap.baseDN, '(objectClass=computer)', ['cn', 'dNSHostName', 'description', 'operatingSystem', 'operatingSystemServicePack', 'lastLogon', 'whenCreated', 'userAccountControl'])
    ]);
    
    const depts = new Set(), comps = new Set(), titles = new Set();
    const locs = new Set(), offices = new Set(), descs = new Set(), assts = new Set();
    const dbStats = {};
    for (let i = 1; i <= 12; i++) dbStats['DB' + String(i).padStart(2, '0')] = 0;
    
    users.forEach(u => {
      if (getAttr(u, 'department')) depts.add(getAttr(u, 'department'));
      if (getAttr(u, 'company')) comps.add(getAttr(u, 'company'));
      if (getAttr(u, 'title')) titles.add(getAttr(u, 'title'));
      if (getAttr(u, 'l')) locs.add(getAttr(u, 'l'));
      if (getAttr(u, 'physicalDeliveryOfficeName')) offices.add(getAttr(u, 'physicalDeliveryOfficeName'));
      if (getAttr(u, 'description')) descs.add(getAttr(u, 'description'));
      if (getAttr(u, 'assistant')) assts.add(getAttr(u, 'assistant'));
      const mdb = getAttr(u, 'homeMDB');
      const m = mdb.match(/CN=(DB\d{2})/i);
      if (m && dbStats[m[1]] !== undefined) dbStats[m[1]]++;
    });
    
    cache = {
      users: users.sort((a, b) => (getAttr(a, 'displayName') || '').localeCompare(getAttr(b, 'displayName') || '')),
      ous: ous.map(o => ({ name: getAttr(o, 'ou'), dn: o.dn, desc: getAttr(o, 'description') })).filter(o => o.dn).sort((a, b) => a.dn.length - b.dn.length),
      groups: groups.map(g => ({ name: getAttr(g, 'cn'), dn: g.dn, description: getAttr(g, 'description'), memberCount: Array.isArray(g.member) ? g.member.length : (g.member ? 1 : 0) })).filter(g => g.dn).sort((a, b) => (a.name || '').localeCompare(b.name || '')),
      computers: computers.map(c => ({ cn: getAttr(c, 'cn'), dn: c.dn, dns: getAttr(c, 'dNSHostName'), os: getAttr(c, 'operatingSystem'), sp: getAttr(c, 'operatingSystemServicePack'), desc: getAttr(c, 'description'), uac: getAttr(c, 'userAccountControl'), lastLogon: getAttr(c, 'lastLogon'), whenCreated: getAttr(c, 'whenCreated') })),
      depts: Array.from(depts).sort(),
      comps: Array.from(comps).sort(),
      titles: Array.from(titles).sort(),
      locations: Array.from(locs).sort(),
      offices: Array.from(offices).sort(),
      descriptions: Array.from(descs).sort(),
      assistants: Array.from(assts).sort(),
      dbStats, syncing: false, lastUpdate: Date.now()
    };
  } catch (err) {
    console.error('AD scan error:', err.message);
    cache.syncing = false;
  } finally {
    client.unbind();
  }
  
  return cache;
}

// GET /api/data - main data endpoint
router.get('/data', isAuth, async (req, res) => {
  if (!cache.users.length || cache.syncing) {
    await loadADData(req);
  }
  res.json(cache);
});

// POST /api/resync - force reload
router.post('/resync', isAuth, async (req, res) => {
  const result = await loadADData(req);
  res.json({ success: true, users: result.users.length, ous: result.ous.length });
});

// GET /api/groups - v3 format
router.get('/groups', isAuth, async (req, res) => {
  if (!cache.groups.length) await loadADData(req);
  const search = req.query.search || '';
  const filtered = search ? cache.groups.filter(g => g.name.toLowerCase().includes(search.toLowerCase())) : cache.groups;
  res.json({ success: true, groups: filtered, total: filtered.length });
});

// GET /api/groups/detail - v3 format
router.get('/groups/detail', isAuth, async (req, res) => {
  const dn = req.query.dn;
  if (!dn) return res.json({ success: false, error: 'DN required' });
  
  const bind = getBindInfo(req);
  const client = ldap.createClient({ url: bind.host, tlsOptions: { rejectUnauthorized: false } });
  
  try {
    await new Promise((resolve, reject) => {
      client.bind(bind.bindDN, bind.bindPass, (err) => err ? reject(err) : resolve());
    });
    
    const groups = await ldapSearch(client, dn, '(objectClass=group)', ['cn', 'description', 'member', 'sAMAccountName']);
    if (!groups.length) return res.json({ success: false, error: 'Group not found' });
    
    const g = groups[0];
    const members = g.member || [];
    const memberList = Array.isArray(members) ? members : (members ? [members] : []);
    
    // Resolve member details
    const memberDetails = [];
    for (const memberDn of memberList.slice(0, 500)) {
      const users = await ldapSearch(client, config.ldap.baseDN, `(distinguishedName=${memberDn})`, ['displayName', 'sAMAccountName', 'title', 'userAccountControl']);
      if (users.length) {
        const u = users[0];
        const uac = parseInt(getAttr(u, 'userAccountControl') || '0');
        memberDetails.push({
          name: getAttr(u, 'displayName') || memberDn.split(',')[0].replace('CN=', ''),
          sam: getAttr(u, 'sAMAccountName'),
          title: getAttr(u, 'title'),
          type: 'user',
          disabled: !!(uac & 2)
        });
      } else {
        // Could be a nested group
        const subGroups = await ldapSearch(client, config.ldap.baseDN, `(distinguishedName=${memberDn})`, ['cn', 'sAMAccountName']);
        if (subGroups.length) {
          memberDetails.push({ name: getAttr(subGroups[0], 'cn'), sam: getAttr(subGroups[0], 'sAMAccountName'), type: 'group', disabled: false });
        }
      }
    }
    
    res.json({
      success: true,
      group: {
        name: getAttr(g, 'cn'),
        dn: g.dn,
        sam: getAttr(g, 'sAMAccountName'),
        memberCount: memberList.length,
        description: getAttr(g, 'description'),
        members: memberDetails
      }
    });
  } catch (err) {
    res.json({ success: false, error: err.message });
  } finally {
    client.unbind();
  }
});

// GET /api/computers - v3 format
router.get('/computers', isAuth, async (req, res) => {
  if (!cache.computers.length) await loadADData(req);
  const now = Date.now();
  const ninetyDays = 90 * 24 * 60 * 60 * 1000;
  
  const stats = { total: cache.computers.length, active: 0, inactive90: 0 };
  const computers = cache.computers.map(c => {
    const uac = parseInt(c.uac || '0');
    const disabled = !!(uac & 2);
    const lastLogon = c.lastLogon ? parseInt(c.lastLogon) : 0;
    const daysSinceLogon = lastLogon ? Math.floor((now - lastLogon) / (24 * 60 * 60 * 1000)) : 999;
    const inactive90 = daysSinceLogon > 90;
    
    if (!disabled) stats.active++;
    if (inactive90) stats.inactive90++;
    
    return { ...c, disabled, daysSinceLogon, inactive90 };
  });
  
  res.json({ success: true, computers, stats });
});

// GET /api/users-disabled - v3 format
router.get('/users-disabled', isAuth, async (req, res) => {
  if (!cache.users.length) await loadADData(req);
  const disabled = cache.users.filter(u => {
    const uac = parseInt(getAttr(u, 'userAccountControl') || '0');
    return !!(uac & 2);
  }).map(u => ({
    dn: u.dn,
    displayName: getAttr(u, 'displayName'),
    sAMAccountName: getAttr(u, 'sAMAccountName'),
    department: getAttr(u, 'department'),
    title: getAttr(u, 'title'),
    mail: getAttr(u, 'mail'),
    whenChanged: getAttr(u, 'whenChanged')
  }));
  
  res.json({ success: true, disabledUsers: disabled, total: disabled.length });
});

// GET /api/report/passwords - v3 format
router.get('/report/passwords', isAuth, async (req, res) => {
  if (!cache.users.length) await loadADData(req);
  const days = parseInt(req.query.days) || 30;
  const now = Date.now();
  const dayMs = 24 * 60 * 60 * 1000;
  
  const expiring = [], expired = [], noExpiry = [];
  
  cache.users.forEach(u => {
    const pwdLastSet = parseInt(getAttr(u, 'pwdLastSet') || '0');
    if (pwdLastSet === 0) return; // Never set
    
    const uac = parseInt(getAttr(u, 'userAccountControl') || '0');
    const dontExpire = !!(uac & 65536);
    
    if (dontExpire) {
      noExpiry.push({
        name: getAttr(u, 'displayName'),
        sam: getAttr(u, 'sAMAccountName'),
        title: getAttr(u, 'title'),
        department: getAttr(u, 'department'),
        pwdLastSet: new Date(pwdLastSet / 10000 - 11644473600000).toISOString().split('T')[0],
        daysUntilExpiry: 9999
      });
      return;
    }
    
    // Max password age: 42 days (default AD)
    const maxAge = 42 * dayMs;
    const expiresAt = pwdLastSet / 10000 - 11644473600000 + maxAge;
    const daysUntilExpiry = Math.floor((expiresAt - now) / dayMs);
    
    const item = {
      name: getAttr(u, 'displayName'),
      sam: getAttr(u, 'sAMAccountName'),
      title: getAttr(u, 'title'),
      department: getAttr(u, 'department'),
      pwdLastSet: new Date(pwdLastSet / 10000 - 11644473600000).toISOString().split('T')[0],
      daysUntilExpiry
    };
    
    if (daysUntilExpiry < 0) expired.push(item);
    else if (daysUntilExpiry <= days) expiring.push(item);
  });
  
  res.json({
    success: true,
    stats: { total: cache.users.length, expiring: expiring.length, expired: expired.length, noExpiry: noExpiry.length },
    expiring: expiring, expired: expired, noExpiry: noExpiry, noexpiry: noExpiry,
    total: cache.users.length
  });
});

// GET /api/xlsx-view - v3 struct tab format
router.get('/xlsx-view', isAuth, async (req, res) => {
  if (!cache.users.length) await loadADData(req);
  const rows = cache.users.map(u => ({
    cn: getAttr(u, 'displayName'),
    sam: getAttr(u, 'sAMAccountName'),
    mail: getAttr(u, 'mail'),
    department: getAttr(u, 'department'),
    title: getAttr(u, 'title'),
    company: getAttr(u, 'company'),
    l: getAttr(u, 'l'),
    manager: getAttr(u, 'manager'),
    description: getAttr(u, 'description'),
    hasDiff: false
  }));
  
  res.json({ success: true, rows, total: rows.length });
});

// GET /api/audit - recent audit log (v3 expects array with ts, operator, action, target, details)
router.get('/audit', isAuth, async (req, res) => {
  const dbPath = '/opt/agro-user-manager-v3/data/audit.db';
  try {
    const Database = require('better-sqlite3');
    const db = new Database(dbPath, { readonly: true });
    const rows = db.prepare('SELECT * FROM audit ORDER BY id DESC LIMIT 100').all();
    db.close();
    return res.json(rows);
  } catch(e) {
    res.json([]);
  }
});

// GET /api/audit/operators
router.get('/audit/operators', isAuth, async (req, res) => {
  const dbPath = '/opt/agro-user-manager-v3/data/audit.db';
  try {
    const Database = require('better-sqlite3');
    const db = new Database(dbPath, { readonly: true });
    const rows = db.prepare('SELECT DISTINCT operator FROM audit ORDER BY operator').all();
    db.close();
    return res.json(rows.map(r => r.operator));
  } catch(e) {
    res.json([]);
  }
});

// GET /api/audit/download
router.get('/audit/download', isAuth, async (req, res) => {
  const dbPath = '/opt/agro-user-manager-v3/data/audit.db';
  try {
    const Database = require('better-sqlite3');
    const db = new Database(dbPath, { readonly: true });
    const op = req.query.operator;
    const rows = op
      ? db.prepare('SELECT * FROM audit WHERE operator = ? ORDER BY id DESC').all(op)
      : db.prepare('SELECT * FROM audit ORDER BY id DESC').all();
    db.close();
    let csv = 'ts;operator;action;target;details\n';
    rows.forEach(r => csv += `${r.ts};${r.operator};${r.action};${r.target};${(r.details||'').replace(/"/g,'""')}\n`);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename=audit.csv');
    res.send('\uFEFF' + csv);
  } catch(e) {
    res.status(500).send('Audit DB not available');
  }
});

// GET /api/report/duplicates - find duplicate displayName users
router.get('/report/duplicates', isAuth, async (req, res) => {
  if (!cache.users.length) await loadADData(req);
  const nameMap = {};
  cache.users.forEach(u => {
    const name = getAttr(u, 'displayName');
    if (!name) return;
    if (!nameMap[name]) nameMap[name] = [];
    nameMap[name].push({ sam: getAttr(u, 'sAMAccountName'), dn: u.dn });
  });
  const dupes = Object.entries(nameMap).filter(([, users]) => users.length > 1).map(([name, users]) => ({ name, users }));
  res.json(dupes);
});

// GET /api/report/empty-attrs - find users with empty attributes
router.get('/report/empty-attrs', isAuth, async (req, res) => {
  if (!cache.users.length) await loadADData(req);
  const attrs = ['title', 'department', 'company', 'manager', 'mail', 'l', 'telephoneNumber', 'mobile'];
  const result = [];
  cache.users.forEach(u => {
    const empty = attrs.filter(a => !getAttr(u, a));
    if (empty.length) {
      result.push({ name: getAttr(u, 'displayName'), sam: getAttr(u, 'sAMAccountName'), dn: u.dn, empty });
    }
  });
  res.json(result);
});

// GET /api/search-user - search users from cache
router.get('/search-user', isAuth, async (req, res) => {
  if (!cache.users.length) await loadADData(req);
  const q = (req.query.q || '').toLowerCase();
  if (!q) return res.json([]);
  const results = cache.users.filter(u =>
    (getAttr(u, 'displayName') || '').toLowerCase().includes(q) ||
    (getAttr(u, 'sAMAccountName') || '').toLowerCase().includes(q) ||
    (getAttr(u, 'title') || '').toLowerCase().includes(q)
  ).slice(0, 50).map(u => ({
    dn: u.dn, displayName: getAttr(u, 'displayName'), sAMAccountName: getAttr(u, 'sAMAccountName'),
    title: getAttr(u, 'title'), department: getAttr(u, 'department'), company: getAttr(u, 'company'),
    mail: getAttr(u, 'mail'), manager: getAttr(u, 'manager'), l: getAttr(u, 'l'),
    userAccountControl: getAttr(u, 'userAccountControl'),
    memberOf: getAttr(u, 'memberOf') || [],
    description: getAttr(u, 'description'), mobile: getAttr(u, 'mobile'),
    telephoneNumber: getAttr(u, 'telephoneNumber')
  }));
  res.json(results);
});

// GET /api/computers/detail
router.get('/computers/detail', isAuth, async (req, res) => {
  if (!cache.computers.length) await loadADData(req);
  const dn = req.query.dn;
  if (!dn) return res.json({ success: false, error: 'DN required' });
  const comp = cache.computers.find(c => c.dn === dn);
  if (!comp) return res.json({ success: false, error: 'Computer not found' });
  res.json({ success: true, computer: comp });
});

// GET /api/user/sessions
router.get('/user/sessions', isAuth, async (req, res) => {
  res.json({ success: true, sessions: [] });
});

module.exports = router;
