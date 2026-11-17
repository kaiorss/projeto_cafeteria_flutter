const { pool } = require('../db/pool');
const { validarTransferencia } = require('../validators/transferencia.validator');

const CAMPOS_RESPOSTA = `
  id,
  client_uuid,
  nome,
  valor,
  identificador,
  icone_codigo,
  criado_em
`;

const UPSERT_TRANSFERENCIA = `
  INSERT INTO transferencias (
    client_uuid,
    nome,
    valor,
    identificador,
    icone_codigo,
    criado_em
  )
  VALUES ($1, $2, $3, $4, $5, $6)
  ON CONFLICT (client_uuid) DO UPDATE
  SET nome = EXCLUDED.nome,
      valor = EXCLUDED.valor,
      identificador = EXCLUDED.identificador,
      icone_codigo = EXCLUDED.icone_codigo,
      criado_em = EXCLUDED.criado_em
  RETURNING ${CAMPOS_RESPOSTA}, (xmax = 0) AS inserido
`;

function mapearTransferencia(registro) {
  return {
    id: registro.id,
    clientUuid: registro.client_uuid,
    nome: registro.nome,
    valor: Number(registro.valor),
    identificador: registro.identificador,
    iconeCodigo: registro.icone_codigo,
    criadoEm: registro.criado_em.toISOString(),
    sincronizado: true,
  };
}

async function criar(req, res, next) {
  const { valido, detalhes, dados } = validarTransferencia(req.body);

  if (!valido) {
    return res.status(400).json({
      erro: 'Dados inválidos.',
      detalhes,
    });
  }

  try {
    const resultado = await pool.query(UPSERT_TRANSFERENCIA, [
      dados.clientUuid,
      dados.nome,
      dados.valor,
      dados.identificador,
      dados.iconeCodigo,
      dados.criadoEm,
    ]);

    const registro = resultado.rows[0];
    const status = registro.inserido ? 201 : 200;

    return res.status(status).json(mapearTransferencia(registro));
  } catch (erro) {
    return next(erro);
  }
}

async function listar(req, res, next) {
  try {
    const resultado = await pool.query(`
      SELECT ${CAMPOS_RESPOSTA}
      FROM transferencias
      ORDER BY criado_em ASC, id ASC
    `);

    return res.status(200).json(resultado.rows.map(mapearTransferencia));
  } catch (erro) {
    return next(erro);
  }
}

module.exports = { criar, listar };
