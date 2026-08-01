import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_dia_share_card.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_dia_share_service.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_do_dia.dart';

/// Verifica que a IMAGEM do compartilhamento é realmente gerada (PNG válido),
/// tanto no formato feed quanto no de stories — inclusive quando o card de
/// stories está fora da área visível (é renderizado recortado na folha).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final palavra = PalavraDoDia(
    id: 'anual-001',
    texto: 'O Senhor é o meu pastor; nada me faltará.',
    referencia: 'Salmos 23:1',
    traducao: 'Almeida (domínio público)',
    data: DateTime(2026, 8, 1),
    reflexao: 'Descanse no cuidado d\'Ele hoje.',
  );

  Future<void> verificarCaptura(
    WidgetTester tester, {
    required ShareCardFormato formato,
    required bool recortado,
  }) async {
    final key = GlobalKey();

    final card = RepaintBoundary(
      key: key,
      child: SizedBox(
        width: formato.largura,
        height: formato.altura,
        child: PalavraDiaShareCard(
          palavra: palavra,
          linkOficial: 'https://app.exemplo.com',
          formato: formato,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: recortado
              // Reproduz o caso do stories: pintado, porém recortado a 1x1.
              ? ClipRect(
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: card,
                    ),
                  ),
                )
              : Center(
                  child: FittedBox(fit: BoxFit.contain, child: card),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // toImage() precisa rodar fora do zone de teste sincronizado.
    await tester.runAsync(() async {
      final png = await PalavraDiaShareService.capturarPng(key);

      expect(png.length, greaterThan(1000),
          reason: 'PNG gerado é pequeno demais — provável imagem vazia.');
      // Assinatura PNG (\x89 P N G).
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);

      // Confere a largura real do PNG (bytes 16..19, big-endian) — deve estar
      // na resolução alvo (1080 px), não na escala da tela.
      final largura = (png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19];
      expect(largura, greaterThanOrEqualTo(1000),
          reason: 'Imagem gerada abaixo da resolução esperada ($largura px).');
    });

    final obj = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    expect(obj.debugNeedsPaint, isFalse);
  }

  testWidgets('gera PNG do card de feed (1080x1350)', (tester) async {
    await verificarCaptura(tester,
        formato: ShareCardFormato.feed, recortado: false);
  });

  testWidgets('gera PNG do card de stories mesmo recortado (1080x1920)',
      (tester) async {
    await verificarCaptura(tester,
        formato: ShareCardFormato.story, recortado: true);
  });
}
