import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/igreja_scope.dart';
import 'campanha_model.dart';

/// Campanhas de UMA unidade: `igrejas/{igrejaId}/campanhas`.
class CampanhasRepository {
  CampanhasRepository(this._scope);

  final IgrejaScope _scope;

  CollectionReference<Map<String, dynamic>> get _col => _scope.campanhas;

  Stream<List<CampanhaModel>> streamAtivas() {
    return _col.where('status', isEqualTo: 'ativa').snapshots().map(_ordenar);
  }

  /// Campanhas visíveis a visitante: ativas E públicas.
  Stream<List<CampanhaModel>> streamAtivasPublicas() {
    return _col
        .where('publico', isEqualTo: true)
        .where('status', isEqualTo: 'ativa')
        .snapshots()
        .map(_ordenar);
  }

  /// Visão de gestão: todas, inclusive encerradas.
  Stream<List<CampanhaModel>> streamGerenciar() {
    return _col.snapshots().map(_ordenar);
  }

  List<CampanhaModel> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs.map(CampanhaModel.fromFirestore).toList()
      ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
  }

  Future<String> criar(CampanhaModel campanha) async {
    final ref = await _col.add(campanha.toMap());
    return ref.id;
  }

  /// `valor_arrecadado` é cache mantido pelo servidor — quem chama preserva o
  /// valor atual em vez de sobrescrevê-lo.
  Future<void> atualizar(CampanhaModel campanha) {
    return _col.doc(campanha.id).update(campanha.toMap());
  }

  /// Encerra sem apagar, preservando o histórico.
  Future<void> definirStatus(String id, String status) {
    return _col.doc(id).update({'status': status});
  }
}
