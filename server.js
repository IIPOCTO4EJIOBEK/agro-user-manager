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
    secure: config.server.env === 'production'
  }
}));

// Make user available in all views
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
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

// Page routes with RBAC
const { requireAdmin, requireNetworkAdmin, requireMonitoring } = require('./middleware/auth');

app.get('/users', isAuthenticated, requireAdmin, (req, res) => {
  res.render('pages/users', {
    title: 'Управление пользователями',
    user: req.session.user
  });
});

app.get('/wifi', isAuthenticated, requireNetworkAdmin, (req, res) => {
  res.render('pages/wifi', {
    title: 'WiFi & SMS',
    user: req.session.user
  });
});

app.get('/monitoring', isAuthenticated, requireMonitoring, (req, res) => {
  res.render('pages/monitoring', {
    title: 'Мониторинг',
    user: req.session.user
  });
});

app.get('/settings', isAuthenticated, requireAdmin, (req, res) => {
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
