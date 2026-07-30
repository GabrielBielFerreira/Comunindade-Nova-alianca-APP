import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusPedidoOracao { recebido, emOracao, testemunho }

class PedidoOracaoModel {
  final String id;
  final String autorId;
  final String autorNome;
  final String texto;
  final bool privado;
  final StatusPedidoOracao status;
  final DateTime criadoEm;
  final String? testemunho;
  final int reacoesCount;

  const PedidoOracaoModel({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    required this.privado,
    required this.status,
    required this.criadoEm,
    this.testemunho,
    required this.reacoesCount,
  });

  factory PedidoOracaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PedidoOracaoModel(
      id: doc.id,
      autorId: data['autor_id'] as String? ?? '',
      autorNome: data['autor_nome'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      privado: data['privado'] as bool? ?? false,
      status: StatusPedidoOracao.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'recebido'),
        orElse: () => StatusPedidoOracao.recebido,
      ),
      criadoEm: (data['criado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
      testemunho: data['testemunho'] as String?,
      reacoesCount: data['reacoes_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'autor_id': autorId,
        'autor_nome': autorNome,
        'texto': texto,
        'privado': privado,
        'status': status.name,
        'criado_em': Timestamp.fromDate(criadoEm),
        'testemunho': testemunho,
        'reacoes_count': reacoesCount,
      };
}

class ReacaoOracao {
  final String uid;
  final DateTime reagiuEm;

  const ReacaoOracao({required this.uid, required this.reagiuEm});

  factory ReacaoOracao.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReacaoOracao(
      uid: doc.id,
      reagiuEm: (data['reagiu_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'reagiu_em': Timestamp.fromDate(reagiuEm),
      };
}
