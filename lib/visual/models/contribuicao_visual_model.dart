enum ContribuicaoVisualStatus { aprovado, pendente, recusado, cancelado }

class ContribuicaoVisualModel {
  const ContribuicaoVisualModel({
    required this.id,
    required this.type,
    required this.valueLabel,
    required this.method,
    required this.status,
    required this.dateLabel,
    required this.church,
    this.campaignName,
  });

  final String id;
  final String type;
  final String valueLabel;
  final String method;
  final ContribuicaoVisualStatus status;
  final String dateLabel;
  final String church;
  final String? campaignName;

  String get statusLabel => switch (status) {
    ContribuicaoVisualStatus.aprovado => 'Aprovado',
    ContribuicaoVisualStatus.pendente => 'Pendente',
    ContribuicaoVisualStatus.recusado => 'Recusado',
    ContribuicaoVisualStatus.cancelado => 'Cancelado',
  };
}
