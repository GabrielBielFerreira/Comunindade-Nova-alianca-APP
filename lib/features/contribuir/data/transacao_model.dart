import 'package:cloud_firestore/cloud_firestore.dart';

enum MeioPagamento { pix, credito, debito }

enum TipoContribuicao { dizimo, oferta, campanha }

enum StatusTransacao { pendente, aprovado, rejeitado, estornado }

class TransacaoModel {
  final String id;
  final String? perfilId;
  final int valor; // em centavos
  final MeioPagamento meioPagamento;
  final TipoContribuicao tipo;
  final String? campanhaId;
  final StatusTransacao status;
  final String mpPaymentId;
  final String mpStatusDetail;
  final DateTime criadoEm;
  final DateTime? aprovadoEm;

  const TransacaoModel({
    required this.id,
    this.perfilId,
    required this.valor,
    required this.meioPagamento,
    required this.tipo,
    this.campanhaId,
    required this.status,
    required this.mpPaymentId,
    required this.mpStatusDetail,
    required this.criadoEm,
    this.aprovadoEm,
  });

  double get valorReais => valor / 100;

  factory TransacaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransacaoModel(
      id: doc.id,
      perfilId: data['perfil_id'] as String?,
      valor: data['valor'] as int? ?? 0,
      meioPagamento: MeioPagamento.values.firstWhere(
        (e) => e.name == (data['meio_pagamento'] as String? ?? 'pix'),
        orElse: () => MeioPagamento.pix,
      ),
      tipo: TipoContribuicao.values.firstWhere(
        (e) => e.name == (data['tipo'] as String? ?? 'oferta'),
        orElse: () => TipoContribuicao.oferta,
      ),
      campanhaId: data['campanha_id'] as String?,
      status: StatusTransacao.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pendente'),
        orElse: () => StatusTransacao.pendente,
      ),
      mpPaymentId: data['mp_payment_id'] as String? ?? '',
      mpStatusDetail: data['mp_status_detail'] as String? ?? '',
      criadoEm: (data['criado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aprovadoEm: (data['aprovado_em'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'perfil_id': perfilId,
        'valor': valor,
        'meio_pagamento': meioPagamento.name,
        'tipo': tipo.name,
        'campanha_id': campanhaId,
        'status': status.name,
        'mp_payment_id': mpPaymentId,
        'mp_status_detail': mpStatusDetail,
        'criado_em': Timestamp.fromDate(criadoEm),
        'aprovado_em':
            aprovadoEm != null ? Timestamp.fromDate(aprovadoEm!) : null,
      };
}
