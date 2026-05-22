const express = require('express');
const router = express.Router();

// GET /dashboard - Dashboard page
router.get('/', (req, res) => {
  res.render('pages/dashboard', {
    title: 'Панель управления',
    user: req.session.user
  });
});

module.exports = router;
