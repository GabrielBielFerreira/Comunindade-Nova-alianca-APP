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
    required this.criadoPor,
    required this.confirmadosCount,
    this.responsavelId = '',
    this.responsavelNome = '',
  });

  factory EventoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventoModel(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      data: (data['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      horario: data['horario'] as String? ?? '',
      local: data['local'] as String? ?? '',
      tipo: TipoEvento.values.firstWhere(
        (e) => e.name == (data['tipo'] as String? ?? 'culto'),
        orElse: () => TipoEvento.culto,
      ),
      imagemUrl: data['imagem_url'] as String?,
      publico: data['publico'] as bool? ?? true,
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
