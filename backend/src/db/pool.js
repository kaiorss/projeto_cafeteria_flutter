const { Pool } = require('pg');
const { config } = require('../config/env');

const opcoesConexao = config.banco.url
  ? { connectionString: config.banco.url }
  : {
      host: config.banco.host,
      port: config.banco.porta,
      user: config.banco.usuario,
      password: config.banco.senha,
      database: config.banco.nome,
    };

if (config.banco.usarSsl) {
  opcoesConexao.ssl = { rejectUnauthorized: false };
}

const pool = new Pool({
  ...opcoesConexao,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (erro) => {
  console.error('[banco] Erro inesperado no pool do PostgreSQL:', erro.message);
});

module.exports = { pool };
