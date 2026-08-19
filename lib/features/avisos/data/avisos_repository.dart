import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/igreja_scope.dart';
import 'aviso_model.dart';

/// Avisos de UMA unidade: `igrejas/{igrejaId}/avisos`.
///
/// Ordenação no cliente para dispensar índice composto. As Rules restringem a
/// escrita a quem pode gerenciar conteúdo na unidade.
class AvisosRepository {
  AvisosRepository(this._scope);

  final IgrejaScope _scope;

  CollectionReference<Map<String, dynamic>> get _col => _scope.avisos;

  /// Feed de membro aprovado: avisos ativos da unidade.
  Stream<List<AvisoModel>> stream() {
    return _col.where('ativo', isEqualTo: true).snapshots().map(_ordenar);
  }

  /// Feed de visitante: SOMENTE avisos públicos.
  ///
  /// O filtro `publico == true` não é cosmético — as Rules exigem que a
  /// consulta o declare, senão negam a leitura inteira.
  Stream<List<AvisoModel>> streamPublicos() {
    return _col
        .where('publico', isEqualTo: true)
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map(_ordenar);
  }

  /// Visão de gestão: inclui despublicados, para editar/republicar.
  Stream<List<AvisoModel>> streamGerenciar() {
    return _col.snapshots().map(_ordenar);
  }

  List<AvisoModel> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(AvisoModel.fromFirestore).toList();
    lista.sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
    return lista;
  }

  Future<String> criar(AvisoModel aviso) async {
    final ref = await _col.add(aviso.toMap());
    return ref.id;
  }

  Future<void> atualizar(AvisoModel aviso) {
    return _col.doc(aviso.id).update(aviso.toMap());
  }

  /// Publica/despublica sem apagar. Substitui a exclusão física: um aviso
  /// despublicado continua no histórico da unidade.
  Future<void> definirAtivo(String id, bool ativo) {
    return _col.doc(id).update({'ativo': ativo});
  }
}
