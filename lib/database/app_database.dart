import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Abre e mantém o banco SQLite local da cafeteria.
///
/// No Windows/Linux usa `sqflite_common_ffi`; no Android/iOS usa o `sqflite`.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? caminhoBanco})
    : _factory = factory ?? _fabricaPadrao(),
      _caminhoBanco = caminhoBanco;

  static const String nomeBanco = 'cafeteria.db';
  static const int versaoBanco = 1;

  final DatabaseFactory _factory;
  final String? _caminhoBanco;

  Database? _banco;
  static bool _ffiConfigurado = false;

  static DatabaseFactory _fabricaPadrao() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      if (!_ffiConfigurado) {
        sqfliteFfiInit();
        _ffiConfigurado = true;
      }
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  Future<Database> abrir() async {
    final Database? bancoAberto = _banco;
    if (bancoAberto != null && bancoAberto.isOpen) {
      return bancoAberto;
    }

    final String caminho =
        _caminhoBanco ??
        p.join(await _factory.getDatabasesPath(), nomeBanco);

    final Database banco = await _factory.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: versaoBanco,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int versao) async {
          await db.execute('''
            CREATE TABLE transferencias (
              uuid TEXT PRIMARY KEY,
              identificador INTEGER NOT NULL,
              nome TEXT NOT NULL,
              valor REAL NOT NULL,
              icone_codigo INTEGER NOT NULL DEFAULT 0,
              sincronizado INTEGER NOT NULL DEFAULT 0,
              remote_id INTEGER,
              criado_em TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_transferencias_pendentes '
            'ON transferencias (sincronizado)',
          );
        },
      ),
    );

    _banco = banco;
    return banco;
  }

  Future<void> fechar() async {
    final Database? banco = _banco;
    _banco = null;
    if (banco != null && banco.isOpen) {
      await banco.close();
    }
  }
}
