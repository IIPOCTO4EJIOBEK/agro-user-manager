const express = require('express');
const router = express.Router();
const ldapService = require('../models/ldap');

// GET /login - Show login page
router.get('/login', (req, res) => {
  if (req.session && req.session.user) {
    return res.redirect('/dashboard');
  }
  res.render('pages/login', { 
    title: 'Вход в систему',
    error: req.query.error,
    returnTo: req.query.returnTo || '/dashboard'
  });
});

// POST /login - Handle login
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.redirect('/login?error=Введите логин и пароль');
    }

    const result = await ldapService.authenticate(username, password);

    if (result.success) {
      // Store user in session
      req.session.user = {
        distinguishedName: result.user.distinguishedName,
        sAMAccountName: result.user.sAMAccountName,
        cn: result.user.cn,
        mail: result.user.mail
      };

      // Get user groups
      const groups = await ldapService.getUserGroups(result.user.distinguishedName);
      req.session.user.groups = groups;

      console.log(`User ${username} logged in successfully. Groups: ${groups.join(', ')}`);

      // Redirect to intended page or dashboard
      const returnTo = req.session.returnTo || '/dashboard';
      delete req.session.returnTo;
      return res.redirect(returnTo);
    } else {
      console.log(`Login failed for ${username}: ${result.message}`);
      return res.redirect(`/login?error=${encodeURIComponent(result.message)}`);
    }
  } catch (error) {
    console.error('Login error:', error);
    return res.redirect(`/login?error=${encodeURIComponent('Ошибка аутентификации: ' + error.message)}`);
  }
});

// GET /logout - Handle logout
router.get('/logout', (req, res) => {
  const username = req.session?.user?.sAMAccountName;
  
  req.session.destroy((err) => {
    if (err) {
      console.error('Error destroying session:', err);
    } else {
      console.log(`User ${username} logged out`);
    }
    res.redirect('/login');
  });
});

module.exports = router;
