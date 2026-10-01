import 'package:flutter/material.dart';
import '../../models/transferencia.dart';
import 'formulario.dart';
import 'package:intl/intl.dart';

/// Formatação brasileira de moeda: R$ 12,00
final NumberFormat _formatoMoeda = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);

/// Tela principal da cafeteria.
///
/// A lista de consumos vive apenas em memória, carregada com registros
/// iniciais e ampliada a cada novo cadastro retornado pelo formulário.
class ListaTransferencias extends StatefulWidget {
  final List<Transferencia> _transferencias = _registrosIniciais();

  ListaTransferencias({super.key});

  @override
  State<StatefulWidget> createState() {
    return ListaTransferenciaState();
  }
}

List<Transferencia> _registrosIniciais() {
  return <Transferencia>[
    Transferencia(nome: 'Café Expresso', valor: 12.00, id: 1),
    Transferencia(
      nome: 'Cappuccino',
      valor: 8.50,
      id: 2,
      icone: Icons.coffee,
    ),
    Transferencia(
      nome: 'Pão de Queijo',
      valor: 4.00,
      id: 3,
      icone: Icons.bakery_dining,
    ),
  ];
}

class ListaTransferenciaState extends State<ListaTransferencias> {
  static const _tituloAppBar = 'Cafeteria';
  static const _mensagemListaVazia = 'Nenhum consumo cadastrado.';
  static const _rotuloId = 'Identificador';

  /// Aguarda cerca de 1 segundo antes de inserir o item na lista,
  /// demonstrando a atualização dinâmica com Future.delayed + setState.
  Future<void> _atualiza(Transferencia? transferenciaRecebida) async {
    if (transferenciaRecebida != null) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        widget._transferencias.add(transferenciaRecebida);
      });
    }
  }

  void _abreFormulario() {
    debugPrint("Botão de novo consumo pressionado");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const FormularioTransferencia();
        },
      ),
    ).then((transferenciaRecebida) => _atualiza(transferenciaRecebida));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            Icon(Icons.local_cafe),
            SizedBox(width: 8),
            Text(_tituloAppBar),
          ],
        ),
      ),
      body: widget._transferencias.isEmpty
          ? Center(
              child: Text(
                _mensagemListaVazia,
                style: const TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: widget._transferencias.length,
              itemBuilder: (context, indice) {
                final transferencia = widget._transferencias[indice];
                return ItemTransferencia(transferencia);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abreFormulario,
        icon: const Icon(Icons.coffee),
        label: const Text('Novo consumo'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ItemTransferencia extends StatelessWidget {
  final Transferencia _transferencia;

  const ItemTransferencia(this._transferencia, {super.key});

  @override
  Widget build(BuildContext context) {
    final String valorFormatado = _formatoMoeda.format(_transferencia.valor);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: Icon(_transferencia.icone),
        ),
        title: Text(
          _transferencia.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${ListaTransferenciaState._rotuloId}: ${_transferencia.id}',
        ),
        trailing: Text(
          valorFormatado,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ),
    );
  }
}
