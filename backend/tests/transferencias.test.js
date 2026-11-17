const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');

const { app } = require('../src/app');
const { pool } = require('../src/db/pool');

let servidor;
let urlBase;
const uuidsCriados = [];

before(async () => {
  await new Promise((resolve, reject) => {
    servidor = app.listen(0, resolve);
    servidor.on('error', reject);
  });

  urlBase = `http://127.0.0.1:${servidor.address().port}`;
});

after(async () => {
  if (uuidsCriados.length > 0) {
    await pool.query(
      'DELETE FROM transferencias WHERE client_uuid = ANY($1::uuid[])',
      [uuidsCriados],
    );
  }

  if (servidor) {
    await new Promise((resolve) => {
      servidor.close(resolve);
      servidor.closeAllConnections();
    });
  }

  await pool.end();
});

function novoUuid() {
  const uuid = crypto.randomUUID();
  uuidsCriados.push(uuid);
  return uuid;
}

function corpoValido(alteracoes = {}) {
  return {
    clientUuid: novoUuid(),
    nome: 'Café com Leite',
    valor: 12.0,
    identificador: 7,
    iconeCodigo: 58719,
    criadoEm: '2026-11-15T12:00:00.000Z',
    ...alteracoes,
  };
}

function postar(corpo) {
  return fetch(`${urlBase}/api/transferencias`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(corpo),
  });
}

async function listar() {
  const resposta = await fetch(`${urlBase}/api/transferencias`);
  assert.equal(resposta.status, 200);
  return resposta.json();
}

test('POST /api/transferencias cadastra e retorna 201', async () => {
  const corpo = corpoValido();

  const resposta = await postar(corpo);
  const criado = await resposta.json();

  assert.equal(resposta.status, 201);
  assert.equal(typeof criado.id, 'number');
  assert.equal(criado.clientUuid, corpo.clientUuid);
  assert.equal(criado.nome, corpo.nome);
  assert.equal(criado.valor, corpo.valor);
  assert.equal(criado.identificador, corpo.identificador);
  assert.equal(criado.iconeCodigo, corpo.iconeCodigo);
  assert.equal(criado.criadoEm, corpo.criadoEm);
  assert.equal(criado.sincronizado, true);
});

test('POST repetido com o mesmo clientUuid mantém o ID e não duplica', async () => {
  const corpo = corpoValido();

  const primeiraResposta = await postar(corpo);
  const primeira = await primeiraResposta.json();

  const segundaResposta = await postar(corpo);
  const segunda = await segundaResposta.json();

  assert.equal(primeiraResposta.status, 201);
  assert.equal(segundaResposta.status, 200);
  assert.equal(segunda.id, primeira.id);
  assert.equal(segunda.clientUuid, primeira.clientUuid);

  const contagem = await pool.query(
    'SELECT COUNT(*)::int AS total FROM transferencias WHERE client_uuid = $1',
    [corpo.clientUuid],
  );

  assert.equal(contagem.rows[0].total, 1);
});

test('GET /api/transferencias lista registros no formato do Flutter', async () => {
  const corpo = corpoValido({
    nome: 'Cappuccino',
    valor: 8.5,
    identificador: 2,
  });

  const respostaCriacao = await postar(corpo);
  assert.equal(respostaCriacao.status, 201);

  const resposta = await fetch(`${urlBase}/api/transferencias`);
  const lista = await resposta.json();

  assert.equal(resposta.status, 200);
  assert.ok(Array.isArray(lista));

  const encontrado = lista.find(
    (item) => item.clientUuid === corpo.clientUuid,
  );

  assert.ok(encontrado);
  assert.equal(encontrado.nome, 'Cappuccino');
  assert.equal(encontrado.valor, 8.5);
  assert.equal(encontrado.identificador, 2);
  assert.equal(encontrado.sincronizado, true);
  assert.equal(typeof encontrado.id, 'number');
});

test('POST com payload inválido retorna 400 com detalhes', async () => {
  const casos = [
    {
      descricao: 'clientUuid ausente',
      corpo: (() => {
        const corpo = corpoValido();
        delete corpo.clientUuid;
        return corpo;
      })(),
    },
    {
      descricao: 'clientUuid inválido',
      corpo: corpoValido({ clientUuid: 'nao-e-um-uuid' }),
    },
    {
      descricao: 'nome vazio',
      corpo: corpoValido({ nome: '   ' }),
    },
    {
      descricao: 'valor negativo',
      corpo: corpoValido({ valor: -1 }),
    },
    {
      descricao: 'valor como texto',
      corpo: corpoValido({ valor: '12,00' }),
    },
    {
      descricao: 'identificador como texto',
      corpo: corpoValido({ identificador: '7' }),
    },
    {
      descricao: 'criadoEm inválido',
      corpo: corpoValido({ criadoEm: 'ontem' }),
    },
  ];

  for (const caso of casos) {
    const resposta = await postar(caso.corpo);
    const erro = await resposta.json();

    assert.equal(resposta.status, 400, caso.descricao);
    assert.equal(erro.erro, 'Dados inválidos.', caso.descricao);
    assert.ok(
      Array.isArray(erro.detalhes) && erro.detalhes.length > 0,
      caso.descricao,
    );
  }
});

test('POST com JSON malformado retorna 400', async () => {
  const resposta = await fetch(`${urlBase}/api/transferencias`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{',
  });

  assert.equal(resposta.status, 400);
  assert.equal((await resposta.json()).erro, 'JSON inválido.');
});
