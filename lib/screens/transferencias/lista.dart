import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/status_sincronizacao.dart';
import '../../models/transferencia.dart';
import '../../repository/transferencia_repository.dart';
import 'formulario.dart';

/// Formatação brasileira de moeda: R$ 12,00
final NumberFormat _formatoMoeda = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);

/// Tela principal da cafeteria.
///
/// Carrega os consumos persistidos no SQLite e atualiza a listagem após
/// cada novo cadastro realizado pelo formulário.
class ListaTransferencias extends StatefulWidget {
  const ListaTransferencias({super.key, required this.repository});

  final TransferenciaRepository repository;

  @override
  State<ListaTransferencias> createState() {
    return ListaTransferenciaState();
  }
}

class ListaTransferenciaState extends State<ListaTransferencias> {
  static const _tituloAppBar = 'Cafeteria';
  static const _mensagemListaVazia = 'Nenhum consumo cadastrado.';
  static const _rotuloId = 'Identificador';

  List<Transferencia> _transferencias = <Transferencia>[];
  bool _carregando = true;
  bool _sincronizando = false;
  int _pendentes = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final List<Transferencia> itens = await widget.repository.listar();
    if (!mounted) {
      return;
    }
    setState(() {
      _transferencias = itens;
      _pendentes = itens.where((item) => !item.sincronizado).length;
      _carregando = false;
    });
  }

  Future<void> _abreFormulario() async {
    debugPrint('Botão de novo consumo pressionado');

    final Transferencia? transferenciaSalva =
        await Navigator.push<Transferencia>(
          context,
          MaterialPageRoute<Transferencia>(
            builder: (context) {
              return FormularioTransferencia(repository: widget.repository);
            },
          ),
        );

    if (transferenciaSalva == null || !mounted) {
      return;
    }

    await _carregar();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          transferenciaSalva.sincronizado
              ? 'Consumo salvo e sincronizado com o servidor.'
              : 'Consumo salvo localmente. Aguardando sincronização.',
        ),
      ),
    );
  }

  Future<void> _sincronizar() async {
    if (_sincronizando || _pendentes == 0) {
      return;
    }

    setState(() {
      _sincronizando = true;
    });

    ResultadoSincronizacao? resultado;
    Object? erro;

    try {
      resultado = await widget.repository.sincronizarPendentes();
    } catch (e) {
      erro = e;
      debugPrint('Erro ao sincronizar pendentes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _sincronizando = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    await _carregar();
    if (!mounted) {
      return;
    }

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível sincronizar. Os registros continuam pendentes.',
          ),
        ),
      );
      return;
    }

    _mostrarResultado(resultado!);
  }

  void _mostrarResultado(ResultadoSincronizacao resultado) {
    final String mensagem;

    if (resultado.totalPendentes == 0) {
      mensagem = 'Nenhum registro pendente.';
    } else if (resultado.interrompidoPorConexao) {
      mensagem =
          'Sem conexão com a API. Sincronizados: '
          '${resultado.sincronizados}. Pendentes: ${resultado.restantes}.';
    } else if (resultado.tudoSincronizado) {
      mensagem =
          'Sincronização concluída. Sincronizados: '
          '${resultado.sincronizados}. Pendentes: 0.';
    } else {
      mensagem =
          'Sincronização parcial. Sincronizados: '
          '${resultado.sincronizados}. Pendentes: ${resultado.restantes}.';
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
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
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                _PainelSincronizacao(
                  pendentes: _pendentes,
                  sincronizando: _sincronizando,
                  onSincronizar: _pendentes == 0 || _sincronizando
                      ? null
                      : _sincronizar,
                ),
                Expanded(
                  child: _transferencias.isEmpty
                      ? Center(
                          child: Text(
                            _mensagemListaVazia,
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 96),
                          itemCount: _transferencias.length,
                          itemBuilder: (context, indice) {
                            final transferencia = _transferencias[indice];
                            return ItemTransferencia(transferencia);
                          },
                        ),
                ),
              ],
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

class _PainelSincronizacao extends StatelessWidget {
  const _PainelSincronizacao({
    required this.pendentes,
    required this.sincronizando,
    required this.onSincronizar,
  });

  final int pendentes;
  final bool sincronizando;
  final VoidCallback? onSincronizar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onSincronizar,
          icon: sincronizando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text('Sincronizar pendentes ($pendentes)'),
        ),
      ),
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              valorFormatado,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 2),
            StatusSincronizacao(sincronizado: _transferencia.sincronizado),
          ],
        ),
      ),
    );
  }
}
