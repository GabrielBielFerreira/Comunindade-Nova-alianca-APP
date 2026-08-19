import 'package:cloud_firestore/cloud_firestore.dart';

enum PrioridadeAviso { normal, urgente }

// Segmentação por ministério/grupo — a Comunidade Nova Aliança não usa células.
enum SegmentoAviso { todos, jovens, lideres, ministerio }

class AvisoModel {
  final String id;
  final String titulo;
  final String conteudo;
  final PrioridadeAviso prioridade;
  final SegmentoAviso segmento;
  final String? segmentoId;
  final String? imagemUrl;
  final String autorId;
  final DateTime publicadoEm;
  final bool ativo;

  /// Conteúdo visível a qualquer autenticado (inclui visitante anônimo).
  /// As Rules exigem `publico == true` no documento E o filtro correspondente
  /// na consulta — um aviso interno nunca chega a quem não é membro.
  final bool publico;

  const AvisoModel({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.prioridade,
    required this.segmento,
    this.segmentoId,
    this.imagemUrl,
    required this.autorId,
    required this.publicadoEm,
    required this.ativo,
    this.publico = false,
  });

  bool get isUrgente => prioridade == PrioridadeAviso.urgente;

  factory AvisoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AvisoModel(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      // `conteudo` é o campo canônico. `corpo` é aceito apenas na LEITURA,
      // por compatibilidade com documentos gravados antes da padronização;
      // nenhuma gravação nova usa `corpo`.
      conteudo: (data['conteudo'] as String?) ?? (data['corpo'] as String?) ?? '',
      prioridade: (data['prioridade'] as String?) == 'urgente'
          ? PrioridadeAviso.urgente
          : PrioridadeAviso.normal,
      segmento: SegmentoAviso.values.firstWhere(
        (e) => e.name == (data['segmento'] as String? ?? 'todos'),
        orElse: () => SegmentoAviso.todos,
      ),
      segmentoId: data['segmento_id'] as String?,
      imagemUrl: data['imagem_url'] as String?,
      autorId: data['autor_id'] as String? ?? '',
      publicadoEm:
          (data['publicado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ativo: data['ativo'] as bool? ?? true,
      publico: data['publico'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        // Somente `conteudo`: `corpo` é legado de leitura.
        'conteudo': conteudo,
        'prioridade': prioridade.name,
        'segmento': segmento.name,
        'segmento_id': segmentoId,
        'imagem_url': imagemUrl,
        'autor_id': autorId,
        'publicado_em': Timestamp.fromDate(publicadoEm),
        'ativo': ativo,
        'publico': publico,
      };

  AvisoModel copiarCom({
    String? titulo,
    String? conteudo,
    PrioridadeAviso? prioridade,
    SegmentoAviso? segmento,
    String? segmentoId,
    bool? ativo,
    bool? publico,
  }) {
    return AvisoModel(
      id: id,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      prioridade: prioridade ?? this.prioridade,
      segmento: segmento ?? this.segmento,
      segmentoId: segmentoId ?? this.segmentoId,
      imagemUrl: imagemUrl,
      autorId: autorId,
      publicadoEm: publicadoEm,
      ativo: ativo ?? this.ativo,
      publico: publico ?? this.publico,
    );
  }
}
