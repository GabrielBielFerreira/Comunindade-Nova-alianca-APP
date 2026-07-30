class ContribuicaoMockData {
  const ContribuicaoMockData._();

  static const verse = '"Cada um contribua segundo propôs\nno seu coração..."';
  static const verseReference = '2 Coríntios 9:7';
  static const safeEnvironment =
      'Você será direcionado para fazer o pagamento em\nPix, Cartão ou boleto';

  static const campaigns = <ContribuicaoCampaignData>[
    ContribuicaoCampaignData(
      title: 'Reforma do Teto Principal',
      imageAsset: 'assets/images/figma/contribuir/campanha_reforma_teto.png',
      progress: 0.70,
      progressLabel: '70% alcançado',
      trailingLabel: 'Faltam R\$ 15k',
      buttonLabel: 'Apoiar campanha',
      urgent: true,
    ),
    ContribuicaoCampaignData(
      title: 'Ação Cestas Básicas',
      imageAsset: 'assets/images/figma/contribuir/campanha_cestas.png',
      progress: 0.45,
      progressLabel: '45% alcançado',
      trailingLabel: 'Meta: 500 cestas',
      buttonLabel: 'Apoiar Ação',
    ),
  ];
}

class ContribuicaoCampaignData {
  const ContribuicaoCampaignData({
    required this.title,
    required this.imageAsset,
    required this.progress,
    required this.progressLabel,
    required this.trailingLabel,
    required this.buttonLabel,
    this.urgent = false,
  });

  final String title;
  final String imageAsset;
  final double progress;
  final String progressLabel;
  final String trailingLabel;
  final String buttonLabel;
  final bool urgent;
}
