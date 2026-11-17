const { app } = require('./app');
const { config } = require('./config/env');
const { pool } = require('./db/pool');

const servidor = app.listen(config.porta, () => {
  const urlBase = config.urlPublica || `http://localhost:${config.porta}`;

  console.log(`[api] Cafeteria backend ouvindo em ${urlBase}`);
  console.log(`[api] Health check: ${urlBase}/health`);
});

async function encerrar(sinal) {
  console.log(`\n[api] Recebido ${sinal}. Encerrando...`);

  servidor.close(async () => {
    await pool.end();
    process.exit(0);
  });
}

process.on('SIGINT', () => encerrar('SIGINT'));
process.on('SIGTERM', () => encerrar('SIGTERM'));
