const express = require('express');
const router = express.Router();
const ldapService = require('../models/ldap');

// Login page
router.get('/login', (req, res) => {
  if (req.session && req.session.user) {
    return res.redirect('/dashboard');
  }
  res.render('pages/login', { 
    title: 'Login',
    error: null 
  });
});

// Login handler
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.render('pages/login', {
        title: 'Login',
        error: 'Please enter username and password'
      });
    }

    // Authenticate user via LDAP
    const user = await ldapService.authenticate(username, password);
    
    // Store user in session
    req.session.user = {
      dn: user.dn,
      username: user.username,
      displayName: user.displayName,
      email: user.email,
      memberOf: user.memberOf,
      roles: []
    };

    // Redirect to originally requested page or dashboard
    const returnTo = req.session.returnTo || '/dashboard';
    delete req.session.returnTo;
    res.redirect(returnTo);
  } catch (error) {
    console.error('Login error:', error);
    res.render('pages/login', {
      title: 'Login',
      error: 'Invalid username or password'
    });
  }
});

// Logout handler
router.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Logout error:', err);
    }
    res.redirect('/login');
  });
});

module.exports = router;
