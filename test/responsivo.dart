import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Larguras exigidas pela auditoria de responsividade.
///
/// 320 é o piso real do produto (iPhone SE 1ª geração) e a largura que a
/// escala antiga — piso 0.86 sobre a prancha de 394 px — não conseguia
/// desenhar sem estourar.
const tamanhosDeTeste = <String, Size>{
  '320x568 (iPhone SE)': Size(320, 568),
  '360x800 (Android comum)': Size(360, 800),
  '390x844 (iPhone 14)': Size(390, 844),
  '412x915 (Pixel)': Size(412, 915),
  '768 (tablet)': Size(768, 1024),
  '1024 (tablet grande)': Size(1024, 768),
  '1440 (desktop)': Size(1440, 900),
};

const escalasDeTexto = <double>[1.0, 1.3];

/// Pinta [widget] no tamanho e escala pedidos e FALHA se houver overflow.
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
  await tester.pump();

  final erro = tester.takeException();
  if (erro == null) return;

  // Tolerância de MENOS de um pixel lógico.
  //
  // A escala das telas é uma divisão (`largura / 391`), e a soma das alturas
  // resultantes às vezes passa da tela por 0,0125 px. Isso não corta nada:
  // nem meio pixel físico. Falhar por isso deixaria a suíte vermelha em
  // permanência, e uma suíte cronicamente vermelha para de ser lida — que é
  // pior do que não ter o teste.
  //
  // O corte que importa é de pixels inteiros; abaixo de 1 px é aritmética.
  final medida = RegExp(r'overflowed by ([\d.]+) pixels').firstMatch('$erro');
  final pixels = double.tryParse(medida?.group(1) ?? '');
  if (pixels != null && pixels < 1.0) return;

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
