import 'package:cloud_firestore/cloud_firestore.dart';

import 'aviso_model.dart';

/// Acesso ao Firestore para avisos (coleção `avisos`). Ordenação no cliente
/// para evitar índices compostos. Escrita é restrita à liderança pelas regras.
class AvisosRepository {
  AvisosRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('avisos');

  final CollectionReference<Map<String, dynamic>> _col;

  /// Feed público (membros): apenas avisos ativos, mais recentes primeiro.
  Stream<List<AvisoModel>> stream() {
    return _col.where('ativo', isEqualTo: true).snapshots().map((snap) {
      final lista = snap.docs.map(AvisoModel.fromFirestore).toList();
      lista.sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
      return lista;
    });
  }

  /// Visão da liderança (Gestão): TODOS os avisos, inclusive os despublicados
  /// (ativo == false), para permitir editar/republicar. Ordenado por data.
  Stream<List<AvisoModel>> streamGerenciar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(AvisoModel.fromFirestore).toList();
      lista.sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
      return lista;
    });
  }

  /// Cria um novo aviso. Retorna o id gerado.
  Future<String> criar(AvisoModel aviso) async {
    final ref = await _col.add(aviso.toMap());
    return ref.id;
  }

  /// Atualiza um aviso existente (título/conteúdo/prioridade/segmento/ativo).
  Future<void> atualizar(AvisoModel aviso) {
    return _col.doc(aviso.id).update(aviso.toMap());
  }

  /// Publica/despublica sem apagar (troca `ativo`). Preferível a excluir quando
  /// o aviso pode voltar a ser útil.
  Future<void> definirAtivo(String id, bool ativo) {
    return _col.doc(id).update({'ativo': ativo});
  }

  /// Remove definitivamente um aviso.
  Future<void> excluir(String id) {
    return _col.doc(id).delete();
  }
}
