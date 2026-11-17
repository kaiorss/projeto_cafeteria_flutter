const express = require('express');

const { validarConfiguracaoBanco } = require('../config/env');
const { pool } = require('../db/pool');

const router = express.Router();

router.get('/health', async (req, res) => {
  const faltando = validarConfiguracaoBanco();

  if (faltando.length > 0) {
    return res.status(503).json({
      status: 'degradado',
      banco: 'nao_configurado',
      variaveisFaltando: faltando,
    });
  }

  try {
    await pool.query('SELECT 1');
    return res.status(200).json({ status: 'ok', banco: 'conectado' });
  } catch (erro) {
    console.error('[health] Banco indisponível:', erro.message);
    return res.status(503).json({
      status: 'degradado',
      banco: 'indisponivel',
    });
  }
});

module.exports = router;
