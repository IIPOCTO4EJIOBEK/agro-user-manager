const ldapService = require('../models/ldap');

// Middleware to check if user is authenticated
function requireAuth(req, res, next) {
  if (req.session && req.session.user) {
    return next();
  }
  
  // Store original URL for redirect after login
  req.session.returnTo = req.originalUrl;
  res.redirect('/login');
}

// Middleware to check role membership
function requireRole(roleName) {
  return async (req, res, next) => {
    if (!req.session || !req.session.user) {
      return res.redirect('/login');
    }

    try {
      const userDN = req.session.user.dn;
      const isMember = await ldapService.checkGroupMembership(userDN, roleName);
      
      if (isMember) {
        req.session.user.roles = req.session.user.roles || [];
        if (!req.session.user.roles.includes(roleName)) {
          req.session.user.roles.push(roleName);
        }
        return next();
      } else {
        // User doesn't have required role
        if (req.xhr || req.headers.accept?.includes('application/json')) {
          return res.status(403).json({ error: 'Access denied: insufficient privileges' });
        }
        res.status(403).render('pages/error', { 
          title: 'Access Denied',
          message: `You don't have permission to access this page. Required role: ${roleName}`,
          user: req.session.user
        });
      }
    } catch (error) {
      console.error('Role check error:', error);
      res.status(500).render('pages/error', {
        title: 'Error',
        message: 'Failed to verify permissions',
        user: req.session.user
      });
    }
  };
}

// Middleware to check multiple roles (any of them grants access)
function requireAnyRole(roleNames) {
  return async (req, res, next) => {
    if (!req.session || !req.session.user) {
      return res.redirect('/login');
    }

    try {
      const userDN = req.session.user.dn;
      let hasAccess = false;

      for (const roleName of roleNames) {
        const isMember = await ldapService.checkGroupMembership(userDN, roleName);
        if (isMember) {
          hasAccess = true;
          req.session.user.roles = req.session.user.roles || [];
          if (!req.session.user.roles.includes(roleName)) {
            req.session.user.roles.push(roleName);
          }
          break;
        }
      }

      if (hasAccess) {
        return next();
      } else {
        if (req.xhr || req.headers.accept?.includes('application/json')) {
          return res.status(403).json({ error: 'Access denied: insufficient privileges' });
        }
        res.status(403).render('pages/error', {
          title: 'Access Denied',
          message: `You don't have permission to access this page. Required roles: ${roleNames.join(' or ')}`,
          user: req.session.user
        });
      }
    } catch (error) {
      console.error('Role check error:', error);
      res.status(500).render('pages/error', {
        title: 'Error',
        message: 'Failed to verify permissions',
        user: req.session.user
      });
    }
  };
}

// Helper to check if user has a specific role (for use in views)
async function userHasRole(user, roleName) {
  if (!user || !user.dn) return false;
  
  try {
    return await ldapService.checkGroupMembership(user.dn, roleName);
  } catch (error) {
    console.error('Role check error:', error);
    return false;
  }
}

module.exports = {
  requireAuth,
  requireRole,
  requireAnyRole,
  userHasRole
};
