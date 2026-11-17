import 'dart:io';
import 'dart:ui' as ui;

import 'package:cafeteria/database/app_database.dart';
import 'package:cafeteria/database/transferencia_dao.dart';
import 'package:cafeteria/main.dart';
import 'package:cafeteria/models/transferencia.dart';
import 'package:cafeteria/repository/transferencia_repository.dart';
import 'package:cafeteria/services/transferencia_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _pastaEvidencias = String.fromEnvironment(
  'PASTA_EVIDENCIAS',
  defaultValue: 'evidencias',
);

const String _apiBaseUrlDefinida = String.fromEnvironment('API_BASE_URL');

bool _superficieConvertida = false;

bool get _executandoEmDesktop {
  return !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
}

String get _apiBaseUrl {
  if (_apiBaseUrlDefinida.isNotEmpty) {
    return _apiBaseUrlDefinida;
  }
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cadastra, sincroniza e confirma o registro na API real', (
    WidgetTester tester,
  ) async {
    if (_executandoEmDesktop) {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _carregarFontesReais();
    }

    Directory? diretorio;
    final AppDatabase appDatabase;

    if (_executandoEmDesktop) {
      sqfliteFfiInit();
      diretorio = await Directory.systemTemp.createTemp('cafeteria_b5_');
      appDatabase = AppDatabase(
        factory: databaseFactoryFfiNoIsolate,
        caminhoBanco: p.join(diretorio.path, 'cafeteria.db'),
      );
    } else {
      appDatabase = AppDatabase();
    }

    final Database banco = await appDatabase.abrir();
    await banco.delete('transferencias');

    final TransferenciaApiService api = TransferenciaApiService(
      baseUrl: _apiBaseUrl,
    );
    final TransferenciaRepository repository = TransferenciaRepository(
      dao: TransferenciaDao(appDatabase),
      apiService: api,
    );

    addTearDown(() async {
      api.dispose();
      await appDatabase.fechar();
      final Directory? pastaTemporaria = diretorio;
      if (pastaTemporaria != null && await pastaTemporaria.exists()) {
        await pastaTemporaria.delete(recursive: true);
      }
    });

    await tester.pumpWidget(CafeteriaApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizar pendentes (0)'), findsOneWidget);

    await tester.tap(find.text('Novo consumo'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome do consumo'),
      'Café com Leite',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '12,00');
    await tester.enterText(
      find.widgetWithText(TextField, 'Identificador'),
      '3',
    );
    await tester.pumpAndSettle();

    await _capturarEvidencia(binding, tester, 'formulario');

    await tester.tap(find.text('Salvar consumo'));
    await _aguardar(tester, find.text('Café com Leite'));

    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Sincronizar pendentes (1)'), findsOneWidget);

    await tester.tap(find.text('Sincronizar pendentes (1)'));
    await _aguardar(tester, find.text('Sincronizado'));

    expect(find.text('Sincronizar pendentes (0)'), findsOneWidget);
    expect(find.text('Pendente'), findsNothing);
    expect(await repository.contarPendentes(), 0);

    final List<Transferencia> locais = await repository.listar();
    final Transferencia salva = locais.single;
    expect(salva.sincronizado, isTrue);
    expect(salva.remoteId, isNotNull);

    final List<Transferencia> remotas = await api.listar();
    final Transferencia remota = remotas.firstWhere(
      (item) => item.uuid == salva.uuid,
    );
    expect(remota.nome, 'Café com Leite');
    expect(remota.id, 3);
    expect(remota.valor, 12.0);
    expect(remota.remoteId, salva.remoteId);

    final int idDoReenvio = await api.enviar(salva);
    expect(idDoReenvio, salva.remoteId);

    await Future<void>.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await _capturarEvidencia(binding, tester, 'lista');

    await banco.delete(
      'transferencias',
      where: 'uuid = ?',
      whereArgs: <Object?>[salva.uuid],
    );
  });
}

Future<void> _carregarFontesReais() async {
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    return;
  }

  String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    final String executavel = Platform.resolvedExecutable;
    flutterRoot = p.dirname(
      p.dirname(p.dirname(p.dirname(p.dirname(executavel)))),
    );
  }

  final Directory pastaFontes = Directory(
    p.join(flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
  );
  if (!await pastaFontes.exists()) {
    return;
  }

  final Map<String, List<String>> fontes = <String, List<String>>{
    'Roboto': <String>[
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ],
    'MaterialIcons': <String>['materialicons-regular.otf'],
  };

  for (final MapEntry<String, List<String>> familia in fontes.entries) {
    final FontLoader carregador = FontLoader(familia.key);
    for (final String nomeArquivo in familia.value) {
      final File arquivo = File(p.join(pastaFontes.path, nomeArquivo));
      if (await arquivo.exists()) {
        carregador.addFont(
          arquivo.readAsBytes().then(
            (Uint8List bytes) => ByteData.view(bytes.buffer),
          ),
        );
      }
    }
    await carregador.load();
  }
}

Future<void> _capturarEvidencia(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String nome,
) async {
  await tester.pumpAndSettle();

  if (_executandoEmDesktop) {
    final RenderRepaintBoundary limite = tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('tela-cafeteria')),
        );
    final ui.Image imagem = await limite.toImage(pixelRatio: 2);
    final ByteData? bytes = await imagem.toByteData(
      format: ui.ImageByteFormat.png,
    );
    imagem.dispose();

    if (bytes == null) {
      fail('Não foi possível gerar a imagem de $nome.');
    }

    final Directory pasta = Directory(_pastaEvidencias);
    await pasta.create(recursive: true);
    final File arquivo = File(p.join(pasta.path, '$nome.png'));
    await arquivo.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    debugPrint('Evidência salva em ${arquivo.absolute.path}');
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    if (!_superficieConvertida) {
      await binding.convertFlutterSurfaceToImage();
      _superficieConvertida = true;
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot(nome);
  }
}

Future<void> _aguardar(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final DateTime limite = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(limite)) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Tempo esgotado aguardando o widget: $finder');
}
