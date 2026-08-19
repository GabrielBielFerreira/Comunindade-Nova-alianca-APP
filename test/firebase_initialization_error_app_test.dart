import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/app/firebase_initialization_error_app.dart';

void main() {
  testWidgets(
    'falha obrigatória mostra tela segura sem montar o fluxo normal',
    (tester) async {
      await tester.pumpWidget(const FirebaseInitializationErrorApp());

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(
        find.text('Não foi possível iniciar o aplicativo'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Os serviços essenciais não puderam ser carregados',
        ),
        findsOneWidget,
      );

      // A mensagem de produção não revela tecnologia, configuração ou exceção.
      expect(find.textContaining('Firebase'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    },
  );
}
