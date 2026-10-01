// Testes de widget do app Cafeteria.
//
// Cobrem o modelo em memória, a montagem da lista, a navegação até o
// formulário e a atualização dinâmica com Future.delayed + setState.

import 'package:cafeteria/main.dart';
import 'package:cafeteria/models/transferencia.dart';
import 'package:cafeteria/screens/transferencias/formulario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O NumberFormat usa espaço não separável (U+00A0) entre "R$" e o valor.
/// Esta função normaliza para comparar com o texto no padrão "R$ 12,00".
String _normalizar(String texto) => texto.replaceAll('\u00A0', ' ');

/// Encontra um Text cujo conteúdo, normalizado, seja igual a [texto].
/// O escopo padrão é a lista, para não confundir com o texto do TextField
/// preenchido no formulário.
Finder _textoDaLista(String texto) {
  return find.descendant(
    of: find.byType(ListView),
    matching: find.byWidgetPredicate(
      (widget) => widget is Text && _normalizar(widget.data ?? '') == texto,
    ),
  );
}


void main() {
  group('Modelo Transferencia', () {
    test('guarda nome, valor, id e ícone padrão', () {
      final consumo = Transferencia(nome: 'Café Expresso', valor: 12.00, id: 1);

      expect(consumo.nome, 'Café Expresso');
      expect(consumo.valor, 12.00);
      expect(consumo.id, 1);
      expect(consumo.icone, Icons.local_cafe);
    });

    test('conversões usadas no formulário', () {
      expect(double.tryParse('12,00'.replaceAll(',', '.')), 12.00);
      expect(int.tryParse('7'), 7);
    });
  });

  testWidgets('a lista mostra os registros iniciais em memória', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CafeteriaApp());
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(3));
    expect(find.text('Café Expresso'), findsOneWidget);
    expect(find.text('Cappuccino'), findsOneWidget);
    expect(find.text('Pão de Queijo'), findsOneWidget);

    // Cada registro exibe o identificador no subtítulo do ListTile.
    expect(find.text('Identificador: 1'), findsOneWidget);
    expect(find.text('Identificador: 2'), findsOneWidget);
    expect(find.text('Identificador: 3'), findsOneWidget);
  });

  testWidgets('o valor é exibido no padrão brasileiro (R\$ 12,00)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CafeteriaApp());
    await tester.pumpAndSettle();

    expect(_textoDaLista(r'R$ 12,00'), findsOneWidget);
    expect(_textoDaLista(r'R$ 8,50'), findsOneWidget);
    expect(_textoDaLista(r'R$ 4,00'), findsOneWidget);
  });

  testWidgets('o botão flutuante abre a tela de formulário', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CafeteriaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo consumo'));
    await tester.pumpAndSettle();

    expect(find.byType(FormularioTransferencia), findsOneWidget);
    expect(find.text('Nome do consumo'), findsOneWidget);
    expect(find.text('Valor'), findsOneWidget);
    expect(find.text('Identificador'), findsOneWidget);
  });

  testWidgets(
    'o formulário devolve o objeto e a lista inclui após 1 segundo (setState)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CafeteriaApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo consumo'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome do consumo'),
        'Café com Leite',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Valor'),
        '12,00',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Identificador'),
        '7',
      );

      await tester.tap(find.text('Salvar consumo'));

      // Mede, no relógio virtual, quanto tempo passa desde o toque em
      // "Salvar consumo" até o item aparecer na lista.
      // Usa pumps manuais (sem pumpAndSettle) para não avançar o tempo sozinho.
      int tempoAteInclusaoMs = -1;
      for (int ms = 0; ms <= 2000; ms += 50) {
        if (ms > 0) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        if (_textoDaLista('Café com Leite').evaluate().isNotEmpty) {
          tempoAteInclusaoMs = ms;
          break;
        }
      }

      // O Navigator.pop(context, transferenciaCriada) encerra o formulário
      // antes da inclusão, que só ocorre após o Future.delayed de 1 segundo.
      expect(find.byType(FormularioTransferencia), findsNothing);
      expect(tempoAteInclusaoMs, greaterThanOrEqualTo(1000));
      await tester.pumpAndSettle();

      expect(_textoDaLista('Café com Leite'), findsOneWidget);
      expect(_textoDaLista(r'R$ 12,00'), findsNWidgets(2));
      expect(find.text('Identificador: 7'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(4));
    },
  );

  testWidgets('campos inválidos não criam registro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CafeteriaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo consumo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar consumo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.byType(FormularioTransferencia), findsOneWidget);
    expect(find.text('Preencha todos os campos corretamente!'), findsOneWidget);
  });
}
