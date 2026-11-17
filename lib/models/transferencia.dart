import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const Uuid _geradorUuid = Uuid();

/// Modelo da cafeteria.
///
/// Cada instância representa um produto (um "consumo") vendido no cardápio.
///
/// O campo [uuid] é o identificador estável usado na sincronização com a API,
/// enquanto [id] continua sendo o "Identificador" informado pelo usuário.
class Transferencia {
  final String uuid;
  final String nome;
  final double valor;
  final int id;
  final IconData icone;

  /// `true` somente depois da confirmação do servidor.
  final bool sincronizado;

  /// Identificador do registro no PostgreSQL, quando já sincronizado.
  final int? remoteId;

  final DateTime criadoEm;

  Transferencia({
    String? uuid,
    required this.nome,
    required this.valor,
    required this.id,
    this.icone = Icons.local_cafe,
    this.sincronizado = false,
    this.remoteId,
    DateTime? criadoEm,
  }) : uuid = uuid ?? _geradorUuid.v4(),
       criadoEm = criadoEm ?? DateTime.now();

  Transferencia copyWith({
    String? uuid,
    String? nome,
    double? valor,
    int? id,
    IconData? icone,
    bool? sincronizado,
    int? remoteId,
    DateTime? criadoEm,
  }) {
    return Transferencia(
      uuid: uuid ?? this.uuid,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      id: id ?? this.id,
      icone: icone ?? this.icone,
      sincronizado: sincronizado ?? this.sincronizado,
      remoteId: remoteId ?? this.remoteId,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  static const List<IconData> _iconesConhecidos = <IconData>[
    Icons.local_cafe,
    Icons.coffee,
    Icons.bakery_dining,
  ];

  static IconData iconePorCodigo(int? codigo) {
    for (final IconData icone in _iconesConhecidos) {
      if (icone.codePoint == codigo) {
        return icone;
      }
    }
    return Icons.local_cafe;
  }

  /// Formato usado na tabela SQLite `transferencias`.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'uuid': uuid,
      'identificador': id,
      'nome': nome,
      'valor': valor,
      'icone_codigo': icone.codePoint,
      'sincronizado': sincronizado ? 1 : 0,
      'remote_id': remoteId,
      'criado_em': criadoEm.toUtc().toIso8601String(),
    };
  }

  factory Transferencia.fromMap(Map<String, Object?> map) {
    return Transferencia(
      uuid: map['uuid'] as String,
      nome: map['nome'] as String,
      valor: (map['valor'] as num).toDouble(),
      id: (map['identificador'] as num).toInt(),
      icone: iconePorCodigo((map['icone_codigo'] as num?)?.toInt()),
      sincronizado: ((map['sincronizado'] as num?)?.toInt() ?? 0) == 1,
      remoteId: (map['remote_id'] as num?)?.toInt(),
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }

  /// Formato usado no corpo das requisições para a API.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'clientUuid': uuid,
      'nome': nome,
      'valor': valor,
      'identificador': id,
      'iconeCodigo': icone.codePoint,
      'criadoEm': criadoEm.toUtc().toIso8601String(),
    };
  }

  factory Transferencia.fromJson(Map<String, Object?> json) {
    return Transferencia(
      uuid: (json['clientUuid'] ?? json['uuid']) as String,
      nome: json['nome'] as String,
      valor: (json['valor'] as num).toDouble(),
      id: (json['identificador'] as num).toInt(),
      icone: iconePorCodigo((json['iconeCodigo'] as num?)?.toInt()),
      sincronizado:
          json['sincronizado'] == true || json['sincronizado'] == 1,
      remoteId: (json['id'] as num?)?.toInt(),
      criadoEm: json['criadoEm'] is String
          ? DateTime.tryParse(json['criadoEm'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Transferencia{uuid: $uuid, nome: $nome, valor: $valor, '
        'id: $id, sincronizado: $sincronizado, remoteId: $remoteId}';
  }
}
