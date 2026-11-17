import 'package:flutter/material.dart';

/// Indicação visual do estado de sincronização de um consumo.
class StatusSincronizacao extends StatelessWidget {
  const StatusSincronizacao({super.key, required this.sincronizado});

  final bool sincronizado;

  @override
  Widget build(BuildContext context) {
    final Color cor = sincronizado
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB26A00);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          sincronizado ? Icons.cloud_done : Icons.cloud_off,
          size: 14,
          color: cor,
        ),
        const SizedBox(width: 4),
        Text(
          sincronizado ? 'Sincronizado' : 'Pendente',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cor,
          ),
        ),
      ],
    );
  }
}
