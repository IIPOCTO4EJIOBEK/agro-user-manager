const express = require('express');
const path = require('path');
const session = require('express-session');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');
const methodOverride = require('method-override');
const config = require('./config/config');
const ldapService = require('./models/ldap');

// Import routes
const authRoutes = require('./routes/auth');
const indexRoutes = require('./routes/index');
const usersRoutes = require('./routes/users');
const wifiRoutes = require('./routes/wifi');
const monitoringRoutes = require('./routes/monitoring');
const settingsRoutes = require('./routes/settings');

const app = express();

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable for development
  crossOriginEmbedderPolicy: false
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.maxRequests,
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(methodOverride('_method'));

// Session configuration
app.use(session({
  secret: config.session.secret,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: config.nodeEnv === 'production',
    httpOnly: true,
    maxAge: config.session.timeout
  }
}));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// View engine setup (EJS)
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Make user available in all views
app.use((req, res, next) => {
  res.locals.user = req.session?.user || null;
  res.locals.config = config;
  next();
});

// Routes
app.use('/', indexRoutes);
app.use('/login', authRoutes);
app.use('/dashboard', indexRoutes);
app.use('/users', usersRoutes);
app.use('/wifi', wifiRoutes);
app.use('/monitoring', monitoringRoutes);
app.use('/settings', settingsRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).render('pages/error', {
    title: 'Error',
    message: 'An unexpected error occurred',
    error: config.nodeEnv === 'development' ? err : {},
    user: req.session?.user || null
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).render('pages/error', {
    title: 'Not Found',
    message: 'The page you are looking for does not exist',
    user: req.session?.user || null
  });
});

// Connect to LDAP and start server
async function startServer() {
  try {
    await ldapService.connect();
    
    app.listen(config.port, () => {
      console.log(`✓ AD Manager Portal v4.0 running on port ${config.port}`);
      console.log(`✓ Environment: ${config.nodeEnv}`);
      console.log(`✓ Open http://localhost:${config.port} in your browser`);
    });
  } catch (error) {
    console.error('✗ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('\n✓ SIGTERM received. Shutting down gracefully...');
  await ldapService.disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('\n✓ SIGINT received. Shutting down gracefully...');
  await ldapService.disconnect();
  process.exit(0);
});

startServer();
