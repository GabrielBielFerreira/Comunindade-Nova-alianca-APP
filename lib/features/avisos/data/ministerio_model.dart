import 'package:cloud_firestore/cloud_firestore.dart';

class MinisterioModel {
  final String id;
  final String nome;
  final String descricao;
  final String liderId;
  // Nome do líder denormalizado (cache): evita uma busca extra ao exibir
  // "Líder: X" na gestão/detalhe. Vazio quando nenhum líder foi atribuído.
  final String liderNome;
  final int membrosCount;
  final bool ativo;
  final bool publico;
  final DateTime criadoEm;

  const MinisterioModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.liderId,
    this.liderNome = '',
    required this.membrosCount,
    required this.ativo,
    this.publico = true,
    required this.criadoEm,
  });

  factory MinisterioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MinisterioModel.fromMap(doc.id, data);
  }

  factory MinisterioModel.fromMap(String id, Map<String, dynamic> data) {
    return MinisterioModel(
      id: id,
      nome: data['nome'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      liderId: data['lider_id'] as String? ?? '',
      liderNome: data['lider_nome'] as String? ?? '',
      membrosCount: data['membros_count'] as int? ?? 0,
      ativo: data['ativo'] as bool? ?? true,
      publico: data['publico'] as bool? ?? true,
      criadoEm: (data['criado_em'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'descricao': descricao,
    'lider_id': liderId,
    'lider_nome': liderNome,
    'membros_count': membrosCount,
    'ativo': ativo,
    'publico': publico,
    'criado_em': Timestamp.fromDate(criadoEm),
  };
}
