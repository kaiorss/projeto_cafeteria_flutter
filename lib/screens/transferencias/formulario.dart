import 'package:flutter/material.dart';

import '../../components/editor.dart';
import '../../models/transferencia.dart';
import '../../repository/transferencia_repository.dart';

/// Tela de formulário da cafeteria.
///
/// Cadastra um novo consumo (produto) através do repositório e devolve o
/// registro salvo para a tela de lista através de [Navigator.pop].
class FormularioTransferencia extends StatefulWidget {
  const FormularioTransferencia({super.key, required this.repository});

  final TransferenciaRepository repository;

  @override
  State<FormularioTransferencia> createState() {
    return FormularioTransferenciaState();
  }
}

class FormularioTransferenciaState extends State<FormularioTransferencia> {
  final TextEditingController _controladorCampoNome = TextEditingController();
  final TextEditingController _controladorCampoValor = TextEditingController();
  final TextEditingController _controladorCampoIdentificador =
      TextEditingController();

  static const _tituloAppBar = 'Novo consumo';
  static const _rotuloCampoNome = 'Nome do consumo';
  static const _dicaCampoNome = 'Ex.: Café Expresso';
  static const _rotuloCampoValor = 'Valor';
  static const _dicaCampoValor = '12,00';
  static const _rotuloCampoIdentificador = 'Identificador';
  static const _dicaCampoIdentificador = '1';
  static const _textoBotaoConfirmar = 'Salvar consumo';
  static const _textoSalvando = 'Salvando...';
  static const _erroCampos = 'Preencha todos os campos corretamente!';
  static const _erroSalvar =
      'Não foi possível salvar o consumo. Tente novamente.';

  bool _salvando = false;

  @override
  void dispose() {
    _controladorCampoNome.dispose();
    _controladorCampoValor.dispose();
    _controladorCampoIdentificador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_tituloAppBar)),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Editor(
              controlador: _controladorCampoNome,
              rotulo: _rotuloCampoNome,
              dica: _dicaCampoNome,
              icone: Icons.coffee,
              teclado: TextInputType.text,
            ),

            Editor(
              controlador: _controladorCampoValor,
              rotulo: _rotuloCampoValor,
              dica: _dicaCampoValor,
              icone: Icons.attach_money,
            ),

            Editor(
              controlador: _controladorCampoIdentificador,
              rotulo: _rotuloCampoIdentificador,
              dica: _dicaCampoIdentificador,
              icone: Icons.qr_code,
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _confirmar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.local_cafe),
                label: Text(
                  _salvando ? _textoSalvando : _textoBotaoConfirmar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    if (_salvando) {
      return;
    }

    debugPrint('Clicou em salvar consumo...');

    // Converte o texto do identificador usando int.tryParse.
    final int? identificador = int.tryParse(
      _controladorCampoIdentificador.text.trim(),
    );

    // Converte o texto do valor usando double.tryParse.
    // O ponto é normalizado para vírgula para aceitar "12,00" e "12.00".
    final double? valor = double.tryParse(
      _controladorCampoValor.text.trim().replaceAll(',', '.'),
    );

    final String nome = _controladorCampoNome.text.trim();

    if (identificador == null || valor == null || nome.isEmpty) {
      debugPrint('Dados inválidos: $nome / $valor / $identificador');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_erroCampos)),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final Transferencia transferenciaCriada = Transferencia(
        nome: nome,
        valor: valor,
        id: identificador,
        icone: Icons.local_cafe,
      );
      debugPrint('$transferenciaCriada'); // Teste de saída no console

      final Transferencia salva = await widget.repository.cadastrar(
        transferenciaCriada,
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, salva);
    } catch (erro) {
      debugPrint('Erro ao salvar consumo: $erro');
      if (!mounted) {
        return;
      }
      setState(() {
        _salvando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_erroSalvar)),
      );
    }
  }
}
