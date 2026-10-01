import 'package:flutter/material.dart';

/// Modelo da cafeteria.
///
/// Cada instância representa um produto (um "consumo") vendido no cardápio.
/// Os dados vivem apenas em memória: nenhuma persistência é feita.
class Transferencia {
  final String nome;
  final double valor;
  final int id;
  final IconData icone;

  Transferencia({
    required this.nome,
    required this.valor,
    required this.id,
    this.icone = Icons.local_cafe,
  });

  @override
  String toString() {
    return "Transferencia{nome: $nome, valor: $valor, id: $id, icone: $icone}";
  }
}
