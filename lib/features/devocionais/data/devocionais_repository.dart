import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/igreja_scope.dart';
import 'devocional_model.dart';

/// Devocionais de UMA unidade: `igrejas/{igrejaId}/devocionais`.
class DevocionaisRepository {
  DevocionaisRepository(this._scope);

  final IgrejaScope _scope;

  CollectionReference<Map<String, dynamic>> get _col => _scope.devocionais;

  /// Devocionais ativos, mais recentes primeiro.
  Stream<List<DevocionalModel>> stream() {
    return _col.where('ativo', isEqualTo: true).snapshots().map(_ordenar);
  }

  /// Visão de gestão: inclui inativos, para reeditar ou reativar.
  Stream<List<DevocionalModel>> streamGerenciar() {
    return _col.snapshots().map(_ordenar);
  }

  List<DevocionalModel> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(DevocionalModel.fromFirestore).toList();
    lista.sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  Future<String> criar(DevocionalModel devocional) async {
    final ref = await _col.add(devocional.toMap());
    return ref.id;
  }

  Future<void> atualizar(DevocionalModel devocional) {
    return _col.doc(devocional.id).update(devocional.toMap());
  }

  /// Inativa em vez de apagar: o histórico da unidade é preservado.
  Future<void> definirAtivo(String id, bool ativo) {
    return _col.doc(id).update({'ativo': ativo});
  }
}
