import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_dia_share_card.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_do_dia.dart';

PalavraDoDia _palavra(String texto) => PalavraDoDia(
      id: 'anual-1',
      texto: texto,
      referencia: 'Salmos 23:1',
      traducao: 'Almeida (domínio público)',
      data: DateTime(2026, 3, 15),
      reflexao: 'Descanse no cuidado d\'Ele.',
    );

Future<void> _pump(
  WidgetTester tester,
  PalavraDoDia p, {
  double textScale = 1.0,
  ShareCardFormato formato = ShareCardFormato.feed,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: formato.largura,
            height: formato.altura,
            child: PalavraDiaShareCard(
              palavra: p,
              linkOficial: 'https://app.exemplo.com',
              formato: formato,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    // Evita tentativa de baixar fontes na suíte de testes.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renderiza referência, rótulo e assinatura', (tester) async {
    await _pump(tester, _palavra('O Senhor é o meu pastor; nada me faltará.'));
    expect(find.text('PALAVRA DO DIA'), findsOneWidget);
    expect(find.text('Salmos 23:1'), findsWidgets);
    expect(find.text('Nova Aliança App'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('versículo curto não estoura o layout', (tester) async {
    await _pump(tester, _palavra('Deus é amor.'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('versículo longo é ajustado sem overflow', (tester) async {
    final longo = 'Porque Deus amou o mundo de tal maneira que deu o seu '
        'Filho unigênito, para que todo aquele que nele crê não pereça, mas '
        'tenha a vida eterna; e este é o amor: que andemos segundo os seus '
        'mandamentos, permanecendo firmes na fé, na esperança e na caridade.';
    await _pump(tester, _palavra(longo));
    expect(tester.takeException(), isNull);
  });

  testWidgets('imune à fonte do sistema em 200% (sem overflow)',
      (tester) async {
    await _pump(
      tester,
      _palavra('O Senhor é a minha luz e a minha salvação.'),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('formato Stories (1080x1920) renderiza sem overflow',
      (tester) async {
    await _pump(
      tester,
      _palavra('O choro pode durar uma noite, mas a alegria vem pela manhã.'),
      formato: ShareCardFormato.story,
    );
    expect(tester.takeException(), isNull);
  });
}
