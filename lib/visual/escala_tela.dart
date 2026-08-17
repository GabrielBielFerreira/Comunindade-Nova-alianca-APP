import 'package:flutter/widgets.dart';

/// Escala de layout das telas do aplicativo.
///
/// As telas foram desenhadas sobre uma prancha de [larguraDeReferencia] px e
/// multiplicam paddings, ícones e caixas por uma escala derivada da largura
/// real.
///
/// ## Por que o piso mudou
///
/// O piso original era `0.86`. Isso significava que, abaixo de
/// `394 × 0.86 ≈ 339 px`, o conteúdo continuava sendo desenhado com ~339 px de
/// largura dentro de uma tela menor — e estourava. Aparelhos de 320 px
/// (iPhone SE 1ª geração e similares) caíam exatamente nessa faixa.
///
/// O piso agora é a razão da menor largura que o produto suporta
/// ([larguraMinimaSuportada]) pela prancha, de modo que a escala nunca desenha
/// mais largo que a tela.
///
/// A escala não sobe acima de `1.0`: em telas largas o desenho mantém o
/// tamanho e ganha respiro, em vez de virar um bloco gigante.
const double larguraDeReferencia = 394.0;

/// Menor largura lógica suportada (iPhone SE 1ª geração, 320×568).
const double larguraMinimaSuportada = 320.0;

/// Piso da escala: garante que o conteúdo nunca seja mais largo que a tela.
const double escalaMinima = larguraMinimaSuportada / larguraDeReferencia;

/// Escala de layout para uma largura disponível.
double escalaPara(double larguraDisponivel) =>
    (larguraDisponivel / larguraDeReferencia).clamp(escalaMinima, 1.0).toDouble();

/// Escala de layout a partir do `MediaQuery` do contexto.
double escalaDe(BuildContext context) =>
    escalaPara(MediaQuery.sizeOf(context).width);

/// Limita o quanto a fonte do sistema amplia dentro de blocos com altura
/// rígida (barras, cabeçalhos, navegação inferior).
///
/// Não serve para texto de leitura — ali a ampliação do usuário é respeitada
/// integralmente. Serve para o caso em que ampliar sem limite quebraria a
/// própria navegação do aplicativo.
TextScaler escalaDeTextoLimitada(BuildContext context, {double maximo = 1.3}) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maximo);
