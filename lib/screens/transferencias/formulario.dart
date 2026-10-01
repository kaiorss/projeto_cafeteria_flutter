import 'package:flutter/material.dart';
import '../../components/editor.dart';
import '../../models/transferencia.dart';

/// Tela de formulário da cafeteria.
///
/// Cadastra um novo consumo (produto) e devolve o objeto criado para a
/// tela de lista através de [Navigator.pop].
class FormularioTransferencia extends StatefulWidget {
  const FormularioTransferencia({super.key});

  @override
  State<StatefulWidget> createState() {
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
  static const _erroCampos = 'Preencha todos os campos corretamente!';

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
      appBar: AppBar(
        title: const Text(_tituloAppBar),
      ),
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
                onPressed: _confirmar,
                icon: const Icon(Icons.local_cafe),
                label: const Text(_textoBotaoConfirmar),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmar() {
    debugPrint("Clicou em salvar consumo...");
    _criaTransferencia(
      context,
      _controladorCampoNome,
      _controladorCampoValor,
      _controladorCampoIdentificador,
    );
  }
}

void _criaTransferencia(
  BuildContext context,
  TextEditingController controladorCampoNome,
  TextEditingController controladorCampoValor,
  TextEditingController controladorCampoIdentificador,
) {
  // Converte o texto do identificador usando int.tryParse.
  final int? identificador =
      int.tryParse(controladorCampoIdentificador.text.trim());

  // Converte o texto do valor usando double.tryParse.
  // O ponto é normalizado para vírgula para aceitar "12,00" e "12.00".
  final double? valor = double.tryParse(
    controladorCampoValor.text.trim().replaceAll(',', '.'),
  );

  final String nome = controladorCampoNome.text.trim();

  if (identificador != null && valor != null && nome.isNotEmpty) {
    final transferenciaCriada = Transferencia(
      nome: nome,
      valor: valor,
      id: identificador,
      icone: Icons.local_cafe,
    );
    debugPrint('$transferenciaCriada'); // Teste de saída no console
    Navigator.pop(context, transferenciaCriada);
  } else {
    debugPrint('Dados inválidos: $nome / $valor / $identificador');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(FormularioTransferenciaState._erroCampos)),
    );
  }
}
