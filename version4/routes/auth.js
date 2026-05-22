const express = require('express');
const router = express.Router();
const ldap = require('ldapjs');
const config = require('../config/config');

// Login page (HTML)
router.get('/login', (req, res) => {
  if (req.session?.authenticated) return res.redirect('/');
  res.render('pages/login', { title: 'Login', error: null });
});

// Login handler (JSON API for v3 frontend)
router.post('/login', async (req, res) => {
  try {
    const { username, password, adIp } = req.body;
    const adUser = username.includes('@') ? username : username + '@rusagroeco.ru';
    const dcIPs = [adIp || '10.1.20.21', '10.0.2.21'].filter((v, i, a) => a.indexOf(v) === i);
    
    const tryLogin = async (idx) => {
      if (idx >= dcIPs.length) {
        return res.json({ success: false, error: 'Неверный логин/пароль или сервер недоступен' });
      }
      
      const adUrl = 'ldaps://' + dcIPs[idx];
      const client = ldap.createClient({ url: adUrl, tlsOptions: { rejectUnauthorized: false } });
      
      return new Promise((resolve) => {
        client.bind(adUser, password, (err) => {
          if (err) {
            client.destroy();
            return tryLogin(idx + 1).then(resolve);
          }
          
          req.session.authenticated = true;
          req.session.adUser = adUser;
          req.session.adPass = password;
          req.session.adUrl = adUrl;
          req.session.username = username;
          req.session.user = { dn: adUser, username, displayName: username };
          
          client.unbind();
          res.json({ success: true, server: dcIPs[idx] });
          resolve();
        });
      });
    };
    
    tryLogin(0);
  } catch (error) {
    console.error('Login error:', error);
    res.json({ success: false, error: 'Ошибка входа' });
  }
});

// Check auth status
router.get('/check', (req, res) => {
  res.json({ authenticated: !!req.session?.authenticated });
});

// Logout
router.post('/logout', (req, res) => {
  req.session.destroy(() => res.json({ success: true }));
});

module.exports = router;
