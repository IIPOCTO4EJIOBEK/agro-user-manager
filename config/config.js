require('dotenv').config();

module.exports = {
  ldap: {
    primary: process.env.LDAP_HOST_PRIMARY || 'ldaps://10.1.20.21:636',
    secondary: process.env.LDAP_HOST_SECONDARY || 'ldaps://10.0.2.21:636',
    baseDN: process.env.LDAP_BASE_DN || 'DC=rusagroeco,DC=ru',
    adminDN: process.env.LDAP_ADMIN_DN || 'CN=Administrator,CN=Users,DC=rusagroeco,DC=ru',
    adminPassword: process.env.LDAP_ADMIN_PASSWORD || '',
    useSSL: process.env.LDAP_USE_SSL === 'true',
    tlsRejectUnauthorized: process.env.LDAP_TLS_REJECT_UNAUTHORIZED !== 'false'
  },
  adGroups: {
    admins: process.env.AD_GROUP_ADMINS || 'AD Administrators',
    network: process.env.AD_GROUP_NETWORK || 'Network Admins',
    wifi: process.env.AD_GROUP_WIFI || 'WiFi Managers',
    monitoring: process.env.AD_GROUP_MONITORING || 'Monitoring Group'
  },
  mikrotik: {
    host: process.env.MIKROTIK_HOST || '10.5.24.150',
    user: process.env.MIKROTIK_USER || 'vardo001',
    password: process.env.MIKROTIK_PASSWORD || '',
    port: parseInt(process.env.MIKROTIK_PORT) || 22
  },
  homeRouter: {
    host: process.env.HOME_ROUTER_HOST || '10.1.222.1',
    user: process.env.HOME_ROUTER_USER || 'admin',
    password: process.env.HOME_ROUTER_PASSWORD || ''
  },
  sms: {
    scriptPath: process.env.SMS_SCRIPT_PATH || '/usr/lib/zabbix/alertscripts/mikrotik_sms.sh'
  },
  server: {
    port: parseInt(process.env.PORT) || 3000,
    sessionSecret: process.env.SESSION_SECRET || 'change-this-secret-in-production',
    env: process.env.NODE_ENV || 'development'
  }
};
