import 'package:cloud_firestore/cloud_firestore.dart';

/// Notificação pessoal (coleção `notificacoes`). Diferente de Avisos (mural
/// público): estas são alertas direcionados ao usuário (escalas, oração,
/// sistema, etc.), com estado lido/não lido.
enum TipoNotificacao { geral, pessoal, escala, oracao, sistema }

class NotificacaoModel {
  final String id;
  final String destinatarioId;
  final String titulo;
  final String corpo;
  final TipoNotificacao tipo;
  final bool lida;
  final DateTime criadoEm;

  /// Rota interna para deep link ao tocar (ex.: '/oracao'), opcional.
  final String? rota;

  const NotificacaoModel({
    required this.id,
    required this.destinatarioId,
    required this.titulo,
    required this.corpo,
    required this.tipo,
    required this.lida,
    required this.criadoEm,
    this.rota,
  });

  factory NotificacaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificacaoModel(
      id: doc.id,
      destinatarioId: data['destinatario_id'] as String? ?? '',
      titulo: data['titulo'] as String? ?? '',
      corpo: data['corpo'] as String? ?? '',
      tipo: TipoNotificacao.values.firstWhere(
        (e) => e.name == (data['tipo'] as String? ?? 'geral'),
        orElse: () => TipoNotificacao.geral,
      ),
      lida: data['lida'] as bool? ?? false,
      criadoEm: (data['criado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rota: data['rota'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'destinatario_id': destinatarioId,
        'titulo': titulo,
        'corpo': corpo,
        'tipo': tipo.name,
        'lida': lida,
        'criado_em': Timestamp.fromDate(criadoEm),
        'rota': rota,
      };
}
