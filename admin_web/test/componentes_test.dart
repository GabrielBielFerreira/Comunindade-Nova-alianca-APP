import 'package:admin_web/ui/componentes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget envolver(Widget filho) => MaterialApp(home: Scaffold(body: filho));

void main() {
  testWidgets('EstadoVazio mostra título e detalhe', (tester) async {
    await tester.pumpWidget(envolver(const EstadoVazio(
      titulo: 'Nenhuma transação registrada',
      detalhe: 'Esta unidade ainda não possui contribuições lançadas.',
    )));

    expect(find.text('Nenhuma transação registrada'), findsOneWidget);
    expect(
      find.text('Esta unidade ainda não possui contribuições lançadas.'),
      findsOneWidget,
    );
  });

  testWidgets('EstadoErro oferece tentar novamente', (tester) async {
    var tentou = false;
    await tester.pumpWidget(envolver(EstadoErro(
      erro: 'permission-denied',
      onTentarNovamente: () => tentou = true,
    )));

    expect(find.text('Não foi possível carregar'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(tentou, isTrue);
  });

  testWidgets('CartaoMetrica exibe o valor informado', (tester) async {
    await tester.pumpWidget(envolver(const CartaoMetrica(
      rotulo: 'Cadastros pendentes',
      valor: '3',
    )));

    expect(find.text('Cadastros pendentes'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  group('DialogoMotivo', () {
    testWidgets('confirmar fica desabilitado sem motivo suficiente',
        (tester) async {
      await tester.pumpWidget(envolver(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => DialogoMotivo.mostrar(
              context,
              titulo: 'Remover da liderança',
              descricao: 'Descrição',
              rotuloConfirmar: 'Rebaixar',
            ),
            child: const Text('abrir'),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final botao = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Rebaixar'),
      );
      expect(botao.onPressed, isNull);

      // Texto curto continua bloqueando.
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Rebaixar'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('devolve o motivo quando válido', (tester) async {
      String? capturado;
      await tester.pumpWidget(envolver(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              capturado = await DialogoMotivo.mostrar(
                context,
                titulo: 'Desvincular',
                descricao: 'Descrição',
                rotuloConfirmar: 'Desvincular',
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Mudanca de ministerio');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Desvincular'));
      await tester.pumpAndSettle();

      expect(capturado, 'Mudanca de ministerio');
    });
  });
}
