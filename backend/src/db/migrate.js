const fs = require('fs');
const path = require('path');

const {
  validarConfiguracaoBanco,
  descreverBanco,
} = require('../config/env');
const { pool } = require('./pool');

async function migrar() {
  const faltando = validarConfiguracaoBanco();

  if (faltando.length > 0) {
    console.error(
      'Configuração do banco incompleta. Defina no backend/.env ou nas variáveis de ambiente:',
    );
    faltando.forEach((variavel) => console.error(`  - ${variavel}`));
    console.error('Use backend/.env.example como modelo.');
    process.exitCode = 1;
    return;
  }

  const caminhoSchema = path.join(__dirname, 'schema.sql');
  const schema = fs.readFileSync(caminhoSchema, 'utf8');

  console.log(`Aplicando schema em ${descreverBanco()}...`);

  await pool.query(schema);
  console.log('Schema aplicado com sucesso.');
}

migrar()
  .catch((erro) => {
    console.error('Falha ao aplicar o schema:', erro.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
