const express = require('express');

const {
  criar,
  listar,
} = require('../controllers/transferencias.controller');

const router = express.Router();

router.post('/api/transferencias', criar);
router.get('/api/transferencias', listar);

module.exports = router;
