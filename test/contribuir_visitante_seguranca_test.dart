import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/visual/screens/contribuir_screen.dart';
import 'package:nova_alianca_app/features/igrejas/providers/igreja_providers.dart';
import 'package:nova_alianca_app/visual/visual_router.dart';

void main() {
  testWidgets(
    'visitante não recebe formulário nem dados de pagamento públicos',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isMembroAprovadoAtualProvider.overrideWithValue(false)],
          child: MaterialApp(
            initialRoute: VisualRoutes.contribuir,
            routes: {
              ...visualRoutes,
              VisualRoutes.entraconta: (_) =>
                  const Scaffold(body: Center(child: Text('Tela de entrada'))),
            },
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('contribuicao_visitante_bloqueada')),
        findsOneWidget,
      );
      expect(find.text('Contribuição protegida'), findsOneWidget);
      expect(
        find.textContaining('os dados de pagamento não ficam'),
        findsOneWidget,
      );
      expect(find.text('R\$ 0,00'), findsNothing);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byKey(const Key('entrar_para_contribuir')));
      await tester.pumpAndSettle();

      expect(find.text('Tela de entrada'), findsOneWidget);
    },
  );

  testWidgets('membro aprovado mantém acesso ao formulário', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isMembroAprovadoAtualProvider.overrideWithValue(true)],
        child: const MaterialApp(home: ContribuirScreen(isLeader: false)),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('contribuicao_visitante_bloqueada')),
      findsNothing,
    );
    expect(find.text('R\$ 0,00'), findsOneWidget);
  });
}
