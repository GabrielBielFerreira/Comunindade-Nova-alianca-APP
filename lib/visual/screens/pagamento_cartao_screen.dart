import 'pagamento_externo_screen.dart';

class PagamentoCartaoScreen extends PagamentoExternoScreen {
  const PagamentoCartaoScreen({
    super.key,
    required super.isLeader,
    super.contributionType,
    super.valueLabel,
    super.campaign,
  }) : super(kind: PagamentoExternoKind.cartao);
}
