import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/transferencia.dart';

class TransferenciaApiException implements Exception {
  TransferenciaApiException(this.mensagem, {this.statusCode});

  final String mensagem;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'TransferenciaApiException: $mensagem';
    }
    return 'TransferenciaApiException($statusCode): $mensagem';
  }
}

class TransferenciaApiService {
  TransferenciaApiService({http.Client? cliente, String? baseUrl})
    : _cliente = cliente ?? http.Client(),
      _baseUrl = _normalizarBaseUrl(baseUrl ?? ApiConfig.baseUrl);

  final http.Client _cliente;
  final String _baseUrl;

  static const Duration _tempoLimite = Duration(seconds: 15);

  Future<int> enviar(Transferencia transferencia) async {
    final Uri uri = Uri.parse('$_baseUrl/api/transferencias');

    final http.Response resposta;
    try {
      resposta = await _cliente
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(transferencia.toJson()),
          )
          .timeout(_tempoLimite);
    } on TimeoutException {
      throw TransferenciaApiException('Tempo esgotado ao conectar com a API.');
    } on http.ClientException catch (erro) {
      throw TransferenciaApiException(
        'Não foi possível conectar com a API: ${erro.message}',
      );
    }

    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw TransferenciaApiException(
        _mensagemDeErro(resposta),
        statusCode: resposta.statusCode,
      );
    }

    final Object? corpo = _decodificar(resposta);
    if (corpo is! Map<String, dynamic>) {
      throw TransferenciaApiException(
        'Resposta inválida da API.',
        statusCode: resposta.statusCode,
      );
    }

    final Object? id = corpo['id'];
    if (id is! num) {
      throw TransferenciaApiException(
        'A API não retornou o identificador do registro.',
        statusCode: resposta.statusCode,
      );
    }

    return id.toInt();
  }

  Future<List<Transferencia>> listar() async {
    final Uri uri = Uri.parse('$_baseUrl/api/transferencias');

    final http.Response resposta;
    try {
      resposta = await _cliente.get(uri).timeout(_tempoLimite);
    } on TimeoutException {
      throw TransferenciaApiException('Tempo esgotado ao conectar com a API.');
    } on http.ClientException catch (erro) {
      throw TransferenciaApiException(
        'Não foi possível conectar com a API: ${erro.message}',
      );
    }

    if (resposta.statusCode != 200) {
      throw TransferenciaApiException(
        _mensagemDeErro(resposta),
        statusCode: resposta.statusCode,
      );
    }

    final Object? corpo = _decodificar(resposta);
    if (corpo is! List<dynamic>) {
      throw TransferenciaApiException(
        'Resposta inválida da API.',
        statusCode: resposta.statusCode,
      );
    }

    final List<Transferencia> transferencias = <Transferencia>[];
    for (final Object? item in corpo) {
      if (item is! Map<String, dynamic>) {
        throw TransferenciaApiException(
          'Resposta inválida da API.',
          statusCode: resposta.statusCode,
        );
      }
      transferencias.add(Transferencia.fromJson(item));
    }

    return transferencias;
  }

  void dispose() {
    _cliente.close();
  }

  static Object? _decodificar(http.Response resposta) {
    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      throw TransferenciaApiException(
        'Resposta inválida da API.',
        statusCode: resposta.statusCode,
      );
    }
  }

  static String _mensagemDeErro(http.Response resposta) {
    final Object? corpo;
    try {
      corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      return 'Falha ao sincronizar com a API (HTTP ${resposta.statusCode}).';
    }

    if (corpo is Map<String, dynamic>) {
      final Object? erro = corpo['erro'];
      if (erro is String && erro.isNotEmpty) {
        return erro;
      }
    }

    return 'Falha ao sincronizar com a API (HTTP ${resposta.statusCode}).';
  }

  static String _normalizarBaseUrl(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
