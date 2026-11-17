import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (
          String nome,
          List<int> bytes, [
          Map<String, Object?>? argumentos,
        ]) async {
          final File imagem = File('evidencias/$nome.png');
          await imagem.create(recursive: true);
          await imagem.writeAsBytes(bytes, flush: true);
          return true;
        },
  );
}
