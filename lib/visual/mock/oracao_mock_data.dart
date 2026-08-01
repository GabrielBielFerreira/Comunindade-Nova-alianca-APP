class OracaoAssets {
  const OracaoAssets._();

  static const requestBadge =
      'assets/images/figma/oracao/oracao_request_badge.svg';
  static const prayerHands =
      'assets/images/figma/oracao/oracao_prayer_hands.svg';
  static const plus = 'assets/images/figma/oracao/oracao_plus.svg';
  static const urgent = 'assets/images/figma/oracao/oracao_urgent.svg';
  static const heart = 'assets/images/figma/oracao/oracao_heart.svg';
}

class OracaoMockData {
  const OracaoMockData._();

  static const title = 'ORAÇÃO';
  static const subtitle = 'Compartilhe seu pedido e receba apoio em\noração.';
  static const wordLabel = 'PALAVRA DO DIA';
  static const verse = '"O Senhor é o meu pastor; nada\nme faltará."';
  static const verseReference = 'Salmos 23:1';
  static const devotionalTitle = 'Devocional diário';
  static const devotionalBody =
      'O Senhor cuida de cada detalhe da nossa caminhada. Hoje, descanse na certeza de que Ele guia, sustenta e renova a sua fé.';
  static const requestTitle = 'Como podemos orar\npor você?';
  static const requestDescription =
      'Compartilhe seu pedido de oração\npara receber apoio da equipe pastoral ou da intercessão.';
  static const newRequest = 'Novo pedido';
  static const urgentRequest = 'Pedido urgente';
  static const myRequestsTab = 'Meus Pedidos';
  static const communityTab = 'Comunidade';
  static const recentTitle = 'Pedidos Recentes';
  static const seeAll = 'Ver todos';
  static const muralTitle = 'Mural de Oração';
  static const muralSubtitle =
      'Ore pelos pedidos compartilhados pela\ncomunidade.';
  static const muralRecentTitle = 'Mural Recente';
  static const muralHighlightLabel = 'URGENTE';
  static const myMuralTab = 'Meus pedidos';
}

class OracaoRequestData {
  const OracaoRequestData({
    required this.author,
    required this.time,
    required this.text,
    this.prayerCount = 0,
    this.label,
  });

  final String author;
  final String time;
  final String text;
  final int prayerCount;
  final String? label;
}
