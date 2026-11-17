// Testes do app Cafeteria.
//
// Cobrem o modelo, a persistência SQLite (inclusive após reabrir o banco)
// e o fluxo de cadastro/listagem com o status de sincronização.

import 'dart:convert';
import 'dart:io';

import 'package:cafeteria/database/app_database.dart';
import 'package:cafeteria/database/transferencia_dao.dart';
import 'package:cafeteria/main.dart';
import 'package:cafeteria/models/transferencia.dart';
import 'package:cafeteria/repository/transferencia_repository.dart';
import 'package:cafeteria/screens/transferencias/formulario.dart';
import 'package:cafeteria/services/transferencia_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// O NumberFormat usa espaço não separável (U+00A0) entre "R$" e o valor.
String _normalizar(String texto) => texto.replaceAll('\u00A0', ' ');

Finder _textoExibido(String texto) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && _normalizar(widget.data ?? '') == texto,
  );
}

/// DAO em memória usado nos testes de widget.
///
/// O SQLite real é exercitado no teste de persistência abaixo; aqui evitamos
/// I/O de banco dentro do relógio virtual do `testWidgets`.
class _DaoEmMemoria extends TransferenciaDao {
  _DaoEmMemoria()
    : super(
        AppDatabase(
          factory: databaseFactoryFfiNoIsolate,
          caminhoBanco: inMemoryDatabasePath,
        ),
      );

  final List<Transferencia> _itens = <Transferencia>[];

  @override
  Future<void> inserir(Transferencia transferencia) async {
    _itens.removeWhere((item) => item.uuid == transferencia.uuid);
    _itens.add(transferencia);
  }

  @override
  Future<List<Transferencia>> listar() async {
    return List<Transferencia>.of(_itens);
  }

  @override
  Future<List<Transferencia>> listarPendentes() async {
    return _itens.where((item) => !item.sincronizado).toList();
  }

  @override
  Future<int> contarPendentes() async {
    return _itens.where((item) => !item.sincronizado).length;
  }

  @override
  Future<void> marcarSincronizado(String uuid, {required int remoteId}) async {
    final int indice = _itens.indexWhere((item) => item.uuid == uuid);
    if (indice < 0) {
      return;
    }
    _itens[indice] = _itens[indice].copyWith(
      sincronizado: true,
      remoteId: remoteId,
    );
  }
}

Future<TransferenciaRepository> _criarRepositorioEmMemoria({
  TransferenciaApiService? apiService,
}) async {
  return TransferenciaRepository(dao: _DaoEmMemoria(), apiService: apiService);
}

TransferenciaApiService _criarApiFake(
  Future<http.Response> Function(http.Request) responder,
) {
  return TransferenciaApiService(
    cliente: MockClient(responder),
    baseUrl: 'http://localhost:3000',
  );
}

http.Response _respostaJson(Map<String, Object?> corpo, int statusCode) {
  return http.Response(
    jsonEncode(corpo),
    statusCode,
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Modelo Transferencia', () {
    test('guarda nome, valor, id, ícone padrão e gera uuid', () {
      final consumo = Transferencia(nome: 'Café Expresso', valor: 12.00, id: 1);

      expect(consumo.nome, 'Café Expresso');
      expect(consumo.valor, 12.00);
      expect(consumo.id, 1);
      expect(consumo.icone, Icons.local_cafe);
      expect(consumo.uuid, isNotEmpty);
      expect(consumo.sincronizado, isFalse);
      expect(consumo.remoteId, isNull);
    });

    test('converte para Map do SQLite e volta', () {
      final consumo = Transferencia(
        nome: 'Cappuccino',
        valor: 8.50,
        id: 2,
        icone: Icons.coffee,
        criadoEm: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );

      final Transferencia devolta = Transferencia.fromMap(consumo.toMap());

      expect(devolta.uuid, consumo.uuid);
      expect(devolta.nome, 'Cappuccino');
      expect(devolta.valor, 8.50);
      expect(devolta.id, 2);
      expect(devolta.icone, Icons.coffee);
      expect(devolta.sincronizado, isFalse);
      expect(devolta.criadoEm, consumo.criadoEm);
    });

    test('converte o JSON da API em modelo', () {
      final Transferencia consumo = Transferencia.fromJson(<String, Object?>{
        'id': 10,
        'clientUuid': 'uuid-fixo',
        'nome': 'Pão de Queijo',
        'valor': 4,
        'identificador': 3,
        'iconeCodigo': Icons.bakery_dining.codePoint,
        'criadoEm': '2026-01-02T03:04:05.000Z',
      });

      expect(consumo.remoteId, 10);
      expect(consumo.uuid, 'uuid-fixo');
      expect(consumo.nome, 'Pão de Queijo');
      expect(consumo.valor, 4.0);
      expect(consumo.id, 3);
      expect(consumo.icone, Icons.bakery_dining);
      expect(consumo.sincronizado, isFalse);
    });

    test('copyWith mantém o uuid e altera o status', () {
      final consumo = Transferencia(nome: 'Café', valor: 5, id: 1);
      final sincronizado = consumo.copyWith(sincronizado: true, remoteId: 99);

      expect(sincronizado.uuid, consumo.uuid);
      expect(sincronizado.sincronizado, isTrue);
      expect(sincronizado.remoteId, 99);
    });
  });

  group('Persistência SQLite', () {
    test('mantém registros após fechar e reabrir o banco', () async {
      final Directory diretorio = await Directory.systemTemp.createTemp(
        'cafeteria_teste_',
      );
      final String caminho = p.join(diretorio.path, 'cafeteria.db');

      final AppDatabase banco1 = AppDatabase(
        factory: databaseFactoryFfiNoIsolate,
        caminhoBanco: caminho,
      );
      final TransferenciaDao dao1 = TransferenciaDao(banco1);
      final Transferencia consumo = Transferencia(
        nome: 'Café com Leite',
        valor: 12.00,
        id: 7,
      );

      await dao1.inserir(consumo);
      expect(await dao1.contarPendentes(), 1);
      await banco1.fechar();

      final AppDatabase banco2 = AppDatabase(
        factory: databaseFactoryFfiNoIsolate,
        caminhoBanco: caminho,
      );
      final TransferenciaDao dao2 = TransferenciaDao(banco2);
      final List<Transferencia> registros = await dao2.listar();

      expect(registros, hasLength(1));
      expect(registros.single.uuid, consumo.uuid);
      expect(registros.single.nome, 'Café com Leite');
      expect(registros.single.sincronizado, isFalse);
      expect(await dao2.contarPendentes(), 1);

      await dao2.marcarSincronizado(consumo.uuid, remoteId: 10);
      expect(await dao2.contarPendentes(), 0);
      expect((await dao2.listar()).single.remoteId, 10);

      await banco2.fechar();
      await diretorio.delete(recursive: true);
    });
  });

  group('Sincronização de pendentes', () {
    test('envia os pendentes e só marca após confirmação da API', () async {
      final List<String> uuidsEnviados = <String>[];
      final TransferenciaApiService api = _criarApiFake((
        http.Request request,
      ) async {
        final Map<String, dynamic> corpo =
            jsonDecode(request.body) as Map<String, dynamic>;
        uuidsEnviados.add(corpo['clientUuid'] as String);
        return _respostaJson(<String, Object?>{
          'id': 100 + uuidsEnviados.length,
        }, 201);
      });

      final TransferenciaRepository repository =
          await _criarRepositorioEmMemoria(apiService: api);
      final Transferencia primeiro = await repository.cadastrar(
        Transferencia(nome: 'Café', valor: 5, id: 1),
      );
      final Transferencia segundo = await repository.cadastrar(
        Transferencia(nome: 'Pão de Queijo', valor: 4, id: 2),
      );

      final ResultadoSincronizacao resultado = await repository
          .sincronizarPendentes();

      expect(resultado.totalPendentes, 2);
      expect(resultado.sincronizados, 2);
      expect(resultado.falhas, 0);
      expect(resultado.restantes, 0);
      expect(resultado.interrompidoPorConexao, isFalse);
      expect(uuidsEnviados, <String>[primeiro.uuid, segundo.uuid]);
      expect(await repository.contarPendentes(), 0);

      final List<Transferencia> salvas = await repository.listar();
      expect(salvas.every((item) => item.sincronizado), isTrue);
      expect(salvas.map((item) => item.remoteId).toSet(), <int>{101, 102});

      api.dispose();
    });

    test('mantém o registro pendente quando a API está indisponível', () async {
      final TransferenciaApiService api = _criarApiFake((
        http.Request request,
      ) async {
        throw http.ClientException('Sem conexão');
      });
      final TransferenciaRepository repository =
          await _criarRepositorioEmMemoria(apiService: api);
      await repository.cadastrar(
        Transferencia(nome: 'Cappuccino', valor: 8.50, id: 2),
      );

      final ResultadoSincronizacao resultado = await repository
          .sincronizarPendentes();

      expect(resultado.interrompidoPorConexao, isTrue);
      expect(resultado.sincronizados, 0);
      expect(resultado.falhas, 1);
      expect(resultado.restantes, 1);
      expect(await repository.contarPendentes(), 1);

      final List<Transferencia> salvas = await repository.listar();
      expect(salvas.single.sincronizado, isFalse);
      expect(salvas.single.remoteId, isNull);

      api.dispose();
    });

    test('continua a sincronização após um erro de validação', () async {
      final TransferenciaApiService api = _criarApiFake((
        http.Request request,
      ) async {
        final Map<String, dynamic> corpo =
            jsonDecode(request.body) as Map<String, dynamic>;
        if (corpo['nome'] == 'Inválido') {
          return _respostaJson(<String, Object?>{
            'erro': 'Dados inválidos.',
          }, 400);
        }
        return _respostaJson(<String, Object?>{'id': 77}, 201);
      });
      final TransferenciaRepository repository =
          await _criarRepositorioEmMemoria(apiService: api);
      await repository.cadastrar(
        Transferencia(nome: 'Inválido', valor: 1, id: 1),
      );
      await repository.cadastrar(Transferencia(nome: 'Café', valor: 5, id: 2));

      final ResultadoSincronizacao resultado = await repository
          .sincronizarPendentes();

      expect(resultado.totalPendentes, 2);
      expect(resultado.sincronizados, 1);
      expect(resultado.falhas, 1);
      expect(resultado.restantes, 1);
      expect(resultado.interrompidoPorConexao, isFalse);

      final List<Transferencia> pendentes = await repository.listarPendentes();
      expect(pendentes, hasLength(1));
      expect(pendentes.single.nome, 'Inválido');
      expect(pendentes.single.sincronizado, isFalse);
      expect(pendentes.single.remoteId, isNull);

      api.dispose();
    });
  });

  testWidgets('a lista começa vazia quando o banco não tem registros', (
    WidgetTester tester,
  ) async {
    final TransferenciaRepository repository =
        await _criarRepositorioEmMemoria();

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum consumo cadastrado.'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('o botão flutuante abre a tela de formulário', (
    WidgetTester tester,
  ) async {
    final TransferenciaRepository repository =
        await _criarRepositorioEmMemoria();

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo consumo'));
    await tester.pumpAndSettle();

    expect(find.byType(FormularioTransferencia), findsOneWidget);
    expect(find.text('Nome do consumo'), findsOneWidget);
    expect(find.text('Valor'), findsOneWidget);
    expect(find.text('Identificador'), findsOneWidget);
  });

  testWidgets('cadastra no SQLite, atualiza a lista e marca como pendente', (
    WidgetTester tester,
  ) async {
    final TransferenciaRepository repository =
        await _criarRepositorioEmMemoria();

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo consumo'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome do consumo'),
      'Café com Leite',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '12,00');
    await tester.enterText(
      find.widgetWithText(TextField, 'Identificador'),
      '7',
    );

    await tester.tap(find.text('Salvar consumo'));
    await tester.pumpAndSettle();

    expect(find.byType(FormularioTransferencia), findsNothing);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Café com Leite'), findsOneWidget);
    expect(find.text('Identificador: 7'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(_textoExibido(r'R$ 12,00'), findsOneWidget);

    final List<Transferencia> salvas = await repository.listar();
    expect(salvas, hasLength(1));
    expect(salvas.single.nome, 'Café com Leite');
    expect(salvas.single.sincronizado, isFalse);
    expect(await repository.contarPendentes(), 1);
  });

  testWidgets('campos inválidos não criam registro', (
    WidgetTester tester,
  ) async {
    final TransferenciaRepository repository =
        await _criarRepositorioEmMemoria();

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo consumo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar consumo'));
    await tester.pumpAndSettle();

    expect(find.byType(FormularioTransferencia), findsOneWidget);
    expect(find.text('Preencha todos os campos corretamente!'), findsOneWidget);
    expect(await repository.listar(), isEmpty);
  });

  testWidgets('carrega registros já persistidos ao abrir o aplicativo', (
    WidgetTester tester,
  ) async {
    final TransferenciaRepository repository =
        await _criarRepositorioEmMemoria();

    await repository.cadastrar(
      Transferencia(nome: 'Cappuccino', valor: 8.50, id: 2),
    );

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Cappuccino'), findsOneWidget);
    expect(find.text('Identificador: 2'), findsOneWidget);
    expect(_textoExibido(r'R$ 8,50'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
  });

  testWidgets('sincronização manual envia pendentes e atualiza o contador', (
    WidgetTester tester,
  ) async {
    final TransferenciaApiService api = _criarApiFake((
      http.Request request,
    ) async {
      return _respostaJson(<String, Object?>{'id': 77}, 201);
    });
    final TransferenciaRepository repository = await _criarRepositorioEmMemoria(
      apiService: api,
    );
    await repository.cadastrar(
      Transferencia(nome: 'Café com Leite', valor: 12.00, id: 7),
    );

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizar pendentes (1)'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Sincronizado'), findsNothing);

    await tester.tap(find.text('Sincronizar pendentes (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizar pendentes (0)'), findsOneWidget);
    expect(find.text('Pendente'), findsNothing);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.textContaining('Sincronização concluída'), findsOneWidget);
    expect(await repository.contarPendentes(), 0);
    expect((await repository.listar()).single.remoteId, 77);

    api.dispose();
  });

  testWidgets('mantém pendentes quando a API está indisponível', (
    WidgetTester tester,
  ) async {
    final TransferenciaApiService api = _criarApiFake((
      http.Request request,
    ) async {
      throw http.ClientException('Sem conexão');
    });
    final TransferenciaRepository repository = await _criarRepositorioEmMemoria(
      apiService: api,
    );
    await repository.cadastrar(
      Transferencia(nome: 'Cappuccino', valor: 8.50, id: 2),
    );

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizar pendentes (1)'), findsOneWidget);

    await tester.tap(find.text('Sincronizar pendentes (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizar pendentes (1)'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.textContaining('Sem conexão com a API'), findsOneWidget);
    expect(await repository.contarPendentes(), 1);

    final List<Transferencia> salvas = await repository.listar();
    expect(salvas.single.sincronizado, isFalse);
    expect(salvas.single.remoteId, isNull);

    api.dispose();
  });
}
