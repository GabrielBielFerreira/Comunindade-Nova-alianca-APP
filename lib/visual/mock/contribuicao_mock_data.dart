import '../../core/utils/formatters.dart';
import '../../features/campanhas/data/campanha_model.dart';

class ContribuicaoMockData {
  const ContribuicaoMockData._();

  static const verse = '"Cada um contribua segundo propôs\nno seu coração..."';
  static const verseReference = '2 Coríntios 9:7';
  static const safeEnvironment =
      'Você contribui via PIX. O recebimento é confirmado pela tesouraria.';
}

/// Dados de uma campanha para os cards/telas de contribuição.
///
/// Pode vir de uma campanha real do Firestore
/// ([ContribuicaoCampaignData.fromCampanha]) — nesse caso [campanhaId] é
/// preenchido e a contribuição referencia a campanha.
class ContribuicaoCampaignData {
  const ContribuicaoCampaignData({
    required this.title,
    required this.imageAsset,
    required this.progress,
    required this.progressLabel,
    required this.trailingLabel,
    required this.buttonLabel,
    this.urgent = false,
    this.campanhaId,
    this.description,
    this.imageUrl,
  });

  final String title;

  /// Imagem local (mock). Campanhas reais usam [imageUrl].
  final String imageAsset;
  final double progress;
  final String progressLabel;
  final String trailingLabel;
  final String buttonLabel;
  final bool urgent;

  /// Id da campanha no Firestore (nulo quando não vinculada a uma campanha).
  final String? campanhaId;

  /// Descrição da campanha (para a tela de detalhes).
  final String? description;

  /// Imagem em rede (campanhas reais). Tem prioridade sobre [imageAsset].
  final String? imageUrl;

  factory ContribuicaoCampaignData.fromCampanha(CampanhaModel c) {
    final pct = (c.progresso * 100).round();
    final faltam = (c.metaValor - c.valorArrecadado).clamp(0, c.metaValor);
    return ContribuicaoCampaignData(
      title: c.titulo,
      imageAsset: '',
      imageUrl: c.imagemUrl,
      progress: c.progresso,
      progressLabel: '$pct% alcançado',
      trailingLabel: c.metaValor > 0
          ? 'Faltam ${Formatters.moedaCentavos(faltam)}'
          : Formatters.moedaCentavos(c.valorArrecadado),
      buttonLabel: 'Apoiar campanha',
      campanhaId: c.id,
      description: c.descricao,
    );
  }
}
