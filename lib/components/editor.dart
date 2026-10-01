import 'package:flutter/material.dart';

/// Componente reutilizável de edição de texto usado nos formulários.
///
/// Recebe um [TextEditingController] externo, permitindo ler e converter
/// o conteúdo digitado (por exemplo com [double.tryParse] e [int.tryParse]).
class Editor extends StatelessWidget {
  final TextEditingController? controlador;
  final String? rotulo;
  final String? dica;
  final IconData? icone;
  final TextInputType teclado;

  const Editor({
    super.key,
    this.controlador,
    this.rotulo,
    this.dica,
    this.icone,
    this.teclado = TextInputType.number,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: TextField(
        controller: controlador,
        style: const TextStyle(fontSize: 20.0),
        decoration: InputDecoration(
          icon: icone != null ? Icon(icone) : null,
          labelText: rotulo,
          hintText: dica,
        ),
        keyboardType: teclado,
      ),
    );
  }
}
