const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

function numero(valor, padrao) {
  const convertido = Number(valor);
  return Number.isFinite(convertido) && convertido > 0 ? convertido : padrao;
}

const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  porta: numero(process.env.PORT, 3000),
  urlPublica: process.env.RENDER_EXTERNAL_URL || '',
  banco: {
    url: process.env.DATABASE_URL || '',
    usarSsl: /^true$/i.test(process.env.PGSSL || ''),
    host: process.env.PGHOST || 'localhost',
    porta: numero(process.env.PGPORT, 5432),
    usuario: process.env.PGUSER || 'postgres',
    senha: process.env.PGPASSWORD || '',
    nome: process.env.PGDATABASE || 'cafeteria_db',
  },
};

function validarConfiguracaoBanco() {
  const faltando = [];

  if (!config.banco.url && !config.banco.senha) {
    faltando.push('DATABASE_URL ou PGPASSWORD');
  }

  return faltando;
}

function descreverBanco() {
  if (config.banco.url) {
    try {
      const url = new URL(config.banco.url);
      return `${url.hostname}:${url.port || 5432}${url.pathname}`;
    } catch {
      return 'DATABASE_URL';
    }
  }

  const { usuario, host, porta, nome } = config.banco;
  return `${usuario}@${host}:${porta}/${nome}`;
}

module.exports = { config, validarConfiguracaoBanco, descreverBanco };
