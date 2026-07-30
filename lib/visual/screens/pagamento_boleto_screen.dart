import 'pagamento_externo_screen.dart';

class PagamentoBoletoScreen extends PagamentoExternoScreen {
  const PagamentoBoletoScreen({
    super.key,
    required super.isLeader,
    super.contributionType,
    super.valueLabel,
    super.campaign,
  }) : super(kind: PagamentoExternoKind.boleto);
}
