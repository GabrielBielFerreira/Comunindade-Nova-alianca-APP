import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusCampanha { ativa, encerrada }

class CampanhaModel {
  final String id;
  final String titulo;
  final String descricao;
  final int metaValor; // em centavos
  final int valorArrecadado; // em centavos (cache)
  final StatusCampanha status;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String? imagemUrl;
  final String criadoPor;
  final bool publico;

  const CampanhaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.metaValor,
    required this.valorArrecadado,
    required this.status,
    required this.dataInicio,
    this.dataFim,
    this.imagemUrl,
    required this.criadoPor,
    this.publico = true,
  });

  double get progresso =>
      metaValor > 0 ? (valorArrecadado / metaValor).clamp(0.0, 1.0) : 0.0;

  double get metaReais => metaValor / 100;
  double get arrecadadoReais => valorArrecadado / 100;

  factory CampanhaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampanhaModel.fromMap(doc.id, data);
  }

  /// Contrato compartilhado com o painel web.
  ///
  /// `meta_centavos` é o campo canônico. `meta_valor` é aceito somente na
  /// leitura para preservar campanhas criadas antes da migração.
  factory CampanhaModel.fromMap(String id, Map<String, dynamic> data) {
    final meta = data['meta_centavos'] ?? data['meta_valor'];
    final arrecadado = data['valor_arrecadado'];
    return CampanhaModel(
      id: id,
      titulo: data['titulo'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      metaValor: meta is num ? meta.toInt() : 0,
      valorArrecadado: arrecadado is num ? arrecadado.toInt() : 0,
      status: (data['status'] as String?) == 'encerrada'
          ? StatusCampanha.encerrada
          : StatusCampanha.ativa,
      dataInicio:
          (data['data_inicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataFim: (data['data_fim'] as Timestamp?)?.toDate(),
      imagemUrl: data['imagem_url'] as String?,
      criadoPor: data['criado_por'] as String? ?? '',
      publico: data['publico'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'descricao': descricao,
    'meta_centavos': metaValor,
    'valor_arrecadado': valorArrecadado,
    'status': status.name,
    'data_inicio': Timestamp.fromDate(dataInicio),
    'data_fim': dataFim != null ? Timestamp.fromDate(dataFim!) : null,
    'imagem_url': imagemUrl,
    'criado_por': criadoPor,
    'publico': publico,
  };
}
