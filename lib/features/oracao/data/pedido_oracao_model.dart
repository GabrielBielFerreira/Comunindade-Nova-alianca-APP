import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusPedidoOracao { recebido, emOracao, testemunho }

/// Pedido de oração persistido no Firestore (coleção `pedidos_oracao`).
///
/// Regras de segurança (firestore.rules): pedidos privados só são lidos pelo
/// autor e liderança; a reação "Estou orando" só pode alterar
/// `oram_count`/`oram_por`.
class PedidoOracaoModel {
  final String id;
  final String autorId;
  final String autorNome;
  final String texto;
  final bool privado;
  final bool anonimo;
  final bool urgente;
  final String? categoria;
  final bool solicitaVisita;
  final bool solicitaLigacao;

  /// Moderação: pedidos públicos só aparecem na Comunidade após `aprovado`.
  final bool aprovado;

  /// Recusado pela moderação. O documento é PRESERVADO — recusar marca este
  /// campo em vez de apagar, para não destruir o histórico do pedido nem o
  /// registro de quem moderou.
  final bool recusado;
  final String? motivoRecusa;
  final String? moderadoPor;
  final DateTime? moderadoEm;

  final StatusPedidoOracao status;
  final DateTime criadoEm;
  final String? testemunho;
  final int oramCount;
  final List<String> oramPor;

  const PedidoOracaoModel({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    required this.privado,
    this.anonimo = false,
    this.urgente = false,
    this.categoria,
    this.solicitaVisita = false,
    this.solicitaLigacao = false,
    this.aprovado = false,
    this.recusado = false,
    this.motivoRecusa,
    this.moderadoPor,
    this.moderadoEm,
    required this.status,
    required this.criadoEm,
    this.testemunho,
    this.oramCount = 0,
    this.oramPor = const [],
  });

  /// Nome a exibir, respeitando o anonimato.
  String get nomeExibicao => anonimo ? 'Anônimo' : autorNome;

  bool orouUsuario(String uid) => oramPor.contains(uid);

  factory PedidoOracaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PedidoOracaoModel(
      id: doc.id,
      autorId: data['autor_id'] as String? ?? '',
      autorNome: data['autor_nome'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      privado: data['privado'] as bool? ?? false,
      anonimo: data['anonimo'] as bool? ?? false,
      urgente: data['urgente'] as bool? ?? false,
      categoria: data['categoria'] as String?,
      solicitaVisita: data['solicita_visita'] as bool? ?? false,
      solicitaLigacao: data['solicita_ligacao'] as bool? ?? false,
      aprovado: data['aprovado'] as bool? ?? false,
      recusado: data['recusado'] as bool? ?? false,
      motivoRecusa: data['motivo_recusa'] as String?,
      moderadoPor: data['moderado_por'] as String?,
      moderadoEm: (data['moderado_em'] as Timestamp?)?.toDate(),
      status: StatusPedidoOracao.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'recebido'),
        orElse: () => StatusPedidoOracao.recebido,
      ),
      criadoEm: (data['criado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
      testemunho: data['testemunho'] as String?,
      oramCount: (data['oram_count'] as num?)?.toInt() ?? 0,
      oramPor: (data['oram_por'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'autor_id': autorId,
    'autor_nome': autorNome,
    'texto': texto,
    'privado': privado,
    'anonimo': anonimo,
    'urgente': urgente,
    'categoria': categoria,
    'solicita_visita': solicitaVisita,
    'solicita_ligacao': solicitaLigacao,
    'aprovado': aprovado,
    'recusado': recusado,
    'motivo_recusa': motivoRecusa,
    'moderado_por': moderadoPor,
    'moderado_em': moderadoEm != null ? Timestamp.fromDate(moderadoEm!) : null,
    'status': status.name,
    'criado_em': Timestamp.fromDate(criadoEm),
    'testemunho': testemunho,
    'oram_count': oramCount,
    'oram_por': oramPor,
  };
}
