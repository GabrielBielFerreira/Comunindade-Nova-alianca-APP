import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/app/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renderiza indicador e mensagem opcional',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(mensagem: 'Preparando sua conta...')),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Preparando sua conta...'), findsOneWidget);
  });

  testWidgets('SplashScreen sem mensagem não quebra',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
