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

// Create user
app.post('/api/users', isAuthenticated, async (req, res) => {
  try {
    const data = req.body;
    if (!data.sAMAccountName || !data.cn) {
      return res.json({ success: false, message: 'Missing required fields' });
    }
    const bind = global.currentBindDN || 'vardo001@rusagroeco.ru';
    const pass = global.currentBindPass || '!P09710023p2023';
    const host = global.currentLdapHost || 'ldap://10.0.2.21:389';
    const ou = data.ou || 'OU=Users,DC=rusagroeco,DC=ru';
    const dn = 'CN=' + data.cn + ',' + ou;
    const fs = require('fs');
    const pwdEncoded = Buffer.from('"' + (data.userPassword || 'Password123') + '"').toString('base64');
    var ldif = 'dn: ' + dn + '\n'; 
    ldif += 'objectClass: user\nobjectClass: organizationalPerson\nobjectClass: person\nobjectClass: top\n'; 
    ldif += 'cn: ' + data.cn + '\nsn: ' + (data.sn || data.cn) + '\ngivenName: ' + (data.givenName || data.cn.split(' ')[0]) + '\n';
    ldif += 'sAMAccountName: ' + data.sAMAccountName + '\n';
    if (data.mail) ldif += 'mail: ' + data.mail + '\n';
    ldif += 'unicodePwd:: ' + pwdEncoded + '\nuserAccountControl: 512\n';
    const tmpfile = '/tmp/create_' + Date.now() + '.ldif';
    fs.writeFileSync(tmpfile, ldif);
    const result = require('child_process').execSync('ldapmodify -x -H ' + host + ' -D \"' + bind + '\" -w \"' + pass + '\" -f ' + tmpfile + ' 2>&1', {timeout: 10000});
    fs.unlinkSync(tmpfile);
    res.json({ success: true, message: 'User created', dn: dn });
  } catch(e) {
    res.json({ success: false, message: e.message || 'Error' });
  }
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
