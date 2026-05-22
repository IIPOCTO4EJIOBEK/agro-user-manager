const ldapService = require('../models/ldap');
const config = require('../config/config');

// Middleware to check if user is authenticated
function isAuthenticated(req, res, next) {
  if (req.session && req.session.user) {
    return next();
  }
  
  if (req.xhr || req.headers.accept?.indexOf('json') > -1) {
    return res.status(401).json({ success: false, message: 'Unauthorized' });
  }
  
  req.session.returnTo = req.originalUrl;
  return res.redirect('/login');
}

// Middleware to check group membership
function requireGroup(groupNames) {
  const groups = Array.isArray(groupNames) ? groupNames : [groupNames];
  
  return async (req, res, next) => {
    if (!req.session || !req.session.user) {
      if (req.xhr || req.headers.accept?.indexOf('json') > -1) {
        return res.status(401).json({ success: false, message: 'Unauthorized' });
      }
      req.session.returnTo = req.originalUrl;
      return res.redirect('/login');
    }

    const userDN = req.session.user.distinguishedName;
    
    try {
      // Check if user is in any of the required groups
      const hasAccess = await ldapService.isUserInAnyGroup(userDN, groups);
      
      if (hasAccess) {
        return next();
      }
      
      // Log access denied
      console.log(`Access denied for user ${req.session.user.sAMAccountName} to ${req.path}. Required groups: ${groups.join(', ')}`);
      
      if (req.xhr || req.headers.accept?.indexOf('json') > -1) {
        return res.status(403).json({ 
          success: false, 
          message: `Access denied. Required groups: ${groups.join(', ')}` 
        });
      }
      
      return res.render('pages/error', {
        title: 'Access Denied',
        error: {
          code: 403,
          message: 'У вас нет доступа к этой странице',
          details: `Требуемые группы: ${groups.join(', ')}`
        },
        user: req.session.user
      });
    } catch (error) {
      console.error('Error checking group membership:', error);
      
      if (req.xhr || req.headers.accept?.indexOf('json') > -1) {
        return res.status(500).json({ success: false, message: 'Error checking permissions' });
      }
      
      return res.render('pages/error', {
        title: 'Error',
        error: {
          code: 500,
          message: 'Ошибка проверки прав доступа',
          details: error.message
        },
        user: req.session.user
      });
    }
  };
}

// Middleware to check if user is admin
function requireAdmin() {
  return requireGroup(config.adGroups.admins);
}

// Middleware to check network admin access
function requireNetworkAdmin() {
  return requireGroup([config.adGroups.network, config.adGroups.wifi]);
}

// Middleware to check monitoring access
function requireMonitoring() {
  return requireGroup(config.adGroups.monitoring);
}

module.exports = {
  isAuthenticated,
  requireGroup,
  requireAdmin,
  requireNetworkAdmin,
  requireMonitoring
};
