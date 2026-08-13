import 'package:cloud_firestore/cloud_firestore.dart';

import 'campanha_model.dart';

/// Acesso ao Firestore para campanhas (coleção `campanhas`). Filtra ativas e
/// ordena no cliente para evitar índices compostos. Escrita é restrita à
/// liderança pelas regras.
class CampanhasRepository {
  CampanhasRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('campanhas');

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<List<CampanhaModel>> streamAtivas() {
    return _col
        .where('status', isEqualTo: 'ativa')
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(CampanhaModel.fromFirestore).toList()
        ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
      return lista;
    });
  }

  /// Visão da liderança (Gestão): TODAS as campanhas, inclusive encerradas.
  Stream<List<CampanhaModel>> streamGerenciar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(CampanhaModel.fromFirestore).toList()
        ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
      return lista;
    });
  }

  /// Cria uma nova campanha. Retorna o id gerado.
  Future<String> criar(CampanhaModel campanha) async {
    final ref = await _col.add(campanha.toMap());
    return ref.id;
  }

  /// Atualiza uma campanha existente. O `valor_arrecadado` é cache do servidor
  /// e não deve ser sobrescrito por engano — quem chama preserva o valor atual.
  Future<void> atualizar(CampanhaModel campanha) {
    return _col.doc(campanha.id).update(campanha.toMap());
  }

  /// Remove definitivamente uma campanha.
  Future<void> excluir(String id) {
    return _col.doc(id).delete();
  }
}
