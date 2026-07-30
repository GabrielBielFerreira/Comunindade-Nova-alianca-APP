import 'package:cloud_firestore/cloud_firestore.dart';

/// Devocional (coleção `devocionais`). Conteúdo criado pela liderança.
class DevocionalModel {
  final String id;
  final String titulo;
  final String corpo;
  final String autor;
  final DateTime data;
  final String? referencia; // referência bíblica opcional
  final bool destaque;

  const DevocionalModel({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.autor,
    required this.data,
    this.referencia,
    this.destaque = false,
  });

  factory DevocionalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DevocionalModel(
      id: doc.id,
      titulo: d['titulo'] as String? ?? '',
      corpo: d['corpo'] as String? ?? '',
      autor: d['autor'] as String? ?? '',
      data: (d['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      referencia: d['referencia'] as String?,
      destaque: d['destaque'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'corpo': corpo,
        'autor': autor,
        'data': Timestamp.fromDate(data),
        'referencia': referencia,
        'destaque': destaque,
      };
}
