import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoEvento { culto, ministerio, eventoEspecial }

class EventoModel {
  final String id;
  final String titulo;
  final String descricao;
  final DateTime data;
  final String horario;
  final String local;
  final TipoEvento tipo;
  final String? imagemUrl;
  final bool publico;
  final bool cancelado;
  final String criadoPor;
  final int confirmadosCount;
  // Responsável pelo evento (membro escolhido pela liderança). Denormalizado
  // (id + nome) para exibir sem busca extra. Vazio quando não atribuído.
  final String responsavelId;
  final String responsavelNome;

  const EventoModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.horario,
    required this.local,
    required this.tipo,
    this.imagemUrl,
    required this.publico,
    this.cancelado = false,
    required this.criadoPor,
    required this.confirmadosCount,
    this.responsavelId = '',
    this.responsavelNome = '',
  });

  factory EventoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventoModel.fromMap(doc.id, data);
  }

  /// Lê o contrato gravado pelo painel e preserva documentos legados.
  ///
  /// O Timestamp `data` é a fonte de verdade. `horario` continua gravado para
  /// compatibilidade e exibição; quando faltar, é derivado de `data`.
  factory EventoModel.fromMap(String id, Map<String, dynamic> data) {
    final dataEvento = (data['data'] as Timestamp?)?.toDate() ?? DateTime.now();
    final horarioSalvo = (data['horario'] as String?)?.trim() ?? '';
    return EventoModel(
      id: id,
      titulo: data['titulo'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      data: dataEvento,
      horario: horarioSalvo.isNotEmpty
          ? horarioSalvo
          : '${dataEvento.hour.toString().padLeft(2, '0')}:'
                '${dataEvento.minute.toString().padLeft(2, '0')}',
      local: data['local'] as String? ?? '',
      tipo: TipoEvento.values.firstWhere(
        (e) => e.name == (data['tipo'] as String? ?? 'culto'),
        orElse: () => TipoEvento.culto,
      ),
      imagemUrl: data['imagem_url'] as String?,
      publico: data['publico'] as bool? ?? true,
      cancelado: data['cancelado'] as bool? ?? false,
      criadoPor: data['criado_por'] as String? ?? '',
      confirmadosCount: data['confirmados_count'] as int? ?? 0,
      responsavelId: data['responsavel_id'] as String? ?? '',
      responsavelNome: data['responsavel_nome'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'descricao': descricao,
    'data': Timestamp.fromDate(data),
    'horario': horario,
    'local': local,
    'tipo': tipo.name,
    'imagem_url': imagemUrl,
    'publico': publico,
    'cancelado': cancelado,
    'criado_por': criadoPor,
    'confirmados_count': confirmadosCount,
    'responsavel_id': responsavelId,
    'responsavel_nome': responsavelNome,
  };
}

class ConfirmadoEvento {
  final String uid;
  final DateTime confirmadoEm;
  final bool checkinRealizado;

  const ConfirmadoEvento({
    required this.uid,
    required this.confirmadoEm,
    required this.checkinRealizado,
  });

  factory ConfirmadoEvento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConfirmadoEvento(
      uid: doc.id,
      confirmadoEm:
          (data['confirmado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkinRealizado: data['checkin_realizado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'confirmado_em': Timestamp.fromDate(confirmadoEm),
    'checkin_realizado': checkinRealizado,
  };
}
