require('dotenv').config({ path: __dirname + '/.env' });

module.exports = {
  // Server
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // LDAP Configuration
  ldap: {
    url: process.env.LDAP_URL || 'ldap://localhost:389',
    baseDN: process.env.LDAP_BASE_DN || 'DC=example,DC=com',
    bindDN: process.env.LDAP_BIND_DN || '',
    bindPassword: process.env.LDAP_BIND_PASSWORD || ''
  },
  
  // AD Groups for Role-Based Access Control
  adGroups: {
    admins: process.env.AD_GROUP_ADMINS || 'AD Administrators',
    network: process.env.AD_GROUP_NETWORK || 'Network Administrators',
    monitor: process.env.AD_GROUP_MONITOR || 'Monitoring Group',
    wifi: process.env.AD_GROUP_WIFI || 'WiFi Managers'
  },
  
  // Session Configuration
  session: {
    secret: process.env.SESSION_SECRET || 'default-secret-change-me',
    timeout: parseInt(process.env.SESSION_TIMEOUT) || 3600000
  },
  
  // Redis (optional)
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379
  },
  
  // Security Settings
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000,
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
  }
};
