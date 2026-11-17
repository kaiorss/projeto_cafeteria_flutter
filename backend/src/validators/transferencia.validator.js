const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function validarTransferencia(corpo) {
  if (corpo === null || typeof corpo !== 'object' || Array.isArray(corpo)) {
    return {
      valido: false,
      detalhes: ['O corpo da requisição deve ser um objeto JSON.'],
      dados: null,
    };
  }

  const {
    clientUuid,
    nome,
    valor,
    identificador,
    iconeCodigo,
    criadoEm,
  } = corpo;

  const detalhes = [];

  if (typeof clientUuid !== 'string' || !UUID_REGEX.test(clientUuid.trim())) {
    detalhes.push('clientUuid deve ser um UUID válido.');
  }

  if (typeof nome !== 'string' || nome.trim().length === 0) {
    detalhes.push('nome é obrigatório e deve ser um texto não vazio.');
  }

  if (typeof valor !== 'number' || !Number.isFinite(valor) || valor < 0) {
    detalhes.push('valor deve ser um número maior ou igual a zero.');
  }

  if (
    typeof identificador !== 'number' ||
    !Number.isInteger(identificador)
  ) {
    detalhes.push('identificador deve ser um número inteiro.');
  }

  if (
    iconeCodigo !== undefined &&
    (typeof iconeCodigo !== 'number' || !Number.isInteger(iconeCodigo))
  ) {
    detalhes.push('iconeCodigo deve ser um número inteiro quando informado.');
  }

  if (
    typeof criadoEm !== 'string' ||
    Number.isNaN(Date.parse(criadoEm))
  ) {
    detalhes.push('criadoEm deve ser uma data ISO 8601 válida.');
  }

  if (detalhes.length > 0) {
    return { valido: false, detalhes, dados: null };
  }

  return {
    valido: true,
    detalhes: [],
    dados: {
      clientUuid: clientUuid.trim().toLowerCase(),
      nome: nome.trim(),
      valor,
      identificador,
      iconeCodigo: iconeCodigo ?? 0,
      criadoEm: new Date(criadoEm).toISOString(),
    },
  };
}

module.exports = { validarTransferencia };
