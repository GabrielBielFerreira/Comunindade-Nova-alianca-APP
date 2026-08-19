import 'igreja_id.dart';
import 'normalizacao.dart';

/// Tipo de contribuição.
enum TipoContribuicao {
  dizimo,
  oferta,
  campanha;

  String get valor => name;

  static TipoContribuicao deTexto(String? bruto) {
    final chave = normalizarChave(bruto ?? '');
    for (final t in TipoContribuicao.values) {
      if (t.name == chave) return t;
    }
    return TipoContribuicao.oferta;
  }

  String get rotulo => switch (this) {
        TipoContribuicao.dizimo => 'Dízimo',
        TipoContribuicao.oferta => 'Oferta',
        TipoContribuicao.campanha => 'Campanha',
      };
}

/// Meio de pagamento. `checkout_pro` cobre cartão e boleto via Mercado Pago.
enum MetodoPagamento {
  pix,
  checkoutPro;

  String get valor => switch (this) {
        MetodoPagamento.pix => 'pix',
        MetodoPagamento.checkoutPro => 'checkout_pro',
      };

  static MetodoPagamento deTexto(String? bruto) {
    final chave = normalizarChave(bruto ?? '');
    for (final m in MetodoPagamento.values) {
      if (m.valor == chave) return m;
    }
    return MetodoPagamento.pix;
  }

  String get rotulo => switch (this) {
        MetodoPagamento.pix => 'PIX',
        MetodoPagamento.checkoutPro => 'Cartão/Boleto',
      };
}

/// Situação da transação. Só o backend escreve o status definitivo.
enum StatusTransacao {
  /// Registro interno criado, ainda sem cobrança emitida.
  criando,
  pendente,
  aprovado,
  rejeitado,
  cancelado,
  estornado;

  String get valor => name;

  static StatusTransacao deTexto(String? bruto) {
    final chave = normalizarChave(bruto ?? '');
    for (final s in StatusTransacao.values) {
      if (s.name == chave) return s;
    }
    return StatusTransacao.pendente;
  }

  bool get isAprovado => this == StatusTransacao.aprovado;

  /// Entra na soma de valores efetivamente recebidos.
  bool get contabiliza => this == StatusTransacao.aprovado;

  String get rotulo => switch (this) {
        StatusTransacao.criando => 'Criando',
        StatusTransacao.pendente => 'Pendente',
        StatusTransacao.aprovado => 'Aprovado',
        StatusTransacao.rejeitado => 'Rejeitado',
        StatusTransacao.cancelado => 'Cancelado',
        StatusTransacao.estornado => 'Estornado',
      };
}

/// Uma transação: `/igrejas/{igrejaId}/transacoes/{id}`.
///
/// CONTRATO CANÔNICO — o valor é SEMPRE inteiro em centavos
/// (`valor_centavos`). Nunca gravar `valor` em reais, nem `perfil_id`, nem
/// `meio_pagamento`: eram os campos divergentes da versão anterior e
/// produziam erro de fator 100 entre app e backend.
class Transacao {
  const Transacao({
    required this.id,
    required this.usuarioId,
    required this.igrejaId,
    required this.valorCentavos,
    required this.tipo,
    required this.metodo,
    required this.status,
    this.campanhaId,
    this.mpPaymentId,
    this.mpStatusDetail,
    this.criadoEm,
    this.atualizadoEm,
    this.aprovadoEm,
  });

  final String id;
  final String usuarioId;
  final IgrejaId igrejaId;

  /// Inteiro, em centavos. R$ 25,50 => 2550.
  final int valorCentavos;

  final TipoContribuicao tipo;
  final MetodoPagamento metodo;
  final StatusTransacao status;
  final String? campanhaId;
  final String? mpPaymentId;
  final String? mpStatusDetail;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final DateTime? aprovadoEm;

  /// Valor em reais, apenas para exibição/formatação.
  double get valorReais => valorCentavos / 100;

  factory Transacao.doMapa({
    required String id,
    required Map<String, dynamic> dados,
    DateTime? Function(dynamic)? lerData,
  }) {
    final converterData = lerData ?? (dynamic v) => v is DateTime ? v : null;
    return Transacao(
      id: id,
      usuarioId: dados['usuario_id'] as String? ?? '',
      igrejaId: IgrejaId(dados['igreja_id'] as String? ?? 'olinda'),
      valorCentavos: _lerCentavos(dados['valor_centavos']),
      tipo: TipoContribuicao.deTexto(dados['tipo'] as String?),
      metodo: MetodoPagamento.deTexto(dados['metodo'] as String?),
      status: StatusTransacao.deTexto(dados['status'] as String?),
      campanhaId: dados['campanha_id'] as String?,
      mpPaymentId: dados['mp_payment_id'] as String?,
      mpStatusDetail: dados['mp_status_detail'] as String?,
      criadoEm: converterData(dados['criado_em']),
      atualizadoEm: converterData(dados['atualizado_em']),
      aprovadoEm: converterData(dados['aprovado_em']),
    );
  }

  /// Aceita apenas inteiro. Um `double` aqui indicaria valor em reais vazando
  /// para o campo de centavos — trunca para o inteiro mais próximo em vez de
  /// multiplicar, para nunca inflar silenciosamente um valor.
  static int _lerCentavos(dynamic bruto) {
    if (bruto is int) return bruto;
    if (bruto is num) return bruto.round();
    if (bruto is String) return int.tryParse(bruto) ?? 0;
    return 0;
  }

  Map<String, dynamic> paraMapa() => {
        'usuario_id': usuarioId,
        'igreja_id': igrejaId.valor,
        'valor_centavos': valorCentavos,
        'tipo': tipo.valor,
        'metodo': metodo.valor,
        'status': status.valor,
        'campanha_id': campanhaId,
        'mp_payment_id': mpPaymentId,
        'mp_status_detail': mpStatusDetail,
        'criado_em': criadoEm,
        'atualizado_em': atualizadoEm,
        'aprovado_em': aprovadoEm,
      };
}

/// Totais de um conjunto de transações, em centavos.
class TotaisFinanceiros {
  const TotaisFinanceiros({
    required this.aprovadoCentavos,
    required this.pendenteCentavos,
    required this.recusadoCentavos,
    required this.quantidade,
  });

  final int aprovadoCentavos;
  final int pendenteCentavos;
  final int recusadoCentavos;
  final int quantidade;

  double get aprovadoReais => aprovadoCentavos / 100;
  double get pendenteReais => pendenteCentavos / 100;
  double get recusadoReais => recusadoCentavos / 100;

  /// Soma por status. `rejeitado`, `cancelado` e `estornado` entram como
  /// "recusado" para efeito de painel; só `aprovado` conta como recebido.
  factory TotaisFinanceiros.de(Iterable<Transacao> transacoes) {
    var aprovado = 0;
    var pendente = 0;
    var recusado = 0;
    var quantidade = 0;

    for (final t in transacoes) {
      quantidade++;
      switch (t.status) {
        case StatusTransacao.aprovado:
          aprovado += t.valorCentavos;
        case StatusTransacao.pendente:
        case StatusTransacao.criando:
          pendente += t.valorCentavos;
        case StatusTransacao.rejeitado:
        case StatusTransacao.cancelado:
        case StatusTransacao.estornado:
          recusado += t.valorCentavos;
      }
    }

    return TotaisFinanceiros(
      aprovadoCentavos: aprovado,
      pendenteCentavos: pendente,
      recusadoCentavos: recusado,
      quantidade: quantidade,
    );
  }
}

/// Formata centavos como moeda brasileira, sem depender de `intl`.
String formatarCentavos(int centavos) {
  final negativo = centavos < 0;
  final absoluto = centavos.abs();
  final reais = absoluto ~/ 100;
  final resto = absoluto % 100;

  final digitos = reais.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }

  final centavosTexto = resto.toString().padLeft(2, '0');
  return '${negativo ? '-' : ''}R\$ $buffer,$centavosTexto';
}
