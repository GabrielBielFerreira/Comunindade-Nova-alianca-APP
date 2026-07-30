import 'package:cloud_firestore/cloud_firestore.dart';

class MinisterioModel {
  final String id;
  final String nome;
  final String descricao;
  final String liderId;
  final int membrosCount;
  final bool ativo;
  final DateTime criadoEm;

  const MinisterioModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.liderId,
    required this.membrosCount,
    required this.ativo,
    required this.criadoEm,
  });

  factory MinisterioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MinisterioModel(
      id: doc.id,
      nome: data['nome'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      liderId: data['lider_id'] as String? ?? '',
      membrosCount: data['membros_count'] as int? ?? 0,
      ativo: data['ativo'] as bool? ?? true,
      criadoEm:
          (data['criado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'descricao': descricao,
        'lider_id': liderId,
        'membros_count': membrosCount,
        'ativo': ativo,
        'criado_em': Timestamp.fromDate(criadoEm),
      };
}
