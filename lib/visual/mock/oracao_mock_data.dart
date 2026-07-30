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

  static const communityRequests = <OracaoRequestData>[
    OracaoRequestData(
      author: 'Micael',
      time: 'Há 5 horas',
      text:
          'Peço oração pela minha família nesta semana e por fortalecimento espiritual.',
      prayerCount: 20,
    ),
    OracaoRequestData(
      author: 'Maria Silva',
      time: 'Há 5 horas',
      text:
          'Agradeço a Deus por uma resposta de oração recebida. Que Ele continue fortalecendo nossa comunidade.',
      prayerCount: 40,
    ),
  ];

  static const myRequests = <OracaoRequestData>[
    OracaoRequestData(
      author: 'João',
      time: 'Hoje',
      text: 'Peço direção e sabedoria para tomar boas decisões esta semana.',
      prayerCount: 4,
    ),
  ];

  static const muralHighlight = OracaoRequestData(
    author: 'Maria Silva',
    time: 'Há 1 hora',
    text:
        'Peço orações pela cirurgia cardíaca do meupai, João Silva, que acontecerá amanhã de manhã. Que Deus guie as mãos dos médicos.',
    prayerCount: 40,
    label: muralHighlightLabel,
  );

  static const muralRecentRequests = <OracaoRequestData>[
    OracaoRequestData(
      author: 'Maria Silva',
      time: 'Há 1 hora',
      text:
          'Agradecimento! Minha cirurgia foi um sucesso. Agradeço a todos que oraram por mim. Continuem orando pela minha...',
      prayerCount: 40,
    ),
    OracaoRequestData(
      author: 'Micael',
      time: 'Há 5 horas',
      text:
          'Peço oração pela restauração do meu casamento e pela saúde emocional dos meus filhos durante este período difícil....',
      prayerCount: 20,
    ),
    OracaoRequestData(
      author: 'Gustavo',
      time: 'Há 5 horas',
      text:
          'Peço oração pela restauração do meu casamento e pela saúde emocional dos meus filhos durante este período difícil....',
      prayerCount: 17,
    ),
  ];

  static const myMuralRequests = <OracaoRequestData>[
    OracaoRequestData(
      author: 'João',
      time: 'Hoje',
      text: 'Peço direção e paz para conduzir minha família nesta nova semana.',
      prayerCount: 3,
    ),
  ];
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
