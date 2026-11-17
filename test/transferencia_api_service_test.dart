import 'dart:convert';

import 'package:cafeteria/models/transferencia.dart';
import 'package:cafeteria/services/transferencia_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String _uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

Transferencia _criarTransferencia() {
  return Transferencia(
    uuid: _uuid,
    nome: 'Café com Leite',
    valor: 12,
    id: 7,
    icone: Icons.local_cafe,
    criadoEm: DateTime.utc(2026, 11, 15, 12),
  );
}

http.Response _respostaJson(Object? corpo, int status) {
  return http.Response(
    jsonEncode(corpo),
    status,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

void main() {
  test('envia POST para a API e retorna o id do servidor', () async {
    final Transferencia transferencia = _criarTransferencia();
    late http.Request requisicao;

    final MockClient cliente = MockClient((http.Request request) async {
      requisicao = request;
      return _respostaJson(<String, Object?>{
        'id': 42,
        'clientUuid': transferencia.uuid,
        'nome': transferencia.nome,
        'valor': transferencia.valor,
        'identificador': transferencia.id,
        'iconeCodigo': transferencia.icone.codePoint,
        'criadoEm': transferencia.criadoEm.toIso8601String(),
        'sincronizado': true,
      }, 201);
    });

    final TransferenciaApiService servico = TransferenciaApiService(
      cliente: cliente,
      baseUrl: 'http://localhost:3000/',
    );

    final int remoteId = await servico.enviar(transferencia);

    expect(remoteId, 42);
    expect(requisicao.method, 'POST');
    expect(
      requisicao.url.toString(),
      'http://localhost:3000/api/transferencias',
    );
    expect(requisicao.headers['Content-Type'], contains('application/json'));

    final Map<String, dynamic> enviado =
        jsonDecode(requisicao.body) as Map<String, dynamic>;
    expect(enviado['clientUuid'], transferencia.uuid);
    expect(enviado['nome'], transferencia.nome);
    expect(enviado['valor'], transferencia.valor);
    expect(enviado['identificador'], transferencia.id);
    expect(enviado['iconeCodigo'], transferencia.icone.codePoint);
    expect(
      enviado['criadoEm'],
      transferencia.criadoEm.toUtc().toIso8601String(),
    );

    servico.dispose();
  });

  test('aceita HTTP 200 em reenvio idempotente', () async {
    final MockClient cliente = MockClient((http.Request request) async {
      return _respostaJson(<String, Object?>{'id': 42}, 200);
    });
    final TransferenciaApiService servico = TransferenciaApiService(
      cliente: cliente,
      baseUrl: 'http://localhost:3000',
    );

    final int remoteId = await servico.enviar(_criarTransferencia());

    expect(remoteId, 42);
    servico.dispose();
  });

  test('lança exceção com status 400 e mensagem da API', () async {
    final MockClient cliente = MockClient((http.Request request) async {
      return _respostaJson(<String, Object?>{
        'erro': 'Dados inválidos.',
        'detalhes': <String>['valor deve ser um número maior ou igual a zero.'],
      }, 400);
    });
    final TransferenciaApiService servico = TransferenciaApiService(
      cliente: cliente,
      baseUrl: 'http://localhost:3000',
    );

    await expectLater(
      servico.enviar(_criarTransferencia()),
      throwsA(
        isA<TransferenciaApiException>()
            .having((erro) => erro.statusCode, 'statusCode', 400)
            .having(
              (erro) => erro.mensagem,
              'mensagem',
              contains('Dados inválidos'),
            ),
      ),
    );

    servico.dispose();
  });

  test('lança exceção com status 500', () async {
    final MockClient cliente = MockClient((http.Request request) async {
      return http.Response('Falha interna', 500);
    });
    final TransferenciaApiService servico = TransferenciaApiService(
      cliente: cliente,
      baseUrl: 'http://localhost:3000',
    );

    await expectLater(
      servico.enviar(_criarTransferencia()),
      throwsA(
        isA<TransferenciaApiException>().having(
          (erro) => erro.statusCode,
          'statusCode',
          500,
        ),
      ),
    );

    servico.dispose();
  });

  test('converte falha de conexão em TransferenciaApiException', () async {
    final MockClient cliente = MockClient((http.Request request) async {
      throw http.ClientException('conexão recusada');
    });
    final TransferenciaApiService servico = TransferenciaApiService(
      cliente: cliente,
      baseUrl: 'http://localhost:3000',
    );

    await expectLater(
      servico.enviar(_criarTransferencia()),
      throwsA(
        isA<TransferenciaApiException>()
            .having((erro) => erro.statusCode, 'statusCode', isNull)
            .having(
              (erro) => erro.mensagem,
              'mensagem',
              contains('Não foi possível conectar'),
            ),
      ),
    );

    servico.dispose();
  });

  test('listar converte o JSON da API em modelos', () async {
    final MockClient cliente = MockClient((http.Request request) async {
      return _respostaJson(<Object?>[
        <String, Object?>{
          'id': 10,
          'clientUuid': _uuid,
          'nome': 'Pão de Queijo',
          'valor': 4.0,
          'identificador': 3,
          'iconeCodigo': Icons.bakery_dining.codePoint,
          'criadoEm': '2026-01-02T03:04:05.000Z',
          'sincronizado': true,
        },
      ], 200);
    });
    final TransferenciaApiService servico = TransferenciaApiService(
      cliente: cliente,
      baseUrl: 'http://localhost:3000',
    );

    final List<Transferencia> lista = await servico.listar();

    expect(lista, hasLength(1));
    expect(lista.single.remoteId, 10);
    expect(lista.single.uuid, _uuid);
    expect(lista.single.nome, 'Pão de Queijo');
    expect(lista.single.valor, 4.0);
    expect(lista.single.id, 3);
    expect(lista.single.icone, Icons.bakery_dining);
    expect(lista.single.sincronizado, isTrue);

    servico.dispose();
  });
}
