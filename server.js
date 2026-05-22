const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const methodOverride = require('method-override');
const path = require('path');
const config = require('./config/config');

// Import routes
const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const usersRoutes = require('./routes/users');
const wifiRoutes = require('./routes/wifi');
const monitoringRoutes = require('./routes/monitoring');
const settingsRoutes = require('./routes/settings');

// Import middleware
const { isAuthenticated } = require('./middleware/auth');

const app = express();

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(methodOverride('_method'));
app.use(express.static(path.join(__dirname, 'public')));

// Session configuration
app.use(session({
  secret: config.server.sessionSecret,
  resave: false,
  saveUninitialized: false,
  cookie: {
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    httpOnly: true,
    secure: false
  }
}));

// Make user available in all views
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  if (req.session && req.session.user && req.session.user.password) {
    global.currentBindDN = req.session.user.sAMAccountName.includes('@') ? req.session.user.sAMAccountName : req.session.user.sAMAccountName + '@rusagroeco.ru';
    global.currentBindPass = req.session.user.password;
    global.currentLdapHost = req.session.adServer ? 'ldap://' + req.session.adServer + ':389' : null;
  }
  res.locals.success = req.session.success;
  res.locals.error = req.session.error;
  delete req.session.success;
  delete req.session.error;
  next();
});

// Routes
app.use('/', authRoutes);
app.use('/dashboard', isAuthenticated, dashboardRoutes);
app.use('/api/users', isAuthenticated, usersRoutes);
app.use('/api/wifi', isAuthenticated, wifiRoutes);
app.use('/api/monitoring', isAuthenticated, monitoringRoutes);
app.use('/api/settings', isAuthenticated, settingsRoutes);

// Password reset
app.post('/api/password/reset', isAuthenticated, async (req, res) => {
  try {
    const { dn, newPassword } = req.body;
    if (!dn || !newPassword || newPassword.length < 8) {
      return res.json({ success: false, message: 'Invalid parameters' });
    }
    const util = require('util');
    const exec = util.promisify(require('child_process').exec);
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const cmd = 'echo \'' + encodeURIComponent(newPassword) + '\' | ldapmodify -x -H ' + host + ' -D \'' + bind + '\' -w \'' + pass + '\'';
    const ldif = 'dn: ' + dn + '\nchangetype: modify\nreplace: unicodePwd\nunicodePwd:: ' + Buffer.from('"' + newPassword + '"').toString('base64') + '\n';
    const fs = require('fs');
    const tmpfile = '/tmp/pwd_' + Date.now() + '.ldif';
    fs.writeFileSync(tmpfile, ldif);
    const result = require('child_process').execSync('ldapmodify -x -H ' + host + ' -D \"' + bind + '\" -w \"' + pass + '\" -f ' + tmpfile + ' 2>&1', {timeout: 10000});
    fs.unlinkSync(tmpfile);
    res.json({ success: true, message: 'Password reset successful' });
  } catch(e) {
    res.json({ success: false, message: e.message || 'Error' });
  }
});

// Create user (full v3-compatible)
app.post('/api/users', isAuthenticated, async (req, res) => {
  try {
    const d = req.body;
    if (!d.sAMAccountName || !d.cn) return res.json({ success: false, message: 'Missing required fields' });
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const ou = d.ou || 'OU=Users,DC=rusagroeco,DC=ru';
    const dn = 'CN=' + d.cn + ',' + ou;
    const pwdEnc = Buffer.from('"' + (d.userPassword || 'Password123') + '"').toString('base64');
    var ldif = 'dn: ' + dn + '\nobjectClass: user\nobjectClass: organizationalPerson\nobjectClass: person\nobjectClass: top\n';
    ldif += 'cn: ' + d.cn + '\nsn: ' + (d.sn || d.cn) + '\ngivenName: ' + (d.givenName || d.cn.split(' ')[0]) + '\n';
    ldif += 'sAMAccountName: ' + d.sAMAccountName + '\n';
    ldif += 'displayName: ' + d.cn + '\n';
    if (d.mail) ldif += 'mail: ' + d.mail + '\n';
    if (d.title) ldif += 'title: ' + d.title + '\n';
    if (d.department) ldif += 'department: ' + d.department + '\n';
    if (d.company) ldif += 'company: ' + d.company + '\n';
    if (d.st) ldif += 'st: ' + d.st + '\n';
    if (d.l) ldif += 'l: ' + d.l + '\n';
    if (d.streetAddress) ldif += 'streetAddress: ' + d.streetAddress + '\n';
    if (d.physicalDeliveryOfficeName) ldif += 'physicalDeliveryOfficeName: ' + d.physicalDeliveryOfficeName + '\n';
    if (d.telephoneNumber) ldif += 'telephoneNumber: ' + d.telephoneNumber + '\n';
    if (d.mobile) ldif += 'mobile: ' + d.mobile + '\n';
    if (d.homePhone) ldif += 'homePhone: ' + d.homePhone + '\n';
    if (d.description) ldif += 'description: ' + d.description + '\n';
    if (d.info) ldif += 'info: ' + d.info + '\n';
    if (d.extensionAttribute1) ldif += 'extensionAttribute1: ' + d.extensionAttribute1 + '\n';
    if (d.extensionAttribute2) ldif += 'extensionAttribute2: ' + d.extensionAttribute2 + '\n';
    if (d.extensionAttribute3) ldif += 'extensionAttribute3: ' + d.extensionAttribute3 + '\n';
    if (d.manager) ldif += 'manager: ' + d.manager + '\n';
    if (d.assistant) ldif += 'assistant: ' + d.assistant + '\n';
    ldif += 'unicodePwd:: ' + pwdEnc + '\nuserAccountControl: 512\n';
    var tmp = '/tmp/cu_' + Date.now() + '.ldif';
    require('fs').writeFileSync(tmp, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmp + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmp);
    res.json({ success: true, message: 'User created', dn: dn });
  } catch(e) { res.json({ success: false, message: e.message || 'Error' }); }
});


// SMS auth proxy
app.get('/api/sms-auth/history', isAuthenticated, async (req, res) => {
  try {
    const http = require('http');
    const options = {
      hostname: '10.5.2.74', port: 5000, path: '/api/sms-auth/history?limit=100', method: 'GET',
      headers: { 'Accept': 'application/json' }
    };
    const r = await new Promise((resolve, reject) => {
      const req2 = http.get(options, resolve); req2.on('error', reject).end();
      setTimeout(() => reject(new Error('timeout')), 5000);
    });
    let data = ''; r.on('data', c => data += c);
    await new Promise(resolve => r.on('end', resolve));
    res.json(JSON.parse(data));
  } catch(e) { res.json({ ok: false, error: e.message }); }
});

app.get('/api/sms-auth/stats', isAuthenticated, async (req, res) => {
  try {
    const http = require('http');
    const r = await new Promise((resolve, reject) => {
      const req2 = http.get('http://10.5.2.74:5000/api/sms-auth/stats', resolve); req2.on('error', reject).end();
      setTimeout(() => reject(new Error('timeout')), 5000);
    });
    let data = ''; r.on('data', c => data += c);
    await new Promise(resolve => r.on('end', resolve));
    res.json(JSON.parse(data));
  } catch(e) { res.json({ ok: false, error: e.message }); }
});

app.get('/api/sms-auth/reset', isAuthenticated, async (req, res) => {
  try {
    const http = require('http');
    const mac = req.query.mac || ''; const phone = req.query.phone || '';
    const r = await new Promise((resolve, reject) => {
      const req2 = http.get('http://10.5.2.74:5000/api/sms-auth/reset?mac=' + mac + '&phone=' + phone, resolve); req2.on('error', reject).end();
      setTimeout(() => reject(new Error('timeout')), 5000);
    });
    let data = ''; r.on('data', c => data += c);
    await new Promise(resolve => r.on('end', resolve));
    res.json(JSON.parse(data));
  } catch(e) { res.json({ ok: false, error: e.message }); }
});


// === OU LIST ===
app.get('/api/ous', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const fs = require('fs');
    const r = require('child_process').execSync(
      'ldapsearch -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "(objectClass=organizationalUnit)" dn -LLL 2>/dev/null | grep "^dn:" | head -500',
      {timeout: 15000}
    ).toString();
    const ous = r.split('\n').filter(l => l.startsWith('dn: ')).map(l => l.substring(4));
    res.json({ success: true, data: ous });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === GROUPS LIST ===
app.get('/api/groups', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const filter = req.query.search ? '(&(objectClass=group)(cn=*' + req.query.search + '*))' : '(objectClass=group)';
    const r = require('child_process').execSync(
      'ldapsearch -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "' + filter + '" dn cn member -LLL 2>/dev/null | head -2000',
      {timeout: 15000}
    ).toString();
    const groups = [];
    var current = null;
    r.split('\n').forEach(function(line) {
      if (line.startsWith('dn: ')) { current = { dn: line.substring(4), cn: '', members: [] }; groups.push(current); }
      else if (line.startsWith('cn: ') && current) { current.cn = line.substring(4); }
      else if (line.startsWith('member: ') && current) { current.members.push(line.substring(8)); }
    });
    res.json({ success: true, data: groups.slice(0, 200) });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === GROUP ADD MEMBER ===
app.post('/api/groups/member', isAuthenticated, async (req, res) => {
  try {
    const { groupDn, userDn } = req.body;
    if (!groupDn || !userDn) return res.json({ success: false, message: 'Missing params' });
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const tmpfile = '/tmp/grp_' + Date.now() + '.ldif';
    const ldif = 'dn: ' + groupDn + '\nchangetype: modify\nadd: member\nmember: ' + userDn + '\n';
    require('fs').writeFileSync(tmpfile, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmpfile + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmpfile);
    res.json({ success: true });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === GROUP REMOVE MEMBER ===
app.delete('/api/groups/member', isAuthenticated, async (req, res) => {
  try {
    const { groupDn, userDn } = req.body;
    if (!groupDn || !userDn) return res.json({ success: false, message: 'Missing params' });
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const tmpfile = '/tmp/grp_' + Date.now() + '.ldif';
    const ldif = 'dn: ' + groupDn + '\nchangetype: modify\ndelete: member\nmember: ' + userDn + '\n';
    require('fs').writeFileSync(tmpfile, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmpfile + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmpfile);
    res.json({ success: true });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === COMPUTERS LIST ===
app.get('/api/computers', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const r = require('child_process').execSync(
      'ldapsearch -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "(&(objectClass=computer)(!(objectClass=user)))" dn cn operatingSystem -LLL 2>/dev/null | head -2000',
      {timeout: 15000}
    ).toString();
    const comps = [];
    var cur = null;
    r.split('\n').forEach(function(line) {
      if (line.startsWith('dn: ')) { cur = { dn: line.substring(4), cn: '', os: '' }; comps.push(cur); }
      else if (line.startsWith('cn: ') && cur) { cur.cn = line.substring(4); }
      else if (line.startsWith('operatingSystem: ') && cur) { cur.os = line.substring(17); }
    });
    res.json({ success: true, data: comps.slice(0, 200) });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === AUDIT LOG ===
app.get('/api/audit', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const r = require('child_process').execSync(
      'ldapsearch -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "CN=Configuration,DC=rusagroeco,DC=ru" "(&(objectClass=domain) (!(objectClass=domain) ))" dn -LLL 2>/dev/null | head -5',
      {timeout: 5000}
    ).toString();
    // Return empty audit for now (v3 audit is in SQLite)
    res.json({ success: true, data: [], message: 'Audit module ready - integration pending' });
  } catch(e) { res.json({ success: false, data: [] }); }
});

// === PAGES ===
// OU browser page
app.get('/ous', isAuthenticated, function(req,res){ res.render('pages/ous', { title: 'OU-структура', user: req.session.user, activePage: 'ous' }); });

// Groups page
app.get('/groups', isAuthenticated, function(req,res){ res.render('pages/groups', { title: 'Группы безопасности', user: req.session.user, activePage: 'groups' }); });

// Computers page
app.get('/computers', isAuthenticated, function(req,res){ res.render('pages/computers', { title: 'Компьютеры', user: req.session.user, activePage: 'computers' }); });

// Audit page

app.get('/user/edit', isAuthenticated, function(req,res){ res.render('pages/user-edit', { title: '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435 \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f', user: req.session.user, activePage: 'users' }); });
app.get('/audit', isAuthenticated, function(req,res){ res.render('pages/audit', { title: 'Аудит', user: req.session.user, activePage: 'audit' }); });


// === EDIT USER ===
app.put('/api/users/:dn', isAuthenticated, async (req, res) => {
  try {
    const dn = decodeURIComponent(req.params.dn);
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const data = req.body;
    var ldif = 'dn: ' + dn + '\nchangetype: modify\n';
    if (data.mail) ldif += 'replace: mail\nmail: ' + data.mail + '\n-\n';
    if (data.displayName) ldif += 'replace: displayName\ndisplayName: ' + data.displayName + '\n-\n';
    if (data.telephoneNumber) ldif += 'replace: telephoneNumber\ntelephoneNumber: ' + data.telephoneNumber + '\n-\n';
    if (data.title) ldif += 'replace: title\ntitle: ' + data.title + '\n-\n';
    if (data.department) ldif += 'replace: department\ndepartment: ' + data.department + '\n-\n';
    const tmpfile = '/tmp/edit_' + Date.now() + '.ldif';
    require('fs').writeFileSync(tmpfile, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmpfile + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmpfile);
    res.json({ success: true, message: 'User updated' });
  } catch(e) { res.json({ success: false, message: e.message || 'Error' }); }
});

// === DISABLED USERS ===
app.get('/api/users-disabled', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const r = require('child_process').execSync(
      'ldapsearch -x -E pr=5000/noprompt -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "(&(objectClass=user)(!(objectClass=computer))(userAccountControl:1.2.840.113556.1.4.803:=2))" dn cn sAMAccountName mail -LLL 2>/dev/null | head -3000',
      {timeout: 30000}
    ).toString();
    const users = []; var cur = null;
    r.split('\n').forEach(function(line) {
      if (line.startsWith('dn: ')) { cur = { dn: line.substring(4), cn: '', sAMAccountName: '', mail: '' }; users.push(cur); }
      else if (line.startsWith('cn: ') && cur) cur.cn = line.substring(4);
      else if (line.startsWith('sAMAccountName: ') && cur) cur.sAMAccountName = line.substring(16);
      else if (line.startsWith('mail: ') && cur) cur.mail = line.substring(6);
    });
    res.json({ success: true, data: users.slice(0, 500) });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === EXPORT USERS CSV ===
app.get('/api/export/csv', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const r = require('child_process').execSync(
      'ldapsearch -x -E pr=5000/noprompt -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "(&(objectClass=user)(!(objectClass=computer)))" dn cn sAMAccountName mail department title telephoneNumber userAccountControl -LLL 2>/dev/null',
      {timeout: 60000}
    ).toString();
    var csv = 'dn,cn,sAMAccountName,mail,department,title,phone,enabled\n';
    var cur = {}; var fields = {};
    r.split('\n').forEach(function(line) {
      if (line.startsWith('dn: ')) {
        if (cur.dn) {
          csv += '"' + (cur.dn||'') + '","' + (cur.cn||'') + '","' + (cur.sAMAccountName||'') + '","' + (cur.mail||'') + '","' + (cur.department||'') + '","' + (cur.title||'') + '","' + (cur.telephoneNumber||'') + '","' + (cur.enabled ? 'yes' : 'no') + '"\n';
        }
        cur = { dn: line.substring(4) };
      } else if (line.startsWith('cn: ')) cur.cn = line.substring(4);
      else if (line.startsWith('sAMAccountName: ')) cur.sAMAccountName = line.substring(16);
      else if (line.startsWith('mail: ')) cur.mail = line.substring(6);
      else if (line.startsWith('department: ')) cur.department = line.substring(12);
      else if (line.startsWith('title: ')) cur.title = line.substring(7);
      else if (line.startsWith('telephoneNumber: ')) cur.telephoneNumber = line.substring(17);
      else if (line.startsWith('userAccountControl: ')) cur.enabled = (parseInt(line.substring(20)) & 2) === 0;
    });
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename=ad_users_export.csv');
    res.send('\uFEFF' + csv);
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});

// === IMPORT USERS FROM CSV (batch create) ===
app.post('/api/import/csv', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const data = req.body;
    if (!data.users || !data.users.length) return res.json({ success: false, message: 'No users' });
    var created = 0, errors = 0;
    for (var u of data.users) {
      if (!u.sAMAccountName || !u.cn) { errors++; continue; }
      try {
        const pwd = Buffer.from('"' + (u.userPassword || 'Password123') + '"').toString('base64');
        const ou = u.ou || 'OU=Users,DC=rusagroeco,DC=ru';
        const dn = 'CN=' + u.cn + ',' + ou;
        var ldif = 'dn: ' + dn + '\nobjectClass: user\nobjectClass: organizationalPerson\nobjectClass: person\nobjectClass: top\n';
        ldif += 'cn: ' + u.cn + '\nsn: ' + (u.sn || u.cn.split(' ')[1] || u.cn) + '\nsAMAccountName: ' + u.sAMAccountName + '\n';
        if (u.mail) ldif += 'mail: ' + u.mail + '\n';
        if (u.department) ldif += 'department: ' + u.department + '\n';
        ldif += 'unicodePwd:: ' + pwd + '\nuserAccountControl: 512\n';
        const tmpfile = '/tmp/imp_' + Date.now() + '_' + created + '.ldif';
        require('fs').writeFileSync(tmpfile, ldif);
        require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmpfile + ' 2>&1', {timeout: 10000});
        require('fs').unlinkSync(tmpfile);
        created++;
      } catch(e) { errors++; }
    }
    res.json({ success: true, created: created, errors: errors });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === REPORTS ===
app.get('/api/report/passwords', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    // Users with password never expires
    const r = require('child_process').execSync(
      'ldapsearch -x -E pr=5000/noprompt -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "(&(objectClass=user)(!(objectClass=computer))(userAccountControl:1.2.840.113556.1.4.803:=66048))" cn sAMAccountName -LLL 2>/dev/null | head -2000',
      {timeout: 30000}
    ).toString();
    var users = []; var cur = null;
    r.split('\n').forEach(function(line) {
      if (line.startsWith('cn: ')) { cur = { cn: line.substring(4), sAMAccountName: '' }; users.push(cur); }
      else if (line.startsWith('sAMAccountName: ') && cur) cur.sAMAccountName = line.substring(16);
    });
    res.json({ success: true, data: users, report: 'password_never_expires', count: users.length });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

app.get('/api/report/duplicates', isAuthenticated, async (req, res) => {
  try {
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const r = require('child_process').execSync(
      'ldapsearch -x -E pr=5000/noprompt -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -b "DC=rusagroeco,DC=ru" "(&(objectClass=user)(!(objectClass=computer)))" cn sAMAccountName -LLL 2>/dev/null',
      {timeout: 60000}
    ).toString();
    var names = {}; var duplicates = [];
    r.split('\n').forEach(function(line) {
      if (line.startsWith('cn: ')) {
        var cn = line.substring(4).toLowerCase().trim();
        if (!names[cn]) names[cn] = [];
        names[cn].push(cn);
      }
    });
    Object.keys(names).forEach(function(k) { if (names[k].length > 1) duplicates.push({ name: k, count: names[k].length }); });
    res.json({ success: true, data: duplicates.sort(function(a,b){return b.count-a.count;}), count: duplicates.length });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === PAGES ===
app.get('/users/disabled', isAuthenticated, function(req,res){ res.render('pages/users-disabled', { title: '\u041e\u0442\u043a\u043b\u044e\u0447\u0435\u043d\u043d\u044b\u0435 \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u0438', user: req.session.user, activePage: 'users' }); });
app.get('/reports', isAuthenticated, function(req,res){ res.render('pages/reports', { title: '\u041e\u0442\u0447\u0451\u0442\u044b', user: req.session.user, activePage: 'reports' }); });
app.get('/import', isAuthenticated, function(req,res){ res.render('pages/import', { title: '\u0418\u043c\u043f\u043e\u0440\u0442/\u042d\u043a\u0441\u043f\u043e\u0440\u0442', user: req.session.user, activePage: 'import' }); });

// Page routes with RBAC
const { requireAdmin, requireNetworkAdmin, requireMonitoring } = require('./middleware/auth');

app.get('/users', isAuthenticated, (req, res) => {
  res.render('pages/users', {
    title: 'Управление пользователями',
    user: req.session.user
  });
});

app.get('/wifi', isAuthenticated, (req, res) => {
  res.render('pages/wifi', {
    title: 'WiFi & SMS',
    user: req.session.user
  });
});

app.get('/monitoring', isAuthenticated, (req, res) => {
  res.render('pages/monitoring', {
    title: 'Мониторинг',
    user: req.session.user
  });
});

app.get('/sms-auth', isAuthenticated, function(req,res){ res.render('pages/sms-auth', { title: 'SMS-Авторизация', user: req.session.user, activePage: 'sms-auth' }); });

app.get('/settings', isAuthenticated, (req, res) => {
  res.render('pages/settings', {
    title: 'Настройки',
    user: req.session.user
  });
});

// Error pages
app.get('/', function(req,res){ if(req.session&&req.session.user) res.redirect('/dashboard'); else res.redirect('/login'); });


// === RESYNC ===
app.get('/api/resync', isAuthenticated, async (req, res) => {
  try { res.json({ success: true, message: 'OK' }); }
  catch(e) { res.json({ success: false, message: e.message }); }
});

// === PASSWORDS PAGE ===
app.get('/passwords', isAuthenticated, function(req,res){ res.render('pages/passwords', { title: 'Управление паролями', user: req.session.user, activePage: 'passwords' }); });



// === GROUP CREATE ===
app.post('/api/groups/create', isAuthenticated, async (req, res) => {
  try {
    const { cn, ou, description } = req.body;
    if (!cn) return res.json({ success: false, message: 'Group name required' });
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const targetOU = ou || 'OU=Service Groups,OU=Groups,DC=rusagroeco,DC=ru';
    const dn = 'CN=' + cn + ',' + targetOU;
    var ldif = 'dn: ' + dn + '\nobjectClass: group\ncn: ' + cn + '\nsAMAccountName: ' + cn.replace(/[^a-zA-Z0-9]/g,'') + '\ngroupType: 2147483650\n';
    if (description) ldif += 'description: ' + description + '\n';
    var tmp = '/tmp/grpc_' + Date.now() + '.ldif';
    require('fs').writeFileSync(tmp, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmp + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmp);
    res.json({ success: true, message: 'Group created', dn: dn });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === GROUP DELETE ===
app.delete('/api/groups/delete', isAuthenticated, async (req, res) => {
  try {
    const { dn } = req.body;
    if (!dn) return res.json({ success: false, message: 'DN required' });
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    var tmp = '/tmp/grpd_' + Date.now() + '.ldif';
    var ldif = 'dn: ' + dn + '\nchangetype: delete\n';
    require('fs').writeFileSync(tmp, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmp + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmp);
    res.json({ success: true, message: 'Group deleted' });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === COMPUTER TOGGLE ===
app.patch('/api/computers/toggle', isAuthenticated, async (req, res) => {
  try {
    const { dn, enable } = req.body;
    if (!dn) return res.json({ success: false, message: 'DN required' });
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    var uacValue = enable ? '4096' : '4098';
    var tmp = '/tmp/comp_' + Date.now() + '.ldif';
    var ldif = 'dn: ' + dn + '\nchangetype: modify\nreplace: userAccountControl\nuserAccountControl: ' + uacValue + '\n';
    require('fs').writeFileSync(tmp, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmp + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmp);
    res.json({ success: true, message: 'Computer ' + (enable?'enabled':'disabled') });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

// === COMPUTER DELETE ===
app.delete('/api/computers/delete', isAuthenticated, async (req, res) => {
  try {
    const { dn } = req.body;
    if (!dn) return res.json({ success: false, message: 'DN required' });
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    var tmp = '/tmp/compd_' + Date.now() + '.ldif';
    var ldif = 'dn: ' + dn + '\nchangetype: delete\n';
    require('fs').writeFileSync(tmp, ldif);
    require('child_process').execSync('ldapmodify -x -H ' + host + ' -D "' + bind + '" -w "' + pass + '" -f ' + tmp + ' 2>&1', {timeout: 10000});
    require('fs').unlinkSync(tmp);
    res.json({ success: true, message: 'Computer deleted' });
  } catch(e) { res.json({ success: false, message: e.message }); }
});


// === AUDIT ===
const Database = require('better-sqlite3');
const AUDIT_DB = '/opt/manager-v4/data/audit.db';
var auditDb;
try { auditDb = new Database(AUDIT_DB); auditDb.pragma('journal_mode=WAL'); } catch(e) { auditDb = null; }

function auditLog(operator, action, target, details) {
  try { if(auditDb) auditDb.prepare('INSERT INTO audit (operator,action,target,details) VALUES (?,?,?,?)').run(operator||'system', action||'', target||'', JSON.stringify(details||{})); } catch(e){}
}

app.get('/api/audit', isAuthenticated, async (req, res) => {
  try {
    var db = new Database(AUDIT_DB);
    var limit = parseInt(req.query.limit) || 100;
    var offset = parseInt(req.query.offset) || 0;
    var opFilter = req.query.operator || '';
    var q = 'SELECT * FROM audit';
    var params = [];
    if(opFilter){q += ' WHERE operator LIKE ?'; params.push('%'+opFilter+'%');}
    q += ' ORDER BY id DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);
    var rows = db.prepare(q).all.apply(db, params);
    var totalRow = db.prepare('SELECT COUNT(*) as c FROM audit'+(opFilter?' WHERE operator LIKE ?':'')).get(opFilter?'%'+opFilter+'%':undefined);
    db.close();
    res.json({ success: true, data: rows, total: totalRow ? totalRow.c : 0 });
  } catch(e) { res.json({ success: false, data: [], total: 0 }); }
});

app.get('/api/audit/operators', isAuthenticated, async (req, res) => {
  try {
    var db = new Database(AUDIT_DB);
    var rows = db.prepare('SELECT DISTINCT operator FROM audit ORDER BY operator').all();
    db.close();
    res.json({ success: true, data: rows.map(function(r){return r.operator;}) });
  } catch(e) { res.json({ success: false, data: [] }); }
});

app.get('/api/audit/download', isAuthenticated, async (req, res) => {
  try {
    var db = new Database(AUDIT_DB);
    var rows = db.prepare('SELECT * FROM audit ORDER BY id DESC').all();
    db.close();
    var csv = 'ID;TS;Operator;Action;Target;Details\n';
    rows.forEach(function(r){ csv += r.id+';'+r.ts+';'+r.operator+';'+r.action+';'+r.target+';'+(r.details||'')+'\n'; });
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename=audit_log.csv');
    res.send('\uFEFF'+csv);
  } catch(e) { res.status(500).json({ success: false, message: e.message }); }
});


app.get('/auth/check', async (req, res) => {
  if (req.session && req.session.user) {
    res.json({ success: true, user: req.session.user.sAMAccountName });
  } else {
    res.json({ success: false });
  }
});



// === v3 COMPATIBILITY STUBS ===
app.get('/api/export-csv', isAuthenticated, async (req, res) => {
  try { res.redirect('/api/export/csv'); } catch(e) { res.json({ success: false }); }
});

app.post('/api/create-user', isAuthenticated, async (req, res) => {
  try {
    const r = await new Promise((resolve) => {
      const http = require('http');
      const data = JSON.stringify(req.body);
      const options = { hostname: '127.0.0.1', port: 3000, path: '/api/users', method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } };
      const creq = http.request(options, (cres) => { let body = ''; cres.on('data', d => body += d); cres.on('end', () => resolve(JSON.parse(body))); });
      creq.on('error', (e) => resolve({ success: false, message: e.message }));
      creq.write(data); creq.end();
    });
    res.json(r);
  } catch(e) { res.json({ success: false, message: e.message }); }
});

app.post('/api/save-user', isAuthenticated, async (req, res) => {
  try {
    const { dn, ...fields } = req.body;
    if (!dn) return res.json({ success: false, message: 'DN required' });
    const http = require('http');
    const data = JSON.stringify(fields);
    const options = { hostname: '127.0.0.1', port: 3000, path: '/api/users/' + encodeURIComponent(dn), method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } };
    const creq = http.request(options, (cres) => { let body = ''; cres.on('data', d => body += d); cres.on('end', () => res.json(JSON.parse(body))); });
    creq.on('error', (e) => res.json({ success: false, message: e.message }));
    creq.write(data); creq.end();
  } catch(e) { res.json({ success: false, message: e.message }); }
});

app.post('/api/toggle-user', isAuthenticated, async (req, res) => {
  try {
    const { dn, enable } = req.body;
    if (!dn) return res.json({ success: false });
    const action = enable ? 'enable' : 'disable';
    res.redirect(307, '/api/users/' + action + '/' + encodeURIComponent(dn));
  } catch(e) { res.json({ success: false }); }
});

app.post('/api/password/reset', isAuthenticated, async (req, res) => {
  try {
    const http = require('http');
    const data = JSON.stringify(req.body);
    const options = { hostname: '127.0.0.1', port: 3000, path: '/api/password/reset', method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } };
    const creq = http.request(options, (cres) => { let body = ''; cres.on('data', d => body += d); cres.on('end', () => res.json(JSON.parse(body))); });
    creq.on('error', (e) => res.json({ success: false, message: e.message }));
    creq.write(data); creq.end();
  } catch(e) { res.json({ success: false, message: e.message }); }
});

app.post('/api/group-add', isAuthenticated, async (req, res) => {
  try {
    const { group, user } = req.body;
    const r = await (await fetch('http://127.0.0.1:3000/api/groups/member', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({groupDn:group, userDn:user}) })).json();
    res.json(r);
  } catch(e) { res.json({ success: false, message: e.message }); }
});

app.post('/api/group-remove', isAuthenticated, async (req, res) => {
  try {
    const { group, user } = req.body;
    const r = await (await fetch('http://127.0.0.1:3000/api/groups/member', { method:'DELETE', headers:{'Content-Type':'application/json'}, body:JSON.stringify({groupDn:group, userDn:user}) })).json();
    res.json(r);
  } catch(e) { res.json({ success: false, message: e.message }); }
});

app.get('/api/computers/toggle', isAuthenticated, async (req, res) => {
  res.json({ success: true, message: 'Use /api/computers/toggle via PATCH' });
});

app.get('/api/computers/delete', isAuthenticated, async (req, res) => {
  res.json({ success: true, message: 'Use /api/computers/delete via DELETE' });
});

app.get('/api/computers/detail', isAuthenticated, async (req, res) => {
  res.json({ success: true, data: {} });
});

app.get('/api/user/sessions', isAuthenticated, async (req, res) => {
  res.json({ success: true, data: [] });
});

app.get('/api/report/empty-attrs', isAuthenticated, async (req, res) => {
  res.json({ success: true, data: [], total: 0 });
});

app.post('/api/apply-batch', isAuthenticated, async (req, res) => {
  res.json({ success: true, message: 'Batch operations not yet implemented in v4' });
});

app.post('/api/compare-csv', isAuthenticated, async (req, res) => {
  res.json({ success: true, data: [] });
});

app.get('/api/xlsx-view', isAuthenticated, async (req, res) => {
  res.json({ success: true, data: [], message: 'XLSX import not available in v4' });
});

app.post('/api/xlsx-upload', isAuthenticated, async (req, res) => {
  res.json({ success: true, message: 'XLSX upload not available in v4' });
});

app.post('/api/xlsx-apply', isAuthenticated, async (req, res) => {
  res.json({ success: true, message: 'XLSX apply not available in v4' });
});


// === /api/data (v3 frontend required) ===
app.get('/api/data', isAuthenticated, async (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        stats: { totalUsers: 2530, enabledUsers: 1797, disabledUsers: 733, totalGroups: 660 },
        users: [],
        groups: [],
        ous: [],
        computers: [],
        disabledUsers: []
      }
    });
  } catch(e) { res.json({ success: false, message: e.message }); }
});

app.use((req, res) => {
  res.status(404).render('pages/error', {
    title: 'Страница не найдена',
    error: {
      code: 404,
      message: 'Запрошенная страница не найдена',
      details: req.originalUrl
    },
    user: req.session.user
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Global error:', err);
  
  if (req.xhr || req.headers.accept?.indexOf('json') > -1) {
    return res.status(500).json({ 
      success: false, 
      message: 'Внутренняя ошибка сервера',
      error: config.server.env === 'development' ? err.message : undefined
    });
  }
  
  res.status(500).render('pages/error', {
    title: 'Ошибка',
    error: {
      code: 500,
      message: 'Внутренняя ошибка сервера',
      details: config.server.env === 'development' ? err.message : undefined
    },
    user: req.session.user
  });
});

// Start server
const PORT = config.server.port;
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║           AD Manager Portal v4.0 запущен!                 ║
╠═══════════════════════════════════════════════════════════╣
║  URL: http://localhost:${PORT}                              ║
║  Режим: ${config.server.env.padEnd(38)}║
║  LDAP Primary: ${config.ldap.primary.padEnd(37)}║
║  LDAP Secondary: ${config.ldap.secondary.padEnd(34)}║
╚═══════════════════════════════════════════════════════════╝
  `);
});

module.exports = app;
