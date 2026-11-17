import 'package:sqflite/sqflite.dart';

import '../models/transferencia.dart';
import 'app_database.dart';

/// Acesso à tabela `transferencias` no SQLite.
class TransferenciaDao {
  TransferenciaDao(this._appDatabase);

  static const String tabela = 'transferencias';

  final AppDatabase _appDatabase;

  Future<void> inserir(Transferencia transferencia) async {
    final Database db = await _appDatabase.abrir();
    await db.insert(
      tabela,
      transferencia.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Transferencia>> listar() async {
    final Database db = await _appDatabase.abrir();
    final List<Map<String, Object?>> registros = await db.query(
      tabela,
      orderBy: 'criado_em ASC',
    );
    return registros.map(Transferencia.fromMap).toList();
  }

  Future<List<Transferencia>> listarPendentes() async {
    final Database db = await _appDatabase.abrir();
    final List<Map<String, Object?>> registros = await db.query(
      tabela,
      where: 'sincronizado = ?',
      whereArgs: <Object?>[0],
      orderBy: 'criado_em ASC',
    );
    return registros.map(Transferencia.fromMap).toList();
  }

  Future<int> contarPendentes() async {
    final Database db = await _appDatabase.abrir();
    final List<Map<String, Object?>> resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tabela WHERE sincronizado = 0',
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  Future<void> marcarSincronizado(
    String uuid, {
    required int remoteId,
  }) async {
    final Database db = await _appDatabase.abrir();
    await db.update(
      tabela,
      <String, Object?>{'sincronizado': 1, 'remote_id': remoteId},
      where: 'uuid = ?',
      whereArgs: <Object?>[uuid],
    );
  }
}
