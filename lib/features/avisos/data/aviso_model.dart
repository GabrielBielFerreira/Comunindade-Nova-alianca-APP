import 'package:cloud_firestore/cloud_firestore.dart';

enum PrioridadeAviso { normal, urgente }

enum SegmentoAviso { todos, jovens, lideres, ministerio, celula }

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
  });

  bool get isUrgente => prioridade == PrioridadeAviso.urgente;

  factory AvisoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AvisoModel(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      conteudo: data['conteudo'] as String? ?? '',
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
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'conteudo': conteudo,
        'prioridade': prioridade.name,
        'segmento': segmento.name,
        'segmento_id': segmentoId,
        'imagem_url': imagemUrl,
        'autor_id': autorId,
        'publicado_em': Timestamp.fromDate(publicadoEm),
        'ativo': ativo,
      };
}
