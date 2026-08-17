import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Larguras exigidas pela auditoria de responsividade.
///
/// As quatro primeiras são aparelhos reais; 768/1024/1440 cobrem tablet,
/// tablet grande e desktop.
const tamanhosDeTeste = <String, Size>{
  '320x568 (iPhone SE)': Size(320, 568),
  '360x800 (Android comum)': Size(360, 800),
  '390x844 (iPhone 14)': Size(390, 844),
  '412x915 (Pixel)': Size(412, 915),
  '768 (tablet)': Size(768, 1024),
  '1024 (tablet grande)': Size(1024, 768),
  '1440 (desktop)': Size(1440, 900),
};

/// Fonte no tamanho normal e ampliada pelo sistema.
const escalasDeTexto = <double>[1.0, 1.3];

/// Pinta [construir] no tamanho e escala pedidos e FALHA se houver overflow.
///
/// `RenderFlex overflowed`, `RenderBox overflowed` e afins chegam aqui por
/// [WidgetTester.takeException]. O teste não verifica aparência — verifica que
/// nada foi cortado nem estourou a tela.
Future<void> esperarSemOverflow(
  WidgetTester tester,
  Widget widget, {
  required Size tamanho,
  required double escalaTexto,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = tamanho;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: tamanho,
        textScaler: TextScaler.linear(escalaTexto),
      ),
      child: widget,
    ),
  );
  // Um segundo quadro resolve layouts que dependem de LayoutBuilder.
  await tester.pump();

  final erro = tester.takeException();
  expect(
    erro,
    isNull,
    reason: 'Overflow em $tamanho com textScale $escalaTexto: $erro',
  );
}

/// Roda [corpo] em todas as combinações de tamanho e escala de texto.
void paraCadaTamanho(
  String descricao,
  Future<void> Function(WidgetTester, Size, double) corpo,
) {
  for (final entrada in tamanhosDeTeste.entries) {
    for (final escala in escalasDeTexto) {
      testWidgets(
        '$descricao — ${entrada.key} @ textScale $escala',
        (tester) => corpo(tester, entrada.value, escala),
      );
    }
  }
}
